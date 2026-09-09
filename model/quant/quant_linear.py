"""Minimal inference-only quantized Linear layer."""

from __future__ import annotations

import torch
import torch.nn as nn
import torch.nn.functional as F

from .config import QuantConfig
from .quant_func import int_quant
from .stats import observe_quant_tensor


class QuantLinear(nn.Module):
    """``nn.Linear`` with dense weight/activation fake quantization."""

    def __init__(
        self,
        in_features: int,
        out_features: int,
        config: QuantConfig,
        *,
        bias: bool,
        dtype: torch.dtype,
        device: torch.device,
        layer_name: str,
    ) -> None:
        super().__init__()
        self.in_features = in_features
        self.out_features = out_features
        self.layer_name = layer_name
        self.quant_config = QuantConfig.from_object(config)
        self.weight_prequantized = False
        self._weight_stats_recorded = False

        self.weight = nn.Parameter(
            torch.empty(
                out_features,
                in_features,
                dtype=dtype,
                device=device,
            )
        )
        if bias:
            self.bias = nn.Parameter(
                torch.empty(out_features, dtype=dtype, device=device)
            )
        else:
            self.register_parameter("bias", None)

    def _fake_quant(
        self,
        tensor: torch.Tensor,
        bits: int,
        tensor_name: str,
        *,
        record_stats: bool = True,
    ) -> torch.Tensor:
        should_observe = (
            self.quant_config.collect_stats
            and record_stats
            and bits < 16
        )
        quant_result = int_quant(
            tensor,
            bits,
            dim=-1,
            group_size=self.quant_config.group_size,
            e8_scale=self.quant_config.e8_scale,
            e8_scale_op=self.quant_config.e8_scale_op,
            clip_style=self.quant_config.clip_style,
            return_scale=should_observe,
        )
        if not should_observe:
            return quant_result

        quantized, scales = quant_result
        observe_quant_tensor(
            layer_name=self.layer_name,
            tensor_name=tensor_name,
            original=tensor,
            dequantized=quantized,
            scales=scales,
            bits=bits,
            clip_style=self.quant_config.clip_style,
            group_size=self.quant_config.group_size,
        )
        return quantized

    def quant_forward(self, x: torch.Tensor) -> torch.Tensor:
        """Run the dense fake-quantized Linear operation."""
        quantized_x = self._fake_quant(
            x,
            self.quant_config.q1_x,
            "activation",
        )
        if self.weight_prequantized:
            quantized_weight = self.weight
        else:
            quantized_weight = self._fake_quant(
                self.weight,
                self.quant_config.q1_w,
                "weight",
                record_stats=not self._weight_stats_recorded,
            )
            if self.quant_config.collect_stats:
                self._weight_stats_recorded = True
        return F.linear(quantized_x, quantized_weight, self.bias)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return self.quant_forward(x)

    def prequantize_weight_(self) -> None:
        """Fake-quantize and store the weight once for inference.

        This public helper lets attention postpone O-projection weight
        quantization until after its V-rotation compensation has been applied.
        """
        if self.weight_prequantized:
            return
        with torch.no_grad():
            quantized_weight = self._fake_quant(
                self.weight,
                self.quant_config.q1_w,
                "weight",
            )
            self.weight.copy_(quantized_weight)
        self.weight_prequantized = True
        self._weight_stats_recorded = self.quant_config.collect_stats

    @classmethod
    def from_original_module(
        cls,
        original_module: nn.Linear,
        config: QuantConfig,
        layer_name: str,
    ) -> "QuantLinear":
        quant_config = QuantConfig.from_object(config)
        new_module = cls(
            original_module.in_features,
            original_module.out_features,
            quant_config,
            bias=original_module.bias is not None,
            dtype=original_module.weight.dtype,
            device=original_module.weight.device,
            layer_name=layer_name,
        )

        with torch.no_grad():
            new_module.weight.copy_(original_module.weight)

            if original_module.bias is not None:
                new_module.bias.copy_(original_module.bias)

        final_components = layer_name.split(".")[-2:]
        is_attention_output_projection = final_components in (
            ["self_attn", "o_proj"],
            ["self_attn", "dense"],
            ["attention", "dense"],
        )
        defer_for_v_rotation = (
            quant_config.attention_hadamard
            and is_attention_output_projection
        )
        if quant_config.w_quant_inplace and not defer_for_v_rotation:
            new_module.prequantize_weight_()

        new_module.train(original_module.training)
        return new_module

    def extra_repr(self) -> str:
        return (
            f"in_features={self.in_features}, "
            f"out_features={self.out_features}, "
            f"bias={self.bias is not None}, "
            f"w_bits={self.quant_config.q1_w}, "
            f"a_bits={self.quant_config.q1_x}, "
            f"group_size={self.quant_config.group_size}, "
            f"e8_scale={self.quant_config.e8_scale}"
        )
