// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
//////////////////////////////////////////////////////////////////////////////////
// Description: Processing Element (PE) Module
// Author:      Mingxuan Li <siris-lmx@stu.pku.edu.cn> [Peking University]
// Acknowledge: VSCode Copilot + GPT-5 Agent
//////////////////////////////////////////////////////////////////////////////////

module pe #(
	parameter DATA_WIDTH    = 4,
	parameter MAX_ACCUM_NUM = 32,

	// derived parameters, DO NOT MODIFY!!!
	parameter ACCUM_WIDTH   = $clog2(MAX_ACCUM_NUM) + DATA_WIDTH * 2
) (
	input   logic                       clk_i           ,
	input   logic                       rstn_i          ,
	input   logic                       in_valid_i      ,
	input   logic                       initial_i       ,
	input   logic [ DATA_WIDTH-1:0]     activation_i    ,
	input   logic [ DATA_WIDTH-1:0]     weight_i        ,
	output  logic [ACCUM_WIDTH-1:0]     result_o
);

	// Tips about `signed` keyword and `$signed` system function:
	// 1. `signed` keyword determines the explanation of a variable on the left side of an assignment,
	//    while `$signed` function casts the expression on the right side to signed type.
	// 2. The signedness of the signal on the left-hand side of an assignment statement does not play
	//    any role in determining the signedness of the operation on the right-hand side of the assignment.
	// 3. If one of the operands in an expression on the right side is signed,
	//    the entire expression is treated as signed.
	// 4. Signedness of operands affects operations like sign extension.

	logic [ACCUM_WIDTH-1:0] partial_sum;
	logic [ACCUM_WIDTH-1:0] result_d, result_q;

	assign partial_sum = $signed(activation_i) * $signed(weight_i);
	assign result_o    = result_q;

	always_comb begin
		result_d = result_q;

		if (in_valid_i) begin
			if (initial_i) begin
				result_d = partial_sum;
			end else begin
				result_d = $signed(partial_sum) + $signed(result_q);
			end
		end
	end

	always_ff @(posedge clk_i or negedge rstn_i) begin
		if (!rstn_i) begin
			result_q <= '0;
		end else begin
			result_q <= result_d;
		end
	end

endmodule
