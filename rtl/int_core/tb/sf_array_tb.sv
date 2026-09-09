// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
//////////////////////////////////////////////////////////////////////////////////
// Description: Testbench for SF Array module
// Author:      Mingxuan Li <siris-lmx@stu.pku.edu.cn> [Peking University]
// Acknowledge: VSCode Copilot + Gemini-3-Pro Agent
//////////////////////////////////////////////////////////////////////////////////

// pragma translate_off
`timescale 1ns/1ps

module sf_array_tb;

  // Parameters
  localparam DATA_WIDTH       = 8;
  localparam SF_WIDTH         = 6;
  localparam BUCKET_WIDTH     = 12;
  localparam ARRAY_SIZE       = 8;
  localparam SPATTN_CNT_MAX   = 128;

  // Derived Parameters
  localparam ACCUM_WIDTH      = BUCKET_WIDTH + 2 * $clog2(ARRAY_SIZE);
  localparam ADDR_WIDTH       = $clog2(ARRAY_SIZE);

  // DUT Signals
  logic                                   clk_i;
  logic                                   rstn_i;
  logic                                   sf_valid_i;
  logic [ARRAY_SIZE-1:0][DATA_WIDTH-1:0]  sf_line0_i;
  logic [ARRAY_SIZE-1:0][DATA_WIDTH-1:0]  sf_line1_i;
  logic [ARRAY_SIZE-1:0]                  sign_line0_i;
  logic [ARRAY_SIZE-1:0]                  sign_line1_i;
  logic [ARRAY_SIZE-1:0][ARRAY_SIZE-1:0][DATA_WIDTH-1:0] exponent_matrix_o;
  logic                                   spattn_valid_i;
  logic                                   spattn_initial_i;
  logic [4-1:0][32-1:0]                   sum_bucket_aligned_o;
  logic                                   sum_valid_o;

  // Reference Model State
  logic [DATA_WIDTH-1:0]   ref_exp_matrix [ARRAY_SIZE][ARRAY_SIZE];
  logic                    ref_sign_matrix [ARRAY_SIZE][ARRAY_SIZE];
  logic [BUCKET_WIDTH-1:0] ref_buckets [4][ARRAY_SIZE][ARRAY_SIZE]; // 0:000, 1:001, 2:110, 3:111

  // Debug History
  logic [SF_WIDTH-1:0]     debug_signed_sf  [SPATTN_CNT_MAX][ARRAY_SIZE][ARRAY_SIZE];
  logic [SF_WIDTH-5:0]     debug_shift_bits [SPATTN_CNT_MAX][ARRAY_SIZE][ARRAY_SIZE];
  logic [BUCKET_WIDTH-1:0] debug_shift_val  [SPATTN_CNT_MAX][ARRAY_SIZE][ARRAY_SIZE];
  int                      debug_bucket_idx [SPATTN_CNT_MAX][ARRAY_SIZE][ARRAY_SIZE];

  // Test Control
  int fail_cnt = 0;
  string GREEN = "\033[32m";
  string RED   = "\033[31m";
  string RESET = "\033[0m";

  // Clock Generation
  initial begin
    clk_i = 0;
    forever #5 clk_i = ~clk_i;
  end

  // DUT Instantiation
  sf_array #(
    .DATA_WIDTH       (DATA_WIDTH),
    .SF_WIDTH         (SF_WIDTH),
    .BUCKET_WIDTH     (BUCKET_WIDTH),
    .ARRAY_SIZE       (ARRAY_SIZE),
    .SPATTN_CNT_MAX   (SPATTN_CNT_MAX)
  ) u_dut (
    .clk_i                (clk_i),
    .rstn_i               (rstn_i),
    .sf_valid_i           (sf_valid_i),
    .sf_line0_i           (sf_line0_i),
    .sf_line1_i           (sf_line1_i),
    .sign_line0_i         (sign_line0_i),
    .sign_line1_i         (sign_line1_i),
    .exponent_matrix_o    (exponent_matrix_o),
    .spattn_valid_i       (spattn_valid_i),
    .spattn_initial_i     (spattn_initial_i),
    .sum_bucket_aligned_o (sum_bucket_aligned_o),
    .sum_valid_o          (sum_valid_o)
  );

  // --- Reference Model Logic ---

  // Update Exponents (Simulates sf_valid_i)
  function void update_ref_exponents();
    for (int i = 0; i < ARRAY_SIZE; i++) begin
      for (int j = 0; j < ARRAY_SIZE; j++) begin
        ref_exp_matrix[i][j]  = sf_line0_i[i] + sf_line1_i[j];
        ref_sign_matrix[i][j] = sign_line0_i[i] ^ sign_line1_i[j];
      end
    end
  endfunction

  // Update Buckets (Simulates spattn_valid_i)
  // Note: DUT updates buckets based on *registered* exponent/sign from previous cycle.
  // In TB, we call this function *after* update_ref_exponents has been called in the previous step.
  function void update_ref_buckets(input logic init, input int step);
    for (int i = 0; i < ARRAY_SIZE; i++) begin
      for (int j = 0; j < ARRAY_SIZE; j++) begin
        logic [SF_WIDTH-1:0] signed_sf;
        logic [2:0]          high_3bits;
        logic [SF_WIDTH-5:0] shift_bits;
        logic [BUCKET_WIDTH-1:0] shift_val;
        int bucket_idx;

        signed_sf  = {ref_sign_matrix[i][j], ref_exp_matrix[i][j][SF_WIDTH-2:0]};
        high_3bits = signed_sf[SF_WIDTH-2:SF_WIDTH-4];
        shift_bits = signed_sf[SF_WIDTH-5:0];
        shift_val  = 1 << shift_bits;

        bucket_idx = -1;
        case (high_3bits)
          3'b000: bucket_idx = 0;
          3'b001: bucket_idx = 1;
          3'b110: bucket_idx = 2;
          3'b111: bucket_idx = 3;
        endcase

        // Store debug info
        if (step < SPATTN_CNT_MAX) begin
            debug_signed_sf[step][i][j]  = signed_sf;
            debug_shift_bits[step][i][j] = shift_bits;
            debug_shift_val[step][i][j]  = shift_val;
            debug_bucket_idx[step][i][j] = bucket_idx;
        end

        // Clear all buckets for this element if init
        if (init) begin
          ref_buckets[0][i][j] = 0;
          ref_buckets[1][i][j] = 0;
          ref_buckets[2][i][j] = 0;
          ref_buckets[3][i][j] = 0;
        end

        if (bucket_idx != -1) begin
          logic [BUCKET_WIDTH-1:0] current_val;
          current_val = ref_buckets[bucket_idx][i][j];

          if (signed_sf[SF_WIDTH-1]) begin // Negative
            ref_buckets[bucket_idx][i][j] = current_val - shift_val;
          end else begin // Positive
            ref_buckets[bucket_idx][i][j] = current_val + shift_val;
          end
        end
      end
    end
  endfunction

  // Calculate Final Sums
  function void get_expected_sums(output logic [ACCUM_WIDTH-1:0] sums[4]);
    for (int b = 0; b < 4; b++) begin
      logic signed [ACCUM_WIDTH-1:0] total;
      total = 0;
      for (int i = 0; i < ARRAY_SIZE; i++) begin
        for (int j = 0; j < ARRAY_SIZE; j++) begin
          total = total + $signed(ref_buckets[b][i][j]);
        end
      end
      sums[b] = total;
    end
  endfunction

  // --- Tasks ---

  task drive_random_sf();
    for (int i = 0; i < ARRAY_SIZE; i++) begin
      sf_line0_i[i]   = $urandom() & {DATA_WIDTH{1'b1}};
      sf_line1_i[i]   = $urandom() & {DATA_WIDTH{1'b1}};
      sign_line0_i[i] = $urandom() & 1'b1;
      sign_line1_i[i] = $urandom() & 1'b1;
    end
    @(posedge clk_i);
    #1;
    sf_valid_i = 1;
    @(posedge clk_i);
    #1;
    sf_valid_i = 0;
    // Update Ref Model (Delayed by 1 cycle in DUT, but we update state now for next step usage)
    update_ref_exponents();
  endtask

  task check_exponents();
    int start_fail_cnt = fail_cnt;
    $display("Checking Exponent Matrix...");

    // Wait for computation to finish (already waited in drive_random_sf)
    // Directly check output matrix
    for (int i = 0; i < ARRAY_SIZE; i++) begin
      for (int j = 0; j < ARRAY_SIZE; j++) begin
        if (exponent_matrix_o[i][j] !== ref_exp_matrix[i][j]) begin
          $display("%s[FAIL]%s Exp[%0d][%0d] DUT=%h REF=%h", RED, RESET, i, j, exponent_matrix_o[i][j], ref_exp_matrix[i][j]);
          fail_cnt++;
        end
      end
    end
    if (fail_cnt == start_fail_cnt)
      $display("%s[PASS]%s Exponent Check Passed", GREEN, RESET);
  endtask

  task run_spattn_sequence();
    $display("Running SpAttn Sequence (Length=%0d)...", SPATTN_CNT_MAX);

    // Clear ref buckets (Global reset simulation)
    // Since we rely on rstn_i to clear DUT, we should clear ref here too if this is a fresh start
    // But let's assume we just follow the flow.

    for (int k = 0; k < SPATTN_CNT_MAX; k++) begin
      // 1. Drive new SF (Pipeline Stage 1)
      drive_random_sf();

      // 2. Drive SpAttn (Pipeline Stage 2 - uses SF from previous drive)
      // Note: In this TB structure, drive_random_sf advances 1 clock.
      // So the SF driven in loop k is available for SpAttn in loop k+1?
      // No, let's align:
      // Cycle 0: Drive SF_0.
      // Cycle 1: SF_0 latched. Drive SpAttn (uses SF_0). Drive SF_1.
      // This requires parallel driving or careful ordering.

      // Simplified approach:
      // Drive SF. Wait clock.
      // Drive SpAttn. Wait clock.
      // This is slower but functionally correct for verification logic.

      spattn_valid_i   = 1;
      spattn_initial_i = (k == 0); // Init on first step

      // Update Ref Model Buckets (using the SF we just drove and updated in ref model)
      update_ref_buckets(spattn_initial_i, k);

      @(posedge clk_i);
      #1;
      spattn_valid_i   = 0;
      spattn_initial_i = 0;
    end

    // Wait for Sum Valid
    $display("Waiting for Sum Valid...");
    fork
      begin
        wait(sum_valid_o);
        #1;
        check_sums();
      end
      begin
        repeat(100) @(posedge clk_i);
        $display("%s[FAIL]%s Timeout waiting for sum_valid_o", RED, RESET);
        fail_cnt++;
      end
    join_any
    disable fork;
  endtask

  task check_sums();
    int start_fail_cnt = fail_cnt;
    logic [ACCUM_WIDTH-1:0] exp_sums[4];
    bit any_fail;
    get_expected_sums(exp_sums);

    $display("--- Detailed Bucket Check ---");
    for (int i = 0; i < ARRAY_SIZE; i++) begin
      for (int j = 0; j < ARRAY_SIZE; j++) begin
        any_fail = (u_dut.bucket_3b000_matrix[i][j] !== ref_buckets[0][i][j]) ||
                   (u_dut.bucket_3b001_matrix[i][j] !== ref_buckets[1][i][j]) ||
                   (u_dut.bucket_3b110_matrix[i][j] !== ref_buckets[2][i][j]) ||
                   (u_dut.bucket_3b111_matrix[i][j] !== ref_buckets[3][i][j]);

        if (any_fail) begin
            $display("SF[%0d][%0d]:", i, j);
            $display("  [DEBUG HISTORY]");
            for (int k=0; k<SPATTN_CNT_MAX; k++) begin
                $display("    Step %0d: signed_sf=6'b%b, shift_bits=%0d, shift_val=%0d, bucket=%0d",
                    k,
                    debug_signed_sf[k][i][j],
                    debug_shift_bits[k][i][j],
                    debug_shift_val[k][i][j],
                    debug_bucket_idx[k][i][j]);
            end

            // Bucket 000
            if (u_dut.bucket_3b000_matrix[i][j] !== ref_buckets[0][i][j])
               $display("  B000: DUT=%0d REF=%0d %s[FAIL]%s", $signed(u_dut.bucket_3b000_matrix[i][j]), $signed(ref_buckets[0][i][j]), RED, RESET);
            else
               $display("  B000: DUT=%0d REF=%0d [PASS]", $signed(u_dut.bucket_3b000_matrix[i][j]), $signed(ref_buckets[0][i][j]));

            // Bucket 001
            if (u_dut.bucket_3b001_matrix[i][j] !== ref_buckets[1][i][j])
               $display("  B001: DUT=%0d REF=%0d %s[FAIL]%s", $signed(u_dut.bucket_3b001_matrix[i][j]), $signed(ref_buckets[1][i][j]), RED, RESET);
            else
               $display("  B001: DUT=%0d REF=%0d [PASS]", $signed(u_dut.bucket_3b001_matrix[i][j]), $signed(ref_buckets[1][i][j]));

            // Bucket 110
            if (u_dut.bucket_3b110_matrix[i][j] !== ref_buckets[2][i][j])
               $display("  B110: DUT=%0d REF=%0d %s[FAIL]%s", $signed(u_dut.bucket_3b110_matrix[i][j]), $signed(ref_buckets[2][i][j]), RED, RESET);
            else
               $display("  B110: DUT=%0d REF=%0d [PASS]", $signed(u_dut.bucket_3b110_matrix[i][j]), $signed(ref_buckets[2][i][j]));

            // Bucket 111
            if (u_dut.bucket_3b111_matrix[i][j] !== ref_buckets[3][i][j])
               $display("  B111: DUT=%0d REF=%0d %s[FAIL]%s", $signed(u_dut.bucket_3b111_matrix[i][j]), $signed(ref_buckets[3][i][j]), RED, RESET);
            else
               $display("  B111: DUT=%0d REF=%0d [PASS]", $signed(u_dut.bucket_3b111_matrix[i][j]), $signed(ref_buckets[3][i][j]));
        end
      end
    end
    $display("------------------------------------");

    $display("--- Sum Check Details ---");
    $display("Bucket | DUT Output | Expected | Result");
    $display("-------|------------|----------|-------");

    // Bucket 000
    if (sum_bucket_aligned_o[0] !== 32'(signed'(exp_sums[0]))) begin
      $display("  000  | %10d | %8d | %sFAIL%s", $signed(sum_bucket_aligned_o[0]), $signed(exp_sums[0]), RED, RESET);
      fail_cnt++;
    end else begin
      $display("  000  | %10d | %8d | %sPASS%s", $signed(sum_bucket_aligned_o[0]), $signed(exp_sums[0]), GREEN, RESET);
    end

    // Bucket 001
    if (sum_bucket_aligned_o[1] !== 32'(signed'(exp_sums[1]))) begin
      $display("  001  | %10d | %8d | %sFAIL%s", $signed(sum_bucket_aligned_o[1]), $signed(exp_sums[1]), RED, RESET);
      fail_cnt++;
    end else begin
      $display("  001  | %10d | %8d | %sPASS%s", $signed(sum_bucket_aligned_o[1]), $signed(exp_sums[1]), GREEN, RESET);
    end

    // Bucket 110
    if (sum_bucket_aligned_o[2] !== 32'(signed'(exp_sums[2]))) begin
      $display("  110  | %10d | %8d | %sFAIL%s", $signed(sum_bucket_aligned_o[2]), $signed(exp_sums[2]), RED, RESET);
      fail_cnt++;
    end else begin
      $display("  110  | %10d | %8d | %sPASS%s", $signed(sum_bucket_aligned_o[2]), $signed(exp_sums[2]), GREEN, RESET);
    end

    // Bucket 111
    if (sum_bucket_aligned_o[3] !== 32'(signed'(exp_sums[3]))) begin
      $display("  111  | %10d | %8d | %sFAIL%s", $signed(sum_bucket_aligned_o[3]), $signed(exp_sums[3]), RED, RESET);
      fail_cnt++;
    end else begin
      $display("  111  | %10d | %8d | %sPASS%s", $signed(sum_bucket_aligned_o[3]), $signed(exp_sums[3]), GREEN, RESET);
    end
    $display("---------------------------------------");

    if (fail_cnt == start_fail_cnt) $display("%s[PASS]%s Sum Checks Passed", GREEN, RESET);
  endtask

  // --- Main ---
  initial begin
    // Init
    rstn_i = 0;
    sf_valid_i = 0;
    spattn_valid_i = 0;
    spattn_initial_i = 0;
    sf_line0_i = '0;
    sf_line1_i = '0;
    sign_line0_i = '0;
    sign_line1_i = '0;

    // Clear Ref Buckets
    for(int b=0; b<4; b++)
      for(int i=0; i<ARRAY_SIZE; i++)
        for(int j=0; j<ARRAY_SIZE; j++)
          ref_buckets[b][i][j] = 0;

    #20;
    rstn_i = 1;
    #10;
    $display("=== Starting SF Array Testbench ===");

    // Test 1: SF Compute & Read
    $display("[TEST 1] SF Compute & Read");
    drive_random_sf(); // Drive one set of inputs
    check_exponents(); // Verify calculation via read interface

    // Test 2: Full SpAttn Sequence
    $display("[TEST 2] Full SpAttn Sequence");
    // Reset DUT to clear any previous state (optional, but good for clean test)
    rstn_i = 0; #10; rstn_i = 1; #10;
    // Clear Ref Buckets again
    for(int b=0; b<4; b++)
      for(int i=0; i<ARRAY_SIZE; i++)
        for(int j=0; j<ARRAY_SIZE; j++)
          ref_buckets[b][i][j] = 0;

    run_spattn_sequence();

    // Summary
    $display("========================================");
    $display("SUMMARY: FAIL=%0d", fail_cnt);
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
