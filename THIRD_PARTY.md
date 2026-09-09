# Third-party material and provenance

This is the inventory of third-party material in the repository: the
open-source hardware IP vendored under `rtl/`, the models and datasets used
by the evaluation software under `model/`, and the third-party code in the
silicon test programs. The licenses of the repository's own parts are mapped
in [LICENSE.md](LICENSE.md); the license texts are in [LICENSES/](LICENSES/).
Every file carries its own license notice, which is authoritative.

## Hardware IP vendored under `rtl/`

Sources written for this project are licensed under `Apache-2.0 WITH SHL-2.1`
(copyright School of Integrated Circuits, Peking University). Third-party
files keep their original headers; every file that differs from its upstream
release carries a modification notice with the date of the last local change,
a one-line description and the upstream file it derives from, as required by
section 4(b) of the Solderpad 0.51 and Apache-2.0 licenses and by section
2(b) of the LGPL.

The inventory was produced by hashing every source, header, script and
documentation file (selected by extension) of the vendored directories
(`cpu_cva6/`, `floo_noc/`, `idma/`, `soc_axi/`, `misc_common/`, `include/`)
and looking the hashes up in the complete git histories of the upstream
repositories; the 11 build, wave and ignore files without such an extension
are listed as `unscanned`. A file is *identical* when its content occurs in some upstream
revision; otherwise it was diffed against the closest upstream release. The
file-by-file result is [rtl/provenance.csv](rtl/provenance.csv) (columns:
file, category, upstream repository, path and revision, differing lines,
notice). The revision is a tag range when the content occurs in tagged
releases, and otherwise the upstream commit that introduced the content and
the commit that replaced it, so that every entry can be checked with
`git show <commit>:<path>`. The notices of files with more than ten differing
lines describe the change generically and state the number of differing
lines; the 15 third-party files whose origin revision could not be identified
carry the same generic notice.

| Directory | Upstream repository | License | Matching revision | Files (identical / adapted) |
|---|---|---|---|---|
| `cpu_cva6/` | [openhwgroup/cva6](https://github.com/openhwgroup/cva6) | Solderpad 0.51 (Thales files: Apache-2.0 WITH SHL-2.0) | v5.0.0 | 101 (78 / 23) |
| `cpu_cva6/fpu/` | [openhwgroup/cvfpu](https://github.com/openhwgroup/cvfpu) (FPnew) | Solderpad 0.51 | v0.7.0 | 2 (0 / 2); the other FPnew files match the copy vendored in cva6 |
| `cpu_cva6/fpu/fpu_div_sqrt_mvp/` | [pulp-platform/fpu_div_sqrt_mvp](https://github.com/pulp-platform/fpu_div_sqrt_mvp) | Solderpad 0.51 | v1.0.1 | 5 (0 / 5) |
| `floo_noc/` | [pulp-platform/FlooNoC](https://github.com/pulp-platform/FlooNoC) | Solderpad 0.51 (hardware) | v0.6.0 | 52 (34 / 18) |
| `idma/` | [pulp-platform/iDMA](https://github.com/pulp-platform/iDMA) | Solderpad 0.51 (reggen output Apache-2.0) | v0.6.5 | 43 (26 / 17) |
| `soc_axi/axi_bus/`, `include/axi/`, most of `soc_axi/bus_converter/` | [pulp-platform/axi](https://github.com/pulp-platform/axi) | Solderpad 0.51 | v0.39.3 (a few files from an earlier release) | 58 (36 / 22) |
| `soc_axi/axi_bus/axi_slice/` | [pulp-platform/axi_slice](https://github.com/pulp-platform/axi_slice) | Solderpad 0.51 | v1.1.4 | 9 (9 / 0) |
| `soc_axi/axi_bus/axi_riscv_atomics/` | [pulp-platform/axi_riscv_atomics](https://github.com/pulp-platform/axi_riscv_atomics) | Solderpad 0.51 | v0.8.2 | 9 (9 / 0) |
| `soc_axi/axi_llc/` | [pulp-platform/axi_llc](https://github.com/pulp-platform/axi_llc) | Solderpad 0.51 (reggen output `axi_llc_reg.sv`: Apache-2.0) | v0.2.2 | 25 (11 / 14) |
| `soc_axi/serial_link/` | [pulp-platform/serial_link](https://github.com/pulp-platform/serial_link) | Solderpad 0.51 (`regs/slink_reg.rdl`: Apache-2.0) | v2.0.0 | 15 (8 / 7) |
| `soc_axi/riscv-dbg/` | [pulp-platform/riscv-dbg](https://github.com/pulp-platform/riscv-dbg) | Solderpad 0.51 | v0.4.1 | 11 (10 / 1) |
| `soc_axi/apb_uart/` | [pulp-platform/apb_uart](https://github.com/pulp-platform/apb_uart) | LGPL-2.1-or-later (16750 UART by Sebastian Witt, SystemVerilog conversion by Jonathan Kimmitt) | master | 13 (13 / 0) |
| `soc_axi/apb_timer/` | [pulp-platform/apb_timer](https://github.com/pulp-platform/apb_timer) | Solderpad 0.51 | v0.1.0 | 3 (3 / 0) |
| `soc_axi/rv_plic/` | [pulp-platform/rv_plic](https://github.com/pulp-platform/rv_plic) (lowRISC OpenTitan derived) | Apache-2.0 | master | 5 (3 / 2) |
| `soc_axi/reg_bus/`, register adapters | [pulp-platform/register_interface](https://github.com/pulp-platform/register_interface) (lowRISC primitives vendored inside) | Solderpad 0.51 / Apache-2.0 | v0.4.1 | 6 (2 / 4) |
| `soc_axi/bus_converter/axi2apb*.sv` | [pulp-platform/axi2apb](https://github.com/pulp-platform/axi2apb) | Solderpad 0.51 | v0.1.0 | 3 (2 / 1) |
| `include/apb/` | [pulp-platform/apb](https://github.com/pulp-platform/apb) | Solderpad 0.51 | v0.2.1 | 2 (1 / 1) |
| `include/axi_stream/` | [pulp-platform/axi_stream](https://github.com/pulp-platform/axi_stream) | Solderpad 0.51 | v0.1.0 | 2 (2 / 0) |
| `misc_common/` | [pulp-platform/common_cells](https://github.com/pulp-platform/common_cells) | Solderpad 0.51 (`read.sv`: Apache-2.0 WITH SHL-2.1) | v1.32.0 (`lzc.sv`: v1.24.0) | 64 (46 / 18) |
| `misc_common/tc_sram*.sv`, `tech_specific/tc_clk.v` | [pulp-platform/tech_cells_generic](https://github.com/pulp-platform/tech_cells_generic) | Solderpad 0.51 | v0.2.10 | 3 (1 / 2) |
| `soc_axi/bootrom.sv`, `soc_axi/bus_converter/reg_to_*.sv` | [pulp-platform/cheshire](https://github.com/pulp-platform/cheshire) | Solderpad 0.51 (`reg_to_tlul.sv`: Apache-2.0 WITH SHL-2.1) | untagged commit of 2023-12-13 (intervals in the CSV) | 36 (33 / 3) |

*Adapted* files differ from upstream by the rewritten include paths only
(`common_cells/` became `misc_common/`, the project's copy of common_cells;
49 files), by small edits (41), or by medium (26) or large (24) local
modifications. Besides these 467 files, 15 third-party files have no
identified origin revision, 27 project files live in the vendored
directories (category `project` in the CSV) and 11 files were not hashed
(`unscanned`).

### Generated files

- FlooGen (part of FlooNoC): `floo_agent_noc.sv`, `floo_agent_noc_pkg.sv`,
  maintained as a snapshot; the topology inputs are not released and the
  endpoint of the die's third-party accelerator was renamed `aux_slot_slave`.
- PeakRDL: `soc_axi/serial_link/regs/slink_reg*.sv` from the included
  `slink_reg.rdl`.
- lowRISC reggen: `soc_axi/axi_llc/axi_llc_reg.sv`,
  `idma/frontend/idma_reg64_1d_reg_top.sv`.
- Machine-code arrays: `soc_axi/bootrom.sv` (boot code source not released)
  and `soc_axi/riscv-dbg/debug_rom.sv` (regenerated for the die's debug
  configuration).

### LGPL-2.1 files

The twelve SystemVerilog files of `soc_axi/apb_uart/` are licensed under the
GNU Lesser General Public License 2.1 or later, as stated in their headers.
They are distributed in source form with the license text
`LICENSES/LGPL-2.1-or-later.txt`; none of them was modified locally, and no
object form of the UART is distributed with the repository.

### Technology interfaces

`tech_specific/` holds behavioural, technology-independent replacements of
the foundry cells of the taped-out die (SRAM and register-file wrappers,
clock cells, pads, a placeholder clock generator). No foundry cell name,
timing library, LEF/GDS data or SRAM-compiler output is part of the release.

## Models and datasets used by `model/`

`model/` does not redistribute model weights, tokenizer files or dataset
text; obtaining and using them is subject to the upstream terms below. The
benchmark manifest records the exact repository, or public mirror, used for
each run; a mirror does not waive the original terms.

| Evaluation entry | Upstream model or family | Terms to review |
|---|---|---|
| Qwen3-1.7B / 4B / 8B | [Qwen3](https://huggingface.co/Qwen) | License shown on each model card |
| Llama-3.2-1B / 3B mirrors | [Llama 3.2](https://huggingface.co/meta-llama) | Llama 3.2 Community License and acceptable-use policy |
| SmolLM2-1.7B | [HuggingFaceTB/SmolLM2-1.7B](https://huggingface.co/HuggingFaceTB/SmolLM2-1.7B) | License shown on the model card |
| Llama-2-7B | [Llama 2](https://huggingface.co/meta-llama/Llama-2-7b-hf) | Llama 2 Community License and acceptable-use policy |
| Mistral-7B-v0.3 | [mistralai/Mistral-7B-v0.3](https://huggingface.co/mistralai/Mistral-7B-v0.3) | License shown on the model card |
| Pythia-6.9B | [EleutherAI/pythia-6.9b](https://huggingface.co/EleutherAI/pythia-6.9b) | License shown on the model card |
| Gemma3-1B | [google/gemma-3-1b-pt](https://huggingface.co/google/gemma-3-1b-pt) | Gemma Terms of Use; access requires accepting the terms |
| Phi-2 | [microsoft/phi-2](https://huggingface.co/microsoft/phi-2) | MIT license shown on the model card |

Datasets: [WikiText](https://huggingface.co/datasets/Salesforce/wikitext)
(the included perplexity measurements), [PG-19](https://huggingface.co/datasets/deepmind/pg19)
(optional long-document source, text not included) and
[LongBench](https://github.com/THUDM/LongBench) (retrieval runner, JSONL data
not included).

## Silicon test programs

`silicon/test_programs/src/uart.c` and `uart.h` derive from the bare-metal
UART driver of the OpenHW Group CVA6 project (Apache-2.0); the modifications
are stated in their headers. Everything else under `silicon/test_programs/`
was written for this project.
