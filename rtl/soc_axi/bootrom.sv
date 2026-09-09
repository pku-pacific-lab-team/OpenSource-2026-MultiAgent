//
// Local modifications: see the notices in this file (last changed 2025-12-26).
// Upstream: cheshire (https://github.com/pulp-platform/cheshire), target/sim/src/dpi/bootrom.sv at branch zx/c910
/* Copyright 2018 ETH Zurich and University of Bologna.
 * Copyright and related rights are licensed under the Solderpad Hardware
 * License, Version 0.51 (the "License"); you may not use this file except in
 * compliance with the License.  You may obtain a copy of the License at
 * http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
 * or agreed to in writing, software, hardware and materials distributed under
 * this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 * CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 *
 * File: $filename.v
 *
 * Description: Auto-generated bootrom
 */

// Auto-generated code
// Modified by: Hongou Li [Peking University]
//              Mingxuan Li <siris-lmx@stu.pku.edu.cn> [Peking University]
module bootrom (
   input  logic         clk_i,
   input  logic         req_i,
   input  logic [63:0]  addr_i,
   input  logic [1:0]   soc_id_i,
   input  logic         jump_sel_i,  // 0: scratchpad, 1: DRAM
   output logic [63:0]  rdata_o
);

    localparam int RomSize = 9;

`ifdef SIM
    // ROM content for SoC with ID = 2'b00
    const logic [RomSize-1:0][63:0] mem_scratchpad_00 = {
        64'h00000000_000000ef,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00040067,
        64'h01f41413_0010041b
    };

    const logic [RomSize-1:0][63:0] mem_dram_00 = {
        64'h00000000_000000ef,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00040067,
        64'h01c41413_0090041b
    };

    // ROM content for SoC with ID = 2'b01
    const logic [RomSize-1:0][63:0] mem_scratchpad_01 = {
        64'h00000000_000000ef,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00040067,
        64'h01f41413_0030041b
    };

    const logic [RomSize-1:0][63:0] mem_dram_01 = {
        64'h00000000_000000ef,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00040067,
        64'h01c41413_0190041b
    };

    // ROM content for SoC with ID = 2'b10
    const logic [RomSize-1:0][63:0] mem_scratchpad_10 = {
        64'h00000000_000000ef,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00040067,
        64'h01f41413_0050041b
    };

    const logic [RomSize-1:0][63:0] mem_dram_10 = {
        64'h00000000_000000ef,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00040067,
        64'h01c41413_0290041b
    };

    // ROM content for SoC with ID = 2'b11
    const logic [RomSize-1:0][63:0] mem_scratchpad_11 = {
        64'h00000000_000000ef,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00040067,
        64'h01f41413_0070041b
    };

    const logic [RomSize-1:0][63:0] mem_dram_11 = {
        64'h00000000_000000ef,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00040067,
        64'h01c41413_0390041b
    };
`else
    // ROM content for SoC with ID = 2'b00
    const logic [RomSize-1:0][63:0] mem_scratchpad_00 = {
        64'h00000000_000000ef,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00040067,
        64'h01f41413_0010041b
    };

    const logic [RomSize-1:0][63:0] mem_dram_00 = {
        64'h00000000_000000ef,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00040067,
        64'h01c41413_0090041b
    };

    // ROM content for SoC with ID = 2'b01
    const logic [RomSize-1:0][63:0] mem_scratchpad_01 = {
        64'h00000000_000000ef,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00040067,
        64'h01f41413_0030041b
    };

    const logic [RomSize-1:0][63:0] mem_dram_01 = {
        64'h00000000_000000ef,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00040067,
        64'h01c41413_0190041b
    };

    // ROM content for SoC with ID = 2'b10
    const logic [RomSize-1:0][63:0] mem_scratchpad_10 = {
        64'h00000000_000000ef,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00040067,
        64'h01f41413_0050041b
    };

    const logic [RomSize-1:0][63:0] mem_dram_10 = {
        64'h00000000_000000ef,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00040067,
        64'h01c41413_0290041b
    };

    // ROM content for SoC with ID = 2'b11
    const logic [RomSize-1:0][63:0] mem_scratchpad_11 = {
        64'h00000000_000000ef,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00040067,
        64'h01f41413_0070041b
    };

    const logic [RomSize-1:0][63:0] mem_dram_11 = {
        64'h00000000_000000ef,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00000000,
        64'h00000000_00040067,
        64'h01c41413_0390041b
    };
`endif

    logic [$clog2(RomSize)-1:0] addr_q;

    always_ff @(posedge clk_i) begin
        if (req_i) begin
            addr_q <= addr_i[$clog2(RomSize)-1+3:3];
        end
    end

    always_comb begin
        rdata_o = '0;

        if (addr_q < RomSize) begin
            case (soc_id_i)
                2'b00:   rdata_o = jump_sel_i ? mem_dram_00[addr_q] : mem_scratchpad_00[addr_q];
                2'b01:   rdata_o = jump_sel_i ? mem_dram_01[addr_q] : mem_scratchpad_01[addr_q];
                2'b10:   rdata_o = jump_sel_i ? mem_dram_10[addr_q] : mem_scratchpad_10[addr_q];
                2'b11:   rdata_o = jump_sel_i ? mem_dram_11[addr_q] : mem_scratchpad_11[addr_q];
                default: rdata_o = '0;
            endcase
        end
    end

endmodule
