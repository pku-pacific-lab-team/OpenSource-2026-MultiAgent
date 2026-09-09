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

`include "misc_common/registers.svh"
module quant (
    input  logic             clk_i,
    input  logic             rstn_i,
    input  logic [31:0][15:0] bf_group_i,
    input  logic             mode_i,  // 0: asymmetric (-8 to 7), 1: symmetric (-7 to 7)
    output logic [31:0][3:0]  mx_man_group_o,
    output logic [7:0]        mx_sf_o
);

    // =========================================================================
    // Pipeline Stage 0: Unpack + Max Exponent Tree (Combinational)
    // =========================================================================

    // --- Unpack signals ---
    logic [31:0][7:0] exps;
    logic [31:0]      signs;
    logic [31:0][6:0] mantissas;
    logic [31:0]      is_zero;
    logic [31:0]      is_subnormal;
    logic [31:0]      is_inf;
    logic [31:0]      is_nan;
    logic [31:0][7:0] adj_exps;  // Adjusted exponents for max calculation (exclude inf/nan)
    logic             has_inf;

    // --- Unpack logic ---
    for (genvar i = 0; i < 32; i++) begin : gen_unpack
        assign signs[i]       = bf_group_i[i][15];
        assign exps[i]        = bf_group_i[i][14:7];
        assign mantissas[i]   = bf_group_i[i][6:0];
        assign is_zero[i]     = (exps[i] == 8'd0) && (mantissas[i] == 7'd0);
        assign is_subnormal[i]= (exps[i] == 8'd0) && (mantissas[i] != 7'd0);
        assign is_inf[i]      = (exps[i] == 8'd255) && (mantissas[i] == 7'd0);
        assign is_nan[i]      = (exps[i] == 8'd255) && (mantissas[i] != 7'd0);
        assign adj_exps[i]    = (is_inf[i] || is_nan[i]) ? 8'd0 : exps[i];
    end

    // --- Detect if any inf in the group ---
    always_comb begin
        has_inf = 1'b0;
        for (int i = 0; i < 32; i++) begin
            if (is_inf[i]) has_inf = 1'b1;
        end
    end

    // --- Max exponent tree ---
    logic [7:0] max_exp_l0 [15:0];
    logic [7:0] max_exp_l1 [7:0];
    logic [7:0] max_exp_l2 [3:0];
    logic [7:0] max_exp_l3 [1:0];
    logic [7:0] max_exp_final;

    always_comb begin
        // Level 0: 32 -> 16
        for (int i = 0; i < 16; i++)
            max_exp_l0[i] = (adj_exps[2*i] > adj_exps[2*i+1]) ? adj_exps[2*i] : adj_exps[2*i+1];

        // Level 1: 16 -> 8
        for (int i = 0; i < 8; i++)
            max_exp_l1[i] = (max_exp_l0[2*i] > max_exp_l0[2*i+1]) ? max_exp_l0[2*i] : max_exp_l0[2*i+1];

        // Level 2: 8 -> 4
        for (int i = 0; i < 4; i++)
            max_exp_l2[i] = (max_exp_l1[2*i] > max_exp_l1[2*i+1]) ? max_exp_l1[2*i] : max_exp_l1[2*i+1];

        // Level 3: 4 -> 2
        for (int i = 0; i < 2; i++)
            max_exp_l3[i] = (max_exp_l2[2*i] > max_exp_l2[2*i+1]) ? max_exp_l2[2*i] : max_exp_l2[2*i+1];

        // Final
        max_exp_final = (max_exp_l3[0] > max_exp_l3[1]) ? max_exp_l3[0] : max_exp_l3[1];
    end

    // =========================================================================
    // Pipeline Register: Between Max Tree and Quantization
    // =========================================================================

    // --- Registered signals ---
    logic [7:0]       max_exp_q;
    logic [31:0][7:0] exps_q;
    logic [31:0]      signs_q;
    logic [31:0][6:0] mantissas_q;
    logic [31:0]      is_zero_q;
    logic [31:0]      is_subnormal_q;
    logic [31:0]      is_inf_q;
    logic [31:0]      is_nan_q;
    logic             has_inf_q;
    logic             mode_q;

    // --- Pipeline registers using FF macro ---
    `FF(max_exp_q,       max_exp_final, 8'd0,  clk_i, rstn_i)
    `FF(exps_q,          exps,          '0,    clk_i, rstn_i)
    `FF(signs_q,         signs,         '0,    clk_i, rstn_i)
    `FF(mantissas_q,     mantissas,     '0,    clk_i, rstn_i)
    `FF(is_zero_q,       is_zero,       '0,    clk_i, rstn_i)
    `FF(is_subnormal_q,  is_subnormal,  '0,    clk_i, rstn_i)
    `FF(is_inf_q,        is_inf,        '0,    clk_i, rstn_i)
    `FF(is_nan_q,        is_nan,        '0,    clk_i, rstn_i)
    `FF(has_inf_q,       has_inf,       1'b0,  clk_i, rstn_i)
    `FF(mode_q,          mode_i,        1'b0,  clk_i, rstn_i)

    // =========================================================================
    // Pipeline Stage 1: Quantization (uses registered signals)
    // =========================================================================

    // --- Scale factor output (from registered max_exp) ---
    assign mx_sf_o = (max_exp_q >= 8'd2) ? (max_exp_q - 8'd2) : 8'd0;

    // --- Quantization lanes ---
    for (genvar i = 0; i < 32; i++) begin : gen_quant_lane
        logic [7:0] exp_delta;
        logic [19:0] shifted_val;
        logic        round_bit;
        logic [5:0]  rounded_mag;  // Widened to handle overflow
        logic [3:0]  final_int;

        assign exp_delta = max_exp_q - exps_q[i];

        always_comb begin
            if (is_zero_q[i]) begin
                shifted_val = '0;
            end else if (is_subnormal_q[i]) begin
                shifted_val = {mantissas_q[i], 13'b0} >> exp_delta;
            end else begin
                shifted_val = {1'b1, mantissas_q[i], 12'b0} >> exp_delta;
            end
        end

        assign round_bit = shifted_val[14];

        always_comb begin
            rounded_mag = {1'b0, shifted_val[19:15]} + {5'd0, round_bit};
        end

        always_comb begin
            if (is_inf_q[i]) begin
                final_int = signs_q[i] ? 4'b1000 : 4'b0111;  // -8 or +7
            end else if (is_nan_q[i]) begin
                final_int = 4'b0000;  // Treat NaN as 0
            end else begin
                // Normal quantization
                if (signs_q[i]) begin
                    if (rounded_mag > 6'd8)
                        final_int = 4'b1000;  // -8
                    else
                        final_int = (~rounded_mag[3:0]) + 4'd1;
                end else begin
                    if (rounded_mag > 6'd7)
                        final_int = 4'b0111;  // +7
                    else
                        final_int = rounded_mag[3:0];
                end
            end

            // Override if has_inf and not inf
            if (has_inf_q && !is_inf_q[i]) begin
                final_int = 4'b0000;
            end

            // Apply mode for symmetric: map -8 to -7
            if (mode_q && (final_int == 4'b1000)) begin
                final_int = 4'b1001;  // -7
            end
        end

        assign mx_man_group_o[i] = final_int;
    end

endmodule
