// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
//////////////////////////////////////////////////////////////////////////////////
// Description: Testbench for xor_adder
// Author:      Mingxuan Li <siris-lmx@stu.pku.edu.cn>
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module xor_adder_tb;
  // Parameters consistent with the RTL
  localparam int unsigned NUM_INPUT = 32;
  localparam int unsigned HDC_DIM     = 2048;

  // Clock and reset
  logic clk;
  logic rstn;
  logic en;

  // DUT interface
  logic [NUM_INPUT-1:0] input_a;
  logic [NUM_INPUT-1:0] input_b;
  logic [$clog2(HDC_DIM)-1:0] output_sum;

  // 100MHz clock
  initial clk = 1'b0;
  always #5 clk = ~clk;

  // DUT
  xor_adder #(
      .NUM_INPUT (NUM_INPUT),
      .HDC_DIM     (HDC_DIM)
  ) dut (
      .clk_i     (clk),
      .rstn_i    (rstn),
      .en_i      (en),
      .input_a_i (input_a),
      .input_b_i (input_b),
      .output_o  (output_sum)
  );

  // Software reference: computes the increment exactly following the RTL level-by-level XOR tree
  function automatic logic [$clog2(HDC_DIM)-1:0] calc_increment(
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
    en      = 1'b0;
    input_a = '0;
    input_b = '0;
    rstn    = 1'b0;
    repeat (2) @(posedge clk);
    rstn = 1'b1;
    @(posedge clk);
  endtask

  // Single test scenario: verifies accumulation and clearing
  task automatic run_case(
      input logic [NUM_INPUT-1:0] a0,
      input logic [NUM_INPUT-1:0] b0,
      input logic [NUM_INPUT-1:0] a1,
      input logic [NUM_INPUT-1:0] b1,
      string tag);
    logic [$clog2(HDC_DIM)-1:0] inc0, inc1;
    inc0 = calc_increment(a0, b0);
    inc1 = calc_increment(a1, b1);

    $display("[XOR_ADDER_TB] %s start, inc0=%0d inc1=%0d", tag, inc0, inc1);

    // First set of inputs, accumulate for two cycles
    input_a = a0;
    input_b = b0;
    en      = 1'b1;
    @(posedge clk);
    assert (output_sum == inc0)
      else $fatal(1, "[XOR_ADDER_TB] %s step1 exp=%0d got=%0d", tag, inc0, output_sum);
    @(posedge clk);
    assert (output_sum == inc0 + inc0)
      else $fatal(1, "[XOR_ADDER_TB] %s step2 exp=%0d got=%0d", tag, inc0 + inc0, output_sum);

    // Second set of inputs, continue accumulating for two cycles
    input_a = a1;
    input_b = b1;
    @(posedge clk);
    assert (output_sum == inc0*2 + inc1)
      else $fatal(1, "[XOR_ADDER_TB] %s step3 exp=%0d got=%0d", tag, inc0*2 + inc1, output_sum);
    @(posedge clk);
    assert (output_sum == inc0*2 + inc1*2)
      else $fatal(1, "[XOR_ADDER_TB] %s step4 exp=%0d got=%0d", tag, inc0*2 + inc1*2, output_sum);

    // Reset again to make sure it is cleared
    rstn = 1'b0;
    @(posedge clk);
    rstn = 1'b1;
    @(posedge clk);
    assert (output_sum == '0)
      else $fatal(1, "[XOR_ADDER_TB] %s reset exp=0 got=%0d", tag, output_sum);

    $display("[XOR_ADDER_TB] %s passed.", tag);
  endtask

  initial begin
    do_reset();

    // case0: identical inputs (all 1s)
    run_case(32'hFFFF_FFFF, 32'hFFFF_FFFF,
             32'hAAAA_AAAA, 32'hAAAA_AAAA,
             "case0_same_inputs");

    do_reset();

    // case1: completely opposite inputs (all 0s vs all 1s)
    run_case(32'h0000_0000, 32'hFFFF_FFFF,
             32'h1234_5678, 32'hEDCB_A987,
             "case1_opposite_and_mixed");

    $display("[XOR_ADDER_TB] all cases done.");
    #20;
    $finish;
  end
endmodule


