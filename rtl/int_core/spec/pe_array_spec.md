# PE Array Specification

- Author:      Mingxuan Li <siris-lmx@stu.pku.edu.cn> [Peking University]
- Acknowledge: VSCode Copilot + GPT-5 Agent
- DUT File:    `int_core/src/pe_array.sv`
- TB File:     `int_core/tb/pe_array_tb.sv`

## Overview
The `pe_array` module builds a two-dimensional `ARRAY_SIZE x ARRAY_SIZE` grid of PEs, each of which is a multiply-accumulate unit (see `pe_spec.md`); the row input is `activation_line_i` and the column input is `weight_line_i`. The array supports multi-cycle accumulation (up to `MAX_ACCUM_NUM` times) and indicates that the result is valid through `out_valid_o` once an accumulation depth has been completed. The module also supports reading the result vector at a given address by row or by column, returning a `result_line_o` through simple multiplexing logic.

Application scenarios: matrix multiply-accumulate, batched vector dot products, local compute arrays for unrolled convolution kernels, etc.

## Parameters
- `DATA_WIDTH` (default: 4): Bit width of activations and weights (same as a single PE).
- `MAX_ACCUM_NUM` (default: 32): Maximum depth of an accumulation sequence (same as a single PE; used to control the done flag).
- `ARRAY_SIZE` (default: 8): Row and column dimension of the array. The array contains `ARRAY_SIZE^2` PEs.
- `ACCUM_WIDTH` (derived: `$clog2(MAX_ACCUM_NUM) + DATA_WIDTH * 2`): Result bit width of each PE.
- `ADDR_WIDTH` (derived: `$clog2(ARRAY_SIZE)`): Bit width needed for the row or column read address.

## Port Definitions
- Clock and reset
  - `clk_i`: Rising-edge sequential clock.
  - `rstn_i`: Active-low asynchronous reset. Clears the accumulation count and the readout register.
- Compute interface
  - `in_valid_i`: Input valid for the current cycle; drives one multiply-accumulate operation in all PEs.
  - `initial_i`: When asserted, starts a new accumulation sequence (the internal results and counters of all PEs are reset/overwritten with the current cycle's product).
  - `activation_line_i[ARRAY_SIZE][DATA_WIDTH]`: Column vector input; each row index i is distributed to all columns of row i of the array.
  - `weight_line_i[ARRAY_SIZE][DATA_WIDTH]`: Row vector input; each column index j is distributed to all rows of column j of the array.
  - `result_matrix_aligned_o[ARRAY_SIZE][ARRAY_SIZE][16]`: Directly outputs the accumulation results of all PEs in the array, each aligned to 16-bit (sign-extended).
  - `output_accum_cnt_o[$clog2(MAX_ACCUM_NUM)]`: Output of the current accumulation depth counter value.

## Data Flow Diagram (ASCII)

```
                        weight_line_i
               w[0]  w[1]  ...  w[ARRAY_SIZE-1]
                 |     |              |
                 v     v              v
        +---------------------------------------+
 a[0]-> | PE00   PE01  ...       PE0N           |
 a[1]-> | PE10   PE11  ...       PE1N           |
  ...   | ...   ...   ...       ...             |
 a[N]-> | PEN0   PEN1  ...       PENN           |
        +---------------------------------------+
                 |     |              |
                 +-----+--------------+
                         result_matrix[i][j]
                                |
                                v
                      Sign Extension to 16-bit
                                |
                                v
                      result_matrix_aligned_o
```

Note: in each cycle, one activation row vector and one weight column vector are broadcast synchronously to all PEs, implementing an outer-product-like operation; over multiple cycles (initial=1 followed by initial=0), the matrix elements are accumulated across cycles (e.g. convolution/block processing). The results are output directly through `result_matrix_aligned_o`.

## Functional Description
1. Multiply-accumulate: all `ARRAY_SIZE^2` PEs compute their products simultaneously and accumulate them in sequence.
2. Accumulation sequence count: `accum_cnt_q` records the accumulation depth of the current sequence; when it reaches `MAX_ACCUM_NUM-1`, `out_valid_o=1` is output.
3. Result output: the accumulation results of all PEs are output in real time through `result_matrix_aligned_o`, each sign-extended to 16-bit.
4. Asynchronous reset: clears the accumulation count and the readout register; does not clear the PE-internal results (each PE clears itself on reset).

## Implementation Details
- Uses a two-level `for (genvar)` to generate the structured array with index `[i][j]`.
- `activation_line_i[i]` is broadcast to all columns of the same row; `weight_line_i[j]` is broadcast to all rows of the same column.
- `accum_cnt_q` is cleared when `initial_i` is asserted; it increments on every subsequent valid accumulation cycle.
- The read logic generates the next state `result_line_d` combinationally; it is updated only in the cycle in which `read_request_i` is asserted; otherwise the previously latched row/column is held.
- `result_line_o` is a registered output, which helps reduce glitches on the read side.

## Timing Behavior
- The PE internals and the array control are sampled at `posedge clk_i`.
- Accumulation counter: cycle with `initial_i` asserted → cleared; afterwards, every `in_valid_i` cycle that is not an initial cycle → counter increments by one.
- Read: in the cycle in which `read_request_i` is high, the data is selected combinationally, latched at the next rising edge and output through `result_line_o`.

## Usage Constraints
- The input broadcast must ensure that `activation_line_i` and `weight_line_i` are stable during `in_valid_i` cycles.
- To start a new accumulation sequence, assert `initial_i` in the first valid cycle.
- `initial_i` should not be asserted repeatedly in the middle of an accumulation (this forcibly resets the count).
- `read_request_i` may run in parallel with computation; the read result is the `result_matrix` state of the PEs in the array at the previous instant (no race with the current cycle's multiply-accumulate, since the PE results are updated at the clock edge).
- To read all matrix data at once, iterate over the addresses and alternate the direction.

## Numerical and Bit-Width Analysis
- Each `result_matrix[i][j]` has the same bit width as a single PE output: `ACCUM_WIDTH`.
- Worst case: all products have the same sign and maximum magnitude and are accumulated `MAX_ACCUM_NUM` times consecutively; the bit width given by the parameter expression guarantees no overflow of the theoretical range.

## Reference Model (for the Testbench)
A two-dimensional reference matrix `ref[i][j]` is maintained inside the TB:
```
for each valid cycle:
  for i,j:
    prod = signed(activation_line_i[i]) * signed(weight_line_i[j])
    if initial_i: ref[i][j] = prod;
    else if in_valid_i: ref[i][j] += prod;
```
Counter behavior: generates `out_valid_ref` consistently with the RTL.
Read behavior: when `read_request_i` is triggered, the selected row or column is copied to `read_line_ref`.

## Integration Suggestions
- Can be used as the local array of a basic matrix multiply-accumulate core, with external control driving the row-vector and column-vector streams.
- Extensions: add a write-back interface or a blocked read interface; add overflow detection; support different accumulation modes (e.g. saturation, clipping).
