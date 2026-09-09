// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
//////////////////////////////////////////////////////////////////////////////////
// Description: Testbench for LFSR, HDC vector generator and HDC encoder
// Author:      Mingxuan Li <siris-lmx@stu.pku.edu.cn> [Peking University]
// Acknowledge: VSCode Copilot + GPT-5 Agent
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

// Common function: 16-bit LFSR step consistent with the RTL
function automatic logic [15:0] lfsr_step(input logic [15:0] cur);
  logic feedback;
  begin
    feedback  = !(cur[15] ^ cur[12] ^ cur[5] ^ cur[1]);
    lfsr_step = {cur[14:0], feedback};
  end
endfunction

//////////////////////////////////////////////////////////////////////////////////
// hdc_encoder top-level self-test
//////////////////////////////////////////////////////////////////////////////////
module encoder_tb;

  // Parameter configuration: shortens simulation time; HDC_DIM must be an integer multiple of RANDOM_WIDTH
  localparam int unsigned HDC_DIM        = 64;
  localparam int unsigned TOKEN_ID_WIDTH = 16;
  localparam int unsigned RANDOM_WIDTH   = 16;
  localparam int unsigned N_TOKEN        = 4;
  localparam int unsigned NUM_WORDS      = HDC_DIM / RANDOM_WIDTH;

  // Clock and reset
  logic clk;
  logic rstn;

  // DUT interface
  logic en;
  logic [N_TOKEN-1:0][TOKEN_ID_WIDTH-1:0] token_id;
  logic finish;
  logic [HDC_DIM-1:0] hdc_vector;
  // 100MHz clock
  initial clk = 1'b0;
  always #5 clk = ~clk;

  // DUT instance
  hdc_encoder #(
      .HDC_DIM        (HDC_DIM),
      .TOKEN_ID_WIDTH (TOKEN_ID_WIDTH),
      .RANDOM_WIDTH   (RANDOM_WIDTH),
      .N_TOKEN        (N_TOKEN)
  ) dut (
      .clk_i      (clk),
      .rstn_i     (rstn),
      .en_i       (en),
      .token_id_i (token_id),
      .finish_o   (finish),
      .vector_o   (hdc_vector)
  );

  // Software reference model: reuses gen_expect and follows the RTL partial_hdc_vector update scheme
  function automatic logic [HDC_DIM-1:0] gen_expect(input logic [15:0] seed_in);
    logic [15:0] cur;
    logic [HDC_DIM-1:0] vec;
    int idx;
    begin
      cur = seed_in;
      vec = '0;
      for (idx = 0; idx < NUM_WORDS; idx++) begin
        // cur                                   = lfsr_step(cur);
        vec[idx*RANDOM_WIDTH +: RANDOM_WIDTH] = cur;
        cur                                   = lfsr_step(cur);
      end
      gen_expect = vec;
    end
  endfunction

  function automatic logic [HDC_DIM-1:0] ref_encoder(
    input logic [N_TOKEN-1:0][TOKEN_ID_WIDTH-1:0] tokens);
    logic [HDC_DIM-1:0] partial;
    logic [HDC_DIM-1:0] cur_vec;
    int t;
    begin
      partial = '0;
      for (t = 0; t < N_TOKEN; t++) begin
        cur_vec = gen_expect(tokens[t]);
        partial = (partial >> t) ^ cur_vec;
      end
      ref_encoder = partial;
    end
  endfunction

  // Reset
  task automatic do_reset();
    rstn     = 1'b0;
    en       = 1'b0;
    token_id = '0;
    repeat (4) @(posedge clk);
    rstn = 1'b1;
    @(posedge clk);
  endtask

  // Wait for finish; report an error if the maximum cycle count is exceeded
  task automatic wait_finish(int unsigned max_cycle = 20480, logic [HDC_DIM-1:0] expect_ref);
    int unsigned c = 0;
    while (!finish) begin
      @(posedge clk);
      c++;
      if (c > max_cycle) begin
        $fatal(1, "[ENC_TB] timeout waiting finish after %0d cycles", c);
      end
    end
    $display("[ENC_TB] finish asserted at %0t after %0d cycles", $time, c);
    if (finish) begin
      assert (hdc_vector == expect_ref)
        else $fatal(1, "[ENC_TB] mismatch exp=%0h got=%0h", expect_ref, hdc_vector);
      $display("[ENC_TB] PASSED: exp=%0h got=%0h", expect_ref, hdc_vector);
    end
  endtask

  // Start one encoding run and compare against the reference model
  task automatic run_once(logic [N_TOKEN-1:0][TOKEN_ID_WIDTH-1:0] tokens, string tag);
    logic [HDC_DIM-1:0] expect_ref;
    expect_ref  = ref_encoder(tokens);
    token_id = tokens;
    repeat (3) @(posedge clk);
    @(negedge clk);
    en = 1'b1;
    @(negedge clk);
    en = 1'b0;    
    wait_finish(2*NUM_WORDS * N_TOKEN + 10, expect_ref);
  endtask

  // Monitor signals
  initial begin
    $display("time\tclk\trstn\ten\tfinish\ttoken0");
    forever begin
      @(posedge clk);
      $display("%0t\t%b\t%b\t%b\t%b\t%0h", $time, clk, rstn, en, finish, token_id[0]);
    end
  end

  // Main test flow
  initial begin
    do_reset();

    run_once('{16'h0001, 16'h00A5, 16'h1234, 16'hFEDC}, "case0");
    run_once('{16'hFFFF, 16'h0F0F, 16'hAAAA, 16'h5555}, "case1");
    run_once('{16'hFBAF, 16'hDF1F, 16'hABCD, 16'h5658}, "case2");

    $display("[ENC_TB] all cases done, simulation finish.");
    #20;
    $finish;
  end

endmodule
