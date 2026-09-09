<!-- Modified by the PKU_2602 project team (School of Integrated Circuits, Peking University), last changed 2025-12-19: adapted for the PKU_2602 SoC integration (216 differing lines against the upstream version; see the file inventory in THIRD_PARTY.md at the repository root). Upstream: cva6 (https://github.com/openhwgroup/cva6), .gitlab-ci/README.md at tag v5.0.0 -->

# PMP

This repository houses a purely combinatorial and parametrizable physical memory protection (PMP) unit.

__Warning__: The PMP unit does only check the exact byte that is addressed. If the processor wants to load a 8 byte value, then every single byte should get checked. Due to the default granularity of PMPs of 4 bytes, this only comes into play for 8byte RISC-V memory accesses. An easy fix is to increase the granularity to 8 bytes. You can do this by setting the lowest bit of conf_addr_i to 1 if the pmp is in NAPOT mode, or to 0 if the PMP is in TOR mode.
