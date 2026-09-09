# RTL implementation

**SystemVerilog sources of the die: the MX/SF accelerator cluster, the
speculative prefill scheduler and the chiplet SoC integration, with
reproducible Verilator subsystem tests.**

The accelerator cluster contains four INT cores and one FP core. The INT
cores implement signed 4-bit MAC arrays, scaling-factor arrays, and sparse
attention bucket reduction. The FP core converts four MXINT16 input streams
to BF16, adds them, and quantizes the results to packed 4-bit outputs. The
surrounding SoC integrates CVA6, FlooNoC, DMA, an AXI LLC, two die-to-die
serial links and peripherals. Eight clusters (32 INT + 8 FP cores) sit on the
5x8 compute mesh of one die.

The supplied build targets cover subsystem simulation, top-level interface
checks and a full-SoC elaboration. See [Testing](#testing) for commands and
supported configurations.

[Quick start](#quick-start) |
[Architecture](docs/architecture.md) |
[Testing](#testing) |
[Die-to-die links](#die-to-die-links) |
[Notes on the tree](#notes-on-the-tree)

## Requirements

The recorded runs use **Verilator 5.050**, Python 3.9.6, GNU Make, and Apple
Clang on macOS arm64. The release regression was repeated on Linux (CentOS 7)
with Verilator 5.024, GCC 12.2 and Python 3.8. Python scripts use only the
standard library. A C++ compiler with the coroutine support required by
Verilator `--timing` must be available. Other tool versions and platforms
have not been validated. No GPU, PyTorch environment, model weights, or
RISC-V cross compiler is needed for the subsystem tests.

Two observations from the Linux runs:

- Verilator picks up `ccache` automatically. On a machine whose cache
  contained object files from earlier builds, the resulting simulation
  binaries crashed at run time while freshly compiled binaries pass; the
  runs were therefore made with `CCACHE_DISABLE=1`.
- `make lint` disables the Verilator restriction checks `BLKANDNBLK` and
  `BLKLOOPINIT` (continuous and clocked assignments to elements of one array
  in the FPnew pipeline registers; clocked byte-enable writes to the generic
  `tc_sram` array inside a loop) and turns off the DFG optimiser
  (`-fno-dfg`), which terminates with an internal error in Verilator 5.024 on
  this design. Neither is a design error; the flags are documented in
  `verification/run_dco_checks.py`.

Install Verilator using its [official installation instructions](https://verilator.org/guide/latest/install.html),
then check the tools before running:

```bash
verilator --version
python3 --version
make --version
c++ --version
```

## Quick start

From a new checkout:

```bash
git clone https://github.com/pku-pacific-lab-team/OpenSource-2026-MultiAgent.git
cd OpenSource-2026-MultiAgent/rtl
make test
```

`make test` builds and runs 16 self-checking simulations: the core/address/
cluster suite and the DCO register/clock/AXI suite. Each mismatch or timeout
causes a nonzero exit. Logs, build commands, and return codes are written to
`build/core/` and `build/dco/`. Compilation uses four parallel jobs per binary.
Two additional header-based top-level interface checks verify the pad top in
ASIC and SIM modes; their logs are in `build/top_interface/`. These are
connectivity checks, not full-SoC simulation.

To include all seven tested FP parallel widths and a second INT random seed:

```bash
make extended
```

This includes `make test` and runs 23 simulations in total. It generates fresh
FP vectors with an independent scalar Python reference model. Build products
and locally generated logs are ignored by Git.

To elaborate the complete SoC (all sources of `filelist.f`, top module
`soc_noc_top`) with the technology-independent cell models:

```bash
make lint
```

For a focused rerun:

```bash
python3 verification/run_dco_checks.py --only axi --out build/axi
python3 verification/run_regression.py --only fp --width 16 \
  --seed 260916 --out build/fp_p16
```

## Testing

`make test` runs the INT/FP, reduction, address-attribute, cluster, and DCO
suites. `make extended` includes all seven FP widths (1, 2, 4, 8, 16, 32, 64)
and a second INT random seed. Both targets also check the pad-level top port
interface in ASIC and SIM configurations. `make lint` runs Verilator in
lint-only mode over the complete file list; it is the check that every module
of the release elaborates together.

The Python vector generator models the RTL's converter encoding, BF16
round-to-nearest-even addition, and quantizer magnitude half-up rounding with
saturation. The software model and RTL have separate numerical contracts.
The clock tests use external-clock operation with the behavioural cell models
of `tech_specific/`; they exercise the divider logic and register block, not
an oscillator or physical timing. Top-interface checks use extracted port
declarations and do not execute the full SoC.

For a focused component test, select a target with `--only` and put its output
in a separate `--out` directory. Runners write commands, return codes, and logs
locally, and return nonzero on a failed check or timeout. `make clean` removes
the generated `build/` directory.

## Die-to-die links

Each die has two source-synchronous serial links to its neighbours
(`soc_axi/serial_link/`, instantiated twice in `soc_noc.sv`), plus a third
link of the same type towards the external memory bridge. Every link has two
data lanes per direction and transfers data on both edges of a forwarded
clock (`NumLanes = 2`, `EnDdr = 1`, 4 bits per link clock cycle,
`regs/slink_reg_pkg.sv`). The link clock is the core clock divided by the
programmable `clk_div` of the TX PHY, so the raw line rate per link and
direction is

```text
rate = 2 lanes x 2 edges x f_core / clk_div = 4 x f_core / clk_div
```

`clk_div = 2` is the fastest usable setting (with `clk_div = 1` the data
register is loaded only every second cycle while a word is accepted every
cycle). At 990 MHz this gives 1.98 Gb/s per link and 3.96 Gb/s for the two
die-to-die links of one die. The reset values of the TX PHY registers are
`clk_div = 8`, `clk_shift_start = 2`, `clk_shift_end = 6`
(`regs/slink_reg.sv`), i.e. 0.99 Gb/s for the two links; for `clk_div = 2`
the shift-start/end values must lie inside the two-cycle period (for example
0 and 1), otherwise the forwarded clock never toggles. The figures are raw
line rates: the serialized stream also carries AXI channel headers, credits
and padding, so the payload throughput is lower. Link timing was not
characterized on silicon.

## Hardware and software relationship

The sibling [`model/`](../model/) directory evaluates model-level fake
quantization and SF-based block selection in PyTorch. `rtl/` provides hardware
building blocks and their own testbenches. The two components have separate
execution flows and numerical reference models. The RTL rounding, saturation,
and data-packing rules are specified in the
[architecture guide](docs/architecture.md) and block specifications.

## Repository layout

Hardware sources, specifications, and verification utilities are organized
under `rtl/` by subsystem.

| Path | Purpose |
|---|---|
| [int_core/](int_core/) | INT MAC, SF, and SpAttn RTL, specifications, and tests |
| [fp_core/](fp_core/) | MX-to-BF16 conversion, addition, quantization, and tests |
| [core_cluster/](core_cluster/) | Four INT cores plus one FP core, clock gating, and cluster test |
| [spec_prefill/](spec_prefill/) | HDC encoder, team predictor and online learner of the speculative prefill scheduler, specifications, and tests |
| [cpu_cva6/](cpu_cva6/) | CVA6, caches, MMU, and FPU |
| [floo_noc/](floo_noc/), [floo_agent_noc.sv](floo_agent_noc.sv) | NoC components and the generated system topology |
| [idma/](idma/), [soc_axi/](soc_axi/) | DMA, AXI infrastructure, LLC, debug, serial links, and peripherals |
| [misc_common/](misc_common/), [include/](include/) | Shared primitives, packages, and interface headers |
| [tech_specific/](tech_specific/) | Behavioural, technology-independent models of the cells the die implements with foundry macros: SRAM/register-file wrappers, clock cells, pads, clock generator |
| [soc_noc_top.sv](soc_noc_top.sv), [soc_noc.sv](soc_noc.sv), [soc_pkg.sv](soc_pkg.sv) | Chip top, SoC integration, and address constants |
| [filelist.f](filelist.f) | Dependency-ordered SoC source list |
| [verification/](verification/) | Portable test runners and the scalar reference model of the FP vectors |
| [docs/](docs/) | Architecture, interfaces, and verification documentation |

## Integration sources

[`filelist.f`](filelist.f) uses `${SRC_DIR}` as the root of the hardware source
tree. Preserve its package ordering when adapting it to an integration flow.
From `rtl/`, set the source root with:

```bash
export SRC_DIR="$PWD"
```

The provided Make targets support subsystem verification and full-SoC
elaboration. A silicon implementation requires technology-specific SRAM, pad,
clock-cell and clock-generator implementations in place of the behavioural
models of `tech_specific/`; the clock generator model is simulation-only and a
synthesis target drives the SoC from the external clock input.

## Notes on the tree

- The die integrates a third-party accelerator whose sources are not part of
  this tree. Its NoC endpoint (`aux_slot_slave`) is kept and terminated by an
  AXI error slave, so the address map and the topology are complete.
- Foundry cells (SRAM macros, clock cells, pads, the ring-oscillator clock
  generator) are represented by the behavioural models in `tech_specific/`;
  on-die temperature sensors are not included.
- Every die runs one hart with `mhartid = 0`. The position of a die in the
  2x2 module is set by the `soc_id_i` pins and selects its address windows
  (`soc_pkg.sv`); software distinguishes dies by the address window it runs
  in, not by the hart id.

## License and provenance

This tree contains project sources and third-party RTL with different
licenses. Sources written for this project are licensed under
`Apache-2.0 WITH SHL-2.1` (copyright School of Integrated Circuits, Peking
University); third-party files keep their original headers and carry a
modification notice where they were changed. The Apache-2.0 terms of the
software parts do not replace file-level Solderpad or LGPL terms. The license
map is in [LICENSE.md](../LICENSE.md), the component inventory with the
matched upstream revisions in [THIRD_PARTY.md](../THIRD_PARTY.md) and the
license texts in [LICENSES/](../LICENSES/), all at the repository root; the
file-by-file provenance of this tree is [provenance.csv](provenance.csv).
