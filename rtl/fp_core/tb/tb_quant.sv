// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
`timescale 1ns/1ps

module tb_quant;

    localparam int WIDTH = 32;

    // Inputs
    logic [WIDTH-1:0][15:0] bf_group_i;
    logic                  mode_i;  // 0: asymmetric (-8..7), 1: symmetric (-7..7)

    // Outputs
    logic [WIDTH-1:0][3:0]  mx_man_group_o;
    logic [7:0]            mx_sf_o;

    // DUT
    quant dut (
        .bf_group_i(bf_group_i),
        .mode_i(mode_i),
        .mx_man_group_o(mx_man_group_o),
        .mx_sf_o(mx_sf_o)
    );

    // --------- Helper: BF16 -> shortreal ---------
    function automatic shortreal bf16_to_fp32(input logic [15:0] bf);
        logic [31:0] fp32 = {bf, 16'h0000};  // zero-extend to FP32
        return $bitstoshortreal(fp32);
    endfunction

    // --------- Golden Model ---------
    task automatic golden_model(
        input logic [WIDTH-1:0][15:0] group,
        input logic                  mode,
        output logic [7:0]           sf_golden,
        output logic [3:0]           man_golden [WIDTH]
    );
        logic [7:0]  exps       [WIDTH];
        logic        signs      [WIDTH];
        logic [6:0]  mants      [WIDTH];
        logic        is_zero    [WIDTH];
        logic        is_subnorm [WIDTH];
        logic        is_inf     [WIDTH];
        logic        is_nan     [WIDTH];
        logic        has_inf = 0;

        logic [7:0]  max_exp = 0;

        // Step 1: Unpack
        for (int i = 0; i < WIDTH; i++) begin
            signs[i]      = group[i][15];
            exps[i]       = group[i][14:7];
            mants[i]      = group[i][6:0];

            is_zero[i]     = (exps[i] == 0) && (mants[i] == 0);
            is_subnorm[i] = (exps[i] == 0) && (mants[i] != 0);
            is_inf[i]     = (exps[i] == 8'hFF) && (mants[i] == 0);
            is_nan[i]     = (exps[i] == 8'hFF) && (mants[i] != 0);

            if (is_inf[i]) has_inf = 1;
        end

        // Step 2: Find max_exp (exclude inf/nan)
        for (int i = 0; i < WIDTH; i++) begin
            if (!is_inf[i] && !is_nan[i]) begin
                if (exps[i] > max_exp) max_exp = exps[i];
            end
        end

        // Step 3: Compute sf
        sf_golden = (max_exp >= 8'd2) ? (max_exp - 8'd2) : 8'd0;

        // Step 4: Quantize each lane
        for (int i = 0; i < WIDTH; i++) begin
            logic [19:0] shifted;
            logic        round_bit;
            logic [5:0]  rounded_mag;
            logic [3:0]  final_int;

            if (is_inf[i]) begin
                final_int = signs[i] ? 4'b1000 : 4'b0111;  // -8 or +7
            end else if (is_nan[i]) begin
                final_int = 4'b0000;
            end else begin
                // Compute shifted value
                logic [7:0] delta = max_exp - exps[i];

                if (is_zero[i]) begin
                    shifted = 0;
                end else if (is_subnorm[i]) begin
                    shifted = {mants[i], 13'd0} >> delta;
                end else begin
                    shifted = {1'b1, mants[i], 12'd0} >> delta;
                end

                round_bit   = shifted[14];
                rounded_mag = {1'b0, shifted[19:15]} + round_bit;  // 5+1 bit add

                if (signs[i]) begin  // negative
                    if (rounded_mag > 8)
                        final_int = 4'b1000;  // -8
                    else
                        final_int = (~rounded_mag[3:0]) + 1;
                end else begin  // positive
                    if (rounded_mag > 7)
                        final_int = 4'b0111;  // +7
                    else
                        final_int = rounded_mag[3:0];
                end
            end

            // If group has any inf, non-inf -> 0
            if (has_inf && !is_inf[i])
                final_int = 4'b0000;

            // Symmetric mode: map -8 -> -7
            if (mode && final_int == 4'b1000)
                final_int = 4'b1001;  // -7 in 2's complement

            man_golden[i] = final_int;
        end
    endtask

    // --------- Main Test Loop ---------
    initial begin
        logic [7:0]   golden_sf;
        logic [3:0]   golden_man [WIDTH];

        static int errors = 0;
        static int iters = 10000;
        int sel;

        shortreal val;

        $display("Starting %0d random tests...", iters);

        for (int n = 0; n < iters; n++) begin
            // Random mode
            mode_i = $urandom_range(0,1);

            // Random BF16 inputs with good coverage
            for (int i = 0; i < WIDTH; i++) begin
                sel = $urandom_range(0, 20);

                case (sel)
                    0:  bf_group_i[i] = 16'h0000;                   // +0
                    1:  bf_group_i[i] = 16'h8000;                   // -0
                    2:  bf_group_i[i] = 16'h7F80;                   // +Inf
                    3:  bf_group_i[i] = 16'hFF80;                   // -Inf
                    4:  bf_group_i[i] = 16'h7FC1;                   // NaN
                    5:  bf_group_i[i] = {1'b0, 8'd0, 7'($urandom_range(1, 127))}; // +subnormal, non-zero
                    6:  bf_group_i[i] = {1'b1, 8'd0, 7'($urandom_range(1, 127))}; // -subnormal, non-zero
                    default: begin
                        bf_group_i[i][15]   = $urandom_range(0,1);
                        bf_group_i[i][14:7] = $urandom_range(1, 254);
                        bf_group_i[i][6:0]  = $urandom;
                    end
                endcase
            end

            // Compute golden
            golden_model(bf_group_i, mode_i, golden_sf, golden_man);

            // Apply to DUT
            #1;

            // Check
            if (mx_sf_o !== golden_sf) begin
                $display("[%0t] ERROR %0d: SF mismatch! DUT=%0d Golden=%0d", $time, n, mx_sf_o, golden_sf);
                errors++;
            end

            

            for (int i = 0; i < WIDTH; i++) begin
                if (mx_man_group_o[i] !== golden_man[i]) begin
                    val = bf16_to_fp32(bf_group_i[i]);
                    $display("[%0t] ERROR %0d lane %0d: MAN mismatch!", $time, n, i);
                    $display("  Input BF16: %h  (fp: %f)", bf_group_i[i], val);
                    $display("  DUT:  %b  Golden: %b", mx_man_group_o[i], golden_man[i]);
                    errors++;
                end
            end

            if (errors > 50) begin
                $display("Too many errors, stopping...");
                $stop;
            end
        end

        if (errors == 0)
            $display("PASS: All %0d tests passed!", iters);
        else
            $display("FAIL: %0d errors in %0d tests", errors, iters);

        $finish;
    end

endmodule