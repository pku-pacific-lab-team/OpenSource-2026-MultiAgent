// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
//////////////////////////////////////////////////////////////////////////////////
// Description: HDC Encoder with LFSR-based Random Hypervector Generator
// Author:      Siyuan He [Peking University]
// Acknowledge: Cursor Agent
//////////////////////////////////////////////////////////////////////////////////

module hdc_lfsr_16bit #(
    parameter int unsigned SEED_WIDTH = 16,
    parameter int unsigned RANDOM_WIDTH = 16
)(
    input  logic                      clk_i,
    input  logic                      rstn_i,
    input  logic                      en_i,
    input  logic [SEED_WIDTH-1:0]     seed_i,
    output logic [RANDOM_WIDTH-1:0]   random_vector_o
);

    logic [RANDOM_WIDTH-1:0] shift_d, shift_q;
    logic shift_in;

    always_comb begin
        shift_in = !(shift_q[15] ^ shift_q[12] ^ shift_q[5] ^ shift_q[1]);

        if (en_i) begin
            shift_d = {shift_q[14:0], shift_in};
        end else begin
            shift_d = shift_q;
        end
    end

    // always_ff @(posedge clk_i or negedge rstn_i) begin : proc_
    always_ff @(posedge clk_i) begin
        if(~rstn_i) begin
            // shift_q <= {seed_i[14:0], !(seed_i[15] ^ seed_i[12] ^ seed_i[5] ^ seed_i[1])};
            shift_q <= seed_i;
        end else begin
            shift_q <= shift_d;
        end
    end

    assign random_vector_o = shift_q;
    
endmodule   


module hdc_vector_generator #(
    parameter int unsigned HDC_DIM = 2048,
    parameter int unsigned TOKEN_ID_WIDTH = 16,
    parameter int unsigned RANDOM_WIDTH = 16
)(
    input  logic                      clk_i,
    input  logic                      rstn_i,
    input  logic                      en_i,
    input  logic [TOKEN_ID_WIDTH-1:0] token_id_i,
    output logic                      finish_o,
    output logic [HDC_DIM-1:0]        hdc_vector_o
);

    // How many "16-bit blocks" are needed in total to make up 2048 bits
    localparam int unsigned NUM_WORDS = HDC_DIM / RANDOM_WIDTH;
    localparam int unsigned CNT_WIDTH = $clog2(NUM_WORDS);

    // LFSR interface signals
    logic                      lfsr_rstn_i;
    logic                      lfsr_en;
    logic [RANDOM_WIDTH-1:0]   lfsr_bin;

    // Instantiate an LFSR
    hdc_lfsr_16bit #(
        .SEED_WIDTH   (TOKEN_ID_WIDTH),
        .RANDOM_WIDTH (RANDOM_WIDTH)
    ) u_lfsr_16bit (
        .clk_i          (clk_i),
        .rstn_i         (lfsr_rstn_i),
        .en_i           (lfsr_en),
        .seed_i         (token_id_i),
        .random_vector_o (lfsr_bin)
    );

    // FSM definition
    typedef enum logic [1:0] {
        IDLE,       // Idle, waiting for en_i=1
        SEED_LFSR,  // Pull lfsr_rstn_i low so the LFSR loads the new seed
        GEN_VEC     // Sample the LFSR output once per cycle and fill it into hdc_vector_o
    } state_e;

    state_e state_q, state_d;

    logic [CNT_WIDTH-1:0] cnt_q, cnt_d;
    logic [HDC_DIM-1:0]   vec_q, vec_d;
    logic                 finish_q, finish_d;
    // Outputs

    // Combinational logic: state transitions + LFSR control
    always_comb begin
        case (state_q)
            IDLE: begin
                cnt_d = '0;
                finish_d = 1'b0;
                lfsr_en = 1'b0;
                lfsr_rstn_i = 1'b1;
                vec_d = '0;
                state_d = en_i ? SEED_LFSR : IDLE;
            end

            SEED_LFSR: begin
                // Pull rst low this cycle so that LFSR shift_q <= seed_i
                // Release rst next cycle and start the serial output
                cnt_d = '0;
                lfsr_en = 1'b0;
                lfsr_rstn_i = 1'b0;
                finish_d = 1'b0;
                vec_d = '0;
                state_d = GEN_VEC;
            end

            GEN_VEC: begin
                // Shift the LFSR once per cycle and write the current 16-bit state into the corresponding position of random_vector_o
                for (int i = 0; i < NUM_WORDS; i++) begin
                    vec_d[i*RANDOM_WIDTH +: RANDOM_WIDTH] = (i == cnt_q) ? lfsr_bin : vec_q[i*RANDOM_WIDTH +: RANDOM_WIDTH];
                end
                
                lfsr_rstn_i = 1'b1;
                if (cnt_q == NUM_WORDS-1) begin
                    // All 2048 bits are filled; stay in IDLE, vec_q holds the final result
                    lfsr_en     = 1'b0;
                    finish_d    = 1'b1;
                    cnt_d       = '0;
                    state_d     = IDLE;
                end else begin
                    lfsr_en     = 1'b1;
                    finish_d    = 1'b0;
                    cnt_d       = cnt_q + 1'b1;
                    state_d     = GEN_VEC;
                end
            end

            default: begin
                cnt_d = '0;
                finish_d = 1'b0;
                lfsr_en = 1'b0;
                lfsr_rstn_i = 1'b1;
                vec_d = '0;
                state_d = IDLE;
            end
        endcase
    end

    // State/registers
    always_ff @(posedge clk_i or negedge rstn_i) begin
        if (!rstn_i) begin
            state_q     <= IDLE;
            cnt_q       <= '0;
            vec_q       <= '0;
            finish_q    <= '0;
        end else begin
            state_q     <= state_d;
            cnt_q       <= cnt_d;
            vec_q       <= vec_d;
            finish_q    <= finish_d;
        end
    end

    assign finish_o     = finish_q;
    assign hdc_vector_o = finish_o ? vec_q : '0;

endmodule


module hdc_encoder #(
    parameter int unsigned HDC_DIM = 2048,
    parameter int unsigned TOKEN_ID_WIDTH = 16, 
    parameter int unsigned RANDOM_WIDTH = 16,
    parameter int unsigned N_TOKEN = 4
)(
    input  logic                      clk_i,
    input  logic                      rstn_i,
    input  logic                      en_i,
    input  logic [N_TOKEN-1:0][TOKEN_ID_WIDTH-1:0] token_id_i,
    output logic                      finish_o,
    output logic [HDC_DIM-1:0]        vector_o
);

    localparam int unsigned CNT_WIDTH = $clog2(N_TOKEN);
    logic [CNT_WIDTH-1:0]       cnt_q, cnt_d;
    logic [HDC_DIM-1:0]         partial_hdc_vector_q, partial_hdc_vector_d;
    logic [TOKEN_ID_WIDTH-1:0]  current_token_id;
    logic                       hdc_en_i;
    logic                       hdc_finish_o;
    logic [HDC_DIM-1:0]         hdc_vector_o;
    logic                       finish_q, finish_d;
    
    hdc_vector_generator #(
        .HDC_DIM       (HDC_DIM),
        .TOKEN_ID_WIDTH(TOKEN_ID_WIDTH),
        .RANDOM_WIDTH  (RANDOM_WIDTH)
    ) u_hdc_vector_generator (
        .clk_i          (clk_i),
        .rstn_i         (rstn_i),
        .en_i           (hdc_en_i),
        .token_id_i     (current_token_id),
        .finish_o       (hdc_finish_o),
        .hdc_vector_o   (hdc_vector_o)
    );

    // FSM definition
    typedef enum logic [1:0] {
        IDLE,       // Idle, waiting for en_i=1
        GEN_HDC_VECTOR,     // Sample the LFSR output once per cycle and fill it into random_vector_o
        UPDATE_TOKEN_ID  // Update token_id_q
    } state_e;

    state_e state_q, state_d;

    always_comb begin
        current_token_id = token_id_i[cnt_q];
        case (state_q)
            IDLE: begin
                cnt_d                   = '0;
                partial_hdc_vector_d    = '0;
                hdc_en_i                = 1'b0;
                finish_d                = 1'b0;
                state_d                 = en_i ? UPDATE_TOKEN_ID : IDLE;
            end

            UPDATE_TOKEN_ID: begin
                cnt_d = cnt_q;
                partial_hdc_vector_d = partial_hdc_vector_q;
                hdc_en_i      = 1'b1;
                finish_d    = 1'b0;
                state_d     = GEN_HDC_VECTOR;
            end
            
            GEN_HDC_VECTOR: begin
                if (hdc_finish_o) begin
                    partial_hdc_vector_d    = (partial_hdc_vector_q >> cnt_q) ^ hdc_vector_o;
                    cnt_d                   = cnt_q + 1'b1;
                    hdc_en_i                = (cnt_q == N_TOKEN-1) ? 1'b0 : 1'b1;
                    finish_d                = (cnt_q == N_TOKEN-1) ? 1'b1 : 1'b0;
                    state_d                 = (cnt_q == N_TOKEN-1) ? IDLE : UPDATE_TOKEN_ID;
                end else begin
                    partial_hdc_vector_d    = partial_hdc_vector_q;
                    cnt_d                   = cnt_q;
                    hdc_en_i                = 1'b1;
                    finish_d                = 1'b0;
                    state_d                 = GEN_HDC_VECTOR;
                end
            end
            default: begin
                cnt_d                   = '0;
                partial_hdc_vector_d    = '0;
                hdc_en_i                = 1'b0;
                finish_d                = 1'b0;
                state_d                 = IDLE;
            end

        endcase

    end


    always_ff @(posedge clk_i or negedge rstn_i) begin
        if (!rstn_i) begin
            cnt_q                   <= '0;
            state_q                 <= IDLE;
            partial_hdc_vector_q    <= '0;
            finish_q                <= '0;
        end else begin
            cnt_q                   <= cnt_d;
            state_q                 <= state_d;
            partial_hdc_vector_q    <= partial_hdc_vector_d;
            finish_q                <= finish_d;
        end
    end

    assign finish_o = finish_q;
    assign vector_o = finish_o ? partial_hdc_vector_q : '0;
    
endmodule
