// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
//////////////////////////////////////////////////////////////////////////////////
// Description: Cluster Top Including AXI Interface Convertion
// Author:      Mingxuan Li <siris-lmx@stu.pku.edu.cn> [Peking University]
// Acknowledge: VSCode Copilot + Gemini-3-Pro Agent
//////////////////////////////////////////////////////////////////////////////////

`include "axi/typedef.svh"
`include "axi/assign.svh"

module cluster_top #(
  parameter type axi_req_t  = logic,
  parameter type axi_rsp_t  = logic
)
(
  input  logic                 clk_i             ,
  input  logic                 rstn_i            ,
  input  logic     [5-1:0]     clk_en_i          ,

  // AXI4 master interface
  output axi_req_t [4-1:0]     mst_axi_req_o     ,
  input  axi_rsp_t [4-1:0]     mst_axi_rsp_i     ,

  // AXI4 slave interface
  input  axi_req_t [5-1:0]     slv_axi_req_i     ,
  output axi_rsp_t [5-1:0]     slv_axi_rsp_o
);

  logic [5-1:0]         mem_req                 ;
  logic [5-1:0]         mem_write_en            ;
  logic [5-1:0][64-1:0] mem_addr                ;
  logic [5-1:0][64-1:0] mem_wdata               ;
  logic [5-1:0][64-1:0] mem_rdata               ;
  logic [5-1:0]         mem_rvalid              ;

  logic [5-1:0]         cluster_mem_req         ;
  logic [5-1:0]         cluster_mem_write_en    ;
  logic [5-1:0][12-1:0] cluster_mem_addr        ;
  logic [5-1:0][64-1:0] cluster_mem_wdata       ;
  logic [5-1:0][64-1:0] cluster_mem_rdata       ;
  logic [5-1:0]         cluster_mem_rvalid      ;

  logic [4-1:0][12-1:0] dma_length              ;
  logic [4-1:0][12-1:0] dma_src_offset          ;
  logic [4-1:0][12-1:0] dma_dst_offset          ;
  logic [4-1:0]         dma_run                 ;
  logic [4-1:0]         dma_ready               ;
  logic [4-1:0]         dma_busy                ;

  logic [4-1:0]          int_core_mem_req       ;
  logic [4-1:0]          int_core_mem_write_en  ;
  logic [4-1:0][64-1:0]  int_core_mem_addr      ;
  logic [4-1:0][64-1:0]  int_core_mem_wdata     ;
  logic [4-1:0][64-1:0]  int_core_mem_rdata     ;
  logic [4-1:0]          int_core_mem_rvalid    ;

  logic [4-1:0]          dma_mem_req            ;
  logic [4-1:0]          dma_mem_write_en       ;
  logic [4-1:0][64-1:0]  dma_mem_addr           ;
  logic [4-1:0][64-1:0]  dma_mem_wdata          ;
  logic [4-1:0][64-1:0]  dma_mem_rdata          ;
  logic [4-1:0]          dma_mem_rvalid         ;

  localparam              INT_CORE = 0, DMA = 1;
  logic [4-1:0]           mem_sel;  // 0: int core, 1: dma
  logic [4-1:0]           last_mem_sel_d, last_mem_sel_q;

  for (genvar i = 0; i < 4; i++) begin : gen_axi_convertion
    // ---------------------------------------------------
    // convert AXI4 slave interface to memory interface
    // ---------------------------------------------------
    axi_to_mem #(
      .axi_req_t    ( axi_req_t ),
      .axi_resp_t   ( axi_rsp_t ),
      .AddrWidth    ( 64 ),
      .DataWidth    ( 64 ),
      .IdWidth      ( 4  ),
      .NumBanks     ( 1  )
    ) axi_to_mem_int_inst (
      .clk_i        ( clk_i            ),
      .rst_ni       ( rstn_i           ),
      .busy_o       (                  ),
      .axi_req_i    ( slv_axi_req_i[i] ),
      .axi_resp_o   ( slv_axi_rsp_o[i] ),
      .mem_req_o    ( mem_req[i]       ),
      .mem_gnt_i    ( '1               ),
      .mem_addr_o   ( mem_addr[i]      ),
      .mem_wdata_o  ( mem_wdata[i]     ),
      .mem_we_o     ( mem_write_en[i]  ),
      .mem_rvalid_i ( mem_rvalid[i]    ),
      .mem_rdata_i  ( mem_rdata[i]     ),
      .mem_strb_o   (),
      .mem_atop_o   ()
    );

    // ---------------------------------------------------
    // arbit memory interface between INT Core and DMA
    // ---------------------------------------------------
    assign mem_sel[i]                = mem_addr[i][32-8-1:12];
    assign last_mem_sel_d[i]         = mem_req[i] ? mem_sel[i] : last_mem_sel_q[i];

    assign int_core_mem_write_en[i]  = mem_write_en[i];
    assign int_core_mem_addr[i]      = mem_addr[i];
    assign int_core_mem_wdata[i]     = mem_wdata[i];

    assign dma_mem_write_en[i]       = mem_write_en[i];
    assign dma_mem_addr[i]           = mem_addr[i];
    assign dma_mem_wdata[i]          = mem_wdata[i];

    // memory write data mux
    assign int_core_mem_req[i] = mem_req[i] & ~mem_sel[i];
    assign dma_mem_req[i]      = mem_req[i] &  mem_sel[i];

    // memory read data mux
    assign mem_rdata[i]  = (last_mem_sel_q[i] == INT_CORE) ? int_core_mem_rdata[i] : dma_mem_rdata[i];
    assign mem_rvalid[i] = (last_mem_sel_q[i] == INT_CORE) ? int_core_mem_rvalid[i] : dma_mem_rvalid[i];

    always_ff @(posedge clk_i or negedge rstn_i) begin
      if (!rstn_i) begin
        last_mem_sel_q[i] <= 1'b0;
      end
      else begin
        last_mem_sel_q[i] <= last_mem_sel_d[i];
      end
    end

    // ---------------------------------------------------
    // DMA instance
    // ---------------------------------------------------
    idma_top #(
      .AxiAddrWidth ( 64 ),
      .AxiDataWidth ( 64 ),
      .AxiIdWidth   ( 4  ),
      .AxiUserWidth ( 64 ),
      .axi_req_t    ( axi_req_t ),
      .axi_res_t    ( axi_rsp_t )
    ) idma_top_inst (
      .clk_i            ( clk_i            ),
      .rst_ni           ( rstn_i           ),
      .testmode_i       ( 1'b0             ),

      // AXI4 Master interface
      .axi_req_o        ( mst_axi_req_o[i]    ),
      .axi_res_i        ( mst_axi_rsp_i[i]    ),

      // Control register interface
      .axi_req_i        ( dma_mem_req[i]      ),
      .axi_write_en_i   ( dma_mem_write_en[i] ),
      .axi_addr_i       ( dma_mem_addr[i]     ),
      .axi_wdata_i      ( dma_mem_wdata[i]    ),
      .axi_rdata_o      ( dma_mem_rdata[i]    ),
      .axi_rvalid_o     ( dma_mem_rvalid[i]   ),

      // Direct interface to internal accelerator
      .dma_length_i     ( { 52'b0, dma_length[i]    } ),
      .dma_src_offset_i ( { 52'b0, dma_src_offset[i]} ),
      .dma_dst_offset_i ( { 52'b0, dma_dst_offset[i]} ),
      .dma_run_i        ( dma_run[i]          ),
      .dma_ready_o      ( dma_ready[i]        ),
      .dma_busy_o       ( dma_busy[i]         )
    );
  end

  // ---------------------------------------------------
  // convert AXI4 slave interface to memory interface
  // ---------------------------------------------------
  axi_to_mem #(
    .axi_req_t    ( axi_req_t ),
    .axi_resp_t   ( axi_rsp_t ),
    .AddrWidth    ( 64 ),
    .DataWidth    ( 64 ),
    .IdWidth      ( 4  ),
    .NumBanks     ( 1  )
  ) axi_to_mem_fp_inst (
    .clk_i        ( clk_i            ),
    .rst_ni       ( rstn_i           ),
    .busy_o       (                  ),
    .axi_req_i    ( slv_axi_req_i[4] ),
    .axi_resp_o   ( slv_axi_rsp_o[4] ),
    .mem_req_o    ( mem_req[4]       ),
    .mem_gnt_i    ( '1               ),
    .mem_addr_o   ( mem_addr[4]      ),
    .mem_wdata_o  ( mem_wdata[4]     ),
    .mem_we_o     ( mem_write_en[4]  ),
    .mem_rvalid_i ( mem_rvalid[4]    ),
    .mem_rdata_i  ( mem_rdata[4]     ),
    .mem_strb_o   (),
    .mem_atop_o   ()
  );

  // ---------------------------------------------------
  // INT-FP-Cluster instance
  // ---------------------------------------------------
  assign cluster_mem_req      = {mem_req[4], int_core_mem_req}            ;
  assign cluster_mem_write_en = {mem_write_en[4], int_core_mem_write_en}  ;
  assign cluster_mem_addr     = {mem_addr[4][12-1:0]                      ,
                                 int_core_mem_addr[3][12-1:0]             ,
                                 int_core_mem_addr[2][12-1:0]             ,
                                 int_core_mem_addr[1][12-1:0]             ,
                                 int_core_mem_addr[0][12-1:0]}            ;
  assign cluster_mem_wdata    = {mem_wdata[4], int_core_mem_wdata}        ;
  assign {mem_rvalid[4], int_core_mem_rvalid} = cluster_mem_rvalid        ;
  assign {mem_rdata[4], int_core_mem_rdata}   = cluster_mem_rdata         ;

  int_fp_cluster int_fp_cluster_inst (
    .clk_i             ( clk_i                ),
    .rstn_i            ( rstn_i               ),
    .clk_en_i          ( clk_en_i            ),

    .mem_req_i         ( cluster_mem_req      ),
    .mem_write_en_i    ( cluster_mem_write_en ),
    .mem_addr_i        ( cluster_mem_addr     ),
    .mem_wdata_i       ( cluster_mem_wdata    ),
    .mem_rdata_o       ( cluster_mem_rdata    ),
    .mem_rvalid_o      ( cluster_mem_rvalid   ),

    .dma_length_o      ( dma_length           ),
    .dma_src_offset_o  ( dma_src_offset       ),
    .dma_dst_offset_o  ( dma_dst_offset       ),
    .dma_run_o         ( dma_run              ),
    .dma_ready_i       ( dma_ready            ),
    .dma_busy_i        ( dma_busy             )
  );

endmodule
