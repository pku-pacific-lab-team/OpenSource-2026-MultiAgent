"""Resumable cross-model MXINT + SF Sparse benchmark queue."""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parent
DEFAULT_MANIFEST = ROOT / "configs" / "scale_model_queue.json"
DEFAULT_OUTPUT_DIR = ROOT / "results" / "model_queue_ceil"
DEFAULT_HF_HOME = Path(
    os.environ.get(
        "HF_HOME",
        Path.home() / ".cache" / "huggingface",
    )
)
PHASES = ("smoke", "full_int8", "full_int4_hadamard")


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def write_json_atomic(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary_path = path.with_suffix(path.suffix + ".tmp")
    with temporary_path.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, sort_keys=True)
        handle.write("\n")
    temporary_path.replace(path)


def load_json(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR)
    parser.add_argument("--runner", type=Path, default=ROOT / "run_sparse_comparison.py")
    parser.add_argument("--python", default=sys.executable)
    parser.add_argument(
        "--models",
        nargs="+",
        help="Model slugs in execution order; default uses every supported model",
    )
    parser.add_argument(
        "--phases",
        nargs="+",
        choices=PHASES,
        default=list(PHASES),
    )
    parser.add_argument(
        "--hf-home",
        type=Path,
        default=DEFAULT_HF_HOME,
    )
    parser.add_argument(
        "--hf-endpoint",
        help="Optional Hugging Face endpoint override; defaults to HF_ENDPOINT",
    )
    parser.add_argument(
        "--e8-scale-op",
        choices=("ceil", "floor", "round", "ocp"),
        default="ceil",
    )
    parser.add_argument("--full-seqlen", type=int, default=2048)
    parser.add_argument("--full-nsamples", type=int, default=64)
    parser.add_argument("--full-topk", nargs="+", type=int, default=[32, 40])
    parser.add_argument("--smoke-seqlen", type=int, default=512)
    parser.add_argument("--smoke-nsamples", type=int, default=1)
    parser.add_argument("--smoke-topk", type=int, default=16)
    parser.add_argument("--kl-topk", type=int, default=16)
    parser.add_argument(
        "--smoke-max-ppl-change-percent",
        type=float,
        default=0.05,
    )
    parser.add_argument(
        "--download-margin-gib",
        type=float,
        default=1.0,
        help="Required free space beyond estimated BF16 weight size",
    )
    parser.add_argument(
        "--local-files-only",
        action=argparse.BooleanOptionalAction,
        default=False,
    )
    parser.add_argument(
        "--resume",
        action=argparse.BooleanOptionalAction,
        default=True,
    )
    parser.add_argument(
        "--continue-on-error",
        action=argparse.BooleanOptionalAction,
        default=True,
    )
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    if args.full_nsamples < 1 or args.smoke_nsamples < 1:
        parser.error("sample counts must be positive")
    if args.full_seqlen < 2 or args.smoke_seqlen < 2:
        parser.error("sequence lengths must be at least 2")
    if any(value < 1 for value in args.full_topk):
        parser.error("full Top-K values must be positive")
    if args.smoke_topk < 1:
        parser.error("smoke Top-K must be positive")
    if args.download_margin_gib < 0:
        parser.error("download margin must be non-negative")
    return args


def select_models(
    manifest: dict[str, Any], requested_slugs: list[str] | None
) -> list[dict[str, Any]]:
    models = manifest["models"]
    by_slug = {model["slug"]: model for model in models}
    if requested_slugs:
        missing = [slug for slug in requested_slugs if slug not in by_slug]
        if missing:
            raise ValueError(f"unknown model slugs: {', '.join(missing)}")
        selected = [by_slug[slug] for slug in requested_slugs]
    else:
        selected = [model for model in models if model["status"] == "supported"]
    unsupported = [model for model in selected if model["status"] != "supported"]
    if unsupported:
        details = "; ".join(
            f"{model['slug']}: {model.get('reason', model['status'])}"
            for model in unsupported
        )
        raise ValueError(f"requested models are not runnable: {details}")
    return selected


def model_cache_path(hf_home: Path, model_id: str) -> Path:
    return hf_home / "hub" / f"models--{model_id.replace('/', '--')}"


def model_is_cached(hf_home: Path, model_id: str) -> bool:
    cache_path = model_cache_path(hf_home, model_id)
    snapshots = cache_path / "snapshots"
    if not snapshots.is_dir():
        return False
    weight_patterns = ("*.safetensors", "pytorch_model*.bin")
    return any(
        any(snapshot.glob(pattern))
        for snapshot in snapshots.iterdir()
        if snapshot.is_dir()
        for pattern in weight_patterns
    )


def free_gib(path: Path) -> float:
    existing_path = path
    while not existing_path.exists() and existing_path != existing_path.parent:
        existing_path = existing_path.parent
    return shutil.disk_usage(existing_path).free / 2**30


def phase_settings(args: argparse.Namespace, phase: str) -> dict[str, Any]:
    if phase == "smoke":
        return {
            "bits": 8,
            "hadamard": False,
            "seqlen": args.smoke_seqlen,
            "nsamples": args.smoke_nsamples,
            "topk": [args.smoke_topk],
        }
    if phase == "full_int8":
        return {
            "bits": 8,
            "hadamard": False,
            "seqlen": args.full_seqlen,
            "nsamples": args.full_nsamples,
            "topk": args.full_topk,
        }
    if phase == "full_int4_hadamard":
        return {
            "bits": 4,
            "hadamard": True,
            "seqlen": args.full_seqlen,
            "nsamples": args.full_nsamples,
            "topk": args.full_topk,
        }
    raise ValueError(f"unknown phase: {phase}")


def build_command(
    args: argparse.Namespace,
    model: dict[str, Any],
    phase: str,
    output_path: Path,
) -> list[str]:
    settings = phase_settings(args, phase)
    command = [
        args.python,
        str(args.runner),
        "--model-path",
        model["model_id"],
        "--seqlen",
        str(settings["seqlen"]),
        "--nsamples",
        str(settings["nsamples"]),
        "--batch-size",
        "1",
        "--mxint-bits",
        str(settings["bits"]),
        "--group-size",
        "32",
        "--e8-scale",
        "--e8-scale-op",
        args.e8_scale_op,
        "--clip-style",
        "sym",
        "--model-dtype",
        "bfloat16",
        "--w-quant-inplace",
        "--sf-sparse-attention",
        "--topk",
        *(str(value) for value in settings["topk"]),
        "--sf-sparse-block-size",
        "32",
        "--sf-sparse-reduction",
        "mean",
        "--sf-sparse-force-first-block",
        "--sf-sparse-force-diagonal-block",
        "--sf-sparse-dense-fallback",
        "--kl-topk",
        str(args.kl_topk),
        "--output",
        str(output_path),
    ]
    command.append(
        "--attention-hadamard"
        if settings["hadamard"]
        else "--no-attention-hadamard"
    )
    command.append(
        "--local-files-only"
        if args.local_files_only
        else "--no-local-files-only"
    )
    return command


def validate_report(
    path: Path,
    model: dict[str, Any],
    phase: str,
    expected_topk: list[int],
    smoke_max_ppl_change_percent: float,
) -> tuple[bool, str]:
    if not path.exists():
        return False, "result JSON was not created"
    try:
        payload = load_json(path)
    except (OSError, json.JSONDecodeError) as error:
        return False, f"cannot read result JSON: {error}"
    if payload.get("status") != "complete":
        return False, f"report status is {payload.get('status')!r}"
    actual_layers = payload.get("model", {}).get("attention_layers")
    if actual_layers != model["expected_attention_layers"]:
        return False, (
            f"attention adapter coverage {actual_layers}, expected "
            f"{model['expected_attention_layers']}"
        )
    for topk in expected_topk:
        run_key = f"topk_{topk}"
        sparse_run = payload.get("sparse_runs", {}).get(run_key)
        if sparse_run is None:
            return False, f"missing {run_key}"
        fallback_calls = sparse_run.get("aggregate_sparse_stats", {}).get(
            "fallback_calls"
        )
        if fallback_calls != 0:
            return False, f"{run_key} used {fallback_calls} dense fallbacks"
    if phase == "smoke":
        run_key = f"topk_{expected_topk[0]}"
        change = payload["comparisons"][run_key][
            "sparse_vs_dense_ppl_change_percent"
        ]
        if abs(change) > smoke_max_ppl_change_percent:
            return False, (
                f"K-all sparse/dense PPL change {change:+.6f}% exceeds "
                f"{smoke_max_ppl_change_percent:.6f}%"
            )
    return True, "validated"


def initial_state(args: argparse.Namespace, models: list[dict[str, Any]]) -> dict[str, Any]:
    return {
        "format_version": 1,
        "status": "pending",
        "created_at_utc": utc_now(),
        "updated_at_utc": utc_now(),
        "manifest": str(args.manifest),
        "e8_scale_op": args.e8_scale_op,
        "model_order": [model["slug"] for model in models],
        "phases": args.phases,
        "jobs": {},
    }


def load_or_create_state(
    args: argparse.Namespace, models: list[dict[str, Any]], state_path: Path
) -> dict[str, Any]:
    if args.resume and state_path.exists():
        state = load_json(state_path)
        state["e8_scale_op"] = args.e8_scale_op
        state["model_order"] = [model["slug"] for model in models]
        state["phases"] = args.phases
        return state
    return initial_state(args, models)


def update_job(
    state: dict[str, Any],
    state_path: Path,
    job_key: str,
    **values: Any,
) -> None:
    state["jobs"].setdefault(job_key, {}).update(values)
    state["updated_at_utc"] = utc_now()
    write_json_atomic(state_path, state)


def run_and_tee(command: list[str], log_path: Path, env: dict[str, str]) -> int:
    log_path.parent.mkdir(parents=True, exist_ok=True)
    with log_path.open("a", encoding="utf-8") as log:
        log.write(f"\n[{utc_now()}] {' '.join(command)}\n")
        log.flush()
        process = subprocess.Popen(
            command,
            cwd=ROOT,
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
        )
        assert process.stdout is not None
        for line in process.stdout:
            print(line, end="", flush=True)
            log.write(line)
            log.flush()
        return process.wait()


def main() -> int:
    args = parse_args()
    manifest = load_json(args.manifest)
    models = select_models(manifest, args.models)
    args.output_dir.mkdir(parents=True, exist_ok=True)
    state_path = args.output_dir / "queue_state.json"
    state = load_or_create_state(args, models, state_path)
    state["status"] = "running"
    state["updated_at_utc"] = utc_now()
    write_json_atomic(state_path, state)

    env = os.environ.copy()
    env["HF_HOME"] = str(args.hf_home)
    if args.hf_endpoint:
        env["HF_ENDPOINT"] = args.hf_endpoint

    had_failure = False
    for model in models:
        smoke_passed = "smoke" not in args.phases
        for phase in args.phases:
            job_key = f"{model['slug']}::{phase}"
            model_dir = args.output_dir / model["slug"]
            output_path = model_dir / f"{phase}.json"
            log_path = model_dir / f"{phase}.log"
            settings = phase_settings(args, phase)
            command = build_command(args, model, phase, output_path)

            if phase != "smoke" and not smoke_passed:
                update_job(
                    state,
                    state_path,
                    job_key,
                    status="skipped_smoke_failed",
                    ended_at_utc=utc_now(),
                )
                continue

            if args.resume:
                valid, reason = validate_report(
                    output_path,
                    model,
                    phase,
                    settings["topk"],
                    args.smoke_max_ppl_change_percent,
                )
                if valid:
                    print(f"SKIP {job_key}: existing result validated", flush=True)
                    update_job(
                        state,
                        state_path,
                        job_key,
                        status="complete",
                        validation=reason,
                        output=str(output_path),
                    )
                    if phase == "smoke":
                        smoke_passed = True
                    continue

            cached = model_is_cached(args.hf_home, model["model_id"])
            available_gib = free_gib(args.hf_home)
            required_gib = model["weight_size_gib"] + args.download_margin_gib
            if not cached and available_gib < required_gib:
                reason = (
                    f"model is not cached; {available_gib:.2f} GiB free, "
                    f"at least {required_gib:.2f} GiB required"
                )
                print(f"BLOCK {job_key}: {reason}", flush=True)
                update_job(
                    state,
                    state_path,
                    job_key,
                    status="blocked_disk",
                    reason=reason,
                    ended_at_utc=utc_now(),
                )
                state["status"] = "blocked_disk"
                state["updated_at_utc"] = utc_now()
                write_json_atomic(state_path, state)
                return 3

            print(
                f"RUN {job_key}: model={model['model_id']} "
                f"cached={cached} free={available_gib:.2f}GiB",
                flush=True,
            )
            update_job(
                state,
                state_path,
                job_key,
                status="dry_run" if args.dry_run else "running",
                started_at_utc=utc_now(),
                command=command,
                output=str(output_path),
                log=str(log_path),
            )
            if args.dry_run:
                print(" ".join(command), flush=True)
                if phase == "smoke":
                    smoke_passed = True
                continue

            return_code = run_and_tee(command, log_path, env)
            valid, reason = validate_report(
                output_path,
                model,
                phase,
                settings["topk"],
                args.smoke_max_ppl_change_percent,
            )
            complete = return_code == 0 and valid
            update_job(
                state,
                state_path,
                job_key,
                status="complete" if complete else "failed",
                return_code=return_code,
                validation=reason,
                ended_at_utc=utc_now(),
            )
            if phase == "smoke":
                smoke_passed = complete
            if not complete:
                had_failure = True
                print(
                    f"FAIL {job_key}: return_code={return_code}; {reason}",
                    flush=True,
                )
                if not args.continue_on_error:
                    state["status"] = "failed"
                    state["updated_at_utc"] = utc_now()
                    write_json_atomic(state_path, state)
                    return 1

    if args.dry_run:
        state["status"] = "dry_run"
    else:
        state["status"] = (
            "complete_with_failures" if had_failure else "complete"
        )
    state["updated_at_utc"] = utc_now()
    write_json_atomic(state_path, state)
    return 1 if had_failure else 0


if __name__ == "__main__":
    raise SystemExit(main())
