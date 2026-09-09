// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
// Authors:
// - Renati Tuerhong  <renati0423@gmail.com>
// Modified by Mingxuan Li <siris-lmx@stu.pku.edu.cn> [Peking University]

/// Description: Register-based front-end for iDMA
module idma_frontend #(
  /// DMA 1d or ND burst request type
  parameter int unsigned AxiDataWidth    = 32'd0,
  parameter int unsigned AxiAddrWidth    = 32'd0,
  parameter int unsigned AxiUserWidth    = 32'd0,
  parameter int unsigned AxiIdWidth      = 32'd0,
  parameter type         dma_req_t      = logic
) (
  input  logic                      clk_i             ,
  input  logic                      rst_ni            ,
  /// Direct interface to internal accelerator
  input  logic [AxiAddrWidth-1:0]   dma_length_i      ,
  input  logic [AxiAddrWidth-1:0]   dma_src_offset_i  ,
  input  logic [AxiAddrWidth-1:0]   dma_dst_offset_i  ,
  input  logic                      dma_run_i         ,
  output logic                      dma_ready_o       ,
  /// Register interface control slave
  // Control register interface
  input  logic                      axi_req_i         ,
  input  logic                      axi_write_en_i    ,
  input  logic [AxiAddrWidth-1:0]   axi_addr_i        ,
  input  logic [AxiDataWidth-1:0]   axi_wdata_i       ,
  output logic [AxiDataWidth-1:0]   axi_rdata_o       ,
  output logic                      axi_rvalid_o      ,
  /// Request signals
  output dma_req_t                  dma_req_o         ,
  output logic                      req_valid_o       ,
  input  logic                      req_ready_i
);

  localparam logic [2-1:0] CSR_DMA_LENGTH    = 2'h0;
  localparam logic [2-1:0] CSR_DMA_SRC_ADDR  = 2'h1;
  localparam logic [2-1:0] CSR_DMA_DST_ADDR  = 2'h2;
  localparam logic [2-1:0] CSR_DMA_CONTRL    = 2'h3;

  logic [AxiAddrWidth-1:0]    csr_length    ;
  logic [AxiAddrWidth-1:0]    csr_src_addr  ;
  logic [AxiAddrWidth-1:0]    csr_dst_addr  ;
  logic                       csr_en        ;

  ///////////////////////////////////////
  // posedge edge detector for dma_run_i
  ///////////////////////////////////////
  logic dma_run_reg;
  logic posedge_dma_run;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      dma_run_reg <= 1'b0;
    end
    else begin
      dma_run_reg <= dma_run_i;
    end
  end
  assign posedge_dma_run = dma_run_i & ~dma_run_reg;

  ///////////////////////////////////////
  // memory-mapped register read & write
  // direct link to accelerator
  ///////////////////////////////////////
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      csr_length         <= '0;
      csr_src_addr       <= '0;
      csr_dst_addr       <= '0;
      csr_en             <= '0;
      axi_rdata_o        <= '0;
      axi_rvalid_o       <= '0;
    end
    else begin
      // set default value
      axi_rdata_o     <= 64'hCA11AB1EBADCAB1E;
      axi_rvalid_o    <= axi_req_i;
      csr_length      <= dma_length_i;
      csr_src_addr    <= {csr_src_addr[AxiAddrWidth-12-1:12], dma_src_offset_i[12-1:0]};
      csr_dst_addr    <= {csr_dst_addr[AxiAddrWidth-12-1:12], dma_dst_offset_i[12-1:0]};
      csr_en          <= posedge_dma_run;

      // write operation
      if (axi_req_i & axi_write_en_i) begin
        case (axi_addr_i[4:3])
          CSR_DMA_LENGTH: begin
              csr_length    <= axi_wdata_i;
          end
          CSR_DMA_SRC_ADDR: begin
              csr_src_addr  <= axi_wdata_i;
          end
          CSR_DMA_DST_ADDR: begin
              csr_dst_addr  <= axi_wdata_i;
          end
          CSR_DMA_CONTRL: begin
              csr_en        <= axi_wdata_i[0];
          end
          default:begin end
        endcase
      end

      // read operation
      else if (axi_req_i & !axi_write_en_i) begin
        case (axi_addr_i[4:3])
          CSR_DMA_LENGTH: begin
              axi_rdata_o      <= csr_length;
          end
          CSR_DMA_SRC_ADDR: begin
              axi_rdata_o      <= csr_src_addr;
          end
          CSR_DMA_DST_ADDR: begin
              axi_rdata_o      <= csr_dst_addr;
          end
          CSR_DMA_CONTRL: begin
              axi_rdata_o      <= req_ready_i;
          end
        endcase
      end
    end
  end
  assign dma_ready_o = req_ready_i;

  ///////////////////////////////////////
  // assign request struct
  ///////////////////////////////////////

  always_comb begin : proc_hw_req_conv
    // all fields are zero per default
    dma_req_o = '0;
    // address and length
    req_valid_o = csr_en;
    dma_req_o.length   = csr_length;
    dma_req_o.src_addr = csr_src_addr;
    dma_req_o.dst_addr = csr_dst_addr;
    // Protocols
    dma_req_o.opt.src_protocol = idma_pkg::AXI;  //AXI
    dma_req_o.opt.dst_protocol = idma_pkg::AXI;  //AXI
    // Current backend only supports incremental burst
    dma_req_o.opt.src.burst = axi_pkg::BURST_INCR;
    dma_req_o.opt.dst.burst = axi_pkg::BURST_INCR;
    // this frontend currently does not support cache variations
    dma_req_o.opt.src.cache = axi_pkg::CACHE_MODIFIABLE;
    dma_req_o.opt.dst.cache = axi_pkg::CACHE_MODIFIABLE;
    // Backend options
    dma_req_o.opt.beo.decouple_aw    = 1'b0;
    dma_req_o.opt.beo.decouple_rw    = 1'b0;
    dma_req_o.opt.beo.src_max_llen   = 8'd255;
    dma_req_o.opt.beo.dst_max_llen   = 8'd255;
    dma_req_o.opt.beo.src_reduce_len = 1'b0;
    dma_req_o.opt.beo.dst_reduce_len = 1'b0;
  end
endmodule
