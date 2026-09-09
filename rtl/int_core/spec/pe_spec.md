# Processing Element (PE) Specification

- Author:      Mingxuan Li <siris-lmx@stu.pku.edu.cn> [Peking University]
- Acknowledge: VSCode Copilot + GPT-5 Agent
- DUT File:    `int_core/src/pe.sv`
- TB File:     `int_core/tb/pe_tb.sv`

## Overview
The PE module implements a multiply-accumulate (MAC) unit with an accumulator. In each valid input cycle, when `in_valid_i` is asserted:
- If `initial_i`=1, the output `result_o` is initialized with the current product;
- If `initial_i`=0, the output `result_o` accumulates the current product;
Both the product and the accumulation are computed as signed numbers.

## Parameters
- `DATA_WIDTH` (default: 4)
  - Bit width of the inputs `activation_i` and `weight_i`.
- `MAX_ACCUM_NUM` (default: 32)
  - Maximum number of consecutive accumulation terms allowed by design (used to determine the accumulator bit width).
- `ACCUM_WIDTH` (default: `$clog2(MAX_ACCUM_NUM) + DATA_WIDTH * 2`)
  - Bit width of the accumulator and the output `result_o`; ensures no overflow in the worst case (`MAX_ACCUM_NUM` accumulations of same-sign maximum-magnitude products).

Note: the product bit width is `2*DATA_WIDTH`, extended by `ceil(log2(MAX_ACCUM_NUM))` bits to cover the accumulation growth.

## Port Definitions
- Clock and reset
  - `clk_i` : Input clock, rising-edge triggered.
  - `rstn_i`: Active-low asynchronous reset; `result_o` is cleared to zero during reset.
- Control and data
  - `in_valid_i` : Input valid. Only when it is 1 does the current cycle take part in computation and registering.
  - `initial_i`  : Initializes the accumulator. When `in_valid_i=1` and `initial_i=1` in the current cycle, `result_o` is overwritten with the current product; otherwise accumulation is performed.
  - `activation_i[DATA_WIDTH-1:0]` : Signed activation value.
  - `weight_i[DATA_WIDTH-1:0]`     : Signed weight value.
- Output
  - `result_o[ACCUM_WIDTH-1:0]` : Signed accumulation result (sequential registered output).

All arithmetic operations are `$signed` signed computations.

## Function and Timing
- Reset: when `rstn_i=0`, `result_o` is asynchronously cleared to zero.
- Normal operation: sampled at every `posedge clk_i`.
  - If `in_valid_i=1 && initial_i=1`: `result_o_next = activation_i * weight_i`.
  - If `in_valid_i=1 && initial_i=0`: `result_o_next = result_o + activation_i * weight_i`.
  - If `in_valid_i=0`: `result_o` holds its value.
- Combinational logic: `partial_sum = $signed(activation_i) * $signed(weight_i)`.

Timing relationship: the inputs are sampled as valid at the rising clock edge, the output `result_o` is updated at the same rising edge, and it becomes externally visible in the next clock cycle.

## Implementation Details
- Uses `always_ff @(posedge clk_i or negedge rstn_i)` to implement the register with asynchronous reset.
- Both multiplication and addition use `$signed` to ensure correct handling of two's-complement negative and positive numbers.
- The bit width selection follows a full-precision (lossless) design: `ACCUM_WIDTH` is given by a parameterized expression that covers the worst-case accumulation depth.
- There is no saturation or rounding logic; on out-of-range values the result is naturally truncated to `ACCUM_WIDTH` bits (determined by synthesis/simulation semantics).

## Usage Constraints and Boundaries
- When setting the parameters, the user should ensure that the number of consecutive accumulation terms at run time does not exceed the order of `MAX_ACCUM_NUM`; otherwise overflow truncation may occur.
- Inputs are in two's-complement format; if the upstream data is unsigned, perform explicit sign extension or normalization.
- `in_valid_i` must be aligned with `activation_i/weight_i`.
- `initial_i` is asserted for only one valid cycle when a new accumulation sequence is to be started.

## Reset and Invalid-Cycle Behavior
- After reset is released and until the first `in_valid_i=1` cycle, `result_o` stays at 0.
- During several consecutive cycles with `in_valid_i=0`, `result_o` holds the last valid value.

## Example Timing
- Cycle k: `in_valid=1, initial=1, A=a0, W=w0` -> `result=a0*w0`.
- Cycle k+1: `in_valid=1, initial=0, A=a1, W=w1` -> `result=(a0*w0)+(a1*w1)`.
- Cycle k+2: `in_valid=0` -> `result` holds its value.

## Reference Model (for the TB)
- Combinational product: `prod = $signed(A) * $signed(W)`, with the bit width aligned to `ACCUM_WIDTH`.
- Update rule: if `init` then `ref=prod`, otherwise `ref=ref+prod`; if `in_valid=0` then hold.

## PE Testbench Usage

Self-checking testbench for `int_core/src/pe.sv`. The test coverage includes reset, initialization, accumulation, sign combinations, bit-width boundaries, `in_valid` gaps, consecutive accumulation depth and random regression, with colored PASS/FAIL printing and summary statistics.

## Expected Output
- Each sub-case prints a `[CASE]` start line; each per-cycle check prints `[PASS]` or `[FAIL]`; at the end, the `[SUMMARY] PASS/FAIL` statistics and `[DONE]` are printed.
