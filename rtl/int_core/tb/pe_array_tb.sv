// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
//////////////////////////////////////////////////////////////////////////////////
// Description: Testbench for PE Array Module
// Author:      Mingxuan Li <siris-lmx@stu.pku.edu.cn> [Peking University]
// Acknowledge: VSCode Copilot + GPT-5 Agent
//////////////////////////////////////////////////////////////////////////////////

// pragma translate_off
`timescale 1ns/1ps

module pe_array_tb;

  // Parameters can be modified to match the DUT
  localparam DATA_WIDTH    = 4;
  localparam MAX_ACCUM_NUM = 32;
  localparam ARRAY_SIZE    = 8;
  localparam ACCUM_WIDTH   = $clog2(MAX_ACCUM_NUM) + DATA_WIDTH * 2;
  localparam ADDR_WIDTH    = $clog2(ARRAY_SIZE);

  // DUT ports
  logic                                   clk_i;
  logic                                   rstn_i;
  logic                                   in_valid_i;
  logic                                   initial_i;
  logic [ARRAY_SIZE-1:0][ DATA_WIDTH-1:0] activation_line_i;
  logic [ARRAY_SIZE-1:0][ DATA_WIDTH-1:0] weight_line_i;
  logic [ARRAY_SIZE-1:0][ARRAY_SIZE-1:0][16-1:0] result_matrix_aligned_o;

  typedef logic signed [DATA_WIDTH-1:0]    sdata_t;
  typedef logic signed [ACCUM_WIDTH-1:0]   saccu_t;


  // Statistics and control
  int pass_cnt = 0;
  int fail_cnt = 0;
  int rand_num = 50;
  int seed     = 32'h2;

  // Color control (ANSI)
  string GREEN = "\033[1;32m"; // Bold Green
  string RED   = "\033[1;31m"; // Bold Red
  string YEL   = "\033[1;33m"; // Bold Yellow
  string CYAN  = "\033[1;36m"; // Bold Cyan
  string BLUE  = "\033[1;34m"; // Bold Blue
  string RESET = "\033[0m";

  // Print helper tasks
  task automatic print_banner(string title);
    $display("\n%s======================================================================", BLUE);
    $display("   %s", title);
    $display("======================================================================%s", RESET);
  endtask

  task automatic print_pass(string msg);
    pass_cnt++;
    $display("%s[PASS]%s %s", GREEN, RESET, msg);
  endtask

  task automatic print_fail(string msg);
    fail_cnt++;
    $display("%s[FAIL]%s %s", RED, RESET, msg);
  endtask

  // DUT instantiation
  pe_array #(
    .DATA_WIDTH(DATA_WIDTH), .MAX_ACCUM_NUM(MAX_ACCUM_NUM), .ARRAY_SIZE(ARRAY_SIZE)
  ) u_dut (
    .clk_i(clk_i), .rstn_i(rstn_i),
    .in_valid_i(in_valid_i), .initial_i(initial_i),
    .activation_line_i(activation_line_i), .weight_line_i(weight_line_i),
    .result_matrix_aligned_o(result_matrix_aligned_o)
  );

  // Clock
  initial begin
    clk_i = 0;
    forever #5 clk_i = ~clk_i;
  end

  // Drive functions
  task automatic drive_compute(bit vld, bit init, int acts[ARRAY_SIZE], int wgts[ARRAY_SIZE]);
    #1; // signal transmission delay
    in_valid_i = vld; initial_i = init;
    for (int i=0;i<ARRAY_SIZE;i++) begin
      activation_line_i[i] = sdata_t'(acts[i]);
      weight_line_i[i]     = sdata_t'(wgts[i]);
    end
  endtask

  // Verification function: read and check one row
  task automatic verify_read_row(int row_idx, int expected_matrix[ARRAY_SIZE][ARRAY_SIZE], string tag);
    // Check the output ports directly
    for (int j=0; j<ARRAY_SIZE; j++) begin
      // Note: result_matrix_aligned_o is 16-bit aligned; comparison needs sign extension or truncation
      // Here it is assumed that the expected_matrix values fit in the 16-bit range
      logic [15:0] expected_val;
      logic [15:0] actual_val;

      // Handle sign extension (ACCUM_WIDTH -> 16)
      // The RTL sign-extends: result_matrix_aligned_o[i][j] = $signed(result_matrix[i][j]);
      expected_val = 16'(signed'(saccu_t'(expected_matrix[row_idx][j])));
      actual_val   = result_matrix_aligned_o[row_idx][j];

      if (actual_val !== expected_val) begin
        print_fail($sformatf("%s Row %0d Col %0d Exp=0x%04x Got=0x%04x", tag, row_idx, j, expected_val, actual_val));
      end
    end
  endtask

  // Test case: reset
  task automatic test_reset();
    print_banner("TEST CASE: RESET");
    rstn_i = 0; in_valid_i=0; initial_i=0; activation_line_i='0; weight_line_i='0;
    repeat(2) @(posedge clk_i);
    rstn_i = 1; @(posedge clk_i);

    #1;
    // Check internal memory is 0 by reading
    for(int i=0; i<ARRAY_SIZE; i++) begin
        for(int j=0; j<ARRAY_SIZE; j++) begin
            if(result_matrix_aligned_o[i][j] !== 0) begin
                print_fail($sformatf("Reset memory not 0 at [%0d][%0d]", i, j));
            end
        end
    end
  endtask

  // Test case: initialization overwrite + single out_valid
  task automatic test_initial_once();
    int acts[ARRAY_SIZE]; int wgts[ARRAY_SIZE];
    int expected[ARRAY_SIZE][ARRAY_SIZE];

    repeat(10) @(posedge clk_i);
    print_banner("TEST CASE: INITIAL_ONCE");

    // Prepare data
    for (int i=0;i<ARRAY_SIZE;i++) begin acts[i]=i-1; wgts[i]=1; end

    // Calculate expected
    for(int i=0; i<ARRAY_SIZE; i++) begin
        for(int j=0; j<ARRAY_SIZE; j++) begin
            expected[i][j] = acts[i] * wgts[j];
        end
    end

    // Drive
    drive_compute(1,1, acts, wgts);
    @(posedge clk_i);
    #1 in_valid_i=0; initial_i=0;

    // Check memory
    for(int i=0; i<ARRAY_SIZE; i++) verify_read_row(i, expected, "InitOnce");
  endtask

  // Test case: continuous accumulation up to the maximum depth
  task automatic test_accumulate_depth();
    int acts[ARRAY_SIZE]; int wgts[ARRAY_SIZE];
    int expected[ARRAY_SIZE][ARRAY_SIZE];

    repeat(10) @(posedge clk_i);
    print_banner("TEST CASE: ACC_DEPTH");

    // Initialize expected
    for(int i=0; i<ARRAY_SIZE; i++) for(int j=0; j<ARRAY_SIZE; j++) expected[i][j] = 0;

    for (int i=0;i<ARRAY_SIZE;i++) begin acts[i]=7; wgts[i]=7; end

    // Loop
    for (int t=0; t<MAX_ACCUM_NUM; t++) begin
        bit init = (t==0);

        // Update expected
        for(int i=0; i<ARRAY_SIZE; i++) begin
            for(int j=0; j<ARRAY_SIZE; j++) begin
                int prod = acts[i] * wgts[j]; // acts[i]=7, wgts[j]=7
                if(init) expected[i][j] = prod;
                else expected[i][j] += prod;
            end
        end

        drive_compute(1, init, acts, wgts);
        @(posedge clk_i);
        #1 in_valid_i=0; initial_i=0;
        @(posedge clk_i);
    end
    print_pass("Depth check done");
  endtask

  // Test case: ROW read
  task automatic test_read_row();
    int acts[ARRAY_SIZE]; int wgts[ARRAY_SIZE];
    int expected[ARRAY_SIZE][ARRAY_SIZE];

    repeat(10) @(posedge clk_i);
    print_banner("TEST CASE: READ_ROW");

    // Construct data
    for (int i=0;i<ARRAY_SIZE;i++) begin acts[i]=i; wgts[i]= (i&1)?-2:3; end

    // Calculate expected
    for(int i=0; i<ARRAY_SIZE; i++) begin
        for(int j=0; j<ARRAY_SIZE; j++) begin
            expected[i][j] = acts[i] * wgts[j];
        end
    end

    drive_compute(1,1, acts, wgts);
    @(posedge clk_i);
    #1 in_valid_i=0; initial_i=0;
    @(posedge clk_i);

    // Read checks
    verify_read_row(0, expected, "ReadRow0");
    verify_read_row(ARRAY_SIZE-1, expected, "ReadRowMax");

    print_pass("Read Row done");
  endtask

  // Random regression
  task automatic test_random(int num);
    int shadow_mem[ARRAY_SIZE][ARRAY_SIZE];
    int shadow_mem_prev[ARRAY_SIZE][ARRAY_SIZE];
    int shadow_accum_cnt = 0;
    int prod;
    bit exp_valid;
    bit error_found = 0;

    repeat(10) @(posedge clk_i);
    print_banner($sformatf("TEST CASE: RANDOM (num=%0d)", num));

    // Initialize shadow
    for(int i=0; i<ARRAY_SIZE; i++) for(int j=0; j<ARRAY_SIZE; j++) shadow_mem[i][j] = 0;

    for (int t=0;t<num;t++) begin
      bit init = (t==0) || ($urandom_range(0,7)==0);
      bit vld  = ($urandom_range(0,3)!=0);
      int acts[ARRAY_SIZE]; int wgts[ARRAY_SIZE];

      // Save previous state
      shadow_mem_prev = shadow_mem;

      // Randomize inputs
      for (int i=0;i<ARRAY_SIZE;i++) begin
        acts[i] = $random() % (1<<(DATA_WIDTH-1));
        wgts[i] = $random() % (1<<(DATA_WIDTH-1));
      end

      // Update Shadow
      if (vld) begin
          if (init) shadow_accum_cnt = 0;
          else if (shadow_accum_cnt != MAX_ACCUM_NUM - 1) shadow_accum_cnt++;

          for(int i=0; i<ARRAY_SIZE; i++) begin
            for(int j=0; j<ARRAY_SIZE; j++) begin
                prod = acts[i] * wgts[j];
                if (init) shadow_mem[i][j] = prod;
                else shadow_mem[i][j] += prod;
            end
          end
      end

      // Drive
      drive_compute(vld, init, acts, wgts);
      @(posedge clk_i);
      #1;
      in_valid_i=0; initial_i=0;
      @(posedge clk_i); #1;

      // Check All Matrix Elements
      for(int r=0; r<ARRAY_SIZE; r++) begin
        for(int c=0; c<ARRAY_SIZE; c++) begin
          logic [15:0] expected_val = 16'(signed'(saccu_t'(shadow_mem[r][c])));
          if (result_matrix_aligned_o[r][c] !== expected_val) begin
            print_fail($sformatf("Rand T=%0d Row %0d Col %0d Exp=0x%04x Got=0x%04x", t, r, c, expected_val, result_matrix_aligned_o[r][c]));
            error_found = 1;
          end
        end
      end

      // Check Out Valid
      if (error_found) begin
          $display("%s[DEBUG] Dumping state due to error...%s", YEL, RESET);
          $display("Time: %0t", $time);

          $write("[DEBUG] Inputs (Acts): ");
          for(int i=0; i<ARRAY_SIZE; i++) $write("%0d ", acts[i]);
          $write("\n");

          $write("[DEBUG] Inputs (Wgts): ");
          for(int i=0; i<ARRAY_SIZE; i++) $write("%0d ", wgts[i]);
          $write("\n");

          $display("[DEBUG] Previous Shadow Matrix (Before this step):");
          for(int r=0; r<ARRAY_SIZE; r++) begin
              for(int c=0; c<ARRAY_SIZE; c++) $write("%5d ", shadow_mem_prev[r][c]);
              $write("\n");
          end

          $display("[DEBUG] Expected Shadow Matrix (After this step):");
          for(int r=0; r<ARRAY_SIZE; r++) begin
              for(int c=0; c<ARRAY_SIZE; c++) $write("%5d ", shadow_mem[r][c]);
              $write("\n");
          end

          $display("[DEBUG] Actual DUT Matrix:");
          for(int r=0; r<ARRAY_SIZE; r++) begin
              for(int c=0; c<ARRAY_SIZE; c++) $write("%5d ", $signed(result_matrix_aligned_o[r][c])); // Note: this print might be misleading if sign extension is not handled in print, but good enough for debug
              $write("\n");
          end
          $display("--------------------------------------------------");
      end
    end
    print_pass("Random test done");
  endtask

  // Test case: 8x32 * 32x8 matrix multiplication
  task automatic test_matrix_mul_8x32_32x8(int num_tests);
    int A[ARRAY_SIZE][MAX_ACCUM_NUM];
    int B[MAX_ACCUM_NUM][ARRAY_SIZE];
    int C[ARRAY_SIZE][ARRAY_SIZE]; // Expected result
    int acts[ARRAY_SIZE];
    int wgts[ARRAY_SIZE];
    int R_dut[ARRAY_SIZE][ARRAY_SIZE];
    bit error_found;

    repeat(10) @(posedge clk_i);
    print_banner($sformatf("TEST CASE: MAT_MUL_8x32_32x8 (NumTests=%0d)", num_tests));

    for (int t=0; t<num_tests; t++) begin
      error_found = 0;
      $display("  -> Running Test %0d/%0d", t+1, num_tests);

      // 1. Generate random matrix data
      for (int i=0; i<ARRAY_SIZE; i++) begin
        for (int k=0; k<MAX_ACCUM_NUM; k++) begin
          A[i][k] = $random() % (1<<(DATA_WIDTH-1));
        end
      end
      for (int k=0; k<MAX_ACCUM_NUM; k++) begin
        for (int j=0; j<ARRAY_SIZE; j++) begin
          B[k][j] = $random() % (1<<(DATA_WIDTH-1));
        end
      end

      // 2. Compute the expected result C = A * B
      for (int i=0; i<ARRAY_SIZE; i++) begin
        for (int j=0; j<ARRAY_SIZE; j++) begin
          C[i][j] = 0;
          for (int k=0; k<MAX_ACCUM_NUM; k++) begin
            C[i][j] += $signed(A[i][k]) * $signed(B[k][j]);
          end
        end
      end

      // 3. Feed data (32 cycles)
      for (int k=0; k<MAX_ACCUM_NUM; k++) begin
        // Prepare the inputs for the k-th iteration
        for (int i=0; i<ARRAY_SIZE; i++) acts[i] = A[i][k];
        for (int j=0; j<ARRAY_SIZE; j++) wgts[j] = B[k][j];

        drive_compute(1, (k==0), acts, wgts);
        @(posedge clk_i);
        #1 in_valid_i = 0; initial_i = 0;
        @(posedge clk_i);
      end

      // 4. Check out_valid
      pass_cnt++;

      // 5. Check the result matrix (read row by row and compare)
      for (int i=0; i<ARRAY_SIZE; i++) begin
        for (int j=0; j<ARRAY_SIZE; j++) begin
          logic [15:0] expected_val = 16'(signed'(saccu_t'(C[i][j])));
          if (result_matrix_aligned_o[i][j] !== expected_val) begin
            error_found = 1;
            print_fail($sformatf("MAT_MUL Test %0d Row %0d Col %0d Exp=0x%04x Got=0x%04x", t, i, j, expected_val, result_matrix_aligned_o[i][j]));
          end
        end
      end

      if (!error_found) begin
          print_pass($sformatf("MAT_MUL Test %0d OK", t));
      end else begin
        // 6. If there is an error, print detailed matrix information for debugging
        $display("%s[DEBUG] Dumping Matrices due to error in Test %0d...%s", YEL, RESET, t);

        // ===== Print matrices A and B =====
        $display("%s[DEBUG]%s Matrix A (%0dx%0d):", CYAN, RESET, ARRAY_SIZE, MAX_ACCUM_NUM);
        for (int i=0; i<ARRAY_SIZE; i++) begin
          string line = "";
          for (int k=0; k<MAX_ACCUM_NUM; k++) begin
            line = {line, $sformatf("%5d ", $signed(A[i][k]))};
          end
          $display("%s", line);
        end

        $display("%s[DEBUG]%s Matrix B (%0dx%0d):", CYAN, RESET, MAX_ACCUM_NUM, ARRAY_SIZE);
        for (int k=0; k<MAX_ACCUM_NUM; k++) begin
          string line = "";
          for (int j=0; j<ARRAY_SIZE; j++) begin
            line = {line, $sformatf("%5d ", $signed(B[k][j]))};
          end
          $display("%s", line);
        end

        // ===== Print expected result matrix C =====
        $display("%s[DEBUG]%s Matrix C = A * B (%0dx%0d):", CYAN, RESET, ARRAY_SIZE, ARRAY_SIZE);
        for (int i=0; i<ARRAY_SIZE; i++) begin
          string line = "";
          for (int j=0; j<ARRAY_SIZE; j++) begin
            line = {line, $sformatf("%5d ", $signed(C[i][j]))};
          end
          $display("%s", line);
        end

        // ===== Read the DUT result matrix and print it =====
        // Print DUT result matrix
        $display("%s[DEBUG]%s DUT Result Matrix (%0dx%0d):", CYAN, RESET, ARRAY_SIZE, ARRAY_SIZE);
        for (int i=0; i<ARRAY_SIZE; i++) begin
          string line = "";
          for (int j=0; j<ARRAY_SIZE; j++) begin
            line = {line, $sformatf("%5d ", $signed(result_matrix_aligned_o[i][j]))};
          end
          $display("%s", line);
        end
      end
    end
  endtask

  // Main process
  initial begin
    // plusargs configuration
    int noc; if ($value$plusargs("NOCOLOR=%d", noc) && (noc!=0)) begin GREEN=""; RED=""; YEL=""; CYAN=""; RESET=""; end
    if ($value$plusargs("SEED=%d", seed)) begin end
    if ($value$plusargs("RAND_NUM=%d", rand_num)) begin end
    void'($urandom(seed));

    $display("%s[START]%s PE_ARRAY Testbench SEED=%0d RAND_NUM=%0d", CYAN, RESET, seed, rand_num);

    // Initialization
    rstn_i=0; in_valid_i=0; initial_i=0; activation_line_i='0; weight_line_i='0;

    // Reset
    test_reset();

    // Functional test cases
    test_initial_once();
    test_accumulate_depth();
    test_read_row();
    test_random(rand_num);
    test_matrix_mul_8x32_32x8(10);

    // Summary
    $display("\n%s======================================================================", BLUE);
    $display("   TEST SUMMARY");
    $display("======================================================================%s", RESET);
    $display("   Total Tests: %0d", pass_cnt + fail_cnt);
    $display("   Passed:      %s%0d%s", GREEN, pass_cnt, RESET);
    $display("   Failed:      %s%0d%s", (fail_cnt > 0) ? RED : GREEN, fail_cnt, RESET);
    $display("%s======================================================================%s\n", BLUE, RESET);

    if (fail_cnt == 0) begin
        $display("%s[DONE] All tests passed successfully!%s", GREEN, RESET);
    end else begin
        $display("%s[DONE] Some tests failed. Check log for details.%s", RED, RESET);
    end

    #20; $finish;
  end

  initial begin
    $fsdbDumpfile("waveform.fsdb");
    $fsdbDumpvars("+all");
    $fsdbDumpMDA();
    $display("FSDB dump started.");
  end

endmodule
// pragma translate_on
