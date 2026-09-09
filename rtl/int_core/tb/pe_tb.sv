// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
//////////////////////////////////////////////////////////////////////////////////
// Description: Testbench for PE module
// Author:      Mingxuan Li <siris-lmx@stu.pku.edu.cn> [Peking University]
// Acknowledge: VSCode Copilot + GPT-5 Agent
//////////////////////////////////////////////////////////////////////////////////

// pramga translate_off
`timescale 1ns/1ps

// Function: covers reset, initialization, accumulation, sign combinations, bit-width boundaries, in_valid gaps, random regression

module pe_tb;

  // Adjustable parameters
  localparam DATA_WIDTH    = 4;
  localparam MAX_ACCUM_NUM = 32;
  localparam ACCUM_WIDTH   = $clog2(MAX_ACCUM_NUM) + DATA_WIDTH * 2;

  // DUT port signals
  logic                       clk_i;
  logic                       rstn_i;
  logic                       in_valid_i;
  logic                       initial_i;
  logic [DATA_WIDTH-1:0]      activation_i;
  logic [DATA_WIDTH-1:0]      weight_i;
  logic [ACCUM_WIDTH-1:0]     result_o;

  // Reference model and monitoring
  logic signed [ACCUM_WIDTH-1:0] ref_result;
  logic signed [DATA_WIDTH-1:0]  act_s;
  logic signed [DATA_WIDTH-1:0]  wgt_s;
  logic signed [ACCUM_WIDTH-1:0] prod_s;
  int pass_cnt = 0;
  int fail_cnt = 0;
  int rand_num = 30;
  int seed     = 32'h1;

  // Color macros (if the simulator supports ANSI)
  string GREEN = "\033[32m";
  string RED   = "\033[31m";
  string YEL   = "\033[33m";
  string CYAN  = "\033[36m";
  string RESET = "\033[0m";

  // Clock generation
  initial begin
    clk_i = 0;
    forever #5 clk_i = ~clk_i; // 100MHz
  end

  // Reference model update
  always_comb begin
    act_s  = activation_i;
    wgt_s  = weight_i;
    prod_s = $signed(act_s) * $signed(wgt_s); // Signed multiplication
  end

  // DUT instantiation
  pe #(.DATA_WIDTH(DATA_WIDTH), .MAX_ACCUM_NUM(MAX_ACCUM_NUM)) u_pe (
    .clk_i(clk_i), .rstn_i(rstn_i), .in_valid_i(in_valid_i), .initial_i(initial_i),
    .activation_i(activation_i), .weight_i(weight_i), .result_o(result_o)
  );

  // Reference model sequential behavior
  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (!rstn_i) begin
      ref_result <= '0;
    end else if (in_valid_i) begin
      if (initial_i) begin
        ref_result <= prod_s;
      end else begin
        ref_result <= $signed(ref_result) + $signed(prod_s);
      end
    end
  end

  // Compare task
  task check_output(string tag);
    #1; // signal transmission delay
    if (result_o !== ref_result) begin
      fail_cnt++;
      $display("%s[FAIL]%s %s result_o=%0d ref=%0d", RED, RESET, tag, $signed(result_o), $signed(ref_result));
    end else begin
      pass_cnt++;
      $display("%s[PASS]%s %s result_o=%0d", GREEN, RESET, tag, $signed(result_o));
    end
  endtask

  // Drive a single-cycle transaction
  task automatic drive(input logic vld, input logic init, input integer act, input integer wgt);
    #1; // signal transmission delay
    in_valid_i   = vld;
    initial_i    = init;
    activation_i = act[DATA_WIDTH-1:0];
    weight_i     = wgt[DATA_WIDTH-1:0];
  endtask

  // Insert gap cycles
  task automatic idle_cycle(int cycles); begin
    repeat(cycles) begin
      drive(0,0,0,0);
      @(posedge clk_i); check_output("idle_hold");
    end
  end endtask

  // Test case: reset
  task automatic test_reset();
    $display("%s[CASE]%s RESET", CYAN, RESET);
    rstn_i = 0;
    drive(0,0,0,0);
    @(posedge clk_i);
    if (result_o !== '0) $display("%s[FAIL]%s reset not zero result=%0d", RED, RESET, result_o);
    else $display("%s[PASS]%s reset zero", GREEN, RESET);
    rstn_i = 1;
    @(posedge clk_i); check_output("after_reset_release");
  endtask

  // Test case: initialization overwrite
  task automatic test_initial();
    $display("%s[CASE]%s INITIAL", CYAN, RESET);
    drive(1,1, 2, 3); @(posedge clk_i); check_output("init_2x3");
    drive(1,1, -3, 2); @(posedge clk_i); check_output("init_-3x2_override");
  endtask

  // Test case: accumulation sequence
  task automatic test_accumulate();
    $display("%s[CASE]%s ACCUMULATE", CYAN, RESET);
    // start
    drive(1,1, 1, 1); @(posedge clk_i); check_output("acc_start");
    drive(1,0, 2, 1); @(posedge clk_i); check_output("acc_add_2");
    drive(1,0, -1, 2); @(posedge clk_i); check_output("acc_add_-2");
    drive(1,0, -2, -3); @(posedge clk_i); check_output("acc_add_6");
  endtask

  // Test case: sign combinations
  task automatic test_signs();
    $display("%s[CASE]%s SIGNS", CYAN, RESET);
    drive(1,1,  3,  3); @(posedge clk_i); check_output("pos_pos");
    drive(1,1, -3,  3); @(posedge clk_i); check_output("neg_pos");
    drive(1,1,  3, -3); @(posedge clk_i); check_output("pos_neg");
    drive(1,1, -3, -3); @(posedge clk_i); check_output("neg_neg");
    drive(1,1,  0,  3); @(posedge clk_i); check_output("zero_pos");
    drive(1,1,  3,  0); @(posedge clk_i); check_output("pos_zero");
  endtask

  // Test case: bit-width boundaries (max/min)
  task automatic test_extremes();
    int maxv =  (1 << (DATA_WIDTH-1)) - 1;
    int minv = -(1 << (DATA_WIDTH-1));
    $display("%s[CASE]%s EXTREMES", CYAN, RESET);
    drive(1,1, maxv, maxv); @(posedge clk_i); check_output("max*max");
    drive(1,1, minv, minv); @(posedge clk_i); check_output("min*min");
    drive(1,1, maxv, minv); @(posedge clk_i); check_output("max*min");
  endtask

  // Test case: hold across in_valid gaps
  task automatic test_idle_gaps();
    $display("%s[CASE]%s IDLE_GAPS", CYAN, RESET);
    drive(1,1, 2,2); @(posedge clk_i); check_output("gap_start");
    idle_cycle(3);
    drive(1,0, 1,1); @(posedge clk_i); check_output("gap_acc");
  endtask

  // Test case: continuous accumulation depth (<=MAX_ACCUM_NUM)
  task automatic test_depth();
    $display("%s[CASE]%s DEPTH", CYAN, RESET);
    drive(1,1, 1,1); @(posedge clk_i); check_output("depth_start");
    for (int i=1; i<MAX_ACCUM_NUM; i++) begin
      drive(1,0, 1,1); @(posedge clk_i); check_output($sformatf("depth_step_%0d", i));
    end
  endtask

  // Test case: random regression
  task automatic test_random(int num);
    $display("%s[CASE]%s RANDOM num=%0d", YEL, RESET, num);
    for (int i=0; i<num; i++) begin
      logic init = (i==0) || ($urandom_range(0,7)==0); // Occasionally restart the sequence
      logic vld  = ($urandom_range(0,3)!=0); // 75% valid
      int act = $urandom_range(-(1<<(DATA_WIDTH-1)), (1<<(DATA_WIDTH-1))-1);
      int wgt = $urandom_range(-(1<<(DATA_WIDTH-1)), (1<<(DATA_WIDTH-1))-1);
      drive(vld, init, act, wgt);
      @(posedge clk_i); check_output($sformatf("rand_%0d", i));
    end
  endtask

  // Main process
  initial begin
    // +NOCOLOR=1 disables color, +SEED=<n> sets the random seed, +RAND_NUM=<n> sets the number of random test cases
    int noc; if ($value$plusargs("NOCOLOR=%d", noc) && (noc!=0)) begin
      GREEN=""; RED=""; YEL=""; CYAN=""; RESET="";
    end
    if ($value$plusargs("SEED=%d", seed)) begin end
    if ($value$plusargs("RAND_NUM=%d", rand_num)) begin end
    void'($urandom(seed));

    $display("%s[START]%s PE Testbench SEED=%0d RAND_NUM=%0d", CYAN, RESET, seed, rand_num);
    // Initial values
    rstn_i = 0; in_valid_i = 0; initial_i = 0; activation_i='0; weight_i='0;

    // Reset and settle
    repeat(2) @(posedge clk_i);
    test_reset();

    repeat(10) @(posedge clk_i);
    test_initial();
    repeat(10) @(posedge clk_i);
    test_accumulate();
    repeat(10) @(posedge clk_i);
    test_signs();
    repeat(10) @(posedge clk_i);
    test_extremes();
    repeat(10) @(posedge clk_i);
    test_idle_gaps();
    repeat(10) @(posedge clk_i);
    test_depth();
    repeat(10) @(posedge clk_i);
    test_random(rand_num);

    @(posedge clk_i);
    $display("%s[SUMMARY]%s PASS=%0d FAIL=%0d", (fail_cnt==0)?GREEN:YEL, RESET, pass_cnt, fail_cnt);
    $display("%s[DONE]%s all tests completed", (fail_cnt==0)?GREEN:RED, RESET);
    #20;
    $finish;
  end

  initial begin
    $fsdbDumpfile("waveform.fsdb");
    $fsdbDumpvars("+all");
    $fsdbDumpMDA();
    $display("FSDB dump started.");
  end

endmodule
// pragma translate_on
