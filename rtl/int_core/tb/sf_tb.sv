// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
//////////////////////////////////////////////////////////////////////////////////
// Description: Testbench for SF (Scaling Factor) module
// Author:      Mingxuan Li <siris-lmx@stu.pku.edu.cn> [Peking University]
// Acknowledge: VSCode Copilot + Gemini-3-Pro Agent
//////////////////////////////////////////////////////////////////////////////////

// pragma translate_off
`timescale 1ns/1ps

// Function: covers reset, SF computation, bucket accumulation (initialize/accumulate), sign-bit handling, bucket selection logic, random regression
// Note: this testbench does not use a parallel reference model; expected values are computed directly in the test flow and compared

module sf_tb;

  // Adjustable parameters
  localparam DATA_WIDTH    = 8;
  localparam SF_WIDTH      = 6;
  localparam BUCKET_WIDTH   = 12;

  // DUT port signals
  logic                       clk_i;
  logic                       rstn_i;
  logic                       sf_valid_i;
  logic                       spattn_valid_i;
  logic                       spattn_initial_i;
  logic [DATA_WIDTH-1:0]      scaling_factor0_i;
  logic [DATA_WIDTH-1:0]      scaling_factor1_i;
  logic                       sign0_i;
  logic                       sign1_i;
  logic [DATA_WIDTH-1:0]      exponent_o;
  logic [BUCKET_WIDTH-1:0]    bucket_3b000_o;
  logic [BUCKET_WIDTH-1:0]    bucket_3b001_o;
  logic [BUCKET_WIDTH-1:0]    bucket_3b110_o;
  logic [BUCKET_WIDTH-1:0]    bucket_3b111_o;

  // Expected values (Expected State)
  logic [DATA_WIDTH-1:0]      exp_exponent;
  logic [BUCKET_WIDTH-1:0]    exp_bucket_3b000;
  logic [BUCKET_WIDTH-1:0]    exp_bucket_3b001;
  logic [BUCKET_WIDTH-1:0]    exp_bucket_3b110;
  logic [BUCKET_WIDTH-1:0]    exp_bucket_3b111;

  // Internal state tracking (used to compute expected values)
  logic [DATA_WIDTH-1:0]      last_exponent;
  logic                       last_sign_bit;

  int pass_cnt = 0;
  int fail_cnt = 0;
  int rand_num = 50;

  // Color macros
  string GREEN = "\033[32m";
  string RED   = "\033[31m";
  string RESET = "\033[0m";

  // Clock generation
  initial begin
    clk_i = 0;
    forever #5 clk_i = ~clk_i; // 100MHz
  end

  // DUT instantiation
  sf #(
    .DATA_WIDTH(DATA_WIDTH),
    .SF_WIDTH(SF_WIDTH),
    .BUCKET_WIDTH(BUCKET_WIDTH)
  ) u_sf (
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .sf_valid_i(sf_valid_i),
    .spattn_valid_i(spattn_valid_i),
    .spattn_initial_i(spattn_initial_i),
    .scaling_factor0_i(scaling_factor0_i),
    .scaling_factor1_i(scaling_factor1_i),
    .sign0_i(sign0_i),
    .sign1_i(sign1_i),
    .exponent_o(exponent_o),
    .bucket_3b000_o(bucket_3b000_o),
    .bucket_3b001_o(bucket_3b001_o),
    .bucket_3b110_o(bucket_3b110_o),
    .bucket_3b111_o(bucket_3b111_o)
  );

  // Helper function: compute the expected bucket update
  function void update_expected_buckets(input logic init);
    logic [SF_WIDTH-1:0] current_sf;
    logic [2:0]          high_3bits;
    logic [SF_WIDTH-5:0] shift_bits;
    logic [BUCKET_WIDTH-1:0] shift_val;

    // Use the previously computed exponent and sign (mimics the DUT register behavior)
    current_sf = {last_sign_bit, last_exponent[SF_WIDTH-2:0]};
    high_3bits = current_sf[SF_WIDTH-2:SF_WIDTH-4];
    shift_bits = current_sf[SF_WIDTH-5:0];
    shift_val  = 1 << shift_bits;

    // If initializing, clear all buckets first
    if (init) begin
      exp_bucket_3b000 = 0;
      exp_bucket_3b001 = 0;
      exp_bucket_3b110 = 0;
      exp_bucket_3b111 = 0;
    end

    case (high_3bits)
      3'b000: begin
        if (current_sf[SF_WIDTH-1]) // Negative
          exp_bucket_3b000 = exp_bucket_3b000 - shift_val;
        else // Positive
          exp_bucket_3b000 = exp_bucket_3b000 + shift_val;
      end
      3'b001: begin
        if (current_sf[SF_WIDTH-1])
          exp_bucket_3b001 = exp_bucket_3b001 - shift_val;
        else
          exp_bucket_3b001 = exp_bucket_3b001 + shift_val;
      end
      3'b110: begin
        if (current_sf[SF_WIDTH-1])
          exp_bucket_3b110 = exp_bucket_3b110 - shift_val;
        else
          exp_bucket_3b110 = exp_bucket_3b110 + shift_val;
      end
      3'b111: begin
        if (current_sf[SF_WIDTH-1])
          exp_bucket_3b111 = exp_bucket_3b111 - shift_val;
        else
          exp_bucket_3b111 = exp_bucket_3b111 + shift_val;
      end
      default: ; // Do nothing
    endcase
  endfunction

  // Drive task: drive the SF computation and update the expected Exponent
  task automatic drive_sf(input logic [DATA_WIDTH-1:0] sf0, input logic [DATA_WIDTH-1:0] sf1, input logic s0, input logic s1);
    @(posedge clk_i);
    #1;
    sf_valid_i        = 1;
    scaling_factor0_i = sf0;
    scaling_factor1_i = sf1;
    sign0_i           = s0;
    sign1_i           = s1;
    @(posedge clk_i);
    #1;
    sf_valid_i        = 0;
    scaling_factor0_i = 'x;
    scaling_factor1_i = 'x;
    sign0_i           = 'x;
    sign1_i           = 'x;

    // Update the expected Exponent state immediately (the DUT outputs it in the next cycle)
    last_exponent = sf0 + sf1;
    last_sign_bit = s0 ^ s1;
    exp_exponent  = last_exponent;
  endtask

  // Drive task: drive the Bucket update and compute the expected Bucket values
  task automatic drive_spattn(input logic init);
    @(posedge clk_i);
    #1;
    spattn_valid_i   = 1;
    spattn_initial_i = init;

    // Compute the expected Bucket update based on the current SF (last_exponent/sign)
    update_expected_buckets(init);

    @(posedge clk_i);
    #1;
    spattn_valid_i   = 0;
    spattn_initial_i = 'x;
  endtask

  // Check task
  task check_output(string tag);
    @(posedge clk_i);
    if (exponent_o !== exp_exponent) begin
      fail_cnt++;
      $display("%s[FAIL]%s %s Exponent Mismatch: DUT=%h EXP=%h", RED, RESET, tag, exponent_o, exp_exponent);
    end else if (bucket_3b000_o !== exp_bucket_3b000 ||
                 bucket_3b001_o !== exp_bucket_3b001 ||
                 bucket_3b110_o !== exp_bucket_3b110 ||
                 bucket_3b111_o !== exp_bucket_3b111) begin
      fail_cnt++;
      $display("%s[FAIL]%s %s Bucket Mismatch", RED, RESET, tag);
      $display("  DUT:  Bucket[000]=%d Bucket[001]=%d Bucket[110]=%d Bucket[111]=%d", $signed(bucket_3b000_o), $signed(bucket_3b001_o), $signed(bucket_3b110_o), $signed(bucket_3b111_o));
      $display("  GOLD: Bucket[000]=%d Bucket[001]=%d Bucket[110]=%d Bucket[111]=%d", $signed(exp_bucket_3b000), $signed(exp_bucket_3b001), $signed(exp_bucket_3b110), $signed(exp_bucket_3b111));
    end else begin
      pass_cnt++;
      $display("%s[PASS]%s %s", GREEN, RESET, tag);
    end
  endtask

  // Main test flow
  initial begin
    // Initialization
    rstn_i = 0;
    sf_valid_i = 0;
    spattn_valid_i = 0;
    spattn_initial_i = 0;
    scaling_factor0_i = 0;
    scaling_factor1_i = 0;
    sign0_i = 0;
    sign1_i = 0;

    // Reset the expected state
    exp_exponent = 0;
    exp_bucket_3b000 = 0;
    exp_bucket_3b001 = 0;
    exp_bucket_3b110 = 0;
    exp_bucket_3b111 = 0;
    last_exponent = 0;
    last_sign_bit = 0;

    #20;
    rstn_i = 1;
    #10;
    $display("=== Starting SF Testbench ===");

    // Case 1: basic SF computation test
    $display("[CASE 1] Basic SF Computation");
    drive_sf(10, 5, 0, 0); // Exp=15, Sign=0
    check_output("SF Calc 1");

    // Case 2: bucket update (no hit)
    $display("[CASE 2] Bucket Update (No Match)");
    // Exp=15 (01111), Sign=0 -> SF=0_01111 -> High3=011 (No match)
    drive_spattn(1);
    check_output("Bucket No Match");

    // Case 3: Bucket 000 initialization
    $display("[CASE 3] Bucket 000 Init");
    drive_sf(1, 1, 0, 0); // Exp=2 (00010), Sign=0 -> SF=0_00010 -> High3=000, Shift=2 -> Val=4
    check_output("SF Calc 2"); // Check exp update
    drive_spattn(1);      // Init
    check_output("Bucket 000 Init");

    // Case 4: Bucket 000 accumulation
    $display("[CASE 4] Bucket 000 Accumulate");
    drive_spattn(0);      // Accum -> 4+4=8
    check_output("Bucket 000 Accum");

    // Case 5: Bucket 000 subtraction
    $display("[CASE 5] Bucket 000 Subtract");
    drive_sf(1, 1, 1, 0); // Exp=2, Sign=1 -> SF=1_00010 -> High3=000, Shift=2 -> Val=4 (Sub)
    check_output("SF Calc 3");
    drive_spattn(0);      // Accum -> 8-4=4
    check_output("Bucket 000 Sub");

    // Case 6: Bucket 001 initialization
    $display("[CASE 6] Bucket 001 Init");
    drive_sf(2, 2, 0, 0); // Exp=4 (00100) -> SF=0_00100 -> High3=001, Shift=0 -> Val=1
    check_output("SF Calc 4");
    drive_spattn(1);      // Init -> 1
    check_output("Bucket 001 Init");

    // Case 7: Bucket 110 initialization
    $display("[CASE 7] Bucket 110 Init");
    drive_sf(12, 12, 0, 0); // Exp=24 (11000) -> SF=0_11000 -> High3=110, Shift=0 -> Val=1
    check_output("SF Calc 5");
    drive_spattn(1);
    check_output("Bucket 110 Init");

    // Case 8: Bucket 111 initialization
    $display("[CASE 8] Bucket 111 Init");
    drive_sf(14, 14, 0, 0); // Exp=28 (11100) -> SF=0_11100 -> High3=111, Shift=0 -> Val=1
    check_output("SF Calc 6");
    drive_spattn(1);
    check_output("Bucket 111 Init");

    // Case 9: random regression
    $display("[CASE 9] Random Regression (%0d cycles)", rand_num);
    repeat(rand_num) begin
      logic [DATA_WIDTH-1:0] r_sf0, r_sf1;
      logic r_s0, r_s1;
      logic r_init;

      r_sf0 = $urandom();
      r_sf1 = $urandom();
      r_s0  = $urandom();
      r_s1  = $urandom();
      r_init = $urandom_range(0, 5) == 0;

      drive_sf(r_sf0, r_sf1, r_s0, r_s1);
      drive_spattn(r_init);
      check_output("Rand");
    end

    // Summary
    $display("========================================");
    $display("SUMMARY: PASS=%0d  FAIL=%0d", pass_cnt, fail_cnt);
    if (fail_cnt == 0)
      $display("%s[ALL PASS]%s", GREEN, RESET);
    else
      $display("%s[FAILURES FOUND]%s", RED, RESET);
    $display("========================================");
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
