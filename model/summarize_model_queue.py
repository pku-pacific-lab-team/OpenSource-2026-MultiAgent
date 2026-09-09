"""Validate and summarize completed cross-model queue results."""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parent
DEFAULT_RESULTS_DIR = ROOT / "results" / "model_queue_ceil_20260901"
DEFAULT_MANIFEST = ROOT / "configs" / "scale_model_queue.json"
TOPK_VALUES = (32, 40)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--results-dir", type=Path, default=DEFAULT_RESULTS_DIR)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--csv-output", type=Path)
    parser.add_argument("--markdown-output", type=Path)
    return parser.parse_args()


def load_json(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def write_text_atomic(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary_path = path.with_suffix(path.suffix + ".tmp")
    temporary_path.write_text(text, encoding="utf-8")
    temporary_path.replace(path)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def validate_report(
    report: dict[str, Any],
    *,
    model_id: str,
    quant_format: str,
    hadamard: bool,
) -> None:
    require(report.get("status") == "complete", "report is not complete")
    require(report["model"]["path"] == model_id, "model path mismatch")
    require(report["quant_format"] == quant_format, "quant format mismatch")
    require(report["dataset"]["seqlen"] == 2048, "seqlen is not 2048")
    require(report["dataset"]["blocks"] == 64, "block count is not 64")
    require(
        report["dataset"]["name"] == "wikitext/wikitext-2-raw-v1:test",
        "dataset mismatch",
    )
    config = report["dense_config"]
    require(config["e8_scale_op"] == "ceil", "scale op is not ceil")
    require(config["group_size"] == 32, "group size is not 32")
    require(
        config["attention_hadamard"] is hadamard,
        "Hadamard setting mismatch",
    )
    for topk in TOPK_VALUES:
        run = report["sparse_runs"][f"topk_{topk}"]
        require(
            run["aggregate_sparse_stats"]["fallback_calls"] == 0,
            f"TopK={topk} used dense fallback",
        )


def pct_change(value: float, baseline: float) -> float:
    return (value / baseline - 1.0) * 100.0


def add_format_fields(
    row: dict[str, Any],
    report: dict[str, Any],
    prefix: str,
) -> None:
    bf16_ppl = report["reference"]["metrics"]["ppl"]
    dense_ppl = report["dense_fake_quant"]["metrics"]["ppl"]
    row[f"{prefix}_dense_ppl"] = dense_ppl
    row[f"{prefix}_dense_vs_bf16_percent"] = pct_change(
        dense_ppl, bf16_ppl
    )
    for topk in TOPK_VALUES:
        run = report["sparse_runs"][f"topk_{topk}"]
        metrics = run["metrics"]
        stats = run["aggregate_sparse_stats"]
        row[f"{prefix}_k{topk}_ppl"] = metrics["ppl"]
        row[f"{prefix}_k{topk}_vs_dense_percent"] = pct_change(
            metrics["ppl"], dense_ppl
        )
        row[f"{prefix}_k{topk}_block_sparsity_percent"] = (
            stats["block_sparsity_ratio"] * 100.0
        )
        row[f"{prefix}_k{topk}_qk_reduction_vs_causal_percent"] = (
            stats["qk_compute_reduction_ratio_vs_causal"] * 100.0
        )
        row[f"{prefix}_k{topk}_fallback_calls"] = stats["fallback_calls"]


def collect_rows(
    results_dir: Path, manifest: dict[str, Any]
) -> list[dict[str, Any]]:
    state = load_json(results_dir / "queue_state.json")
    require(state["status"] == "complete", "queue is not complete")
    require(state["e8_scale_op"] == "ceil", "queue scale op is not ceil")
    supported_models = [
        model for model in manifest["models"] if model["status"] == "supported"
    ]
    manifest_models = {model["slug"]: model for model in supported_models}
    require(
        len(state["model_order"]) == len(manifest_models)
        and set(state["model_order"]) == set(manifest_models),
        "queue model set does not match supported manifest models",
    )

    rows: list[dict[str, Any]] = []
    for model in supported_models:
        slug = model["slug"]
        int8_report = load_json(results_dir / slug / "full_int8.json")
        int4_report = load_json(
            results_dir / slug / "full_int4_hadamard.json"
        )
        validate_report(
            int8_report,
            model_id=model["model_id"],
            quant_format="MXINT8",
            hadamard=False,
        )
        validate_report(
            int4_report,
            model_id=model["model_id"],
            quant_format="MXINT4",
            hadamard=True,
        )
        int8_bf16 = int8_report["reference"]["metrics"]["ppl"]
        int4_bf16 = int4_report["reference"]["metrics"]["ppl"]
        require(abs(int8_bf16 - int4_bf16) < 1e-9, "BF16 PPL mismatch")
        row: dict[str, Any] = {
            "model_slug": slug,
            "family": model["family"],
            "requested_model_id": model["requested_model_id"],
            "evaluated_model_id": model["model_id"],
            "parameters_b": model["parameters_b"],
            "attention_layers": int8_report["model"]["attention_layers"],
            "bf16_ppl": int8_bf16,
        }
        add_format_fields(row, int8_report, "mxint8")
        add_format_fields(row, int4_report, "mxint4_hadamard")
        rows.append(row)
    return rows


def write_csv(path: Path, rows: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary_path = path.with_suffix(path.suffix + ".tmp")
    with temporary_path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    temporary_path.replace(path)


def markdown_table(
    rows: list[dict[str, Any]], *, queue_job_count: int
) -> str:
    lines = [
        "# Cross-model MXINT + SF Sparse results (E8M0 ceil)",
        "",
        "Common scope: WikiText2 test, 64 non-overlapping blocks x 2048 "
        "tokens, group size 32, BF16 reference, SF block size 32, K32/K40. "
        "MXINT4 includes Attention Hadamard; MXINT8 does not.",
        "",
        f"All {queue_job_count} queue jobs are complete and validated. "
        "All sparse runs report zero dense fallbacks.",
        "",
        "| Model | BF16 | INT8 dense | INT8 K32 | INT8 K40 | "
        "INT4+H dense | INT4+H K32 | INT4+H K40 |",
        "|---|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for row in rows:
        lines.append(
            f"| {row['model_slug']} | {row['bf16_ppl']:.4f} | "
            f"{row['mxint8_dense_ppl']:.4f} | "
            f"{row['mxint8_k32_ppl']:.4f} | "
            f"{row['mxint8_k40_ppl']:.4f} | "
            f"{row['mxint4_hadamard_dense_ppl']:.4f} | "
            f"{row['mxint4_hadamard_k32_ppl']:.4f} | "
            f"{row['mxint4_hadamard_k40_ppl']:.4f} |"
        )
    lines.extend(
        [
            "",
            "K32 block sparsity is 25.385%; K40 block sparsity is 14.423% "
            "for every 2048-token run under the current causal-block "
            "definition.",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> None:
    args = parse_args()
    csv_output = args.csv_output or args.results_dir / "model_summary.csv"
    markdown_output = (
        args.markdown_output or args.results_dir / "model_summary.md"
    )
    queue_state = load_json(args.results_dir / "queue_state.json")
    rows = collect_rows(args.results_dir, load_json(args.manifest))
    write_csv(csv_output, rows)
    write_text_atomic(
        markdown_output,
        markdown_table(rows, queue_job_count=len(queue_state["jobs"])),
    )
    print(f"Validated models: {len(rows)}")
    print(f"CSV: {csv_output}")
    print(f"Markdown: {markdown_output}")


if __name__ == "__main__":
    main()
