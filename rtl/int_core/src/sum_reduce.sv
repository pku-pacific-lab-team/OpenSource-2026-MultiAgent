// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
//////////////////////////////////////////////////////////////////////////////////
// Description: Sum Reduce Module for SF Array
// Author:      Mingxuan Li <siris-lmx@stu.pku.edu.cn> [Peking University]
// Acknowledge: VSCode Copilot + Gemini-3-Pro Agent
//////////////////////////////////////////////////////////////////////////////////

module sum_reduce #(
  parameter IN_WIDTH      = 12                                ,
  parameter ARRAY_SIZE    = 8                                 ,

	// derived parameters, DO NOT MODIFY!!!
  parameter HIDDEN_WIDTH  = IN_WIDTH     + $clog2(ARRAY_SIZE) ,
  parameter OUT_WIDTH     = HIDDEN_WIDTH + $clog2(ARRAY_SIZE)
) (
  input   logic                                                 clk_i           ,
  input   logic                                                 rstn_i          ,
  input   logic                                                 reduce_valid_i  ,
  input   logic [ARRAY_SIZE-1:0][ARRAY_SIZE-1:0][IN_WIDTH-1:0]  array_i         ,
  output  logic [OUT_WIDTH-1:0]                                 sum_o           ,
  output  logic                                                 sum_valid_o
);

  logic                                                 posedge_reduce_valid;
  enum logic [1:0] { IDLE, STAGE1, STAGE2, FINISH }     state_d,        state_q;
  logic                                                 reduce_valid_d, reduce_valid_q;
  logic [ARRAY_SIZE-1:0][ARRAY_SIZE-1:0][IN_WIDTH-1:0]  stage0_psum_d,  stage0_psum_q;
  logic [ARRAY_SIZE-1:0][HIDDEN_WIDTH-1:0]              stage1_psum_d,  stage1_psum_q;
  logic [OUT_WIDTH-1:0]                                 stage2_psum_d,  stage2_psum_q;
  assign posedge_reduce_valid = reduce_valid_d & ~reduce_valid_q;

  // state machine for sum reduce stages
  always_comb begin
    state_d        = state_q;
    reduce_valid_d = reduce_valid_i;

    case (state_q)
      IDLE: begin
        if (posedge_reduce_valid) begin
          state_d = STAGE1;
        end
      end
      STAGE1: begin
        state_d   = STAGE2;
      end
      STAGE2: begin
        state_d   = FINISH;
      end
      FINISH: begin
        if (posedge_reduce_valid) begin
          state_d = STAGE1;
        end
      end
      default: ;  // do nothing
    endcase
  end

  // stage 0 (idle | finish): array registering
  always_comb begin
    stage0_psum_d = stage0_psum_q;

    if (posedge_reduce_valid) begin
      for (int i = 0; i < ARRAY_SIZE; i++) begin
        stage0_psum_d[i] = array_i[i];
      end
    end
  end

  // stage 1: 8 * 8-to-1 adder tree
  generate
    for (genvar i = 0; i < ARRAY_SIZE; i++) begin : stage0
      adder_tree #(
        .INPUTS_NUM   ( ARRAY_SIZE       ),
        .IDATA_WIDTH  ( IN_WIDTH         )
      ) stage1_adder_tree_inst (
        .data_i       ( stage0_psum_q[i] ),
        .data_o       ( stage1_psum_d[i] )
      );
    end
  endgenerate

  // stage 2: 1 * 8-to-1 adder tree
  adder_tree #(
    .INPUTS_NUM   ( ARRAY_SIZE    ),
    .IDATA_WIDTH  ( HIDDEN_WIDTH  )
  ) stage2_adder_tree_inst (
    .data_i       ( stage1_psum_q ),
    .data_o       ( stage2_psum_d )
  );

  // stage 3: finish sum reduce
  assign sum_o       = stage2_psum_q;
  assign sum_valid_o = (state_q == FINISH) & (~posedge_reduce_valid);

  // register update
  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (!rstn_i) begin
      state_q         <= IDLE;
      reduce_valid_q  <= '0;
      stage0_psum_q   <= '0;
      stage1_psum_q   <= '0;
      stage2_psum_q   <= '0;
    end else begin
      state_q         <= state_d;
      reduce_valid_q  <= reduce_valid_d;
      stage0_psum_q   <= stage0_psum_d;
      stage1_psum_q   <= stage1_psum_d;
      stage2_psum_q   <= stage2_psum_d;
    end
  end

endmodule
