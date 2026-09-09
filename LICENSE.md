# Licenses

The repository combines parts with different licenses. The license of a file
is stated in its header; this page maps the parts and points to the license
texts in [LICENSES/](LICENSES/). Third-party material (vendored hardware IP,
the models and datasets used by the evaluation, and derived test-program
code) is inventoried with its upstream revisions and terms in
[THIRD_PARTY.md](THIRD_PARTY.md).

| Part | Contents | License | Text |
|---|---|---|---|
| `model/` | evaluation software, vector generators, scripts | Apache-2.0 | [LICENSES/Apache-2.0.txt](LICENSES/Apache-2.0.txt) |
| `rtl/`, project sources | hardware written for this project (headers name the copyright holder, School of Integrated Circuits, Peking University) | Apache-2.0 WITH SHL-2.1 (Solderpad Hardware License 2.1) | [LICENSES/Apache-2.0.txt](LICENSES/Apache-2.0.txt), [LICENSES/SHL-2.1.txt](LICENSES/SHL-2.1.txt) |
| `rtl/`, vendored IP | third-party hardware IP, per file | Solderpad 0.51; Apache-2.0, some WITH SHL-2.0 or SHL-2.1; LGPL-2.1-or-later (`soc_axi/apb_uart/`) | [LICENSES/SHL-0.51.txt](LICENSES/SHL-0.51.txt), [LICENSES/SHL-2.0.txt](LICENSES/SHL-2.0.txt), [LICENSES/LGPL-2.1-or-later.txt](LICENSES/LGPL-2.1-or-later.txt) |
| `rtl/verification/`, `rtl/Makefile`, `silicon/test_programs/` | regression runners, bench tools, bare-metal programs (`uart.c`/`uart.h` derived from OpenHW Group code) | Apache-2.0; the SystemVerilog stub and fixture template under `rtl/verification/` are Apache-2.0 WITH SHL-2.1 like the other project HDL | [LICENSES/Apache-2.0.txt](LICENSES/Apache-2.0.txt), [LICENSES/SHL-2.1.txt](LICENSES/SHL-2.1.txt) |
| `model/data/results/`, `silicon/data/` | numerical tables | CC BY 4.0 | [LICENSES/CC-BY-4.0.txt](LICENSES/CC-BY-4.0.txt) |

Documentation (README files and the specifications under `rtl/`) follows the
license of the part it belongs to. The Apache-2.0 terms of the software parts
do not replace the Solderpad or LGPL terms stated in individual hardware
files. Upstream headers and READMEs that say "see LICENSE for details" refer
to the license text of their own project; the corresponding text is provided
under [LICENSES/](LICENSES/).

## Data attribution

When reusing the numerical tables, provide attribution to "MXINT and SF
Sparse Attention project contributors" and link to this repository. The data
license does not cover the third-party model weights and dataset text, which
are not redistributed; see [THIRD_PARTY.md](THIRD_PARTY.md) for their terms.

## License texts

- [Apache-2.0](LICENSES/Apache-2.0.txt)
- [Solderpad Hardware License 0.51](LICENSES/SHL-0.51.txt)
- [Solderpad 2.0 exception](LICENSES/SHL-2.0.txt), used with Apache-2.0
- [Solderpad 2.1 exception](LICENSES/SHL-2.1.txt), used with Apache-2.0
- [LGPL-2.1-or-later](LICENSES/LGPL-2.1-or-later.txt)
- [CC BY 4.0](LICENSES/CC-BY-4.0.txt)

The bundled Apache, Solderpad and LGPL texts are copied from the
[SPDX license-list-data project](https://github.com/spdx/license-list-data);
the CC BY 4.0 text is the legal code published by Creative Commons.
