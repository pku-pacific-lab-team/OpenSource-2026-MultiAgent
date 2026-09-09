// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
//////////////////////////////////////////////////////////////////////////////////
// Designer:        Qinzhe Zhi, Zhantong Zhu, Yifan Ding, Mingxuan Li
// Acknowledgement: Cursor + Claude
// Description:     Main memory consisted of multiple SRAM macros
//////////////////////////////////////////////////////////////////////////////////

module main_mem_wrapper #(
  parameter int AXI_ADDR_WIDTH    = 64,
  parameter int AXI_DATA_WIDTH    = 64,
  parameter int AXI_ADDR_OFFSET   = 3,
  parameter int NUM_MACROS        = 16,   // 128KB total memory
  parameter int MACRO_ADDR_WIDTH  = 10,   // 8KB per macro
  parameter int CS_WIDTH          = $clog2(NUM_MACROS)
) (
  input  logic                                clk_i,
  input  logic                                rstn_i,

  // axi2mem interface
  input  logic                                    axi_req_i,
  input  logic                                    axi_write_en_i,
  input  logic [  AXI_ADDR_WIDTH-1:0]    			axi_addr_i,
  input  logic [AXI_DATA_WIDTH/8-1:0]             axi_byte_en_i,
  input  logic [  AXI_DATA_WIDTH-1:0]             axi_wdata_i,
  output logic [  AXI_DATA_WIDTH-1:0]             axi_rdata_o
);

  // Internal signals
  logic [AXI_DATA_WIDTH-1:0]                 		main_mem_wdata  ;
  logic [NUM_MACROS-1:0]                          main_mem_en     ;
  logic [NUM_MACROS-1:0]                          main_mem_wen    ;
  logic [MACRO_ADDR_WIDTH-1:0]                    main_mem_addr   ;
  logic [AXI_DATA_WIDTH/8-1:0][8-1:0]      		bit_mask        ;
  logic [AXI_DATA_WIDTH/8-1:0]               		byte_mask       ;

  // SRAM read signal
  logic [NUM_MACROS-1:0][AXI_DATA_WIDTH-1:0]      main_mem_rdata;
  logic                                           axi_rdata_valid_q, axi_rdata_valid_d;
  logic                                           axi_req_q, axi_req_d;
  logic [CS_WIDTH-1:0]                            axi_cs_d, axi_cs_q;

  // buf
  always_comb begin
    axi_req_d               = 1'b0;
    axi_cs_d                = axi_cs_q;
    if (axi_req_i) begin
      axi_req_d           = 1'b1;
      axi_cs_d            = axi_addr_i[AXI_ADDR_OFFSET+CS_WIDTH+MACRO_ADDR_WIDTH-1 -: CS_WIDTH];
    end
  end

  always_ff@(posedge clk_i or negedge rstn_i) begin
    if (~rstn_i) begin
      axi_cs_q            <= '0;
      axi_req_q           <= 1'b0;
      axi_rdata_valid_q   <= 1'b0;
    end else begin
      axi_cs_q            <= axi_cs_d;
      axi_req_q           <= axi_req_d;
      axi_rdata_valid_q   <= axi_rdata_valid_d;
    end
  end

  assign axi_rdata_o = main_mem_rdata[axi_cs_q];

  //axi_req_i -> main_mem_en
  always_comb begin: generate_en
    main_mem_en                                                                         = '0;
    if(axi_req_i) begin
      main_mem_en                                                                       = '0;
      main_mem_en[axi_addr_i[AXI_ADDR_OFFSET+CS_WIDTH+MACRO_ADDR_WIDTH-1 -: CS_WIDTH]]  = 1'b1;
    end
  end

  //axi_write_en_i -> main_mem_wen
  always_comb begin: generate_wen
    main_mem_wen                                                                        = '0;
    if(axi_req_i) begin
      main_mem_wen                                                                      = '0;
      main_mem_wen[axi_addr_i[AXI_ADDR_OFFSET+CS_WIDTH+MACRO_ADDR_WIDTH-1 -: CS_WIDTH]] = axi_write_en_i;
    end
  end

  //axi_addr_i -> main_mem_addr
  always_comb begin: generate_addr
    main_mem_addr = '0;
    if(axi_req_i) begin
      main_mem_addr = axi_addr_i[AXI_ADDR_OFFSET+MACRO_ADDR_WIDTH-1 -: MACRO_ADDR_WIDTH];
    end
  end

  // axi_wdata_i -> main_mem_wdata
  always_comb begin: generate_wdata
    main_mem_wdata  = '0;
    if(axi_req_i) begin
      // main_mem_wdata[axi_addr_i[AXI_ADDR_OFFSET]] = axi_wdata_i;
      main_mem_wdata = axi_wdata_i;
    end
  end

  assign byte_mask = axi_byte_en_i;
  //byte_mask -> bit_mask
  always_comb begin : generate_bit_mask
    for(int i = 0; i < AXI_DATA_WIDTH/8; i++) begin
      bit_mask[i] = {8{byte_mask[i]}};
    end
  end

  // Generate SRAM
  genvar i;
  generate
    for (i = 0; i < NUM_MACROS; i++) begin : gen_main_mem
      sram_be_1024x64 main_mem_inst(
        .clk_i          ( clk_i             ),
        .chip_enable_i  ( main_mem_en[i]    ),
        .write_enable_i ( main_mem_wen[i]   ),
        .addr_i         ( main_mem_addr     ),
        .write_data_i   ( main_mem_wdata    ),
        .bit_enable_i   ( bit_mask          ),
        .read_data_o    ( main_mem_rdata[i] )
      );
    end
  endgenerate

endmodule
