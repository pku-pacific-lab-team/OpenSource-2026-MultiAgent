# INT Core Specification

- Author:      Mingxuan Li <siris-lmx@stu.pku.edu.cn> [Peking University]
- Acknowledge: Renati Tuerhong  <renati0423@gmail.com>
- DUT File:    `int_core/src/int_core.sv`
- TB File:     `int_core/tb/int_core_tb.sv`

## Overview
`int_core` is a dedicated integer arithmetic core that integrates a Processing Element (PE) Array for matrix multiply-accumulate and a Scaling Factor (SF) Array for sparse attention operations. The core is controlled through a memory-mapped interface and uses a dedicated DMA interface for bulk data movement.

## Parameters
| Parameter | Default | Description |
| :--- | :--- | :--- |
| `AXI_ADDR_WIDTH` | 12 | AXI address bus width. |
| `AXI_DATA_WIDTH` | 64 | AXI data bus width. |
| `TILE` (localparam) | 4 | Fixed number of tiles; not an overridable module parameter. |
| `PE_MAX_ACCUM_NUM` | 32 | Maximum PE accumulation depth. |
| `PE_ARRAY_SIZE` | 8 | PE array size (N x N). |
| `PE_DATA_WIDTH` | 4 | PE input data bit width (weight/activation). |
| `SF_DATA_WIDTH` | 8 | SF input data bit width. |
| `SF_BUCKET_WIDTH` | 12 | SF bucket bit width. |
| `SF_ARRAY_SIZE` | 8 | SF array size. |
| `SF_SPATTN_CNT_MAX` | 128 | Maximum sparse attention count. |

## Port Definitions

### Clock and Reset
| Signal | Direction | Description |
| :--- | :--- | :--- |
| `clk_i` | Input | System clock. |
| `rstn_i` | Input | Active-low asynchronous reset. |

### DMA Interface
Connects directly to the internal DMA controller for bulk data transfers.
| Signal | Direction | Width | Description |
| :--- | :--- | :--- | :--- |
| `dma_length_o` | Output | `AXI_ADDR_WIDTH` | Transfer length (bytes). |
| `dma_src_offset_o` | Output | `AXI_ADDR_WIDTH` | Source address offset. |
| `dma_dst_offset_o` | Output | `AXI_ADDR_WIDTH` | Destination address offset. |
| `dma_run_o` | Output | 1 | Pulse that starts a DMA transfer. |
| `dma_ready_i` | Input | 1 | DMA completion handshake signal. |
| `dma_busy_i` | Input | 1 | DMA busy status signal (1: busy, 0: idle). |

### Memory-Mapped Interface
Used for configuration, status readout and data buffer access.
| Signal | Direction | Width | Description |
| :--- | :--- | :--- | :--- |
| `mem_req_i` | Input | 1 | Memory request valid signal. |
| `mem_write_en_i` | Input | 1 | Write enable (1: write, 0: read). |
| `mem_addr_i` | Input | `AXI_ADDR_WIDTH` | Access address. |
| `mem_wdata_i` | Input | `AXI_DATA_WIDTH` | Write data. |
| `mem_rdata_o` | Output | `AXI_DATA_WIDTH` | Read data. |
| `mem_rvalid_o` | Output | 1 | Return valid signal for a pipelined request. |

## Memory Map
The module exposes a 4KB address space (12-bit address).

| Base Address | Name | Size (Bytes) | Description |
| :--- | :--- | :--- | :--- |
| `0x000` | `PE_WEIGHT_BUFFER` | `PE_INPUT_LENGTH` | PE weight buffer. |
| `0x200` | `PE_ACTIVATION_BUFFER` | `PE_INPUT_LENGTH` | PE activation buffer. |
| `0x400` | `PE_RESULT_BUFFER` | `PE_OUTPUT_LENGTH` | PE result buffer (read-only). |
| `0x500` | `SF0_CURR_BUFFER` | `SF_INPUT_LENGTH` | SF0 current value buffer. |
| `0x520` | `SF1_CURR_BUFFER` | `SF_INPUT_LENGTH` | SF1 current value buffer. |
| `0x540` | `SF0_PRED_BUFFER` | `SF_INPUT_LENGTH` | SF0 predicted value buffer. |
| `0x560` | `SF1_PRED_BUFFER` | `SF_INPUT_LENGTH` | SF1 predicted value buffer. |
| `0x580` | `SF_RESULT_BUFFER` | `SF_OUTPUT_LENGTH` | SF result buffer (read-only). |
| `0x600` | `SIGN0_BUFFER` | `SIGN_LENGTH` | Sign0 value buffer. |
| `0x680` | `SIGN1_BUFFER` | `SIGN_LENGTH` | Sign1 value buffer. |
| `0x700` | `SUM_BUCKET_BUFFER` | `SUM_BUCKET_LENGTH` | Bucket sum result buffer (read-only). |
| `0x800` | Reserved | 256 | Reads back `0xCA11AB1EBADCAB1E`; writes are ignored. |
| `0xF00` | `CTRL_STATUS_REG` | 8 | Control and status register. |

The memory interface has no byte-enable; use 64-bit whole-word accesses and sample the returned value when `mem_rvalid_o` is asserted.

### Control/Status Register (`0xF00`)
**Write:**
| Bit | Name | Description |
| :--- | :--- | :--- |
| 0 | `pe_enable` | Pulse that starts PE array computation. |
| 1 | `sf_enable` | Pulse that starts SF array computation. |
| 2 | `spattn_enable` | Pulse that starts sparse attention computation. |
| 9:8 | `run_mode` | 0: functional mode (FUNC), 1: compute power mode (COMPUTE_PWR), 2: DMA power mode (DMA_PWR), 3: all power mode (ALL_PWR). |

| 13:12 | `col_idx` | SpAttn column select. |
| 7:3 | Reserved | Writes are ignored. |

**Read:**
| Bit | Name | Description |
| :--- | :--- | :--- |
| 0-15 | `pe_cycle_cnt` | PE operation cycle count. |
| 16-31 | `sf_cycle_cnt` | SF operation cycle count. |
| 32-47 | `spattn_cycle_cnt` | Sparse attention operation cycle count. |
| 48 | `pe_finish` | PE operation done flag. |
| 49 | `sf_finish` | SF operation done flag. |
| 50 | `spattn_finish` | SpAttn operation done flag. |
| 57:56 | `run_mode` | Current run mode. |

| 61:60 | `col_idx` | Current SpAttn column select. |
| 55:51 | Reserved | Reads as zero. |

## Functional Description

### 1. PE Array Operation
The PE array performs matrix multiplication.
1.  **Configuration**: Write weights and activations into `PE_WEIGHT_BUFFER` and `PE_ACTIVATION_BUFFER` through the memory-mapped interface.
2.  **Execution**: Write `1` to the `pe_enable` bit of `CTRL_STATUS_REG`.
3.  **Processing**: The controller feeds data to the PE array tile by tile.
    - The computation is divided into 4 tiles (groups).
    - Each tile performs one matrix multiplication with an accumulation depth of 32 (`PE_MAX_ACCUM_NUM`).
    - **Execution sequence**:
        1.  **Tile 0**: Load data and compute the 8x8 result (32 cycles).
        2.  **DMA 0**: Transfer the Tile 0 result to memory/NoC. After the DMA handshake completes, wait for `dma_busy_i` to go low to ensure the transfer has finished.
        3.  **Tile 1**: Load data and compute the 8x8 result (32 cycles).
        4.  **DMA 1**: Transfer the Tile 1 result. After the DMA handshake completes, wait for `dma_busy_i` to go low to ensure the transfer has finished.
        5.  **Tile 2**: Load data and compute the 8x8 result (32 cycles).
        6.  **DMA 2**: Transfer the Tile 2 result. After the DMA handshake completes, wait for `dma_busy_i` to go low to ensure the transfer has finished.
        7.  **Tile 3**: Load data and compute the 8x8 result (32 cycles).
        8.  **DMA 3**: Transfer the Tile 3 result. After the DMA handshake completes, wait for `dma_busy_i` to go low, and return to IDLE once the transfer has finished.
4.  **Note**: Results can be read from `PE_RESULT_BUFFER` during the corresponding DMA phase. Note that the result buffer is overwritten by the next tile, so the data must be read or transferred immediately.

### 2. SF Array & SpAttn Operation
The SF array and the sparse attention logic share one main FSM, which supports three operating modes.

#### Mode 1: SF Computation Only (`sf_enable=1`, `spattn_enable=0`)
Performs SF computation and DMA transfer for 4 tiles.
- **Sequence**: `SF_TILE0` -> `SF_DMA0` -> `SF_TILE1` -> `SF_DMA1` -> `SF_TILE2` -> `SF_DMA2` -> `SF_TILE3` -> `SF_DMA3` -> `SF_IDLE`.
- Each tile computes an 8x8 exponent matrix.
- In the `SF_DMA*` phases, after the DMA handshake completes, wait for `dma_busy_i` to go low to ensure the transfer has finished.

#### Mode 2: SpAttn Computation Only (`sf_enable=0`, `spattn_enable=1`)
Performs sparse attention bucket accumulation and reduction.
- **Sequence**: `SPATTN_COMPUTE` -> `SPATTN_DMA` -> `SF_IDLE`.
- `SPATTN_COMPUTE`: Lasts `SF_SPATTN_CNT_MAX` cycles and updates the buckets using the data in the prediction buffers (`SF_PRED_BUFFER`).
- `SPATTN_DMA`: Transfers the final bucket sum result (`SUM_BUCKET_BUFFER`). After the DMA handshake completes, wait for `dma_busy_i` to go low, and return to IDLE once the transfer has finished.

#### Mode 3: Combined Computation (`sf_enable=1`, `spattn_enable=1`)
Performs SF computation and SpAttn computation serially.
- **Sequence**: `SF_TILE0` -> `SF_DMA0` -> ... -> `SF_TILE3` -> `SF_DMA3` -> `SPATTN_COMPUTE` -> `SPATTN_DMA` -> `SF_IDLE`.
- In the `SPATTN_DMA` phase, after the DMA handshake completes, wait for `dma_busy_i` to go low, and return to IDLE once the transfer has finished.

### 3. DMA Arbitration
The module integrates a round-robin arbiter that coordinates the DMA requests from the PE, SF and SpAttn.
- **Priority**: Adjusted dynamically based on the previous winner (`dma_last_winner`).
- **Request sources**:
  - `PE_DMA`: PE array result transfer.
  - `SF_DMA`: SF array result transfer.
  - `SPATTN_DMA`: SpAttn bucket result transfer.
- **Mechanism**: Ensures that all request sources obtain DMA bandwidth fairly and avoids starvation.

### 4. Power Modes
Configured through the `run_mode` register; used for power testing and evaluation.
- **FUNC (0)**: Normal functional mode. After an operation completes, the FSM returns to IDLE automatically and sets the done flag.
- **COMPUTE_PWR (1)**: Compute-only loop mode. The FSM loops among the compute states (`TILEx` / `COMPUTE`) and skips DMA.
- **DMA_PWR (2)**: DMA-only loop mode. The FSM loops among the DMA states and skips computation.
- **ALL_PWR (3)**: Full-load loop mode. The FSM loops indefinitely between the compute and DMA states.
