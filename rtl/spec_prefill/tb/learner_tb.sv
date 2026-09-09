// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
//////////////////////////////////////////////////////////////////////////////////
// Description: Testbench for learner
// Author:      Mingxuan Li <siris-lmx@stu.pku.edu.cn>
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module learner_tb;
  localparam int unsigned NUM_INPUT     = 32;
  localparam int unsigned WEIGHT_WIDTH  = 6;
  localparam int unsigned WEIGHT_VEC_W  = NUM_INPUT * WEIGHT_WIDTH;

  logic en;
  logic reward;
  logic [NUM_INPUT-1:0] hdc_input;
  logic [WEIGHT_VEC_W-1:0] weight_input;
  logic [WEIGHT_VEC_W-1:0] updated_weight;

  // DUT: purely combinational, no clock or reset
  learner #(
      .NUM_INPUT    (NUM_INPUT),
      .WEIGHT_WIDTH (WEIGHT_WIDTH)
  ) dut (
      .en_i           (en),
      .reward_i       (reward),
      .hdc_input_i    (hdc_input),
      .weight_input_i (weight_input),
      .updated_weight (updated_weight)
  );

  // Reference model: computed exactly following the RTL logic
  function automatic logic [WEIGHT_VEC_W-1:0] ref_comb(
      input logic [NUM_INPUT-1:0] hdc_in,
      input logic [WEIGHT_VEC_W-1:0] weight_in,
      input logic en_in,
      input logic reward_in);
    logic [WEIGHT_VEC_W-1:0] nxt;
    logic signed [1:0] reward_val, rewardn_val;
    logic signed [1:0] feedback;
    logic signed [WEIGHT_WIDTH:0] tmp_sum;
    logic eq_bit;
    begin
      if (!en_in) begin
        nxt = '0;
      end else begin
        // reward = reward_i ? 1 : -1
        reward_val  = reward_in ? 2'sd1 : -2'sd1;  // +1 or -1
        // rewardn = reward_i ? -1 : 1
        rewardn_val = reward_in ? -2'sd1 : 2'sd1;  // -1 or +1
        for (int i = 0; i < NUM_INPUT; i++) begin
          // Compare hdc_input_i[i] with the weight MSB
          eq_bit = (hdc_in[i] == weight_in[i*WEIGHT_WIDTH + WEIGHT_WIDTH - 1]);
          // feedback = eq ? reward : rewardn
          feedback = eq_bit ? reward_val : rewardn_val;
          // weight_out = weight_in + feedback (signed addition, truncated to 6 bits)
          tmp_sum = $signed(weight_in[i*WEIGHT_WIDTH +: WEIGHT_WIDTH]) + feedback;
          nxt[i*WEIGHT_WIDTH +: WEIGHT_WIDTH] = tmp_sum[WEIGHT_WIDTH-1:0];
        end
      end
      ref_comb = nxt;
    end
  endfunction

  // Apply inputs and check outputs
  task automatic apply_and_check(
      input logic [NUM_INPUT-1:0] hdc,
      input logic [WEIGHT_VEC_W-1:0] win,
      input logic en_in,
      input logic reward_in,
      string tag);
    logic [WEIGHT_VEC_W-1:0] expect_next;
    hdc_input    = hdc;
    weight_input = win;
    en           = en_in;
    reward       = reward_in;
    #1; // Wait for combinational logic to settle
    expect_next  = ref_comb(hdc, win, en_in, reward_in);
    assert (updated_weight == expect_next)
      else $fatal(1, "[LEARN_TB] %s mismatch exp=%0h got=%0h", tag, expect_next, updated_weight);
    $display("[LEARN_TB] %s passed. en=%0b reward=%0b hdc[0]=%b weight0_msb=%b weight0=%0h out0=%0h",
             tag, en_in, reward_in, hdc[0], win[WEIGHT_WIDTH-1], win[WEIGHT_WIDTH-1:0], updated_weight[WEIGHT_WIDTH-1:0]);
  endtask

  initial begin
    // Initialization
    en           = 1'b0;
    reward       = 1'b0;
    hdc_input    = '0;
    weight_input = '0;
    #1;

    $display("[LEARN_TB] Starting test cases...");

    // case0: en=0, output should be cleared to zero
    apply_and_check('0, {WEIGHT_VEC_W{1'b0}}, 1'b0, 1'b0, "case0_en0_clear");

    // case1: reward=1, hdc[i]=0, weight MSB=0 -> equal -> use reward(+1) -> increment
    apply_and_check('0, {32{6'h08}}, 1'b1, 1'b1, "case1_reward1_eq_inc");

    // case2: reward=1, hdc[i]=1, weight MSB=0 -> not equal -> use rewardn(-1) -> decrement
    apply_and_check({NUM_INPUT{1'b1}}, {32{6'h20}}, 1'b1, 1'b1, "case2_reward1_neq_dec");

    // case3: reward=0, hdc[i]=0, weight MSB=0 -> equal -> use reward(-1) -> decrement
    apply_and_check('0, {32{6'h08}}, 1'b1, 1'b0, "case3_reward0_eq_dec");

    // case4: reward=0, hdc[i]=1, weight MSB=0 -> not equal -> use rewardn(+1) -> increment
    apply_and_check({NUM_INPUT{1'b1}}, {32{6'h20}}, 1'b1, 1'b0, "case4_reward0_neq_inc");

    // case5: reward=1, weight MSB=1, hdc=1 -> equal -> use reward(+1) -> increment
    apply_and_check({NUM_INPUT{1'b1}}, {32{6'h3F}}, 1'b1, 1'b1, "case5_reward1_eq_msb1_inc");

    // case6: reward=1, weight MSB=1, hdc=0 -> not equal -> use rewardn(-1) -> decrement
    apply_and_check('0, {32{6'h3F}}, 1'b1, 1'b1, "case6_reward1_neq_msb1_dec");

    // case7: mixed inputs, different elements may increment or decrement
    apply_and_check(32'hA5A5_1234, {32{6'h15}}, 1'b1, 1'b1, "case7_mixed_reward1");

    // case8: boundary test: weight is 0, becomes 1 after increment
    apply_and_check('0, {WEIGHT_VEC_W{1'b0}}, 1'b1, 1'b1, "case8_zero_weight_inc");

    // case9: boundary test: weight is the maximum value (63), wraps around to 0 after increment
    apply_and_check('0, {32{6'h3F}}, 1'b1, 1'b1, "case9_max_weight_wrap");

    // case10: boundary test: weight is 1, becomes 0 after decrement
    apply_and_check({NUM_INPUT{1'b1}}, {32{6'h01}}, 1'b1, 1'b1, "case10_min_weight_dec");

    // case11: boundary test: weight is 0, wraps around to 63 after decrement
    apply_and_check({NUM_INPUT{1'b1}}, {WEIGHT_VEC_W{1'b0}}, 1'b1, 1'b1, "case11_zero_weight_dec_wrap");

    $display("[LEARN_TB] all cases done.");
    #10;
    $finish;
  end

endmodule
