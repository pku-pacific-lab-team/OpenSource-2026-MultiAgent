#!/usr/bin/env python3
# Copyright 2025-2026 School of Integrated Circuits, Peking University
# SPDX-License-Identifier: Apache-2.0
#
"""Check the published top-level interface without claiming full-SoC elaboration.

Compile the real pad top against headers extracted from its real SoC source
and the pad-wrapper source. Bodies are intentionally empty: this checks
port connectivity, not SoC or physical-pad behavior.
"""
import argparse
import json
import re
import subprocess
import sys
import time
from pathlib import Path

RTL = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, default=RTL / 'build/top_interface')
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)

    prefix = '${SRC_DIR}/'
    for line in (RTL / 'filelist.f').read_text().splitlines():
        if line.strip().startswith(prefix):
            rel = line.strip()[len(prefix):]
            if not (RTL / rel).is_file():
                raise SystemExit(f'File-list source missing: {rel}')

    pads = (RTL / 'tech_specific/signal_io_pad.v').read_text()
    pad_headers = re.findall(r'^module\s+\w+\s*\(.*?^\);', pads, re.M | re.S)
    if len(pad_headers) != 4:
        raise SystemExit('Pad-wrapper header extraction changed; inspect source')
    rows = []
    for label, suffix in [('primary', '')]:
        soc = (RTL / f'soc_noc{suffix}.sv').read_text()
        header = re.search(r'^module soc_noc\s*\(.*?^\);', soc, re.M | re.S)
        if header is None:
            raise SystemExit('SoC port declaration could not be extracted')
        stub = out / f'{label}_interface_stubs.sv'
        stub.write_text('\n\n'.join(part + '\nendmodule' for part in
                                    [header.group(), *pad_headers]) + '\n')
        for mode, defines in [('asic', []), ('sim', ['+define+SIM'])]:
            name = f'{label}_{mode}_interface'
            command = ['verilator', '--lint-only', '-Wno-fatal', '-Werror-PINMISSING',
                       '--top-module', 'soc_noc_top', '--Mdir', str(out / ('obj_' + name)),
                       *defines, str(RTL / f'soc_noc_top{suffix}.sv'), str(stub)]
            start = time.time()
            result = subprocess.run(command, capture_output=True, text=True, timeout=120)
            (out / f'{name}.log').write_text(result.stdout + result.stderr)
            rows.append(dict(name=name, kind='interface_check', command=command,
                             exit_code=result.returncode, log=f'{name}.log',
                             seconds=round(time.time() - start, 2)))
            print(name, 'PASS' if result.returncode == 0 else 'FAIL', flush=True)
    (out / 'results.json').write_text(json.dumps(rows, indent=2) + '\n')
    print('File-list checks passed; interface checks use header-only stubs.')
    return any(row['exit_code'] for row in rows)


if __name__ == '__main__':
    sys.exit(main())
