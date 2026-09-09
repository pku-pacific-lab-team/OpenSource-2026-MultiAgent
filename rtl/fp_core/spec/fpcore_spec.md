# FP Core Current RTL Interface and Behavior

This specification describes the parameters, interface, registers and data formats of `fp_core/src/fp_core.sv`.

## Parameters and Interface

| Item | Default / Behavior |
|---|---|
| Module name | `fp_core` |
| PARALLEL_WIDTH | 2; number of four-way input groups processed per cycle; must be a power of 2 |
| AXI_ADDR_WIDTH / AXI_DATA_WIDTH | 12 / 64 |
| INPUT_REG_STAGES / OUTPUT_REG_STAGES | 2 / 2 |
| Request ports | req_i, we_i, addr_i, wdata_i |
| Return ports | rdata_o, rvalid_o |
| Clock / reset | clk_i / rstn_i (active-low asynchronous reset) |

This is a whole-word read/write interface with no byte-enable port. Request pulses pass through the input pipeline; both read and write requests produce rvalid_o. Take the return data on rvalid_o. Internally the address is addr_i[11:0], accessed with 8-byte alignment.

## Addresses and CSRs

| Address | Size | Purpose |
|---|---:|---|
| 0x000–0x7FF | 2048 B | 256 64-bit mantissa input words, RW |
| 0x800–0xBFF | 1024 B | 128 64-bit scale-factor input words, RW |
| 0xC00–0xC7F | 128 B | 256 4-bit mantissa outputs, RO |
| 0xC80–0xC87 | 8 B | 8 8-bit scale-factor outputs, RO |
| 0xC88–0xCC7 | 64 B | 8 64-bit calc input words, RW |
| 0xCC8–0xCCF | 8 B | calc_result, RO |
| 0xCD0–0xCD7 | 8 B | Control / status word |
| 0xCD8–0xCDF | 8 B | Reserved register, readable and writable |
| 0xCE0–0xFFF | — | Not implemented; reads 0xCA11AB1EBADCAB1E, writes are ignored |

0xCD0 bit definitions: bit0 is quant mode (0 asymmetric, 1 symmetric); bit1 is start; bit2 is done; bit3 is reserved, writes are ignored and it reads as zero; bit4 is power_mode; the remaining bits have no function.

done is cleared when start changes from 0 to 1 or when power_mode changes from 0 to 1. When the last output group of a normal job is written, the hardware clears start and sets done. In power_mode the computation loops and completion events do not set done. After power_mode is stopped, the current job completes and the module returns to idle.

Bit2 of the control word is not strictly read-only; software writes can affect done, so software should write the control word as specified. The reserved bit3 ignores writes and reads as zero.

## Datapath and Output Format

Each of the four MXINT16 inputs is converted to BF16 by int2bf; after two levels of BF16 ADD, 32 results enter quant as one group. Each job processes 256 four-way input groups and produces 8 quantized blocks.

The first 16 4-bit mantissas of each block are written to mx_man_out_mem[2*m] and the last 16 to [2*m+1]; lower-index elements are placed in the lower-order bits. The scale factor of block m is written to [8*m +: 8] of 0xC80. This direct quantization output path is the only output path.

The FSM has the states S_IDLE and S_COMPUTE. After all 256 input groups have been sent, the processed count stops at 256, the module waits for the pipeline to complete, and then ends the current job.

## calc_result

The 8 64-bit input words are interpreted as four 128-bit groups, each containing four signed 32-bit numbers a, b, c, d. The corresponding positions of the four groups are first added, then `4*a + 8*b + 256*c + 512*d` is computed. The existing implementation uses 32-bit modular arithmetic and sign-extends the result to 64-bit. Overflow is not saturating.

## Test Entry

Run `python3 verification/run_regression.py --only fp --width 2` in the rtl directory.
The test uses an independent scalar model to generate the inputs and expected outputs; the random seed can be specified with --seed,
and the local output directory with --out. Tool dependencies and the full test commands are given in the [usage instructions](../../README.md#testing).
