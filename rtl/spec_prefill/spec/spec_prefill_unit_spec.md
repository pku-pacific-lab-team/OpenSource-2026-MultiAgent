# spec_prefill_unit Specification

- Author:      Siyuan He [Peking University]
- Acknowledge: Cursor Agent
- DUT File:    `spec_prefill/src/spec_prefill_unit.sv`
- TB Files:    `spec_prefill/tb/spec_prefill_unit_cpu_access_tb.sv`, `spec_prefill/tb/spec_prefill_unit_encoder_tb.sv`, `spec_prefill/tb/spec_prefill_unit_predictor_tb.sv`, `spec_prefill/tb/spec_prefill_unit_learner_tb.sv`

## Overview
spec_prefill_unit integrates the encoder, predictor and learner, and provides an AXI-like CPU access interface together with on-chip Input/Weight SRAMs. The CPU accesses the SRAMs, Token Buffer, Predictor output buffer and control/status registers through base-address decoding, and drives the three functional modules.

## Parameters
- `ADDR_WIDTH`(64), `DATA_WIDTH`(64)
- `HDC_DIM`(default 2048), `WEIGHT_WIDTH`(6), `TOKEN_ID_WIDTH`(16), `RANDOM_WIDTH`(16), `TOKEN_WINDOW`(4), `BIAS`(default 1024)
- `NUM_INPUT = 192 / WEIGHT_WIDTH`, `NUM_ACCESS = HDC_DIM / NUM_INPUT`

## Base Addresses and Decoding
- `INPUT_SRAM_BASE_ADDRESS = 0x0` READ & WRITE
- `WEIGHT_SRAM_BASE_ADDRESS = 0x1000` READ & WRITE
- `TOKEN_ID_BUF_BASE_ADDRESS = 0x3000` READ & WRITE
- `PREDICTOR_O_BUF_BASE_ADDRESS = 0x3008` READ-ONLY
- `CSR_BASE_ADDRESS = 0x3010` READ & WRITE
- `STATUS_BASE_ADDRESS = 0x3018` READ-ONLY
- `HISTORY_BASE_ADDRESS = {1C0,180,140,100,0C0,080,040,000}` (9-bit, internal use, not visible to the CPU)
- `AGENT_BASE_ADDRESS = {C0,80,40,00}` (8-bit, internal use, not visible to the CPU)
- Decoding ranges (when `req_i`=1):
  - `[0, INPUT_SRAM_BASE_ADDRESS-1]` → Input SRAM, internal address = `addr_i[11:3]`
  - `[INPUT_SRAM_BASE_ADDRESS, WEIGHT_SRAM_BASE_ADDRESS-1]` → Weight SRAM, `addr_offset = addr_i - INPUT_SRAM_BASE_ADDRESS`; internal address `addr_offset[12:5]`, part select `addr_offset[4:3]`
  - The remaining base addresses map to the Token Buffer, Predictor O Buffer, CSR and Status

## CSR/Status
- Control CSR (`ctrl_csr_q`) bit fields (independent power_mode per module):
  - `[1:0]   cmd`               : 00 idle / 01 encoder / 10 predictor / 11 learner
  - `[3:2]   encoder_power_mode`: 00 idle / 01 work / 10 power_test
  - `[5:4]   predictor_power_mode`: 00 idle / 01 work / 10 power_test
  - `[7:6]   learner_power_mode`: 00 idle / 01 work / 10 power_test
  - `[9:8]   agent_id`
  - `[12:10] history_id`
  - `[13]    reward`
  - Enable condition: a module's enable is asserted when its power_mode=POWER_WORK and cmd selects that module
- Status CSR (`status_csr_q`):
  - `[1:0] encoder_status`
  - `[3:2] predictor_status`
  - `[5:4] learner_status`
  - Each FSM writes back FINISHED on completion

## Submodules and Data Paths
- Encoder (`hdc_encoder`): reads `token_id_buffer_q` and generates `encoder_vector_o`; writes the Input SRAM (32-bit words) at `HISTORY_BASE_ADDRESS[history_id] + encoder_cnt`.
- Predictor: reads the Encoder_o_buffer (the HDC vector output by the encoder) and the Weight SRAM (address `AGENT_BASE_ADDRESS[agent_id] + predictor_cnt`, assembled from 3 64-bit accesses into 192 bits); invokes the internal predictor and accumulates the result into `predictor_o_buffer_q[agent_id]`.
- Learner: reads the Input SRAM (history_id) and the Weight SRAM (agent_id); writes back the corresponding 192-bit weight row with `learner_updated_weight_o`.

## FSM Summary
- CPU Access: decodes the address and drives the SRAM chip selects/write enables and addresses; maps the control/status registers.
- Encoder FSM: IDLE → RUN → STORE; on completion clears cmd and sets encoder_status=FINISHED.
- Predictor FSM: PRED_IDLE → PRED_PREDICT → PRED_STORE; on completion clears cmd and sets predictor_status=FINISHED.
- Learner FSM: LEARN_IDLE → LEARN_LOAD → LEARN_UPDATE → LEARN_STORE; updates row by row, and on completion clears cmd and sets learner_status=FINISHED.

## Timing and Address Formulas
- Input SRAM: CPU read/write address = `INPUT_SRAM_BASE_ADDRESS + (word_idx << 3)`; encoder write address = `INPUT_SRAM_BASE_ADDRESS + ((HISTORY_BASE_ADDRESS[history_id] + cnt) << 3)`.
- Weight SRAM: CPU read/write address = `WEIGHT_SRAM_BASE_ADDRESS + (sram_addr << 5) + (part << 3)`, where `sram_addr = AGENT_BASE_ADDRESS[agent_id] + row_idx` and part=0/1/2.
- CSR/Status: single-cycle request; read data is valid in the next cycle.

## Usage
- `CPU Access`: same as a normal memory access.
- `Encoder`: after writing `TOKEN_ID_BUF`, set `cmd=ENCODER`, `encoder_power_mode=WORK` and history_id, then wait for the encoder field in STATUS to become FINISHED.
- `Predictor`: after the encoder and before the next encoder run, set `cmd=PREDICTOR`, `predictor_power_mode=WORK` and agent_id, then wait for the predictor field in STATUS to become FINISHED.
- `Learner`: set `cmd=LEARNER`, `learner_power_mode=WORK`, history_id, agent_id and reward, then wait for the learner field in STATUS to become FINISHED.

## Usage Constraints
- `HDC_DIM` must be divisible by `NUM_INPUT`.
- CPU accesses must be 8-byte aligned; a weight write requires 3 64-bit writes to form 192 bits.
- cmd takes effect only in IDLE; on completion the FSM clears cmd (written back to the CSR).
- A CPU access preempts the CSR read/write, which can prevent a completed FSM from clearing cmd and cause it to run again; the timing of CPU accesses must be handled with care.

## Verification Points
- Correctness of address decoding and SRAM address formulas (including history/agent offsets).
- Completion handshake of the three FSMs and status field write-back.
- Predictor/learner accumulation and update match the reference model (including BIAS and reward direction).
- Registers/buffers are cleared after reset; an illegal cmd stays idle.
