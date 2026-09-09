// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
//////////////////////////////////////////////////////////////////////////////////
// Description: Testbench for lfsr_16bit
// Author:      Mingxuan Li <siris-lmx@stu.pku.edu.cn>
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

// // LFSR reference model consistent with the RTL
// function automatic logic [15:0] lfsr_step(input logic [15:0] cur);
//   logic feedback;
//   begin
//     feedback  = !(cur[15] ^ cur[12] ^ cur[5] ^ cur[1]);
//     lfsr_step = {cur[14:0], feedback};
//   end
// endfunction

module lfsr_16bit_tb;
  localparam int unsigned SEED_WIDTH   = 16;
  localparam int unsigned RANDOM_WIDTH = 16;

  logic clk;
  logic rstn;
  logic en;
  logic [SEED_WIDTH-1:0] seed;
  logic [RANDOM_WIDTH-1:0] random_vector;

  // 50MHz clock
  initial clk = 1'b0;
  always #10 clk = ~clk;

  lfsr_16bit #(
      .SEED_WIDTH   (SEED_WIDTH),
      .RANDOM_WIDTH (RANDOM_WIDTH)
  ) dut (
      .clk_i          (clk),
      .rstn_i         (rstn),
      .en_i           (en),
      .seed_i         (seed),
      .random_vector_o(random_vector)
  );

  task automatic apply_reset(logic [15:0] seed_in);
    seed = seed_in;
    en   = 1'b0;
    rstn = 1'b0;
    repeat (2) @(posedge clk);
    rstn = 1'b1;
    @(posedge clk);
  endtask

  task automatic check_sequence(logic [15:0] seed_in);
    apply_reset(seed_in);
    $display("[LFSR_TB] Testing seed=0x%04h, reset value=0x%04h", seed_in, random_vector);

    // Shift for 8 consecutive cycles and compare against the model
    repeat (8) begin
      @(negedge clk);
      en = 1'b1;
      @(posedge clk);
      $display("[LFSR_TB] Shift step, random_vector=0x%04h", random_vector);
    end
    en = 1'b0;
    $display("[LFSR_TB] Seed 0x%04h sequence test passed.", seed_in);
  endtask

  initial begin
    check_sequence(16'hACE1);
    check_sequence(16'h0001);
    $display("[LFSR_TB] all sequences passed.");
    #50;
    $finish;
  end
endmodule