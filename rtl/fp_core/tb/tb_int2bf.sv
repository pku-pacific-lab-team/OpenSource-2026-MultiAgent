// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
`timescale 1ns/1ps

module tb_int2bf;

  localparam int NUM_TESTS = 1000000;

  // DUT I/O
  logic [15:0] mx_man_i;
  logic [7:0]  mx_sf_i;
  fpnew_pkg::roundmode_e  rnd_mode_i;
  logic [15:0] bf_o;

  // DUT
  int2bf dut (
    .mx_man_i  (mx_man_i),
    .mx_sf_i   (mx_sf_i),
    .rnd_mode_i(rnd_mode_i),
    .bf_o      (bf_o)
  );


  // BF16 bits -> FP32 shortreal
  function automatic shortreal bf16_to_fp32(logic [15:0] val);
    logic [31:0] fp32;
    fp32 = {val, 16'h0000};
    return $bitstoshortreal(fp32);
  endfunction

  // FP32 shortreal -> BF16 bits (RNE)
  function automatic logic [15:0] fp32_to_bf16(shortreal val);
    logic [31:0] f32_bits;
    logic lsb, rb, sb;

    f32_bits = $shortrealtobits(val);

    if (f32_bits[30:23] == 8'hff)
      return f32_bits[31:16];

    lsb = f32_bits[16];        // LSB of BF16 mantissa
    rb  = f32_bits[15];        // round bit
    sb  = |f32_bits[14:0];     // sticky bit

    // RNE
    if (rb && (lsb || sb))
      return f32_bits[31:16] + 1'b1;
    else
      return f32_bits[31:16];
  endfunction

  // =========================
  // MXINT16 -> FP32 golden
  // =========================
  function automatic shortreal mxint16_to_fp32(
    logic signed [15:0] man,
    logic [7:0]         sf
  );
    shortreal val;
    int exp;
    exp = sf - 127;
    val = shortreal'(man) * (2.0 ** exp);
    return val;

  endfunction

  shortreal golden_fp32;
  logic [15:0] golden_bf16;

  initial begin
    rnd_mode_i = fpnew_pkg::RNE;
    
    #1;

    for (int t = 0; t < NUM_TESTS; t++) begin
      
      mx_man_i = $urandom_range(0, 16'hffff);
      mx_sf_i  = $urandom_range(0, 255);
      
      #1;

      golden_fp32 = mxint16_to_fp32(
                      mx_man_i,
                      mx_sf_i
                      );

      golden_bf16 = fp32_to_bf16(golden_fp32);

      if (bf_o !== golden_bf16) begin
          $display("❌ MISMATCH at test %0d", t);
          $display("  mx_man = 0x%h (%0d)", mx_man_i, $signed(mx_man_i));
          $display("  mx_sf  = %0d", mx_sf_i);
          $display("  golden fp32 = %e", golden_fp32);
          $display("  golden bf16 = 0x%h", golden_bf16);
          $display("  dut    bf16 = 0x%h", bf_o);
          $fatal;
      end
      
    end

    $display("✅ ALL %0d TESTS PASSED", NUM_TESTS);
    $stop;
  end

endmodule

