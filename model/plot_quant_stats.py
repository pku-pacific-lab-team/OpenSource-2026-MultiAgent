"""Render quantization plots from a previously saved statistics JSON file."""

from __future__ import annotations

import argparse

from quant.plotting import plot_quant_stats_file


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("stats_path")
    parser.add_argument("--output-dir", default="results/plots")
    parser.add_argument("--per-layer", action="store_true")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    paths = plot_quant_stats_file(
        args.stats_path,
        args.output_dir,
        per_layer=args.per_layer,
    )
    print(f"Generated {len(paths)} plots in {args.output_dir}")


if __name__ == "__main__":
    main()
