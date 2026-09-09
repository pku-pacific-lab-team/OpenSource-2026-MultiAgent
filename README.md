# OpenSource-2026-MultiAgent

**Design and evaluation artifacts of a 12 nm multi-agent LLM inference
chiplet: the software reference model, the synthesizable RTL of the die, and
the silicon operating points with the test programs used on the bench.**

The die integrates 32 INT cores and 8 FP cores on a 5x8 compute mesh, a
RISC-V CVA6 host, a hyperdimensional-computing speculative prefill scheduler,
a last-level cache, DMA engines and two die-to-die serial links; four identical
dies form a 2x2 module. The INT cores carry a sparse attention scorer array
that estimates the importance of attention blocks from the shared scaling
factors of the microscaling (MX) number format and skips the unimportant
blocks. The software model evaluates the accuracy side of the same scheme on
public language models.

## Repository parts

| Directory | Content | Entry point | Self-check |
|---|---|---|---|
| [`model/`](model/) | PyTorch reference of MXINT4/8 fake quantization and SF-hinted block selection; benchmark data of 11 language models with provenance and checksums | [model/README.md](model/README.md) | `cd model && python -m pytest tests -q` |
| [`rtl/`](rtl/) | SystemVerilog sources of the die (accelerator cores, scheduler, SoC integration on open-source IP), block specifications, Verilator regression | [rtl/README.md](rtl/README.md) | `cd rtl && make test` |
| [`silicon/`](silicon/) | Operating points and V-F-P tables of the die, Vmin distribution of the measured dies, and the bare-metal test programs, OpenOCD configurations and bench tools of the measurement campaign | [silicon/README.md](silicon/README.md) | see the README |

## Where each feature lives

| Feature | Hardware | Model / data |
|---|---|---|
| SF-hinted block-sparse attention (scorer array, bucket shift-accumulation, reduction tree, Top-K block selection) | [`rtl/int_core/`](rtl/int_core/) (`sf.sv`, `sf_array.sv`, `sum_reduce.sv`, `adder_tree.sv`, `int_core.sv`), specifications in `rtl/int_core/spec/` | [`model/quant/sparse_attention.py`](model/quant/sparse_attention.py), [`model/quant/quant_attention.py`](model/quant/quant_attention.py); results in [`model/data/results/`](model/data/results/) |
| MX-format arithmetic (MXINT4/8 quantization, MX to BF16 conversion, accumulation, requantization) | [`rtl/fp_core/`](rtl/fp_core/), INT MAC array in `rtl/int_core/src/pe*.sv` | [`model/quant/quant_func.py`](model/quant/quant_func.py), [`model/quant/quant_linear.py`](model/quant/quant_linear.py) |
| Speculative prefill scheduler (HDC encoder, similarity-based team predictor, online learner) | [`rtl/spec_prefill/`](rtl/spec_prefill/), specifications in `rtl/spec_prefill/spec/` | - |
| Chiplet SoC integration on open-source hardware (CVA6, FlooNoC mesh, iDMA, AXI LLC, die-to-die serial links) | [`rtl/soc_noc.sv`](rtl/soc_noc.sv), [`rtl/floo_agent_noc.sv`](rtl/floo_agent_noc.sv), [`rtl/soc_axi/`](rtl/soc_axi/), [`rtl/idma/`](rtl/idma/), [`rtl/cpu_cva6/`](rtl/cpu_cva6/) | - |
| Silicon operating points (supply, frequency, power, throughput, efficiency) and measurement method | [`silicon/test_programs/`](silicon/test_programs/) | [`silicon/data/`](silicon/data/) |

## Verifying the artifacts

- Model: the CPU regression tests need no GPU and no model download; the
  checksum manifest of the benchmark data is verified with
  `python scripts/write_checksums.py --check` from `model/`.
- RTL: `make test` in `rtl/` builds and runs the self-checking Verilator
  regressions of the compute cores, the accelerator cluster, the address
  attributes and the clock/register blocks; `make lint` elaborates the full
  SoC with the technology-independent cell models.
- Silicon: the tables are plain CSV with units in the header row and in
  `silicon/README.md`.

## License

The license map of the parts is in [LICENSE.md](LICENSE.md) and the license
texts are in [LICENSES/](LICENSES/). In short: software (`model/`,
`rtl/verification/`, `silicon/test_programs/`) is Apache-2.0; hardware
written for this project (`rtl/`) is `Apache-2.0 WITH SHL-2.1` (Solderpad
Hardware License 2.1), stated in each file header; vendored third-party
hardware IP keeps its own Solderpad 0.51, Apache-2.0 or LGPL-2.1 terms; the
numerical tables (`model/data/results/`, `silicon/data/`) are CC BY 4.0.
Third-party material, including the models and dataset text that are not
redistributed, is inventoried with its upstream revisions and terms in
[THIRD_PARTY.md](THIRD_PARTY.md).
