"""Write deterministic SHA-256 metadata for the included result files."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RESULTS_DIR = ROOT / "data" / "results"
OUTPUT = RESULTS_DIR / "SHA256SUMS.json"


def collect_entries() -> list[dict[str, str | int]]:
    entries = []
    for path in sorted(RESULTS_DIR.rglob("*")):
        if not path.is_file() or path == OUTPUT:
            continue
        payload = path.read_bytes()
        entries.append(
            {
                "path": path.relative_to(ROOT).as_posix(),
                "bytes": len(payload),
                "sha256": hashlib.sha256(payload).hexdigest(),
            }
        )
    return entries


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--check",
        action="store_true",
        help="Verify the committed checksum manifest instead of rewriting it",
    )
    args = parser.parse_args()
    entries = collect_entries()
    payload = {"algorithm": "sha256", "files": entries}
    if args.check:
        expected = json.loads(OUTPUT.read_text(encoding="utf-8"))
        if payload != expected:
            raise SystemExit("checksum verification failed")
        print(f"Verified {len(entries)} checksums from {OUTPUT}")
        return

    temporary = OUTPUT.with_suffix(".json.tmp")
    # Force LF so the manifest bytes are identical on every platform.
    temporary.write_text(
        json.dumps(payload, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    temporary.replace(OUTPUT)
    print(f"Wrote {len(entries)} checksums to {OUTPUT}")


if __name__ == "__main__":
    main()
