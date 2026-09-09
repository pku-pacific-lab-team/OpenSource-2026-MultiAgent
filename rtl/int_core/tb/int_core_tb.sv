// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
//////////////////////////////////////////////////////////////////////////////////
// Description: Testbench for INT Core Module
// Author:      Mingxuan Li <siris-lmx@stu.pku.edu.cn> [Peking University]
// Acknowledge: VSCode Copilot + Gemini-3-Pro Agent
//////////////////////////////////////////////////////////////////////////////////

// pragma translate_off
`timescale 1ns / 1ps

module int_core_tb;

  // Parameters
  localparam TILE             = 4;
  localparam AXI_ADDR_WIDTH   = 64;
  localparam AXI_DATA_WIDTH   = 64;
  localparam PE_MAX_ACCUM_NUM = 32;
  localparam PE_ARRAY_SIZE    = 8;
  localparam PE_DATA_WIDTH    = 4;
  localparam SF_DATA_WIDTH    = 8;
  localparam SF_BUCKET_WIDTH  = 12;
  localparam SF_ARRAY_SIZE    = 8;
  localparam SF_SPATTN_CNT_MAX = 128;

  // Addresses
  localparam logic [12-1:0] PE_WEIGHT_BASE_ADDR     = 12'h000;
  localparam logic [12-1:0] PE_ACTIVATION_BASE_ADDR = 12'h200;
  localparam logic [12-1:0] PE_RESULT_BASE_ADDR     = 12'h400;
  localparam logic [12-1:0] SF0_CURR_BASE_ADDR      = 12'h500;
  localparam logic [12-1:0] SF1_CURR_BASE_ADDR      = 12'h520;
  localparam logic [12-1:0] SF0_PRED_BASE_ADDR      = 12'h540;
  localparam logic [12-1:0] SF1_PRED_BASE_ADDR      = 12'h560;
  localparam logic [12-1:0] SF_RESULT_BASE_ADDR     = 12'h580;
  localparam logic [12-1:0] SIGN0_BASE_ADDR         = 12'h600;
  localparam logic [12-1:0] SIGN1_BASE_ADDR         = 12'h680;
  localparam logic [12-1:0] SUM_BUCKET_BASE_ADDR    = 12'h700;
  localparam logic [12-1:0] CTRL_STATUS_ADDR        = 12'hf00;

  // State Parameters
  localparam  PE_IDLE  = 0,
              PE_TILE0 = 1, PE_DMA0 = 2, PE_TILE1 = 3, PE_DMA1 = 4,
              PE_TILE2 = 5, PE_DMA2 = 6, PE_TILE3 = 7, PE_DMA3 = 8;
  localparam  SF_IDLE  = 0,
              SF_TILE0 = 1, SF_DMA0 = 2, SF_TILE1 = 3, SF_DMA1 = 4,
              SF_TILE2 = 5, SF_DMA2 = 6, SF_TILE3 = 7, SF_DMA3 = 8,
              SPATTN_COMPUTE = 9, SPATTN_DMA = 10;

  // Signals
  logic                       clk_i;
  logic                       rstn_i;

  // DMA Interface
  logic [AXI_ADDR_WIDTH-1:0]  dma_length_o;
  logic                       dma_run_o;
  logic                       dma_ready_i;
  logic                       dma_busy_i;

  // Memory Interface
  logic                       mem_req_i;
  logic                       mem_write_en_i;
  logic [AXI_ADDR_WIDTH-1:0]  mem_addr_i;
  logic [AXI_DATA_WIDTH-1:0]  mem_wdata_i;
  logic [AXI_DATA_WIDTH-1:0]  mem_rdata_o;

  // Statistics
  int pass_cnt = 0;
  int fail_cnt = 0;

  // Colors
  string GREEN = "\033[1;32m";
  string RED   = "\033[1;31m";
  string BLUE  = "\033[1;34m";
  string RESET = "\033[0m";

  // DUT Instantiation
  int_core #(
    .AXI_ADDR_WIDTH   (AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH   (AXI_DATA_WIDTH),
    .PE_MAX_ACCUM_NUM (PE_MAX_ACCUM_NUM),
    .PE_ARRAY_SIZE    (PE_ARRAY_SIZE),
    .PE_DATA_WIDTH    (PE_DATA_WIDTH),
    .SF_DATA_WIDTH    (SF_DATA_WIDTH),
    .SF_BUCKET_WIDTH  (SF_BUCKET_WIDTH),
    .SF_ARRAY_SIZE    (SF_ARRAY_SIZE),
    .SF_SPATTN_CNT_MAX(SF_SPATTN_CNT_MAX)
  ) dut (
    .clk_i            (clk_i),
    .rstn_i           (rstn_i),
    .dma_length_o     (dma_length_o),
    .dma_run_o        (dma_run_o),
    .dma_ready_i      (dma_ready_i),
    .dma_busy_i       (dma_busy_i),
    .mem_req_i        (mem_req_i),
    .mem_write_en_i   (mem_write_en_i),
    .mem_addr_i       (mem_addr_i),
    .mem_wdata_i      (mem_wdata_i),
    .mem_rdata_o      (mem_rdata_o)
  );

  // Clock Generation
  initial begin
    clk_i = 0;
    forever #5 clk_i = ~clk_i;
  end

  // Reset-aware DMA model. Complete only after request acceptance and a transfer delay.
  int dma_model_state=0,dma_delay=0,dma_transactions=0;
  always @(negedge clk_i) begin
    if(!rstn_i)begin
      dma_busy_i=0;dma_model_state=0;dma_delay=0;
    end else begin
      case(dma_model_state)
        0: if(dma_run_o)begin dma_busy_i=1;dma_model_state=1;end
        1: if(dma_ready_i)dma_model_state=2;
        2: if(!dma_ready_i)begin
             dma_delay=20+(dma_transactions%4)*7;dma_transactions++;
             dma_model_state=3;
           end
        3: if(dma_delay==0)begin dma_busy_i=0;dma_model_state=4;end
           else dma_delay--;
        4: if(!dma_run_o)dma_model_state=0;
      endcase
    end
  end

  // Data Structures for Verification
  logic signed [PE_DATA_WIDTH-1:0] weights [TILE][PE_MAX_ACCUM_NUM][PE_ARRAY_SIZE];
  logic signed [PE_DATA_WIDTH-1:0] activations [TILE][PE_MAX_ACCUM_NUM][PE_ARRAY_SIZE];
  logic signed [15:0] expected_results [TILE][PE_ARRAY_SIZE][PE_ARRAY_SIZE];

  logic [SF_DATA_WIDTH-1:0] sf0_curr [TILE][SF_ARRAY_SIZE];
  logic [SF_DATA_WIDTH-1:0] sf1_curr [TILE][SF_ARRAY_SIZE];
  logic [SF_DATA_WIDTH-1:0] expected_sf_results [TILE][SF_ARRAY_SIZE][SF_ARRAY_SIZE];
  logic [SF_DATA_WIDTH-1:0] actual_sf_results [SF_ARRAY_SIZE][SF_ARRAY_SIZE];

  logic [63:0] rdata;
  logic [63:0] wdata;
  logic [63:0] expected_wdata;
  int flat_idx, r, c;
  logic signed [15:0] actual [PE_ARRAY_SIZE][PE_ARRAY_SIZE];
  bit error_found;

  logic [63:0] status;

  int tile;

  // Helper Tasks
  task automatic print_banner(string title);
    $display("\n%s===============================================", BLUE);
    $display("   %s", title);
    $display("===============================================%s", RESET);
  endtask

  task automatic print_pass(string msg);
    pass_cnt++;
    $display("%s[PASS]%s %s", GREEN, RESET, msg);
  endtask

  task automatic print_fail(string msg);
    fail_cnt++;
    $display("%s[FAIL]%s %s", RED, RESET, msg);
  endtask

  task automatic mem_write(input logic [11:0] addr, input logic [63:0] data);
    @(posedge clk_i);
    #1;
    mem_req_i      = 1;
    mem_write_en_i = 1;
    mem_addr_i     = {52'b0, addr};
    mem_wdata_i    = data;
    @(posedge clk_i);
    #1;
    mem_req_i      = 0;
    mem_write_en_i = 0;
    mem_addr_i     = 0;
    mem_wdata_i    = 0;
  endtask

  task automatic mem_read(input logic [11:0] addr, output logic [63:0] data);
    @(posedge clk_i);
    #1;
    mem_req_i      = 1;
    mem_write_en_i = 0;
    mem_addr_i     = {52'b0, addr};
    @(posedge clk_i);
    // Read data is available in the next cycle (or same cycle depending on implementation)
    // In int_core.sv, it is combinational read (mem_rdata_d = ...), registered to mem_rdata_q.
    // So it takes 1 cycle latency.
    #1;
    mem_req_i      = 0;
    @(posedge clk_i); #1; // Request and response each have a register stage.
    data = mem_rdata_o;
  endtask

  task automatic dump_debug_info(int t, logic signed [15:0] actual_results [PE_ARRAY_SIZE][PE_ARRAY_SIZE]);
    $display("%s[DEBUG] Dumping Matrices due to error in Tile %0d...%s", "\033[1;33m", t, "\033[0m");

    // Print Matrix A (Activations)
    // A is [Rows x AccumSteps]
    // activations[t][acc][r] -> A[r][acc]
    $display("%s[DEBUG]%s Matrix A (Activations) [Rows x AccumSteps]:", "\033[1;36m", "\033[0m");
    for (int r = 0; r < PE_ARRAY_SIZE; r++) begin
        string line = "";
        for (int acc = 0; acc < PE_MAX_ACCUM_NUM; acc++) begin
            line = {line, $sformatf("%4d ", activations[t][acc][r])};
        end
        $display("%s", line);
    end

    // Print Matrix B (Weights)
    $display("%s[DEBUG]%s Matrix B (Weights) [AccumSteps x Cols]:", "\033[1;36m", "\033[0m");
    for (int acc = 0; acc < PE_MAX_ACCUM_NUM; acc++) begin
        string line = "";
        for (int c = 0; c < PE_ARRAY_SIZE; c++) begin
            line = {line, $sformatf("%4d ", weights[t][acc][c])};
        end
        $display("%s", line);
    end

    // Print Expected Result
    $display("%s[DEBUG]%s Expected Result Matrix:", "\033[1;36m", "\033[0m");
    for (int r = 0; r < PE_ARRAY_SIZE; r++) begin
        string line = "";
        for (int c = 0; c < PE_ARRAY_SIZE; c++) begin
            line = {line, $sformatf("%6d ", expected_results[t][r][c])};
        end
        $display("%s", line);
    end

    // Print Actual Result
    $display("%s[DEBUG]%s Actual Result Matrix:", "\033[1;36m", "\033[0m");
    for (int r = 0; r < PE_ARRAY_SIZE; r++) begin
        string line = "";
        for (int c = 0; c < PE_ARRAY_SIZE; c++) begin
            line = {line, $sformatf("%6d ", actual_results[r][c])};
        end
        $display("%s", line);
    end
  endtask

  task automatic dump_sf_debug_info(int t, logic [SF_DATA_WIDTH-1:0] actual_results [SF_ARRAY_SIZE][SF_ARRAY_SIZE]);
    $display("%s[DEBUG] Dumping SF Matrices due to error in Tile %0d...%s", "\033[1;33m", t, "\033[0m");

    // Print SF0
    $display("%s[DEBUG]%s SF0 (Rows):", "\033[1;36m", "\033[0m");
    begin
        string line = "";
        for (int i = 0; i < SF_ARRAY_SIZE; i++) begin
            line = {line, $sformatf("%4d ", sf0_curr[t][i])};
        end
        $display("%s", line);
    end

    // Print SF1
    $display("%s[DEBUG]%s SF1 (Cols):", "\033[1;36m", "\033[0m");
    begin
        string line = "";
        for (int i = 0; i < SF_ARRAY_SIZE; i++) begin
            line = {line, $sformatf("%4d ", sf1_curr[t][i])};
        end
        $display("%s", line);
    end

    // Print Expected Result
    $display("%s[DEBUG]%s Expected SF Result Matrix:", "\033[1;36m", "\033[0m");
    for (int r = 0; r < SF_ARRAY_SIZE; r++) begin
        string line = "";
        for (int c = 0; c < SF_ARRAY_SIZE; c++) begin
            line = {line, $sformatf("%4d ", expected_sf_results[t][r][c])};
        end
        $display("%s", line);
    end

    // Print Actual Result
    $display("%s[DEBUG]%s Actual SF Result Matrix:", "\033[1;36m", "\033[0m");
    for (int r = 0; r < SF_ARRAY_SIZE; r++) begin
        string line = "";
        for (int c = 0; c < SF_ARRAY_SIZE; c++) begin
            line = {line, $sformatf("%4d ", actual_results[r][c])};
        end
        $display("%s", line);
    end
  endtask

  // Main Test Sequence
  initial begin
    // Initialize signals
    rstn_i = 0;
    dma_ready_i = 0;
    mem_req_i = 0;
    mem_write_en_i = 0;
    mem_addr_i = 0;
    mem_wdata_i = 0;

    // Reset
    #100;
    rstn_i = 1;
    #20;
    check_reserved_registers();

    // =================================================================================================
    // PE Array Test
    // =================================================================================================
    for(int pe_case=0;pe_case<6;pe_case++)begin
    reset_dut();
    print_banner($sformatf("INT Core PE Array Test pattern=%0d",pe_case));

    // 1. Initialize Data
    $display("Initializing Weights and Activations...");
    for (int t = 0; t < TILE; t++) begin
      for (int acc = 0; acc < PE_MAX_ACCUM_NUM; acc++) begin
        for (int i = 0; i < PE_ARRAY_SIZE; i++) begin
          weights[t][acc][i] = pe_case==0 ? 4'($random) : pe_case==1 ? 0 : pe_case==2 ? 7 : pe_case==3 ? -8 : pe_case==4 ? 7 : ((i+acc)%2 ? -8 : 7);
          activations[t][acc][i] = pe_case==0 ? 4'($random) : pe_case==1 ? 0 : pe_case==2 ? 7 : pe_case==3 ? -8 : pe_case==4 ? -8 : ((i+acc)%2 ? 7 : -8);
        end
      end
    end

    // Calculate Expected Results
    for (int t = 0; t < TILE; t++) begin
      for (int r = 0; r < PE_ARRAY_SIZE; r++) begin
        for (int c = 0; c < PE_ARRAY_SIZE; c++) begin
          expected_results[t][r][c] = 0;
          for (int acc = 0; acc < PE_MAX_ACCUM_NUM; acc++) begin
             // PE(r, c) uses activation[r] and weight[c]
             expected_results[t][r][c] += activations[t][acc][r] * weights[t][acc][c];
          end
        end
      end
    end

    // 2. Write to Registers
    $display("Writing to PE Array Registers...");

    // Write Weights
    begin
      automatic int addr_offset = 0;
      int steps_per_word = AXI_DATA_WIDTH / (PE_ARRAY_SIZE * PE_DATA_WIDTH);

      for (int t = 0; t < TILE; t++) begin
        for (int acc = 0; acc < PE_MAX_ACCUM_NUM; acc += steps_per_word) begin
          wdata = 0;
          for (int s = 0; s < steps_per_word; s++) begin
             if (acc + s < PE_MAX_ACCUM_NUM) begin
               for (int i = 0; i < PE_ARRAY_SIZE; i++) begin
                  wdata[(s * PE_ARRAY_SIZE * PE_DATA_WIDTH) + (i * PE_DATA_WIDTH) +: PE_DATA_WIDTH] = weights[t][acc+s][i];
               end
             end
          end
          mem_write(PE_WEIGHT_BASE_ADDR + addr_offset, wdata);
          addr_offset += (AXI_DATA_WIDTH / 8);
        end
      end
    end

    // Write Activations
    begin
      automatic int addr_offset = 0;
      int steps_per_word = AXI_DATA_WIDTH / (PE_ARRAY_SIZE * PE_DATA_WIDTH);

      for (int t = 0; t < TILE; t++) begin
        for (int acc = 0; acc < PE_MAX_ACCUM_NUM; acc += steps_per_word) begin
          wdata = 0;
          for (int s = 0; s < steps_per_word; s++) begin
             if (acc + s < PE_MAX_ACCUM_NUM) begin
               for (int i = 0; i < PE_ARRAY_SIZE; i++) begin
                  wdata[(s * PE_ARRAY_SIZE * PE_DATA_WIDTH) + (i * PE_DATA_WIDTH) +: PE_DATA_WIDTH] = activations[t][acc+s][i];
               end
             end
          end
          mem_write(PE_ACTIVATION_BASE_ADDR + addr_offset, wdata);
          addr_offset += (AXI_DATA_WIDTH / 8);
        end
      end
    end

    // Verify Readback
    $display("Verifying Register Readback...");

    // Reconstruct the expected data for the first weight word
    expected_wdata = 0;
    begin
      int steps_per_word = AXI_DATA_WIDTH / (PE_ARRAY_SIZE * PE_DATA_WIDTH);
      for (int s = 0; s < steps_per_word; s++) begin
         if (s < PE_MAX_ACCUM_NUM) begin
           for (int i = 0; i < PE_ARRAY_SIZE; i++) begin
              expected_wdata[(s * PE_ARRAY_SIZE * PE_DATA_WIDTH) + (i * PE_DATA_WIDTH) +: PE_DATA_WIDTH] = weights[0][s][i];
           end
         end
      end
    end

    mem_read(PE_WEIGHT_BASE_ADDR, rdata);

    if (rdata !== expected_wdata) begin
        print_fail($sformatf("Readback Mismatch at Address %h. Expected %h, Got %h", PE_WEIGHT_BASE_ADDR, expected_wdata, rdata));
    end else begin
        print_pass("Register Readback Verified");
    end

    // 3. Start Computation
    $display("Starting Computation...");
    // Write to CTRL_STATUS_ADDR: pe_enable=1 (bit 0)
    mem_write(CTRL_STATUS_ADDR, 64'h1);

    // 4. Verify Results for Each Tile
    for (int t = 0; t < TILE; t++) begin
        error_found = 0;
        $display("Waiting for Tile %0d completion...", t);

        // Wait for DMA request (dma_run_o == 1)
        wait(dma_run_o == 1);

        // Now in PE_DMAx state, result should be stable
        $display("Verifying Tile %0d Results...", t);

        // Read Results
        begin
            int words_to_read = (PE_ARRAY_SIZE * PE_ARRAY_SIZE * 2) / (AXI_DATA_WIDTH / 8);
            int results_per_word = AXI_DATA_WIDTH / 16; // 16-bit results

            for (int word_idx = 0; word_idx < words_to_read; word_idx++) begin
                mem_read(PE_RESULT_BASE_ADDR + word_idx * 8, rdata);

                // Verify results in this word
                for (int k = 0; k < results_per_word; k++) begin
                    flat_idx = word_idx * results_per_word + k;
                    r = flat_idx / PE_ARRAY_SIZE;
                    c = flat_idx % PE_ARRAY_SIZE;

                    actual[r][c] = rdata[k*16 +: 16];

                    if (actual[r][c] !== expected_results[t][r][c]) begin
                        error_found = 1;
                        print_fail($sformatf("Tile %0d PE(%0d,%0d): Expected %5d, Got %5d", t, r, c, expected_results[t][r][c], actual[r][c]));
                    end
                end
            end
        end

        if (error_found) begin
            dump_debug_info(t, actual);
            break;
        end

        // Proceed to next tile
        @(posedge clk_i);
        #1;
        dma_ready_i = 1;
        @(posedge clk_i);
        #1;
        dma_ready_i = 0;

        // Wait for dma_run_o to deassert (it might happen quickly)
        wait(dma_run_o == 0);
    end

    // 5. Check Idle Status
    $display("Checking Idle Status...");
    // Wait for final DMA to finish (Tile 3)
    // The loop above handles Tile 3 DMA.
    // After Tile 3 DMA, it goes to IDLE (if run_mode=0).
    // We need to wait for dma_busy_i to deassert
    wait(dma_busy_i == 0);
    #10; // Small margin

    mem_read(CTRL_STATUS_ADDR, status);
    // Status: { 10'b0, run_mode_q, 1'b0, spattn_finish_q, sf_finish_q, pe_finish_q, ... }
    // pe_finish_q is bit 48
    $display("Status Register: %h", status);
    if (status[48] == 0) begin
          print_fail("PE Finish Flag is 0 after execution");
    end else begin
          print_pass("PE Finish Flag is 1");
    end

    if (status[15:0] == 0) begin
          print_fail("PE Cycle Count is 0 after execution");
    end else begin
          print_pass("PE Cycle Count is non-zero");
    end

    if (fail_cnt == 0) begin
        print_pass("All tests passed!");
    end else begin
        print_fail($sformatf("%0d tests failed.", fail_cnt));
    end

    // =================================================================================================
    // SF Array Test (SF Only Mode)
    // =================================================================================================
    end // Six PE input patterns, all four tiles checked.
    print_banner("INT Core SF Array Test (SF Only Mode)");

    // 1. Initialize Data
    $display("Initializing SF Data...");
    for (int t = 0; t < TILE; t++) begin
      for (int i = 0; i < SF_ARRAY_SIZE; i++) begin
        sf0_curr[t][i] = $random;
        sf1_curr[t][i] = $random;
      end
    end

    // Calculate Expected Results
    for (int t = 0; t < TILE; t++) begin
      for (int r = 0; r < SF_ARRAY_SIZE; r++) begin
        for (int c = 0; c < SF_ARRAY_SIZE; c++) begin
          expected_sf_results[t][r][c] = sf0_curr[t][r] + sf1_curr[t][c];
        end
      end
    end

    // 2. Write to Registers
    $display("Writing to SF Array Registers...");

    // Write SF0
    begin
      automatic int addr_offset = 0;
      int steps_per_word = AXI_DATA_WIDTH / (SF_ARRAY_SIZE * SF_DATA_WIDTH); // 64 / (8*8) = 1

      for (int t = 0; t < TILE; t++) begin
          wdata = 0;
          for (int i = 0; i < SF_ARRAY_SIZE; i++) begin
             wdata[(i * SF_DATA_WIDTH) +: SF_DATA_WIDTH] = sf0_curr[t][i];
          end
          mem_write(SF0_CURR_BASE_ADDR + addr_offset, wdata);
          addr_offset += (AXI_DATA_WIDTH / 8);
      end
    end

    // Write SF1
    begin
      automatic int addr_offset = 0;
      int steps_per_word = AXI_DATA_WIDTH / (SF_ARRAY_SIZE * SF_DATA_WIDTH); // 64 / (8*8) = 1

      for (int t = 0; t < TILE; t++) begin
          wdata = 0;
          for (int i = 0; i < SF_ARRAY_SIZE; i++) begin
             wdata[(i * SF_DATA_WIDTH) +: SF_DATA_WIDTH] = sf1_curr[t][i];
          end
          mem_write(SF1_CURR_BASE_ADDR + addr_offset, wdata);
          addr_offset += (AXI_DATA_WIDTH / 8);
      end
    end

    // Verify SF Readback
    $display("Verifying SF Register Readback...");

    // Reconstruct the expected data for the first SF0 word
    expected_wdata = 0;
    begin
      for (int i = 0; i < SF_ARRAY_SIZE; i++) begin
         expected_wdata[(i * SF_DATA_WIDTH) +: SF_DATA_WIDTH] = sf0_curr[0][i];
      end
    end

    mem_read(SF0_CURR_BASE_ADDR, rdata);

    if (rdata !== expected_wdata) begin
        print_fail($sformatf("SF0 Readback Mismatch at Address %h. Expected %h, Got %h", SF0_CURR_BASE_ADDR, expected_wdata, rdata));
    end else begin
        print_pass("SF0 Register Readback Verified");
    end

    // Reconstruct the expected data for the first SF1 word
    expected_wdata = 0;
    begin
      for (int i = 0; i < SF_ARRAY_SIZE; i++) begin
         expected_wdata[(i * SF_DATA_WIDTH) +: SF_DATA_WIDTH] = sf1_curr[0][i];
      end
    end

    mem_read(SF1_CURR_BASE_ADDR, rdata);

    if (rdata !== expected_wdata) begin
        print_fail($sformatf("SF1 Readback Mismatch at Address %h. Expected %h, Got %h", SF1_CURR_BASE_ADDR, expected_wdata, rdata));
    end else begin
        print_pass("SF1 Register Readback Verified");
    end

    // 3. Start Computation (SF Only Mode)
    $display("Starting SF Computation...");
    // Write to CTRL_STATUS_ADDR: sf_enable=1 (bit 1), pe_enable=0, spattn_enable=0
    mem_write(CTRL_STATUS_ADDR, 64'h2);

    // 4. Verify Results for Each Tile
    for (int t = 0; t < TILE; t++) begin
        error_found = 0;
        $display("Waiting for SF Tile %0d completion...", t);

        // Wait for DMA request (dma_run_o == 1)
        wait(dma_run_o == 1);

        // Now in SF_DMAx state, result should be stable
        $display("Verifying SF Tile %0d Results...", t);

        // Read Results
        begin
            int words_to_read = (SF_ARRAY_SIZE * SF_ARRAY_SIZE * SF_DATA_WIDTH) / AXI_DATA_WIDTH; // (8*8*8)/64 = 8 words
            int results_per_word = AXI_DATA_WIDTH / SF_DATA_WIDTH; // 64/8 = 8 results

            for (int word_idx = 0; word_idx < words_to_read; word_idx++) begin
                mem_read(SF_RESULT_BASE_ADDR + word_idx * 8, rdata);

                // Verify results in this word
                for (int k = 0; k < results_per_word; k++) begin
                    flat_idx = word_idx * results_per_word + k;
                    r = flat_idx / SF_ARRAY_SIZE;
                    c = flat_idx % SF_ARRAY_SIZE;

                    actual_sf_results[r][c] = rdata[k*SF_DATA_WIDTH +: SF_DATA_WIDTH];

                    if (actual_sf_results[r][c] !== expected_sf_results[t][r][c]) begin
                        error_found = 1;
                        print_fail($sformatf("SF Tile %0d (%0d,%0d): Expected %d, Got %d", t, r, c, expected_sf_results[t][r][c], actual_sf_results[r][c]));
                    end
                end
            end
        end

        if (error_found) begin
            dump_sf_debug_info(t, actual_sf_results);
            break;
        end

        // Proceed to next tile
        @(posedge clk_i);
        #1;
        dma_ready_i = 1;
        @(posedge clk_i);
        #1;
        dma_ready_i = 0;

        // Wait for dma_run_o to deassert
        wait(dma_run_o == 0);
    end

    // 5. Check Idle Status
    $display("Checking SF Idle Status...");
    wait(dma_busy_i == 0);
    #10;

    mem_read(CTRL_STATUS_ADDR, status);
    // Status: { 10'b0, run_mode_q, 1'b0, spattn_finish_q, sf_finish_q, pe_finish_q, ... }
    // sf_finish_q is bit 49
    $display("Status Register: %h", status);
    if (status[49] == 0) begin
          print_fail("SF Finish Flag is 0 after execution");
    end else begin
          print_pass("SF Finish Flag is 1");
    end

    if (fail_cnt == 0) begin
        print_pass("All SF tests passed!");
    end else begin
        print_fail($sformatf("%0d SF tests failed.", fail_cnt));
    end

    // =================================================================================================
    // SpAttn Test (SpAttn Only Mode)
    // =================================================================================================
    print_banner("INT Core SpAttn Test (SpAttn Only Mode)");

    begin
      logic [SF_DATA_WIDTH-1:0] sf0_pred [SF_SPATTN_CNT_MAX][SF_ARRAY_SIZE];
      logic [SF_DATA_WIDTH-1:0] sf1_pred [SF_SPATTN_CNT_MAX][SF_ARRAY_SIZE];
      logic                     sign0    [SF_SPATTN_CNT_MAX][SF_ARRAY_SIZE];
      logic                     sign1    [SF_SPATTN_CNT_MAX][SF_ARRAY_SIZE];
      logic signed [31:0]       expected_buckets [4];
      logic signed [31:0]       actual_buckets [4];
      logic [5:0]               signed_sf;
      logic [2:0]               bucket_sel;
      logic [31:0]              val;
      logic                     op;

      // 1. Initialize Data
      $display("Initializing SpAttn Data...");
      for (int t = 0; t < SF_SPATTN_CNT_MAX; t++) begin
        for (int i = 0; i < SF_ARRAY_SIZE; i++) begin
          sf0_pred[t][i] = $random;
          sf1_pred[t][i] = $random;
          sign0[t][i]    = $random;
          sign1[t][i]    = $random;
        end
      end

      // Calculate Expected Results
      expected_buckets = '{0, 0, 0, 0};
      for (int t = 0; t < SF_SPATTN_CNT_MAX; t++) begin
        for (int r = 0; r < SF_ARRAY_SIZE; r++) begin
          for (int c = 0; c < SF_ARRAY_SIZE; c++) begin
            logic [SF_DATA_WIDTH-1:0] exp;
            logic                     s;

            // RTL reuses SF data for 32 cycles (TILE=4, Total=128)
            exp = sf0_pred[(t/32)*32][r] + sf1_pred[(t/32)*32][c];
            s   = sign0[t][r] ^ sign1[t][c];

            // SF_WIDTH is 6, so we take 5 bits of exponent + sign bit
            signed_sf = {s, exp[4:0]};
            bucket_sel = signed_sf[4:2];
            val        = 1 << signed_sf[1:0];
            op         = signed_sf[5]; // 1 for subtract, 0 for add

            case (bucket_sel)
              3'b000: expected_buckets[0] += op ? -val : val;
              3'b001: expected_buckets[1] += op ? -val : val;
              3'b110: expected_buckets[2] += op ? -val : val;
              3'b111: expected_buckets[3] += op ? -val : val;
              default: ;
            endcase
          end
        end
      end

      // 2. Write to Registers
      $display("Writing to SpAttn Registers...");

      // Write SF0 Pred (Only 4 words)
      for (int t = 0; t < TILE; t++) begin
        wdata = 0;
        for (int i = 0; i < SF_ARRAY_SIZE; i++) begin
            wdata[(i * SF_DATA_WIDTH) +: SF_DATA_WIDTH] = sf0_pred[t*32][i]; // Use t*32 as representative
        end
        mem_write(SF0_PRED_BASE_ADDR + t*8, wdata);
      end

      // Write SF1 Pred (Only 4 words)
      for (int t = 0; t < TILE; t++) begin
        wdata = 0;
        for (int i = 0; i < SF_ARRAY_SIZE; i++) begin
            wdata[(i * SF_DATA_WIDTH) +: SF_DATA_WIDTH] = sf1_pred[t*32][i];
        end
        mem_write(SF1_PRED_BASE_ADDR + t*8, wdata);
      end

      // Write Signs (16 words)
      for (int w = 0; w < 16; w++) begin
        wdata = 0;
        for (int b = 0; b < 8; b++) begin
            tile = w * 8 + b;
            for (int i = 0; i < SF_ARRAY_SIZE; i++) begin
              wdata[b*8 + i] = sign0[tile][i]; // Bit packing
            end
        end
        mem_write(SIGN0_BASE_ADDR + w*8, wdata);
      end

      for (int w = 0; w < 16; w++) begin
        wdata = 0;
        for (int b = 0; b < 8; b++) begin
            tile = w * 8 + b;
            for (int i = 0; i < SF_ARRAY_SIZE; i++) begin
              wdata[b*8 + i] = sign1[tile][i];
            end
        end
        mem_write(SIGN1_BASE_ADDR + w*8, wdata);
      end

      // Verify SpAttn Register Readback
      $display("Verifying SpAttn Register Readback...");

      // Verify SF0 Pred Readback
      for (int t = 0; t < TILE; t++) begin
          expected_wdata = 0;
          for (int i = 0; i < SF_ARRAY_SIZE; i++) begin
            expected_wdata[(i * SF_DATA_WIDTH) +: SF_DATA_WIDTH] = sf0_pred[t*32][i];
          end
          mem_read(SF0_PRED_BASE_ADDR + t*8, rdata);
          if (rdata !== expected_wdata) begin
              print_fail($sformatf("SF0 Pred Readback Mismatch at offset %0d. Expected %h, Got %h", t*8, expected_wdata, rdata));
          end
      end
      print_pass("SF0 Pred Register Readback Verified");

      // Verify SF1 Pred Readback
      for (int t = 0; t < TILE; t++) begin
          expected_wdata = 0;
          for (int i = 0; i < SF_ARRAY_SIZE; i++) begin
            expected_wdata[(i * SF_DATA_WIDTH) +: SF_DATA_WIDTH] = sf1_pred[t*32][i];
          end
          mem_read(SF1_PRED_BASE_ADDR + t*8, rdata);
          if (rdata !== expected_wdata) begin
              print_fail($sformatf("SF1 Pred Readback Mismatch at offset %0d. Expected %h, Got %h", t*8, expected_wdata, rdata));
          end
      end
      print_pass("SF1 Pred Register Readback Verified");

      // Verify Sign0 Readback
      for (int w = 0; w < 16; w++) begin
          expected_wdata = 0;
          for (int b = 0; b < 8; b++) begin
            tile = w * 8 + b;
            for (int i = 0; i < SF_ARRAY_SIZE; i++) begin
                expected_wdata[b*8 + i] = sign0[tile][i];
            end
          end
          mem_read(SIGN0_BASE_ADDR + w*8, rdata);
          if (rdata !== expected_wdata) begin
              print_fail($sformatf("Sign0 Readback Mismatch at offset %0d. Expected %h, Got %h", w*8, expected_wdata, rdata));
          end
      end
      print_pass("Sign0 Register Readback Verified");

      // Verify Sign1 Readback
      for (int w = 0; w < 16; w++) begin
          expected_wdata = 0;
          for (int b = 0; b < 8; b++) begin
            tile = w * 8 + b;
            for (int i = 0; i < SF_ARRAY_SIZE; i++) begin
                expected_wdata[b*8 + i] = sign1[tile][i];
            end
          end
          mem_read(SIGN1_BASE_ADDR + w*8, rdata);
          if (rdata !== expected_wdata) begin
              print_fail($sformatf("Sign1 Readback Mismatch at offset %0d. Expected %h, Got %h", w*8, expected_wdata, rdata));
          end
      end
      print_pass("Sign1 Register Readback Verified");

      // 3. Start Computation
      $display("Starting SpAttn Computation...");
      mem_write(CTRL_STATUS_ADDR, 64'h4); // spattn_enable=1

      // 4. Wait for Completion
      $display("Waiting for SpAttn completion...");
      wait(dma_run_o == 1);

      // 5. Verify Results
      $display("Verifying SpAttn Results... cnt=%d bucket0=%d sum=%h",dut.spattn_cycle_cnt_q,dut.sf_array_inst.row[0].col[0].sf_inst.bucket_3b000_q,dut.sum_bucket_buffer_aligned);

      // Read first word (Buckets 0 and 1)
      mem_read(SUM_BUCKET_BASE_ADDR, rdata);
      actual_buckets[0] = rdata[31:0];
      actual_buckets[1] = rdata[63:32];

      // Read second word (Buckets 2 and 3)
      mem_read(SUM_BUCKET_BASE_ADDR + 8, rdata);
      actual_buckets[2] = rdata[31:0];
      actual_buckets[3] = rdata[63:32];

      for (int i = 0; i < 4; i++) begin
         if (actual_buckets[i] !== expected_buckets[i]) begin
             print_fail($sformatf("SpAttn Bucket %0d Mismatch. Expected %d, Got %d", i, expected_buckets[i], actual_buckets[i]));
         end else begin
             print_pass($sformatf("SpAttn Bucket %0d Verified", i));
         end
      end

      // 6. Handshake DMA
      @(posedge clk_i);
      #1;
      dma_ready_i = 1;
      @(posedge clk_i);
      #1;
      dma_ready_i = 0;
      wait(dma_run_o == 0);

      // 7. Check Status
      wait(dma_busy_i == 0);
      #10;
      mem_read(CTRL_STATUS_ADDR, status);
      // spattn_finish_q is bit 50
      if (status[50] == 0) begin
            print_fail("SpAttn Finish Flag is 0 after execution");
      end else begin
            print_pass("SpAttn Finish Flag is 1");
      end
    end

    // =================================================================================================
    // Combined SF & SpAttn Test
    // =================================================================================================
    print_banner("INT Core Combined SF & SpAttn Test");

    begin
      // Re-declare local variables for SpAttn part (SF part uses globals)
      logic [SF_DATA_WIDTH-1:0] sf0_pred [SF_SPATTN_CNT_MAX][SF_ARRAY_SIZE];
      logic [SF_DATA_WIDTH-1:0] sf1_pred [SF_SPATTN_CNT_MAX][SF_ARRAY_SIZE];
      logic                     sign0    [SF_SPATTN_CNT_MAX][SF_ARRAY_SIZE];
      logic                     sign1    [SF_SPATTN_CNT_MAX][SF_ARRAY_SIZE];
      logic signed [31:0]       expected_buckets [4];
      logic signed [31:0]       actual_buckets [4];
      logic [5:0]               signed_sf;
      logic [2:0]               bucket_sel;
      logic [31:0]              val;
      logic                     op;
      logic [SF_DATA_WIDTH-1:0] exp;
      logic                     s;

      // 1. Initialize Data
      $display("Initializing Combined Test Data...");

      // SF Data
      for (int t = 0; t < TILE; t++) begin
        for (int i = 0; i < SF_ARRAY_SIZE; i++) begin
          sf0_curr[t][i] = $random;
          sf1_curr[t][i] = $random;
        end
      end

      // SpAttn Data
      for (int t = 0; t < SF_SPATTN_CNT_MAX; t++) begin
        for (int i = 0; i < SF_ARRAY_SIZE; i++) begin
          sf0_pred[t][i] = $random;
          sf1_pred[t][i] = $random;
          sign0[t][i]    = $random;
          sign1[t][i]    = $random;
        end
      end

      // Calculate Expected Results (SF)
      for (int t = 0; t < TILE; t++) begin
        for (int r = 0; r < SF_ARRAY_SIZE; r++) begin
          for (int c = 0; c < SF_ARRAY_SIZE; c++) begin
            expected_sf_results[t][r][c] = sf0_curr[t][r] + sf1_curr[t][c];
          end
        end
      end

      // Calculate Expected Results (SpAttn)
      expected_buckets = '{0, 0, 0, 0};
      for (int t = 0; t < SF_SPATTN_CNT_MAX; t++) begin
        for (int r = 0; r < SF_ARRAY_SIZE; r++) begin
          for (int c = 0; c < SF_ARRAY_SIZE; c++) begin
            exp = sf0_pred[(t/32)*32][r] + sf1_pred[(t/32)*32][c];
            s   = sign0[t][r] ^ sign1[t][c];
            signed_sf = {s, exp[4:0]};
            bucket_sel = signed_sf[4:2];
            val        = 1 << signed_sf[1:0];
            op         = signed_sf[5];
            case (bucket_sel)
              3'b000: expected_buckets[0] += op ? -val : val;
              3'b001: expected_buckets[1] += op ? -val : val;
              3'b110: expected_buckets[2] += op ? -val : val;
              3'b111: expected_buckets[3] += op ? -val : val;
              default: ;
            endcase
          end
        end
      end

      // 2. Write to Registers
      $display("Writing to Registers...");

      // Write SF0 Curr
      for (int t = 0; t < TILE; t++) begin
          wdata = 0;
          for (int i = 0; i < SF_ARRAY_SIZE; i++) begin
             wdata[(i * SF_DATA_WIDTH) +: SF_DATA_WIDTH] = sf0_curr[t][i];
          end
          mem_write(SF0_CURR_BASE_ADDR + t*8, wdata);
      end

      // Write SF1 Curr
      for (int t = 0; t < TILE; t++) begin
          wdata = 0;
          for (int i = 0; i < SF_ARRAY_SIZE; i++) begin
             wdata[(i * SF_DATA_WIDTH) +: SF_DATA_WIDTH] = sf1_curr[t][i];
          end
          mem_write(SF1_CURR_BASE_ADDR + t*8, wdata);
      end

      // Write SF0 Pred
      for (int t = 0; t < TILE; t++) begin
          wdata = 0;
          for (int i = 0; i < SF_ARRAY_SIZE; i++) begin
             wdata[(i * SF_DATA_WIDTH) +: SF_DATA_WIDTH] = sf0_pred[t*32][i];
          end
          mem_write(SF0_PRED_BASE_ADDR + t*8, wdata);
      end

      // Write SF1 Pred
      for (int t = 0; t < TILE; t++) begin
          wdata = 0;
          for (int i = 0; i < SF_ARRAY_SIZE; i++) begin
             wdata[(i * SF_DATA_WIDTH) +: SF_DATA_WIDTH] = sf1_pred[t*32][i];
          end
          mem_write(SF1_PRED_BASE_ADDR + t*8, wdata);
      end

      // Write Signs
      for (int w = 0; w < 16; w++) begin
          wdata = 0;
          for (int b = 0; b < 8; b++) begin
             tile = w * 8 + b;
             for (int i = 0; i < SF_ARRAY_SIZE; i++) begin
                wdata[b*8 + i] = sign0[tile][i];
             end
          end
          mem_write(SIGN0_BASE_ADDR + w*8, wdata);
      end
      for (int w = 0; w < 16; w++) begin
          wdata = 0;
          for (int b = 0; b < 8; b++) begin
             tile = w * 8 + b;
             for (int i = 0; i < SF_ARRAY_SIZE; i++) begin
                wdata[b*8 + i] = sign1[tile][i];
             end
          end
          mem_write(SIGN1_BASE_ADDR + w*8, wdata);
      end

      // 3. Start Computation
      $display("Starting Combined Computation...");
      mem_write(CTRL_STATUS_ADDR, 64'h6); // sf_enable=1, spattn_enable=1

      // 4. Verify SF Results (4 Tiles)
      for (int t = 0; t < TILE; t++) begin
          error_found = 0;
          $display("Waiting for SF Tile %0d completion...", t);
          wait(dma_run_o == 1);

          // Read Results
          for (int word_idx = 0; word_idx < 8; word_idx++) begin
              mem_read(SF_RESULT_BASE_ADDR + word_idx * 8, rdata);
              for (int k = 0; k < 8; k++) begin
                  flat_idx = word_idx * 8 + k;
                  r = flat_idx / SF_ARRAY_SIZE;
                  c = flat_idx % SF_ARRAY_SIZE;
                  actual_sf_results[r][c] = rdata[k*SF_DATA_WIDTH +: SF_DATA_WIDTH];
                  if (actual_sf_results[r][c] !== expected_sf_results[t][r][c]) begin
                      error_found = 1;
                      print_fail($sformatf("SF Tile %0d (%0d,%0d): Expected %d, Got %d", t, r, c, expected_sf_results[t][r][c], actual_sf_results[r][c]));
                  end
              end
          end

          if (error_found) dump_sf_debug_info(t, actual_sf_results);

          // Handshake
          @(posedge clk_i); #1; dma_ready_i = 1;
          @(posedge clk_i); #1; dma_ready_i = 0;
          wait(dma_run_o == 0);
      end

      // 5. Verify SpAttn Results
      $display("Waiting for SpAttn completion...");
      wait(dma_run_o == 1);

      mem_read(SUM_BUCKET_BASE_ADDR, rdata);
      actual_buckets[0] = rdata[31:0];
      actual_buckets[1] = rdata[63:32];
      mem_read(SUM_BUCKET_BASE_ADDR + 8, rdata);
      actual_buckets[2] = rdata[31:0];
      actual_buckets[3] = rdata[63:32];

      for (int i = 0; i < 4; i++) begin
         if (actual_buckets[i] !== expected_buckets[i]) begin
             print_fail($sformatf("SpAttn Bucket %0d Mismatch. Expected %d, Got %d", i, expected_buckets[i], actual_buckets[i]));
         end else begin
             print_pass($sformatf("SpAttn Bucket %0d Verified", i));
         end
      end

      // Handshake
      @(posedge clk_i); #1; dma_ready_i = 1;
      @(posedge clk_i); #1; dma_ready_i = 0;
      wait(dma_run_o == 0);

      // 6. Check Status
      wait(dma_busy_i == 0);
      #10;
      mem_read(CTRL_STATUS_ADDR, status);
      if (status[49] == 0) print_fail("SF Finish Flag is 0");
      else print_pass("SF Finish Flag is 1");
      if (status[50] == 0) print_fail("SpAttn Finish Flag is 0");
      else print_pass("SpAttn Finish Flag is 1");
    end

    // =================================================================================================
    // Power Mode Test
    // =================================================================================================
    #100 verify_power_mode(1, "COMPUTE_PWR");
    #100 verify_power_mode(2, "DMA_PWR");
    #100 verify_power_mode(3, "ALL_PWR");

    if (fail_cnt == 0) begin
        print_pass("All tests passed!");
    end else begin
        print_fail($sformatf("%0d tests failed.", fail_cnt));
    end

    if (fail_cnt != 0) $fatal(1,"[FAIL] INT regression failures=%0d",fail_cnt);
    $display("[PASS] INT full regression checks=%0d",pass_cnt);
    $finish;
  end

  task automatic reset_dut();
    rstn_i = 0;
    #20;
    rstn_i = 1;
    #20;
  endtask

  task automatic do_dma_handshake();
    wait(dma_run_o == 1);
    @(posedge clk_i); #1; dma_ready_i = 1;
    @(posedge clk_i); #1; dma_ready_i = 0;
    wait(dma_run_o == 0);
  endtask

  task automatic verify_power_mode(input logic [2:0] mode, input string mode_name);
    print_banner({"Power Mode Test: ", mode_name});

    // 1. PE Test
    $display("  Testing PE Loop...");
    reset_dut();
    mem_write(CTRL_STATUS_ADDR, ((64'(mode)<<8)|1)); // pe_enable=1

    if (mode == 1) begin // COMPUTE_PWR
        // Expect: IDLE -> TILE0 -> TILE1 -> ... -> TILE3 -> TILE0
        wait(dut.pe_state_q == PE_TILE0);
        wait(dut.pe_state_q == PE_TILE1);
        wait(dut.pe_state_q == PE_TILE2);
        wait(dut.pe_state_q == PE_TILE3);
        wait(dut.pe_state_q == PE_TILE0);
        wait(dut.pe_state_q == PE_TILE1);
        wait(dut.pe_state_q == PE_TILE2);
        wait(dut.pe_state_q == PE_TILE3);
        print_pass("PE Compute Loop Verified");
    end else if (mode == 2) begin // DMA_PWR
        // Expect: IDLE -> DMA0 -> DMA1 -> ... -> DMA3 -> DMA0
        wait(dut.pe_state_q == PE_DMA0); do_dma_handshake();
        wait(dut.pe_state_q == PE_DMA1); do_dma_handshake();
        wait(dut.pe_state_q == PE_DMA2); do_dma_handshake();
        wait(dut.pe_state_q == PE_DMA3); do_dma_handshake();
        wait(dut.pe_state_q == PE_DMA0); do_dma_handshake();
        wait(dut.pe_state_q == PE_DMA1); do_dma_handshake();
        wait(dut.pe_state_q == PE_DMA2); do_dma_handshake();
        wait(dut.pe_state_q == PE_DMA3); do_dma_handshake();
        print_pass("PE DMA Loop Verified");
    end else if (mode == 3) begin // ALL_PWR
        // Expect: IDLE -> TILE0 -> DMA0 -> ...
        wait(dut.pe_state_q == PE_TILE0);
        wait(dut.pe_state_q == PE_DMA0); do_dma_handshake();
        wait(dut.pe_state_q == PE_TILE1);
        wait(dut.pe_state_q == PE_DMA1); do_dma_handshake();
        wait(dut.pe_state_q == PE_TILE2);
        wait(dut.pe_state_q == PE_DMA2); do_dma_handshake();
        wait(dut.pe_state_q == PE_TILE3);
        wait(dut.pe_state_q == PE_DMA3); do_dma_handshake();
        wait(dut.pe_state_q == PE_TILE0);
        wait(dut.pe_state_q == PE_DMA0); do_dma_handshake();
        wait(dut.pe_state_q == PE_TILE1);
        wait(dut.pe_state_q == PE_DMA1); do_dma_handshake();
        wait(dut.pe_state_q == PE_TILE2);
        wait(dut.pe_state_q == PE_DMA2); do_dma_handshake();
        wait(dut.pe_state_q == PE_TILE3);
        wait(dut.pe_state_q == PE_DMA3); do_dma_handshake();
        print_pass("PE All Power Loop Verified");
    end

    // 2. SF Test
    $display("  Testing SF Loop...");
    reset_dut();
    mem_write(CTRL_STATUS_ADDR, ((64'(mode)<<8)|2)); // sf_enable=1

    if (mode == 1) begin // COMPUTE_PWR
        wait(dut.sf_state_q == SF_TILE0);
        wait(dut.sf_state_q == SF_TILE1);
        wait(dut.sf_state_q == SF_TILE2);
        wait(dut.sf_state_q == SF_TILE3);
        wait(dut.sf_state_q == SF_TILE0);
        wait(dut.sf_state_q == SF_TILE1);
        wait(dut.sf_state_q == SF_TILE2);
        wait(dut.sf_state_q == SF_TILE3);
        print_pass("SF Compute Loop Verified");
    end else if (mode == 2) begin // DMA_PWR
        wait(dut.sf_state_q == SF_DMA0); do_dma_handshake();
        wait(dut.sf_state_q == SF_DMA1); do_dma_handshake();
        wait(dut.sf_state_q == SF_DMA2); do_dma_handshake();
        wait(dut.sf_state_q == SF_DMA3); do_dma_handshake();
        wait(dut.sf_state_q == SF_DMA0); do_dma_handshake();
        wait(dut.sf_state_q == SF_DMA1); do_dma_handshake();
        wait(dut.sf_state_q == SF_DMA2); do_dma_handshake();
        wait(dut.sf_state_q == SF_DMA3); do_dma_handshake();
        print_pass("SF DMA Loop Verified");
    end else if (mode == 3) begin // ALL_PWR
        wait(dut.sf_state_q == SF_TILE0);
        wait(dut.sf_state_q == SF_DMA0); do_dma_handshake();
        wait(dut.sf_state_q == SF_TILE1);
        wait(dut.sf_state_q == SF_DMA1); do_dma_handshake();
        wait(dut.sf_state_q == SF_TILE2);
        wait(dut.sf_state_q == SF_DMA2); do_dma_handshake();
        wait(dut.sf_state_q == SF_TILE3);
        wait(dut.sf_state_q == SF_DMA3); do_dma_handshake();
        wait(dut.sf_state_q == SF_TILE0);
        wait(dut.sf_state_q == SF_DMA0); do_dma_handshake();
        wait(dut.sf_state_q == SF_TILE1);
        wait(dut.sf_state_q == SF_DMA1); do_dma_handshake();
        wait(dut.sf_state_q == SF_TILE2);
        wait(dut.sf_state_q == SF_DMA2); do_dma_handshake();
        wait(dut.sf_state_q == SF_TILE3);
        wait(dut.sf_state_q == SF_DMA3); do_dma_handshake();
        print_pass("SF All Power Loop Verified");
    end

    // 3. SpAttn Test
    $display("  Testing SpAttn Loop...");
    reset_dut();
    mem_write(CTRL_STATUS_ADDR, ((64'(mode)<<8)|3'b100)); // spattn_enable=1

    if (mode == 1) begin // COMPUTE_PWR
        wait(dut.sf_state_q == SPATTN_COMPUTE);
        // Wait for some cycles to ensure it stays or loops
        #1000;
        if (dut.sf_state_q != SPATTN_COMPUTE) print_fail("SpAttn left COMPUTE state in COMPUTE_PWR mode");
        else print_pass("SpAttn Compute Loop Verified");
    end else if (mode == 2) begin // DMA_PWR
        wait(dut.sf_state_q == SPATTN_DMA);
        do_dma_handshake();
        wait(dut.sf_state_q == SPATTN_DMA); // Should loop back
        do_dma_handshake();
        print_pass("SpAttn DMA Loop Verified");
    end else if (mode == 3) begin // ALL_PWR
        wait(dut.sf_state_q == SPATTN_COMPUTE);
        wait(dut.sf_state_q == SPATTN_DMA);
        do_dma_handshake();
        wait(dut.sf_state_q == SPATTN_COMPUTE);
        wait(dut.sf_state_q == SPATTN_DMA);
        do_dma_handshake();
        print_pass("SpAttn All Power Loop Verified");
    end

    // 4. PE + SF Test
    $display("  Testing PE + SF Loop...");
    reset_dut();
    mem_write(CTRL_STATUS_ADDR, ((64'(mode)<<8)|3'b011)); // sf_enable=1, pe_enable=1

    if (mode == 1) begin // COMPUTE_PWR
        fork
            begin
                wait(dut.pe_state_q == PE_TILE0);
                wait(dut.pe_state_q == PE_TILE1);
                wait(dut.pe_state_q == PE_TILE2);
                wait(dut.pe_state_q == PE_TILE3);
                wait(dut.pe_state_q == PE_TILE0);
                wait(dut.pe_state_q == PE_TILE1);
                wait(dut.pe_state_q == PE_TILE2);
                wait(dut.pe_state_q == PE_TILE3);
            end
            begin
                wait(dut.sf_state_q == SF_TILE0);
                wait(dut.sf_state_q == SF_TILE1);
                wait(dut.sf_state_q == SF_TILE2);
                wait(dut.sf_state_q == SF_TILE3);
                wait(dut.sf_state_q == SF_TILE0);
                wait(dut.sf_state_q == SF_TILE1);
                wait(dut.sf_state_q == SF_TILE2);
                wait(dut.sf_state_q == SF_TILE3);
            end
        join
        print_pass("PE + SF Compute Loop Verified");
    end else if (mode == 2) begin // DMA_PWR
        // NOTE: Why use repeat(20) do_dma_handshake() instead of wait(state)?
        // 1. Shared Resource: PE and SF share the SAME DMA interface.
        // 2. Unpredictable Arbitration: The internal Round-Robin arbiter decides who goes first.
        //    We cannot predict if PE or SF will win the bus next.
        //    Using rigid `wait(PE_DMA); wait(SF_DMA);` could cause a deadlock if the HW order differs.
        // 3. Goal: Verify that both modules are RUNNING (not IDLE) and consuming power,
        //    rather than verifying a strict sequence.
        repeat(20) do_dma_handshake();
        if (dut.pe_state_q == PE_IDLE || dut.sf_state_q == SF_IDLE) print_fail("PE or SF stuck in IDLE during DMA Loop");
        else print_pass("PE + SF DMA Loop Verified");
    end else if (mode == 3) begin // ALL_PWR
        // Same logic as DMA_PWR applies here.
        repeat(20) do_dma_handshake();
        if (dut.pe_state_q == PE_IDLE || dut.sf_state_q == SF_IDLE) print_fail("PE or SF stuck in IDLE during All Power Loop");
        else print_pass("PE + SF All Power Loop Verified");
    end

    // 5. PE + SpAttn Test
    $display("  Testing PE + SpAttn Loop...");
    reset_dut();
    mem_write(CTRL_STATUS_ADDR, ((64'(mode)<<8)|3'b101)); // spattn_enable=1, pe_enable=1

    if (mode == 1) begin // COMPUTE_PWR
        fork
            begin
                wait(dut.pe_state_q == PE_TILE0);
                wait(dut.pe_state_q == PE_TILE1);
                wait(dut.pe_state_q == PE_TILE2);
                wait(dut.pe_state_q == PE_TILE3);
                wait(dut.pe_state_q == PE_TILE0);
                wait(dut.pe_state_q == PE_TILE1);
                wait(dut.pe_state_q == PE_TILE2);
                wait(dut.pe_state_q == PE_TILE3);
            end
            begin
                wait(dut.sf_state_q == SPATTN_COMPUTE);
                #1000;
                if (dut.sf_state_q != SPATTN_COMPUTE) print_fail("SpAttn left COMPUTE state");
            end
        join
        print_pass("PE + SpAttn Compute Loop Verified");
    end else if (mode == 2) begin // DMA_PWR
        // NOTE: See explanation in PE + SF Test above.
        // We blindly handshake to ensure both modules stay active despite arbitration uncertainty.
        repeat(20) do_dma_handshake();
        if (dut.pe_state_q == PE_IDLE || dut.sf_state_q == SF_IDLE) print_fail("PE or SpAttn stuck in IDLE during DMA Loop");
        else print_pass("PE + SpAttn DMA Loop Verified");
    end else if (mode == 3) begin // ALL_PWR
        // Same logic applies.
        repeat(20) do_dma_handshake();
        if (dut.pe_state_q == PE_IDLE || dut.sf_state_q == SF_IDLE) print_fail("PE or SpAttn stuck in IDLE during All Power Loop");
        else print_pass("PE + SpAttn All Power Loop Verified");
    end

    // 6. SF + SpAttn Test
    $display("  Testing SF + SpAttn Loop...");
    reset_dut();
    mem_write(CTRL_STATUS_ADDR, ((64'(mode)<<8)|3'b110)); // spattn_enable=1, sf_enable=1

    if (mode == 1) begin // COMPUTE_PWR
        // Expect: SF_TILE0 -> ... -> SF_TILE3 -> SPATTN_COMPUTE -> SF_TILE0
        wait(dut.sf_state_q == SF_TILE0);
        wait(dut.sf_state_q == SF_TILE1);
        wait(dut.sf_state_q == SF_TILE2);
        wait(dut.sf_state_q == SF_TILE3);
        wait(dut.sf_state_q == SPATTN_COMPUTE);
        wait(dut.sf_state_q == SF_TILE0);
        wait(dut.sf_state_q == SF_TILE1);
        wait(dut.sf_state_q == SF_TILE2);
        wait(dut.sf_state_q == SF_TILE3);
        wait(dut.sf_state_q == SPATTN_COMPUTE);
        print_pass("SF + SpAttn Compute Loop Verified");
    end else if (mode == 2) begin // DMA_PWR
        // Expect: SF_DMA0 -> ... -> SF_DMA3 -> SPATTN_DMA -> SF_DMA0
        wait(dut.sf_state_q == SF_DMA0); do_dma_handshake();
        wait(dut.sf_state_q == SF_DMA1); do_dma_handshake();
        wait(dut.sf_state_q == SF_DMA2); do_dma_handshake();
        wait(dut.sf_state_q == SF_DMA3); do_dma_handshake();
        wait(dut.sf_state_q == SPATTN_DMA); do_dma_handshake();
        wait(dut.sf_state_q == SF_DMA0); do_dma_handshake();
        wait(dut.sf_state_q == SF_DMA1); do_dma_handshake();
        wait(dut.sf_state_q == SF_DMA2); do_dma_handshake();
        wait(dut.sf_state_q == SF_DMA3); do_dma_handshake();
        wait(dut.sf_state_q == SPATTN_DMA); do_dma_handshake();
        print_pass("SF + SpAttn DMA Loop Verified");
    end else if (mode == 3) begin // ALL_PWR
        // Expect: SF_TILE0 -> SF_DMA0 -> ... -> SPATTN_COMPUTE -> SPATTN_DMA -> SF_TILE0
        wait(dut.sf_state_q == SF_TILE0);
        wait(dut.sf_state_q == SF_DMA0); do_dma_handshake();
        wait(dut.sf_state_q == SF_TILE1);
        wait(dut.sf_state_q == SF_DMA1); do_dma_handshake();
        wait(dut.sf_state_q == SF_TILE2);
        wait(dut.sf_state_q == SF_DMA2); do_dma_handshake();
        wait(dut.sf_state_q == SF_TILE3);
        wait(dut.sf_state_q == SF_DMA3); do_dma_handshake();
        wait(dut.sf_state_q == SPATTN_COMPUTE);
        wait(dut.sf_state_q == SPATTN_DMA); do_dma_handshake();
        wait(dut.sf_state_q == SF_TILE0);
        wait(dut.sf_state_q == SF_DMA0); do_dma_handshake();
        wait(dut.sf_state_q == SF_TILE1);
        wait(dut.sf_state_q == SF_DMA1); do_dma_handshake();
        wait(dut.sf_state_q == SF_TILE2);
        wait(dut.sf_state_q == SF_DMA2); do_dma_handshake();
        wait(dut.sf_state_q == SF_TILE3);
        wait(dut.sf_state_q == SF_DMA3); do_dma_handshake();
        wait(dut.sf_state_q == SPATTN_COMPUTE);
        wait(dut.sf_state_q == SPATTN_DMA); do_dma_handshake();
        print_pass("SF + SpAttn All Power Loop Verified");
    end

    // 7. PE + SF + SpAttn Test (All Modules)
    $display("  Testing PE + SF + SpAttn Loop...");
    reset_dut();
    mem_write(CTRL_STATUS_ADDR, ((64'(mode)<<8)|3'b111)); // all enable

    if (mode == 1) begin // COMPUTE_PWR
        fork
            begin
                // PE Loop
                wait(dut.pe_state_q == PE_TILE0);
                wait(dut.pe_state_q == PE_TILE1);
                wait(dut.pe_state_q == PE_TILE2);
                wait(dut.pe_state_q == PE_TILE3);
                wait(dut.pe_state_q == PE_TILE0);
                wait(dut.pe_state_q == PE_TILE1);
                wait(dut.pe_state_q == PE_TILE2);
                wait(dut.pe_state_q == PE_TILE3);
            end
            begin
                // SF + SpAttn Loop
                wait(dut.sf_state_q == SF_TILE0);
                wait(dut.sf_state_q == SF_TILE1);
                wait(dut.sf_state_q == SF_TILE2);
                wait(dut.sf_state_q == SF_TILE3);
                wait(dut.sf_state_q == SPATTN_COMPUTE);
                wait(dut.sf_state_q == SF_TILE0);
                wait(dut.sf_state_q == SF_TILE1);
                wait(dut.sf_state_q == SF_TILE2);
                wait(dut.sf_state_q == SF_TILE3);
                wait(dut.sf_state_q == SPATTN_COMPUTE);
            end
        join
        print_pass("All Modules Compute Loop Verified");
    end else if (mode == 2) begin // DMA_PWR
        repeat(30) do_dma_handshake(); // Increased repeat count for 3 modules
        if (dut.pe_state_q == PE_IDLE || dut.sf_state_q == SF_IDLE) print_fail("Modules stuck in IDLE during DMA Loop");
        else print_pass("All Modules DMA Loop Verified");
    end else if (mode == 3) begin // ALL_PWR
        repeat(30) do_dma_handshake();
        if (dut.pe_state_q == PE_IDLE || dut.sf_state_q == SF_IDLE) print_fail("Modules stuck in IDLE during All Power Loop");
        else print_pass("All Modules All Power Loop Verified");
    end
  endtask

  task automatic check_reserved_registers;
    logic [63:0] v,expected;
    int addresses[4]='{0,'h1f8,'h200,'h3f8};
    print_banner("Removed compression path and MMIO boundaries");
    for(int k=0;k<4;k++)begin
      expected=64'h0123456789abcdef ^ (64'(k)<<40);
      mem_write(12'(addresses[k]),expected);
      mem_read(12'(addresses[k]),v);
      if(v!==expected)$fatal(1,"direct input write boundary %h",addresses[k]);
    end
    for(int a='h800;a<'h900;a+=8)begin
      mem_write(12'(a),'1);mem_read(12'(a),v);
      if(v!==64'hca11ab1ebadcab1e)$fatal(1,"reserved window %h still implemented",a);
    end
    // Former enable and selectors must neither run a decoder nor overwrite PE buffers.
    mem_write(CTRL_STATUS_ADDR,64'hf8);
    repeat(100) @(posedge clk_i);
    mem_read(CTRL_STATUS_ADDR,v);
    if(v[55:51]!==0)$fatal(1,"reserved status bits not zero");
    for(int k=0;k<4;k++)begin
      expected=64'h0123456789abcdef ^ (64'(k)<<40);
      mem_read(12'(addresses[k]),v);
      if(v!==expected)$fatal(1,"reserved control write changed PE input");
    end
    print_pass("Reserved writes inert; first/last weight and activation words preserved");
    reset_dut();
  endtask

  always @(negedge clk_i) begin
    if ($test$plusargs("debug_spattn") && dut.spattn_valid && (dut.spattn_cycle_cnt_q<6 || dut.spattn_cycle_cnt_q>126))
      $display("TRACE cycle=%d valid=%b initial=%b exp=%h sign=%b b0=%d b1=%d b6=%d b7=%d",dut.spattn_cycle_cnt_q,dut.spattn_valid,dut.spattn_initial,dut.sf_array_inst.row[0].col[0].sf_inst.exponent_q,dut.sf_array_inst.row[0].col[0].sf_inst.sign_bit_q,dut.sf_array_inst.row[0].col[0].sf_inst.bucket_3b000_q,dut.sf_array_inst.row[0].col[0].sf_inst.bucket_3b001_q,dut.sf_array_inst.row[0].col[0].sf_inst.bucket_3b110_q,dut.sf_array_inst.row[0].col[0].sf_inst.bucket_3b111_q);
  end
  initial begin
    #20000000; $fatal(1,"[FAIL] INT global timeout");
  end
endmodule
// pragma translate_on
