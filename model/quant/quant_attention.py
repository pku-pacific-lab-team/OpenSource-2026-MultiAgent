"""Dense Q/K/P/V fake quant and SF Sparse for rotary GQA models."""

from __future__ import annotations

import warnings
from typing import Optional

import torch
import torch.nn as nn
import torch.nn.functional as F
from transformers.cache_utils import Cache
from transformers.models.gpt_neox.modeling_gpt_neox import (
    apply_rotary_pos_emb as apply_gpt_neox_rotary_pos_emb,
)
from transformers.models.phi.modeling_phi import (
    apply_rotary_pos_emb as apply_phi_rotary_pos_emb,
)
from transformers.models.qwen3.modeling_qwen3 import (
    apply_rotary_pos_emb,
    repeat_kv,
)
from transformers.utils.deprecation import deprecate_kwarg

from .config import QuantConfig
from .hadamard import (
    compensate_output_projection_weight_,
    randomized_hadamard_matrix,
    right_rotate_head_dim,
)
from .quant_func import int_quant
from .sparse_attention import build_sf_topk_selection
from .stats import observe_quant_tensor, observe_sparse_attention


class QuantRotaryAttention(nn.Module):
    """Shared eager attention for supported rotary causal-LM modules."""

    def __init__(
        self,
        original_module: nn.Module,
        config: QuantConfig,
        layer_name: str,
    ) -> None:
        # Do not call the original attention __init__: it would allocate a
        # second set of
        # large projection weights before we replace them with existing modules.
        nn.Module.__init__(self)

        self.config = original_module.config
        self.layer_idx = original_module.layer_idx
        self.packed_qkv = hasattr(original_module, "query_key_value")
        if self.packed_qkv:
            self.head_dim = original_module.head_size
            self.num_key_value_groups = 1
        else:
            self.head_dim = original_module.head_dim
            self.num_key_value_groups = original_module.num_key_value_groups
        self.scaling = original_module.scaling
        self.attention_dropout = original_module.attention_dropout
        self.is_causal = getattr(original_module, "is_causal", True)
        self.is_sliding = getattr(original_module, "is_sliding", False)
        self.sliding_window = getattr(original_module, "sliding_window", None)
        self.attn_logit_softcapping = getattr(
            original_module,
            "attn_logit_softcapping",
            None,
        )

        if self.packed_qkv:
            self.query_key_value = original_module.query_key_value
            self.dense = original_module.dense
            self.rotary_ndims = original_module.rotary_ndims
            output_projection = self.dense
        else:
            self.q_proj = original_module.q_proj
            self.k_proj = original_module.k_proj
            self.v_proj = original_module.v_proj
            if hasattr(original_module, "o_proj"):
                self.o_proj = original_module.o_proj
                output_projection = self.o_proj
            elif hasattr(original_module, "dense"):
                self.dense = original_module.dense
                output_projection = self.dense
            else:
                raise TypeError(
                    "supported attention requires o_proj or dense output "
                    "projection"
                )
            self.q_norm = getattr(
                original_module,
                "q_norm",
                getattr(original_module, "q_layernorm", nn.Identity()),
            )
            self.k_norm = getattr(
                original_module,
                "k_norm",
                getattr(original_module, "k_layernorm", nn.Identity()),
            )
            self.rotary_ndims = getattr(
                original_module,
                "rotary_ndims",
                self.head_dim,
            )

        self.quant_config = QuantConfig.from_object(config)
        self.layer_name = layer_name
        self.need_quantization = any(
            bits < 16
            for bits in (
                self.quant_config.attn_q_bits,
                self.quant_config.attn_k_bits,
                self.quant_config.attn_p_bits,
                self.quant_config.attn_v_bits,
            )
        )
        self.attention_hadamard = self.quant_config.attention_hadamard
        if self.attention_hadamard:
            layer_seed_offset = 2 * int(self.layer_idx or 0)
            qk_rotation = randomized_hadamard_matrix(
                self.head_dim,
                seed=(
                    self.quant_config.attention_hadamard_seed
                    + layer_seed_offset
                ),
                device=output_projection.weight.device,
            )
            v_rotation = randomized_hadamard_matrix(
                self.head_dim,
                seed=(
                    self.quant_config.attention_hadamard_seed
                    + layer_seed_offset
                    + 1
                ),
                device=output_projection.weight.device,
            )
            self.register_buffer(
                "qk_hadamard",
                qk_rotation,
                persistent=False,
            )
            self.register_buffer(
                "v_hadamard",
                v_rotation,
                persistent=False,
            )
            if getattr(output_projection, "weight_prequantized", False):
                raise ValueError(
                    "O projection was prequantized before V-rotation "
                    "compensation"
                )
            compensate_output_projection_weight_(
                output_projection.weight,
                self.v_hadamard,
                head_dim=self.head_dim,
            )
            if (
                self.quant_config.w_quant_inplace
                and hasattr(output_projection, "prequantize_weight_")
            ):
                output_projection.prequantize_weight_()
        else:
            self.register_buffer("qk_hadamard", None, persistent=False)
            self.register_buffer("v_hadamard", None, persistent=False)
        self.stored_attention_map: Optional[torch.Tensor] = None
        self.train(original_module.training)

    @classmethod
    def from_original_module(
        cls,
        original_module: nn.Module,
        config: QuantConfig,
        layer_name: str,
    ) -> "QuantRotaryAttention":
        return cls(original_module, config, layer_name)

    def _apply_attention_hadamard(
        self,
        query_states: torch.Tensor,
        key_states: torch.Tensor,
        value_states: torch.Tensor,
    ) -> tuple[torch.Tensor, torch.Tensor, torch.Tensor]:
        if not self.attention_hadamard:
            return query_states, key_states, value_states
        return (
            right_rotate_head_dim(query_states, self.qk_hadamard),
            right_rotate_head_dim(key_states, self.qk_hadamard),
            right_rotate_head_dim(value_states, self.v_hadamard),
        )

    def _fake_quant_last_dim(
        self,
        tensor: torch.Tensor,
        bits: int,
        tensor_name: str,
        *,
        pad_to_group: bool = False,
        return_scale: bool = False,
    ) -> torch.Tensor | tuple[torch.Tensor, torch.Tensor]:
        original = tensor
        if bits >= 16:
            if return_scale:
                raise ValueError(
                    "return_scale requires a quantized tensor with bits < 16"
                )
            return tensor
        group_size = self.quant_config.group_size
        original_last_dim = tensor.shape[-1]
        if group_size > 0 and original_last_dim % group_size:
            if not pad_to_group:
                raise ValueError(
                    f"last dimension {original_last_dim} is not divisible by "
                    f"group_size {group_size}"
                )
            pad_size = group_size - original_last_dim % group_size
            tensor = F.pad(tensor, (0, pad_size), value=0.0)

        should_observe = self.quant_config.collect_stats and bits < 16
        need_scale = should_observe or return_scale
        quant_result = int_quant(
            tensor,
            bits,
            dim=-1,
            group_size=group_size,
            e8_scale=self.quant_config.e8_scale,
            e8_scale_op=self.quant_config.e8_scale_op,
            clip_style=self.quant_config.clip_style,
            return_scale=need_scale,
        )
        if need_scale:
            quantized, scales = quant_result
        else:
            quantized = quant_result
        quantized = quantized[..., :original_last_dim]

        if should_observe:
            observe_quant_tensor(
                layer_name=self.layer_name,
                tensor_name=tensor_name,
                original=original,
                dequantized=quantized,
                scales=scales,
                bits=bits,
                clip_style=self.quant_config.clip_style,
                group_size=group_size,
            )
        if return_scale:
            return quantized, scales
        return quantized

    @staticmethod
    def _attention_mask_to_block_valid_mask(
        attention_mask: Optional[torch.Tensor],
        *,
        batch: int,
        heads: int,
        query_length: int,
        key_length: int,
        block_size: int,
    ) -> Optional[torch.Tensor]:
        """Reduce a token mask to blocks containing at least one valid pair."""
        if attention_mask is None:
            return None
        if attention_mask.ndim != 4:
            raise ValueError("attention_mask must have shape [B, H|1, Q, K]")
        token_mask = attention_mask[
            :,
            :,
            :query_length,
            :key_length,
        ]
        if token_mask.shape[0] not in (1, batch):
            raise ValueError("attention_mask batch dimension must be 1 or B")
        if token_mask.shape[1] not in (1, heads):
            raise ValueError("attention_mask head dimension must be 1 or H")
        token_mask = token_mask.expand(batch, heads, -1, -1)
        if token_mask.dtype == torch.bool:
            token_valid = token_mask
        elif token_mask.dtype.is_floating_point:
            # HF additive masks use the dtype minimum (or -inf) for blocked
            # positions. Finite attention biases remain valid candidates.
            threshold = torch.finfo(token_mask.dtype).min / 2
            token_valid = token_mask > threshold
        else:
            raise TypeError("attention_mask must be boolean or floating point")

        query_blocks = (query_length + block_size - 1) // block_size
        key_blocks = (key_length + block_size - 1) // block_size
        token_valid = F.pad(
            token_valid,
            (
                0,
                key_blocks * block_size - key_length,
                0,
                query_blocks * block_size - query_length,
            ),
            value=False,
        )
        token_valid = token_valid.reshape(
            batch,
            heads,
            query_blocks,
            block_size,
            key_blocks,
            block_size,
        )
        return token_valid.any(dim=(3, 5))

    def _sf_sparse_attention_forward(
        self,
        query_states: torch.Tensor,
        key_states: torch.Tensor,
        value_states: torch.Tensor,
        query_scales: torch.Tensor,
        key_scales: torch.Tensor,
        attention_mask: Optional[torch.Tensor],
        *,
        scaling: float,
        dropout: float,
        softcap: Optional[float] = None,
    ) -> tuple[torch.Tensor, None]:
        """Reference selected-block QK/softmax/PV without a dense SxS score."""
        batch, heads, query_length, head_dim = query_states.shape
        key_length = key_states.shape[-2]
        block_size = self.quant_config.sf_sparse_block_size
        block_valid_mask = self._attention_mask_to_block_valid_mask(
            attention_mask,
            batch=batch,
            heads=heads,
            query_length=query_length,
            key_length=key_length,
            block_size=block_size,
        )
        selection = build_sf_topk_selection(
            query_scales,
            key_scales,
            block_size=block_size,
            topk_blocks=self.quant_config.sf_sparse_topk_blocks,
            reduction=self.quant_config.sf_sparse_reduction,
            force_first_block=self.quant_config.sf_sparse_force_first_block,
            force_diagonal_block=(
                self.quant_config.sf_sparse_force_diagonal_block
            ),
            block_valid_mask=block_valid_mask,
        )

        selected = selection.selected_block_indices
        valid_selected = selected >= 0
        safe_selected = selected.clamp_min(0)
        selected_key_counts = selection.key_block_token_counts[safe_selected]
        selected_key_counts = selected_key_counts * valid_selected
        executed_qk_pairs = int(
            (
                selected_key_counts.sum(dim=-1)
                * selection.query_block_token_counts.view(1, 1, -1)
            ).sum().item()
        )
        dense_qk_pairs = batch * heads * query_length * key_length
        total_causal_blocks = (
            batch
            * heads
            * selection.block_mask.shape[-2]
            * (selection.block_mask.shape[-2] + 1)
            // 2
        )
        total_valid_blocks = int(selection.candidate_block_mask.sum().item())
        observe_sparse_attention(
            layer_name=self.layer_name,
            total_causal_blocks=total_causal_blocks,
            total_valid_blocks=total_valid_blocks,
            kept_blocks=int(selection.block_mask.sum().item()),
            executed_qk_pairs=executed_qk_pairs,
            dense_qk_pairs=dense_qk_pairs,
            fallback=False,
        )

        output = torch.zeros_like(query_states)
        capture_map: Optional[torch.Tensor] = None
        capture_heads = 0
        capture_query_tokens = 0
        capture_key_tokens = 0
        if (
            self.quant_config.capture_attention_maps
            and self.stored_attention_map is None
        ):
            max_heads = self.quant_config.attention_map_max_heads
            max_tokens = self.quant_config.attention_map_max_tokens
            capture_heads = (
                heads if max_heads < 0 else min(max_heads, heads)
            )
            capture_query_tokens = (
                query_length
                if max_tokens < 0
                else min(max_tokens, query_length)
            )
            capture_key_tokens = (
                key_length
                if max_tokens < 0
                else min(max_tokens, key_length)
            )
            capture_map = torch.zeros(
                capture_heads,
                capture_query_tokens,
                capture_key_tokens,
                dtype=torch.float32,
                device=query_states.device,
            )

        offsets = torch.arange(block_size, device=query_states.device)
        num_query_blocks = selected.shape[-2]
        for query_block in range(num_query_blocks):
            query_start = query_block * block_size
            query_end = min(query_start + block_size, query_length)
            query_block_states = query_states[:, :, query_start:query_end, :]

            # Every causal row has min(K, row+1) selected blocks. Dropping the
            # trailing -1 entries avoids quantizing structural padding as P.
            active_blocks = min(
                self.quant_config.sf_sparse_topk_blocks,
                query_block + 1,
            )
            selected_blocks = selected[
                :, :, query_block, :active_blocks
            ]
            valid_blocks = selected_blocks >= 0
            safe_blocks = selected_blocks.clamp_min(0)
            key_positions = (
                safe_blocks.unsqueeze(-1) * block_size
                + offsets.view(1, 1, 1, block_size)
            ).flatten(-2)
            valid_key_positions = (
                valid_blocks.unsqueeze(-1)
                & (
                    safe_blocks.unsqueeze(-1) * block_size
                    + offsets.view(1, 1, 1, block_size)
                    < key_length
                )
            ).flatten(-2)
            safe_key_positions = key_positions.clamp(max=key_length - 1)
            gather_index = safe_key_positions.unsqueeze(-1).expand(
                -1,
                -1,
                -1,
                head_dim,
            )
            selected_keys = torch.gather(key_states, 2, gather_index)
            selected_values = torch.gather(value_states, 2, gather_index)

            attention_scores = torch.matmul(
                query_block_states,
                selected_keys.transpose(-1, -2),
            ) * scaling
            if softcap is not None:
                attention_scores = torch.tanh(
                    attention_scores / softcap
                ) * softcap
            query_positions = torch.arange(
                query_start,
                query_end,
                device=query_states.device,
            ).view(1, 1, -1, 1)
            causal_token_mask = (
                valid_key_positions.unsqueeze(-2)
                & (safe_key_positions.unsqueeze(-2) <= query_positions)
            )

            if attention_mask is not None:
                selected_mask = attention_mask[
                    :, :, query_start:query_end, :key_length
                ]
                if selected_mask.shape[1] == 1:
                    selected_mask = selected_mask.expand(-1, heads, -1, -1)
                elif selected_mask.shape[1] != heads:
                    raise ValueError(
                        "attention_mask head dimension must be 1 or num_heads"
                    )
                mask_gather_index = safe_key_positions.unsqueeze(-2).expand(
                    -1,
                    -1,
                    query_end - query_start,
                    -1,
                )
                selected_mask = torch.gather(
                    selected_mask,
                    dim=-1,
                    index=mask_gather_index,
                )
                if selected_mask.dtype == torch.bool:
                    attention_scores = attention_scores.masked_fill(
                        ~selected_mask,
                        -torch.inf,
                    )
                else:
                    attention_scores = attention_scores + selected_mask

            attention_scores = attention_scores.masked_fill(
                ~causal_token_mask,
                -torch.inf,
            )
            attention_probs = F.softmax(
                attention_scores,
                dim=-1,
                dtype=torch.float32,
            ).to(query_states.dtype)

            if capture_map is not None and query_start < capture_query_tokens:
                captured_query_count = min(
                    query_end,
                    capture_query_tokens,
                ) - query_start
                captured_positions = safe_key_positions[
                    0, :capture_heads
                ].clamp(max=capture_key_tokens - 1)
                captured_valid = (
                    valid_key_positions[0, :capture_heads]
                    & (
                        safe_key_positions[0, :capture_heads]
                        < capture_key_tokens
                    )
                )
                capture_index = captured_positions.unsqueeze(-2).expand(
                    -1,
                    captured_query_count,
                    -1,
                )
                capture_values = attention_probs[
                    0,
                    :capture_heads,
                    :captured_query_count,
                ].float()
                capture_values = capture_values * captured_valid.unsqueeze(-2)
                capture_map[
                    :, query_start : query_start + captured_query_count
                ].scatter_add_(-1, capture_index, capture_values)

            attention_probs = F.dropout(
                attention_probs,
                p=dropout,
                training=self.training,
            )
            attention_probs = self._fake_quant_last_dim(
                attention_probs,
                self.quant_config.attn_p_bits,
                "p",
                pad_to_group=True,
            )
            output[:, :, query_start:query_end] = torch.matmul(
                attention_probs,
                selected_values,
            )

        if capture_map is not None:
            self.stored_attention_map = capture_map.detach().cpu()
        return output.transpose(1, 2).contiguous(), None

    def _quantized_attention_forward(
        self,
        query_states: torch.Tensor,
        key_states: torch.Tensor,
        value_states: torch.Tensor,
        attention_mask: Optional[torch.Tensor],
        *,
        scaling: float,
        dropout: float,
        softcap: Optional[float] = None,
    ) -> tuple[torch.Tensor, Optional[torch.Tensor]]:
        if self.quant_config.sf_sparse_enabled:
            query_states, query_scales = self._fake_quant_last_dim(
                query_states,
                self.quant_config.attn_q_bits,
                "q",
                pad_to_group=True,
                return_scale=True,
            )
            key_states, key_scales = self._fake_quant_last_dim(
                key_states,
                self.quant_config.attn_k_bits,
                "k",
                pad_to_group=True,
                return_scale=True,
            )
        else:
            query_states = self._fake_quant_last_dim(
                query_states,
                self.quant_config.attn_q_bits,
                "q",
                pad_to_group=True,
            )
            key_states = self._fake_quant_last_dim(
                key_states,
                self.quant_config.attn_k_bits,
                "k",
                pad_to_group=True,
            )
        value_states = self._fake_quant_last_dim(
            value_states,
            self.quant_config.attn_v_bits,
            "v",
            pad_to_group=True,
        )

        key_states = repeat_kv(key_states, self.num_key_value_groups)
        value_states = repeat_kv(value_states, self.num_key_value_groups)

        if self.quant_config.sf_sparse_enabled:
            key_scales = repeat_kv(
                key_scales,
                self.num_key_value_groups,
            )
            if query_states.shape[-2] == key_states.shape[-2]:
                return self._sf_sparse_attention_forward(
                    query_states,
                    key_states,
                    value_states,
                    query_scales,
                    key_scales,
                    attention_mask,
                    scaling=scaling,
                    dropout=dropout,
                    softcap=softcap,
                )
            if not self.quant_config.sf_sparse_dense_fallback:
                raise NotImplementedError(
                    "SF Sparse decode/KV-cache attention is not implemented; "
                    "enable sf_sparse_dense_fallback or use aligned prefill"
                )
            batch, heads, query_length, _ = query_states.shape
            key_length = key_states.shape[-2]
            dense_pairs = batch * heads * query_length * key_length
            observe_sparse_attention(
                layer_name=self.layer_name,
                total_causal_blocks=0,
                kept_blocks=0,
                executed_qk_pairs=dense_pairs,
                dense_qk_pairs=dense_pairs,
                fallback=True,
            )

        attn_weights = (
            torch.matmul(query_states, key_states.transpose(2, 3)) * scaling
        )
        if softcap is not None:
            attn_weights = torch.tanh(attn_weights / softcap) * softcap
        if attention_mask is not None:
            causal_mask = attention_mask[:, :, :, : key_states.shape[-2]]
            attn_weights = attn_weights + causal_mask

        attn_weights = F.softmax(
            attn_weights,
            dim=-1,
            dtype=torch.float32,
        ).to(query_states.dtype)

        # Capture at most one bounded, post-softmax map per layer.  The old
        # script retained every head at full sequence length; explicit limits
        # make the diagnostic usable at normal PPL context lengths.
        if (
            self.quant_config.capture_attention_maps
            and self.stored_attention_map is None
        ):
            max_heads = self.quant_config.attention_map_max_heads
            max_tokens = self.quant_config.attention_map_max_tokens
            head_stop = (
                attn_weights.shape[1]
                if max_heads < 0
                else min(max_heads, attn_weights.shape[1])
            )
            query_stop = (
                attn_weights.shape[-2]
                if max_tokens < 0
                else min(max_tokens, attn_weights.shape[-2])
            )
            key_stop = (
                attn_weights.shape[-1]
                if max_tokens < 0
                else min(max_tokens, attn_weights.shape[-1])
            )
            self.stored_attention_map = (
                attn_weights[0, :head_stop, :query_stop, :key_stop]
                .detach()
                .float()
                .cpu()
            )
        attn_weights = F.dropout(
            attn_weights,
            p=dropout,
            training=self.training,
        )
        # Generation sequence lengths are often not divisible by 32. Padding is
        # only an implementation detail and is removed before P @ V.
        attn_weights = self._fake_quant_last_dim(
            attn_weights,
            self.quant_config.attn_p_bits,
            "p",
            pad_to_group=True,
        )

        attn_output = torch.matmul(attn_weights, value_states)
        return attn_output.transpose(1, 2).contiguous(), attn_weights

    @deprecate_kwarg(
        "past_key_value",
        new_name="past_key_values",
        version="4.58",
    )
    def forward(
        self,
        hidden_states: torch.Tensor,
        position_embeddings: tuple[torch.Tensor, torch.Tensor],
        attention_mask: Optional[torch.Tensor],
        past_key_values: Optional[Cache] = None,
        cache_position: Optional[torch.LongTensor] = None,
        **kwargs,
    ) -> tuple[torch.Tensor, Optional[torch.Tensor]]:
        if self.config._attn_implementation != "eager":
            warnings.warn(
                "Q/K/P/V quantization uses the eager attention path; "
                f"configured backend is {self.config._attn_implementation!r}.",
                stacklevel=2,
            )

        input_shape = hidden_states.shape[:-1]
        hidden_shape = (*input_shape, -1, self.head_dim)

        query_states = self.q_norm(
            self.q_proj(hidden_states).view(hidden_shape)
        ).transpose(1, 2)
        key_states = self.k_norm(
            self.k_proj(hidden_states).view(hidden_shape)
        ).transpose(1, 2)
        value_states = self.v_proj(hidden_states).view(hidden_shape).transpose(
            1,
            2,
        )

        cos, sin = position_embeddings
        query_states, key_states = apply_rotary_pos_emb(
            query_states,
            key_states,
            cos,
            sin,
        )

        # Rotate after RoPE so Q and K meet at the score matmul with the same
        # right-side orthogonal matrix.  Rotate before cache.update so cached
        # K/V use the transformed basis once, rather than being re-rotated on
        # every decoding step.
        query_states, key_states, value_states = (
            self._apply_attention_hadamard(
                query_states,
                key_states,
                value_states,
            )
        )

        if past_key_values is not None:
            cache_kwargs = {
                "sin": sin,
                "cos": cos,
                "cache_position": cache_position,
            }
            key_states, value_states = past_key_values.update(
                key_states,
                value_states,
                self.layer_idx,
                cache_kwargs,
            )

        attn_output, attn_weights = self._quantized_attention_forward(
            query_states,
            key_states,
            value_states,
            attention_mask,
            scaling=self.scaling,
            dropout=0.0 if not self.training else self.attention_dropout,
            softcap=self.attn_logit_softcapping,
        )
        attn_output = attn_output.reshape(*input_shape, -1).contiguous()
        return self.o_proj(attn_output), attn_weights


class QuantQwen3Attention(QuantRotaryAttention):
    """Qwen3 adapter for the shared quantized rotary attention."""


class QuantQwen2Attention(QuantRotaryAttention):
    """Qwen2/Qwen2.5 adapter for the shared quantized rotary attention."""


class QuantMistralAttention(QuantRotaryAttention):
    """Mistral adapter for the shared quantized rotary attention."""


class QuantLlamaAttention(QuantRotaryAttention):
    """Llama/OpenLLaMA adapter for the shared quantized rotary attention."""


class QuantGemma3Attention(QuantRotaryAttention):
    """Gemma3 text adapter, including sliding-mask and optional softcap."""


class QuantPhiAttention(QuantRotaryAttention):
    """Phi/Phi-2 adapter for separate QKV and partial rotary embedding."""

    @deprecate_kwarg(
        "past_key_value",
        new_name="past_key_values",
        version="4.58",
    )
    def forward(
        self,
        hidden_states: torch.Tensor,
        position_embeddings: tuple[torch.Tensor, torch.Tensor],
        attention_mask: Optional[torch.Tensor],
        past_key_values: Optional[Cache] = None,
        cache_position: Optional[torch.LongTensor] = None,
        **kwargs,
    ) -> tuple[torch.Tensor, Optional[torch.Tensor]]:
        if self.config._attn_implementation != "eager":
            warnings.warn(
                "Q/K/P/V quantization uses the eager attention path; "
                f"configured backend is {self.config._attn_implementation!r}.",
                stacklevel=2,
            )

        input_shape = hidden_states.shape[:-1]
        hidden_shape = (*input_shape, -1, self.head_dim)
        query_states = self.q_norm(
            self.q_proj(hidden_states).view(hidden_shape)
        ).transpose(1, 2)
        key_states = self.k_norm(
            self.k_proj(hidden_states).view(hidden_shape)
        ).transpose(1, 2)
        value_states = self.v_proj(hidden_states).view(hidden_shape).transpose(
            1,
            2,
        )

        cos, sin = position_embeddings
        query_rot = query_states[..., : self.rotary_ndims]
        query_pass = query_states[..., self.rotary_ndims :]
        key_rot = key_states[..., : self.rotary_ndims]
        key_pass = key_states[..., self.rotary_ndims :]
        query_rot, key_rot = apply_phi_rotary_pos_emb(
            query_rot,
            key_rot,
            cos,
            sin,
        )
        query_states = torch.cat((query_rot, query_pass), dim=-1)
        key_states = torch.cat((key_rot, key_pass), dim=-1)
        query_states, key_states, value_states = (
            self._apply_attention_hadamard(
                query_states,
                key_states,
                value_states,
            )
        )

        if past_key_values is not None:
            cache_kwargs = {
                "sin": sin,
                "cos": cos,
                "cache_position": cache_position,
            }
            key_states, value_states = past_key_values.update(
                key_states,
                value_states,
                self.layer_idx,
                cache_kwargs,
            )

        attn_output, attn_weights = self._quantized_attention_forward(
            query_states,
            key_states,
            value_states,
            attention_mask,
            scaling=self.scaling,
            dropout=0.0 if not self.training else self.attention_dropout,
        )
        attn_output = attn_output.reshape(*input_shape, -1).contiguous()
        return self.dense(attn_output), attn_weights


class QuantGPTNeoXAttention(QuantRotaryAttention):
    """GPT-NeoX/Pythia adapter for packed QKV rotary attention."""

    def forward(
        self,
        hidden_states: torch.Tensor,
        attention_mask: Optional[torch.Tensor],
        head_mask: Optional[torch.Tensor] = None,
        layer_past: Optional[Cache] = None,
        output_attentions: bool = False,
        cache_position: Optional[torch.LongTensor] = None,
        position_embeddings: Optional[
            tuple[torch.Tensor, torch.Tensor]
        ] = None,
        **kwargs,
    ) -> tuple[torch.Tensor, Optional[torch.Tensor]]:
        if head_mask is not None:
            raise NotImplementedError(
                "QuantGPTNeoXAttention does not support head_mask"
            )
        if position_embeddings is None:
            raise ValueError("GPT-NeoX attention requires position_embeddings")
        if self.config._attn_implementation != "eager":
            warnings.warn(
                "Q/K/P/V quantization uses the eager attention path; "
                f"configured backend is {self.config._attn_implementation!r}.",
                stacklevel=2,
            )

        input_shape = hidden_states.shape[:-1]
        hidden_shape = (*input_shape, -1, 3 * self.head_dim)
        qkv = self.query_key_value(hidden_states).view(hidden_shape).transpose(
            1,
            2,
        )
        query_states, key_states, value_states = qkv.chunk(3, dim=-1)

        cos, sin = position_embeddings
        query_states, key_states = apply_gpt_neox_rotary_pos_emb(
            query_states,
            key_states,
            cos,
            sin,
        )
        query_states, key_states, value_states = (
            self._apply_attention_hadamard(
                query_states,
                key_states,
                value_states,
            )
        )

        if layer_past is None:
            layer_past = kwargs.pop("past_key_values", None)
        if layer_past is not None:
            cache_kwargs = {
                "sin": sin,
                "cos": cos,
                "partial_rotation_size": self.rotary_ndims,
                "cache_position": cache_position,
            }
            key_states, value_states = layer_past.update(
                key_states,
                value_states,
                self.layer_idx,
                cache_kwargs,
            )

        attn_output, attn_weights = self._quantized_attention_forward(
            query_states,
            key_states,
            value_states,
            attention_mask,
            scaling=self.scaling,
            dropout=0.0 if not self.training else self.attention_dropout,
            softcap=self.attn_logit_softcapping,
        )
        attn_output = attn_output.reshape(*input_shape, -1).contiguous()
        return self.dense(attn_output), attn_weights
