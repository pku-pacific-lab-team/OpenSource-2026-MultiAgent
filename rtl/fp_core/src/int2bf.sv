// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
//////////////////////////////////////////////////////////////////////////////////
// Author:      Hongou Li [Peking University]
// Acknowledge: Google AI Studio + Gemini-3-Pro
//////////////////////////////////////////////////////////////////////////////////

module int2bf (
    input  logic [15:0] mx_man_i,
    input  logic [7:0]  mx_sf_i,
    input  fpnew_pkg::roundmode_e  rnd_mode_i,
    output logic [15:0] bf_o
);

    localparam int unsigned BfAbsWidth = 15;
 
    logic        sign;
    logic [15:0] abs_val;
    logic [3:0]  lz_cnt;
    logic        is_empty;
    logic [15:0] norm_val;
    logic [8:0]  pre_exp;
    logic [6:0]  mantissa;
    logic        round_bit;
    logic        sticky_bit;
    logic        is_overflow;

    logic [BfAbsWidth-1:0] round_in_abs;
    logic [1:0]            round_sticky;
    logic [BfAbsWidth-1:0] round_out_abs;
    logic                  round_out_sign;

    assign sign = mx_man_i[15];
    assign abs_val = sign ? (~mx_man_i + 16'd1) : mx_man_i;

    lzc #(
        .WIDTH(16),
        .MODE (1) // Leading Zero Counter
    ) i_lzc (
        .in_i   (abs_val),
        .cnt_o  (lz_cnt),
        .empty_o(is_empty)
    );

    assign norm_val = abs_val << lz_cnt;

    assign pre_exp = {1'b0, mx_sf_i} + (9'd15 - {5'd0, lz_cnt});

    assign is_overflow = (pre_exp >= 9'd255);

    assign mantissa   = norm_val[14:8];
    assign round_bit  = norm_val[7];
    assign sticky_bit = |norm_val[6:0];

    always_comb begin
        if (is_empty) begin
            round_in_abs = '0;
            round_sticky = 2'b00;
        end else if (is_overflow) begin
            round_in_abs = {8'hFF, 7'd0}; 
            round_sticky = 2'b00;
        end else begin
            round_in_abs = {pre_exp[7:0], mantissa};
            round_sticky = {round_bit, sticky_bit};
        end
    end

    fpnew_rounding #(
        .AbsWidth(BfAbsWidth)
    ) i_rounding (
        .abs_value_i            (round_in_abs),
        .sign_i                 (sign),
        .round_sticky_bits_i    (round_sticky),
        .rnd_mode_i             (rnd_mode_i),
        .effective_subtraction_i(1'b0),
        .abs_rounded_o          (round_out_abs),
        .sign_o                 (round_out_sign),
        .exact_zero_o           ()
    );

    assign bf_o = {round_out_sign, round_out_abs};

endmodule