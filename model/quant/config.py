"""Configuration for the inference-only MXINT8 fake-quantization path."""

from __future__ import annotations

from dataclasses import asdict, dataclass, fields
from typing import Any


@dataclass(frozen=True)
class QuantConfig:
    """Dense MXINT8 fake-quantization settings.

    The names intentionally match the original experiment scripts where useful,
    so an ``argparse.Namespace`` from the old code can still be converted.
    """

    quant_type: str = "int"
    q1_w: int = 8
    q1_x: int = 8
    group_size: int = 32
    clip_style: str = "sym"
    e8_scale: bool = True
    e8_scale_op: str = "ceil"
    w_quant_inplace: bool = False
    attention_hadamard: bool = False
    attention_hadamard_seed: int = 0
    collect_stats: bool = False
    capture_attention_maps: bool = False
    attention_map_max_tokens: int = 256
    attention_map_max_heads: int = 4

    sf_sparse_enabled: bool = False
    sf_sparse_block_size: int = 32
    sf_sparse_topk_blocks: int = 8
    sf_sparse_reduction: str = "mean"
    sf_sparse_force_first_block: bool = True
    sf_sparse_force_diagonal_block: bool = True
    sf_sparse_dense_fallback: bool = True

    attn_q_bits: int = 8
    attn_k_bits: int = 8
    attn_p_bits: int = 8
    attn_v_bits: int = 8

    def __post_init__(self) -> None:
        if self.quant_type != "int":
            raise ValueError(
                "The clean baseline supports quant_type='int' only"
            )
        for name in (
            "q1_w",
            "q1_x",
            "attn_q_bits",
            "attn_k_bits",
            "attn_p_bits",
            "attn_v_bits",
        ):
            bit = getattr(self, name)
            if not isinstance(bit, int):
                raise TypeError(f"{name} must be int, got {type(bit).__name__}")
            if bit < 2:
                raise ValueError(f"{name} must be at least 2, got {bit}")
        if self.group_size == 0 or self.group_size < -1:
            raise ValueError("group_size must be -1 or a positive integer")
        if self.clip_style not in {"sym", "asym"}:
            raise ValueError("clip_style must be 'sym' or 'asym'")
        if self.e8_scale_op not in {"ceil", "floor", "round", "ocp"}:
            raise ValueError(
                "e8_scale_op must be one of: ceil, floor, round, ocp"
            )
        if self.attention_hadamard_seed < 0:
            raise ValueError("attention_hadamard_seed must be non-negative")
        for name in ("attention_map_max_tokens", "attention_map_max_heads"):
            value = getattr(self, name)
            if value == 0 or value < -1:
                raise ValueError(f"{name} must be -1 or a positive integer")
        if self.sf_sparse_block_size < 1:
            raise ValueError("sf_sparse_block_size must be positive")
        if self.sf_sparse_topk_blocks < 1:
            raise ValueError("sf_sparse_topk_blocks must be positive")
        if self.sf_sparse_reduction not in {"mean", "sum"}:
            raise ValueError("sf_sparse_reduction must be 'mean' or 'sum'")
        if (
            self.sf_sparse_force_first_block
            and self.sf_sparse_force_diagonal_block
            and self.sf_sparse_topk_blocks < 2
        ):
            raise ValueError(
                "sf_sparse_topk_blocks must be at least 2 when first and "
                "diagonal blocks are both forced"
            )
        if self.sf_sparse_enabled and (
            self.attn_q_bits >= 16 or self.attn_k_bits >= 16
        ):
            raise ValueError(
                "SF Sparse Attention requires quantized Q/K with bits < 16"
            )

    @classmethod
    def from_object(cls, config: Any) -> "QuantConfig":
        """Copy supported fields from another config object or namespace."""
        if isinstance(config, cls):
            return config
        values = {}
        for field in fields(cls):
            if hasattr(config, field.name):
                values[field.name] = getattr(config, field.name)
        return cls(**values)

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)
