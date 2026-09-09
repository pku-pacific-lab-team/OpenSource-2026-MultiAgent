// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
//////////////////////////////////////////////////////////////////////////////////
// Description: Testbench for predictor
// Author:      Mingxuan Li <siris-lmx@stu.pku.edu.cn>
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module predictor_tb;
  // Reduce HDC_DIM to 1024 so that NUM_ACCU=32, making it easy to verify 32 accumulations
  localparam int unsigned HDC_DIM     = 2048;
  localparam int unsigned NUM_INPUT = 32;
  localparam int unsigned NUM_ACCU    = HDC_DIM / NUM_INPUT;
  localparam int unsigned OUT_WIDTH   = $clog2(HDC_DIM);
  localparam int unsigned BIAS = 1024;

  logic clk;
  logic rstn;
  logic en;
  logic [NUM_INPUT-1:0] hdc_input;
  logic [NUM_INPUT-1:0] weight_input;
  logic finish;
  logic [OUT_WIDTH-1:0] results;
  // Prepare different inputs for the 32 accumulations
  logic [NUM_ACCU-1:0][NUM_INPUT-1:0] hdc_seq;
  logic [NUM_ACCU-1:0][NUM_INPUT-1:0] weight_seq;

  // 100MHz clock
  initial clk = 1'b0;
  always #5 clk = ~clk;

  predictor #(
      .HDC_DIM     (HDC_DIM),
      .NUM_INPUT (NUM_INPUT),
      .BIAS       (BIAS)
  ) dut (
      .clk_i         (clk),
      .rstn_i        (rstn),
      .en_i          (en),
      .hdc_input_i   (hdc_input),
      .weight_input_i(weight_input),
      .finish_o      (finish),
      .results_o     (results)
  );

  // Increment computation matching the RTL (reuses the xor_adder structure)
  function automatic logic [OUT_WIDTH-1:0] calc_increment(
      input logic [NUM_INPUT-1:0] a, input logic [NUM_INPUT-1:0] b);
    logic [NUM_INPUT-1:0] add_input;
    logic [NUM_INPUT/2-1:0][1:0] stage0;
    logic [NUM_INPUT/4-1:0][2:0] stage1;
    logic [NUM_INPUT/8-1:0][3:0] stage2;
    logic [NUM_INPUT/16-1:0][4:0] stage3;
    logic [NUM_INPUT/32-1:0][5:0] stage4;
    int i;
    begin
      for (i = 0; i < NUM_INPUT; i++) begin
        add_input[i] = ~(a[i] ^ b[i]);
      end
      for (i = 0; i < NUM_INPUT/2; i++) begin
        stage0[i] = add_input[2*i] + add_input[2*i+1];
      end
      for (i = 0; i < NUM_INPUT/4; i++) begin
        stage1[i] = stage0[2*i] + stage0[2*i+1];
      end
      for (i = 0; i < NUM_INPUT/8; i++) begin
        stage2[i] = stage1[2*i] + stage1[2*i+1];
      end
      for (i = 0; i < NUM_INPUT/16; i++) begin
        stage3[i] = stage2[2*i] + stage2[2*i+1];
      end
      for (i = 0; i < NUM_INPUT/32; i++) begin
        stage4[i] = stage3[2*i] + stage3[2*i+1];
      end
      calc_increment = {'0, stage4};
    end
  endfunction

  // Reset
  task automatic do_reset();
    en           = 1'b0;
    hdc_input    = '0;
    weight_input = '0;
    rstn         = 1'b0;
    repeat (1) @(posedge clk);
    rstn = 1'b1;
    @(posedge clk);
  endtask

  // Reference model: compute the final results based on the RTL timing
  // Note: in the FINISH state the RTL directly outputs adder_output_o - 1024 (combinational, OUT_WIDTH+1 bits wide, then truncated to the low OUT_WIDTH bits)
  function automatic logic [OUT_WIDTH-1:0] ref_result_seq(
      input logic [NUM_ACCU-1:0][NUM_INPUT-1:0] a_seq,
      input logic [NUM_ACCU-1:0][NUM_INPUT-1:0] b_seq);
    logic [OUT_WIDTH:0] sum; // OUT_WIDTH+1 bits, matching {1'b0, adder_output_o}
    logic [OUT_WIDTH-1:0] inc;
    begin
      sum = 0;
      // Accumulate NUM_ACCU times (corresponding to the predictor's NUM_ACCU accumulations)
      for (int idx = 0; idx < NUM_ACCU; idx++) begin
        inc = calc_increment(a_seq[idx], b_seq[idx]);
        sum = sum + inc;
        $display("[REF] step=%0d inc=%0d sum_after=%0d", idx, inc, sum);
      end
      // FINISH state: results_o = low OUT_WIDTH bits of (adder_output_o - 1024)
      sum = sum - 1024;
      $display("[REF] final_after_minus_1024_trunc=%0d", sum[OUT_WIDTH-1:0]);
      ref_result_seq = sum[OUT_WIDTH-1:0];
    end
  endfunction

  // Generate 32 sets of inputs (deterministic pseudo-random) for reuse across multiple cases
  task automatic gen_sequence(
      input logic [NUM_INPUT-1:0] seed_a,
      input logic [NUM_INPUT-1:0] seed_b);
    for (int i = 0; i < NUM_ACCU; i++) begin
      hdc_seq[i]    = seed_a ^ (i * 32'h9E37_79B9) + (i << 4);
      weight_seq[i] = seed_b + i * 32'h7F4A_7C15;
    end
  endtask

  // Drive the 32 sets of inputs and compare the result when finish=1
  task automatic run_sequence(string tag);
    logic [OUT_WIDTH-1:0] expect_res;
    int unsigned cycle;

    expect_res = ref_result_seq(hdc_seq, weight_seq);
    $display("[PRED_TB] %s expect=%0d", tag, expect_res);

    // Timing requirement: the first input is fed only in the cycle after en is asserted
    // Cycle T0 negedge: only assert en, inputs stay 0
    @(negedge clk);
    en           = 1'b1;
    hdc_input    = '0;
    weight_input = '0;
    // Cycle T1 negedge: feed the first input, en still 1 (IDLE -> GEN_PRED_SUM)
    @(negedge clk);
    hdc_input    = hdc_seq[0];
    weight_input = weight_seq[0];
    // From cycle T2 negedge on, feed the remaining inputs and deassert en
    @(negedge clk);
    en = 1'b0;
    for (int idx = 1; idx < NUM_ACCU; idx++) begin
      hdc_input    = hdc_seq[idx];
      weight_input = weight_seq[idx];
      @(negedge clk);
    end

    // Wait for finish=1 (sampled synchronously on the rising edge of clk)
    // finish is asserted on the rising edge that enters the FINISH state; results_o is produced combinationally in the same cycle
    cycle = 0;
    forever begin
      @(posedge clk);
      cycle++;
      if (finish) begin
        if (results == expect_res) begin
          $display("[PRED_TB] %s passed at cycle %0d, result=%0d", tag, cycle, results);
        end else begin
          $fatal(1, "[PRED_TB] %s mismatch exp=%0d got=%0d", tag, expect_res, results);
        end
        break;
      end
      if (cycle > (NUM_ACCU + 10)) begin
        $fatal(1, "[PRED_TB] %s timeout waiting finish", tag);
      end
    end
    repeat (2) @(posedge clk);
  endtask

  initial begin
    do_reset();

    // case0: original pattern
    gen_sequence(32'h1357_0001, 32'h89AB_CDEF);
    run_sequence("seq0_base");

    // case1: inverted seeds
    gen_sequence(32'hFFFF_0000, 32'h0000_FFFF);
    run_sequence("seq1_inverted_seeds");


    // case2: seeds with low-bit changes
    gen_sequence(32'h0000_00F0, 32'h0000_0F0F);
    run_sequence("seq2_lowbit_variation");

    // case3: fully random seeds (fixed values to ensure reproducibility)
    gen_sequence(32'hDEAD_BEEF, 32'hC0DE_2024);
    run_sequence("seq3_randomish");

    $display("[PRED_TB] all cases done.");
    #50;
    $finish;
  end

endmodule

