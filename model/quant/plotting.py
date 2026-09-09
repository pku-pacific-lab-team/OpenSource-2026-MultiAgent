"""Plot quantization statistics collected by :mod:`quant.stats`.

The original experiment code kept activation tensors and NumPy histograms in
each module.  The clean implementation instead plots the streaming JSON
summary, so plotting does not change the quantized forward path or retain full
model activations.
"""

from __future__ import annotations

import json
import math
import re
from collections import defaultdict
from pathlib import Path
from typing import Any, Iterable


def _pyplot():
    import matplotlib

    matplotlib.use("Agg", force=True)
    import matplotlib.pyplot as plt

    return plt


def _safe_name(value: str) -> str:
    return re.sub(r"[^A-Za-z0-9_.-]+", "_", value).strip("._") or "record"


def _iter_records(
    stats_or_payload: dict[str, Any],
) -> Iterable[tuple[str, str, dict[str, Any]]]:
    records = stats_or_payload.get("records", stats_or_payload)
    for layer_name, tensors in sorted(records.items()):
        for tensor_name, record in sorted(tensors.items()):
            yield layer_name, tensor_name, record


def _merge_histogram(
    target: dict[int, int],
    histogram: dict[str, int],
) -> None:
    for key, count in histogram.items():
        target[int(key)] += int(count)


def _plot_histogram(
    histogram: dict[int, int],
    *,
    title: str,
    xlabel: str,
    output_path: Path,
    color: str,
) -> bool:
    if not histogram or not sum(histogram.values()):
        return False
    plt = _pyplot()
    x_values = sorted(histogram)
    counts = [histogram[value] for value in x_values]
    width = 0.8 if len(x_values) < 2 else min(
        0.8,
        max(0.15, 0.8 * min(b - a for a, b in zip(x_values, x_values[1:]))),
    )
    figure, axis = plt.subplots(figsize=(11, 6))
    axis.bar(x_values, counts, width=width, color=color, alpha=0.8)
    axis.set_title(title)
    axis.set_xlabel(xlabel)
    axis.set_ylabel("Count (log scale)")
    axis.set_yscale("log")
    axis.grid(axis="y", linestyle="--", alpha=0.35)
    figure.tight_layout()
    figure.savefig(output_path, dpi=150)
    plt.close(figure)
    return True


def _aggregate_by_tensor(
    records: list[tuple[str, str, dict[str, Any]]],
    histogram_name: str,
) -> dict[tuple[str, int], dict[int, int]]:
    aggregated: dict[tuple[str, int], dict[int, int]] = defaultdict(
        lambda: defaultdict(int)
    )
    for _, tensor_name, record in records:
        key = (tensor_name, int(record["bits"]))
        _merge_histogram(aggregated[key], record.get(histogram_name, {}))
    return aggregated


def _plot_sf_distributions(
    records: list[tuple[str, str, dict[str, Any]]],
    output_dir: Path,
) -> list[Path]:
    paths: list[Path] = []
    histograms = _aggregate_by_tensor(records, "rounded_log2_scale_histogram")
    for (tensor_name, bits), histogram in sorted(histograms.items()):
        path = output_dir / f"sf_exponent_{_safe_name(tensor_name)}_{bits}bit.png"
        if _plot_histogram(
            histogram,
            title=(
                f"Aggregated {tensor_name.upper()} Scaling-Factor Distribution "
                f"({bits}-bit quantizer)"
            ),
            xlabel="E8M0 exponent e, where SF = 2^e",
            output_path=path,
            color="teal",
        ):
            paths.append(path)
    return paths


def _plot_qkv_distributions(
    records: list[tuple[str, str, dict[str, Any]]],
    output_dir: Path,
) -> list[Path]:
    paths: list[Path] = []
    histograms = _aggregate_by_tensor(records, "integer_code_histogram")
    for (tensor_name, bits), histogram in sorted(histograms.items()):
        if tensor_name not in {"q", "k", "v", "p", "activation"}:
            continue
        path = output_dir / (
            f"integer_codes_{_safe_name(tensor_name)}_{bits}bit.png"
        )
        if _plot_histogram(
            histogram,
            title=f"Aggregated {tensor_name.upper()} Simulated Integer Codes",
            xlabel=f"Signed {bits}-bit quantization code",
            output_path=path,
            color="royalblue",
        ):
            paths.append(path)

    per_head: dict[
        tuple[int, int], dict[str, dict[int, int]]
    ] = defaultdict(lambda: defaultdict(lambda: defaultdict(int)))
    for _, tensor_name, record in records:
        if tensor_name not in {"q", "k", "v"}:
            continue
        bits = int(record["bits"])
        for head, histogram in record.get(
            "per_head_integer_code_histogram",
            {},
        ).items():
            _merge_histogram(
                per_head[(bits, int(head))][tensor_name],
                histogram,
            )

    plt = _pyplot()
    colors = {"q": "royalblue", "k": "darkorange", "v": "seagreen"}
    for (bits, head), tensor_histograms in sorted(per_head.items()):
        all_codes = sorted(
            {
                code
                for histogram in tensor_histograms.values()
                for code in histogram
            }
        )
        if not all_codes:
            continue
        figure, axis = plt.subplots(figsize=(13, 7))
        present = [name for name in ("q", "k", "v") if name in tensor_histograms]
        width = 0.8 / len(present)
        for offset_index, tensor_name in enumerate(present):
            offset = (offset_index - (len(present) - 1) / 2) * width
            counts = [tensor_histograms[tensor_name].get(code, 0) for code in all_codes]
            axis.bar(
                [code + offset for code in all_codes],
                counts,
                width=width,
                label=tensor_name.upper(),
                color=colors[tensor_name],
                alpha=0.75,
            )
        axis.set_yscale("log")
        axis.set_xlabel(f"Signed {bits}-bit quantization code")
        axis.set_ylabel("Count (log scale)")
        axis.set_title(f"Aggregated Q/K/V Integer Codes: Head {head}")
        axis.legend()
        axis.grid(axis="y", linestyle="--", alpha=0.3)
        figure.tight_layout()
        path = output_dir / f"qkv_integer_codes_head_{head}_{bits}bit.png"
        figure.savefig(path, dpi=150)
        plt.close(figure)
        paths.append(path)
    return paths


def _plot_weight_integer_distributions(
    records: list[tuple[str, str, dict[str, Any]]],
    output_dir: Path,
) -> list[Path]:
    paths: list[Path] = []
    histograms: dict[tuple[str, int], dict[int, int]] = defaultdict(
        lambda: defaultdict(int)
    )
    for layer_name, tensor_name, record in records:
        if tensor_name != "weight":
            continue
        projection_type = layer_name.rsplit(".", 1)[-1]
        key = (projection_type, int(record["bits"]))
        _merge_histogram(histograms[key], record["integer_code_histogram"])

    for (projection_type, bits), histogram in sorted(histograms.items()):
        path = output_dir / (
            f"weight_integer_codes_{_safe_name(projection_type)}_{bits}bit.png"
        )
        if _plot_histogram(
            histogram,
            title=(
                f"Aggregated Weight Integer Codes: {projection_type} "
                f"({bits}-bit)"
            ),
            xlabel="Signed quantization code",
            output_path=path,
            color="skyblue",
        ):
            paths.append(path)
    return paths


def _split_bit_counts(
    histogram: dict[int, int],
    *,
    bits: int,
    offset: int = 0,
) -> tuple[list[int], list[int], int]:
    low_bits = bits // 2
    high_bits = bits - low_bits
    low_mask = (1 << low_bits) - 1
    full_mask = (1 << bits) - 1
    low_counts = [0] * (1 << low_bits)
    high_counts = [0] * (1 << high_bits)
    for value, count in histogram.items():
        encoded = (value + offset) & full_mask
        low_counts[encoded & low_mask] += count
        high_counts[encoded >> low_bits] += count
    return high_counts, low_counts, low_bits


def _plot_bit_distributions(
    records: list[tuple[str, str, dict[str, Any]]],
    output_dir: Path,
) -> list[Path]:
    plt = _pyplot()
    paths: list[Path] = []
    sf_histograms = _aggregate_by_tensor(
        records,
        "rounded_log2_scale_histogram",
    )
    code_histograms = _aggregate_by_tensor(records, "integer_code_histogram")

    for key in sorted(set(sf_histograms) & set(code_histograms)):
        tensor_name, bits = key
        sf_histogram = sf_histograms[key]
        code_histogram = code_histograms[key]
        if not sf_histogram or not code_histogram:
            continue

        # E8M0 uses an 8-bit biased exponent. Integer codes use the configured
        # two's-complement width; unlike the old script this is not hard-coded
        # to INT4 when the experiment is actually MXINT8.
        sf_high, sf_low, sf_low_bits = _split_bit_counts(
            sf_histogram,
            bits=8,
            offset=127,
        )
        code_high, code_low, code_low_bits = _split_bit_counts(
            code_histogram,
            bits=bits,
        )

        figure, axes = plt.subplots(2, 2, figsize=(16, 10))
        figure.suptitle(
            f"MXINT Bit-Field Distribution: {tensor_name.upper()} ({bits}-bit)",
            fontsize=15,
        )
        panels = (
            (axes[0, 0], sf_high, f"E8M0 exponent high {8 - sf_low_bits} bits", "teal"),
            (axes[0, 1], sf_low, f"E8M0 exponent low {sf_low_bits} bits", "mediumaquamarine"),
            (axes[1, 0], code_high, f"INT{bits} high {bits - code_low_bits} bits", "purple"),
            (axes[1, 1], code_low, f"INT{bits} low {code_low_bits} bits", "orchid"),
        )
        for axis, counts, title, color in panels:
            x_values = list(range(len(counts)))
            axis.bar(x_values, counts, color=color, alpha=0.75)
            axis.set_title(title)
            axis.set_xticks(x_values)
            if any(counts):
                axis.set_yscale("log")
            axis.grid(axis="y", linestyle="--", alpha=0.3)

        figure.tight_layout()
        path = output_dir / (
            f"bit_fields_{_safe_name(tensor_name)}_{bits}bit.png"
        )
        figure.savefig(path, dpi=150)
        plt.close(figure)
        paths.append(path)
    return paths


def _plot_quant_error_summary(
    records: list[tuple[str, str, dict[str, Any]]],
    output_dir: Path,
) -> list[Path]:
    aggregates: dict[str, dict[str, float]] = defaultdict(
        lambda: defaultdict(float)
    )
    for _, tensor_name, record in records:
        error_elements = int(record.get("error_elements", 0))
        code_elements = int(record.get("code_elements", 0))
        values = aggregates[tensor_name]
        values["error_elements"] += error_elements
        values["absolute_error_sum"] += (
            float(record.get("mae") or 0.0) * error_elements
        )
        values["squared_error_sum"] += (
            float(record.get("rmse") or 0.0) ** 2 * error_elements
        )
        values["code_elements"] += code_elements
        values["zero_codes"] += (
            float(record.get("zero_code_ratio") or 0.0) * code_elements
        )
        values["saturated_codes"] += (
            float(record.get("saturation_ratio") or 0.0) * code_elements
        )

    names = sorted(aggregates)
    if not names:
        return []
    mae = []
    rmse = []
    zero_ratio = []
    saturation_ratio = []
    for name in names:
        values = aggregates[name]
        n_error = max(1.0, values["error_elements"])
        n_code = max(1.0, values["code_elements"])
        mae.append(values["absolute_error_sum"] / n_error)
        rmse.append(math.sqrt(values["squared_error_sum"] / n_error))
        zero_ratio.append(values["zero_codes"] / n_code)
        saturation_ratio.append(values["saturated_codes"] / n_code)

    plt = _pyplot()
    figure, axes = plt.subplots(1, 2, figsize=(15, 6))
    x_values = list(range(len(names)))
    width = 0.38
    axes[0].bar([x - width / 2 for x in x_values], mae, width, label="MAE")
    axes[0].bar([x + width / 2 for x in x_values], rmse, width, label="RMSE")
    axes[0].set_title("Quantize-Dequantize Error")
    axes[0].set_xticks(x_values, names, rotation=30)
    if any(value > 0 for value in mae + rmse):
        axes[0].set_yscale("log")
    axes[0].legend()
    axes[0].grid(axis="y", linestyle="--", alpha=0.3)

    axes[1].bar(
        [x - width / 2 for x in x_values],
        zero_ratio,
        width,
        label="Zero-code ratio",
    )
    axes[1].bar(
        [x + width / 2 for x in x_values],
        saturation_ratio,
        width,
        label="Saturation ratio",
    )
    axes[1].set_title("Integer-Code Utilization")
    axes[1].set_xticks(x_values, names, rotation=30)
    axes[1].set_ylabel("Ratio")
    axes[1].legend()
    axes[1].grid(axis="y", linestyle="--", alpha=0.3)
    figure.tight_layout()
    path = output_dir / "quant_error_and_code_summary.png"
    figure.savefig(path, dpi=150)
    plt.close(figure)
    return [path]


def _plot_sparse_attention_summary(
    sparse_stats: dict[str, dict[str, Any]],
    output_dir: Path,
) -> list[Path]:
    if not sparse_stats:
        return []
    names = sorted(sparse_stats)
    labels = [name.replace("model.layers.", "L").replace(".self_attn", "") for name in names]
    kept = [
        float(sparse_stats[name].get("kept_block_ratio") or 0.0)
        for name in names
    ]
    compute = [
        float(sparse_stats[name].get("qk_compute_ratio") or 0.0)
        for name in names
    ]
    plt = _pyplot()
    figure, axis = plt.subplots(figsize=(max(12, len(names) * 0.35), 6))
    x_values = list(range(len(names)))
    width = 0.4
    axis.bar(
        [x - width / 2 for x in x_values],
        kept,
        width,
        label="Kept model-valid blocks",
    )
    axis.bar(
        [x + width / 2 for x in x_values],
        compute,
        width,
        label="Executed / dense QK pairs",
    )
    axis.set_xticks(x_values, labels, rotation=60)
    axis.set_ylim(0.0, 1.05)
    axis.set_ylabel("Ratio")
    axis.set_title("SF Sparse Attention Utilization by Layer")
    axis.legend()
    axis.grid(axis="y", linestyle="--", alpha=0.3)
    figure.tight_layout()
    path = output_dir / "sf_sparse_attention_summary.png"
    figure.savefig(path, dpi=150)
    plt.close(figure)
    return [path]


def _plot_per_layer(
    records: list[tuple[str, str, dict[str, Any]]],
    output_dir: Path,
) -> list[Path]:
    layer_dir = output_dir / "per_layer"
    layer_dir.mkdir(parents=True, exist_ok=True)
    paths: list[Path] = []
    for layer_name, tensor_name, record in records:
        prefix = _safe_name(f"{layer_name}_{tensor_name}")
        scale_hist: dict[int, int] = defaultdict(int)
        code_hist: dict[int, int] = defaultdict(int)
        _merge_histogram(
            scale_hist,
            record.get("rounded_log2_scale_histogram", {}),
        )
        _merge_histogram(code_hist, record.get("integer_code_histogram", {}))
        scale_path = layer_dir / f"{prefix}_sf_exponent.png"
        if _plot_histogram(
            scale_hist,
            title=f"SF Exponents: {layer_name} / {tensor_name}",
            xlabel="E8M0 exponent e, where SF = 2^e",
            output_path=scale_path,
            color="teal",
        ):
            paths.append(scale_path)
        code_path = layer_dir / f"{prefix}_integer_codes.png"
        if _plot_histogram(
            code_hist,
            title=f"Integer Codes: {layer_name} / {tensor_name}",
            xlabel=f"Signed {record['bits']}-bit quantization code",
            output_path=code_path,
            color="royalblue",
        ):
            paths.append(code_path)
    return paths


def plot_quant_stats(
    stats_or_payload: dict[str, Any],
    output_dir: str | Path,
    *,
    plot_sf_distribution: bool = True,
    plot_bit_distribution: bool = True,
    plot_qkv_distribution: bool = True,
    plot_weight_int_distribution: bool = True,
    plot_quant_error: bool = True,
    per_layer: bool = False,
) -> list[Path]:
    """Generate plots from an in-memory stats snapshot or saved JSON payload."""
    destination = Path(output_dir)
    destination.mkdir(parents=True, exist_ok=True)
    records = list(_iter_records(stats_or_payload))
    paths: list[Path] = []
    if plot_sf_distribution:
        paths.extend(_plot_sf_distributions(records, destination))
    if plot_bit_distribution:
        paths.extend(_plot_bit_distributions(records, destination))
    if plot_qkv_distribution:
        paths.extend(_plot_qkv_distributions(records, destination))
    if plot_weight_int_distribution:
        paths.extend(_plot_weight_integer_distributions(records, destination))
    if plot_quant_error:
        paths.extend(_plot_quant_error_summary(records, destination))
    paths.extend(
        _plot_sparse_attention_summary(
            stats_or_payload.get("sparse_attention", {}),
            destination,
        )
    )
    if per_layer:
        paths.extend(_plot_per_layer(records, destination))

    manifest_path = destination / "plot_manifest.json"
    manifest = {
        "plot_count": len(paths),
        "plots": [str(path) for path in paths],
        "notes": {
            "sf_histogram": "x-axis is log2(SF), so E8M0 SF equals 2^x",
            "integer_histogram": "codes are reconstructed from original/SF",
            "bit_fields": (
                "SF uses exponent bias 127; integer fields use the configured "
                "two's-complement width"
            ),
        },
    }
    with manifest_path.open("w", encoding="utf-8") as handle:
        json.dump(manifest, handle, indent=2, sort_keys=True)
        handle.write("\n")
    return paths


def plot_quant_stats_file(
    stats_path: str | Path,
    output_dir: str | Path,
    **kwargs: Any,
) -> list[Path]:
    """Generate plots from a previously saved quant-statistics JSON file."""
    with Path(stats_path).open(encoding="utf-8") as handle:
        payload = json.load(handle)
    return plot_quant_stats(payload, output_dir, **kwargs)


def plot_attention_maps(model: Any, output_dir: str | Path) -> list[Path]:
    """Plot bounded, first-forward post-softmax maps captured by attention layers."""
    destination = Path(output_dir) / "attention_maps"
    destination.mkdir(parents=True, exist_ok=True)
    plt = _pyplot()
    from matplotlib.colors import LogNorm

    paths: list[Path] = []
    epsilon = 1e-10
    for layer_name, module in model.named_modules():
        stored = getattr(module, "stored_attention_map", None)
        if stored is None:
            continue
        maps = stored.float().cpu().numpy()
        layer_dir = destination / _safe_name(layer_name)
        layer_dir.mkdir(parents=True, exist_ok=True)
        for head_index, data in enumerate(maps):
            vmax = max(epsilon * 10, float(data.max()))
            figure, axis = plt.subplots(figsize=(10, 8))
            image = axis.imshow(
                data + epsilon,
                cmap="viridis",
                aspect="auto",
                interpolation="nearest",
                norm=LogNorm(vmin=epsilon, vmax=vmax),
            )
            figure.colorbar(image, ax=axis, label="Attention probability (log scale)")
            axis.set_title(f"{layer_name} / head {head_index} (post-softmax)")
            axis.set_xlabel("Key position")
            axis.set_ylabel("Query position")
            figure.tight_layout()
            path = layer_dir / f"head_{head_index}_log.png"
            figure.savefig(path, dpi=150)
            plt.close(figure)
            paths.append(path)
        module.stored_attention_map = None
    return paths
