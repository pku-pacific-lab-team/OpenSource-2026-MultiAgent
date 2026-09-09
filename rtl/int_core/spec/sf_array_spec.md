# SF Array Specification

- Author:      Mingxuan Li <siris-lmx@stu.pku.edu.cn> [Peking University]
- Acknowledge: VSCode Copilot + Gemini-3-Pro Agent
- DUT File:    `int_core/src/sf_array.sv`
- TB File:     `int_core/tb/sf_array_tb.sv`

## Overview
The `sf_array` module is an array of `ARRAY_SIZE` x `ARRAY_SIZE` `sf` (Scaling Factor) units. It computes scaling factors in parallel, maintains the bucket statistics for sparse attention, and finally outputs the aggregated result of all buckets through a reduction tree (Sum Reduce). In addition, the module provides a read interface for the computed exponent matrix.

## Parameters
- `DATA_WIDTH` (default: 8)
  - Bit width of the input scaling factors and the output exponents.
- `SF_WIDTH` (default: 6)
  - Bit width of the signed scaling factor used inside the `sf` units.
- `BUCKET_WIDTH` (default: 12)
  - Bit width of the bucket accumulator inside a single `sf` unit.
- `ARRAY_SIZE` (default: 8)
  - Dimension of the array (number of rows/columns).
- `SPATTN_CNT_MAX` (default: 128)
  - Number of cycles/steps of the sparse attention computation. When the count reaches this value, the reduction output is triggered.

### Derived Parameters
- `ACCUM_WIDTH` = `BUCKET_WIDTH + 2 * $clog2(ARRAY_SIZE)`
  - Bit width of the final output sum, sufficient to hold the accumulated value of the whole array.
- `ADDR_WIDTH` = `$clog2(ARRAY_SIZE)`
  - Address bit width of the read interface.
- `SPATTN_CNT_WIDTH` = `$clog2(SPATTN_CNT_MAX)`
  - Bit width of the internal counter.

## Port Definitions
- **Clock and reset**
  - `clk_i`, `rstn_i`

- **Scaling factor compute interface**
  - `sf_valid_i`: Indicates that the input scaling factors are valid.
  - `sf_line0_i [ARRAY_SIZE-1:0][DATA_WIDTH-1:0]`: Row-direction scaling factor input.
  - `sf_line1_i [ARRAY_SIZE-1:0][DATA_WIDTH-1:0]`: Column-direction scaling factor input.
  - `sign_line0_i [ARRAY_SIZE-1:0]`: Row-direction sign bits.
  - `sign_line1_i [ARRAY_SIZE-1:0]`: Column-direction sign bits.

- **Read interface**
  - `exponent_matrix_o [ARRAY_SIZE-1:0][ARRAY_SIZE-1:0][DATA_WIDTH-1:0]`: Directly outputs the exponent matrix computed by all units.

- **Sparse attention/bucket interface**
  - `spattn_valid_i`: Sparse attention computation valid (accumulate/update the buckets).
  - `spattn_initial_i`: Initialization indication (overwrite the bucket values instead of accumulating).
  - `sum_bucket_aligned_o [4-1:0][32-1:0]`: Whole-array aggregated output of the four bucket types (000, 001, 110, 111), sign-extended to 32-bit.
  - `sum_valid_o`: Aggregated result valid indication.

## Functional Description

### 1. SF Array Computation
- Instantiates `ARRAY_SIZE` x `ARRAY_SIZE` `sf` units.
- Unit `(i, j)` receives `sf_line0_i[i]` and `sf_line1_i[j]` as inputs.
- When `sf_valid_i` is asserted, all units compute the exponent and sign in parallel.
- When `spattn_valid_i` is asserted, all units update their local 4 buckets according to their internal state.

### 2. Exponent Matrix Read
- An internal `exponent_matrix` stores the exponents computed by all units.
- The whole matrix is output directly through `exponent_matrix_o` for external modules (such as `int_core`) to read or use.

### 3. Sparse Attention Control (SpAttn Control)
- The internal counter `spattn_cnt` records the number of times `spattn_valid_i` has been asserted.
- When `spattn_initial_i` is high, the counter is set to 1.
- When the counter reaches `SPATTN_CNT_MAX`, the `bucket_valid` signal is generated, which triggers the subsequent reduction operation.

### 4. Reduction Output (Sum Reduce)
- Instantiates 4 `sum_reduce` modules, one for each of the four bucket types (`3b000`, `3b001`, `3b110`, `3b111`).
- When `bucket_valid` is asserted, the reduction process starts.
- Finally, `sum_valid_o` is asserted when `bucket_valid` is valid and all reduction modules have finished, and the whole-array bucket sums are output to `sum_bucket_aligned_o` (indexed 0-3 in order).
