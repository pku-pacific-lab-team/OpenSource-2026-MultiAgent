# Predictor Specification

- Author:      Siyuan He [Peking University]
- Acknowledge: Cursor Agent
- DUT File:    `spec_prefill/src/predictor.sv`
- TB Files:    `spec_prefill/tb/predictor_tb.sv`, `spec_prefill/tb/spec_prefill_unit_predictor_tb.sv`

## Overview
The Predictor receives a set of HDC vector slices (`NUM_INPUT` bits) and the corresponding weights (only the 1-bit MSB is used), and accumulates the number of matching bits every cycle. On completion it outputs the accumulated sum minus the bias BIAS and provides a completion handshake.

## Parameters
- `HDC_DIM` (default: 2048): overall dimension; must be divisible by `NUM_INPUT`.
- `NUM_INPUT` (default: 32): number of bits processed per cycle.
- `BIAS` (default: 1024): bias subtracted before the result is output.
- `NUM_ACCU = HDC_DIM / NUM_INPUT`: number of accumulation cycles.

## Port Definitions
- `clk_i`: clock, sampled on the rising edge.
- `rstn_i`: active-low synchronous reset.
- `en_i`: start signal, sampled only in IDLE.
- `hdc_input_i[NUM_INPUT-1:0]`: HDC input slice.
- `weight_input_i[NUM_INPUT-1:0]`: weight slice; each bit is the MSB of the corresponding weight.
- `finish_o`: completion indication, registered.
- `results_o[$clog2(HDC_DIM)-1:0]`: in the FINISH cycle, combinationally outputs the low bits of `{1'b0, adder_output_o} - BIAS`.

## Internal Structure
- `xor_adder`:
  - Computes `add_input[i] = ~(input_a_i[i] ^ input_b_i[i])` bit by bit.
  - A 5-level adder tree produces a 6-bit count, which is added into the accumulator when `en_i` is set.
  - The registered accumulated sum is output as `adder_output_o`.
- `NUM_ACCU` controls the number of accumulations.

## FSM
`state_q` ∈ {IDLE, GEN_PRED_SUM, FINISH}:
- IDLE: `en_i` is sampled to start, the first input is loaded and `xor_adder_en` is set.
- GEN_PRED_SUM: samples the current input and accumulates it every cycle, `cnt_q` increments; in the last cycle sets `finish_d=1` and moves to FINISH in the next cycle.
- FINISH: combinationally outputs the result `{1'b0, adder_output_o} - BIAS`, `finish_o` is 1 in this cycle; then returns to IDLE.

## Timing and Latency
- Inputs are not additionally registered; GEN_PRED_SUM samples `hdc_input_i/weight_input_i` every cycle.
- `finish_o` is a registered signal; `results_o` is combinationally valid in the FINISH cycle.
- Latency from start to completion is approximately `NUM_ACCU` clock cycles, plus 1 FINISH cycle.

## Usage Constraints
- `en_i` is sampled only in IDLE and must be kept low during processing.
- `HDC_DIM` must be divisible by `NUM_INPUT`, otherwise the counter and slicing go out of range.
- The upstream must provide aligned input slices throughout GEN_PRED_SUM.

## Reset and Invalid Phase
- `rstn_i=0`: clears the state, counter, accumulator and output register.
- `results_o` is set to 0 in non-FINISH cycles.

## Verification Points
- Counting and completion handshake: `finish_o` is asserted for one cycle only after `NUM_ACCU` accumulations.
- Bias subtraction: check the truncation behavior of `{1'b0, adder_output_o} - BIAS`.
- Input alignment: input changes in every GEN_PRED_SUM cycle are accumulated.
- Boundary parameters: counting and adder-tree slicing for different `NUM_INPUT`/`HDC_DIM` combinations.***
# predictor Module Specification

## Parameters and Interface
- Parameters: `HDC_DIM` (default 2048), `NUM_INPUT` (default 32), `BIAS` (default 1024).
- Clock/reset: `clk_i`, active-low reset `rstn_i`.
- Enable: `en_i`.
- Inputs:
  - `hdc_input_i[NUM_INPUT-1:0]`
  - `weight_input_i[NUM_INPUT-1:0]` (the MSB of each weight is taken as 1 bit)
- Outputs:
  - `finish_o`: completion indication, registered.
  - `results_o[$clog2(HDC_DIM)-1:0]`: in the FINISH cycle, combinationally gives the low bits of `{1'b0, adder_output_o} - BIAS`.

## Internal Structure
- `xor_adder`: performs a bitwise XNOR (inverted XOR) of `hdc_input_i` and `weight_input_i`, then a 5-level adder tree produces a 6-bit count; when `en_i` is set, the count is fed to the accumulator and the accumulated result is registered as `adder_output_o`.
- `NUM_ACCU = HDC_DIM / NUM_INPUT`, i.e. one accumulation per input block.

## FSM
`state_q` ∈ {IDLE, GEN_PRED_SUM, FINISH}.
- IDLE: enters GEN_PRED_SUM when `en_i` is asserted, loads the first input and enables xor_adder.
- GEN_PRED_SUM: accumulates one set of inputs every cycle, `cnt_q` counts; when it reaches `NUM_ACCU-1`, `finish_d=1` and moves to FINISH in the next cycle.
- FINISH: `results_o = {1'b0, adder_output_o} - BIAS` (combinational), `finish_o` is asserted in this cycle; returns to IDLE in the next cycle.

## Timing Notes
- Inputs are not registered; GEN_PRED_SUM samples the `hdc_input_i/weight_input_i` of the current cycle.
- `finish_o` is a registered signal; `results_o` is combinationally valid in the FINISH cycle.
- Reset clears all counters and enables.

## Constraints and Assumptions
- `NUM_INPUT` must divide `HDC_DIM`.
- `en_i` must be asserted for one cycle in IDLE to start the computation; subsequent inputs must be aligned to the GEN_PRED_SUM cycles.
