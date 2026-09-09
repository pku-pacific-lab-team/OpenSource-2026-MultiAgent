// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
//////////////////////////////////////////////////////////////////////////////////
// Description:     SRAM wrappers of the die. The taped-out design instantiates
//                  foundry SRAM and register-file macros with bit-write masks
//                  behind these wrappers; this release maps every wrapper onto
//                  the generic behavioural `tc_sram` model (misc_common/) with
//                  a one-bit byte width so that the bit-enable semantics of the
//                  macros are preserved. All wrappers are single-port with a
//                  one-cycle read latency, matching the macros they replace.
//                  Memory contents are uninitialised after reset (X in
//                  simulation), as on silicon.
// Author:          Mingxuan Li
// Date:            2026-09 (behavioural release version)
//////////////////////////////////////////////////////////////////////////////////

// Common wrapper body: active-high chip enable, write enable and per-bit
// write enable; read data valid one cycle after a read request.
module sram_be_generic #(
  parameter int unsigned NumWords  = 1024,
  parameter int unsigned DataWidth = 64,
  parameter int unsigned AddrWidth = (NumWords > 1) ? $clog2(NumWords) : 1
) (
  input  wire                  clk_i,
  input  wire                  chip_enable_i,
  input  wire                  write_enable_i,
  input  wire [AddrWidth-1:0]  addr_i,
  input  wire [DataWidth-1:0]  write_data_i,
  input  wire [DataWidth-1:0]  bit_enable_i,
  output wire [DataWidth-1:0]  read_data_o
);

  tc_sram #(
    .NumWords  ( NumWords  ),
    .DataWidth ( DataWidth ),
    .ByteWidth ( 1         ),
    .NumPorts  ( 1         ),
    .Latency   ( 1         ),
    .SimInit   ( "none"    )
  ) i_tc_sram (
    .clk_i   ( clk_i          ),
    .rst_ni  ( 1'b1           ),
    .req_i   ( chip_enable_i  ),
    .we_i    ( write_enable_i ),
    .addr_i  ( addr_i         ),
    .wdata_i ( write_data_i   ),
    .be_i    ( bit_enable_i   ),
    .rdata_o ( read_data_o    )
  );

endmodule

// 1024 x 64 SRAM (LLC data way, main memory model)
module sram_be_1024x64 (
  input  wire         clk_i           ,
  input  wire         chip_enable_i   ,
  input  wire         write_enable_i  ,
  input  wire [9:0]   addr_i          ,
  input  wire [63:0]  write_data_i    ,
  input  wire [63:0]  bit_enable_i    ,
  output wire [63:0]  read_data_o
);
  sram_be_generic #(.NumWords(1024), .DataWidth(64)) i_mem (.*);
endmodule

// 352 x 192 SRAM (speculative-prefill weight scratchpad)
module sram_be_352x192 (
  input  wire         clk_i           ,
  input  wire         chip_enable_i   ,
  input  wire         write_enable_i  ,
  input  wire [8:0]   addr_i          ,
  input  wire [191:0] write_data_i    ,
  input  wire [191:0] bit_enable_i    ,
  output wire [191:0] read_data_o
);
  sram_be_generic #(.NumWords(352), .DataWidth(192)) i_mem (.*);
endmodule

// 128 x 46 register file (cache tag arrays)
module rf_be_128x46 (
  input  wire         clk_i           ,
  input  wire         chip_enable_i   ,
  input  wire         write_enable_i  ,
  input  wire [6:0]   addr_i          ,
  input  wire [45:0]  write_data_i    ,
  input  wire [45:0]  bit_enable_i    ,
  output wire [45:0]  read_data_o
);
  sram_be_generic #(.NumWords(128), .DataWidth(46)) i_mem (.*);
endmodule

// 128 x 128 register file (cache data arrays)
module rf_be_128x128 (
  input  wire         clk_i           ,
  input  wire         chip_enable_i   ,
  input  wire         write_enable_i  ,
  input  wire [6:0]   addr_i          ,
  input  wire [127:0] write_data_i    ,
  input  wire [127:0] bit_enable_i    ,
  output wire [127:0] read_data_o
);
  sram_be_generic #(.NumWords(128), .DataWidth(128)) i_mem (.*);
endmodule

// 256 x 64 register file (LLC tag store)
module rf_be_256x64 (
  input  wire         clk_i           ,
  input  wire         chip_enable_i   ,
  input  wire         write_enable_i  ,
  input  wire [7:0]   addr_i          ,
  input  wire [63:0]  write_data_i    ,
  input  wire [63:0]  bit_enable_i    ,
  output wire [63:0]  read_data_o
);
  sram_be_generic #(.NumWords(256), .DataWidth(64)) i_mem (.*);
endmodule
