# Sum Reduce Specification

- Author:      Mingxuan Li <siris-lmx@stu.pku.edu.cn> [Peking University]
- Acknowledge: VSCode Copilot + Gemini-3-Pro Agent
- DUT File:    `int_core/src/sum_reduce.sv`
- TB File:     `int_core/tb/sum_reduce_tb.sv`

## Overview
The `sum_reduce` module performs a full-sum reduction over a two-dimensional data array (`ARRAY_SIZE` x `ARRAY_SIZE`), computing the sum of all elements. The module uses a multi-stage pipelined structure and completes the summation step by step with `adder_tree` submodules to optimize timing performance.

## Parameters
- `IN_WIDTH` (default: 12)
  - Bit width of each element in the input matrix.
- `ARRAY_SIZE` (default: 8)
  - Dimension of the input matrix (number of rows and columns).

### Derived Parameters
- `HIDDEN_WIDTH` = `IN_WIDTH + $clog2(ARRAY_SIZE)`
  - Bit width of the intermediate data after the first reduction stage.
- `OUT_WIDTH` = `HIDDEN_WIDTH + $clog2(ARRAY_SIZE)`
  - Bit width of the final output sum; ensures no overflow.

## Port Definitions
- **Clock and reset**
  - `clk_i` : Input clock.
  - `rstn_i`: Active-low asynchronous reset.

- **Control signals**
  - `reduce_valid_i` : Input valid indication. When high, starts one reduction computation.
  - `sum_valid_o`    : Output valid indication. Asserted when the computation is complete.

- **Data input**
  - `array_i [ARRAY_SIZE-1:0][ARRAY_SIZE-1:0][IN_WIDTH-1:0]` : Input two-dimensional data array.

- **Data output**
  - `sum_o [OUT_WIDTH-1:0]` : Computed sum.

## Functional Description
The module completes the computation through a three-stage pipeline controlled by an FSM. To ensure that each computation is triggered only once, the module internally implements rising-edge detection on `reduce_valid_i` (`posedge_reduce_valid`).

1.  **Stage 0 (Input Registering)**:
    - When a rising edge of `reduce_valid_i` (`posedge_reduce_valid`) is detected:
      - The input `array_i` is latched into the internal register `stage0_psum`.
      - The FSM transitions from `IDLE` or `FINISH` to `STAGE1` and starts a new round of computation.

2.  **Stage 1 (Row Reduction)**:
    - Instantiates `ARRAY_SIZE` `adder_tree` modules.
    - Each `adder_tree` sums one row (`ARRAY_SIZE` elements).
    - The results are stored in `stage1_psum`.

3.  **Stage 2 (Column Reduction)**:
    - Instantiates 1 `adder_tree`.
    - Sums all the row sums produced by Stage 1 again to obtain the final result.
    - The result is stored in `stage2_psum`.

4.  **Finish**:
    - When the FSM reaches the `FINISH` state and no new computation request is detected (`posedge_reduce_valid` is low), `sum_valid_o` is asserted and the output `sum_o` is valid.
    - If a new rising edge of `reduce_valid_i` is detected in the `FINISH` state, `sum_valid_o` is deasserted immediately, marking the previous result as invalid, and the module prepares to start a new round of computation.

## Timing Notes
- The computation has a fixed latency.
- From the assertion of `reduce_valid_i` to the assertion of `sum_valid_o`, several clock cycles are required (depending on the number of pipeline stages; the current design uses 3-stage pipeline logic).
- **Note**: When computations are triggered back to back, `sum_valid_o` is deasserted immediately when the new rising edge of `reduce_valid_i` arrives (before the FSM transition), ensuring that downstream modules can correctly identify the valid window of the result.

## Implementation Details
- The FSM states are defined with an `enum`: `IDLE`, `STAGE1`, `STAGE2`, `FINISH`.
- The datapath consists of registers (`_q`) and combinational logic (`_d`).
