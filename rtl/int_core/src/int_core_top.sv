// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
//////////////////////////////////////////////////////////////////////////////////
// Description: INT Core Top Module inlcluding INT Core, DMA & Clock Gating
// Author:      Mingxuan Li <siris-lmx@stu.pku.edu.cn> [Peking University]
// Acknowledge: Renati Tuerhong  <renati0423@gmail.com>
//              VSCode Copilot + Gemini-3-Pro Agent
//////////////////////////////////////////////////////////////////////////////////

`include "axi/typedef.svh"
`include "axi/assign.svh"

module int_core_top #(
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

  // AXI4 master interface
  output axi_req_t  mst_axi_req_o,
  input  axi_rsp_t  mst_axi_rsp_i,

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
  // arbit memory interface between INT Core and DMA
  // ---------------------------------------------------
  logic                       int_core_mem_req;
  logic                       int_core_mem_write_en;
  logic [AXI_ADDR_WIDTH-1:0]  int_core_mem_addr;
  logic [AXI_DATA_WIDTH-1:0]  int_core_mem_wdata;
  logic [AXI_DATA_WIDTH-1:0]  int_core_mem_rdata;

  logic                       dma_mem_req;
  logic                       dma_mem_write_en;
  logic [AXI_ADDR_WIDTH-1:0]  dma_mem_addr;
  logic [AXI_DATA_WIDTH-1:0]  dma_mem_wdata;
  logic [AXI_DATA_WIDTH-1:0]  dma_mem_rdata;

  localparam                  INT_CORE = 0, DMA = 1;
  logic                       mem_sel;  // 0: int core, 1: dma
  logic                       last_mem_sel_d, last_mem_sel_q;

  assign mem_sel                = mem_addr[32-8-1:12];
  assign last_mem_sel_d         = mem_sel;

  assign int_core_mem_write_en  = mem_write_en;
  assign int_core_mem_addr      = mem_addr;
  assign int_core_mem_wdata     = mem_wdata;

  assign dma_mem_write_en       = mem_write_en;
  assign dma_mem_addr           = mem_addr;
  assign dma_mem_wdata          = mem_wdata;

  // memory write data mux
  assign int_core_mem_req = mem_req & ~mem_sel;
  assign dma_mem_req      = mem_req &  mem_sel;

  // memory read data mux
  assign mem_rdata = (last_mem_sel_q == INT_CORE) ? int_core_mem_rdata : dma_mem_rdata;

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (!rstn_i) begin
      last_mem_sel_q <= 1'b0;
    end
    else begin
      last_mem_sel_q <= last_mem_sel_d;
    end
  end


  // ---------------------------------------------------
  // DMA instance
  // ---------------------------------------------------
  logic [AXI_ADDR_WIDTH-1:0]  dma_length      ;
  logic [AXI_ADDR_WIDTH-1:0]  dma_src_offset  ;
  logic [AXI_ADDR_WIDTH-1:0]  dma_dst_offset  ;
  logic                       dma_run         ;
  logic                       dma_ready       ;
  logic                       dma_busy        ;

  idma_top #(
    .AxiAddrWidth ( AXI_ADDR_WIDTH ),
    .AxiDataWidth ( AXI_DATA_WIDTH ),
    .AxiIdWidth   ( AXI_ID_WIDTH   ),
    .AxiUserWidth ( AXI_USER_WIDTH ),
    .axi_req_t    ( axi_req_t      ),
    .axi_res_t    ( axi_rsp_t      )
  ) idma_top_inst (
    .clk_i            ( clk_i            ),
    .rst_ni           ( rstn_i           ),
    .testmode_i       ( 1'b0             ),

    // AXI4 Master interface
    .axi_req_o        ( mst_axi_req_o    ),
    .axi_res_i        ( mst_axi_rsp_i    ),

    // Control register interface
    .axi_req_i        ( dma_mem_req      ),
    .axi_write_en_i   ( dma_mem_write_en ),
    .axi_addr_i       ( dma_mem_addr     ),
    .axi_wdata_i      ( dma_mem_wdata    ),
    .axi_rdata_o      ( dma_mem_rdata    ),

    // Direct interface to internal accelerator
    .dma_length_i     ( dma_length       ),
    .dma_src_offset_i ( dma_src_offset   ),
    .dma_dst_offset_i ( dma_dst_offset   ),
    .dma_run_i        ( dma_run          ),
    .dma_ready_o      ( dma_ready        ),
    .dma_busy_o       ( dma_busy         )
  );


  // ---------------------------------------------------
  // INT Core instance
  // ---------------------------------------------------

  logic clk_int_core;
  tc_clk_gating tc_clk_gating_int_core_inst (
    .clk_i     ( clk_i        ),
    .en_i      ( clk_en_i     ),
    .test_en_i ( 1'b0         ),
    .clk_o     ( clk_int_core )
  );

  int_core int_core_inst (
    .clk_i            ( clk_int_core          ),
    .rstn_i           ( rstn_i                ),

    // Memory interface
    .mem_req_i        ( int_core_mem_req      ),
    .mem_write_en_i   ( int_core_mem_write_en ),
    .mem_addr_i       ( int_core_mem_addr     ),
    .mem_wdata_i      ( int_core_mem_wdata    ),
    .mem_rdata_o      ( int_core_mem_rdata    ),

    // DMA control interface
    .dma_length_o     ( dma_length            ),
    .dma_src_offset_o ( dma_src_offset        ),
    .dma_dst_offset_o ( dma_dst_offset        ),
    .dma_run_o        ( dma_run               ),
    .dma_ready_i      ( dma_ready             ),
    .dma_busy_i       ( dma_busy              )
  );

endmodule
