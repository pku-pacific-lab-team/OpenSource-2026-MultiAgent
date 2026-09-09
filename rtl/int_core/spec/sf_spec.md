# Scaling Factor (SF) Compute Specification

- Author:      Mingxuan Li <siris-lmx@stu.pku.edu.cn> [Peking University]
- Acknowledge: VSCode Copilot + Gemini-3-Pro Agent
- DUT File:    `int_core/src/sf.sv`
- TB File:     `int_core/tb/sf_tb.sv`

## Overview
The SF (Scaling Factor) module performs two main functions:
1. **Scaling factor computation**: Computes the sum of two input scaling factors and the XOR of their sign bits, generating a new signed scaling factor (`signed_sf`).
2. **Bucket accumulation**: Based on the upper bits of the computed `signed_sf`, accumulates a shifted value into the corresponding one of four buckets (`bucket`). This is used to collect statistics on the data distribution.

## Parameters
- `DATA_WIDTH` (default: 8)
  - Bit width of the input scaling factors `scaling_factor0_i`, `scaling_factor1_i` and the output `exponent_o`.
- `SF_WIDTH` (default: 6)
  - Bit width of the internally generated signed scaling factor `signed_sf`.
- `ACCUM_WIDTH` (default: 12)
  - Accumulator bit width of the four output buckets `bucket_3bXXX_o`.

## Port Definitions
- **Clock and reset**
  - `clk_i` : Input clock, rising-edge triggered.
  - `rstn_i`: Active-low asynchronous reset; all registers are cleared to zero during reset.

- **Control signals**
  - `sf_valid_i`       : Scaling factor computation valid indication. When 1, `exponent` and `sign_bit` are updated.
  - `spattn_valid_i`   : Bucket accumulation valid indication. When 1, the bucket values are updated according to the current `signed_sf`.
  - `spattn_initial_i` : Bucket initialization indication. When `spattn_valid_i=1` and `spattn_initial_i=1`, the bucket value is reset to the currently computed value (instead of accumulating).

- **Data inputs**
  - `scaling_factor0_i[DATA_WIDTH-1:0]` : First scaling factor input.
  - `scaling_factor1_i[DATA_WIDTH-1:0]` : Second scaling factor input.
  - `sign0_i` : Sign bit of the first scaling factor.
  - `sign1_i` : Sign bit of the second scaling factor.

- **Data outputs**
  - `exponent_o[DATA_WIDTH-1:0]`  : Computed exponent part (i.e. the sum of the two input scaling factors).
  - `bucket_3b000_o[ACCUM_WIDTH-1:0]` : Bucket accumulation value for upper bits `3'b000`.
  - `bucket_3b001_o[ACCUM_WIDTH-1:0]` : Bucket accumulation value for upper bits `3'b001`.
  - `bucket_3b110_o[ACCUM_WIDTH-1:0]` : Bucket accumulation value for upper bits `3'b110`.
  - `bucket_3b111_o[ACCUM_WIDTH-1:0]` : Bucket accumulation value for upper bits `3'b111`.

## Function and Timing

### 1. Scaling Factor Computation
- When `sf_valid_i` is high:
  - `exponent_d = scaling_factor0_i + scaling_factor1_i`
  - `sign_bit_d = sign0_i ^ sign1_i`
- The results are registered in the next clock cycle as `exponent_q` and `sign_bit_q`, and combined into `signed_sf`:
  - `signed_sf = {sign_bit_q, exponent_q[SF_WIDTH-2:0]}`
  - Note: the bit width of `signed_sf` is determined by `SF_WIDTH`; it takes the lower `SF_WIDTH-1` bits of `exponent_q`.

### 2. Bucket Accumulation
- When `spattn_valid_i` is high, the bucket to update is selected according to the upper 3 bits of `signed_sf` (`signed_sf[SF_WIDTH-2:SF_WIDTH-4]`).
- **Bucket selection logic**:
  - `3'b000` -> update `bucket_3b000`
  - `3'b001` -> update `bucket_3b001`
  - `3'b110` -> update `bucket_3b110`
  - `3'b111` -> update `bucket_3b111`
  - In all other cases, the bucket values are held unchanged.
- **Update algorithm**:
  - Shift value: `shift_val = 1 << signed_sf[SF_WIDTH-5:0]`
  - Operation direction: determined by the most significant bit of `signed_sf` (`sign_bit_q`).
    - If `signed_sf[SF_WIDTH-1] == 1` (negative): perform subtraction.
    - If `signed_sf[SF_WIDTH-1] == 0` (positive): perform addition.
  - Initialization vs. accumulation:
    - If `spattn_initial_i == 1`: **all buckets are first cleared to zero**, then only the currently computed value is written into the selected bucket, i.e. `matched_bucket = 0 +/- shift_val`, and the other buckets stay at 0.
    - If `spattn_initial_i == 0`: `matched_bucket = current_bucket_val +/- shift_val`, and the other buckets are held unchanged.

## Implementation Details
- Register updates are implemented with `always_ff`, with asynchronous reset support.
- Combinational logic, including the addition, XOR, shift and multiplexing, is implemented with `always_comb`.
- `signed_sf` is constructed from `sign_bit_q` and `exponent_q` computed in the previous cycle, so the bucket accumulation is actually based on the scaling factor latched in the previous cycle (if `sf_valid_i` and `spattn_valid_i` arrive at the same time, the bucket accumulation uses the old SF value; the design expects `sf_valid_i` to precede `spattn_valid_i`, so timing alignment must be observed).
  - **Note**: From the code, the `bucket` update logic uses `signed_sf`, and `signed_sf` comes from the `_q` registers. This means that when `spattn_valid_i` is asserted, the SF value currently stored in the registers is processed.

## Usage Constraints and Boundaries
- `ACCUM_WIDTH` should be set according to the expected number of accumulations and the magnitude of the shift value to prevent overflow.
- `spattn_valid_i` should be asserted within the timing window after `sf_valid_i` to ensure that the correct SF value is processed.

## Reset and Invalid-Cycle Behavior
- When `rstn_i=0`, all registers (exponent, sign bit and the four buckets) are cleared to zero.
- When `sf_valid_i=0`, `exponent_q` and `sign_bit_q` hold their values.
- When `spattn_valid_i=0`, all bucket registers hold their values.
