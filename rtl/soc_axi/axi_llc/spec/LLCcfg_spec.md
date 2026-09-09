## LLC Config Detailed Description

### LLC Config Register Map

LLC Config provides configuration and control functions through an AXI register interface. All registers are located at addresses `0x6000_0000` to `0x6000_0FFF`.

| Register Name | Offset Address | Size | Access | Function Description |
|-----------|---------|------|---------|---------|
| `cfg_spm_low` | 0x000 | 32 bits | RW | SPM configuration register (low 32 bits) |
| `cfg_spm_high` | 0x004 | 32 bits | RW | SPM configuration register (high 32 bits) |
| `cfg_flush_low` | 0x008 | 32 bits | RW | Flush configuration register (low 32 bits) |
| `cfg_flush_high` | 0x00C | 32 bits | RW | Flush configuration register (high 32 bits) |
| `commit_cfg` | 0x010 | 1 bit | RW | Configuration commit register |
| `flushed_low` | 0x018 | 32 bits | RO | Flushed status register (low 32 bits) |
| `flushed_high` | 0x01C | 32 bits | RO | Flushed status register (high 32 bits) |
| `bist_out_low` | 0x020 | 32 bits | RO | BIST output result (low 32 bits) |
| `bist_out_high` | 0x024 | 32 bits | RO | BIST output result (high 32 bits) |
| `set_asso_low` | 0x028 | 32 bits | RO | Set Associativity (low 32 bits) |
| `set_asso_high` | 0x02C | 32 bits | RO | Set Associativity (high 32 bits) |
| `num_lines_low` | 0x030 | 32 bits | RO | Number of cache lines (low 32 bits) |
| `num_lines_high` | 0x034 | 32 bits | RO | Number of cache lines (high 32 bits) |
| `num_blocks_low` | 0x038 | 32 bits | RO | Number of blocks (low 32 bits) |
| `num_blocks_high` | 0x03C | 32 bits | RO | Number of blocks (high 32 bits) |
| `version_low` | 0x040 | 32 bits | RO | LLC version number (low 32 bits) |
| `version_high` | 0x044 | 32 bits | RO | LLC version number (high 32 bits) |
| `bist_status` | 0x048 | 1 bit | RO | BIST status register |

### Key Register Details

#### 1. CfgSpm (SPM Configuration Register)
- **Address**: 0x000-0x007 (64 bits)
- **Access**: read/write
- **Function**: configures which cache ways are used as SPM (Scratch-Pad Memory)
- **Bit fields**:
  - `[SetAssociativity-1:0]`: each bit corresponds to one cache way
    - `1'b1`: the way is configured as SPM
    - `1'b0`: the way is used as normal cache
  - `[63:SetAssociativity]`: reserved bits
- **Notes**: 
  - Ways configured as SPM are mapped directly to the SRAM inside the LLC
  - Accesses to the SPM region must use ways configured as SPM, otherwise `RESP_SLVERR` is returned
  - After modification, the `commit_cfg` register must be written for the configuration to take effect

#### 2. CfgFlush (Flush Configuration Register)
- **Address**: 0x008-0x00F (64 bits)
- **Access**: read/write
- **Function**: triggers a flush operation on the specified cache ways
- **Bit fields**:
  - `[SetAssociativity-1:0]`: each bit corresponds to one cache way
    - `1'b1`: triggers a flush of the way
    - `1'b0`: no flush
  - `[63:SetAssociativity]`: reserved bits
- **Notes**:
  - The flush operation writes dirty data back to DRAM and clears the valid flags in the cache
  - During the flush, the LLC enters an isolated state and blocks new cache accesses
  - After modification, the `commit_cfg` register must be written to trigger the flush

#### 3. CommitCfg (Configuration Commit Register)
- **Address**: 0x010 (1 bit)
- **Access**: read/write
- **Function**: commits the SPM or Flush configuration so that it takes effect
- **Bit fields**:
  - `[0]`: configuration commit flag
    - `1'b1`: commits the configuration and triggers hardware processing
    - `1'b0`: no operation
- **Notes**:
  - This register **must** be written after writing `CfgSpm` or `CfgFlush`
  - After `1'b1` is written, the hardware starts processing the configuration (SPM locking or cache flush)
  - After the configuration processing completes, the status can be checked through the `Flushed` register

#### 4. Flushed (Flushed Status Register)
- **Address**: 0x018-0x01F (64 bits)
- **Access**: read-only
- **Function**: shows which cache ways are in the flushed state
- **Bit fields**:
  - `[SetAssociativity-1:0]`: each bit corresponds to one cache way
    - `1'b1`: the way has been flushed (no valid data)
    - `1'b0`: the way contains valid cache data
- **Notes**:
  - Ways configured as SPM automatically have their corresponding flushed bit set
  - After a flush operation completes, the corresponding bits are set
  - When all ways have been flushed, all accesses to the cache region bypass directly to DRAM

#### 5. BistOut (BIST Output Register)
- **Address**: 0x020-0x027 (64 bits)
- **Access**: read-only
- **Function**: shows the BIST (Built-In Self-Test) result of the Tag Storage
- **Bit fields**:
  - `[SetAssociativity-1:0]`: each bit corresponds to one cache way
    - `1'b1`: BIST failed; the tag storage of the way may be faulty
    - `1'b0`: BIST passed
- **Notes**:
  - The BIST is executed automatically during system initialization
  - Ways that fail the test are automatically configured as SPM to avoid using faulty cache

#### 6. BistStatus (BIST Status Register)
- **Address**: 0x048 (1 bit)
- **Access**: read-only
- **Function**: shows whether the BIST has completed
- **Bit fields**:
  - `[0]`: BIST completion flag
    - `1'b1`: BIST completed
    - `1'b0`: BIST in progress or not started

#### 7. SetAsso (Set Associativity Register)
- **Address**: 0x028-0x02F (64 bits)
- **Access**: read-only
- **Function**: shows the instantiated cache set associativity
- **Value**: **8-way** in the current system

#### 8. NumLines (Number of Cache Lines Register)
- **Address**: 0x030-0x037 (64 bits)
- **Access**: read-only
- **Function**: shows the number of cache lines per set
- **Value**: **256 lines** in the current system

#### 9. NumBlocks (Number of Blocks Register)
- **Address**: 0x038-0x03F (64 bits)
- **Access**: read-only
- **Function**: shows the number of blocks per cache line
- **Value**: **8 blocks** in the current system

#### 10. Version (LLC Version Register)
- **Address**: 0x040-0x047 (64 bits)
- **Access**: read-only
- **Function**: shows the version number of the LLC module
- **Value**: defined by `axi_llc_pkg::AxiLlcVersion`

### LLC Config Configuration Flow

#### SPM Configuration Flow
1. **Write the CfgSpm register**: set which ways are used as SPM
   ```c
   // Example: configure ways 0-3 as SPM (assuming 8-way)
   write_reg(0x6000_0000, 0x0000000F); // low 32 bits
   write_reg(0x6000_0004, 0x00000000); // high 32 bits
   ```

2. **Commit the configuration**: write the `commit_cfg` register
   ```c
   write_reg(0x6000_0010, 0x1); // commit configuration
   ```

3. **Wait for the configuration to complete**: poll the `Flushed` register to confirm that the configuration has taken effect
   ```c
   while ((read_reg(0x6000_0018) & 0x0F) != 0x0F) {
       // wait for ways 0-3 to be marked as flushed
   }
   ```

#### Flush Configuration Flow
1. **Write the CfgFlush register**: set the ways to flush
   ```c
   // Example: flush all ways
   write_reg(0x6000_0008, 0xFFFFFFFF); // low 32 bits
   write_reg(0x6000_000C, 0xFFFFFFFF); // high 32 bits
   ```

2. **Commit the configuration**: write the `commit_cfg` register to trigger the flush
   ```c
   write_reg(0x6000_0010, 0x1); // trigger flush
   ```

3. **Wait for the flush to complete**: poll the `Flushed` register
   ```c
   while ((read_reg(0x6000_0018) & 0xFF) != 0xFF) {
       // wait for all ways to finish flushing
   }
   ```

### LLC Config Key Functions

1. **SPM locking**: `CfgSpm` configures which ways are used as SPM; these ways are not used as normal cache
2. **Cache flush**: `CfgFlush` triggers a cache flush that writes dirty data back to DRAM
3. **BIST support**: automatically detects tag storage faults and configures the faulty ways as SPM
4. **Status monitoring**: read-only registers monitor the LLC operating status and configuration parameters

## Key Code Locations

### Main Files
- `src/soc.sv`: SoC top-level module, contains all connections
- `src/soc_pkg.sv`: SoC parameter definitions, including the address map
- `src/soc_axi/axi_llc/`: LLC-related modules
- `src/soc_axi/axi_llc/axi_llc_config.sv`: LLC configuration module
- `src/soc_axi/axi_llc/axi_llc_reg_top.sv`: LLC register top-level module
- `src/soc_axi/main_mem/`: main memory related modules

### Key Connection Points
- **CPU connection**: `src/soc.sv:418-419`
- **XBAR configuration**: `src/soc.sv:212-226`
- **LLC Config connection**: `src/soc.sv:761-772`
- **LLC instantiation**: `src/soc.sv:774-792`
- **DRAM connection**: `src/soc.sv:719-748`
