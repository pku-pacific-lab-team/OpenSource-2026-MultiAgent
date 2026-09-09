# CVA6 SoC System Architecture Document

## System Connection Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                        SoC Core Architecture                        │
└─────────────────────────────────────────────────────────────────────┘

                    ┌──────────────┐
                    │   CVA6 CPU   │
                    │  (Master)     │
                    └──────┬───────┘
                           │ slave[0]
                           │ AXI_BUS
                           ▼
                    ┌──────────────┐
                    │              │
                    │  AXI_XBAR    │
                    │  (Crossbar)  │
                    │              │
                    └──────┬───────┘
                           │
         ┌─────────────────┼─────────────────┐
         │                 │                 │
    master[11]        master[12]             │
    (LLCcfg)          (LLC)                  │
         │                 │                 │
         │                 │                 │
    ┌────▼────┐      ┌─────▼──────┐          │
    │         │      │            │          │
    │ LLC     │      │    LLC     │          │
    │ Config  │      │  (Cache)   │          │
    │ Regs    │      │            │          │
    └─────────┘      │            │          │
                     │ slv        │          │
                     │ (master[12])│         │
                     │            │          │
                     │ mst        │          │
                     │ (dram)     │          │
                     └──────┬─────┘          │
                            │                │
                            │ dram           │
                            │ AXI_BUS        │
                            ▼                │
                     ┌──────────────┐        │
                     │              │        │
                     │  axi2mem     │        │
                     │  (Converter) │        │
                     │              │        │
                     └──────┬───────┘        │
                            │                │
                            │ mem_bus        │
                            ▼                │
                     ┌──────────────┐        │
                     │              │        │
                     │ main_mem     │        │
                     │ _wrapper     │        │
                     │  (DRAM)      │        │
                     │              │        │
                     └──────────────┘        │
```

## Core Component Connections

### 1. CPU to XBAR
- **CPU (CVA6)**: master device, connected to the XBAR through `slave[0]`
- **Connection code**: 
  ```systemverilog
  `AXI_ASSIGN_FROM_REQ(slave[0], axi_ariane_req)
  `AXI_ASSIGN_TO_RESP(axi_ariane_resp, slave[0])
  ```

### 2. XBAR Routing Rules
The XBAR routes requests to the corresponding master port according to the address map:

| Master Port | Component | Base Address | End Address | Size |
|------------|------|--------|----------|------|
| master[11] | **LLCcfg** | **0x6000_0000** | **0x6000_0FFF** | **4KB** |
| master[12] | **LLC** | **0x8000_0000** | **0x9FFF_FFFF** | **512MB** |

**Note**: the LLC address map covers 512MB (0x8000_0000 to 0x9FFF_FFFF), including:
- **SPM region**: 0x8000_0000 to 0x8FFF_FFFF (256MB) - direct access, not through the cache
- **Cache region**: 0x9000_0000 to 0x9FFF_FFFF (256MB) - DRAM accessed through the LLC cache

### 3. LLC Config Connection
- **LLC Config port**: connected to `master[soc_pkg::LLCcfg]` (master[11])
- **Function**: configures the LLC cache policy, SPM locking, flush control, etc.
- **Connection code**:
  ```systemverilog
  axi_to_reg_intf i_axi_to_llc_csr_reg_intf(
      .in      ( master[soc_pkg::LLCcfg] ),
      .reg_o   ( i_reg_bus_llc           )
  );
  ```

### 4. LLC Connection
- **LLC slave port (slv)**: connected to `master[soc_pkg::LLC]` (master[12]), receives requests from the XBAR
- **LLC master port (mst)**: connected to the dedicated `dram` AXI bus, issues requests to DRAM
- **LLC configuration port**: connected to `i_reg_bus_llc`, used for configuration register access
- **Connection code**:
  ```systemverilog
  axi_llc_reg_wrap_wrap i_axi_llc_dut (
      .clk_i     ( clk                    ),
      .rst_ni    ( ndmreset_n             ),
      .slv       ( master[soc_pkg::LLC]   ),  // receives requests from the XBAR
      .mst       ( dram                   ),  // issues requests to DRAM
      .conf_intf ( i_reg_bus_llc          )   // configuration register interface
  );
  ```

### 5. DRAM Connection
- **DRAM bus**: dedicated `dram` AXI bus connecting the LLC and main_mem
- **Converter**: `axi2mem` converts the AXI protocol to the memory interface
- **Main memory**: `main_mem_wrapper` implements the actual storage
- **Connection code**:
  ```systemverilog
  // AXI to memory interface conversion
  axi2mem i_main_mem_axi2mem (
      .slave  ( dram          ),
      .req_o  ( main_mem_req  ),
      .we_o   ( main_mem_we   ),
      .addr_o ( main_mem_addr ),
      .be_o   ( main_mem_be   ),
      .data_o ( main_mem_wdata),
      .data_i ( main_mem_rdata)
  );
  
  // Main memory instance
  main_mem_wrapper i_main_mem_wrapper (
      .axi_req_i      ( main_mem_req   ),
      .axi_write_en_i ( main_mem_we    ),
      .axi_addr_i     ( main_mem_addr  ),
      .axi_byte_en_i  ( main_mem_be    ),
      .axi_wdata_i    ( main_mem_wdata ),
      .axi_rdata_o    ( main_mem_rdata )
  );
  ```

## Data Flow Paths

### Read Path (Cache Miss)
```
CPU → slave[0] → XBAR → master[12] → LLC (slv)
                                              ↓
                                         LLC processing
                                         (Cache Miss)
                                              ↓
LLC (mst) → dram → axi2mem → main_mem_wrapper
                                              ↓
                                         DRAM returns data
                                              ↓
main_mem_wrapper → axi2mem → dram → LLC (mst)
                                              ↓
                                         LLC caches the data
                                              ↓
LLC (slv) → master[12] → XBAR → slave[0] → CPU
```

### Read Path (Cache Hit)
```
CPU → slave[0] → XBAR → master[12] → LLC (slv)
                                              ↓
                                         LLC cache hit
                                              ↓
LLC (slv) → master[12] → XBAR → slave[0] → CPU
```

### SPM Access Path (Direct Access to the LLC Internal SRAM)
```
CPU → slave[0] → XBAR → master[12] → LLC (slv)
                                              ↓
                                         LLC internal processing
                                         (SPM access)
                                              ↓
                                         LLC Data Way
                                         (internal SRAM)
                                              ↓
LLC (slv) → master[12] → XBAR → slave[0] → CPU
```

**Note**: the SPM (Scratch-Pad Memory) is a storage region inside the LLC; it is accessed directly through the data way SRAMs inside the LLC and **does not go through DRAM**. SPM accesses enter the LLC internals (`idx=0`) through the routing control of the `axi_llc_config` module, rather than the bypass path (`idx=1`). Each cache way has its own SRAM, and SPM accesses read and write these SRAMs directly, with low latency and no DRAM involvement.

## Key Parameters

### AXI Bus Parameters
- **AXI address width**: 64 bits
- **AXI data width**: 64 bits
- **AXI ID width (Master)**: 4 bits
- **AXI ID width (Slaves)**: 5 bits (4 + log2(2))

### LLC Configuration Parameters
- **Set Associativity**: 8-way
- **Number of Lines**: 256
- **Number of Blocks**: 4 (`LLCNumBlocks` in `soc_noc.sv`)
- **Cache Size**: 8 × 256 × 4 × 64 bits = 64 KiB
- **Cached Region Start**: 0x9000_0000 (DRAMBase)
- **Cached Region Length**: 256MB (DRAMLength)
- **SPM Region Start**: 0x8000_0000 (LLCBase)
- **SPM Region Length**: 256MB (LLCLength)

## Address Map

| Component | Base Address | End Address | Size | Master Port | Description |
|------|--------|----------|------|------------|------|
| **LLCcfg** | **0x6000_0000** | **0x6000_0FFF** | **4KB** | **master[11]** | **LLC configuration registers** |
| **LLC (SPM)** | **0x8000_0000** | **0x8FFF_FFFF** | **256MB** | **master[12]** | **LLC SPM region** |
| **LLC (Cache)** | **0x9000_0000** | **0x9FFF_FFFF** | **256MB** | **master[12]** | **LLC cache region (DRAM)** |
