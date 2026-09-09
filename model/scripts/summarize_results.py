"""Validate raw benchmark JSON files and rebuild the public summary tables."""

from __future__ import annotations

import csv
import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "configs" / "scale_model_queue.json"
RAW_DIR = ROOT / "data" / "results" / "raw"
CSV_OUTPUT = ROOT / "data" / "results" / "model_summary.csv"
MARKDOWN_OUTPUT = ROOT / "data" / "results" / "model_summary.md"
TOPK_VALUES = (32, 40)


def load_json(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def percent_change(value: float, baseline: float) -> float:
    return (value / baseline - 1.0) * 100.0


def validate_report(
    report: dict[str, Any],
    *,
    quant_format: str,
    hadamard: bool,
) -> None:
    require(report.get("status") == "complete", "report is incomplete")
    require(report["quant_format"] == quant_format, "quant format mismatch")
    require(report["dataset"]["seqlen"] == 2048, "sequence length mismatch")
    require(report["dataset"]["blocks"] == 64, "sample count mismatch")
    require(
        report["dataset"]["name"] == "wikitext/wikitext-2-raw-v1:test",
        "dataset mismatch",
    )
    config = report["dense_config"]
    require(config["group_size"] == 32, "group size mismatch")
    require(config["e8_scale_op"] == "ceil", "E8M0 rounding mismatch")
    require(
        config["attention_hadamard"] is hadamard,
        "Attention Hadamard mismatch",
    )
    for topk in TOPK_VALUES:
        run = report["sparse_runs"][f"topk_{topk}"]
        require(
            run["aggregate_sparse_stats"]["fallback_calls"] == 0,
            f"K={topk} used dense fallback",
        )


def add_format_fields(
    row: dict[str, Any],
    report: dict[str, Any],
    prefix: str,
) -> None:
    reference_ppl = report["reference"]["metrics"]["ppl"]
    dense_ppl = report["dense_fake_quant"]["metrics"]["ppl"]
    row[f"{prefix}_dense_ppl"] = dense_ppl
    row[f"{prefix}_dense_vs_bf16_percent"] = percent_change(
        dense_ppl,
        reference_ppl,
    )
    for topk in TOPK_VALUES:
        run = report["sparse_runs"][f"topk_{topk}"]
        stats = run["aggregate_sparse_stats"]
        sparse_ppl = run["metrics"]["ppl"]
        row[f"{prefix}_k{topk}_ppl"] = sparse_ppl
        row[f"{prefix}_k{topk}_vs_dense_percent"] = percent_change(
            sparse_ppl,
            dense_ppl,
        )
        row[f"{prefix}_k{topk}_valid_block_sparsity_percent"] = (
            stats["block_sparsity_ratio"] * 100.0
        )
        causal_sparsity = stats.get(
            "block_sparsity_ratio_vs_causal",
            stats["block_sparsity_ratio"],
        )
        row[f"{prefix}_k{topk}_causal_block_sparsity_percent"] = (
            causal_sparsity * 100.0
        )
        row[f"{prefix}_k{topk}_fallback_calls"] = stats["fallback_calls"]


def collect_rows() -> list[dict[str, Any]]:
    manifest = load_json(MANIFEST)
    rows: list[dict[str, Any]] = []
    for model in manifest["models"]:
        if model["status"] != "supported":
            continue
        slug = model["slug"]
        int8_report = load_json(RAW_DIR / slug / "full_int8.json")
        int4_report = load_json(RAW_DIR / slug / "full_int4_hadamard.json")
        validate_report(int8_report, quant_format="MXINT8", hadamard=False)
        validate_report(int4_report, quant_format="MXINT4", hadamard=True)
        int8_bf16 = int8_report["reference"]["metrics"]["ppl"]
        int4_bf16 = int4_report["reference"]["metrics"]["ppl"]
        require(abs(int8_bf16 - int4_bf16) < 1e-9, "BF16 PPL mismatch")
        row: dict[str, Any] = {
            "model_slug": slug,
            "family": model["family"],
            "evaluated_model_id": int8_report["model"]["path"],
            "parameters": int8_report["model"]["parameters"],
            "attention_layers": int8_report["model"]["attention_layers"],
            "bf16_ppl": int8_bf16,
        }
        add_format_fields(row, int8_report, "mxint8")
        add_format_fields(row, int4_report, "mxint4_hadamard")
        for topk in TOPK_VALUES:
            # The Top-K budget is structural, so both precisions must skip
            # exactly the same blocks.
            require(
                abs(
                    row[f"mxint8_k{topk}_valid_block_sparsity_percent"]
                    - row[f"mxint4_hadamard_k{topk}_valid_block_sparsity_percent"]
                )
                < 1e-9,
                f"K={topk} block sparsity differs between MXINT8 and MXINT4",
            )
        rows.append(row)
    return rows


def write_csv(rows: list[dict[str, Any]]) -> None:
    with CSV_OUTPUT.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=list(rows[0]),
            lineterminator="\n",
        )
        writer.writeheader()
        writer.writerows(rows)


def write_markdown(rows: list[dict[str, Any]]) -> None:
    lines = [
        "# Cross-model MXINT and SF sparse results",
        "",
        "Common scope: WikiText-2 test, 64 x 2,048 tokens, group size 32, "
        "E8M0 ceil, SF block size 32, K32/K40. MXINT4 includes Attention "
        "Hadamard; MXINT8 does not.",
        "",
        "K is the Top-K budget of SF block selection: the number of 32-token "
        "key blocks kept for each query block, including the forced first and "
        "diagonal blocks. A 2,048-token sequence has 64 key blocks. The "
        "achieved block sparsity of every run is recorded in the "
        "`*_block_sparsity_percent` columns of `model_summary.csv`.",
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
            "See `data/README.md` for units, provenance, and interpretation.",
            "",
        ]
    )
    # Force LF so the checksummed bytes are identical on every platform.
    MARKDOWN_OUTPUT.write_text("\n".join(lines), encoding="utf-8", newline="\n")


def main() -> None:
    rows = collect_rows()
    write_csv(rows)
    write_markdown(rows)
    print(f"Validated and summarized {len(rows)} models")


if __name__ == "__main__":
    main()
