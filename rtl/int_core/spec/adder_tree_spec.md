# Adder Tree Specification

- Author:      Mingxuan Li <siris-lmx@stu.pku.edu.cn> [Peking University]
- Acknowledge: VSCode Copilot + Gemini-3-Pro Agent
- DUT File:    `int_core/src/adder_tree.sv`
- TB File:     `int_core/tb/adder_tree_tb.sv`

## Overview
The `adder_tree` module implements a parameterized signed adder tree that computes the sum of all inputs through a purely combinational multi-stage addition structure.

## Parameters
- `INPUTS_NUM` (default: 32)
  - Number of input data. Does not need to be a power of 2.
- `IDATA_WIDTH` (default: 16)
  - Bit width of each input data.

### Derived Parameters
- `STAGES_NUM` = `$clog2(INPUTS_NUM)`
  - Number of levels of the adder tree.
- `INPUTS_NUM_INT` = `2 ** STAGES_NUM`
  - Number of inputs rounded up to the nearest power of 2 for internal processing.
- `ODATA_WIDTH` = `IDATA_WIDTH + STAGES_NUM`
  - Bit width of the output data; ensures the accumulated result does not overflow.

## Port Definitions
- **Data input**
  - `data_i [INPUTS_NUM-1:0][IDATA_WIDTH-1:0]` : Input data array. This is a packed multi-dimensional array.

- **Data output**
  - `data_o [ODATA_WIDTH-1:0]` : Signed sum of all input data.

## Functional Description
The module builds a multi-level adder tree structure through `generate` statements:

1.  **Stage 0 (Input Mapping)**:
    - Maps the input port `data_i` to `stage_gen[0].node`.
    - If `INPUTS_NUM` is not a power of 2, the extra input lanes (index >= `INPUTS_NUM`) are automatically padded with 0 and do not affect the final result.
    - Each valid input is interpreted as a signed number.

2.  **Subsequent Stages (Addition)**:
    - Each level (`stage`) adds the outputs of the previous level in pairs.
    - Each operand is first explicitly extended by one sign bit, and then the two adjacent nodes are added.
    - The bit width of each level is 1 bit wider than that of the previous level to accommodate the carry and prevent overflow.

3.  **Output**:
    - The last level (`STAGES_NUM`) has only one result, which is the final sum `data_o`.

## Implementation Details
- Uses `genvar` and `generate` blocks for structural modeling.
- All addition operations explicitly use `$signed()` to specify signed arithmetic.
- Each level has its own signed `node` array, and each node is driven by one continuous assignment.

## Usage Constraints and Boundaries
- The input data is treated as signed numbers (two's-complement format).
- The output bit width `ODATA_WIDTH` is computed automatically to guarantee no overflow.
- This is a purely combinational module; the timing path length depends on `STAGES_NUM`. In high-speed designs, pipeline registers may need to be inserted.
