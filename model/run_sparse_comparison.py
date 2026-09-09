"""One-process dense-MXINT versus SF-Sparse full PPL benchmark."""

from __future__ import annotations

import argparse
import json
import random
import time
from dataclasses import replace
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import numpy as np
import torch
import transformers
from transformers import AutoModelForCausalLM, AutoTokenizer

from eval.data import (
    add_dataset_args,
    dataset_id_from_args,
    load_text_blocks_from_args,
)
from eval.ppl import EvaluationMetrics, evaluate_model
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
from quant.hadamard import hadamard_block_sizes
from quant.quant_attention import QuantRotaryAttention
from quant.stats import get_sparse_attention_stats, reset_quant_stats
from quant.utils import wrap_to_quant_model


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--model-path", default="Qwen/Qwen3-8B")
    parser.add_argument(
        "--local-files-only",
        action=argparse.BooleanOptionalAction,
        default=True,
    )
    parser.add_argument("--seqlen", type=int, default=2048)
    parser.add_argument(
        "--nsamples",
        type=int,
        default=0,
        help="0 uses every complete block in the selected dataset text",
    )
    parser.add_argument("--batch-size", type=int, default=1)
    parser.add_argument("--seed", type=int, default=42)
    add_dataset_args(parser)
    add_quant_format_args(parser)
    add_sparse_attention_args(parser, multiple_topk=True)
    parser.set_defaults(w_quant_inplace=True, sf_sparse_attention=True)
    parser.add_argument("--kl-topk", type=int, default=100)
    parser.add_argument(
        "--output",
        default="results/full_sf_sparse_comparison.json",
    )
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


def write_json_atomic(path: str | Path, payload: dict[str, Any]) -> Path:
    output_path = Path(path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    temporary_path = output_path.with_suffix(output_path.suffix + ".tmp")
    with temporary_path.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, sort_keys=True)
        handle.write("\n")
    temporary_path.replace(output_path)
    return output_path


def warmup(model, token_blocks: torch.Tensor) -> None:
    input_device = model.get_input_embeddings().weight.device
    batch = token_blocks[:1].to(input_device)
    with torch.inference_mode():
        model(input_ids=batch, labels=batch, use_cache=False)
    torch.cuda.synchronize()


def timed_evaluation(
    model,
    token_blocks: torch.Tensor,
    *,
    batch_size: int,
    description: str,
    cache_reference_topk: int = 0,
    reference_topk=None,
) -> tuple[EvaluationMetrics, list, dict[str, float]]:
    torch.cuda.empty_cache()
    torch.cuda.reset_peak_memory_stats()
    torch.cuda.synchronize()
    start = time.perf_counter()
    metrics, cached = evaluate_model(
        model,
        token_blocks,
        batch_size=batch_size,
        description=description,
        cache_reference_topk=cache_reference_topk,
        reference_topk=reference_topk,
    )
    torch.cuda.synchronize()
    elapsed = time.perf_counter() - start
    performance = {
        "seconds": elapsed,
        "predicted_tokens_per_second": metrics.predicted_tokens / elapsed,
        "peak_allocated_gib": torch.cuda.max_memory_allocated() / 2**30,
        "peak_reserved_gib": torch.cuda.max_memory_reserved() / 2**30,
    }
    return metrics, cached, performance


def aggregate_sparse_stats(records: dict[str, Any]) -> dict[str, Any]:
    keys = (
        "calls",
        "fallback_calls",
        "total_causal_blocks",
        "total_valid_blocks",
        "kept_blocks",
        "executed_qk_pairs",
        "dense_qk_pairs",
    )
    totals = {
        key: sum(int(record[key]) for record in records.values())
        for key in keys
    }
    total_blocks = totals["total_valid_blocks"]
    total_causal_blocks = totals["total_causal_blocks"]
    dense_pairs = totals["dense_qk_pairs"]
    totals["kept_block_ratio"] = (
        totals["kept_blocks"] / total_blocks if total_blocks else None
    )
    totals["block_sparsity_ratio"] = (
        1.0 - totals["kept_block_ratio"] if total_blocks else None
    )
    totals["kept_block_ratio_vs_causal"] = (
        totals["kept_blocks"] / total_causal_blocks
        if total_causal_blocks
        else None
    )
    totals["block_sparsity_ratio_vs_causal"] = (
        1.0 - totals["kept_block_ratio_vs_causal"]
        if total_causal_blocks
        else None
    )
    totals["qk_compute_ratio"] = (
        totals["executed_qk_pairs"] / dense_pairs if dense_pairs else None
    )
    totals["qk_compute_reduction_ratio"] = (
        1.0 - totals["qk_compute_ratio"] if dense_pairs else None
    )
    return totals


def add_causal_qk_ratios(
    totals: dict[str, Any],
    *,
    samples: int,
    sequence_length: int,
    attention_heads: int,
    attention_layers: int,
) -> None:
    """Add a causal-triangle baseline alongside the dense SxS baseline."""
    causal_dense_pairs = (
        samples
        * attention_layers
        * attention_heads
        * sequence_length
        * (sequence_length + 1)
        // 2
    )
    totals["causal_dense_qk_pairs"] = causal_dense_pairs
    totals["qk_compute_ratio_vs_causal"] = (
        totals["executed_qk_pairs"] / causal_dense_pairs
        if causal_dense_pairs
        else None
    )
    totals["qk_compute_reduction_ratio_vs_causal"] = (
        1.0 - totals["qk_compute_ratio_vs_causal"]
        if causal_dense_pairs
        else None
    )


def main() -> None:
    args = parse_args()
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU is required")
    set_seed(args.seed)
    format_label = quant_format_label(args)
    dataset_id = dataset_id_from_args(args)
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
    print(f"{dataset_id} blocks: {tuple(token_blocks.shape)}")

    model = AutoModelForCausalLM.from_pretrained(
        args.model_path,
        trust_remote_code=True,
        local_files_only=args.local_files_only,
        device_map="auto",
        dtype=torch_dtype_from_name(args.model_dtype),
        attn_implementation="eager",
    )
    model.eval()

    warmup(model, token_blocks)
    bf16_metrics, reference_topk, bf16_performance = timed_evaluation(
        model,
        token_blocks,
        batch_size=args.batch_size,
        description=f"{args.model_dtype} {dataset_id}",
        cache_reference_topk=args.kl_topk,
    )
    print(
        f"{reference_label} done: PPL={bf16_metrics.ppl:.6f}, "
        f"time={bf16_performance['seconds']:.3f}s"
    )

    dense_config = QuantConfig(
        **quant_config_kwargs(args),
        collect_stats=False,
    )
    torch.cuda.synchronize()
    wrap_start = time.perf_counter()
    wrap_to_quant_model(model, dense_config)
    torch.cuda.synchronize()
    wrap_seconds = time.perf_counter() - wrap_start
    model.eval()
    reset_quant_stats()
    warmup(model, token_blocks)
    reset_quant_stats()
    dense_metrics, _, dense_performance = timed_evaluation(
        model,
        token_blocks,
        batch_size=args.batch_size,
        description=f"Dense {format_label} {dataset_id}",
        reference_topk=reference_topk if args.kl_topk > 0 else None,
    )
    print(
        f"Dense {format_label} done: PPL={dense_metrics.ppl:.6f}, "
        f"time={dense_performance['seconds']:.3f}s"
    )

    checkpoint_path = Path(args.output).with_suffix(".dense_checkpoint.json")
    write_json_atomic(
        checkpoint_path,
        {
            "format_version": 1,
            "status": "dense_complete_sparse_pending",
            "generated_at_utc": datetime.now(timezone.utc).isoformat(),
            "dataset": {
                "name": dataset_id,
                "data_files": args.dataset_data_files,
                "seqlen": args.seqlen,
                "blocks": int(token_blocks.shape[0]),
                "predicted_tokens": int(
                    token_blocks.shape[0] * (token_blocks.shape[1] - 1)
                ),
            },
            "dense_config": dense_config.to_dict(),
            "weight_prequantization_seconds": wrap_seconds,
            "reference": {
                "dtype": reference_label,
                "metrics": bf16_metrics.to_dict(),
                "performance": bf16_performance,
            },
            "dense_fake_quant": {
                "metrics": dense_metrics.to_dict(),
                "performance": dense_performance,
            },
        },
    )
    print(f"Dense checkpoint: {checkpoint_path}")

    sparse_modules = [
        module
        for module in model.modules()
        if isinstance(module, QuantRotaryAttention)
    ]
    if not sparse_modules:
        raise RuntimeError(
            "no supported quantized rotary attention layers found"
        )
    head_dim = int(sparse_modules[0].head_dim)
    payload: dict[str, Any] = {
        "format_version": 3,
        "status": "sparse_sweep_pending",
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "environment": {
            "gpu": torch.cuda.get_device_name(0),
            "torch": torch.__version__,
            "transformers": transformers.__version__,
        },
        "model": {
            "path": args.model_path,
            "model_type": model.config.model_type,
            "parameters": sum(parameter.numel() for parameter in model.parameters()),
            "attention_layers": len(sparse_modules),
            "attention_heads": int(model.config.num_attention_heads),
            "head_dim": head_dim,
            "attention_hadamard_blocks": (
                list(hadamard_block_sizes(head_dim))
                if args.attention_hadamard
                else []
            ),
        },
        "dataset": {
            "name": dataset_id,
            "path": args.dataset_path,
            "config_name": args.dataset_name,
            "split": args.dataset_split,
            "text_column": args.dataset_text_column,
            "data_files": args.dataset_data_files,
            "streaming": args.dataset_streaming,
            "max_documents": args.dataset_max_documents,
            "blocks_per_document": args.dataset_blocks_per_document,
            "seqlen": args.seqlen,
            "blocks": int(token_blocks.shape[0]),
            "predicted_tokens": int(
                token_blocks.shape[0] * (token_blocks.shape[1] - 1)
            ),
        },
        "quant_format": format_label,
        "dense_config": dense_config.to_dict(),
        "requested_sparse_topk_blocks": args.topk,
        "weight_prequantization_seconds": wrap_seconds,
        "reference": {
            "dtype": reference_label,
            "metrics": bf16_metrics.to_dict(),
            "performance": bf16_performance,
        },
        "dense_fake_quant": {
            "metrics": dense_metrics.to_dict(),
            "performance": dense_performance,
        },
        "sparse_runs": {},
        "comparisons": {},
    }
    output_path = Path(args.output)

    for topk_blocks in args.topk:
        sparse_config = replace(
            dense_config,
            **sparse_config_kwargs(args, topk=topk_blocks),
        )
        for module in sparse_modules:
            module.quant_config = sparse_config
            module.stored_attention_map = None

        reset_quant_stats()
        warmup(model, token_blocks)
        reset_quant_stats()
        sparse_metrics, _, sparse_performance = timed_evaluation(
            model,
            token_blocks,
            batch_size=args.batch_size,
            description=f"{format_label} + SF Sparse TopK={topk_blocks}",
            reference_topk=reference_topk if args.kl_topk > 0 else None,
        )
        sparse_records = get_sparse_attention_stats()
        sparse_totals = aggregate_sparse_stats(sparse_records)
        add_causal_qk_ratios(
            sparse_totals,
            samples=int(token_blocks.shape[0]),
            sequence_length=int(token_blocks.shape[1]),
            attention_heads=int(model.config.num_attention_heads),
            attention_layers=len(sparse_modules),
        )

        comparison = {
            "sparse_minus_dense_loss": (
                sparse_metrics.loss - dense_metrics.loss
            ),
            "sparse_vs_dense_ppl_change_percent": (
                sparse_metrics.ppl / dense_metrics.ppl - 1.0
            ) * 100.0,
            "sparse_vs_dense_speedup": (
                dense_performance["seconds"] / sparse_performance["seconds"]
            ),
            "sparse_minus_dense_peak_allocated_gib": (
                sparse_performance["peak_allocated_gib"]
                - dense_performance["peak_allocated_gib"]
            ),
            "sparse_minus_dense_topk_kl_nats": (
                sparse_metrics.topk_renormalized_kl_nats
                - dense_metrics.topk_renormalized_kl_nats
                if sparse_metrics.topk_renormalized_kl_nats is not None
                and dense_metrics.topk_renormalized_kl_nats is not None
                else None
            ),
        }
        run_key = f"topk_{topk_blocks}"
        payload["sparse_runs"][run_key] = {
            "config": sparse_config.to_dict(),
            "metrics": sparse_metrics.to_dict(),
            "performance": sparse_performance,
            "aggregate_sparse_stats": sparse_totals,
            "per_layer_sparse_stats": sparse_records,
        }
        payload["comparisons"][run_key] = comparison
        payload["status"] = f"{run_key}_complete"
        payload["generated_at_utc"] = datetime.now(timezone.utc).isoformat()
        write_json_atomic(output_path, payload)
        print(
            f"TopK={topk_blocks} done: PPL={sparse_metrics.ppl:.6f}, "
            f"block sparsity={sparse_totals['block_sparsity_ratio']:.3%}, "
            f"time={sparse_performance['seconds']:.3f}s"
        )

    payload["status"] = "complete"
    payload["generated_at_utc"] = datetime.now(timezone.utc).isoformat()
    output_path = write_json_atomic(output_path, payload)
    print(f"\nFull {format_label} SF Top-K sweep")
    print(f"  {reference_label} PPL:         {bf16_metrics.ppl:.6f}")
    print(f"  Dense {format_label} PPL: {dense_metrics.ppl:.6f}")
    print("  TopK | block sparsity | PPL       | vs dense | seconds  | speedup")
    for topk_blocks in args.topk:
        run_key = f"topk_{topk_blocks}"
        run = payload["sparse_runs"][run_key]
        comparison = payload["comparisons"][run_key]
        print(
            f"  {topk_blocks:4d} | "
            f"{run['aggregate_sparse_stats']['block_sparsity_ratio']:14.3%} | "
            f"{run['metrics']['ppl']:9.6f} | "
            f"{comparison['sparse_vs_dense_ppl_change_percent']:+8.3f}% | "
            f"{run['performance']['seconds']:8.3f} | "
            f"{comparison['sparse_vs_dense_speedup']:7.3f}x"
        )
    print(f"  Results: {output_path}")


if __name__ == "__main__":
    main()
