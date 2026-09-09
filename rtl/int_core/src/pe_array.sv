// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
//////////////////////////////////////////////////////////////////////////////////
// Description: PE Array Module
// Author:      Mingxuan Li <siris-lmx@stu.pku.edu.cn> [Peking University]
// Acknowledge: VSCode Copilot + GPT-5 Agent
//////////////////////////////////////////////////////////////////////////////////

module pe_array #(
	parameter DATA_WIDTH    = 4                                       ,
	parameter MAX_ACCUM_NUM = 32                                      ,
	parameter ARRAY_SIZE    = 8                                       ,

	// derived parameters, DO NOT MODIFY!!!
	parameter ACCUM_WIDTH   = $clog2(MAX_ACCUM_NUM) + DATA_WIDTH * 2  ,
	parameter ADDR_WIDTH    = $clog2(ARRAY_SIZE)
) (
	input   logic                                   clk_i             ,
	input   logic                                   rstn_i            ,

	// compute interface
	input   logic                                  	in_valid_i        ,
	input   logic                                  	initial_i        	,
	input   logic [ARRAY_SIZE-1:0][ DATA_WIDTH-1:0]	activation_line_i	,
	input   logic [ARRAY_SIZE-1:0][ DATA_WIDTH-1:0]	weight_line_i     ,
	output  logic [$clog2(MAX_ACCUM_NUM)-1:0]				accum_cnt_o       ,

	// direct register access
	output  logic [ARRAY_SIZE-1:0][ARRAY_SIZE-1:0][16-1:0] result_matrix_aligned_o
);

	logic [ARRAY_SIZE-1:0][ARRAY_SIZE-1:0][ACCUM_WIDTH-1:0]	result_matrix;
	logic [$clog2(MAX_ACCUM_NUM)-1:0]                       accum_cnt_d, accum_cnt_q;

	// PE array initialization
	for (genvar i = 0; i < ARRAY_SIZE; i++) begin : row
		for (genvar j = 0; j < ARRAY_SIZE; j++) begin : col
			pe #(
				.DATA_WIDTH     ( DATA_WIDTH           ),
				.MAX_ACCUM_NUM  ( MAX_ACCUM_NUM        )
			) pe_inst (
				.clk_i          ( clk_i                ),
				.rstn_i         ( rstn_i               ),
				.in_valid_i     ( in_valid_i           ),
				.initial_i      ( initial_i            ),
				.activation_i   ( activation_line_i[i] ),
				.weight_i       ( weight_line_i[j]     ),
				.result_o       ( result_matrix[i][j]  )
			);
		end
	end

	// result accumulation count & finish
	always_comb begin
		accum_cnt_d = accum_cnt_q;

		if (in_valid_i) begin
			if (initial_i) begin
				accum_cnt_d = 1'b1;
			end else begin
				accum_cnt_d = accum_cnt_q + 1'b1;
			end
		end
	end
	assign accum_cnt_o = accum_cnt_q;

  // result alignment to 16-bit
  always_comb begin
    for (int i = 0; i < ARRAY_SIZE; i++) begin
      for (int j = 0; j < ARRAY_SIZE; j++) begin
        result_matrix_aligned_o[i][j] = $signed(result_matrix[i][j]);
      end
    end
  end

	// register update
	always_ff @(posedge clk_i or negedge rstn_i) begin
		if (!rstn_i) begin
			accum_cnt_q     <= '0;
		end else begin
			accum_cnt_q     <= accum_cnt_d;
		end
	end

endmodule
