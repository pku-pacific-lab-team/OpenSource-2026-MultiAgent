"""CPU-only smoke test for JSON-backed statistics plotting."""

from __future__ import annotations

import importlib.util
import json
import tempfile
from pathlib import Path


MODULE_PATH = Path(__file__).parents[1] / "quant" / "plotting.py"
SPEC = importlib.util.spec_from_file_location("clean_quant_plotting", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
PLOTTING = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(PLOTTING)


def _record(bits: int) -> dict:
    return {
        "bits": bits,
        "error_elements": 16,
        "code_elements": 16,
        "mae": 0.01,
        "rmse": 0.02,
        "zero_code_ratio": 0.25,
        "saturation_ratio": 0.0625,
        "integer_code_histogram": {"-1": 3, "0": 4, "1": 9},
        "rounded_log2_scale_histogram": {"-6": 5, "-5": 11},
    }


def test_plotting() -> None:
    q_record = _record(8)
    q_record["per_head_integer_code_histogram"] = {
        "0": {"-1": 3, "0": 4, "1": 9}
    }
    stats = {
        "records": {
            "model.layers.0.self_attn": {"q": q_record},
            "model.layers.0.self_attn.q_proj": {"weight": _record(8)},
        },
        "sparse_attention": {
            "model.layers.0.self_attn": {
                "kept_block_ratio": 0.5,
                "qk_compute_ratio": 0.4,
            }
        },
    }
    with tempfile.TemporaryDirectory() as directory:
        paths = PLOTTING.plot_quant_stats(
            stats,
            directory,
            per_layer=True,
        )
        assert len(paths) == 13
        assert all(path.is_file() for path in paths)
        with (Path(directory) / "plot_manifest.json").open(
            encoding="utf-8"
        ) as handle:
            manifest = json.load(handle)
        assert manifest["plot_count"] == len(paths)


if __name__ == "__main__":
    test_plotting()
    print("Quant-statistics plotting smoke test passed.")
