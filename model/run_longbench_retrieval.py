"""LongBench-E passage retrieval sweep for quantized SF Sparse Attention."""

from __future__ import annotations

import argparse
import json
import random
import re
import time
from dataclasses import replace
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import torch
import transformers
from transformers import AutoModelForCausalLM, AutoTokenizer

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
from quant.quant_attention import QuantRotaryAttention
from quant.stats import get_sparse_attention_stats, reset_quant_stats
from quant.utils import wrap_to_quant_model


PROMPT_TEMPLATE = """Here are 30 paragraphs from Wikipedia, along with an abstract. Please determine which paragraph the abstract is from.

{context}

The following is an abstract.

{input}

Please enter the number of the paragraph that the abstract is from. The answer format must be like \"Paragraph 1\", \"Paragraph 2\", etc.

The answer is: """


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--model-path", default="Qwen/Qwen3-8B")
    parser.add_argument(
        "--dataset-file",
        type=Path,
        required=True,
        help="Path to LongBench-E passage_retrieval_en_e JSONL",
    )
    parser.add_argument(
        "--local-files-only",
        action=argparse.BooleanOptionalAction,
        default=True,
    )
    parser.add_argument("--samples-per-length-bucket", type=int, default=10)
    parser.add_argument("--max-context-tokens", type=int, default=8192)
    parser.add_argument("--max-new-tokens", type=int, default=32)
    parser.add_argument("--seed", type=int, default=42)
    add_quant_format_args(parser)
    add_sparse_attention_args(parser, multiple_topk=True)
    parser.set_defaults(w_quant_inplace=True, sf_sparse_attention=True)
    parser.add_argument(
        "--output",
        default="results/longbench_retrieval_sf_sweep.json",
    )
    args = parser.parse_args()
    validate_common_args(parser, args)
    if args.samples_per_length_bucket < 1:
        parser.error("--samples-per-length-bucket must be positive")
    if args.max_context_tokens < 512:
        parser.error("--max-context-tokens must be at least 512")
    if args.max_new_tokens < 1:
        parser.error("--max-new-tokens must be positive")
    return args


def length_bucket(length: int) -> str:
    if length < 4000:
        return "0-4k"
    if length < 8000:
        return "4-8k"
    return "8k+"


def load_stratified_rows(
    path: str | Path,
    *,
    per_bucket: int,
    seed: int,
) -> list[dict[str, Any]]:
    with Path(path).open(encoding="utf-8") as handle:
        rows = [json.loads(line) for line in handle if line.strip()]
    buckets = {"0-4k": [], "4-8k": [], "8k+": []}
    for row in rows:
        buckets[length_bucket(int(row["length"]))].append(row)
    rng = random.Random(seed)
    selected = []
    for bucket_name, bucket_rows in buckets.items():
        rng.shuffle(bucket_rows)
        if len(bucket_rows) < per_bucket:
            raise ValueError(
                f"bucket {bucket_name} has only {len(bucket_rows)} rows"
            )
        selected.extend(bucket_rows[:per_bucket])
    return selected


def retrieval_score(prediction: str, ground_truth: str) -> float:
    target_match = re.search(r"Paragraph (\d+)", ground_truth)
    if target_match is None:
        raise ValueError(f"invalid retrieval answer: {ground_truth!r}")
    numbers = re.findall(r"\d+", prediction)
    if not numbers:
        return 0.0
    target = target_match.group(1)
    return sum(number == target for number in numbers) / len(numbers)


def tokenize_prompt(tokenizer, row, max_context_tokens: int):
    prompt = PROMPT_TEMPLATE.format(
        context=row["context"],
        input=row["input"],
    )
    template_kwargs = {
        "conversation": [{"role": "user", "content": prompt}],
        "add_generation_prompt": True,
        "tokenize": True,
        "return_dict": True,
        "return_tensors": "pt",
    }
    try:
        encoded = tokenizer.apply_chat_template(
            **template_kwargs,
            enable_thinking=False,
        )
    except TypeError:
        encoded = tokenizer.apply_chat_template(**template_kwargs)
    input_ids = encoded["input_ids"]
    if input_ids.shape[-1] > max_context_tokens:
        prefix = max_context_tokens // 2
        suffix = max_context_tokens - prefix
        input_ids = torch.cat(
            (input_ids[:, :prefix], input_ids[:, -suffix:]),
            dim=-1,
        )
    return {
        "input_ids": input_ids,
        "attention_mask": torch.ones_like(input_ids),
    }


def summarize_sparse_stats(records: dict[str, Any]) -> dict[str, Any]:
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
    totals["block_sparsity_ratio"] = (
        1.0 - totals["kept_blocks"] / total_blocks
        if total_blocks
        else None
    )
    totals["block_sparsity_ratio_vs_causal"] = (
        1.0 - totals["kept_blocks"] / totals["total_causal_blocks"]
        if totals["total_causal_blocks"]
        else None
    )
    return totals


def evaluate_variant(
    model,
    tokenizer,
    rows,
    *,
    max_context_tokens: int,
    max_new_tokens: int,
) -> dict[str, Any]:
    results = []
    input_device = model.get_input_embeddings().weight.device
    torch.cuda.empty_cache()
    torch.cuda.reset_peak_memory_stats()
    torch.cuda.synchronize()
    started = time.perf_counter()
    for index, row in enumerate(rows):
        inputs = tokenize_prompt(tokenizer, row, max_context_tokens)
        prompt_tokens = int(inputs["input_ids"].shape[-1])
        inputs = {key: value.to(input_device) for key, value in inputs.items()}
        with torch.inference_mode():
            generated = model.generate(
                **inputs,
                max_new_tokens=max_new_tokens,
                do_sample=False,
                use_cache=True,
                pad_token_id=tokenizer.eos_token_id,
            )
        response_ids = generated[0, prompt_tokens:]
        prediction = tokenizer.decode(
            response_ids,
            skip_special_tokens=True,
        ).strip()
        target = row["answers"][0]
        score = retrieval_score(prediction, target)
        results.append(
            {
                "index": index,
                "id": row["_id"],
                "length": int(row["length"]),
                "length_bucket": length_bucket(int(row["length"])),
                "prompt_tokens": prompt_tokens,
                "generated_tokens": int(response_ids.numel()),
                "target": target,
                "prediction": prediction,
                "score": score,
            }
        )
    torch.cuda.synchronize()
    seconds = time.perf_counter() - started
    scores = [record["score"] for record in results]
    bucket_scores = {}
    for bucket_name in ("0-4k", "4-8k", "8k+"):
        values = [
            record["score"]
            for record in results
            if record["length_bucket"] == bucket_name
        ]
        bucket_scores[bucket_name] = sum(values) / len(values)
    return {
        "accuracy": sum(scores) / len(scores),
        "accuracy_by_length_bucket": bucket_scores,
        "seconds": seconds,
        "examples_per_second": len(results) / seconds,
        "peak_allocated_gib": torch.cuda.max_memory_allocated() / 2**30,
        "peak_reserved_gib": torch.cuda.max_memory_reserved() / 2**30,
        "examples": results,
    }


def write_json(path: str | Path, payload: dict[str, Any]) -> Path:
    output = Path(path)
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = output.with_suffix(output.suffix + ".tmp")
    with temporary.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, sort_keys=True)
        handle.write("\n")
    temporary.replace(output)
    return output


def main() -> None:
    args = parse_args()
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU is required")
    random.seed(args.seed)
    torch.manual_seed(args.seed)
    torch.cuda.manual_seed_all(args.seed)
    rows = load_stratified_rows(
        args.dataset_file,
        per_bucket=args.samples_per_length_bucket,
        seed=args.seed,
    )
    tokenizer = AutoTokenizer.from_pretrained(
        args.model_path,
        trust_remote_code=True,
        local_files_only=args.local_files_only,
    )
    model = AutoModelForCausalLM.from_pretrained(
        args.model_path,
        trust_remote_code=True,
        local_files_only=args.local_files_only,
        device_map="auto",
        dtype=torch_dtype_from_name(args.model_dtype),
        attn_implementation="eager",
    )
    model.eval()
    format_label = quant_format_label(args)
    payload = {
        "format_version": 1,
        "status": "reference_pending",
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "environment": {
            "gpu": torch.cuda.get_device_name(0),
            "torch": torch.__version__,
            "transformers": transformers.__version__,
        },
        "model": {
            "path": args.model_path,
            "model_type": model.config.model_type,
        },
        "dataset": {
            "name": "LongBench-E/passage_retrieval_en_e",
            "file": str(args.dataset_file),
            "sampling_seed": args.seed,
            "samples_per_length_bucket": args.samples_per_length_bucket,
            "examples": len(rows),
            "max_context_tokens": args.max_context_tokens,
            "max_new_tokens": args.max_new_tokens,
            "metric": "official retrieval_score",
        },
        "quant_format": format_label,
        "requested_sparse_topk_blocks": args.topk,
        "reference": None,
        "dense_fake_quant": None,
        "sparse_runs": {},
    }
    output_path = Path(args.output)

    reset_quant_stats()
    payload["reference"] = evaluate_variant(
        model,
        tokenizer,
        rows,
        max_context_tokens=args.max_context_tokens,
        max_new_tokens=args.max_new_tokens,
    )
    payload["status"] = "reference_complete"
    write_json(output_path, payload)
    print(f"Reference accuracy: {payload['reference']['accuracy']:.3%}")

    dense_config = QuantConfig(**quant_config_kwargs(args))
    wrap_to_quant_model(model, dense_config)
    model.eval()
    reset_quant_stats()
    payload["dense_fake_quant"] = evaluate_variant(
        model,
        tokenizer,
        rows,
        max_context_tokens=args.max_context_tokens,
        max_new_tokens=args.max_new_tokens,
    )
    payload["dense_config"] = dense_config.to_dict()
    payload["status"] = "dense_complete"
    write_json(output_path, payload)
    print(
        f"Dense {format_label} accuracy: "
        f"{payload['dense_fake_quant']['accuracy']:.3%}"
    )

    sparse_modules = [
        module
        for module in model.modules()
        if isinstance(module, QuantRotaryAttention)
    ]
    if not sparse_modules:
        raise RuntimeError("no supported quantized attention layers found")
    for topk in args.topk:
        sparse_config = replace(
            dense_config,
            **sparse_config_kwargs(args, topk=topk),
        )
        for module in sparse_modules:
            module.quant_config = sparse_config
            module.stored_attention_map = None
        reset_quant_stats()
        result = evaluate_variant(
            model,
            tokenizer,
            rows,
            max_context_tokens=args.max_context_tokens,
            max_new_tokens=args.max_new_tokens,
        )
        result["config"] = sparse_config.to_dict()
        result["aggregate_sparse_stats"] = summarize_sparse_stats(
            get_sparse_attention_stats()
        )
        payload["sparse_runs"][f"topk_{topk}"] = result
        payload["status"] = f"topk_{topk}_complete"
        payload["generated_at_utc"] = datetime.now(timezone.utc).isoformat()
        write_json(output_path, payload)
        print(
            f"TopK={topk}: accuracy={result['accuracy']:.3%}, "
            "block sparsity="
            f"{result['aggregate_sparse_stats']['block_sparsity_ratio']:.3%}"
        )
    payload["status"] = "complete"
    payload["generated_at_utc"] = datetime.now(timezone.utc).isoformat()
    write_json(output_path, payload)
    print(f"Results: {output_path}")


if __name__ == "__main__":
    main()
