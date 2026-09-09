# Learner Specification

- Author:      Siyuan He [Peking University]
- Acknowledge: Cursor Agent
- DUT File:    `spec_prefill/src/learner.sv`
- Used In:     `spec_prefill/src/spec_prefill_unit.sv`

## Overview
The Learner is a combinational module. For each input bit it compares the HDC bit with the MSB of the weight, generates +1/-1 feedback according to the reward, updates the weight, and outputs the updated weight vector.

## Parameters
- `NUM_INPUT` (default: 32): number of bits processed in parallel.
- `WEIGHT_WIDTH` (default: 6): bit width of a single weight.

## Port Definitions
- `en_i`: enable, active high; the output is all 0 when it is 0.
- `reward_i`: reward bit, 1 indicates positive feedback, 0 indicates negative feedback.
- `hdc_input_i[NUM_INPUT-1:0]`: HDC input.
- `weight_input_i[NUM_INPUT*WEIGHT_WIDTH-1:0]`: current weights.
- `updated_weight[NUM_INPUT*WEIGHT_WIDTH-1:0]`: updated weights.

## Function and Rules
- Define `reward = reward_i ? +1 : -1` and `rewardn = -reward`.
- For each position k:
  - Take `weight_sign = weight_input_i[WEIGHT_WIDTH*k + WEIGHT_WIDTH - 1]`.
  - If `hdc_input_i[k] == weight_sign`, feedback = `reward`; otherwise feedback = `rewardn`.
  - `weight_out = weight_in + feedback` (signed addition, no saturation).
- Output: when `en_i=1`, outputs the concatenation of `weight_out`; when `en_i=0`, outputs 0.

## Timing and Reset
- Purely combinational logic, no internal sequential elements, no reset.
- The upstream/downstream must use/sample the output within one cycle.

## Usage Constraints
- `WEIGHT_WIDTH` must be wide enough to hold the accumulated result; there is no overflow protection, out-of-range values are truncated to the bit width.
- `en_i` should be asserted only when an update is required.

## Verification Points
- Feedback direction for positive/negative reward with different bit combinations.
- The output is all 0 when `en_i=0`.
- Overflow truncation behavior (large feedback accumulation).***
