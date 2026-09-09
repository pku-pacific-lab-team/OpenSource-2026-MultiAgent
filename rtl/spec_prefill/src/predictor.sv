// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
//////////////////////////////////////////////////////////////////////////////////
// Description: HDC-based Agent Predictor Module
// Author:      Siyuan He [Peking University]
// Acknowledge: Cursor Agent
//////////////////////////////////////////////////////////////////////////////////

module xor_adder #(
    parameter int unsigned NUM_INPUT = 32,
    parameter int unsigned HDC_DIM = 2048
)(
    input  logic                      clk_i,
    input  logic                      rstn_i,
    input  logic                      en_i,
    input  logic [NUM_INPUT-1:0]    input_a_i,
    input  logic [NUM_INPUT-1:0]    input_b_i,
    output logic [$clog2(HDC_DIM)-1:0]    output_o
);
    logic [NUM_INPUT-1:0] add_input;
    logic [NUM_INPUT/2-1:0][1:0] adder_output_stage_0;
    logic [NUM_INPUT/4-1:0][2:0] adder_output_stage_1;
    logic [NUM_INPUT/8-1:0][3:0] adder_output_stage_2;
    logic [NUM_INPUT/16-1:0][4:0] adder_output_stage_3;
    logic [NUM_INPUT/32-1:0][5:0] adder_output_stage_4;
    logic [$clog2(HDC_DIM)-1:0] accumulator_input;
    logic [$clog2(HDC_DIM)-1:0] accumulator_output_q, accumulator_output_d;

    genvar i;
    generate
    for (i = 0; i < NUM_INPUT; i++) begin: xor_
            assign add_input[i] = ~(input_a_i[i] ^ input_b_i[i]);
        end
    endgenerate

    generate
    for (i = 0; i < NUM_INPUT/2; i++) begin: add_stage_0
            assign adder_output_stage_0[i] = add_input[2*i] + add_input[2*i+1];
        end
    endgenerate

    generate
    for (i = 0; i < NUM_INPUT/4; i++) begin: add_stage_1
            assign adder_output_stage_1[i] = adder_output_stage_0[2*i] + adder_output_stage_0[2*i+1];
        end
    endgenerate

    generate
    for (i = 0; i < NUM_INPUT/8; i++) begin: add_stage_2
            assign adder_output_stage_2[i] = adder_output_stage_1[2*i] + adder_output_stage_1[2*i+1];
        end
    endgenerate

    generate
    for (i = 0; i < NUM_INPUT/16; i++) begin: add_stage_3
            assign adder_output_stage_3[i] = adder_output_stage_2[2*i] + adder_output_stage_2[2*i+1];
        end
    endgenerate

    generate
    for (i = 0; i < NUM_INPUT/32; i++) begin: add_stage_4
            assign adder_output_stage_4[i] = adder_output_stage_3[2*i] + adder_output_stage_3[2*i+1];
        end
    endgenerate

    assign accumulator_input = en_i ? {'0, adder_output_stage_4} : '0;
    assign accumulator_output_d = accumulator_output_q + accumulator_input;

    always_ff @(posedge clk_i) begin
        if (!rstn_i) begin
            accumulator_output_q <= '0;
        end else begin
            accumulator_output_q <= accumulator_output_d;
        end
    end

    assign output_o = accumulator_output_q;

endmodule

module predictor #(
    parameter int unsigned HDC_DIM = 2048,
    parameter int unsigned NUM_INPUT = 32,
    parameter int unsigned BIAS = 1024
)(
    input  logic                            clk_i,
    input  logic                            rstn_i,
    input  logic                            en_i,
    input  logic [NUM_INPUT-1:0]            hdc_input_i,
    input  logic [NUM_INPUT-1:0]            weight_input_i,
    output logic                            finish_o,
    output logic [$clog2(HDC_DIM)-1:0]      results_o
);
    localparam int unsigned NUM_ACCU = HDC_DIM / NUM_INPUT;

    logic xor_adder_en_d, xor_adder_en_q;
    logic xor_adder_rstn_i;
    logic finish_q, finish_d;
    logic [$clog2(NUM_ACCU)-1:0]    cnt_d, cnt_q;
    // logic [NUM_INPUT-1:0]         adder_input_a_d, adder_input_a_q;
    // logic [NUM_INPUT-1:0]         adder_input_b_d, adder_input_b_q;
    logic [NUM_INPUT-1:0]           adder_input_a, adder_input_b;
    logic [$clog2(HDC_DIM)-1:0]     adder_output_o;

    xor_adder #(
        .NUM_INPUT (NUM_INPUT),
        .HDC_DIM     (HDC_DIM)
    ) u_xor_adder (
        .clk_i          (clk_i),
        .rstn_i         (xor_adder_rstn_i),
        .en_i           (xor_adder_en_q),
        .input_a_i      (adder_input_a),
        .input_b_i      (adder_input_b),
        .output_o       (adder_output_o)
    );

    // FSM definition
    typedef enum logic [1:0]{
        IDLE,
        LOAD,
        GEN_PRED_SUM,
        FINISH
    } state_e;
    state_e state_q, state_d;

    always_comb begin

        case (state_q)
            IDLE: begin
                xor_adder_rstn_i        = 1'b0;
                xor_adder_en_d          = en_i ? 1'b1 : 1'b0;
                adder_input_a           = en_i ? hdc_input_i : '0;
                adder_input_b           = en_i ? weight_input_i : '0;
                results_o               = '0;
                cnt_d                   = '0;
                finish_d                = 1'b 0;
                state_d                 = en_i ? GEN_PRED_SUM : IDLE;
            end

            GEN_PRED_SUM: begin
                xor_adder_en_d          = 1'b1;
                xor_adder_rstn_i        = 1'b1;
                adder_input_a           = hdc_input_i;
                adder_input_b           = weight_input_i;
                results_o               = '0;
                cnt_d                   = (cnt_q == NUM_ACCU-1) ? '0 : cnt_q + 1'b1;
                finish_d                = (cnt_q == NUM_ACCU-1) ? 1'b1 : 1'b0;
                state_d                 = (cnt_q == NUM_ACCU-1) ? FINISH : GEN_PRED_SUM;
            end

            FINISH: begin
                xor_adder_en_d          = 1'b0;
                xor_adder_rstn_i        = 1'b0;
                adder_input_a           = '0;
                adder_input_b           = '0;
                results_o               = {1'b0,adder_output_o} - BIAS;
                cnt_d                   = '0;
                finish_d                = 1'b0;
                state_d                 = IDLE;
            end

            default: begin
                xor_adder_rstn_i        = 1'b0;
                xor_adder_en_d          = 1'b0;
                adder_input_a           = '0;
                adder_input_b           = '0;
                results_o               = '0;
                cnt_d                   = '0;
                finish_d                = 1'b0;
                state_d                 = IDLE;
            end
        endcase

    end


    always_ff @(posedge clk_i or negedge rstn_i) begin
        if (!rstn_i) begin
            cnt_q                   <= '0;
            state_q                 <= IDLE;
            finish_q                <= '0;
            xor_adder_en_q          <= '0;
        end else begin
            cnt_q                   <= cnt_d;
            state_q                 <= state_d;
            finish_q                <= finish_d;
            xor_adder_en_q          <= xor_adder_en_d;
        end
    end

    assign finish_o = finish_q;


endmodule