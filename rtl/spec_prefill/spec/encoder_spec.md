# HDC Encoder Specification

- Author:      Siyuan He [Peking University]
- Acknowledge: Cursor Agent
- DUT File:    `spec_prefill/src/encoder.sv`
- TB File:     `spec_prefill/tb/encoder_tb.sv`

## Overview
The HDC Encoder generates a high-dimensional random hypervector bound to a token ID, and supports XOR aggregation of the results of multiple tokens. The design has three levels:
- `lfsr_16bit`: a 16-bit LFSR that produces a pseudo-random sequence.
- `hdc_vector_generator`: drives the LFSR with the token ID as the seed, serially concatenates the outputs into a single `HDC_DIM`-bit hypervector, and provides a completion handshake.
- `hdc_encoder`: invokes `hdc_vector_generator` for each of the `N_TOKEN` tokens one by one, shifts each result by the token index and accumulates it by XOR, and provides an overall completion handshake.

## Parameters
- `HDC_DIM` (default: 2048)
  - Bit width of a single hypervector. Must be an integer multiple of `RANDOM_WIDTH`.
- `TOKEN_ID_WIDTH` (default: 16)
  - Bit width of the token ID, also used as the LFSR seed width.
- `RANDOM_WIDTH` (default: 16)
  - Bit width of the LFSR output per cycle; equal to `TOKEN_ID_WIDTH` by default.
- `N_TOKEN` (default: 4)
  - Number of tokens contained in one top-level encoding.
- `SEED_WIDTH` (default: 16, `lfsr_16bit` only)
  - LFSR seed width, normally aligned with `TOKEN_ID_WIDTH`.

## Port Definitions
### `lfsr_16bit`
- `clk_i`: clock, sampled on the rising edge.
- `rstn_i`: active-low synchronous reset. The register is loaded with `seed_i` during reset.
- `en_i`: shift enable; when 1, shifts according to the feedback polynomial, otherwise holds.
- `seed_i[SEED_WIDTH-1:0]`: seed input.
- `random_vector_o[RANDOM_WIDTH-1:0]`: current LFSR state.

### `hdc_vector_generator`
- `clk_i`: clock, sampled on the rising edge.
- `rstn_i`: active-low asynchronous reset.
- `en_i`: starts generation; accepted only in IDLE.
- `token_id_i[TOKEN_ID_WIDTH-1:0]`: seed of the current token.
- `finish_o`: high indicates that one hypervector frame has been generated.
- `hdc_vector_o[HDC_DIM-1:0]`: generated hypervector; valid only when `finish_o=1`, outputs 0 at all other times.

### `hdc_encoder`
- `clk_i`: clock, sampled on the rising edge.
- `rstn_i`: active-low asynchronous reset.
- `en_i`: top-level start; accepted only in IDLE.
- `token_id_i[N_TOKEN-1:0][TOKEN_ID_WIDTH-1:0]`: list of token IDs to encode.
- `finish_o`: high indicates that all tokens have been processed.
- `vector_o[HDC_DIM-1:0]`: aggregated hypervector; valid only when `finish_o=1`, outputs 0 at all other times.

## Function and Timing
### `lfsr_16bit`
- Feedback polynomial: `new_bit = !(q15 ^ q12 ^ q5 ^ q1)`; shift rule `{q[14:0], new_bit}`.
- Reset: `seed_i` is loaded synchronously when `rstn_i=0`.
- Operation: shifts every cycle when `en_i=1`; holds state when `en_i=0`.

### `hdc_vector_generator`
- Parameters: `NUM_WORDS = HDC_DIM / RANDOM_WIDTH`; counter width `CNT_WIDTH=$clog2(NUM_WORDS)`.
- FSM:
  - `IDLE`: waits for `en_i=1`, clears the counter and output register.
  - `SEED_LFSR`: resets the LFSR to the current `token_id_i` (`lfsr_rstn_i=0` for one cycle).
  - `GEN_VEC`: enables the LFSR every cycle, samples `RANDOM_WIDTH` bits at a time into `vec_d[cnt*RANDOM_WIDTH +: RANDOM_WIDTH]`; after counting to `NUM_WORDS-1`, asserts `finish_d` and returns to `IDLE`.
- Reset: asynchronously clears the state, counter, vector and finish flag.
- Output: `finish_o` is 1 when generation is complete; `hdc_vector_o` outputs the generated `vec_q` only when `finish_o` is 1, otherwise 0.

### `hdc_encoder`
- Counter: `cnt_q` records the index of the token being processed, width `CNT_WIDTH=$clog2(N_TOKEN)`.
- FSM:
  - `IDLE`: waits for the top-level `en_i=1`, clears the counter and the partial accumulated vector.
  - `UPDATE_TOKEN_ID`: prepares the current token and asserts `hdc_en` to trigger vector generation.
  - `GEN_HDC_VECTOR`: waits for the submodule's `hdc_finish_o`. On completion, shifts `partial_hdc_vector_q` right by `cnt_q` bits, XORs it with `hdc_vector_o` to accumulate, and increments the counter; if the last token has been reached, asserts `finish_d` and returns to `IDLE`, otherwise continues with the next token.
- Output: when `finish_o=1`, `vector_o=partial_hdc_vector_q`, otherwise outputs 0.
- Reset: asynchronously clears the counter, state, partial vector and finish flag.
- Note: the partial vector is shifted right by the token index (`partial_hdc_vector_q >> cnt_q`) before accumulation, implementing a simple shift-based token position encoding.

## Usage Constraints and Boundaries
- `HDC_DIM` must be divisible by `RANDOM_WIDTH`, otherwise the bit slicing goes out of range.
- `token_id_i` must be stable when `en_i` is asserted, and each token ID must then be held until the corresponding token has been processed.
- `en_i` is sampled only in IDLE; keep it low during processing to avoid re-entry.
- The output is 0 outside the completion phase; if the system needs to retain the latest result, it must sample it while `finish_o` is asserted.

## Reset and Invalid-Cycle Behavior
- When the top-level `rstn_i=0`, `hdc_vector_generator` and `hdc_encoder` clear their internal state asynchronously. `lfsr_16bit` is not connected to `rstn_i`: its synchronous reset input is driven by the generator's `SEED_LFSR` state, so it holds its value during a top-level reset and is seeded with `token_id_i` at the start of every generation.
- `hdc_vector_generator`: returns to `IDLE` automatically after completion; stays idle unless `en_i` is asserted again.
- `hdc_encoder`: `finish_o=0` before completion; when idle, the accumulated vector retains the last result but the output is gated to 0.

## Timing and Latency Estimate
- Generation latency for a single token: 1 cycle `SEED_LFSR` + `NUM_WORDS` cycles of filling. Counting the clock edge that samples `en_i` as edge 0, `finish_o` rises at edge `NUM_WORDS+1`; in cycle terms, if the cycle in which `en_i` is sampled is cycle 0, `finish_o` is high from cycle `NUM_WORDS+2`.
- Overall latency is approximately `N_TOKEN` times the above, plus the top-level state transition cycles.
