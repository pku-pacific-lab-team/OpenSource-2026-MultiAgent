"""Module replacement utilities for the clean quantization path."""

from __future__ import annotations

from dataclasses import dataclass

import torch.nn as nn
from transformers.models.gpt_neox.modeling_gpt_neox import GPTNeoXAttention
from transformers.models.gemma3.modeling_gemma3 import Gemma3Attention
from transformers.models.llama.modeling_llama import LlamaAttention
from transformers.models.mistral.modeling_mistral import MistralAttention
from transformers.models.phi.modeling_phi import PhiAttention
from transformers.models.qwen2.modeling_qwen2 import Qwen2Attention
from transformers.models.qwen3.modeling_qwen3 import Qwen3Attention

from .config import QuantConfig
from .quant_attention import (
    QuantMistralAttention,
    QuantLlamaAttention,
    QuantGemma3Attention,
    QuantGPTNeoXAttention,
    QuantPhiAttention,
    QuantQwen2Attention,
    QuantQwen3Attention,
    QuantRotaryAttention,
)
from .quant_linear import QuantLinear


@dataclass(frozen=True)
class WrapSummary:
    linear_layers: int
    attention_layers: int


def _replace_module(model: nn.Module, name: str, module: nn.Module) -> None:
    if "." in name:
        parent_name, child_name = name.rsplit(".", 1)
        parent = model.get_submodule(parent_name)
    else:
        parent = model
        child_name = name
    setattr(parent, child_name, module)


def wrap_to_quant_model(
    model: nn.Module,
    config: QuantConfig,
    *,
    verbose: bool = True,
) -> nn.Module:
    """Replace supported rotary-model Linear/Attention modules in place.

    Linear layers are replaced first. The second pass then wraps each
    supported attention while retaining its already-quantized projections.
    ``lm_head`` remains floating point.
    """
    quant_config = QuantConfig.from_object(config)

    output_embeddings = model.get_output_embeddings()
    linear_names = [
        name
        for name, module in model.named_modules()
        if isinstance(module, nn.Linear) and module is not output_embeddings
    ]
    for name in linear_names:
        original = model.get_submodule(name)
        replacement = QuantLinear.from_original_module(
            original,
            quant_config,
            name,
        )
        _replace_module(model, name, replacement)

    attention_adapters = (
        (Qwen3Attention, QuantQwen3Attention),
        (Qwen2Attention, QuantQwen2Attention),
        (MistralAttention, QuantMistralAttention),
        (LlamaAttention, QuantLlamaAttention),
        (Gemma3Attention, QuantGemma3Attention),
        (PhiAttention, QuantPhiAttention),
        (GPTNeoXAttention, QuantGPTNeoXAttention),
    )
    attention_names = []
    for name, module in model.named_modules():
        if isinstance(module, QuantRotaryAttention):
            continue
        for original_type, replacement_type in attention_adapters:
            if isinstance(module, original_type):
                attention_names.append((name, replacement_type))
                break
    for name, replacement_type in attention_names:
        original = model.get_submodule(name)
        replacement = replacement_type.from_original_module(
            original,
            quant_config,
            name,
        )
        _replace_module(model, name, replacement)

    summary = WrapSummary(
        linear_layers=len(linear_names),
        attention_layers=len(attention_names),
    )
    model._mxint8_wrap_summary = summary
    if verbose:
        print(
            "MXINT wrapper complete: "
            f"{summary.linear_layers} Linear layers, "
            f"{summary.attention_layers} Attention layers"
        )
    return model
