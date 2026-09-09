"""Compare a floating reference and configurable MXINT fake quantization."""

from __future__ import annotations

import argparse
import json
import random
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import numpy as np
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer

from eval.data import (
    add_dataset_args,
    dataset_id_from_args,
    load_text_blocks_from_args,
)
from eval.ppl import evaluate_model
from quant.cli import (
    add_quant_format_args,
    add_sparse_attention_args,
    quant_config_kwargs,
    quant_format_label,
    sparse_config_kwargs,
    torch_dtype_from_name,
    validate_common_args,
)
from quant.config import QuantConfig
from quant.plotting import plot_attention_maps, plot_quant_stats
from quant.stats import (
    get_quant_stats,
    get_sparse_attention_stats,
    reset_quant_stats,
    save_quant_stats,
)
from quant.utils import wrap_to_quant_model


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--model-path", default="Qwen/Qwen3-8B")
    parser.add_argument(
        "--local-files-only",
        action=argparse.BooleanOptionalAction,
        default=False,
    )
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--seqlen", type=int, default=2048)
    parser.add_argument("--nsamples", type=int, default=5)
    parser.add_argument("--batch-size", type=int, default=1)
    add_dataset_args(parser)
    add_quant_format_args(parser)
    add_sparse_attention_args(parser)

    parser.add_argument("--kl-topk", type=int, default=100)
    parser.add_argument(
        "--metrics-output",
        default="results/ppl_metrics.json",
    )
    parser.add_argument("--collect-stats", action="store_true")
    parser.add_argument(
        "--stats-output",
        default="results/ppl_quant_stats.json",
    )
    parser.add_argument("--plot-all-stats", action="store_true")
    parser.add_argument("--plot-sf-distribution", action="store_true")
    parser.add_argument("--plot-bit-distribution", action="store_true")
    parser.add_argument("--plot-qkv-distribution", action="store_true")
    parser.add_argument("--plot-weight-int-distribution", action="store_true")
    parser.add_argument("--plot-quant-error", action="store_true")
    parser.add_argument("--plot-per-layer", action="store_true")
    parser.add_argument("--plot-attention-maps", action="store_true")
    parser.add_argument("--plot-output-dir", default="results/plots")
    parser.add_argument("--attention-map-max-tokens", type=int, default=256)
    parser.add_argument("--attention-map-max-heads", type=int, default=4)
    args = parser.parse_args()
    validate_common_args(parser, args)
    if args.nsamples < 0:
        parser.error("--nsamples must be zero or positive")
    if args.dataset_max_documents < 0:
        parser.error("--dataset-max-documents must be zero or positive")
    if args.dataset_blocks_per_document < 0:
        parser.error(
            "--dataset-blocks-per-document must be zero or positive"
        )
    if args.dataset_streaming and args.dataset_max_documents == 0:
        parser.error(
            "--dataset-streaming requires --dataset-max-documents > 0"
        )
    if args.kl_topk < 0:
        parser.error("--kl-topk must be zero or positive")
    return args


def set_seed(seed: int) -> None:
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    torch.cuda.manual_seed_all(seed)


def _quant_plot_requested(args: argparse.Namespace) -> bool:
    return args.plot_all_stats or any(
        (
            args.plot_sf_distribution,
            args.plot_bit_distribution,
            args.plot_qkv_distribution,
            args.plot_weight_int_distribution,
            args.plot_quant_error,
            args.plot_per_layer,
        )
    )


def make_quant_config(args: argparse.Namespace) -> QuantConfig:
    return QuantConfig(
        **quant_config_kwargs(args),
        **sparse_config_kwargs(args),
        collect_stats=args.collect_stats or _quant_plot_requested(args),
        capture_attention_maps=args.plot_attention_maps,
        attention_map_max_tokens=args.attention_map_max_tokens,
        attention_map_max_heads=args.attention_map_max_heads,
    )


def _write_json_atomic(path: str | Path, payload: dict[str, Any]) -> Path:
    output_path = Path(path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    temporary_path = output_path.with_suffix(output_path.suffix + ".tmp")
    with temporary_path.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, sort_keys=True)
        handle.write("\n")
    temporary_path.replace(output_path)
    return output_path


def main() -> None:
    args = parse_args()
    set_seed(args.seed)
    quant_config = make_quant_config(args)
    reference_label = {
        "bfloat16": "BF16",
        "float16": "FP16",
        "float32": "FP32",
    }[args.model_dtype]

    tokenizer = AutoTokenizer.from_pretrained(
        args.model_path,
        trust_remote_code=True,
        add_bos_token=False,
        local_files_only=args.local_files_only,
    )
    token_blocks = load_text_blocks_from_args(tokenizer, args)
    print(f"Evaluation token blocks: {tuple(token_blocks.shape)}")

    model = AutoModelForCausalLM.from_pretrained(
        args.model_path,
        trust_remote_code=True,
        local_files_only=args.local_files_only,
        device_map="auto",
        dtype=torch_dtype_from_name(args.model_dtype),
        attn_implementation="eager",
    )
    model.eval()
    bf16_metrics, bf16_topk = evaluate_model(
        model,
        token_blocks,
        batch_size=args.batch_size,
        description=f"{reference_label} reference",
        cache_reference_topk=args.kl_topk,
    )

    reset_quant_stats()
    wrap_to_quant_model(model, quant_config)
    model.eval()
    format_label = quant_format_label(args)
    quant_variant = f"{format_label} fake-quant"
    if quant_config.attention_hadamard:
        quant_variant += " + Attention Hadamard"
    if quant_config.sf_sparse_enabled:
        quant_variant += " + SF Sparse"
    quant_metrics, _ = evaluate_model(
        model,
        token_blocks,
        batch_size=args.batch_size,
        description=quant_variant,
        reference_topk=bf16_topk if args.kl_topk > 0 else None,
    )

    relative_change = (
        quant_metrics.ppl / bf16_metrics.ppl - 1.0
    ) * 100.0
    loss_delta = quant_metrics.loss - bf16_metrics.loss
    sparse_stats = get_sparse_attention_stats()
    print("\nEvaluation results")
    print(f"  Predicted tokens:       {quant_metrics.predicted_tokens}")
    print(f"  {reference_label} loss:              {bf16_metrics.loss:.6f}")
    print(f"  {reference_label} PPL:               {bf16_metrics.ppl:.6f}")
    print(f"  {quant_variant} loss: {quant_metrics.loss:.6f}")
    print(f"  {quant_variant} PPL:  {quant_metrics.ppl:.6f}")
    print(f"  Loss delta:             {loss_delta:+.6f}")
    print(f"  Relative PPL change:    {relative_change:+.3f}%")
    if quant_metrics.topk_renormalized_kl_nats is not None:
        print(
            f"  Top-{quant_metrics.reference_topk} renorm KL:     "
            f"{quant_metrics.topk_renormalized_kl_nats:.9f} nats"
        )
        print(
            f"  {reference_label} top-1 agreement:   "
            f"{quant_metrics.reference_top1_agreement:.3%}"
        )
    if sparse_stats:
        total_blocks = sum(
            record["total_valid_blocks"] for record in sparse_stats.values()
        )
        kept_blocks = sum(
            record["kept_blocks"] for record in sparse_stats.values()
        )
        dense_pairs = sum(
            record["dense_qk_pairs"] for record in sparse_stats.values()
        )
        executed_pairs = sum(
            record["executed_qk_pairs"] for record in sparse_stats.values()
        )
        fallback_calls = sum(
            record["fallback_calls"] for record in sparse_stats.values()
        )
        if total_blocks:
            print(
                "  SF kept-block ratio:    "
                f"{kept_blocks / total_blocks:.3%}"
            )
        if dense_pairs:
            print(
                "  Selected QK pair ratio: "
                f"{executed_pairs / dense_pairs:.3%}"
            )
        print(f"  Sparse fallback calls:  {fallback_calls}")

    report = {
        "format_version": 2,
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "model_path": args.model_path,
        "dataset": dataset_id_from_args(args),
        "dataset_config": {
            "path": args.dataset_path,
            "name": args.dataset_name,
            "split": args.dataset_split,
            "text_column": args.dataset_text_column,
            "data_files": args.dataset_data_files,
            "streaming": args.dataset_streaming,
            "max_documents": args.dataset_max_documents,
            "blocks_per_document": args.dataset_blocks_per_document,
        },
        "seqlen": args.seqlen,
        "nsamples": int(token_blocks.shape[0]),
        "batch_size": args.batch_size,
        "quant_config": quant_config.to_dict(),
        "evaluated_variant": quant_variant,
        "definitions": {
            "predicted_tokens_per_block": "seqlen - 1",
            "loss": "sum(batch_loss * B * (S - 1)) / total_predicted_tokens",
            "ppl": "exp(loss)",
            "relative_ppl_change_percent": (
                "(quant_ppl / reference_ppl - 1) * 100"
            ),
            "topk_renormalized_kl": (
                "mean over predicted positions of KL(reference || quant), "
                "after restricting both distributions to reference-selected top-k ids "
                "and renormalizing; this is not full-vocabulary KL"
            ),
        },
        "reference": {
            "dtype": reference_label,
            "metrics": bf16_metrics.to_dict(),
        },
        "quantized": quant_metrics.to_dict(),
        "comparison": {
            "loss_delta": loss_delta,
            "relative_ppl_change_percent": relative_change,
        },
        "sparse_attention": sparse_stats,
    }
    metrics_path = _write_json_atomic(args.metrics_output, report)
    print(f"  Evaluation report:      {metrics_path}")

    if quant_config.collect_stats:
        stats_path = save_quant_stats(
            args.stats_output,
            config=quant_config.to_dict(),
            metadata={
                "model_path": args.model_path,
                "dataset": dataset_id_from_args(args),
                "mode": "ppl",
                "evaluated_variant": quant_variant,
                "seqlen": args.seqlen,
                "nsamples": int(token_blocks.shape[0]),
                "reference": {
                    "dtype": reference_label,
                    "metrics": bf16_metrics.to_dict(),
                },
                "quantized": quant_metrics.to_dict(),
                "loss_delta": loss_delta,
                "relative_ppl_change_percent": relative_change,
            },
        )
        print(f"  Quant statistics:       {stats_path}")

    if _quant_plot_requested(args):
        all_plots = args.plot_all_stats
        plot_paths = plot_quant_stats(
            {
                "records": get_quant_stats(),
                "sparse_attention": sparse_stats,
            },
            args.plot_output_dir,
            plot_sf_distribution=all_plots or args.plot_sf_distribution,
            plot_bit_distribution=all_plots or args.plot_bit_distribution,
            plot_qkv_distribution=all_plots or args.plot_qkv_distribution,
            plot_weight_int_distribution=(
                all_plots or args.plot_weight_int_distribution
            ),
            plot_quant_error=all_plots or args.plot_quant_error,
            per_layer=args.plot_per_layer,
        )
        print(f"  Quant plots:            {len(plot_paths)} in {args.plot_output_dir}")

    if args.plot_attention_maps:
        attention_paths = plot_attention_maps(model, args.plot_output_dir)
        print(
            f"  Attention-map plots:    {len(attention_paths)} in "
            f"{Path(args.plot_output_dir) / 'attention_maps'}"
        )


if __name__ == "__main__":
    main()
