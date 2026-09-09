#!/usr/bin/env python3
# ------------------------------------------------------------------------------
# Description:     Rigol DP2031 bench supply control for the V-F/power campaign
# Author:          Mingxuan Li
# Acknowledgement: Claude Code + Claude Fable 5
# Date:            2026-07-16
# ------------------------------------------------------------------------------
# Only channel 2 (core rail) is ever written: clamped to [0.40, 1.20] V,
# stepped in <= 40 mV increments with read-back verification. Channels 1/3,
# output switches and current limits are never touched.
#
# Usage:
#   python psu_tool.py read            -> i1_mA,i2_mA,i3_mA,v2_V (one line)
#   python psu_tool.py setv 0.76       -> stepped CH2 transition + verify
import argparse
import sys
import time

import pyvisa

RESOURCE = "USB0::6833::42152::DP2A265100999::0::INSTR"
VMIN, VMAX, VSTEP = 0.40, 1.20, 0.040  # F5-ext bounds
TOL_V = 0.015  # measured-vs-setpoint tolerance after settle (CC/wiring guard)


def open_inst():
    mgr = pyvisa.ResourceManager("@py")
    inst = mgr.open_resource(RESOURCE)
    inst.timeout = 5000
    return inst


def cmd_read(_args):
    inst = open_inst()
    i = [float(inst.query(f":MEAS:CURR? CH{n}")) for n in (1, 2, 3)]
    v2 = float(inst.query(":MEAS:VOLT? CH2"))
    inst.close()
    print(f"{i[0]*1000:.3f},{i[1]*1000:.3f},{i[2]*1000:.3f},{v2:.4f}")


def cmd_setv(args):
    target = round(args.volts, 4)
    if not (VMIN <= target <= VMAX):
        sys.exit(f"refused: {target} V outside authorized [{VMIN}, {VMAX}] V")
    inst = open_inst()
    out_state = inst.query(":OUTP? CH2").strip().upper()
    if out_state not in ("1", "ON"):
        inst.close()
        sys.exit(f"refused: CH2 output reads '{out_state}', not ON -- human check needed")
    cur = float(inst.query(":SOUR2:VOLT?"))
    # never step FROM an out-of-range setpoint either: intermediate values
    # would cross unauthorized territory (codex-review finding 3)
    if not (cur == cur) or not (VMIN <= cur <= VMAX):
        inst.close()
        sys.exit(f"refused: current setpoint {cur} V outside authorized range -- human check needed")
    while abs(cur - target) > 1e-4:
        step = max(-VSTEP, min(VSTEP, target - cur))
        cur = round(cur + step, 4)
        inst.write(f":SOUR2:VOLT {cur:.3f}")
        time.sleep(0.3)
        rb = float(inst.query(":SOUR2:VOLT?"))
        if abs(rb - cur) > 2e-3:
            inst.close()
            sys.exit(f"readback mismatch: wrote {cur:.3f}, read {rb:.3f}")
    time.sleep(0.5)
    meas = float(inst.query(":MEAS:VOLT? CH2"))
    inst.close()
    # verify the real output, not just the programmed setpoint (finding 4)
    if abs(meas - target) > TOL_V:
        sys.exit(
            f"FAIL: CH2 set {target:.3f} V but measured {meas:.4f} V "
            f"(>±{TOL_V*1000:.0f} mV) -- CC mode / wiring / load suspected"
        )
    print(f"CH2 set {target:.3f} V, meas {meas:.4f} V")


def main():
    p = argparse.ArgumentParser(description=__doc__)
    sub = p.add_subparsers(dest="cmd", required=True)
    sub.add_parser("read", help="one reading: i1_mA,i2_mA,i3_mA,v2_V")
    sp = sub.add_parser("setv", help="set CH2 voltage (stepped, verified)")
    sp.add_argument("volts", type=float)
    args = p.parse_args()
    {"read": cmd_read, "setv": cmd_setv}[args.cmd](args)


if __name__ == "__main__":
    main()
