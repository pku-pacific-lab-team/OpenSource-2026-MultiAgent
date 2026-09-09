<!-- Modified by the PKU_2602 project team (School of Integrated Circuits, Peking University), last changed 2025-12-19: minor local edits (1 differing lines against the upstream version). Upstream: rv_plic (https://github.com/pulp-platform/rv_plic), README.md at branch master -->

# RISC-V Platform-Level Interrupt Controller

RV_PLIC module is to manage multiple interrupt events generated from the
peripherals. It implements [Platform-Level Interrupt Controller in RISC-V
Privileges specification Section
7](https://people.eecs.berkeley.edu/~krste/papers/riscv-privileged-v1.9.pdf#page=73).

## `reg_rv_plic.py`

The tool is to create register hjson file given values of number of sources,
number of targets, and max value of priority. By default `target` is **1** and
`priority` is **7** (8 level of priorities supported)

To change the value and to re-create hjson,

    $ reg_rv_plic.py -s 64 -t 2 -p 15 rv_plic_reg.tpl.hjson > rv_plic_reg.hjson
