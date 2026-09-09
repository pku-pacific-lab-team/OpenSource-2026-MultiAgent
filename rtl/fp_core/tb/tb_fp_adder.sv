// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
`timescale 1ns/1ps

module tb_fp_adder;
    // Import package types
    import fpnew_pkg::*;

    // Local Parameters
    localparam fp_format_e FMT = FP16ALT; // This is BF16 (8 exp, 7 man)
    localparam int unsigned WIDTH = 16;

    // Signals
    logic [1:0][WIDTH-1:0] operands;
    logic [1:0]            is_boxed;
    roundmode_e            rnd_mode;
    operation_e            op;
    
    logic [WIDTH-1:0]      result;
    status_t               status;

    // Statistics
    int pass_count = 0;
    int fail_count = 0;
    int test_num = 1000000;

    // --- 1. DUT Instantiation ---
    fp_adder #(
        .FpFormat(FMT)
    ) dut (
        .operands_i(operands),
        .is_boxed_i(is_boxed),
        .rnd_mode_i(rnd_mode),
        .op_i(op),
        .result_o(result),
        .status_o(status)
    );

    // --- 2. Helper Functions (Strictly Automatic for ModelSim) ---
    
    // Convert BF16 bits to FP32 shortreal
    function automatic shortreal bf16_to_fp32(logic [15:0] val);
        logic [31:0] fp32;
        fp32 = {val, 16'h0000};
        return $bitstoshortreal(fp32);
    endfunction

    // Convert FP32 shortreal to BF16 bits with RNE rounding
    function automatic logic [15:0] fp32_to_bf16(shortreal val);
        logic [31:0] f32_bits;
        logic lsb, rb, sb;
        f32_bits = $shortrealtobits(val);
        
        lsb = f32_bits[16];
        rb  = f32_bits[15];
        sb  = |f32_bits[14:0];

        // NaN/Inf handling
        if (f32_bits[30:23] == 8'hff) return f32_bits[31:16];

        // RNE Rounding
        if (rb && (lsb || sb)) return f32_bits[31:16] + 1'b1;
        else                   return f32_bits[31:16];
    endfunction

    // --- 3. Main Test Process ---
    initial begin
        // Variable declarations at the top
        shortreal val_a, val_b, golden_sum;
        logic [15:0] golden_bits;
        int i;

        // Initial setup
        operands = '0;
        is_boxed = 2'b11; // Assume operands are properly NaN-boxed
        rnd_mode = RNE;   // Round to Nearest Even
        op       = ADD;
        
        #10;
        $display("===== Starting Automated Test for fpnew_add (BF16) =====");

        // --- Basic Test: 1.0 + 1.0 = 2.0 ---
        operands[0] = 16'h3f80; // 1.0
        operands[1] = 16'h3f80; // 1.0
        #1;
        if (result == 16'h4000) $display("[SUCCESS] 1.0 + 1.0 = 2.0");
        else $display("[ERROR] 1.0 + 1.0 failed. Result: %h", result);

        // --- Basic Test: 2.0 - 1.0 (via sign) = 1.0 ---
        operands[0] = 16'h4000; // 2.0
        operands[1] = 16'hbf80; // -1.0
        #1;
        if (result == 16'h3f80) $display("[SUCCESS] 2.0 + (-1.0) = 1.0");
        else $display("[ERROR] 2.0 + (-1.0) failed. Result: %h", result);

        // --- Random Test Loop ---
        for (i = 0; i < test_num; i = i + 1) begin
            operands[0] = $urandom();
            operands[1] = $urandom();
            
            #1; // Combinational delay

            val_a = bf16_to_fp32(operands[0]);
            val_b = bf16_to_fp32(operands[1]);
            golden_sum = val_a + val_b;
            golden_bits = fp32_to_bf16(golden_sum);

            // Compare (Ignoring payload of NaNs)
            if ((result[14:7] == 8'hff && golden_bits[14:7] == 8'hff) || (result === golden_bits)) begin
                pass_count = pass_count + 1;
            end else begin
                fail_count = fail_count + 1;
                $display("[FAIL] A:%h B:%h | HW:%h Golden:%h", operands[0], operands[1], result, golden_bits);
            end
        end

        $display("===== Test Summary =====");
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        if (fail_count == 0) $display("Overall Result: PASS");
        else                $display("Overall Result: FAIL");

        $stop;
    end

endmodule