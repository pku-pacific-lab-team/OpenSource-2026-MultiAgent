// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
//////////////////////////////////////////////////////////////////////////////////
// Description: Cluster Integrating 4 INT Cores and 1 FP Core
// Author:      Mingxuan Li <siris-lmx@stu.pku.edu.cn> [Peking University]
// Acknowledge: VSCode Copilot + Gemini-3-Pro Agent
//////////////////////////////////////////////////////////////////////////////////

module int_fp_cluster (
  input  logic                  clk_i             ,
  input  logic                  rstn_i            ,

  input  logic [5-1:0]          clk_en_i          ,
  input  logic [5-1:0]          mem_req_i         ,
  input  logic [5-1:0]          mem_write_en_i    ,
  input  logic [5*12-1:0]       mem_addr_i        ,
  input  logic [5*64-1:0]       mem_wdata_i       ,
  output logic [5*64-1:0]       mem_rdata_o       ,
  output logic [5-1:0]          mem_rvalid_o      ,

  output logic [4*12-1:0]       dma_length_o      ,
  output logic [4*12-1:0]       dma_src_offset_o  ,
  output logic [4*12-1:0]       dma_dst_offset_o  ,
  output logic [4-1:0]          dma_run_o         ,
  input  logic [4-1:0]          dma_ready_i       ,
  input  logic [4-1:0]          dma_busy_i
);

  logic [5-1:0][12-1:0]       mem_addr        ;
  logic [5-1:0][64-1:0]       mem_wdata       ;
  logic [5-1:0][64-1:0]       mem_rdata       ;
  logic [4-1:0][12-1:0]       dma_length      ;
  logic [4-1:0][12-1:0]       dma_src_offset  ;
  logic [4-1:0][12-1:0]       dma_dst_offset  ;

  assign mem_addr           = mem_addr_i      ;
  assign mem_wdata          = mem_wdata_i     ;
  assign mem_rdata_o        = mem_rdata       ;
  assign dma_length_o       = dma_length      ;
  assign dma_src_offset_o   = dma_src_offset  ;
  assign dma_dst_offset_o   = dma_dst_offset  ;

  logic [4-1:0] clk_int_core;
  logic         clk_fp_core;

  for (genvar i = 0; i < 4; i++) begin : gen_int_core
    tc_clk_gating tc_clk_gating_int_inst (
      .clk_i     ( clk_i           ),
      .en_i      ( clk_en_i[i]     ),
      .test_en_i ( 1'b0            ),
      .clk_o     ( clk_int_core[i] )
    );

    int_core int_core_inst (
      .clk_i            ( clk_int_core[i]   ),
      .rstn_i           ( rstn_i            ),

      .mem_req_i        ( mem_req_i[i]      ),
      .mem_write_en_i   ( mem_write_en_i[i] ),
      .mem_addr_i       ( mem_addr[i]       ),
      .mem_wdata_i      ( mem_wdata[i]      ),
      .mem_rdata_o      ( mem_rdata[i]      ),
      .mem_rvalid_o     ( mem_rvalid_o[i]   ),
      .dma_length_o     ( dma_length[i]     ),
      .dma_src_offset_o ( dma_src_offset[i] ),
      .dma_dst_offset_o ( dma_dst_offset[i] ),
      .dma_run_o        ( dma_run_o[i]      ),
      .dma_ready_i      ( dma_ready_i[i]    ),
      .dma_busy_i       ( dma_busy_i[i]     )
    );
  end

  tc_clk_gating tc_clk_gating_fp_inst (
    .clk_i     ( clk_i         ),
    .en_i      ( clk_en_i[4]   ),
    .test_en_i ( 1'b0          ),
    .clk_o     ( clk_fp_core   )
  );

  fp_core fp_core_inst (
    .clk_i     ( clk_fp_core       ),
    .rstn_i    ( rstn_i            ),

    .req_i     ( mem_req_i[4]      ),
    .we_i      ( mem_write_en_i[4] ),
    .addr_i    ( mem_addr[4]       ),
    .wdata_i   ( mem_wdata[4]      ),
    .rdata_o   ( mem_rdata[4]      ),
    .rvalid_o  ( mem_rvalid_o[4]   )
  );

endmodule
