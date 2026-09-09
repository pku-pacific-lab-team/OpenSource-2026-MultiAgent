#!/usr/bin/env python3
# ------------------------------------------------------------------------------
# Description:     Read, write and verify 64-bit memory words through RISC-V System Bus Access
# Author:          Mingxuan Li
# Acknowledgement: Claude Code + Claude Fable 5
# Date:            2026-07-14
# ------------------------------------------------------------------------------
"""Read, write, and verify 64-bit memory accesses through RISC-V SBA."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import os
import re
import sys
import warnings

with warnings.catch_warnings():
  warnings.simplefilter("ignore", DeprecationWarning)
  import telnetlib


DEFAULT_HOST = "127.0.0.1"
DEFAULT_PORT = 4444
DEFAULT_TAP = "riscv.cpu"
DEFAULT_WAIT_CYCLES = 1000
DEFAULT_TEST_ADDRESS = 0x80001FF8

DMCONTROL = 0x10
SBCS = 0x38
SBADDRESS0 = 0x39
SBADDRESS1 = 0x3A
SBDATA0 = 0x3C
SBDATA1 = 0x3D

DMI_OP_NOP = 0
DMI_OP_READ = 1
DMI_OP_WRITE = 2
DMI_STATUS_SUCCESS = 0
DMI_STATUS_FAILED = 2
DMI_STATUS_BUSY = 3

SBCS_SBERROR_MASK = 0x7 << 12
SBCS_SBACCESS_64 = 3 << 17
SBCS_SBREADONADDR = 1 << 20
SBCS_SBBUSY = 1 << 21
SBCS_SBBUSYERROR = 1 << 22

VERIFIED_SPM_START = 0x80000000
VERIFIED_SPM_END = 0x80007FFF  # full 32KB confirmed by spm_probe (summary section 15)
VERIFIED_DM_READ_ADDRESS = 0x400


class SbaError(RuntimeError):
  """An OpenOCD, DMI, or SBA operation failed."""


def parse_u64(text: str) -> int:
  try:
    value = int(text, 0)
  except ValueError as exc:
    raise argparse.ArgumentTypeError(f"invalid integer: {text}") from exc
  if not 0 <= value <= 0xFFFFFFFFFFFFFFFF:
    raise argparse.ArgumentTypeError(f"value outside unsigned 64-bit range: {text}")
  return value


def env_int(name: str, default: int) -> int:
  value = os.environ.get(name)
  return default if value is None else int(value, 0)


def validate_address(address: int, operation: str, force: bool) -> None:
  if address & 0x7:
    raise SbaError(f"0x{address:016x} is not aligned to 8 bytes")
  if address > 0xFFFFFFFFFFFFFFF8:
    raise SbaError(f"0x{address:016x} cannot hold one 64-bit access")

  in_verified_spm = VERIFIED_SPM_START <= address <= VERIFIED_SPM_END - 7
  known_safe_read = operation == "read" and address == VERIFIED_DM_READ_ADDRESS
  if force or in_verified_spm or known_safe_read:
    return

  raise SbaError(
      f"0x{address:016x} is outside the verified SBA window "
      f"0x{VERIFIED_SPM_START:08x}..0x{VERIFIED_SPM_END:08x}; "
      "use --force only when a board-level reset is available"
  )


class OpenOcdTelnet:
  PROMPT = b"\r> "

  def __init__(
      self,
      host: str,
      port: int,
      tap: str,
      timeout: float,
      raw: bool,
  ) -> None:
    self.tap = tap
    self.timeout = timeout
    self.raw = raw
    self.connection = telnetlib.Telnet(host, port, timeout)
    greeting = self.connection.read_until(self.PROMPT, timeout)
    if not greeting.endswith(self.PROMPT):
      self.connection.close()
      raise SbaError(f"OpenOCD telnet port {host}:{port} did not return a prompt")

  def close(self) -> None:
    self.connection.close()

  def __enter__(self) -> OpenOcdTelnet:
    return self

  def __exit__(self, *_args: object) -> None:
    self.close()

  def command(self, command: str) -> str:
    self.connection.write(command.encode("ascii") + b"\n")
    raw_output = self.connection.read_until(self.PROMPT, self.timeout)
    if not raw_output.endswith(self.PROMPT):
      raise SbaError(f"OpenOCD timed out while executing: {command}")

    output = raw_output.decode("ascii", errors="replace").replace("\x00", "")
    lines = output.replace("\r\n", "\n").replace("\r", "\n").splitlines()
    payload = "\n".join(
        line for line in lines if line.strip() not in {command, ">"}
    ).strip()

    if self.raw:
      print(f"> {command}", file=sys.stderr)
      if payload:
        print(payload, file=sys.stderr)
    return payload

  def irscan(self, instruction: int) -> None:
    output = self.command(f"irscan {self.tap} 0x{instruction:x}")
    if output:
      raise SbaError(f"irscan failed: {output}")

  def drscan(self, bits: int, value: int) -> int:
    command = f"drscan {self.tap} {bits} 0x{value:x}"
    output = self.command(command)
    matches = re.findall(
        r"(?m)^\s*(?:0x)?([0-9a-fA-F]{8,12})\s*$",
        output,
    )
    if not matches:
      raise SbaError(f"drscan returned no hexadecimal response: {output or '<empty>'}")
    result = int(matches[-1], 16)
    if result >= 1 << bits:
      raise SbaError(f"drscan response 0x{result:x} exceeds {bits} bits")
    return result

  def runtest(self, cycles: int) -> None:
    output = self.command(f"runtest {cycles}")
    if output:
      raise SbaError(f"runtest failed: {output}")


class DmiInterface:
  def __init__(self, transport: OpenOcdTelnet, idle_cycles: int = 50) -> None:
    self.transport = transport
    self.idle_cycles = idle_cycles
    self.abits = 7

  @property
  def scan_width(self) -> int:
    return 34 + self.abits

  def reset(self) -> int:
    self.transport.irscan(0x10)
    self.transport.drscan(32, 1 << 16)
    dtmcs = self.transport.drscan(32, 0)

    version = dtmcs & 0xF
    self.abits = (dtmcs >> 4) & 0x3F
    advertised_idle = (dtmcs >> 12) & 0x7
    self.idle_cycles = max(self.idle_cycles, advertised_idle)
    if version != 1:
      raise SbaError(f"unsupported DTM version {version} (dtmcs=0x{dtmcs:08x})")
    if self.abits == 0:
      raise SbaError(f"DTM reported zero DMI address bits (dtmcs=0x{dtmcs:08x})")

    self.transport.irscan(0x11)
    return dtmcs

  def _request(self, register: int, data: int, operation: int) -> int:
    if not 0 <= register < 1 << self.abits:
      raise SbaError(f"DMI register 0x{register:x} exceeds abits={self.abits}")
    request = (register << 34) | ((data & 0xFFFFFFFF) << 2) | operation
    self.transport.drscan(self.scan_width, request)
    self.transport.runtest(self.idle_cycles)
    response = self.transport.drscan(self.scan_width, DMI_OP_NOP)

    status = response & 0x3
    response_data = (response >> 2) & 0xFFFFFFFF
    if status == DMI_STATUS_SUCCESS:
      return response_data
    if status == DMI_STATUS_BUSY:
      raise SbaError(
          f"DMI remained busy while accessing register 0x{register:02x}; "
          "reset DMI or increase wait cycles"
      )
    if status == DMI_STATUS_FAILED:
      raise SbaError(f"DMI access failed for register 0x{register:02x}")
    raise SbaError(f"DMI returned reserved status {status} for register 0x{register:02x}")

  def read(self, register: int) -> int:
    return self._request(register, 0, DMI_OP_READ)

  def write(self, register: int, data: int) -> None:
    self._request(register, data, DMI_OP_WRITE)


@dataclass(frozen=True)
class SbcsStatus:
  raw: int
  sbaccess64: bool
  sbasize: int
  sberror: int
  sbbusy: bool
  sbbusyerror: bool
  sbversion: int

  @classmethod
  def decode(cls, value: int) -> SbcsStatus:
    return cls(
        raw=value,
        sbaccess64=bool(value & (1 << 3)),
        sbasize=(value >> 5) & 0x7F,
        sberror=(value >> 12) & 0x7,
        sbbusy=bool(value & SBCS_SBBUSY),
        sbbusyerror=bool(value & SBCS_SBBUSYERROR),
        sbversion=(value >> 29) & 0x7,
    )

  def ensure_ready(self, context: str) -> None:
    if self.sbbusy or self.sbbusyerror or self.sberror:
      raise SbaError(
          f"{context}: sbcs=0x{self.raw:08x}, sbbusy={int(self.sbbusy)}, "
          f"sbbusyerror={int(self.sbbusyerror)}, sberror={self.sberror}"
      )

  def summary(self) -> str:
    return (
        f"sbcs=0x{self.raw:08x} sbbusy={int(self.sbbusy)} "
        f"sbbusyerror={int(self.sbbusyerror)} sberror={self.sberror}"
    )


class SbaSession:
  def __init__(self, transport: OpenOcdTelnet, wait_cycles: int) -> None:
    self.transport = transport
    self.dmi = DmiInterface(transport)
    self.wait_cycles = wait_cycles

  def _prepare(self) -> None:
    self.dmi.reset()
    self.dmi.write(DMCONTROL, 1)
    status = SbcsStatus.decode(self.dmi.read(SBCS))

    if status.sbbusy:
      status.ensure_ready("SBA preflight")
    if status.sbbusyerror or status.sberror:
      self.dmi.write(SBCS, SBCS_SBBUSYERROR | SBCS_SBERROR_MASK)
      status = SbcsStatus.decode(self.dmi.read(SBCS))
      status.ensure_ready("SBA error clear")
    if not status.sbaccess64:
      raise SbaError(f"Debug Module does not advertise 64-bit SBA (sbcs=0x{status.raw:08x})")

  def read64(self, address: int) -> tuple[int, SbcsStatus]:
    self._prepare()
    self.dmi.write(SBCS, SBCS_SBACCESS_64 | SBCS_SBREADONADDR)
    self.dmi.write(SBADDRESS1, address >> 32)
    self.dmi.write(SBADDRESS0, address & 0xFFFFFFFF)
    self.transport.runtest(self.wait_cycles)

    status = SbcsStatus.decode(self.dmi.read(SBCS))
    status.ensure_ready("SBA read")
    low = self.dmi.read(SBDATA0)
    high = self.dmi.read(SBDATA1)
    return (high << 32) | low, status

  def write64(self, address: int, value: int) -> SbcsStatus:
    self._prepare()
    self.dmi.write(SBCS, SBCS_SBACCESS_64)
    self.dmi.write(SBADDRESS1, address >> 32)
    self.dmi.write(SBADDRESS0, address & 0xFFFFFFFF)
    self.dmi.write(SBDATA1, value >> 32)
    self.dmi.write(SBDATA0, value & 0xFFFFFFFF)
    self.transport.runtest(self.wait_cycles)

    status = SbcsStatus.decode(self.dmi.read(SBCS))
    status.ensure_ready("SBA write")
    return status


def read_and_report(session: SbaSession, address: int, label: str = "READ") -> int:
  value, status = session.read64(address)
  print(f"{label} 0x{address:016x} = 0x{value:016x}  {status.summary()}")
  return value


def require_equal(actual: int, expected: int, context: str) -> None:
  if actual != expected:
    raise SbaError(
        f"{context}: expected 0x{expected:016x}, read 0x{actual:016x}"
    )


def run_pattern_test(
    session: SbaSession,
    address: int,
    pattern_a: int,
    pattern_b: int,
) -> None:
  original = read_and_report(session, address, "ORIGINAL")
  restore_required = False
  primary_error: Exception | None = None

  try:
    restore_required = True
    status = session.write64(address, pattern_a)
    print(f"WRITE_A 0x{address:016x} <- 0x{pattern_a:016x}  {status.summary()}")
    require_equal(read_and_report(session, address, "READ_A"), pattern_a, "pattern A")

    status = session.write64(address, pattern_b)
    print(f"WRITE_B 0x{address:016x} <- 0x{pattern_b:016x}  {status.summary()}")
    require_equal(read_and_report(session, address, "READ_B"), pattern_b, "pattern B")
  except Exception as exc:  # Restore is still required after any attempted write.
    primary_error = exc
  finally:
    if restore_required:
      try:
        status = session.write64(address, original)
        print(f"RESTORE 0x{address:016x} <- 0x{original:016x}  {status.summary()}")
        restored = read_and_report(session, address, "RESTORED")
        require_equal(restored, original, "restore")
      except Exception as restore_error:
        if primary_error is not None:
          raise SbaError(
              f"test failed ({primary_error}); restore also failed ({restore_error})"
          ) from restore_error
        raise

  if primary_error is not None:
    raise primary_error
  print("TEST PASS: both patterns matched and the original value was restored")


def build_parser() -> argparse.ArgumentParser:
  parser = argparse.ArgumentParser(
      description="Access the RISC-V Debug Module System Bus Access port through OpenOCD."
  )
  parser.add_argument("--host", default=DEFAULT_HOST, help="OpenOCD telnet host")
  parser.add_argument(
      "--port",
      type=int,
      default=env_int("OPENOCD_TELNET_PORT", DEFAULT_PORT),
      help="OpenOCD telnet port (default: 4444)",
  )
  parser.add_argument("--tap", default=DEFAULT_TAP, help="OpenOCD JTAG tap name")
  parser.add_argument(
      "--wait-cycles",
      type=int,
      default=env_int("SBA_WAIT_CYCLES", DEFAULT_WAIT_CYCLES),
      help="JTAG run-test/idle cycles after each SBA bus transaction",
  )
  parser.add_argument("--timeout", type=float, default=5.0, help="telnet command timeout")
  parser.add_argument("--raw", action="store_true", help="print raw OpenOCD commands and replies")

  subparsers = parser.add_subparsers(dest="operation", required=True)

  read_parser = subparsers.add_parser("read", help="read one aligned 64-bit value")
  read_parser.add_argument("address", type=parse_u64)
  read_parser.add_argument("--force", action="store_true", help="allow an unverified address")

  write_parser = subparsers.add_parser("write", help="write one aligned 64-bit value")
  write_parser.add_argument("address", type=parse_u64)
  write_parser.add_argument("value", type=parse_u64)
  write_parser.add_argument("--verify", action="store_true", help="read back and compare")
  write_parser.add_argument("--force", action="store_true", help="allow an unverified address")

  test_parser = subparsers.add_parser(
      "test",
      help="write two patterns, compare each readback, and restore the original value",
  )
  test_parser.add_argument("address", type=parse_u64, nargs="?", default=DEFAULT_TEST_ADDRESS)
  test_parser.add_argument("--pattern-a", type=parse_u64, default=0x0123456789ABCDEF)
  test_parser.add_argument("--pattern-b", type=parse_u64, default=0xFEDCBA9876543210)
  test_parser.add_argument("--force", action="store_true", help="allow an unverified address")
  return parser


def main() -> int:
  args = build_parser().parse_args()
  try:
    validate_address(args.address, args.operation, args.force)
    if args.wait_cycles < 1:
      raise SbaError("--wait-cycles must be positive")

    with OpenOcdTelnet(
        args.host,
        args.port,
        args.tap,
        args.timeout,
        args.raw,
    ) as transport:
      session = SbaSession(transport, args.wait_cycles)
      if args.operation == "read":
        read_and_report(session, args.address)
      elif args.operation == "write":
        status = session.write64(args.address, args.value)
        print(
            f"WRITE 0x{args.address:016x} <- 0x{args.value:016x}  "
            f"{status.summary()}"
        )
        if args.verify:
          require_equal(
              read_and_report(session, args.address, "VERIFY"),
              args.value,
              "write verification",
          )
          print("VERIFY PASS")
      else:
        run_pattern_test(session, args.address, args.pattern_a, args.pattern_b)
  except (OSError, EOFError, SbaError) as exc:
    print(f"ERROR: {exc}", file=sys.stderr)
    return 1
  return 0


if __name__ == "__main__":
  sys.exit(main())
