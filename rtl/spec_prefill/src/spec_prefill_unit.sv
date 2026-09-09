// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
//////////////////////////////////////////////////////////////////////////////////
// Description: Speculative Prefill Unit including Encoder and Learner
// Author:      Siyuan He [Peking University]
// Acknowledge: Cursor Agent
//////////////////////////////////////////////////////////////////////////////////

module spec_prefill_unit #(
    parameter int unsigned ADDR_WIDTH  = 64,
    parameter int unsigned DATA_WIDTH  = 64,
    parameter int unsigned HDC_DIM        = 2048,
    parameter int unsigned WEIGHT_WIDTH   = 6,
    parameter int unsigned TOKEN_ID_WIDTH = 16,
    parameter int unsigned RANDOM_WIDTH   = 16,
    parameter int unsigned TOKEN_WINDOW   = 4,
    parameter int unsigned BIAS = 1024
)(
    input  logic                            clk_i,
    input  logic                            rstn_i,
    input  logic                            req_i,
    input  logic                            we_i,
    input  logic [ADDR_WIDTH-1:0]           addr_i,
    input  logic [1:0]                      rtsel_i,
    input  logic [1:0]                      wtsel_i,
    input  logic [DATA_WIDTH-1:0]           data_i,
    output  logic [DATA_WIDTH-1:0]          data_o
);
    localparam int unsigned WEIGHT_SRAM_IO_WIDTH  = 192;
    localparam int unsigned INPUT_SRAM_IO_WIDTH  = 32;
    localparam int unsigned HISTORY_WINDOW = 8;
    localparam int unsigned NUM_AGENT = 4;
    localparam int unsigned NUM_INPUT = WEIGHT_SRAM_IO_WIDTH / WEIGHT_WIDTH; //192/6=32
    localparam int unsigned NUM_ACCESS = HDC_DIM / NUM_INPUT; // 2048/32=64

    localparam logic [8:0] WEIGHT_START_ADDRESS = 9'd96;
    localparam logic [NUM_AGENT-1:0][8:0] AGENT_BASE_ADDRESS = {9'd288, 9'd224, 9'd160, 9'd96};
    localparam logic [HISTORY_WINDOW-1:0][8:0] HISTORY_BASE_ADDRESS = {9'd84, 9'd72, 9'd60, 9'd48, 9'd36, 9'd24, 9'd12, 9'd0};

    logic [15:0] sp_addr_i;
    assign sp_addr_i = addr_i[15:0];
    localparam logic [15:0] INPUT_SRAM_BASE_ADDRESS             = 16'h0000; //86*{64'breserved, 192'b data}
    localparam logic [15:0] WEIGHT_SRAM_BASE_ADDRESS            = 16'h1000; //256*{64'b reserved, 192'b data}
    localparam logic [15:0] TOKEN_ID_BUF_BASE_ADDRESS           = 16'h3000;
    localparam logic [15:0] PREDICTOR_O_BUF_BASE_ADDRESS        = 16'h3008;
    localparam logic [15:0] CSR_BASE_ADDRESS                    = 16'h3010;
    localparam logic [15:0] STATUS_BASE_ADDRESS                 = 16'h3018;

    //Status CSR
    //[1:0]: encoder_status: 00: idle, 01: busy, 10: finished
    //[3:2]: predictor_status: 00: idle, 01: busy, 10: finished
    //[5:4]: learner_status: 00: idle, 01: busy, 10: finished
    localparam logic [1:0] STATUS_IDLE = 2'b00;
    localparam logic [1:0] STATUS_BUSY = 2'b01;
    localparam logic [1:0] STATUS_FINISHED = 2'b10;
    logic [DATA_WIDTH-1:0]status_csr_q, status_csr_d;
    logic [1:0] encoder_status_q, encoder_status_d;
    logic [1:0] predictor_status_q, predictor_status_d;
    logic [1:0] learner_status_q, learner_status_d;

    //Buffer
    logic [TOKEN_WINDOW-1:0][TOKEN_ID_WIDTH-1:0]    token_id_buffer_q, token_id_buffer_d;
    logic [HDC_DIM-1:0]                             encoder_o_buffer_q, encoder_o_buffer_d;
    logic [NUM_AGENT-1:0][$clog2(HDC_DIM)-1:0]      predictor_o_buffer_q, predictor_o_buffer_d;


    //CSR
    //Control CSR
    //[1:0]: cmd 00: idle, 01: encoder, 10: predict, 11: learn
    //[3:2]: encoder_power_mode 00: idle, 01: work, 10: power_test
    //[5:4]: predictor_power_mode 00: idle, 01: work, 10: power_test
    //[7:6]: learner_power_mode 00: idle, 01: work, 10: power_test
    //[9:8]: 2b agent_id
    //[12:10]: 3b history_id
    //[13]: reward
    localparam logic [1:0] POWER_IDLE = 2'b00;
    localparam logic [1:0] POWER_WORK = 2'b01;
    localparam logic [1:0] POWER_POWER_TEST = 2'b10;
    localparam logic [1:0] CMD_IDLE = 2'b00;
    localparam logic [1:0] CMD_ENCODER = 2'b01;
    localparam logic [1:0] CMD_PREDICTOR = 2'b10;
    localparam logic [1:0] CMD_LEARNER = 2'b11;

    logic [DATA_WIDTH-1:0]ctrl_csr_q, ctrl_csr_d;
    logic [1:0] cmd;
    logic [1:0] encoder_power_mode;
    logic [1:0] predictor_power_mode;
    logic [1:0] learner_power_mode;
    logic [1:0] agent_id;
    logic [2:0] history_id;
    logic reward;
    assign cmd                      = ctrl_csr_q[1:0];
    assign encoder_power_mode       = ctrl_csr_q[3:2];
    assign predictor_power_mode     = ctrl_csr_q[5:4];
    assign learner_power_mode       = ctrl_csr_q[7:6];
    assign agent_id                 = ctrl_csr_q[9:8];
    assign history_id               = ctrl_csr_q[12:10];
    assign reward                   = ctrl_csr_q[13];

    logic encoder_en;
    logic predictor_en;
    logic learner_en;
 ///////////////////////////////////////////// CSR Control Logic ///////////////////////////////////////////
    always_comb begin
        case(encoder_power_mode)
            POWER_IDLE: begin
                encoder_en = 1'b0;
            end
            POWER_WORK: begin
                encoder_en = (cmd == CMD_ENCODER) ? 1'b1 : 1'b0;
            end
            POWER_POWER_TEST: begin
                encoder_en = 1'b1;
            end
            default: begin
                encoder_en = 1'b0;
            end
        endcase

        case(predictor_power_mode)
            POWER_IDLE: begin
                predictor_en = 1'b0;
            end
            POWER_WORK: begin
                predictor_en = (cmd == CMD_PREDICTOR) ? 1'b1 : 1'b0;
            end
            POWER_POWER_TEST: begin
                predictor_en = 1'b1;
            end
            default: begin
                predictor_en = 1'b0;
            end
        endcase

        case(learner_power_mode)
            POWER_IDLE: begin
                learner_en = 1'b0;
            end
            POWER_WORK: begin
                learner_en = (cmd == CMD_LEARNER) ? 1'b1 : 1'b0;
            end
            POWER_POWER_TEST: begin
                learner_en = 1'b1;
            end
            default: begin
                learner_en = 1'b0;
            end
        endcase
    end


    logic [DATA_WIDTH-1:0] ctrl_csr_cpu_d, ctrl_csr_encoder_d, ctrl_csr_learner_d, ctrl_csr_predictor_d;
    // written by cpu or encoder/learner/predictor, avoid repetitive work
    assign ctrl_csr_d = req_i ? ctrl_csr_cpu_d :
                        encoder_en ? ctrl_csr_encoder_d :
                        learner_en ? ctrl_csr_learner_d :
                        predictor_en ? ctrl_csr_predictor_d :
                        ctrl_csr_q;
    // CSR UPDATE
    always@(posedge clk_i or negedge rstn_i) begin
        if (!rstn_i) begin
            ctrl_csr_q <= '0;
        end else begin
            ctrl_csr_q <= ctrl_csr_d;
        end
    end


//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////// Sp_SPM Access Logic /////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // encoder as master
    logic sp_spm_encoder_ceb_i;
    logic sp_spm_encoder_web_i;
    logic [8:0] sp_spm_encoder_address_i;
    logic [191:0] sp_spm_encoder_data_i;
    logic [191:0] sp_spm_encoder_bweb_i;

    // predictor as master
    logic sp_spm_predictor_ceb_i;
    logic sp_spm_predictor_web_i;
    logic [8:0] sp_spm_predictor_address_i;
    logic [191:0] sp_spm_predictor_output_o;

    // learner as master
    logic sp_spm_learner_ceb_i;
    logic sp_spm_learner_web_i;
    logic [8:0] sp_spm_learner_address_i;
    logic [191:0] sp_spm_learner_data_i;
    logic [191:0] sp_spm_learner_output_o;

    // cpu as master
    logic sp_spm_cpu_ceb_i;
    logic sp_spm_cpu_web_i;
    logic [8:0] sp_spm_cpu_address_i;
    logic [191:0] sp_spm_cpu_data_i;
    logic [191:0] sp_spm_cpu_bweb_i;

    // weight sram io
    logic sp_spm_ceb_i;
    logic sp_spm_web_i;
    logic [8:0] sp_spm_address_i;
    logic [191:0] sp_spm_data_i;
    logic [191:0] sp_spm_bweb_i;
    logic [191:0] sp_spm_output_o;


    // Weight scratchpad. The die uses a 352x192 bit-maskable SRAM macro with
    // active-low CEB/WEB/BWEB pins and read/write timing selects (rtsel_i,
    // wtsel_i); the release wraps the behavioural model behind the same
    // active-low signals, and the timing selects are unused.
    sram_be_352x192 sp_spm (
        .clk_i          (clk_i),
        .chip_enable_i  (~sp_spm_ceb_i),
        .write_enable_i (~sp_spm_web_i),
        .addr_i         (sp_spm_address_i),
        .write_data_i   (sp_spm_data_i),
        .bit_enable_i   (~sp_spm_bweb_i),
        .read_data_o    (sp_spm_output_o)
    );


    // CPU access logic
    typedef enum logic [2:0] {
        ACCESS_IDLE = 3'b000,
        ACCESS_INPUT_SRAM = 3'b001,
        ACCESS_WEIGHT_SRAM = 3'b010,
        ACCESS_TOKEN_ID_BUF = 3'b011,
        ACCESS_PREDICTOR_O_BUF = 3'b100,
        ACCESS_CSR = 3'b101,
        ACCESS_STATUS = 3'b110
    } access_sel_e;

    // Temporary variables for weight SRAM address calculation
    logic [ADDR_WIDTH-1:0] addr_offset_d, addr_offset_q;
    access_sel_e access_sel_d, access_sel_q;
    logic access_we_d, access_we_q;


    // weight sram master mux
    assign sp_spm_ceb_i = (req_i & (access_sel_d == ACCESS_WEIGHT_SRAM || access_sel_d == ACCESS_INPUT_SRAM)) ? sp_spm_cpu_ceb_i :
                               encoder_en ? sp_spm_encoder_ceb_i :
                               predictor_en ? sp_spm_predictor_ceb_i :
                               learner_en ? sp_spm_learner_ceb_i : 1'b1;
    assign sp_spm_web_i = (req_i & (access_sel_d == ACCESS_WEIGHT_SRAM || access_sel_d == ACCESS_INPUT_SRAM)) ? sp_spm_cpu_web_i :
                               encoder_en ? sp_spm_encoder_web_i :
                               predictor_en ? sp_spm_predictor_web_i :
                               learner_en ? sp_spm_learner_web_i : 1'b1;
    assign sp_spm_address_i = (req_i & (access_sel_d == ACCESS_WEIGHT_SRAM || access_sel_d == ACCESS_INPUT_SRAM)) ? sp_spm_cpu_address_i :
                                    encoder_en ? sp_spm_encoder_address_i :
                                    predictor_en ? sp_spm_predictor_address_i :
                                    learner_en ? sp_spm_learner_address_i : '0;
    assign sp_spm_data_i = (req_i & (access_sel_d == ACCESS_WEIGHT_SRAM || access_sel_d == ACCESS_INPUT_SRAM)) ? sp_spm_cpu_data_i :
                                encoder_en ? sp_spm_encoder_data_i :
                                learner_en ? sp_spm_learner_data_i : '0;
    assign sp_spm_bweb_i = (req_i & (access_sel_d == ACCESS_WEIGHT_SRAM || access_sel_d == ACCESS_INPUT_SRAM)) ? sp_spm_cpu_bweb_i :
                                encoder_en ? sp_spm_encoder_bweb_i :
                                 '0;
    assign sp_spm_predictor_output_o = predictor_en ? sp_spm_output_o : '0;
    assign sp_spm_learner_output_o = learner_en ? sp_spm_output_o : '0;


    always_comb begin
        status_csr_d = {'0, learner_status_q, predictor_status_q, encoder_status_q};

        // STATE TRANSITION and write logic
        if (req_i) begin
            access_we_d = we_i;
            // address decode
            case (sp_addr_i) inside
                [INPUT_SRAM_BASE_ADDRESS:WEIGHT_SRAM_BASE_ADDRESS-1]: begin
                    access_sel_d = ACCESS_INPUT_SRAM;
                end
                [WEIGHT_SRAM_BASE_ADDRESS:TOKEN_ID_BUF_BASE_ADDRESS-1]: begin
                    access_sel_d = ACCESS_WEIGHT_SRAM;
                end
                TOKEN_ID_BUF_BASE_ADDRESS: begin
                    access_sel_d = ACCESS_TOKEN_ID_BUF;
                end
                PREDICTOR_O_BUF_BASE_ADDRESS: begin
                    access_sel_d = ACCESS_PREDICTOR_O_BUF;
                end
                CSR_BASE_ADDRESS: begin
                    access_sel_d = ACCESS_CSR;
                end
                STATUS_BASE_ADDRESS: begin
                    access_sel_d = ACCESS_STATUS;
                end
                default: access_sel_d = ACCESS_IDLE;
            endcase

            // input_sram
            if (access_sel_d == ACCESS_INPUT_SRAM) begin
                sp_spm_cpu_ceb_i = 1'b0;
                sp_spm_cpu_web_i = access_we_d ? 1'b0 : 1'b1;
                addr_offset_d = (sp_addr_i - INPUT_SRAM_BASE_ADDRESS);
                sp_spm_cpu_address_i = addr_offset_d[13:5];
                case (addr_offset_d[4:3])
                    2'b00: begin
                        sp_spm_cpu_data_i = access_we_d ? {128'b0, data_i} : '0;
                        sp_spm_cpu_bweb_i = {{128{1'b1}}, {64{1'b0}}};
                    end
                    2'b01: begin
                        sp_spm_cpu_data_i = access_we_d ? {64'b0, data_i, 64'b0} : '0;
                        sp_spm_cpu_bweb_i = {{64{1'b1}}, {64{1'b0}}, {64{1'b1}}};
                    end
                    2'b10: begin
                        sp_spm_cpu_data_i = access_we_d ? {data_i, 128'b0} : '0;
                        sp_spm_cpu_bweb_i = {{64{1'b0}}, {128{1'b1}}};
                    end
                    2'd3: begin
                        sp_spm_cpu_data_i = '0;
                        sp_spm_cpu_bweb_i = '1;
                    end
                    default:;
                endcase
            end
            // weight sram
            else if (access_sel_d == ACCESS_WEIGHT_SRAM) begin
                sp_spm_cpu_ceb_i = 1'b0;
                sp_spm_cpu_web_i = access_we_d ? 1'b0 : 1'b1;
                addr_offset_d = (sp_addr_i - WEIGHT_SRAM_BASE_ADDRESS);
                sp_spm_cpu_address_i = addr_offset_d[13:5] + WEIGHT_START_ADDRESS;
                case (addr_offset_d[4:3])
                    2'b00: begin
                        sp_spm_cpu_data_i = access_we_d ? {128'b0, data_i} : '0;
                        sp_spm_cpu_bweb_i = {{128{1'b1}}, {64{1'b0}}};
                    end
                    2'b01: begin
                        sp_spm_cpu_data_i = access_we_d ? {64'b0, data_i, 64'b0} : '0;
                        sp_spm_cpu_bweb_i = {{64{1'b1}}, {64{1'b0}}, {64{1'b1}}};
                    end
                    2'b10: begin
                        sp_spm_cpu_data_i = access_we_d ? {data_i, 128'b0} : '0;
                        sp_spm_cpu_bweb_i = {{64{1'b0}}, {128{1'b1}}};
                    end
                    2'd3: begin
                        sp_spm_cpu_data_i = '0;
                        sp_spm_cpu_bweb_i = '1;
                    end
                    default:;
                endcase
            end else begin
                sp_spm_cpu_ceb_i = 1'b1;
                sp_spm_cpu_web_i = 1'b1;
                addr_offset_d = '0;
                sp_spm_cpu_address_i = addr_offset_d[13:5];
                sp_spm_cpu_data_i = '0;
                sp_spm_cpu_bweb_i = '1;
            end

            // token_id_buffer
            if (access_sel_d == ACCESS_TOKEN_ID_BUF) begin
                for (int i = 0; i < TOKEN_WINDOW; i++) begin
                    token_id_buffer_d[i] = access_we_d ? data_i[TOKEN_ID_WIDTH*i +: TOKEN_ID_WIDTH] : token_id_buffer_q[i];
                end
            end else begin
                token_id_buffer_d = token_id_buffer_q;
            end

            // ctrl_csr
            if (access_sel_d == ACCESS_CSR) begin
                ctrl_csr_cpu_d = access_we_d ? data_i : ctrl_csr_q;
            end else begin
                ctrl_csr_cpu_d = ctrl_csr_q;
            end


        end else begin
            access_sel_d = ACCESS_IDLE;
            access_we_d = '0;

            sp_spm_cpu_ceb_i = 1'b1;
            sp_spm_cpu_web_i = 1'b1;
            addr_offset_d = '0;
            sp_spm_cpu_address_i = addr_offset_d[12:5];
            sp_spm_cpu_data_i = '0;
            sp_spm_cpu_bweb_i = '1;

            token_id_buffer_d = token_id_buffer_q;
            ctrl_csr_cpu_d = ctrl_csr_q;

        end

        // data_out
        case (access_sel_q)
            ACCESS_IDLE: begin
                data_o = '0;
            end
            ACCESS_INPUT_SRAM: begin
                case (addr_offset_q[4:3])
                    2'd0: begin
                        data_o = access_we_q ? '0 : sp_spm_output_o[63:0];
                    end
                    2'd1: begin
                        data_o = access_we_q ? '0 : sp_spm_output_o[127:64];
                    end
                    2'd2: begin
                        data_o = access_we_q ? '0 : sp_spm_output_o[191:128];
                    end
                    2'd3: begin
                        data_o = '0;
                    end
                    default:;
                endcase
            end
            ACCESS_WEIGHT_SRAM: begin
                case (addr_offset_q[4:3])
                    2'd0: begin
                        data_o = access_we_q ? '0 : sp_spm_output_o[63:0];
                    end
                    2'd1: begin
                        data_o = access_we_q ? '0 : sp_spm_output_o[127:64];
                    end
                    2'd2: begin
                        data_o = access_we_q ? '0 : sp_spm_output_o[191:128];
                    end
                    2'd3: begin
                        data_o = '0;
                    end
                    default:;
                endcase
            end
            ACCESS_TOKEN_ID_BUF: begin
                for (int i = 0; i < TOKEN_WINDOW; i++) begin
                    data_o[TOKEN_ID_WIDTH*i +: TOKEN_ID_WIDTH] = access_we_q ? '0 : token_id_buffer_q[i];
                end
            end
            ACCESS_PREDICTOR_O_BUF: begin
                data_o = access_we_q ? '0 : {'0, predictor_o_buffer_q[3], predictor_o_buffer_q[2], predictor_o_buffer_q[1], predictor_o_buffer_q[0]};
            end
            ACCESS_CSR: begin
                data_o = access_we_q ? '0 : ctrl_csr_q;
            end
            ACCESS_STATUS: begin
                data_o = access_we_q ? '0 : status_csr_q;
            end
            default: begin
                data_o = '0;
            end
        endcase
    end


    always@(posedge clk_i or negedge rstn_i) begin
        if (!rstn_i) begin
            access_sel_q <= ACCESS_IDLE;
            access_we_q <= '0;
            addr_offset_q <= '0;
            token_id_buffer_q <= '0;
            status_csr_q <= '0;
        end else begin
            access_sel_q <= access_sel_d;
            access_we_q <= access_we_d;
            addr_offset_q <= addr_offset_d;
            token_id_buffer_q <= token_id_buffer_d;
            status_csr_q <= status_csr_d;
        end
    end

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////// Encoder Instance and Control FSM ////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////

    logic               encoder_en_i;
    logic               encoder_finish_o;
    logic [HDC_DIM-1:0] encoder_vector_o;

    hdc_encoder #(
        .HDC_DIM        (HDC_DIM),
        .TOKEN_ID_WIDTH (TOKEN_ID_WIDTH),
        .RANDOM_WIDTH   (RANDOM_WIDTH),
        .N_TOKEN        (TOKEN_WINDOW)
    ) hdc_encoder (
        .clk_i      (clk_i),
        .rstn_i     (rstn_i),
        .en_i       (encoder_en_i),
        .token_id_i (token_id_buffer_q),
        .finish_o   (encoder_finish_o),
        .vector_o   (encoder_vector_o)
    );


    // encoder FSM logic
    typedef enum logic [1:0] {
        ENCODER_IDLE,    // Idle; starts the encoder when the control CSR enables it
        ENCODER_ENCODE,  // Encoder running; its output vector is captured into encoder_o_buffer on finish
        ENCODER_STORE    // Write encoder_o_buffer to the history slot of the scratchpad, 64 bits per write
    } state_encoder;

    state_encoder state_encoder_q, state_encoder_d;
    logic [$clog2(NUM_ACCESS)-1:0] encoder_cnt_q, encoder_cnt_d; // FSM cnt
    logic [4:0] encoder_addr_cnt_q, encoder_addr_cnt_d; // sram addr cnt for sram addr
    logic [1:0] encoder_bitmask_cnt_q, encoder_bitmask_cnt_d; // sram addr offset cnt for sram bitmask
    logic [8:0] sp_spm_encoder_base_addr;
    assign sp_spm_encoder_base_addr = HISTORY_BASE_ADDRESS[history_id];

    always_comb begin
        sp_spm_encoder_web_i = 1'b0;
        case (state_encoder_q)
            ENCODER_IDLE: begin
                sp_spm_encoder_ceb_i = 1'b1;  // input sram
                sp_spm_encoder_address_i = '0;
                sp_spm_encoder_data_i = '0;
                sp_spm_encoder_bweb_i = '1;

                encoder_cnt_d = '0;
                encoder_addr_cnt_d = '0;
                encoder_bitmask_cnt_d = '0;
                encoder_o_buffer_d = encoder_o_buffer_q;
                encoder_en_i = encoder_en ? 1'b1 : 1'b0;  // encoder enable

                encoder_status_d = encoder_en ? STATUS_BUSY : encoder_status_q; //FSM STATE
                state_encoder_d = encoder_en ? ENCODER_ENCODE : ENCODER_IDLE; //STATUS_CSR
                ctrl_csr_encoder_d = ctrl_csr_q;
            end
            ENCODER_ENCODE: begin
                sp_spm_encoder_ceb_i = 1'b1;
                sp_spm_encoder_address_i = '0;
                sp_spm_encoder_data_i = '0;
                sp_spm_encoder_bweb_i = '1;

                encoder_en_i = 1'b0;
                encoder_cnt_d = '0;
                encoder_addr_cnt_d = '0;
                encoder_bitmask_cnt_d = '0;
                encoder_o_buffer_d = encoder_finish_o ? encoder_vector_o : encoder_o_buffer_q;

                encoder_status_d = STATUS_BUSY; //FSM STATE
                state_encoder_d = encoder_finish_o ? ENCODER_STORE : ENCODER_ENCODE; //STATUS_CSR
                ctrl_csr_encoder_d = ctrl_csr_q;
            end
            ENCODER_STORE: begin
                // 64bit per write
                sp_spm_encoder_ceb_i = 1'b0;
                sp_spm_encoder_address_i = {'0,encoder_addr_cnt_q} + sp_spm_encoder_base_addr;
                case (encoder_bitmask_cnt_q)
                    2'b00: begin
                        sp_spm_encoder_data_i = {128'b0, encoder_o_buffer_q[64*encoder_cnt_q +: 64]};
                        sp_spm_encoder_bweb_i = {{128{1'b1}}, {64{1'b0}}};
                    end
                    2'b01: begin
                        sp_spm_encoder_data_i = {64'b0, encoder_o_buffer_q[64*encoder_cnt_q +: 64], 64'b0};
                        sp_spm_encoder_bweb_i = {{64{1'b1}}, {64{1'b0}}, {64{1'b1}}};
                    end
                    2'b10: begin
                        sp_spm_encoder_data_i = {encoder_o_buffer_q[64*encoder_cnt_q +: 64], 128'b0};
                        sp_spm_encoder_bweb_i = {{64{1'b0}}, {128{1'b1}}};
                    end
                    2'b11: begin
                        sp_spm_encoder_data_i = '0;
                        sp_spm_encoder_bweb_i = '1;
                    end
                    default:;
                endcase

                encoder_en_i = 1'b0;
                encoder_cnt_d = (encoder_cnt_q == (NUM_ACCESS/2)-1) ? '0 : encoder_cnt_q + 1'b1;
                encoder_addr_cnt_d = (encoder_bitmask_cnt_q == 2'b10) ? encoder_addr_cnt_q + 1'b1 : encoder_addr_cnt_q;
                encoder_bitmask_cnt_d = (encoder_bitmask_cnt_q == 2'b10) ? '0 : encoder_bitmask_cnt_q + 1'b1;
                encoder_o_buffer_d = encoder_o_buffer_q;

                encoder_status_d = (encoder_cnt_q == (NUM_ACCESS/2)-1) ? STATUS_FINISHED : STATUS_BUSY; //FSM STATE
                state_encoder_d = (encoder_cnt_q == (NUM_ACCESS/2)-1) ? ENCODER_IDLE : ENCODER_STORE; //STATUS_CSR
                ctrl_csr_encoder_d = (encoder_cnt_q == (NUM_ACCESS/2)-1) ? {ctrl_csr_q[63:2], CMD_IDLE} : ctrl_csr_q; //CSR_CMD

            end
            default: begin
                sp_spm_encoder_ceb_i = 1'b1;
                sp_spm_encoder_address_i = '0;
                sp_spm_encoder_data_i = '0;
                sp_spm_encoder_bweb_i = '1;

                encoder_en_i = 1'b0;
                encoder_cnt_d = '0;
                encoder_addr_cnt_d = '0;
                encoder_bitmask_cnt_d = '0;
                encoder_o_buffer_d = '0;

                encoder_status_d = STATUS_IDLE;
                state_encoder_d = ENCODER_IDLE;
                ctrl_csr_encoder_d = '0;
            end
        endcase
    end

    always@(posedge clk_i or negedge rstn_i) begin
        if (!rstn_i) begin
            state_encoder_q <= ENCODER_IDLE;
            encoder_cnt_q <= '0;
            encoder_addr_cnt_q <= '0;
            encoder_bitmask_cnt_q <= '0;
            encoder_o_buffer_q <= '0;
            encoder_status_q <= STATUS_IDLE;
        end else begin
            state_encoder_q <= state_encoder_d;
            encoder_cnt_q <= encoder_cnt_d;
            encoder_addr_cnt_q <= encoder_addr_cnt_d;
            encoder_bitmask_cnt_q <= encoder_bitmask_cnt_d;
            encoder_o_buffer_q <= encoder_o_buffer_d;
            encoder_status_q <= encoder_status_d;
        end
    end


//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////// Predictor Instance and Control FSM //////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////

    logic predictor_en_i;
    logic [NUM_INPUT-1:0] predictor_hdc_input_i;
    logic [NUM_INPUT-1:0] predictor_weight_input_d, predictor_weight_input_q;
    logic predictor_finish_o;
    logic [$clog2(HDC_DIM)-1:0] predictor_results_o;

    predictor #(
        .HDC_DIM      (HDC_DIM),
        .NUM_INPUT  (NUM_INPUT),
        .BIAS       (BIAS)
    ) predictor (
        .clk_i         (clk_i),
        .rstn_i        (rstn_i),
        .en_i          (predictor_en_i),
        .hdc_input_i   (predictor_hdc_input_i),
        .weight_input_i(predictor_weight_input_q),
        .finish_o      (predictor_finish_o),
        .results_o     (predictor_results_o)
    );

    // predictor FSM logic
    typedef enum logic [1:0] {
        PRED_IDLE,       // Idle; issues the first weight read when the control CSR enables the predictor
        PRED_PRE_LOAD,   // First weight word arrives; feeds the first input slice and starts the predictor
        PRED_PREDICT,    // Stream the remaining weight words and encoder-output slices; accumulate the agent result
        PRED_STORE       // Hold the accumulated result, report STATUS_FINISHED and clear the command
    } state_predictor;

    state_predictor state_predictor_q, state_predictor_d;
    logic [$clog2(NUM_ACCESS)-1:0] predictor_cnt_q, predictor_cnt_d;
    logic [8:0] sp_spm_predictor_base_addr;
    assign sp_spm_predictor_base_addr = AGENT_BASE_ADDRESS[agent_id];
    assign sp_spm_predictor_web_i = 1'b1;

    always_comb begin
        case (state_predictor_q)
            PRED_IDLE: begin
                sp_spm_predictor_ceb_i = predictor_en ? 1'b0 : 1'b1;  // weih sram
                sp_spm_predictor_address_i = predictor_en ? sp_spm_predictor_base_addr : '0;

                predictor_hdc_input_i = '0;
                predictor_weight_input_d = '0;
                predictor_en_i = 1'b0;  // predictor enable
                predictor_cnt_d = 1'b0;
                predictor_o_buffer_d = predictor_o_buffer_q;

                predictor_status_d = predictor_en ? STATUS_BUSY : predictor_status_q; //csr
                state_predictor_d = predictor_en ? PRED_PRE_LOAD : PRED_IDLE; //csr
                ctrl_csr_predictor_d = ctrl_csr_q;
            end

            PRED_PRE_LOAD: begin // read weight from weight SRAM and hdc input from encoder_o_buffer and compute predictor results
                sp_spm_predictor_ceb_i = 1'b0;
                sp_spm_predictor_address_i = {'0, predictor_cnt_q + 1'b1} + sp_spm_predictor_base_addr;

                predictor_hdc_input_i = encoder_o_buffer_q[NUM_INPUT*predictor_cnt_q +: NUM_INPUT];
                for (int i = 0; i < NUM_INPUT; i++) begin
                    predictor_weight_input_d[i] = sp_spm_predictor_output_o[WEIGHT_WIDTH*i+WEIGHT_WIDTH-1];
                end
                predictor_en_i = predictor_en ? 1'b1 : 1'b0;
                predictor_cnt_d = 1'b0;
                predictor_o_buffer_d = predictor_o_buffer_q;

                predictor_status_d = STATUS_BUSY; //csr
                state_predictor_d = PRED_PREDICT;
                ctrl_csr_predictor_d = ctrl_csr_q;
            end

            PRED_PREDICT: begin // read weight from weight SRAM and hdc input from encoder_o_buffer and compute predictor results
                sp_spm_predictor_ceb_i = (predictor_cnt_q == NUM_ACCESS-1) ? 1'b1 : 1'b0;
                sp_spm_predictor_address_i = {'0, predictor_cnt_q + 2'd2} + sp_spm_predictor_base_addr;

                predictor_hdc_input_i = encoder_o_buffer_q[NUM_INPUT*predictor_cnt_q +: NUM_INPUT];
                for (int i = 0; i < NUM_INPUT; i++) begin
                    predictor_weight_input_d[i] = sp_spm_predictor_output_o[WEIGHT_WIDTH*i+WEIGHT_WIDTH-1];
                end
                predictor_en_i = 1'b0;
                predictor_cnt_d = (predictor_cnt_q == NUM_ACCESS-1) ? predictor_cnt_q : predictor_cnt_q + 1'b1;
                for (int i = 0; i < NUM_AGENT; i++) begin
                    if (i == agent_id) begin
                        predictor_o_buffer_d[i] = predictor_finish_o ? predictor_results_o + predictor_o_buffer_q[i] : predictor_o_buffer_q[i];
                    end else begin
                        predictor_o_buffer_d[i] = predictor_o_buffer_q[i];
                    end
                end

                predictor_status_d = STATUS_BUSY; //csr
                state_predictor_d = predictor_finish_o ? PRED_STORE : PRED_PREDICT;
                ctrl_csr_predictor_d = ctrl_csr_q;
            end

            PRED_STORE: begin // result already accumulated in PRED_PREDICT; report completion and clear the command
                sp_spm_predictor_ceb_i = 1'b0;
                sp_spm_predictor_address_i = '0;

                predictor_hdc_input_i = '0;
                predictor_weight_input_d = '0;
                predictor_en_i = 1'b0;
                predictor_cnt_d = '0;
                predictor_o_buffer_d = predictor_o_buffer_q;

                predictor_status_d = STATUS_FINISHED; //csr
                state_predictor_d = PRED_IDLE;
                ctrl_csr_predictor_d = {ctrl_csr_q[63:2], CMD_IDLE};
            end
            default: begin
                sp_spm_predictor_ceb_i = 1'b1;
                sp_spm_predictor_address_i = '0;

                predictor_hdc_input_i = '0;
                predictor_weight_input_d = '0;
                predictor_en_i = 1'b0;
                predictor_cnt_d = '0;
                predictor_o_buffer_d = '0;

                predictor_status_d = STATUS_IDLE;
                state_predictor_d = PRED_IDLE;
                ctrl_csr_predictor_d = '0;
            end
        endcase
    end


    always@(posedge clk_i or negedge rstn_i) begin
        if (!rstn_i) begin
            state_predictor_q <= PRED_IDLE;
            predictor_cnt_q <= '0;
            predictor_weight_input_q <= '0;
            predictor_o_buffer_q <= '0;
            predictor_status_q <= STATUS_IDLE;
        end else begin
            state_predictor_q <= state_predictor_d;
            predictor_cnt_q <= predictor_cnt_d;
            predictor_weight_input_q <= predictor_weight_input_d;
            predictor_o_buffer_q <= predictor_o_buffer_d;
            predictor_status_q <= predictor_status_d;
        end
    end


//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////// Learner Instance and Control FSM //////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////

    logic learner_en_i;
    logic [NUM_INPUT-1:0] learner_hdc_input_d, learner_hdc_input_q;
    logic [NUM_INPUT*WEIGHT_WIDTH-1:0] learner_weight_input_i;
    logic [NUM_INPUT*WEIGHT_WIDTH-1:0] learner_updated_weight_o;

    learner #(
        .NUM_INPUT    (NUM_INPUT),
        .WEIGHT_WIDTH (WEIGHT_WIDTH)
    ) learner (
        .en_i           (learner_en_i),
        .reward_i       (reward),
        .hdc_input_i    (learner_hdc_input_q),
        .weight_input_i (learner_weight_input_i),
        .updated_weight (learner_updated_weight_o)
    );
    // learner FSM logic   rd input_sram  r/w sp_spm
    typedef enum logic [2:0] {
        LEARN_IDLE,       // Idle, waiting for en_i=1
        LEARN_LOAD_HDC,  // LOAD
        LEARN_LOAD_WEIGHT,  // LOAD
        LEARN_UPDATE,  // UPDATE
        LEARN_STORE
    } state_learner;

    state_learner state_learner_q, state_learner_d;
    logic [$clog2(NUM_ACCESS)-1:0] learner_cnt_q, learner_cnt_d;
    logic [4:0] learner_hdc_addr_cnt_q, learner_hdc_addr_cnt_d; // hdc sram addr cnt for sram addr
    logic [2:0] learner_hdc_bitmask_cnt_q, learner_hdc_bitmask_cnt_d; // hdcsram addr offset cnt for sram bitmask
    logic [8:0] learner_hdc_base_addr;
    logic [8:0] learner_weight_base_addr;
    assign learner_hdc_base_addr = HISTORY_BASE_ADDRESS[history_id];
    assign learner_weight_base_addr = AGENT_BASE_ADDRESS[agent_id];

    always_comb begin
        case (state_learner_q)
            LEARN_IDLE: begin
                sp_spm_learner_ceb_i = learner_en ? 1'b0 : 1'b1;  // weight sram
                sp_spm_learner_web_i = 1'b1;
                sp_spm_learner_address_i = learner_en ? learner_hdc_base_addr : '0;
                sp_spm_learner_data_i = '0;

                learner_hdc_input_d = '0;
                learner_weight_input_i = '0;
                learner_en_i = learner_en ? 1'b1 : 1'b0;  // learner enable
                learner_cnt_d = '0;
                learner_hdc_addr_cnt_d = '0;
                learner_hdc_bitmask_cnt_d = '0;

                learner_status_d = learner_en ? STATUS_BUSY : learner_status_q; //csr
                state_learner_d = learner_en ? LEARN_LOAD_HDC : LEARN_IDLE; //csr
                ctrl_csr_learner_d = ctrl_csr_q;
            end

            LEARN_LOAD_HDC: begin // send read requets to SRAM
                sp_spm_learner_ceb_i = 1'b0;
                sp_spm_learner_web_i = 1'b1;
                sp_spm_learner_address_i = {'0,learner_cnt_q} + learner_weight_base_addr;
                sp_spm_learner_data_i = '0;

                learner_hdc_input_d = sp_spm_learner_output_o[learner_hdc_bitmask_cnt_q*32 +: 32];
                learner_weight_input_i = sp_spm_learner_output_o;
                learner_en_i = 1'b0;
                learner_cnt_d = learner_cnt_q;
                learner_hdc_addr_cnt_d = learner_hdc_addr_cnt_q;
                learner_hdc_bitmask_cnt_d = learner_hdc_bitmask_cnt_q;

                learner_status_d = STATUS_BUSY; //csr
                state_learner_d = LEARN_LOAD_WEIGHT;
                ctrl_csr_learner_d = ctrl_csr_q;
            end

            LEARN_LOAD_WEIGHT: begin // send read requets to weight SRAM
                sp_spm_learner_ceb_i = 1'b1;
                sp_spm_learner_web_i = 1'b1;
                sp_spm_learner_address_i = {'0,learner_cnt_q} + learner_weight_base_addr;
                sp_spm_learner_data_i = '0;

                learner_hdc_input_d = learner_hdc_input_q;
                learner_weight_input_i = sp_spm_learner_output_o;
                learner_en_i = 1'b0;
                learner_cnt_d = learner_cnt_q;
                learner_hdc_addr_cnt_d = learner_hdc_addr_cnt_q;
                learner_hdc_bitmask_cnt_d = learner_hdc_bitmask_cnt_q;

                learner_status_d = STATUS_BUSY; //csr
                state_learner_d = LEARN_UPDATE;
                ctrl_csr_learner_d = ctrl_csr_q;
            end

            LEARN_UPDATE: begin // compute updated weight
                sp_spm_learner_ceb_i = 1'b0;
                sp_spm_learner_web_i = 1'b0;
                sp_spm_learner_address_i = {'0,learner_cnt_q} + learner_weight_base_addr;
                sp_spm_learner_data_i = learner_updated_weight_o;

                learner_hdc_input_d = learner_hdc_input_q;
                learner_weight_input_i = sp_spm_learner_output_o;
                learner_en_i = 1'b1;

                learner_cnt_d = learner_cnt_q;
                learner_hdc_addr_cnt_d = learner_hdc_addr_cnt_q;
                learner_hdc_bitmask_cnt_d = learner_hdc_bitmask_cnt_q;

                learner_status_d = STATUS_BUSY; //csr
                state_learner_d = LEARN_STORE;
                ctrl_csr_learner_d = ctrl_csr_q;
            end


            LEARN_STORE: begin // store updated weight to weight SRAM
                sp_spm_learner_ceb_i = (learner_cnt_q == NUM_ACCESS-1) ? 1'b1 : 1'b0;
                sp_spm_learner_web_i = 1'b1;
                sp_spm_learner_data_i = '0;

                learner_hdc_input_d = learner_hdc_input_q;
                learner_weight_input_i = sp_spm_learner_output_o;
                learner_en_i = 1'b0;
                learner_cnt_d = (learner_cnt_q == NUM_ACCESS-1) ? '0 : learner_cnt_q + 1'b1;
                learner_hdc_addr_cnt_d = (learner_hdc_bitmask_cnt_q == 3'd5) ? learner_hdc_addr_cnt_q + 1'b1 : learner_hdc_addr_cnt_q;
                learner_hdc_bitmask_cnt_d = (learner_hdc_bitmask_cnt_q == 3'd5) ? '0 : learner_hdc_bitmask_cnt_q + 1'b1;

                sp_spm_learner_address_i = (learner_cnt_q == NUM_ACCESS-1) ? '0 : {'0,learner_hdc_addr_cnt_d} + learner_hdc_base_addr;

                learner_status_d = (learner_cnt_q == NUM_ACCESS-1) ? STATUS_FINISHED : STATUS_BUSY; //csr
                state_learner_d = (learner_cnt_q == NUM_ACCESS-1) ? LEARN_IDLE : LEARN_LOAD_HDC;
                ctrl_csr_learner_d = (learner_cnt_q == NUM_ACCESS-1) ? {ctrl_csr_q[63:2], CMD_IDLE} : ctrl_csr_q; //CSR_CMD
            end

            default: begin
                sp_spm_learner_ceb_i = 1'b1;
                sp_spm_learner_web_i = 1'b1;
                sp_spm_learner_address_i = '0;
                sp_spm_learner_data_i = '0;

                learner_hdc_input_d = '0;
                learner_weight_input_i = '0;
                learner_en_i = 1'b0;
                learner_cnt_d = '0;
                learner_hdc_addr_cnt_d = '0;
                learner_hdc_bitmask_cnt_d = '0;

                learner_status_d = STATUS_IDLE;
                state_learner_d = LEARN_IDLE;
                ctrl_csr_learner_d = '0;
            end
        endcase
    end

    always@(posedge clk_i or negedge rstn_i) begin
        if (!rstn_i) begin
            state_learner_q <= LEARN_IDLE;
            learner_cnt_q <= '0;
            learner_hdc_addr_cnt_q <= '0;
            learner_hdc_bitmask_cnt_q <= '0;
            learner_hdc_input_q <= '0;
            learner_status_q <= STATUS_IDLE;
        end else begin
            state_learner_q <= state_learner_d;
            learner_cnt_q <= learner_cnt_d;
            learner_hdc_addr_cnt_q <= learner_hdc_addr_cnt_d;
            learner_hdc_bitmask_cnt_q <= learner_hdc_bitmask_cnt_d;
            learner_hdc_input_q <= learner_hdc_input_d;
            learner_status_q <= learner_status_d;
        end
    end

endmodule