// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
//////////////////////////////////////////////////////////////////////////////////
// Description: FP Core Top Module inlcluding Bus Conversion & Clock Gating
// Author:      Hongou Li [Peking University]
// Acknowledge: Google AI Studio + Gemini-3-Pro
//////////////////////////////////////////////////////////////////////////////////

`include "axi/typedef.svh"
`include "axi/assign.svh"

module fp_core_top #(
  parameter int  AXI_ADDR_WIDTH = 64,
  parameter int  AXI_DATA_WIDTH = 64,
  parameter int  AXI_ID_WIDTH   = 16,
  parameter int  AXI_USER_WIDTH = 1,
  parameter type axi_req_t  = logic,
  parameter type axi_rsp_t  = logic
) (
    input  logic                        clk_i                      ,
    input  logic                        clk_en_i                   ,
    input  logic                        rstn_i                     ,

    // AXI4 slave interface
    input                               axi_req_t  slv_axi_req_i   ,
    output                              axi_rsp_t  slv_axi_rsp_o
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

    logic                               clk_fp_core                 ;
  tc_clk_gating tc_clk_gating_inst (
    .clk_i                              (clk_i                     ),
    .en_i                               (clk_en_i                  ),
    .test_en_i                          (1'b0                      ),
    .clk_o                              (clk_fp_core               )
  );

  fp_core fp_core_inst (
    .clk_i                              (clk_fp_core               ),
    .rstn_i                             (rstn_i                    ),
    .req_i                              (mem_req                   ),
    .we_i                               (mem_write_en              ),
    .addr_i                             (mem_addr                  ),
    .byte_en_i                          ({8{mem_write_en}}         ),
    .wdata_i                            (mem_wdata                 ),
    .rdata_o                            (mem_rdata                 )
  );

endmodule
