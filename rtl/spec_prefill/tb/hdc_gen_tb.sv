// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
//////////////////////////////////////////////////////////////////////////////////
// Description: Testbench for hdc_vector_generator
// Author:      Mingxuan Li <siris-lmx@stu.pku.edu.cn>
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

// LFSR reference model, consistent with the RTL
function automatic logic [15:0] lfsr_step(input logic [15:0] cur);
  logic feedback;
  begin
    feedback  = !(cur[15] ^ cur[12] ^ cur[5] ^ cur[1]);
    lfsr_step = {cur[14:0], feedback};
  end
endfunction

module hdc_vector_generator_tb;
  localparam int unsigned HDC_DIM        = 64;
  localparam int unsigned TOKEN_ID_WIDTH = 16;
  localparam int unsigned RANDOM_WIDTH   = 16;
  localparam int unsigned NUM_WORDS      = HDC_DIM / RANDOM_WIDTH;

  logic clk;
  logic rstn;
  logic en;
  logic [TOKEN_ID_WIDTH-1:0] token_id;
  logic finish;
  logic [HDC_DIM-1:0] hdc_vector;

  // 100MHz clock
  initial clk = 1'b0;
  always #5 clk = ~clk;

  hdc_vector_generator #(
      .HDC_DIM        (HDC_DIM),
      .TOKEN_ID_WIDTH (TOKEN_ID_WIDTH),
      .RANDOM_WIDTH   (RANDOM_WIDTH)
  ) dut (
      .clk_i        (clk),
      .rstn_i       (rstn),
      .en_i         (en),
      .token_id_i   (token_id),
      .finish_o     (finish),
      .hdc_vector_o (hdc_vector)
  );

  function automatic logic [HDC_DIM-1:0] gen_expect(input logic [15:0] seed_in);
    logic [15:0] cur;
    logic [HDC_DIM-1:0] vec;
    int idx;
    begin
      cur = seed_in;
      vec = '0;
      for (idx = 0; idx < NUM_WORDS; idx++) begin
        vec[idx*RANDOM_WIDTH +: RANDOM_WIDTH] = cur;
        cur                                   = lfsr_step(cur);
      end
      gen_expect = vec;
    end
  endfunction

  task automatic do_reset();
    rstn     = 1'b0;
    en       = 1'b0;
    token_id = '0;
    repeat (3) @(posedge clk);
    rstn = 1'b1;
    @(posedge clk);
  endtask

  task automatic run_one(input logic [15:0] seed_in, string tag);
    logic [HDC_DIM-1:0] expect_ref;
    expect_ref   = gen_expect(seed_in);
    token_id = seed_in;
    @(negedge clk);
    en = 1'b1;
    @(negedge clk);
    en = 1'b0;
    wait (finish === 1'b1);
    if (finish) begin
      assert (hdc_vector == expect_ref) 
        else $fatal(1, "[HDC_VEC_TB] %s mismatch exp=%0h got=%0h", tag, expect_ref, hdc_vector);
      $display("[HDC_VEC_TB] %s PASSED: exp=%0h got=%0h", tag, expect_ref, hdc_vector);
    end
    @(negedge clk);
    en = 1'b0;
  endtask

  initial begin
    do_reset();
    run_one(16'h0001, "case0");
    repeat (4) @(posedge clk);
    do_reset();
    run_one(16'hA5A5, "case1");
    $display("[HDC_VEC_TB] all cases passed.");
    #50;
    $finish;
  end
endmodule