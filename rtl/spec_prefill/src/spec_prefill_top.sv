// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
//////////////////////////////////////////////////////////////////////////////////
// Description: Speculative Prefill Top Unit w/ Bus Conversion & Clock Gating
// Author:      Mingxuan Li <siris-lmx@stu.pku.edu.cn> [Peking University]
// Acknowledge: Siyuan He [Peking University]
//              VSCode Copilot + Gemini-3-Pro Agent
//////////////////////////////////////////////////////////////////////////////////

`include "axi/typedef.svh"
`include "axi/assign.svh"

module spec_prefill_top #(
  parameter int  AXI_ADDR_WIDTH = 64,
  parameter int  AXI_DATA_WIDTH = 64,
  parameter int  AXI_ID_WIDTH   = 16,
  parameter int  AXI_USER_WIDTH = 1,
  parameter type axi_req_t  = logic,
  parameter type axi_rsp_t  = logic
) (
  input  logic     clk_i,
  input  logic     clk_en_i,
  input  logic     rstn_i,

  // AXI4 slave interface
  input  axi_req_t  slv_axi_req_i,
  output axi_rsp_t  slv_axi_rsp_o
);

  // ---------------------------------------------------
  // convert AXI4 slave interface to memory interface
  // ---------------------------------------------------
  logic                       mem_req;
  logic                       mem_valid;
  logic                       mem_write_en;
  logic [AXI_ADDR_WIDTH-1:0]  mem_addr;
  logic [AXI_DATA_WIDTH-1:0]  mem_wdata;
  logic [AXI_DATA_WIDTH-1:0]  mem_rdata;

  axi_to_mem #(
    .axi_req_t    ( axi_req_t      ),
    .axi_resp_t   ( axi_rsp_t      ),
    .AddrWidth    ( AXI_ADDR_WIDTH ),
    .DataWidth    ( AXI_DATA_WIDTH ),
    .IdWidth      ( AXI_ID_WIDTH   ),
    .NumBanks     ( 1              )
  ) axi_to_mem_inst (
    .clk_i        ( clk_i         ),
    .rst_ni       ( rstn_i        ),
    .busy_o       (               ),
    .axi_req_i    ( slv_axi_req_i ),
    .axi_resp_o   ( slv_axi_rsp_o ),
    .mem_req_o    ( mem_req       ),
    .mem_gnt_i    ( '1            ),
    .mem_addr_o   ( mem_addr      ),
    .mem_wdata_o  ( mem_wdata     ),
    .mem_we_o     ( mem_write_en  ),
    .mem_rvalid_i ( mem_valid     ),
    .mem_rdata_i  ( mem_rdata     ),
    .mem_strb_o   (),
    .mem_atop_o   ()
  );

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (!rstn_i) begin
      mem_valid <= 1'b0;
    end
    else begin
      mem_valid <= mem_req;
    end
  end


  // ---------------------------------------------------
  // Speculative Prefill Unit instance
  // ---------------------------------------------------
  logic clk_spec_prefill;
  tc_clk_gating tc_clk_gating_inst (
    .clk_i     ( clk_i            ),
    .en_i      ( clk_en_i         ),
    .test_en_i ( 1'b0             ),
    .clk_o     ( clk_spec_prefill )
  );

  spec_prefill_unit #(
    .ADDR_WIDTH ( AXI_ADDR_WIDTH ),
    .DATA_WIDTH ( AXI_DATA_WIDTH )
  ) spec_prefill_unit_inst (
    .clk_i    ( clk_spec_prefill ),
    .rstn_i   ( rstn_i           ),
    .req_i    ( mem_req          ),
    .we_i     ( mem_write_en     ),
    .addr_i   ( mem_addr         ),
    .data_i   ( mem_wdata        ),
    .data_o   ( mem_rdata        ),
    .rtsel_i  ( 2'b01            ),
    .wtsel_i  ( 2'b00            )
  );

endmodule
