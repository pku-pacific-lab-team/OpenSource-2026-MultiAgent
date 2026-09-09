# Test programs of the V-F / power campaign

Bare-metal C programs, linker script, build flow, OpenOCD configurations and
bench tools used to measure the 44 dies within 11 packages.
Everything here ran on silicon as-is.

## Directory

```
test_programs/
├── Makefile              # make MAIN=<name> -> bin/<name>.elf, build/<name>.{asm,hex}, scripts/<name>.gdb
├── linker.ld             # 32 KB scratchpad at 0x8000_0000
├── src/
│   ├── startup.S         # reset entry: disables the D-cache, sets up the stack, calls main
│   ├── uart.c, uart.h    # bare-metal UART driver and printf (OpenHW Group code, modified)
│   ├── vf_point.c        # V-F screening point: DCO code sweep, cycle-counter frequency, golden test
│   ├── scaling_pwr.c     # full-load power: 1 INT / 1 FP / 4+1 cluster / all 40 cores, data-sparsity knob
│   ├── baseline_pwr.c    # baseline power: all clock gates off, quiet CPU spin and WFI window
│   ├── int_core_pwr.c    # INT core power across compute modes and data sparsity
│   ├── fp_pwr.c          # FP core power across mode, data sparsity and Huffman coding
│   └── sp_pwr.c          # speculative-prefill engine power (three engines and all-on envelope)
├── utils/
│   ├── asm2hex.py        # objdump listing -> hex image
│   ├── 64b_2_128b.py     # 64-bit hex -> 128-bit hex (memory width conversion)
│   └── gdb_scripts.py    # generates scripts/<name>.gdb for loading and running a program
├── openocd/
│   ├── cva6.cfg              # full CPU / GDB access (after the D-cache stub has run)
│   └── cva6_die0_nohalt.cfg  # deferred examine, bus-level (SBA) access only
└── tools/
    ├── sba_tool.py       # read / write / verify 64-bit words through RISC-V System Bus Access
    └── psu_tool.py       # Rigol DP2031 supply: read the three channel currents and the core voltage, set the core rail
```

## Build

Requires a RISC-V GCC toolchain (`rv64imfd_zicsr`, `lp64`) and Python 3.

    make MAIN=vf_point RISCV_GCC=<path>/riscv-none-elf-gcc RISCV_OBJDUMP=<path>/riscv-none-elf-objdump

The Makefile collects the dependencies of `src/<MAIN>.c` automatically, links
with `linker.ld` and `src/startup.S`, and writes `bin/<MAIN>.elf`,
`build/<MAIN>.asm`, `build/<MAIN>.hex` and `scripts/<MAIN>.gdb`.

## Run

1. `openocd -f openocd/cva6.cfg` (FTDI adapter, channel 0, 1 MHz).
2. In GDB: `file bin/<name>.elf`, `load`, then `continue`, or source
   `scripts/<name>.gdb`.
3. Each program writes its PASS/FAIL words and counters to the result area
   `0x8000_7000 .. 0x8000_70FF` (read with `x/gx`) and prints a summary on the
   UART. The power programs expose their run parameters as global variables
   (for example `sparsity_pct`, `n_int`, `n_fp`) that are set from GDB with
   `set var` before `jump _start`; one run gives one measurement point.
4. During a current reading the chip is kept quiet: no UART output and no
   JTAG traffic inside the measurement window.

## Bench tools

- `tools/psu_tool.py read` prints `i1_mA,i2_mA,i3_mA,v2_V` from the Rigol
  DP2031 (channel 2 is the core rail). `psu_tool.py setv 0.76` moves the core
  rail in 40 mV steps with read-back verification; the other channels are
  never touched.
- `tools/sba_tool.py read|write|test` accesses memory through the debug
  module's System Bus Access without halting the CPU. It is used for the
  D-cache stub injection after power-up and for memory probing.

## Silicon notes

- `startup.S` disables the D-cache as its first instruction. On this silicon
  the debug-module region is cacheable, and a halt request with the D-cache
  enabled wedges the debug ROM; every program keeps this instruction.
- The scratchpad is 32 KB (`0x8000_0000 .. 0x8000_7FFF`). Program and data
  must stay below the result area at `0x8000_7000`.
- Accelerator clock gates (`0x2000_0020`) are off after reset and must be
  enabled before a core is accessed; an access to a gated core hangs the CPU.
