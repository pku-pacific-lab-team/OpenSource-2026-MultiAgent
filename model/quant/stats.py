"""Streaming quantization statistics used by JSON and plotting reports."""

from __future__ import annotations

import json
import math
import os
import threading
from collections import defaultdict
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import torch


def _merge_histogram(target: dict[int, int], update: dict[int, int]) -> None:
    for key, count in update.items():
        target[key] += count


def _sparse_histogram(values: torch.Tensor) -> dict[int, int]:
    if values.numel() == 0:
        return {}
    unique, counts = torch.unique(values.to(torch.int64), return_counts=True)
    return {
        int(key): int(count)
        for key, count in zip(unique.cpu().tolist(), counts.cpu().tolist())
    }


@dataclass
class _TensorAccumulator:
    bits: int
    clip_style: str
    group_size: int
    calls: int = 0
    elements: int = 0
    finite_input_elements: int = 0
    finite_output_elements: int = 0
    nonfinite_input_elements: int = 0
    nonfinite_output_elements: int = 0
    input_sum: float = 0.0
    input_square_sum: float = 0.0
    input_min: float = math.inf
    input_max: float = -math.inf
    output_sum: float = 0.0
    output_min: float = math.inf
    output_max: float = -math.inf
    scale_elements: int = 0
    scale_sum: float = 0.0
    scale_min: float = math.inf
    scale_max: float = -math.inf
    error_elements: int = 0
    absolute_error_sum: float = 0.0
    squared_error_sum: float = 0.0
    max_absolute_error: float = 0.0
    code_elements: int = 0
    zero_codes: int = 0
    saturated_codes: int = 0
    integer_code_histogram: dict[int, int] = field(
        default_factory=lambda: defaultdict(int)
    )
    rounded_log2_scale_histogram: dict[int, int] = field(
        default_factory=lambda: defaultdict(int)
    )
    per_head_integer_code_histogram: dict[int, dict[int, int]] = field(
        default_factory=dict
    )

    def to_dict(self) -> dict[str, Any]:
        input_mean = (
            self.input_sum / self.finite_input_elements
            if self.finite_input_elements
            else None
        )
        input_rms = (
            math.sqrt(self.input_square_sum / self.finite_input_elements)
            if self.finite_input_elements
            else None
        )
        output_mean = (
            self.output_sum / self.finite_output_elements
            if self.finite_output_elements
            else None
        )
        scale_mean = (
            self.scale_sum / self.scale_elements
            if self.scale_elements
            else None
        )
        mae = (
            self.absolute_error_sum / self.error_elements
            if self.error_elements
            else None
        )
        rmse = (
            math.sqrt(self.squared_error_sum / self.error_elements)
            if self.error_elements
            else None
        )
        zero_ratio = (
            self.zero_codes / self.code_elements
            if self.code_elements
            else None
        )
        saturation_ratio = (
            self.saturated_codes / self.code_elements
            if self.code_elements
            else None
        )

        return {
            "bits": self.bits,
            "clip_style": self.clip_style,
            "group_size": self.group_size,
            "calls": self.calls,
            "elements": self.elements,
            "finite_input_elements": self.finite_input_elements,
            "finite_output_elements": self.finite_output_elements,
            "nonfinite_input_elements": self.nonfinite_input_elements,
            "nonfinite_output_elements": self.nonfinite_output_elements,
            "input_min": (
                self.input_min if self.finite_input_elements else None
            ),
            "input_max": (
                self.input_max if self.finite_input_elements else None
            ),
            "input_mean": input_mean,
            "input_rms": input_rms,
            "output_min": (
                self.output_min if self.finite_output_elements else None
            ),
            "output_max": (
                self.output_max if self.finite_output_elements else None
            ),
            "output_mean": output_mean,
            "scale_elements": self.scale_elements,
            "scale_min": self.scale_min if self.scale_elements else None,
            "scale_max": self.scale_max if self.scale_elements else None,
            "scale_mean": scale_mean,
            "mae": mae,
            "rmse": rmse,
            "max_absolute_error": (
                self.max_absolute_error if self.error_elements else None
            ),
            "code_elements": self.code_elements,
            "zero_code_ratio": zero_ratio,
            "saturation_ratio": saturation_ratio,
            "integer_code_histogram": {
                str(key): self.integer_code_histogram[key]
                for key in sorted(self.integer_code_histogram)
            },
            "rounded_log2_scale_histogram": {
                str(key): self.rounded_log2_scale_histogram[key]
                for key in sorted(self.rounded_log2_scale_histogram)
            },
            "per_head_integer_code_histogram": {
                str(head): {
                    str(code): histogram[code]
                    for code in sorted(histogram)
                }
                for head, histogram in sorted(
                    self.per_head_integer_code_histogram.items()
                )
            },
        }


@dataclass
class _SparseAttentionAccumulator:
    calls: int = 0
    fallback_calls: int = 0
    total_causal_blocks: int = 0
    total_valid_blocks: int = 0
    kept_blocks: int = 0
    executed_qk_pairs: int = 0
    dense_qk_pairs: int = 0

    def to_dict(self) -> dict[str, Any]:
        kept_ratio = (
            self.kept_blocks / self.total_valid_blocks
            if self.total_valid_blocks
            else None
        )
        kept_ratio_vs_causal = (
            self.kept_blocks / self.total_causal_blocks
            if self.total_causal_blocks
            else None
        )
        compute_ratio = (
            self.executed_qk_pairs / self.dense_qk_pairs
            if self.dense_qk_pairs
            else None
        )
        return {
            "calls": self.calls,
            "fallback_calls": self.fallback_calls,
            "total_causal_blocks": self.total_causal_blocks,
            "total_valid_blocks": self.total_valid_blocks,
            "kept_blocks": self.kept_blocks,
            "kept_block_ratio": kept_ratio,
            "block_sparsity_ratio": (
                1.0 - kept_ratio if kept_ratio is not None else None
            ),
            "kept_block_ratio_vs_causal": kept_ratio_vs_causal,
            "block_sparsity_ratio_vs_causal": (
                1.0 - kept_ratio_vs_causal
                if kept_ratio_vs_causal is not None
                else None
            ),
            "executed_qk_pairs": self.executed_qk_pairs,
            "dense_qk_pairs": self.dense_qk_pairs,
            "qk_compute_ratio": compute_ratio,
            "qk_compute_reduction_ratio": (
                1.0 - compute_ratio if compute_ratio is not None else None
            ),
        }


class QuantStats:
    """Aggregate statistics without retaining activation tensors."""

    def __init__(self) -> None:
        self._records: dict[tuple[str, str], _TensorAccumulator] = {}
        self._sparse_records: dict[str, _SparseAttentionAccumulator] = {}
        self._lock = threading.Lock()

    def reset(self) -> None:
        with self._lock:
            self._records.clear()
            self._sparse_records.clear()

    def observe_sparse_attention(
        self,
        *,
        layer_name: str,
        total_causal_blocks: int,
        total_valid_blocks: int | None = None,
        kept_blocks: int,
        executed_qk_pairs: int,
        dense_qk_pairs: int,
        fallback: bool,
    ) -> None:
        with self._lock:
            record = self._sparse_records.setdefault(
                layer_name,
                _SparseAttentionAccumulator(),
            )
            record.calls += 1
            record.fallback_calls += int(fallback)
            record.total_causal_blocks += int(total_causal_blocks)
            record.total_valid_blocks += int(
                total_causal_blocks
                if total_valid_blocks is None
                else total_valid_blocks
            )
            record.kept_blocks += int(kept_blocks)
            record.executed_qk_pairs += int(executed_qk_pairs)
            record.dense_qk_pairs += int(dense_qk_pairs)

    @torch.no_grad()
    def observe(
        self,
        *,
        layer_name: str,
        tensor_name: str,
        original: torch.Tensor,
        dequantized: torch.Tensor,
        scales: torch.Tensor,
        bits: int,
        clip_style: str,
        group_size: int,
    ) -> None:
        if original.shape != dequantized.shape:
            raise ValueError(
                "original and dequantized tensors must have the same shape"
            )
        if original.ndim < 1:
            raise ValueError("statistics require a tensor with at least 1 dim")

        # Keep temporary FP32/code tensors bounded for large weights and
        # [B,H,S,S] attention probabilities.
        max_chunk_elements = 1_000_000
        last_dim = original.shape[-1]
        original_rows = original.detach().reshape(-1, last_dim)
        output_rows = dequantized.detach().reshape(-1, last_dim)
        scale_rows = scales.detach().reshape(-1, scales.shape[-1])
        if scale_rows.shape[0] != original_rows.shape[0]:
            raise ValueError(
                "scale leading dimensions do not match the observed tensor"
            )
        rows_per_chunk = max(1, max_chunk_elements // last_dim)

        update = {
            "calls": 1,
            "elements": original.numel(),
            "finite_input_elements": 0,
            "finite_output_elements": 0,
            "nonfinite_input_elements": 0,
            "nonfinite_output_elements": 0,
            "input_sum": 0.0,
            "input_square_sum": 0.0,
            "input_min": math.inf,
            "input_max": -math.inf,
            "output_sum": 0.0,
            "output_min": math.inf,
            "output_max": -math.inf,
            "scale_elements": 0,
            "scale_sum": 0.0,
            "scale_min": math.inf,
            "scale_max": -math.inf,
            "error_elements": 0,
            "absolute_error_sum": 0.0,
            "squared_error_sum": 0.0,
            "max_absolute_error": 0.0,
            "code_elements": 0,
            "zero_codes": 0,
            "saturated_codes": 0,
        }
        integer_hist: dict[int, int] = defaultdict(int)
        exponent_hist: dict[int, int] = defaultdict(int)
        per_head_integer_hist: dict[int, dict[int, int]] = defaultdict(
            lambda: defaultdict(int)
        )

        qmax = 2 ** (bits - 1) - 1
        qmin = -qmax if clip_style == "sym" else -(2 ** (bits - 1))
        effective_group_size = last_dim if group_size <= 0 else group_size

        for start in range(0, original_rows.shape[0], rows_per_chunk):
            end = min(start + rows_per_chunk, original_rows.shape[0])
            original_chunk = original_rows[start:end].float()
            output_chunk = output_rows[start:end].float()
            finite_input = torch.isfinite(original_chunk)
            finite_output = torch.isfinite(output_chunk)
            input_values = original_chunk[finite_input]
            output_values = output_chunk[finite_output]

            update["finite_input_elements"] += input_values.numel()
            update["finite_output_elements"] += output_values.numel()
            update["nonfinite_input_elements"] += (
                original_chunk.numel() - input_values.numel()
            )
            update["nonfinite_output_elements"] += (
                output_chunk.numel() - output_values.numel()
            )
            if input_values.numel():
                input_values_d = input_values.double()
                update["input_sum"] += float(input_values_d.sum().item())
                update["input_square_sum"] += float(
                    (input_values_d * input_values_d).sum().item()
                )
                update["input_min"] = min(
                    update["input_min"],
                    float(input_values.min().item()),
                )
                update["input_max"] = max(
                    update["input_max"],
                    float(input_values.max().item()),
                )
            if output_values.numel():
                update["output_sum"] += float(
                    output_values.double().sum().item()
                )
                update["output_min"] = min(
                    update["output_min"],
                    float(output_values.min().item()),
                )
                update["output_max"] = max(
                    update["output_max"],
                    float(output_values.max().item()),
                )

            valid_error = finite_input & finite_output
            if valid_error.any():
                errors = (output_chunk - original_chunk)[valid_error]
                errors_d = errors.double()
                update["error_elements"] += errors.numel()
                update["absolute_error_sum"] += float(
                    errors_d.abs().sum().item()
                )
                update["squared_error_sum"] += float(
                    (errors_d * errors_d).sum().item()
                )
                update["max_absolute_error"] = max(
                    update["max_absolute_error"],
                    float(errors.abs().max().item()),
                )

            if bits < 16:
                scale_chunk = scale_rows[start:end].float()
                expanded_scales = scale_chunk.repeat_interleave(
                    effective_group_size,
                    dim=-1,
                )[..., :last_dim]
                codes_f = (
                    (original_chunk / expanded_scales)
                    .round()
                    .clamp(qmin, qmax)
                )
                if original.ndim == 4 and tensor_name in {"q", "k", "v"}:
                    sequence_length = original.shape[2]
                    num_heads = original.shape[1]
                    row_indices = torch.arange(
                        start,
                        end,
                        device=codes_f.device,
                    )
                    head_indices = (row_indices // sequence_length) % num_heads
                    for head_index in range(num_heads):
                        head_codes_f = codes_f[head_indices == head_index]
                        head_codes = head_codes_f[
                            torch.isfinite(head_codes_f)
                        ].to(torch.int64)
                        if head_codes.numel():
                            head_counts = torch.bincount(
                                head_codes - qmin,
                                minlength=qmax - qmin + 1,
                            )
                            head_nonzero = torch.nonzero(
                                head_counts,
                                as_tuple=False,
                            ).flatten()
                            for index in head_nonzero.cpu().tolist():
                                per_head_integer_hist[head_index][
                                    index + qmin
                                ] += int(head_counts[index].item())
                codes = codes_f[torch.isfinite(codes_f)].to(torch.int64)
                if codes.numel():
                    counts = torch.bincount(
                        codes - qmin,
                        minlength=qmax - qmin + 1,
                    )
                    nonzero = torch.nonzero(counts, as_tuple=False).flatten()
                    for index in nonzero.cpu().tolist():
                        integer_hist[index + qmin] += int(
                            counts[index].item()
                        )
                    update["code_elements"] += codes.numel()
                    update["zero_codes"] += int((codes == 0).sum().item())
                    update["saturated_codes"] += int(
                        ((codes == qmin) | (codes == qmax)).sum().item()
                    )

        scale_flat = scales.detach().reshape(-1)
        for start in range(0, scale_flat.numel(), max_chunk_elements):
            scale_chunk = scale_flat[
                start : start + max_chunk_elements
            ].float()
            scale_values = scale_chunk[
                torch.isfinite(scale_chunk) & (scale_chunk > 0)
            ]
            if not scale_values.numel():
                continue
            update["scale_elements"] += scale_values.numel()
            update["scale_sum"] += float(scale_values.double().sum().item())
            update["scale_min"] = min(
                update["scale_min"],
                float(scale_values.min().item()),
            )
            update["scale_max"] = max(
                update["scale_max"],
                float(scale_values.max().item()),
            )
            scale_exponents = torch.log2(scale_values).round().to(torch.int64)
            _merge_histogram(
                exponent_hist,
                _sparse_histogram(scale_exponents),
            )

        key = (layer_name, tensor_name)
        with self._lock:
            record = self._records.get(key)
            if record is None:
                record = _TensorAccumulator(
                    bits=bits,
                    clip_style=clip_style,
                    group_size=group_size,
                )
                self._records[key] = record
            elif (
                record.bits != bits
                or record.clip_style != clip_style
                or record.group_size != group_size
            ):
                raise ValueError(
                    f"inconsistent quantization settings for {key}: "
                    f"existing bits/style/group={record.bits}/"
                    f"{record.clip_style}/{record.group_size}, new="
                    f"{bits}/{clip_style}/{group_size}"
                )

            for name, value in update.items():
                if name in {"input_min", "output_min", "scale_min"}:
                    setattr(record, name, min(getattr(record, name), value))
                elif name in {"input_max", "output_max", "scale_max"}:
                    setattr(record, name, max(getattr(record, name), value))
                elif name == "max_absolute_error":
                    record.max_absolute_error = max(
                        record.max_absolute_error,
                        value,
                    )
                else:
                    setattr(record, name, getattr(record, name) + value)
            _merge_histogram(record.integer_code_histogram, integer_hist)
            _merge_histogram(
                record.rounded_log2_scale_histogram,
                exponent_hist,
            )
            for head_index, histogram in per_head_integer_hist.items():
                target = record.per_head_integer_code_histogram.setdefault(
                    head_index,
                    defaultdict(int),
                )
                _merge_histogram(target, histogram)

    def snapshot(self) -> dict[str, Any]:
        with self._lock:
            records: dict[str, dict[str, Any]] = {}
            for (layer_name, tensor_name), accumulator in sorted(
                self._records.items()
            ):
                records.setdefault(layer_name, {})[
                    tensor_name
                ] = accumulator.to_dict()
            return records

    def sparse_snapshot(self) -> dict[str, Any]:
        with self._lock:
            return {
                layer_name: record.to_dict()
                for layer_name, record in sorted(self._sparse_records.items())
            }


_GLOBAL_STATS = QuantStats()


def reset_quant_stats() -> None:
    _GLOBAL_STATS.reset()


def observe_quant_tensor(**kwargs: Any) -> None:
    _GLOBAL_STATS.observe(**kwargs)


def observe_sparse_attention(**kwargs: Any) -> None:
    _GLOBAL_STATS.observe_sparse_attention(**kwargs)


def get_quant_stats() -> dict[str, Any]:
    return _GLOBAL_STATS.snapshot()


def get_sparse_attention_stats() -> dict[str, Any]:
    return _GLOBAL_STATS.sparse_snapshot()


def save_quant_stats(
    path: str | os.PathLike[str],
    *,
    config: dict[str, Any],
    metadata: dict[str, Any] | None = None,
) -> Path:
    output_path = Path(path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "format_version": 1,
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "config": config,
        "metadata": metadata or {},
        "records": get_quant_stats(),
        "sparse_attention": get_sparse_attention_stats(),
    }
    temporary_path = output_path.with_suffix(output_path.suffix + ".tmp")
    with temporary_path.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, sort_keys=True)
        handle.write("\n")
    temporary_path.replace(output_path)
    return output_path
