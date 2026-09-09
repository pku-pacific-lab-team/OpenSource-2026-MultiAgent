// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
//////////////////////////////////////////////////////////////////////////////////
// Description: Scaling Factor (SF) Compute Module
// Author:      Mingxuan Li <siris-lmx@stu.pku.edu.cn> [Peking University]
// Acknowledge: VSCode Copilot + Gemini-3-Pro Agent
//////////////////////////////////////////////////////////////////////////////////

module sf #(
	parameter DATA_WIDTH    = 8                             ,
	parameter SF_WIDTH      = 6                             ,
	parameter BUCKET_WIDTH  = 12
) (
	input   logic                       clk_i               ,
	input   logic                       rstn_i              ,
	input   logic                       sf_valid_i          ,
	input   logic                       spattn_valid_i      ,
	input   logic                       spattn_initial_i    ,
	input   logic [DATA_WIDTH-1:0]      scaling_factor0_i   ,
	input   logic [DATA_WIDTH-1:0]      scaling_factor1_i   ,
	input   logic                       sign0_i             ,
	input   logic                       sign1_i             ,
	output  logic [DATA_WIDTH-1:0]      exponent_o          ,
	output  logic [BUCKET_WIDTH-1:0]    bucket_3b000_o      ,
	output  logic [BUCKET_WIDTH-1:0]    bucket_3b001_o      ,
	output  logic [BUCKET_WIDTH-1:0]    bucket_3b110_o      ,
	output  logic [BUCKET_WIDTH-1:0]    bucket_3b111_o
);

	logic [SF_WIDTH-1:0]      signed_sf;
	logic [DATA_WIDTH-1:0]    exponent_d, exponent_q;
	logic                     sign_bit_d, sign_bit_q;
	logic [BUCKET_WIDTH-1:0]  bucket_3b000_d, bucket_3b000_q;
	logic [BUCKET_WIDTH-1:0]  bucket_3b001_d, bucket_3b001_q;
	logic [BUCKET_WIDTH-1:0]  bucket_3b110_d, bucket_3b110_q;
	logic [BUCKET_WIDTH-1:0]  bucket_3b111_d, bucket_3b111_q;

	// scaling factor computation and get sign bit
	always_comb begin
		exponent_d      = exponent_q;
		sign_bit_d      = sign_bit_q;

		if (sf_valid_i) begin
			exponent_d  = scaling_factor0_i + scaling_factor1_i;
			sign_bit_d  = sign0_i ^ sign1_i;
		end
	end
	assign exponent_o   = exponent_q;
	assign signed_sf    = {sign_bit_q, exponent_q[SF_WIDTH-2:0]};

	// bucketize signed scaling factor (signed_sf) according to higher 3 bits
	// data distribution indicates [MSB-1:MSB-3] == 3'b000 | 3'b001 | 3'b110 | 3'b111 occurs most frequently
	// [MSB] indicates whether to add or subtract from the bucket accumulated value
	always_comb begin
		bucket_3b000_d = bucket_3b000_q;
		bucket_3b001_d = bucket_3b001_q;
		bucket_3b110_d = bucket_3b110_q;
		bucket_3b111_d = bucket_3b111_q;

		if (spattn_valid_i) begin
      if (spattn_initial_i) begin
        bucket_3b000_d = '0;
        bucket_3b001_d = '0;
        bucket_3b110_d = '0;
        bucket_3b111_d = '0;

        case (signed_sf[SF_WIDTH-2:SF_WIDTH-4])
          3'b000: begin
            if (signed_sf[SF_WIDTH-1]) begin
              bucket_3b000_d = 0 - (1 << signed_sf[SF_WIDTH-5:0]);
            end else begin
              bucket_3b000_d = 0 + (1 << signed_sf[SF_WIDTH-5:0]);
            end
          end
          3'b001: begin
            if (signed_sf[SF_WIDTH-1]) begin
              bucket_3b001_d = 0 - (1 << signed_sf[SF_WIDTH-5:0]);
            end else begin
              bucket_3b001_d = 0 + (1 << signed_sf[SF_WIDTH-5:0]);
            end
          end
          3'b110: begin
            if (signed_sf[SF_WIDTH-1]) begin
              bucket_3b110_d = 0 - (1 << signed_sf[SF_WIDTH-5:0]);
            end else begin
              bucket_3b110_d = 0 + (1 << signed_sf[SF_WIDTH-5:0]);
            end
          end
          3'b111: begin
            if (signed_sf[SF_WIDTH-1]) begin
              bucket_3b111_d = 0 - (1 << signed_sf[SF_WIDTH-5:0]);
            end else begin
              bucket_3b111_d = 0 + (1 << signed_sf[SF_WIDTH-5:0]);
            end
          end
          default: ;  // do nothing for other patterns
        endcase
      end else begin
        case (signed_sf[SF_WIDTH-2:SF_WIDTH-4])
          3'b000: begin
            if (signed_sf[SF_WIDTH-1]) begin
              bucket_3b000_d = bucket_3b000_q - (1 << signed_sf[SF_WIDTH-5:0]);
            end else begin
              bucket_3b000_d = bucket_3b000_q + (1 << signed_sf[SF_WIDTH-5:0]);
            end
          end
          3'b001: begin
            if (signed_sf[SF_WIDTH-1]) begin
              bucket_3b001_d = bucket_3b001_q - (1 << signed_sf[SF_WIDTH-5:0]);
            end else begin
              bucket_3b001_d = bucket_3b001_q + (1 << signed_sf[SF_WIDTH-5:0]);
            end
          end
          3'b110: begin
            if (signed_sf[SF_WIDTH-1]) begin
              bucket_3b110_d = bucket_3b110_q - (1 << signed_sf[SF_WIDTH-5:0]);
            end else begin
              bucket_3b110_d = bucket_3b110_q + (1 << signed_sf[SF_WIDTH-5:0]);
            end
          end
          3'b111: begin
            if (signed_sf[SF_WIDTH-1]) begin
              bucket_3b111_d = bucket_3b111_q - (1 << signed_sf[SF_WIDTH-5:0]);
            end else begin
              bucket_3b111_d = bucket_3b111_q + (1 << signed_sf[SF_WIDTH-5:0]);
            end
          end
          default: ;  // do nothing for other patterns
        endcase
      end
		end
	end
	assign bucket_3b000_o = bucket_3b000_q;
  assign bucket_3b001_o = bucket_3b001_q;
  assign bucket_3b110_o = bucket_3b110_q;
  assign bucket_3b111_o = bucket_3b111_q;

	// register update
	always_ff @(posedge clk_i or negedge rstn_i) begin
		if (!rstn_i) begin
			exponent_q      <= '0               ;
			sign_bit_q      <= '0               ;
			bucket_3b000_q  <= '0               ;
			bucket_3b001_q  <= '0               ;
			bucket_3b110_q  <= '0               ;
			bucket_3b111_q  <= '0               ;
		end else begin
			exponent_q      <= exponent_d       ;
			sign_bit_q      <= sign_bit_d       ;
			bucket_3b000_q  <= bucket_3b000_d   ;
			bucket_3b001_q  <= bucket_3b001_d   ;
			bucket_3b110_q  <= bucket_3b110_d   ;
			bucket_3b111_q  <= bucket_3b111_d   ;
		end
	end

endmodule
