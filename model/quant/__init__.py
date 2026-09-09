"""Minimal inference-only MXINT8 fake-quantization package."""

from .config import QuantConfig
from .quant_func import int_quant
from .hadamard import (
    compensate_output_projection_weight_,
    hadamard_block_sizes,
    randomized_hadamard_matrix,
    right_rotate_head_dim,
)
from .quant_linear import QuantLinear
from .plotting import plot_attention_maps, plot_quant_stats, plot_quant_stats_file
from .sparse_attention import (
    SFBlockSelection,
    build_sf_topk_selection,
    causal_topk_block_selection,
    pool_token_scales,
    sf_block_scores,
)
from .stats import (
    get_quant_stats,
    get_sparse_attention_stats,
    reset_quant_stats,
    save_quant_stats,
)

__all__ = [
    "QuantConfig",
    "QuantLinear",
    "SFBlockSelection",
    "build_sf_topk_selection",
    "causal_topk_block_selection",
    "get_quant_stats",
    "get_sparse_attention_stats",
    "hadamard_block_sizes",
    "compensate_output_projection_weight_",
    "int_quant",
    "plot_attention_maps",
    "plot_quant_stats",
    "plot_quant_stats_file",
    "pool_token_scales",
    "reset_quant_stats",
    "randomized_hadamard_matrix",
    "right_rotate_head_dim",
    "save_quant_stats",
    "sf_block_scores",
]
