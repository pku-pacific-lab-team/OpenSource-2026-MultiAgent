// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
//////////////////////////////////////////////////////////////////////////////////
// Description: SF Array Module
// Author:      Mingxuan Li <siris-lmx@stu.pku.edu.cn> [Peking University]
// Acknowledge: VSCode Copilot + Gemini-3-Pro Agent
//////////////////////////////////////////////////////////////////////////////////

module sf_array #(
  parameter DATA_WIDTH        = 8                                       ,
  parameter SF_WIDTH          = 6                                       ,
  parameter BUCKET_WIDTH      = 12                                      ,
  parameter ARRAY_SIZE        = 8                                       ,
  parameter SPATTN_CNT_MAX    = 128                                     ,

  // derived parameter, DO NOT MODIFY!!!
  parameter ACCUM_WIDTH       = BUCKET_WIDTH + 2 * $clog2(ARRAY_SIZE)   ,
  parameter ADDR_WIDTH        = $clog2(ARRAY_SIZE)                      ,
  parameter SPATTN_CNT_WIDTH  = $clog2(SPATTN_CNT_MAX)
) (
  input   logic                                   clk_i                 ,
  input   logic                                   rstn_i                ,

  // scaling factor compute interface
  input   logic                                   sf_valid_i            ,
  input   logic [ARRAY_SIZE-1:0][DATA_WIDTH-1:0]  sf_line0_i            ,
  input   logic [ARRAY_SIZE-1:0][DATA_WIDTH-1:0]  sf_line1_i            ,
  input   logic [ARRAY_SIZE-1:0]                  sign_line0_i          ,
  input   logic [ARRAY_SIZE-1:0]                  sign_line1_i          ,

  // sparse attention bucketize interface
  input   logic                                   spattn_valid_i        ,
  input   logic                                   spattn_initial_i      ,
  output  logic [4-1:0][32-1:0]                   sum_bucket_aligned_o  ,
  output  logic                                   sum_valid_o           ,

  // direct register access
  output  logic [ARRAY_SIZE-1:0][ARRAY_SIZE-1:0][DATA_WIDTH-1:0] exponent_matrix_o
);

  logic [ARRAY_SIZE-1:0][ARRAY_SIZE-1:0][BUCKET_WIDTH-1:0]  bucket_3b000_matrix;
  logic [ARRAY_SIZE-1:0][ARRAY_SIZE-1:0][BUCKET_WIDTH-1:0]  bucket_3b001_matrix;
  logic [ARRAY_SIZE-1:0][ARRAY_SIZE-1:0][BUCKET_WIDTH-1:0]  bucket_3b110_matrix;
  logic [ARRAY_SIZE-1:0][ARRAY_SIZE-1:0][BUCKET_WIDTH-1:0]  bucket_3b111_matrix;
  logic [ACCUM_WIDTH-1:0]                 sum_bucket_3b000;
  logic [ACCUM_WIDTH-1:0]                 sum_bucket_3b001;
  logic [ACCUM_WIDTH-1:0]                 sum_bucket_3b110;
  logic [ACCUM_WIDTH-1:0]                 sum_bucket_3b111;
  logic [SPATTN_CNT_WIDTH:0]              spattn_cnt_d,    spattn_cnt_q;
  logic                                   bucket_valid;
  logic                                   sum_bucket_3b000_valid;
  logic                                   sum_bucket_3b001_valid;
  logic                                   sum_bucket_3b110_valid;
  logic                                   sum_bucket_3b111_valid;

  // SF array initialization
	for (genvar i = 0; i < ARRAY_SIZE; i++) begin : row
		for (genvar j = 0; j < ARRAY_SIZE; j++) begin : col
			sf #(
				.DATA_WIDTH         ( DATA_WIDTH                ),
				.SF_WIDTH           ( SF_WIDTH                  ),
        .BUCKET_WIDTH       ( BUCKET_WIDTH              )
      ) sf_inst (
				.clk_i              ( clk_i                     ),
				.rstn_i             ( rstn_i                    ),
				.sf_valid_i         ( sf_valid_i                ),
        .spattn_valid_i     ( spattn_valid_i            ),
				.spattn_initial_i   ( spattn_initial_i          ),
        .scaling_factor0_i  ( sf_line0_i[i]             ),
        .scaling_factor1_i  ( sf_line1_i[j]             ),
        .sign0_i            ( sign_line0_i[i]           ),
        .sign1_i            ( sign_line1_i[j]           ),
        .exponent_o         ( exponent_matrix_o[i][j]   ),
        .bucket_3b000_o     ( bucket_3b000_matrix[i][j] ),
        .bucket_3b001_o     ( bucket_3b001_matrix[i][j] ),
        .bucket_3b110_o     ( bucket_3b110_matrix[i][j] ),
        .bucket_3b111_o     ( bucket_3b111_matrix[i][j] )
      );
		end
	end

  // sparse attention operation count & finish
  always_comb begin
    spattn_cnt_d = spattn_cnt_q;

    if (spattn_valid_i) begin
      if (spattn_initial_i) begin
        spattn_cnt_d = 1'b1;
      end else begin
        spattn_cnt_d = spattn_cnt_q + 1'b1;
      end
    end
  end
  assign bucket_valid = (spattn_cnt_q == SPATTN_CNT_MAX);

  // bucket sum output
  sum_reduce #(
    .IN_WIDTH       ( BUCKET_WIDTH           ),
    .ARRAY_SIZE     ( ARRAY_SIZE             )
  ) sum_bucket_3b000_inst (
    .clk_i          ( clk_i                  ),
    .rstn_i         ( rstn_i                 ),
    .reduce_valid_i ( bucket_valid           ),
    .array_i        ( bucket_3b000_matrix    ),
    .sum_o          ( sum_bucket_3b000       ),
    .sum_valid_o    ( sum_bucket_3b000_valid )
  );

  sum_reduce #(
    .IN_WIDTH       ( BUCKET_WIDTH           ),
    .ARRAY_SIZE     ( ARRAY_SIZE             )
  ) sum_bucket_3b001_inst (
    .clk_i          ( clk_i                  ),
    .rstn_i         ( rstn_i                 ),
    .reduce_valid_i ( bucket_valid           ),
    .array_i        ( bucket_3b001_matrix    ),
    .sum_o          ( sum_bucket_3b001       ),
    .sum_valid_o    ( sum_bucket_3b001_valid )
  );

  sum_reduce #(
    .IN_WIDTH       ( BUCKET_WIDTH           ),
    .ARRAY_SIZE     ( ARRAY_SIZE             )
  ) sum_bucket_3b110_inst (
    .clk_i          ( clk_i                  ),
    .rstn_i         ( rstn_i                 ),
    .reduce_valid_i ( bucket_valid           ),
    .array_i        ( bucket_3b110_matrix    ),
    .sum_o          ( sum_bucket_3b110       ),
    .sum_valid_o    ( sum_bucket_3b110_valid )
  );

  sum_reduce #(
    .IN_WIDTH       ( BUCKET_WIDTH           ),
    .ARRAY_SIZE     ( ARRAY_SIZE             )
  ) sum_bucket_3b111_inst (
    .clk_i          ( clk_i                  ),
    .rstn_i         ( rstn_i                 ),
    .reduce_valid_i ( bucket_valid           ),
    .array_i        ( bucket_3b111_matrix    ),
    .sum_o          ( sum_bucket_3b111       ),
    .sum_valid_o    ( sum_bucket_3b111_valid )
  );

  assign sum_bucket_aligned_o[0]  = $signed(sum_bucket_3b000);
  assign sum_bucket_aligned_o[1]  = $signed(sum_bucket_3b001);
  assign sum_bucket_aligned_o[2]  = $signed(sum_bucket_3b110);
  assign sum_bucket_aligned_o[3]  = $signed(sum_bucket_3b111);
  assign sum_valid_o              = bucket_valid
                                  & sum_bucket_3b000_valid
                                  & sum_bucket_3b001_valid
                                  & sum_bucket_3b110_valid
                                  & sum_bucket_3b111_valid;

  // register update
  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (!rstn_i) begin
      spattn_cnt_q <= '0;
    end else begin
      spattn_cnt_q <= spattn_cnt_d;
    end
  end

endmodule
