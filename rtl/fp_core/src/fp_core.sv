// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
`include "misc_common/registers.svh"
module fp_core #(
    parameter                           PARALLEL_WIDTH              = 2                    , // 2^n
    parameter                           AXI_ADDR_WIDTH              = 12                   ,
    parameter                           AXI_DATA_WIDTH              = 64                   ,
    parameter int                       INPUT_REG_STAGES            = 2                    , // Input register stages (min 1)
    parameter int                       OUTPUT_REG_STAGES           = 2                    , // Output register stages (min 1)
    localparam                          PARALLEL_WIDTH_QUANT        = (PARALLEL_WIDTH+31)/32,
    localparam int ACCUM_STEPS = 32 / PARALLEL_WIDTH
) (
    input  logic                        clk_i                      ,
    input  logic                        rstn_i                     ,
    input  logic                        req_i                      ,
    input  logic                        we_i                       ,
    input  logic         [AXI_ADDR_WIDTH-1: 0]      addr_i                     ,
    input  logic         [AXI_DATA_WIDTH-1: 0]      wdata_i                    ,
    output logic         [AXI_DATA_WIDTH-1: 0]      rdata_o                    ,
    output logic                                    rvalid_o
);

    // ============================================================================
    // Local Parameters
    // ============================================================================

    // ============================================================================
    // Signal Declarations
    // ============================================================================

    // --- Address Decode Signals ---
    logic                               mx_sf_in_buf_req            ;
    logic                               mx_man_in_buf_req           ;
    logic                               mx_sf_out_buf_req           ;
    logic                               mx_man_out_buf_req          ;
    logic                               calc_reg_req                ;
    logic                               calc_result_req             ;
    logic                               csr_req                     ;
    logic                               mx_sf_in_buf_we             ;
    logic                               mx_man_in_buf_we            ;
    logic                               calc_reg_we                 ;
    logic              [   6: 0]        mx_sf_in_buf_addr           ;
    logic              [   7: 0]        mx_man_in_buf_addr          ;
    logic              [   3: 0]        mx_man_out_buf_addr         ;
    logic              [   2: 0]        calc_reg_addr               ;
    logic              [   0: 0]        csr_addr                    ;
    logic              [  63: 0]        mx_sf_in_buf_rdata_d        ;
    logic              [  63: 0]        mx_man_in_buf_rdata_d       ;
    logic              [  63: 0]        mx_sf_out_buf_rdata_d       ;
    logic              [  63: 0]        mx_man_out_buf_rdata_d      ;
    logic              [  63: 0]        calc_reg_rdata_d            ;
    logic              [  63: 0]        calc_result_rdata_d         ;
    logic              [  63: 0]        csr_rdata_d                 ;

    // --- Memory Arrays (use _q suffix for register outputs) ---
    logic              [255:0][63: 0]        mx_man_in_mem_q             ;
    logic              [127:0][63: 0]        mx_sf_in_mem_q              ;
    logic              [15:0][63: 0]        mx_man_out_mem_q            ;
    logic              [15:0][63: 0]        mx_man_out_mem_d            ;
    logic              [0:0][63: 0]        mx_sf_out_mem_q             ;
    logic              [0:0][63: 0]        mx_sf_out_mem_d             ;

    // --- Calculation Registers (4 x 128-bit = 8 x 64-bit) ---
    logic              [7:0][63: 0]        calc_reg_q                  ;
    logic              [7:0][63: 0]        calc_reg_d                  ;
    logic signed       [  31: 0]        calc_result                 ;

    // --- Data Path Signals ---
    logic              [PARALLEL_WIDTH-1:0][3:0][15: 0]        mx_man_i                    ;
    logic              [PARALLEL_WIDTH-1:0][3:0][7: 0]        mx_sf_i                     ;
    logic              [PARALLEL_WIDTH-1:0][3:0][15: 0]        mx_man_i_q                  ; // Registered for timing
    logic              [PARALLEL_WIDTH-1:0][3:0][7: 0]        mx_sf_i_q                   ; // Registered for timing
    logic              [PARALLEL_WIDTH-1:0][3:0][15: 0]        bf_o                        ;
    logic              [PARALLEL_WIDTH-1:0][3:0][15: 0]        bf_o_q                      ;

    logic              [PARALLEL_WIDTH-1:0][1:0][15: 0]        operand_stage_0_0           ;
    logic              [PARALLEL_WIDTH-1:0][1:0][15: 0]        operand_stage_0_1           ;
    logic              [PARALLEL_WIDTH-1:0][1:0][15: 0]        operand_stage_1             ;
    logic              [PARALLEL_WIDTH-1:0][15: 0]        result_0_0                  ;
    logic              [PARALLEL_WIDTH-1:0][15: 0]        result_0_1                  ;
    logic              [PARALLEL_WIDTH-1:0][15: 0]        result_1                    ;
    logic              [PARALLEL_WIDTH-1:0][15: 0]        result_0_0_q                ;
    logic              [PARALLEL_WIDTH-1:0][15: 0]        result_0_1_q                ;
    logic              [PARALLEL_WIDTH-1:0][15: 0]        result_1_q                  ;
    fpnew_pkg::status_t [PARALLEL_WIDTH-1:0]              status_0_0                 ;
    fpnew_pkg::status_t [PARALLEL_WIDTH-1:0]              status_0_1                 ;
    fpnew_pkg::status_t [PARALLEL_WIDTH-1:0]              status_1                   ;

    // --- Quantization Interface ---
    logic              [PARALLEL_WIDTH_QUANT-1:0][31:0][15: 0]        bf_group_i                  ;
    logic                               mode_i                      ;
    logic              [PARALLEL_WIDTH_QUANT-1:0][31:0][3: 0]        mx_man_group_o              ;
    logic              [PARALLEL_WIDTH_QUANT-1:0][7: 0]        mx_sf_o                     ;

    // --- CSR Registers ---
    logic              [1:0][63: 0]        control_reg_q               ;
    logic              [1:0][63: 0]        control_reg_d               ;
    logic                               start                       ;
    logic                               done                        ;
    logic                               done_pulse                  ;
    // --- State Machine ---
    typedef enum logic {
        S_IDLE,
        S_COMPUTE
    } state_e;
    state_e                             state_q                    ;
    state_e                             state_d                    ;

    // --- Processing Counters ---
    logic              [   8: 0]        processed_q                 ;
    logic              [   8: 0]        processed_d                 ;
    logic              [   2: 0]        current_m_q                 ;
    logic              [   2: 0]        current_m_d                 ;
    logic                               done_sig                    ;

    // --- Accumulator (for PARALLEL_WIDTH < 32) ---
    logic              [   4: 0]        accum_cnt_q                 ;
    logic              [   4: 0]        accum_cnt_d                 ;
    logic              [   4: 0]        sub_cnt_q                   ;
    logic              [   4: 0]        sub_cnt_d                   ;
    logic              [31:0][15: 0]        bf_accum_q                  ;
    logic              [31:0][15: 0]        bf_accum_d                  ;

    // --- Valid Pipeline ---
    logic                               valid_in                    ;
    logic                               valid_stage_0_q             ; // After mx_man_i_q/mx_sf_i_q
    logic                               valid_stage_1_q             ; // After bf_o_q
    logic                               valid_stage_2_q             ; // After result_0_x_q
    logic                               valid_stage_3_q             ; // After result_1_q
    logic                               valid_stage_4_q             ; // For pipelined quant

    // --- Quantization Enable ---
    logic                               quant_in_valid              ; // Data entering quant
    logic                               quant_en                    ; // Quant output valid (delayed)

    // --- Address and Index ---
    logic              [  11: 0]        local_addr                  ;
    logic              [   7: 0]        base_n                      ;

    // --- Input Pipeline Registers ---
    logic                        req_pipe   [INPUT_REG_STAGES:0];
    logic                        we_pipe    [INPUT_REG_STAGES:0];
    logic [AXI_ADDR_WIDTH-1:0]   addr_pipe  [INPUT_REG_STAGES:0];
    logic [AXI_DATA_WIDTH-1:0]   wdata_pipe [INPUT_REG_STAGES:0];

    // Connect input to pipe[0]
    assign req_pipe[0]   = req_i;
    assign we_pipe[0]    = we_i;
    assign addr_pipe[0]  = addr_i;
    assign wdata_pipe[0] = wdata_i;

    // Generate input pipeline stages
    generate
        for (genvar s = 1; s <= INPUT_REG_STAGES; s++) begin : gen_input_pipe
            always_ff @(posedge clk_i or negedge rstn_i) begin
                if (!rstn_i) begin
                    req_pipe[s]   <= 1'b0;
                    we_pipe[s]    <= 1'b0;
                    addr_pipe[s]  <= '0;
                    wdata_pipe[s] <= '0;
                end else begin
                    req_pipe[s]   <= req_pipe[s-1];
                    we_pipe[s]    <= we_pipe[s-1];
                    addr_pipe[s]  <= addr_pipe[s-1];
                    wdata_pipe[s] <= wdata_pipe[s-1];
                end
            end
        end
    endgenerate

    // Final input signals for internal logic
    logic                        req_q;
    logic                        we_q;
    logic [AXI_ADDR_WIDTH-1:0]   addr_q;
    logic [AXI_DATA_WIDTH-1:0]   wdata_q;

    assign req_q   = req_pipe[INPUT_REG_STAGES];
    assign we_q    = we_pipe[INPUT_REG_STAGES];
    assign addr_q  = addr_pipe[INPUT_REG_STAGES];
    assign wdata_q = wdata_pipe[INPUT_REG_STAGES];

    // --- Output Pipeline Registers ---
    logic              [  63: 0] rdata_d;            // Mux output before register
    logic              [  63: 0] rdata_pipe  [OUTPUT_REG_STAGES:0];
    logic                        rvalid_pipe [OUTPUT_REG_STAGES:0];

    // Connect internal signals to pipe[0]
    assign rdata_pipe[0]  = rdata_d;
    assign rvalid_pipe[0] = req_pipe[INPUT_REG_STAGES];  // Use the last input stage req

    // Generate output pipeline stages
    generate
        for (genvar s = 1; s <= OUTPUT_REG_STAGES; s++) begin : gen_output_pipe
            always_ff @(posedge clk_i or negedge rstn_i) begin
                if (!rstn_i) begin
                    rdata_pipe[s]  <= 64'hca11ab1ebadcab1e;
                    rvalid_pipe[s] <= 1'b0;
                end else begin
                    rdata_pipe[s]  <= rdata_pipe[s-1];
                    rvalid_pipe[s] <= rvalid_pipe[s-1];
                end
            end
        end
    endgenerate

    // Final output signals
    assign rdata_o  = rdata_pipe[OUTPUT_REG_STAGES];
    assign rvalid_o = rvalid_pipe[OUTPUT_REG_STAGES];


    // ============================================================================
    // Address Decode Logic
    // ============================================================================
    always_comb begin : address_decode
        local_addr = addr_q[11:0];

        // Default values
        mx_man_in_buf_req   = 1'b0;
        mx_sf_in_buf_req    = 1'b0;
        mx_man_out_buf_req  = 1'b0;
        mx_sf_out_buf_req   = 1'b0;
        calc_reg_req        = 1'b0;
        calc_result_req     = 1'b0;
        csr_req             = 1'b0;
        mx_man_in_buf_we    = 1'b0;
        mx_sf_in_buf_we     = 1'b0;
        calc_reg_we         = 1'b0;
        mx_man_in_buf_addr  = 8'b0;
        mx_sf_in_buf_addr   = 7'b0;
        mx_man_out_buf_addr = 4'b0;
        calc_reg_addr       = 3'b0;
        csr_addr            = 1'b0;

        if (req_q) begin
            if (local_addr < 12'h800) begin
                // 0x0000 - 0x07FF: mx_man_in (2048 bytes, 256 x 64-bit)
                mx_man_in_buf_req  = 1'b1;
                mx_man_in_buf_we   = we_q;
                mx_man_in_buf_addr = local_addr[10:3];
            end else if (local_addr < 12'hC00) begin
                // 0x0800 - 0x0BFF: mx_sf_in (1024 bytes, 128 x 64-bit)
                mx_sf_in_buf_req  = 1'b1;
                mx_sf_in_buf_we   = we_q;
                mx_sf_in_buf_addr = local_addr[9:3] - (12'h800 >> 3);
            end else if (local_addr < 12'hC80) begin
                // 0x0C00 - 0x0C7F: mx_man_out (128 bytes, 16 x 64-bit, read-only)
                mx_man_out_buf_req  = 1'b1;
                mx_man_out_buf_addr = local_addr[6:3] - (12'hC00 >> 3);
            end else if (local_addr < 12'hC88) begin
                // 0x0C80 - 0x0C87: mx_sf_out (8 bytes, 1 x 64-bit, read-only)
                mx_sf_out_buf_req = 1'b1;
            end else if (local_addr < 12'hCC8) begin
                // 0x0C88 - 0x0CC7: calc_reg (64 bytes, 8 x 64-bit, read-write)
                calc_reg_req  = 1'b1;
                calc_reg_we   = we_q;
                calc_reg_addr = local_addr[5:3] - (12'hC88 >> 3);
            end else if (local_addr < 12'hCD0) begin
                // 0x0CC8 - 0x0CCF: calc_result (8 bytes, 1 x 64-bit, read-only)
                calc_result_req = 1'b1;
            end else if (local_addr < 12'hCE0) begin
                // 0x0CD0 - 0x0CDF: CSR registers (16 bytes, 2 x 64-bit)
                csr_req  = 1'b1;
                csr_addr = local_addr[3:3] - (12'hCD0 >> 3);
            end
        end
    end

    // ============================================================================
    // CSR Bit Assignments
    // ============================================================================
    assign                              mode_i                      = control_reg_q[0][0]  ;// Bit 0: Mode selection
    assign                              start                       = control_reg_q[0][1]  ;// Bit 1: Start signal
    assign                              done                        = control_reg_q[0][2]  ;// Bit 2: Done signal
    logic                               power_mode                  ;                       // Bit 4: Power test mode (loop forever)
    assign                              power_mode                  = control_reg_q[0][4]  ;// Bit 4: Power mode enable

    // ============================================================================
    // CSR Register Logic
    // ============================================================================
    // --- Next State Logic (Combinational) ---
    always_comb begin : csr_next_state
        control_reg_d = control_reg_q;

        if (csr_req && we_q) begin
            // External write access
            if (csr_addr == 0) begin
                automatic logic [63:0] new_value = wdata_q;
                // Bit 3 is reserved: writes are ignored and reads return zero.
                new_value[3] = 1'b0;
                // Clear done when start transitions from 0 to 1
                if (new_value[1] && !control_reg_q[0][1]) begin
                    new_value[2] = 1'b0;
                end
                // Clear done when power_mode is enabled
                if (new_value[4] && !control_reg_q[0][4]) begin
                    new_value[2] = 1'b0;
                end
                control_reg_d[0] = new_value;
            end else begin
                control_reg_d[csr_addr] = wdata_q;
            end
        end else begin
            // Internal hardware updates
            // In power_mode, never set done; otherwise use done_pulse
            if (done_pulse && !power_mode) begin
                control_reg_d[0][1] = 1'b0;                         // Clear start
                control_reg_d[0][2] = 1'b1;                         // Set done
            end
        end
    end

    // --- Register Update (Sequential) ---
    always_ff @(posedge clk_i or negedge rstn_i) begin : csr_register
        if (!rstn_i) begin
            control_reg_q <= '0;
        end else begin
            control_reg_q <= control_reg_d;
        end
    end

    assign                              csr_rdata_d                   = control_reg_q[csr_addr];

    // ============================================================================
    // Input Memory Logic
    // ============================================================================
    // --- mx_man_in_mem ---
    always_ff @(posedge clk_i or negedge rstn_i) begin : mx_man_in_mem_register
        if (!rstn_i) begin
            for (int i = 0; i < 256; i++) begin
                mx_man_in_mem_q[i] <= 64'b0;
            end
        end else if (mx_man_in_buf_req && mx_man_in_buf_we) begin
            mx_man_in_mem_q[mx_man_in_buf_addr] <= wdata_q;
        end
    end
    assign                              mx_man_in_buf_rdata_d         = mx_man_in_mem_q[mx_man_in_buf_addr];

    // --- mx_sf_in_mem ---
    always_ff @(posedge clk_i or negedge rstn_i) begin : mx_sf_in_mem_register
        if (!rstn_i) begin
            for (int i = 0; i < 128; i++) begin
                mx_sf_in_mem_q[i] <= 64'b0;
            end
        end else if (mx_sf_in_buf_req && mx_sf_in_buf_we) begin
            mx_sf_in_mem_q[mx_sf_in_buf_addr] <= wdata_q;
        end
    end
    assign                              mx_sf_in_buf_rdata_d          = mx_sf_in_mem_q[mx_sf_in_buf_addr];

    // ============================================================================
    // Calculation Register Logic
    // ============================================================================
    // --- Next State Logic (Combinational) ---
    always_comb begin : calc_reg_next_state
        calc_reg_d = calc_reg_q;

        if (calc_reg_req && calc_reg_we) begin
            calc_reg_d[calc_reg_addr] = wdata_q;
        end
    end

    // --- Register Update (Sequential) ---
    always_ff @(posedge clk_i or negedge rstn_i) begin : calc_reg_register
        if (!rstn_i) begin
            for (int i = 0; i < 8; i++) begin
                calc_reg_q[i] <= 64'b0;
            end
        end else begin
            calc_reg_q <= calc_reg_d;
        end
    end

    assign calc_reg_rdata_d = calc_reg_q[calc_reg_addr];

    // --- Calculation Logic (Pure Combinational) ---
    // calc_reg layout: 4 x 128-bit stored as 8 x 64-bit
    // calc_reg[0:1] = first 128-bit:  [0][31:0]=int0, [0][63:32]=int1, [1][31:0]=int2, [1][63:32]=int3
    // calc_reg[2:3] = second 128-bit: [2][31:0]=int0, [2][63:32]=int1, [3][31:0]=int2, [3][63:32]=int3
    // calc_reg[4:5] = third 128-bit:  [4][31:0]=int0, [4][63:32]=int1, [5][31:0]=int2, [5][63:32]=int3
    // calc_reg[6:7] = fourth 128-bit: [6][31:0]=int0, [6][63:32]=int1, [7][31:0]=int2, [7][63:32]=int3
    //
    // a = sum of all int0 (bits 0-31 of each 128-bit)
    // b = sum of all int1 (bits 32-63 of each 128-bit)
    // c = sum of all int2 (bits 64-95 of each 128-bit)
    // d = sum of all int3 (bits 96-127 of each 128-bit)
    // result = 4 * (1*a + 2*b + 64*c + 128*d)
    always_comb begin : calc_result_logic
        automatic logic signed [31:0] a, b, c, d;
        automatic logic signed [31:0] weighted_sum;

        // Extract and sum the first 32-bit integer from each 128-bit register
        a = $signed(calc_reg_q[0][31:0])  + $signed(calc_reg_q[2][31:0])  +
            $signed(calc_reg_q[4][31:0])  + $signed(calc_reg_q[6][31:0]);

        // Extract and sum the second 32-bit integer from each 128-bit register
        b = $signed(calc_reg_q[0][63:32]) + $signed(calc_reg_q[2][63:32]) +
            $signed(calc_reg_q[4][63:32]) + $signed(calc_reg_q[6][63:32]);

        // Extract and sum the third 32-bit integer from each 128-bit register
        c = $signed(calc_reg_q[1][31:0])  + $signed(calc_reg_q[3][31:0])  +
            $signed(calc_reg_q[5][31:0])  + $signed(calc_reg_q[7][31:0]);

        // Extract and sum the fourth 32-bit integer from each 128-bit register
        d = $signed(calc_reg_q[1][63:32]) + $signed(calc_reg_q[3][63:32]) +
            $signed(calc_reg_q[5][63:32]) + $signed(calc_reg_q[7][63:32]);

        // Calculate: 4 * (1*a + 2*b + 64*c + 128*d)
        weighted_sum = a + (b <<< 1) + (c <<< 6) + (d <<< 7);
        calc_result  = weighted_sum <<< 2;
    end

    // Extend to 64-bit with zero padding for bus alignment
    assign calc_result_rdata_d = {{32{calc_result[31]}}, calc_result};

    // ============================================================================
    // Output Memory Logic
    // ============================================================================
    assign                              mx_man_out_buf_rdata_d        = mx_man_out_mem_q[mx_man_out_buf_addr];
    assign                              mx_sf_out_buf_rdata_d         = mx_sf_out_mem_q[0]   ;

    // --- Next State Logic for Output Memories (Combinational) ---
    always_comb begin : output_mem_next_state
        mx_man_out_mem_d = mx_man_out_mem_q;
        mx_sf_out_mem_d  = mx_sf_out_mem_q;

        // Clear output memories only when actually transitioning to S_COMPUTE
        if (state_q == S_IDLE && state_d == S_COMPUTE) begin
            for (int i = 0; i < 16; i++) begin
                mx_man_out_mem_d[i] = 64'b0;
            end
            mx_sf_out_mem_d[0] = 64'b0;
        end else begin
            // Store the uncompressed quantized mantissas and scale factors.
            // Note: current_m_q is correct here because it only increments when quant_en=1
            if (quant_en) begin
                for (int q = 0; q < PARALLEL_WIDTH_QUANT; q++) begin
                    automatic logic [2:0] m = current_m_q + q;
                    automatic logic [63:0] man_low  = 64'b0;
                    automatic logic [63:0] man_high = 64'b0;
                    automatic logic [7:0]  sf_part  = mx_sf_o[q];

                    for (int k = 0; k < 16; k++) begin
                        man_low[k*4 +: 4]  = mx_man_group_o[q][k];
                        man_high[k*4 +: 4] = mx_man_group_o[q][k+16];
                    end

                    mx_man_out_mem_d[2*m]        = man_low;
                    mx_man_out_mem_d[2*m+1]      = man_high;
                    mx_sf_out_mem_d[0][8*m +: 8] = sf_part;
                end
            end
        end
    end

    // --- Register Update for Output Memories (Sequential) ---
    always_ff @(posedge clk_i or negedge rstn_i) begin : output_mem_register
        if (!rstn_i) begin
            for (int i = 0; i < 16; i++) begin
                mx_man_out_mem_q[i] <= 64'b0;
            end
            mx_sf_out_mem_q[0] <= 64'b0;
        end else begin
            mx_man_out_mem_q <= mx_man_out_mem_d;
            mx_sf_out_mem_q  <= mx_sf_out_mem_d;
        end
    end

    // ============================================================================
    // Read Data Multiplexer (output to rdata_d, then registered to rdata_o)
    // ============================================================================
    always_comb begin : rdata_mux
        rdata_d = 64'hca11ab1ebadcab1e;
        if (mx_man_in_buf_req)
            rdata_d = mx_man_in_buf_rdata_d;
        else if (mx_sf_in_buf_req)
            rdata_d = mx_sf_in_buf_rdata_d;
        else if (mx_man_out_buf_req)
            rdata_d = mx_man_out_buf_rdata_d;
        else if (mx_sf_out_buf_req)
            rdata_d = mx_sf_out_buf_rdata_d;
        else if (calc_reg_req)
            rdata_d = calc_reg_rdata_d;
        else if (calc_result_req)
            rdata_d = calc_result_rdata_d;
        else if (csr_req)
            rdata_d = csr_rdata_d;
    end

    // ============================================================================
    // State Machine (Three-Segment Style)
    // ============================================================================

    // Completion is the cycle in which the final quantized group is stored.
    always_comb begin : fsm_next_state
        state_d    = state_q;
        done_sig   = 1'b0;
        done_pulse = 1'b0;
        case (state_q)
            S_IDLE: begin
                if (start || power_mode) state_d = S_COMPUTE;
            end
            S_COMPUTE: begin
                if (quant_en && ({1'b0, current_m_q} + PARALLEL_WIDTH_QUANT >= 8)) begin
                    done_sig   = 1'b1;
                    done_pulse = 1'b1;
                    state_d    = power_mode ? S_COMPUTE : S_IDLE;
                end
            end
            default: state_d = S_IDLE;
        endcase
    end

    always_ff @(posedge clk_i or negedge rstn_i) begin : fsm_state_register
        if (!rstn_i) state_q <= S_IDLE;
        else        state_q <= state_d;
    end

    // --- Segment 3: Output Logic (handled in other blocks) ---

    // ============================================================================
    // Processing Counter Logic
    // ============================================================================
    // --- Next State Logic (Combinational) ---
    always_comb begin : counter_next_state
        processed_d = processed_q;
        current_m_d = current_m_q;

        if (state_q == S_COMPUTE) begin
            // Stop issuing after 256 groups while the pipeline drains.
            // A free-running 9-bit counter wraps at 512 for wide configurations.
            if (processed_q < 9'd256)
                processed_d = processed_q + PARALLEL_WIDTH;
        end else begin
            processed_d = 9'b0;
        end

        if (quant_en) begin
            current_m_d = current_m_q + PARALLEL_WIDTH_QUANT;
        end

        // Reset counters when computation cycle completes (for power_mode loop)
        if (done_sig) begin
            current_m_d = 3'b0;
            processed_d = 9'b0;  // Also reset processed for power_mode restart
        end
    end

    // --- Register Update (Sequential) ---
    always_ff @(posedge clk_i or negedge rstn_i) begin : counter_register
        if (!rstn_i) begin
            processed_q <= 9'b0;
            current_m_q <= 3'b0;
        end else begin
            processed_q <= processed_d;
            current_m_q <= current_m_d;
        end
    end

    // ============================================================================
    // Valid Pipeline
    // ============================================================================
    assign                              valid_in                    = (state_q == S_COMPUTE) && (processed_q < 9'd256);

    `FF(valid_stage_0_q, valid_in,        1'b0, clk_i, rstn_i)  // After mx_man_i_q/mx_sf_i_q
    `FF(valid_stage_1_q, valid_stage_0_q, 1'b0, clk_i, rstn_i)  // After bf_o_q
    `FF(valid_stage_2_q, valid_stage_1_q, 1'b0, clk_i, rstn_i)  // After result_0_x_q
    `FF(valid_stage_3_q, valid_stage_2_q, 1'b0, clk_i, rstn_i)  // After result_1_q
    `FF(valid_stage_4_q, valid_stage_3_q, 1'b0, clk_i, rstn_i)  // For pipelined quant

    // ============================================================================
    // Accumulator Logic (for PARALLEL_WIDTH < 32)
    // ============================================================================
    generate
        if (PARALLEL_WIDTH < 32) begin : gen_accum_lt32
            // --- Next State Logic (Combinational) ---
            always_comb begin : accum_next_state
                bf_accum_d  = bf_accum_q;
                accum_cnt_d = accum_cnt_q;
                sub_cnt_d   = sub_cnt_q;

                if (valid_stage_3_q) begin
                    for (int i = 0; i < PARALLEL_WIDTH; i++) begin
                        bf_accum_d[accum_cnt_q + i] = result_1_q[i];
                    end
                    accum_cnt_d = accum_cnt_q + PARALLEL_WIDTH;
                    sub_cnt_d   = sub_cnt_q + 1;

                    if (sub_cnt_q == ACCUM_STEPS - 1) begin
                        sub_cnt_d   = 5'b0;
                        accum_cnt_d = 5'b0;
                    end
                end else begin
                    accum_cnt_d = 5'b0;
                    sub_cnt_d   = 5'b0;
                end
            end

            // --- Register Update (Sequential) ---
            always_ff @(posedge clk_i or negedge rstn_i) begin : accum_register
                if (!rstn_i) begin
                    accum_cnt_q <= 5'b0;
                    sub_cnt_q   <= 5'b0;
                    bf_accum_q  <= '{default: 16'b0};
                end else begin
                    accum_cnt_q <= accum_cnt_d;
                    sub_cnt_q   <= sub_cnt_d;
                    bf_accum_q  <= bf_accum_d;
                end
            end

    assign                              bf_group_i[0]               = bf_accum_d           ;

        end else begin : gen_direct_ge32
            for (genvar q = 0; q < PARALLEL_WIDTH_QUANT; q++) begin : assign_bf_groups
    assign                              bf_group_i[q]               = result_1_q[q*32 +: 32];
            end
        end
    endgenerate

    // ============================================================================
    // Quantization Enable Logic (with pipeline delay)
    // ============================================================================
    // quant_in_valid: indicates data is entering quant (combinational)
    // quant_en: indicates quant output is valid (delayed by 1 cycle for pipelined quant)

    always_comb begin : quant_enable_logic
        quant_in_valid = 1'b0;
        if (valid_stage_3_q) begin
            if (PARALLEL_WIDTH < 32) begin
                if (sub_cnt_q == ACCUM_STEPS - 1) begin
                    quant_in_valid = 1'b1;
                end
            end else begin
                quant_in_valid = 1'b1;
            end
        end
    end

    // Delay quant_in_valid by 1 cycle to get quant_en (for pipelined quant output)
    `FF(quant_en, quant_in_valid, 1'b0, clk_i, rstn_i)

    // ============================================================================
    // Input Data Loading Logic
    // ============================================================================
    assign                              base_n                      = processed_q[7:0]     ;

    always_comb begin : input_loading
        for (int i = 0; i < PARALLEL_WIDTH; i++) begin
            automatic logic [7:0] n = base_n + i;
            automatic logic [7:0] n_mod32_div8 = n[4:3];
            automatic logic [1:0] n_mod8_div4  = n[2];
            automatic logic [7:0] n_div32_times2 = (n >> 5) << 1;
            automatic logic [7:0] index0 = (n_mod32_div8 << 6) + {6'b0, n_mod8_div4} + n_div32_times2;
            automatic logic [7:0] index1 = index0 + 8'd16;
            automatic logic [7:0] index2 = index0 + 8'd32;
            automatic logic [7:0] index3 = index0 + 8'd48;

            automatic logic [5:0] low_bit_man = {n[1:0], 4'b0};

            automatic logic [63:0] man_word0 = mx_man_in_mem_q[index0];
            automatic logic [63:0] man_word1 = mx_man_in_mem_q[index1];
            automatic logic [63:0] man_word2 = mx_man_in_mem_q[index2];
            automatic logic [63:0] man_word3 = mx_man_in_mem_q[index3];

            automatic logic [7:0] n_div32 = n[7:5];
            automatic logic [1:0] n_mod32_div8_sf = n[4:3];
            automatic logic [6:0] index_sf0 = {2'b0, n_div32} + {n_mod32_div8_sf, 5'b0};
            automatic logic [6:0] index_sf1 = index_sf0 + 7'd8;
            automatic logic [6:0] index_sf2 = index_sf0 + 7'd16;
            automatic logic [6:0] index_sf3 = index_sf0 + 7'd24;

            automatic logic [5:0] low_bit_sf = {n[2:0], 3'b0};

            automatic logic [63:0] sf_word0 = mx_sf_in_mem_q[index_sf0];
            automatic logic [63:0] sf_word1 = mx_sf_in_mem_q[index_sf1];
            automatic logic [63:0] sf_word2 = mx_sf_in_mem_q[index_sf2];
            automatic logic [63:0] sf_word3 = mx_sf_in_mem_q[index_sf3];

            mx_man_i[i][0] = man_word0[low_bit_man +: 16];
            mx_man_i[i][1] = man_word1[low_bit_man +: 16];
            mx_man_i[i][2] = man_word2[low_bit_man +: 16];
            mx_man_i[i][3] = man_word3[low_bit_man +: 16];

            mx_sf_i[i][0] = sf_word0[low_bit_sf +: 8];
            mx_sf_i[i][1] = sf_word1[low_bit_sf +: 8];
            mx_sf_i[i][2] = sf_word2[low_bit_sf +: 8];
            mx_sf_i[i][3] = sf_word3[low_bit_sf +: 8];
        end
    end

    // ============================================================================
    // Pipeline Registers
    // ============================================================================
    `FF(mx_man_i_q,    mx_man_i,    '0, clk_i, rstn_i)  // Register before int2bf
    `FF(mx_sf_i_q,     mx_sf_i,     '0, clk_i, rstn_i)  // Register before int2bf
    `FF(bf_o_q,        bf_o,        '0, clk_i, rstn_i)
    `FF(result_0_0_q,  result_0_0,  '0, clk_i, rstn_i)
    `FF(result_0_1_q,  result_0_1,  '0, clk_i, rstn_i)
    `FF(result_1_q,    result_1,    '0, clk_i, rstn_i)

    // ============================================================================
    // Adder Operand Assignment
    // ============================================================================
    always_comb begin : operand_assignment
        for (int w = 0; w < PARALLEL_WIDTH; w++) begin
            // Stage 0 operands (from int2bf output register)
            operand_stage_0_0[w][0] = bf_o_q[w][0];
            operand_stage_0_0[w][1] = bf_o_q[w][1];
            operand_stage_0_1[w][0] = bf_o_q[w][2];
            operand_stage_0_1[w][1] = bf_o_q[w][3];

            // Stage 1 operands (from stage 0 result registers)
            operand_stage_1[w][0] = result_0_0_q[w];
            operand_stage_1[w][1] = result_0_1_q[w];
        end
    end

    // ============================================================================
    // Module Instantiations
    // ============================================================================

    // --- INT2BF Converters ---
    generate
        for (genvar i = 0; i < PARALLEL_WIDTH; i++) begin : gen_int2_bf
            for (genvar j = 0; j < 4; j++) begin : gen_int2_bf_inner
                int2bf u_int2bf (
    .mx_man_i                           (mx_man_i_q[i][j]          ),  // Use registered input
    .mx_sf_i                            (mx_sf_i_q[i][j]           ),  // Use registered input
    .rnd_mode_i                         (fpnew_pkg::RNE            ),
    .bf_o                               (bf_o[i][j]                )
                );
            end
        end
    endgenerate

    // --- Floating Point Adders ---
    generate
        for (genvar i = 0; i < PARALLEL_WIDTH; i++) begin : gen_adder
            // Stage 0.0: Add elements 0 and 1
            fp_adder #(
    .FpFormat                           (fpnew_pkg::FP16ALT        ) 
            ) u_fp_adder_stage_0_0 (
    .operands_i                         (operand_stage_0_0[i]      ),
    .is_boxed_i                         (2'b11                     ),
    .rnd_mode_i                         (fpnew_pkg::RNE            ),
    .op_i                               (fpnew_pkg::ADD            ),
    .result_o                           (result_0_0[i]             ),
    .status_o                           (status_0_0[i]             ) 
            );

            // Stage 0.1: Add elements 2 and 3
            fp_adder #(
    .FpFormat                           (fpnew_pkg::FP16ALT        ) 
            ) u_fp_adder_stage_0_1 (
    .operands_i                         (operand_stage_0_1[i]      ),
    .is_boxed_i                         (2'b11                     ),
    .rnd_mode_i                         (fpnew_pkg::RNE            ),
    .op_i                               (fpnew_pkg::ADD            ),
    .result_o                           (result_0_1[i]             ),
    .status_o                           (status_0_1[i]             ) 
            );

            // Stage 1: Add results from stage 0
            fp_adder #(
    .FpFormat                           (fpnew_pkg::FP16ALT        ) 
            ) u_fp_adder_stage_1 (
    .operands_i                         (operand_stage_1[i]        ),
    .is_boxed_i                         (2'b11                     ),
    .rnd_mode_i                         (fpnew_pkg::RNE            ),
    .op_i                               (fpnew_pkg::ADD            ),
    .result_o                           (result_1[i]               ),
    .status_o                           (status_1[i]               ) 
            );
        end
    endgenerate

    // --- Quantizers (pipelined: 1 cycle latency) ---
    generate
        for (genvar i = 0; i < PARALLEL_WIDTH_QUANT; i++) begin : gen_quant
            quant u_quant (
    .clk_i                              (clk_i                     ),
    .rstn_i                             (rstn_i                    ),
    .bf_group_i                         (bf_group_i[i]             ),
    .mode_i                             (mode_i                    ),
    .mx_man_group_o                     (mx_man_group_o[i]         ),
    .mx_sf_o                            (mx_sf_o[i]                )
            );
        end
    endgenerate

endmodule
