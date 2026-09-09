"""Shared argparse helpers for quantization and SF Sparse experiments."""

from __future__ import annotations

import argparse
from typing import Any

import torch


_BIT_DESTINATIONS = (
    "weight_bits",
    "activation_bits",
    "attn_q_bits",
    "attn_k_bits",
    "attn_p_bits",
    "attn_v_bits",
)


def add_quant_format_args(parser: argparse.ArgumentParser) -> None:
    """Add fully externalized MXINT fake-quantization format arguments."""
    parser.add_argument(
        "--mxint-bits",
        "--bits",
        dest="mxint_bits",
        type=int,
        default=8,
        help="Default integer-code width inherited by unspecified tensors",
    )
    parser.add_argument("--weight-bits", type=int)
    parser.add_argument("--activation-bits", type=int)
    parser.add_argument("--attn-q-bits", type=int)
    parser.add_argument("--attn-k-bits", type=int)
    parser.add_argument("--attn-p-bits", type=int)
    parser.add_argument("--attn-v-bits", type=int)
    parser.add_argument("--group-size", type=int, default=32)
    parser.add_argument(
        "--quant-type",
        choices=("int",),
        default="int",
    )
    parser.add_argument(
        "--e8-scale",
        action=argparse.BooleanOptionalAction,
        default=True,
    )
    parser.add_argument(
        "--e8-scale-op",
        choices=("ceil", "floor", "round", "ocp"),
        default="ceil",
    )
    parser.add_argument(
        "--clip-style",
        choices=("sym", "asym"),
        default="sym",
    )
    parser.add_argument(
        "--model-dtype",
        choices=("bfloat16", "float16", "float32"),
        default="bfloat16",
    )
    parser.add_argument(
        "--w-quant-inplace",
        action=argparse.BooleanOptionalAction,
        default=False,
    )
    parser.add_argument(
        "--attention-hadamard",
        action=argparse.BooleanOptionalAction,
        default=False,
        help=(
            "Rotate Q/K by the same per-head orthogonal matrix and rotate V "
            "with compensation in the O projection"
        ),
    )
    parser.add_argument(
        "--attention-hadamard-seed",
        type=int,
        default=0,
        help="Base seed for deterministic per-layer Q/K and V rotations",
    )


def add_sparse_attention_args(
    parser: argparse.ArgumentParser,
    *,
    multiple_topk: bool = False,
) -> None:
    """Add one canonical top-level Top-K plus SF Sparse controls."""
    parser.add_argument("--sf-sparse-attention", action="store_true")
    topk_kwargs: dict[str, Any] = {
        "dest": "topk",
        "type": int,
        "default": [8] if multiple_topk else 8,
        "help": "Causal key-block budget; includes forced blocks",
    }
    if multiple_topk:
        topk_kwargs["nargs"] = "+"
    parser.add_argument(
        "--topk",
        "--sf-sparse-topk-blocks",
        "--sparse-topk-blocks",
        **topk_kwargs,
    )
    parser.add_argument(
        "--sf-sparse-block-size",
        "--sparse-block-size",
        dest="sf_sparse_block_size",
        type=int,
        default=32,
    )
    parser.add_argument(
        "--sf-sparse-reduction",
        "--sparse-reduction",
        dest="sf_sparse_reduction",
        choices=("mean", "sum"),
        default="mean",
    )
    parser.add_argument(
        "--sf-sparse-force-first-block",
        action=argparse.BooleanOptionalAction,
        default=True,
    )
    parser.add_argument(
        "--sf-sparse-force-diagonal-block",
        action=argparse.BooleanOptionalAction,
        default=True,
    )
    parser.add_argument(
        "--sf-sparse-dense-fallback",
        action=argparse.BooleanOptionalAction,
        default=True,
    )


def resolved_quant_bits(args: argparse.Namespace) -> dict[str, int]:
    """Resolve per-tensor overrides against the top-level MXINT width."""
    return {
        destination: (
            args.mxint_bits
            if getattr(args, destination) is None
            else getattr(args, destination)
        )
        for destination in _BIT_DESTINATIONS
    }


def quant_config_kwargs(args: argparse.Namespace) -> dict[str, Any]:
    """Return QuantConfig fields controlled by the common CLI."""
    bits = resolved_quant_bits(args)
    return {
        "quant_type": args.quant_type,
        "q1_w": bits["weight_bits"],
        "q1_x": bits["activation_bits"],
        "group_size": args.group_size,
        "clip_style": args.clip_style,
        "e8_scale": args.e8_scale,
        "e8_scale_op": args.e8_scale_op,
        "w_quant_inplace": args.w_quant_inplace,
        "attention_hadamard": args.attention_hadamard,
        "attention_hadamard_seed": args.attention_hadamard_seed,
        "attn_q_bits": bits["attn_q_bits"],
        "attn_k_bits": bits["attn_k_bits"],
        "attn_p_bits": bits["attn_p_bits"],
        "attn_v_bits": bits["attn_v_bits"],
    }


def sparse_config_kwargs(
    args: argparse.Namespace,
    *,
    topk: int | None = None,
) -> dict[str, Any]:
    """Return QuantConfig fields controlled by the SF Sparse CLI."""
    configured_topk = args.topk if topk is None else topk
    if isinstance(configured_topk, list):
        if len(configured_topk) != 1:
            raise ValueError("a single Top-K value is required here")
        configured_topk = configured_topk[0]
    return {
        "sf_sparse_enabled": args.sf_sparse_attention,
        "sf_sparse_block_size": args.sf_sparse_block_size,
        "sf_sparse_topk_blocks": configured_topk,
        "sf_sparse_reduction": args.sf_sparse_reduction,
        "sf_sparse_force_first_block": args.sf_sparse_force_first_block,
        "sf_sparse_force_diagonal_block": (
            args.sf_sparse_force_diagonal_block
        ),
        "sf_sparse_dense_fallback": args.sf_sparse_dense_fallback,
    }


def validate_common_args(
    parser: argparse.ArgumentParser,
    args: argparse.Namespace,
) -> None:
    """Report common format/Top-K mistakes as argparse errors."""
    bits = resolved_quant_bits(args)
    if any(bit < 2 for bit in bits.values()):
        parser.error("all quantization bit widths must be at least 2")
    if args.group_size == 0 or args.group_size < -1:
        parser.error("--group-size must be -1 or a positive integer")
    if args.attention_hadamard_seed < 0:
        parser.error("--attention-hadamard-seed must be non-negative")
    topk_values = args.topk if isinstance(args.topk, list) else [args.topk]
    if any(value < 1 for value in topk_values):
        parser.error("--topk values must be positive")
    args.topk = list(dict.fromkeys(topk_values)) if isinstance(
        args.topk, list
    ) else args.topk


def torch_dtype_from_name(name: str) -> torch.dtype:
    return {
        "bfloat16": torch.bfloat16,
        "float16": torch.float16,
        "float32": torch.float32,
    }[name]


def quant_format_label(args: argparse.Namespace) -> str:
    bits = resolved_quant_bits(args)
    unique_bits = set(bits.values())
    if len(unique_bits) == 1:
        return f"MXINT{next(iter(unique_bits))}"
    assignments = ",".join(
        f"{name.removesuffix('_bits')}={value}"
        for name, value in bits.items()
    )
    return f"Mixed-MXINT({assignments})"
