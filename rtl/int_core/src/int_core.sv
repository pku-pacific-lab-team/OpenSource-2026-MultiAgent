// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
//////////////////////////////////////////////////////////////////////////////////
// Description: INT Core Module inlcluding PE Array and SF Array
// Author:      Mingxuan Li <siris-lmx@stu.pku.edu.cn> [Peking University]
// Acknowledge: Renati Tuerhong  <renati0423@gmail.com> [Peking University]
//              Claude Agent
//////////////////////////////////////////////////////////////////////////////////

module int_core #(
  parameter AXI_ADDR_WIDTH    = 12,
  parameter AXI_DATA_WIDTH    = 64,

  parameter PE_DATA_WIDTH     = 4,
  parameter PE_MAX_ACCUM_NUM  = 32,
  parameter PE_ARRAY_SIZE     = 8,

  parameter SF_DATA_WIDTH     = 8,
  parameter SF_BUCKET_WIDTH   = 12,
  parameter SF_ARRAY_SIZE     = 8,
  parameter SF_SPATTN_CNT_MAX = 128
) (
  input   logic                       clk_i             ,
  input   logic                       rstn_i            ,

	// direct interface to internal DMA
	output  logic [AXI_ADDR_WIDTH-1:0]  dma_length_o      ,
  output  logic [AXI_ADDR_WIDTH-1:0]  dma_src_offset_o  ,
  output  logic [AXI_ADDR_WIDTH-1:0]  dma_dst_offset_o  ,
	output  logic                       dma_run_o         ,
	input   logic                       dma_ready_i       ,
  input   logic                       dma_busy_i        ,

  // memory-mapped interface
  input   logic                       mem_req_i         ,
  input   logic                       mem_write_en_i    ,
  input   logic [AXI_ADDR_WIDTH-1:0]  mem_addr_i        ,
  input   logic [AXI_DATA_WIDTH-1:0]  mem_wdata_i       ,
  output  logic [AXI_DATA_WIDTH-1:0]  mem_rdata_o       ,
  output  logic                       mem_rvalid_o
);

  // -----------------------------------
  // Input pipeline registers (for timing improvement)
  // -----------------------------------
  logic                       mem_req_q         ;
  logic                       mem_write_en_q    ;
  logic [AXI_ADDR_WIDTH-1:0]  mem_addr_q        ;
  logic [AXI_DATA_WIDTH-1:0]  mem_wdata_q       ;
  logic                       dma_ready_q       ;
  logic                       dma_busy_q        ;
  logic                       dma_busy_delay_q  ;
  logic                       negedge_dma_busy  ;

  // -----------------------------------
  // Output pipeline registers (for timing improvement)
  // -----------------------------------
  logic [AXI_ADDR_WIDTH-1:0]  dma_length_d      ;
  logic [AXI_ADDR_WIDTH-1:0]  dma_src_offset_d  ;
  logic [AXI_ADDR_WIDTH-1:0]  dma_dst_offset_d  ;
  logic                       dma_run_d         ;
  logic [AXI_DATA_WIDTH-1:0]  mem_rdata_d       ;


  localparam TILE = 4;

  localparam logic [12-1:0] PE_WEIGHT_BASE_ADDR     = 12'h000;
  localparam logic [12-1:0] PE_ACTIVATION_BASE_ADDR = 12'h200;
  localparam logic [12-1:0] PE_RESULT_BASE_ADDR     = 12'h400;
  localparam logic [12-1:0] SF0_CURR_BASE_ADDR      = 12'h500;
  localparam logic [12-1:0] SF1_CURR_BASE_ADDR      = 12'h520;
  localparam logic [12-1:0] SF0_PRED_BASE_ADDR      = 12'h540;
  localparam logic [12-1:0] SF1_PRED_BASE_ADDR      = 12'h560;
  localparam logic [12-1:0] SF_RESULT_BASE_ADDR     = 12'h580;
  localparam logic [12-1:0] SIGN0_BASE_ADDR         = 12'h600;
  localparam logic [12-1:0] SIGN1_BASE_ADDR         = 12'h680;
  localparam logic [12-1:0] SUM_BUCKET_BASE_ADDR    = 12'h700;
  localparam logic [12-1:0] CTRL_STATUS_ADDR        = 12'hf00;

  localparam logic [12-1:0] PE_INPUT_LENGTH         = TILE*PE_MAX_ACCUM_NUM*PE_ARRAY_SIZE*PE_DATA_WIDTH/8;  // 12'h200 in bytes
  localparam logic [12-1:0] PE_OUTPUT_LENGTH        = 16*PE_ARRAY_SIZE*PE_ARRAY_SIZE/8;                     // 12'h080 in bytes
  localparam logic [12-1:0] SF_INPUT_LENGTH         = TILE*SF_ARRAY_SIZE*SF_DATA_WIDTH/8;                   // 12'h020 in bytes
  localparam logic [12-1:0] SF_OUTPUT_LENGTH        = SF_ARRAY_SIZE*SF_ARRAY_SIZE*SF_DATA_WIDTH/8;          // 12'h040 in bytes
  localparam logic [12-1:0] SIGN_LENGTH             = SF_SPATTN_CNT_MAX*SF_ARRAY_SIZE/8;                    // 12'h080 in bytes
  localparam logic [12-1:0] SUM_BUCKET_LENGTH       = 32*4/8;                                               // 12'h010 in bytes

  typedef logic [TILE-1:0][PE_MAX_ACCUM_NUM-1:0][PE_ARRAY_SIZE-1:0][PE_DATA_WIDTH-1:0] pe_input_t             ;
  typedef logic [PE_INPUT_LENGTH*8/AXI_DATA_WIDTH-1:0][AXI_DATA_WIDTH-1:0]             pe_input_aligned_t     ;
  typedef logic [PE_OUTPUT_LENGTH*8/AXI_DATA_WIDTH-1:0][AXI_DATA_WIDTH-1:0]            pe_output_aligned_t    ;
  typedef logic [TILE-1:0][SF_ARRAY_SIZE-1:0][SF_DATA_WIDTH-1:0]                       sf_input_t             ;
  typedef logic [SF_INPUT_LENGTH*8/AXI_DATA_WIDTH-1:0][AXI_DATA_WIDTH-1:0]             sf_input_aligned_t     ;
  typedef logic [SF_OUTPUT_LENGTH*8/AXI_DATA_WIDTH-1:0][AXI_DATA_WIDTH-1:0]            sf_output_aligned_t    ;
  typedef logic [SF_SPATTN_CNT_MAX-1:0][SF_ARRAY_SIZE-1:0]                             sign_t                 ;
  typedef logic [SIGN_LENGTH*8/AXI_DATA_WIDTH-1:0][AXI_DATA_WIDTH-1:0]                 sign_aligned_t         ;
  typedef logic [SUM_BUCKET_LENGTH*8/AXI_DATA_WIDTH-1:0][AXI_DATA_WIDTH-1:0]           sum_bucket_aligned_t   ;

  pe_input_t            pe_weight_buffer                                                ;
  pe_input_aligned_t    pe_weight_buffer_aligned_d, pe_weight_buffer_aligned_q          ;
  pe_input_t            pe_activation_buffer                                            ;
  pe_input_aligned_t    pe_activation_buffer_aligned_d, pe_activation_buffer_aligned_q  ;
  pe_output_aligned_t   pe_result_buffer_aligned                                        ;
  sf_input_t            sf0_curr_buffer                                                 ;
  sf_input_aligned_t    sf0_curr_buffer_aligned_d, sf0_curr_buffer_aligned_q            ;
  sf_input_t            sf1_curr_buffer                                                 ;
  sf_input_aligned_t    sf1_curr_buffer_aligned_d, sf1_curr_buffer_aligned_q            ;
  sf_input_t            sf0_pred_buffer                                                 ;
  sf_input_aligned_t    sf0_pred_buffer_aligned_d, sf0_pred_buffer_aligned_q            ;
  sf_input_t            sf1_pred_buffer                                                 ;
  sf_input_aligned_t    sf1_pred_buffer_aligned_d, sf1_pred_buffer_aligned_q            ;
  sf_output_aligned_t   sf_result_buffer_aligned                                        ;
  sign_t                sign0_buffer                                                    ;
  sign_aligned_t        sign0_buffer_aligned_d, sign0_buffer_aligned_q                  ;
  sign_t                sign1_buffer                                                    ;
  sign_aligned_t        sign1_buffer_aligned_d, sign1_buffer_aligned_q                  ;
  sum_bucket_aligned_t  sum_bucket_buffer_aligned                                       ;

  logic [2-1:0]               run_mode_d, run_mode_q        ;   // 0: function, 1: compute power, 2: dma power, 3: all power
  logic [2-1:0]               col_idx_d, col_idx_q          ;

  localparam  PE_IDLE  = 0,
              PE_TILE0 = 1, PE_DMA0 = 2, PE_TILE1 = 3, PE_DMA1 = 4,
              PE_TILE2 = 5, PE_DMA2 = 6, PE_TILE3 = 7, PE_DMA3 = 8;
  localparam  FUNC = 0, COMPUTE_PWR = 1, DMA_PWR = 2, ALL_PWR = 3;

  logic                                         pe_enable_d, pe_enable_q            ;   // 1-bit pulse
  logic                                         pe_finish_d, pe_finish_q            ;
  logic [16-1:0]                                pe_cycle_cnt_d, pe_cycle_cnt_q      ;
  logic [4-1:0]                                 pe_state_d, pe_state_q              ;
  logic                                         pe_in_valid, pe_initial             ;
  logic                                         pe_in_valid_d, pe_in_valid_q        ;
  logic                                         posedge_pe_in_valid                 ;
  logic [PE_ARRAY_SIZE-1:0][PE_DATA_WIDTH-1:0]  pe_activation_line                  ;
  logic [PE_ARRAY_SIZE-1:0][PE_DATA_WIDTH-1:0]  pe_weight_line                      ;
  logic [$clog2(PE_MAX_ACCUM_NUM)-1:0]          pe_accum_cnt                        ;
  logic [AXI_ADDR_WIDTH-1:0]                    pe_dma_length                       ;
  logic [AXI_ADDR_WIDTH-1:0]                    pe_dma_src_offset                   ;
  logic [AXI_ADDR_WIDTH-1:0]                    pe_dma_dst_offset                   ;
  logic                                         pe_dma_run_d, pe_dma_run_q          ;
  logic                                         pe_dma_has_run_d, pe_dma_has_run_q  ;
  logic                                         pe_dma_ready                        ;
  logic                                         pe_dma_ready_d, pe_dma_ready_q      ;
  logic                                         negedge_pe_dma_ready                ;

  localparam  SF_IDLE  = 0,
              SF_TILE0 = 1, SF_DMA0 = 2, SF_TILE1 = 3, SF_DMA1 = 4,
              SF_TILE2 = 5, SF_DMA2 = 6, SF_TILE3 = 7, SF_DMA3 = 8,
              SPATTN_COMPUTE = 9, SPATTN_DMA = 10;

  logic                                         sf_enable_d, sf_enable_q            ;   // 1-bit pulse
  logic                                         sf_has_enabled_d, sf_has_enabled_q  ;
  logic                                         sf_finish_d, sf_finish_q            ;
  logic [16-1:0]                                sf_cycle_cnt_d, sf_cycle_cnt_q      ;
  logic [4-1:0]                                 sf_state_d, sf_state_q              ;
  logic                                         sf_valid                            ;
  logic [SF_ARRAY_SIZE-1:0][SF_DATA_WIDTH-1:0]  sf_line0                            ;
  logic [SF_ARRAY_SIZE-1:0][SF_DATA_WIDTH-1:0]  sf_line1                            ;
  logic [SF_ARRAY_SIZE-1:0]                     sign_line0                          ;
  logic [SF_ARRAY_SIZE-1:0]                     sign_line1                          ;
  logic [AXI_ADDR_WIDTH-1:0]                    sf_dma_length                       ;
  logic [AXI_ADDR_WIDTH-1:0]                    sf_dma_src_offset                   ;
  logic [AXI_ADDR_WIDTH-1:0]                    sf_dma_dst_offset                   ;
  logic                                         sf_dma_run_d, sf_dma_run_q          ;
  logic                                         sf_dma_has_run_d, sf_dma_has_run_q  ;
  logic                                         sf_dma_ready                        ;
  logic                                         sf_dma_ready_d, sf_dma_ready_q      ;
  logic                                         negedge_sf_dma_ready                ;

  logic                                         spattn_enable_d, spattn_enable_q            ;   // 1-bit pulse
  logic                                         spattn_has_enabled_d, spattn_has_enabled_q  ;
  logic                                         spattn_finish_d, spattn_finish_q            ;
  logic [16-1:0]                                spattn_cycle_cnt_d, spattn_cycle_cnt_q      ;
  logic                                         spattn_valid, spattn_initial                ;
  logic                                         spattn_sum_valid                            ;
  logic [AXI_ADDR_WIDTH-1:0]                    spattn_dma_length                           ;
  logic [AXI_ADDR_WIDTH-1:0]                    spattn_dma_src_offset                       ;
  logic [AXI_ADDR_WIDTH-1:0]                    spattn_dma_dst_offset                       ;
  logic                                         spattn_dma_run_d, spattn_dma_run_q          ;
  logic                                         spattn_dma_has_run_d, spattn_dma_has_run_q  ;
  logic                                         spattn_dma_ready                            ;
  logic                                         spattn_dma_ready_d, spattn_dma_ready_q      ;
  logic                                         negedge_spattn_dma_ready                    ;

  localparam DMA_PE = 0, DMA_SF = 1, DMA_SPATTN = 2   ;
  localparam DMA_IDLE = 0, DMA_BUSY = 1               ;

  logic [2-1:0] dma_last_winner_d, dma_last_winner_q  ;
  logic [2-1:0] dma_next_winner                       ;
  logic [2-1:0] dma_winner_sel                        ;
  logic         dma_state_d, dma_state_q              ;

  // -----------------------------------
  // Input/Output pipeline register update
  // -----------------------------------
  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (!rstn_i) begin
      // Input registers
      mem_req_q         <= '0;
      mem_write_en_q    <= '0;
      mem_addr_q        <= '0;
      mem_wdata_q       <= '0;
      dma_ready_q       <= '0;
      dma_busy_q        <= '0;
      dma_busy_delay_q  <= '0;

      // Output registers
      mem_rdata_o       <= 64'hCA11AB1EBADCAB1E;
      mem_rvalid_o      <= '0;
      dma_length_o      <= '0;
      dma_src_offset_o  <= '0;
      dma_dst_offset_o  <= '0;
      dma_run_o         <= '0;
    end else begin
      // Input registers
      mem_req_q         <= mem_req_i;
      mem_write_en_q    <= mem_write_en_i;
      mem_addr_q        <= mem_addr_i;
      mem_wdata_q       <= mem_wdata_i;
      dma_ready_q       <= dma_ready_i;
      dma_busy_q        <= dma_busy_i;
      dma_busy_delay_q  <= dma_busy_q;
      // Output registers
      mem_rdata_o       <= mem_rdata_d;
      mem_rvalid_o      <= mem_req_q;
      dma_length_o      <= dma_length_d;
      dma_src_offset_o  <= dma_src_offset_d;
      dma_dst_offset_o  <= dma_dst_offset_d;
      dma_run_o         <= dma_run_d;
    end
  end

  // utilize negedge of dma_busy signal to ensure DMA has finished its operation
  assign negedge_dma_busy = dma_busy_delay_q & ~dma_busy_q;


  // -----------------------------------
  // register read & write
  // -----------------------------------
  always_comb begin
    // keep register values by default
    pe_weight_buffer_aligned_d      = pe_weight_buffer_aligned_q      ;
    pe_activation_buffer_aligned_d  = pe_activation_buffer_aligned_q  ;
    sf0_curr_buffer_aligned_d       = sf0_curr_buffer_aligned_q       ;
    sf1_curr_buffer_aligned_d       = sf1_curr_buffer_aligned_q       ;
    sf0_pred_buffer_aligned_d       = sf0_pred_buffer_aligned_q       ;
    sf1_pred_buffer_aligned_d       = sf1_pred_buffer_aligned_q       ;
    sign0_buffer_aligned_d          = sign0_buffer_aligned_q          ;
    sign1_buffer_aligned_d          = sign1_buffer_aligned_q          ;
    mem_rdata_d                     = 64'hCA11AB1EBADCAB1E            ;
    col_idx_d                       = col_idx_q                       ;
    run_mode_d                      = run_mode_q                      ;
    pe_enable_d                     = 1'b0                            ;
    sf_enable_d                     = 1'b0                            ;
    spattn_enable_d                 = 1'b0                            ;

    if (mem_req_q & mem_write_en_q) begin
      // write operations
      case (mem_addr_q[12-1:0]) inside
        [PE_WEIGHT_BASE_ADDR:PE_WEIGHT_BASE_ADDR+PE_INPUT_LENGTH-1]: begin
          pe_weight_buffer_aligned_d[mem_addr_q[$clog2(PE_INPUT_LENGTH)-1:3]] = mem_wdata_q;
        end

        [PE_ACTIVATION_BASE_ADDR:PE_ACTIVATION_BASE_ADDR+PE_INPUT_LENGTH-1]: begin
          pe_activation_buffer_aligned_d[mem_addr_q[$clog2(PE_INPUT_LENGTH)-1:3]] = mem_wdata_q;
        end

        [SF0_CURR_BASE_ADDR:SF0_CURR_BASE_ADDR+SF_INPUT_LENGTH-1]: begin
          sf0_curr_buffer_aligned_d[mem_addr_q[$clog2(SF_INPUT_LENGTH)-1:3]] = mem_wdata_q;
        end

        [SF1_CURR_BASE_ADDR:SF1_CURR_BASE_ADDR+SF_INPUT_LENGTH-1]: begin
          sf1_curr_buffer_aligned_d[mem_addr_q[$clog2(SF_INPUT_LENGTH)-1:3]] = mem_wdata_q;
        end

        [SF0_PRED_BASE_ADDR:SF0_PRED_BASE_ADDR+SF_INPUT_LENGTH-1]: begin
          sf0_pred_buffer_aligned_d[mem_addr_q[$clog2(SF_INPUT_LENGTH)-1:3]] = mem_wdata_q;
        end

        [SF1_PRED_BASE_ADDR:SF1_PRED_BASE_ADDR+SF_INPUT_LENGTH-1]: begin
          sf1_pred_buffer_aligned_d[mem_addr_q[$clog2(SF_INPUT_LENGTH)-1:3]] = mem_wdata_q;
        end

        [SIGN0_BASE_ADDR:SIGN0_BASE_ADDR+SIGN_LENGTH-1]: begin
          sign0_buffer_aligned_d[mem_addr_q[$clog2(SIGN_LENGTH)-1:3]] = mem_wdata_q;
        end

        [SIGN1_BASE_ADDR:SIGN1_BASE_ADDR+SIGN_LENGTH-1]: begin
          sign1_buffer_aligned_d[mem_addr_q[$clog2(SIGN_LENGTH)-1:3]] = mem_wdata_q;
        end


        CTRL_STATUS_ADDR: begin
          pe_enable_d     = mem_wdata_q[0]        ;
          sf_enable_d     = mem_wdata_q[1]        ;
          spattn_enable_d = mem_wdata_q[2]        ;
          run_mode_d      = mem_wdata_q[10-1:8]   ;
          col_idx_d       = mem_wdata_q[14-1:12]  ;
        end

        default: ; // do nothing
      endcase
    end else if (mem_req_q & ~mem_write_en_q) begin
      // read operations
      case (mem_addr_q[12-1:0]) inside
        [PE_WEIGHT_BASE_ADDR:PE_WEIGHT_BASE_ADDR+PE_INPUT_LENGTH-1]: begin
          mem_rdata_d = pe_weight_buffer_aligned_q[mem_addr_q[$clog2(PE_INPUT_LENGTH)-1:3]];
        end

        [PE_ACTIVATION_BASE_ADDR:PE_ACTIVATION_BASE_ADDR+PE_INPUT_LENGTH-1]: begin
          mem_rdata_d =  pe_activation_buffer_aligned_q[mem_addr_q[$clog2(PE_INPUT_LENGTH)-1:3]];
        end

        [PE_RESULT_BASE_ADDR:PE_RESULT_BASE_ADDR+PE_OUTPUT_LENGTH-1]: begin
          mem_rdata_d = pe_result_buffer_aligned[mem_addr_q[$clog2(PE_OUTPUT_LENGTH)-1:3]];
        end

        [SF0_CURR_BASE_ADDR:SF0_CURR_BASE_ADDR+SF_INPUT_LENGTH-1]: begin
          mem_rdata_d = sf0_curr_buffer_aligned_q[mem_addr_q[$clog2(SF_INPUT_LENGTH)-1:3]];
        end

        [SF1_CURR_BASE_ADDR:SF1_CURR_BASE_ADDR+SF_INPUT_LENGTH-1]: begin
          mem_rdata_d = sf1_curr_buffer_aligned_q[mem_addr_q[$clog2(SF_INPUT_LENGTH)-1:3]];
        end

        [SF0_PRED_BASE_ADDR:SF0_PRED_BASE_ADDR+SF_INPUT_LENGTH-1]: begin
          mem_rdata_d = sf0_pred_buffer_aligned_q[mem_addr_q[$clog2(SF_INPUT_LENGTH)-1:3]];
        end

        [SF1_PRED_BASE_ADDR:SF1_PRED_BASE_ADDR+SF_INPUT_LENGTH-1]: begin
          mem_rdata_d = sf1_pred_buffer_aligned_q[mem_addr_q[$clog2(SF_INPUT_LENGTH)-1:3]];
        end

        [SF_RESULT_BASE_ADDR:SF_RESULT_BASE_ADDR+SF_OUTPUT_LENGTH-1]: begin
          mem_rdata_d = sf_result_buffer_aligned[mem_addr_q[$clog2(SF_OUTPUT_LENGTH)-1:3]];
        end

        [SIGN0_BASE_ADDR:SIGN0_BASE_ADDR+SIGN_LENGTH-1]: begin
          mem_rdata_d = sign0_buffer_aligned_q[mem_addr_q[$clog2(SIGN_LENGTH)-1:3]];
        end

        [SIGN1_BASE_ADDR:SIGN1_BASE_ADDR+SIGN_LENGTH-1]: begin
          mem_rdata_d = sign1_buffer_aligned_q[mem_addr_q[$clog2(SIGN_LENGTH)-1:3]];
        end

        [SUM_BUCKET_BASE_ADDR:SUM_BUCKET_BASE_ADDR+SUM_BUCKET_LENGTH-1]: begin
          mem_rdata_d = sum_bucket_buffer_aligned[mem_addr_q[$clog2(SUM_BUCKET_LENGTH)-1:3]];
        end


        CTRL_STATUS_ADDR: begin
          mem_rdata_d = { 2'b0, col_idx_q, 2'b0, run_mode_q, 4'b0,
                          1'b0, spattn_finish_q, sf_finish_q, pe_finish_q,
                          spattn_cycle_cnt_q, sf_cycle_cnt_q, pe_cycle_cnt_q };
        end

        default: ; // do nothing
      endcase
    end


  end
  assign pe_weight_buffer     = pe_weight_buffer_aligned_q      ;
  assign pe_activation_buffer = pe_activation_buffer_aligned_q  ;
  assign sf0_curr_buffer      = sf0_curr_buffer_aligned_q       ;
  assign sf1_curr_buffer      = sf1_curr_buffer_aligned_q       ;
  assign sf0_pred_buffer      = sf0_pred_buffer_aligned_q       ;
  assign sf1_pred_buffer      = sf1_pred_buffer_aligned_q       ;
  assign sign0_buffer         = sign0_buffer_aligned_q          ;
  assign sign1_buffer         = sign1_buffer_aligned_q          ;


  // -----------------------------------
  // PE array logic
  // -----------------------------------
  // `valid` posedge detection
  assign pe_in_valid_d       = pe_in_valid;
  assign posedge_pe_in_valid = pe_in_valid_d & ~pe_in_valid_q;

  // `dma_ready` negedge detection
  assign pe_dma_ready_d        = pe_dma_ready;
  assign negedge_pe_dma_ready  = ~pe_dma_ready_d & pe_dma_ready_q;

  // PE array control FSM
  always_comb begin
    // default state transfer
    pe_state_d          = pe_state_q        ;
    pe_finish_d         = pe_finish_q       ;
    pe_cycle_cnt_d      = pe_cycle_cnt_q    ;
    pe_dma_run_d        = 1'b0              ;
    pe_dma_has_run_d    = pe_dma_has_run_q  ;

    // default wire assignments
    pe_in_valid         = '0;
    pe_initial          = '0;
    pe_activation_line  = '0;
    pe_weight_line      = '0;
    pe_dma_length       = '0;
    pe_dma_src_offset   = '0;
    pe_dma_dst_offset   = '0;

    case (pe_state_q)
      PE_IDLE: begin
        // state transfer
        if (pe_enable_q) begin
          case (run_mode_q)
            FUNC:         pe_state_d = PE_TILE0 ;
            COMPUTE_PWR:  pe_state_d = PE_TILE0 ;
            DMA_PWR:      pe_state_d = PE_DMA0  ;
            ALL_PWR:      pe_state_d = PE_TILE0 ;
            default: ;
          endcase
          pe_finish_d    = 1'b0;
          pe_cycle_cnt_d = 16'b0;
        end
      end

      PE_TILE0: begin
        // state transfer
        if (pe_accum_cnt == PE_MAX_ACCUM_NUM - 1) begin
          case (run_mode_q)
            FUNC:         pe_state_d = PE_DMA0  ;
            COMPUTE_PWR:  pe_state_d = PE_TILE1 ;
            DMA_PWR:      pe_state_d = PE_DMA0  ;
            ALL_PWR:      pe_state_d = PE_DMA0  ;
            default: ;
          endcase
        end
        pe_cycle_cnt_d = pe_cycle_cnt_q + 16'b1;

        // wire assignments
        pe_in_valid         = 1'b1;
        pe_initial          = posedge_pe_in_valid ? 1'b1 : 1'b0;
        pe_activation_line  = pe_activation_buffer[0][pe_accum_cnt];
        pe_weight_line      = pe_weight_buffer[0][pe_accum_cnt];
      end

      PE_DMA0: begin
        // state transfer
        if (negedge_dma_busy & pe_dma_has_run_q) begin
          case (run_mode_q)
            FUNC:         pe_state_d = PE_TILE1 ;
            COMPUTE_PWR:  pe_state_d = PE_TILE0 ;
            DMA_PWR:      pe_state_d = PE_DMA1  ;
            ALL_PWR:      pe_state_d = PE_TILE1 ;
            default: ;
          endcase
          pe_dma_has_run_d = 1'b0;
        end
        pe_cycle_cnt_d = pe_cycle_cnt_q + 16'b1;
        pe_dma_run_d   = ~pe_dma_has_run_q & ~pe_dma_ready & ~negedge_pe_dma_ready;
        // utilize dma_ready negedge to involve one cycle delay of run signal in dma frontend
        if (negedge_pe_dma_ready) begin
          pe_dma_has_run_d = 1'b1;
        end

        // wire assignments
        pe_dma_length     = AXI_ADDR_WIDTH'('h80); // in 64-bit double words
        pe_dma_src_offset = PE_RESULT_BASE_ADDR;
        case (col_idx_q)
          2'b00: pe_dma_dst_offset = AXI_ADDR_WIDTH'('h000);
          2'b01: pe_dma_dst_offset = AXI_ADDR_WIDTH'('h200);
          2'b10: pe_dma_dst_offset = AXI_ADDR_WIDTH'('h400);
          2'b11: pe_dma_dst_offset = AXI_ADDR_WIDTH'('h600);
          default: ;
        endcase
      end

      PE_TILE1: begin
        // state transfer
        if (pe_accum_cnt == PE_MAX_ACCUM_NUM - 1) begin
          case (run_mode_q)
            FUNC:         pe_state_d = PE_DMA1  ;
            COMPUTE_PWR:  pe_state_d = PE_TILE2 ;
            DMA_PWR:      pe_state_d = PE_DMA0  ;
            ALL_PWR:      pe_state_d = PE_DMA1  ;
            default: ;
          endcase
        end
        pe_cycle_cnt_d = pe_cycle_cnt_q + 16'b1;

        // wire assignments
        pe_in_valid         = 1'b1;
        pe_initial          = posedge_pe_in_valid ? 1'b1 : 1'b0;
        pe_activation_line  = pe_activation_buffer[1][pe_accum_cnt];
        pe_weight_line      = pe_weight_buffer[1][pe_accum_cnt];
      end

      PE_DMA1: begin
        // state transfer
        if (negedge_dma_busy & pe_dma_has_run_q) begin
          case (run_mode_q)
            FUNC:         pe_state_d = PE_TILE2 ;
            COMPUTE_PWR:  pe_state_d = PE_TILE0 ;
            DMA_PWR:      pe_state_d = PE_DMA2  ;
            ALL_PWR:      pe_state_d = PE_TILE2 ;
            default: ;
          endcase
          pe_dma_has_run_d = 1'b0;
        end
        pe_cycle_cnt_d = pe_cycle_cnt_q + 16'b1;
        pe_dma_run_d   = ~pe_dma_has_run_q & ~pe_dma_ready & ~negedge_pe_dma_ready;
        // utilize dma_ready negedge to involve one cycle delay of run signal in dma frontend
        if (negedge_pe_dma_ready) begin
          pe_dma_has_run_d = 1'b1;
        end

        // wire assignments
        pe_dma_length     = AXI_ADDR_WIDTH'('h80); // in 64-bit double words
        pe_dma_src_offset = PE_RESULT_BASE_ADDR;
        case (col_idx_q)
          2'b00: pe_dma_dst_offset = AXI_ADDR_WIDTH'('h080);
          2'b01: pe_dma_dst_offset = AXI_ADDR_WIDTH'('h280);
          2'b10: pe_dma_dst_offset = AXI_ADDR_WIDTH'('h480);
          2'b11: pe_dma_dst_offset = AXI_ADDR_WIDTH'('h680);
          default: ;
        endcase
      end

      PE_TILE2: begin
        // state transfer
        if (pe_accum_cnt == PE_MAX_ACCUM_NUM - 1) begin
          case (run_mode_q)
            FUNC:         pe_state_d = PE_DMA2  ;
            COMPUTE_PWR:  pe_state_d = PE_TILE3 ;
            DMA_PWR:      pe_state_d = PE_DMA0  ;
            ALL_PWR:      pe_state_d = PE_DMA2  ;
            default: ;
          endcase
        end
        pe_cycle_cnt_d = pe_cycle_cnt_q + 16'b1;

        // wire assignments
        pe_in_valid         = 1'b1;
        pe_initial          = posedge_pe_in_valid ? 1'b1 : 1'b0;
        pe_activation_line  = pe_activation_buffer[2][pe_accum_cnt];
        pe_weight_line      = pe_weight_buffer[2][pe_accum_cnt];
      end

      PE_DMA2: begin
        // state transfer
        if (negedge_dma_busy & pe_dma_has_run_q) begin
          case (run_mode_q)
            FUNC:         pe_state_d = PE_TILE3 ;
            COMPUTE_PWR:  pe_state_d = PE_TILE0 ;
            DMA_PWR:      pe_state_d = PE_DMA3  ;
            ALL_PWR:      pe_state_d = PE_TILE3 ;
            default: ;
          endcase
          pe_dma_has_run_d = 1'b0;
        end
        pe_cycle_cnt_d = pe_cycle_cnt_q + 16'b1;
        pe_dma_run_d   = ~pe_dma_has_run_q & ~pe_dma_ready & ~negedge_pe_dma_ready;
        // utilize dma_ready negedge to involve one cycle delay of run signal in dma frontend
        if (negedge_pe_dma_ready) begin
          pe_dma_has_run_d = 1'b1;
        end

        // wire assignments
        pe_dma_length     = AXI_ADDR_WIDTH'('h80); // in 64-bit double words
        pe_dma_src_offset = PE_RESULT_BASE_ADDR;
        case (col_idx_q)
          2'b00: pe_dma_dst_offset = AXI_ADDR_WIDTH'('h100);
          2'b01: pe_dma_dst_offset = AXI_ADDR_WIDTH'('h300);
          2'b10: pe_dma_dst_offset = AXI_ADDR_WIDTH'('h500);
          2'b11: pe_dma_dst_offset = AXI_ADDR_WIDTH'('h700);
          default: ;
        endcase
      end

      PE_TILE3: begin
        // state transfer
        if (pe_accum_cnt == PE_MAX_ACCUM_NUM - 1) begin
          case (run_mode_q)
            FUNC:         pe_state_d = PE_DMA3  ;
            COMPUTE_PWR:  pe_state_d = PE_TILE0 ;
            DMA_PWR:      pe_state_d = PE_DMA0  ;
            ALL_PWR:      pe_state_d = PE_DMA3  ;
            default: ;
          endcase
        end
        pe_cycle_cnt_d = pe_cycle_cnt_q + 16'b1;

        // wire assignments
        pe_in_valid         = 1'b1;
        pe_initial          = posedge_pe_in_valid ? 1'b1 : 1'b0;
        pe_activation_line  = pe_activation_buffer[3][pe_accum_cnt];
        pe_weight_line      = pe_weight_buffer[3][pe_accum_cnt];
      end

      PE_DMA3: begin
        // state transfer
        if (negedge_dma_busy & pe_dma_has_run_q) begin
          case (run_mode_q)
            FUNC:         pe_state_d = PE_IDLE  ;
            COMPUTE_PWR:  pe_state_d = PE_TILE0 ;
            DMA_PWR:      pe_state_d = PE_DMA0  ;
            ALL_PWR:      pe_state_d = PE_TILE0 ;
            default: ;
          endcase
          pe_dma_has_run_d = 1'b0;
          pe_finish_d      = (run_mode_q == FUNC);
        end
        pe_cycle_cnt_d = pe_cycle_cnt_q + 16'b1;
        pe_dma_run_d   = ~pe_dma_has_run_q & ~pe_dma_ready & ~negedge_pe_dma_ready;
        // utilize dma_ready negedge to involve one cycle delay of run signal in dma frontend
        if (negedge_pe_dma_ready) begin
          pe_dma_has_run_d = 1'b1;
        end

        // wire assignments
        pe_dma_length     = AXI_ADDR_WIDTH'('h80); // in 64-bit double words
        pe_dma_src_offset = PE_RESULT_BASE_ADDR;
        case (col_idx_q)
          2'b00: pe_dma_dst_offset = AXI_ADDR_WIDTH'('h180);
          2'b01: pe_dma_dst_offset = AXI_ADDR_WIDTH'('h380);
          2'b10: pe_dma_dst_offset = AXI_ADDR_WIDTH'('h580);
          2'b11: pe_dma_dst_offset = AXI_ADDR_WIDTH'('h780);
          default: ;
        endcase
      end

      default: pe_state_d = PE_IDLE;  // return to IDLE state
    endcase
  end

  // PE array instance
  pe_array #(
    .DATA_WIDTH               ( PE_DATA_WIDTH            ),
    .MAX_ACCUM_NUM            ( PE_MAX_ACCUM_NUM         ),
    .ARRAY_SIZE               ( PE_ARRAY_SIZE            )
  ) pe_array_inst (
    .clk_i                    ( clk_i                    ),
    .rstn_i                   ( rstn_i                   ),
    .in_valid_i               ( pe_in_valid              ),
    .initial_i                ( pe_initial               ),
    .activation_line_i        ( pe_activation_line       ),
    .weight_line_i            ( pe_weight_line           ),
    .accum_cnt_o              ( pe_accum_cnt             ),
    .result_matrix_aligned_o  ( pe_result_buffer_aligned )
  );


  // -----------------------------------
  // SF array & SpAttn logic
  // -----------------------------------
  // `dma_ready` negedge detection
  assign sf_dma_ready_d           = sf_dma_ready;
  assign negedge_sf_dma_ready     = ~sf_dma_ready_d & sf_dma_ready_q;

  assign spattn_dma_ready_d       = spattn_dma_ready;
  assign negedge_spattn_dma_ready = ~spattn_dma_ready_d & spattn_dma_ready_q;

  // SF array control FSM
  always_comb begin
    // default state transfer
    sf_state_d            = sf_state_q            ;
    sf_finish_d           = sf_finish_q           ;
    sf_cycle_cnt_d        = sf_cycle_cnt_q        ;
    sf_has_enabled_d      = sf_has_enabled_q      ;
    sf_dma_run_d          = 1'b0                  ;
    sf_dma_has_run_d      = sf_dma_has_run_q      ;

    spattn_finish_d       = spattn_finish_q       ;
    spattn_cycle_cnt_d    = spattn_cycle_cnt_q    ;
    spattn_has_enabled_d  = spattn_has_enabled_q  ;
    spattn_dma_run_d      = 1'b0                  ;
    spattn_dma_has_run_d  = spattn_dma_has_run_q  ;

    // default wire assignments
    sf_valid          = '0;
    sf_line0          = '0;
    sf_line1          = '0;
    sign_line0        = '0;
    sign_line1        = '0;
    sf_dma_length     = '0;
    sf_dma_src_offset = '0;
    sf_dma_dst_offset = '0;

    spattn_valid          = '0;
    spattn_initial        = '0;
    spattn_dma_length     = '0;
    spattn_dma_src_offset = '0;
    spattn_dma_dst_offset = '0;

    case (sf_state_q)
      SF_IDLE: begin
        // state transfer
        if (sf_enable_q) begin
          case (run_mode_q)
            FUNC:         sf_state_d = SF_TILE0 ;
            COMPUTE_PWR:  sf_state_d = SF_TILE0 ;
            DMA_PWR:      sf_state_d = SF_DMA0  ;
            ALL_PWR:      sf_state_d = SF_TILE0 ;
            default: ;
          endcase
          sf_finish_d       = 1'b0;
          sf_cycle_cnt_d    = 16'b0;
        end else if (spattn_enable_q) begin
          case (run_mode_q)
            FUNC:         sf_state_d = SPATTN_COMPUTE ;
            COMPUTE_PWR:  sf_state_d = SPATTN_COMPUTE ;
            DMA_PWR:      sf_state_d = SPATTN_DMA     ;
            ALL_PWR:      sf_state_d = SPATTN_COMPUTE ;
            default: ;
          endcase
          spattn_finish_d       = 1'b0;
          spattn_cycle_cnt_d    = 16'b0;
        end
        sf_has_enabled_d      = sf_enable_q;
        spattn_has_enabled_d  = spattn_enable_q;
      end

      SF_TILE0: begin
        // state transfer
        case (run_mode_q)
          FUNC:         sf_state_d = SF_DMA0  ;
          COMPUTE_PWR:  sf_state_d = SF_TILE1 ;
          DMA_PWR:      sf_state_d = SF_DMA0  ;
          ALL_PWR:      sf_state_d = SF_DMA0  ;
          default: ;
        endcase
        sf_cycle_cnt_d = sf_cycle_cnt_q + 16'b1;

        // wire assignments
        sf_valid = 1'b1;
        sf_line0 = sf0_curr_buffer[0];
        sf_line1 = sf1_curr_buffer[0];
      end

      SF_DMA0: begin
        // state transfer
        if (negedge_dma_busy & sf_dma_has_run_q) begin
          case (run_mode_q)
            FUNC:         sf_state_d = SF_TILE1 ;
            COMPUTE_PWR:  sf_state_d = SF_TILE0 ;
            DMA_PWR:      sf_state_d = SF_DMA1  ;
            ALL_PWR:      sf_state_d = SF_TILE1 ;
            default: ;
          endcase
          sf_dma_has_run_d = 1'b0;
        end
        sf_cycle_cnt_d = sf_cycle_cnt_q + 16'b1;
        sf_dma_run_d   = ~sf_dma_has_run_q & ~sf_dma_ready & ~negedge_sf_dma_ready;
        // utilize dma_ready negedge to involve one cycle delay of run signal in dma frontend
        if (negedge_sf_dma_ready) begin
          sf_dma_has_run_d = 1'b1;
        end

        // wire assignments
        sf_dma_length     = AXI_ADDR_WIDTH'('h40); // in 64-bit double words
        sf_dma_src_offset = SF_RESULT_BASE_ADDR;
        case (col_idx_q)
          2'b00: sf_dma_dst_offset = AXI_ADDR_WIDTH'('h800);
          2'b01: sf_dma_dst_offset = AXI_ADDR_WIDTH'('h900);
          2'b10: sf_dma_dst_offset = AXI_ADDR_WIDTH'('ha00);
          2'b11: sf_dma_dst_offset = AXI_ADDR_WIDTH'('hb00);
          default: ;
        endcase
      end

      SF_TILE1: begin
        // state transfer
        case (run_mode_q)
          FUNC:         sf_state_d = SF_DMA1  ;
          COMPUTE_PWR:  sf_state_d = SF_TILE2 ;
          DMA_PWR:      sf_state_d = SF_DMA0  ;
          ALL_PWR:      sf_state_d = SF_DMA1  ;
          default: ;
        endcase
        sf_cycle_cnt_d = sf_cycle_cnt_q + 16'b1;

        // wire assignments
        sf_valid = 1'b1;
        sf_line0 = sf0_curr_buffer[1];
        sf_line1 = sf1_curr_buffer[1];
      end

      SF_DMA1: begin
        // state transfer
        if (negedge_dma_busy & sf_dma_has_run_q) begin
          case (run_mode_q)
            FUNC:         sf_state_d = SF_TILE2 ;
            COMPUTE_PWR:  sf_state_d = SF_TILE0 ;
            DMA_PWR:      sf_state_d = SF_DMA2  ;
            ALL_PWR:      sf_state_d = SF_TILE2 ;
            default: ;
          endcase
          sf_dma_has_run_d = 1'b0;
        end
        sf_cycle_cnt_d = sf_cycle_cnt_q + 16'b1;
        sf_dma_run_d   = ~sf_dma_has_run_q & ~sf_dma_ready & ~negedge_sf_dma_ready;
        // utilize dma_ready negedge to involve one cycle delay of run signal in dma frontend
        if (negedge_sf_dma_ready) begin
          sf_dma_has_run_d = 1'b1;
        end

        // wire assignments
        sf_dma_length     = AXI_ADDR_WIDTH'('h40); // in 64-bit double words
        sf_dma_src_offset = SF_RESULT_BASE_ADDR;
        case (col_idx_q)
          2'b00: sf_dma_dst_offset = AXI_ADDR_WIDTH'('h840);
          2'b01: sf_dma_dst_offset = AXI_ADDR_WIDTH'('h940);
          2'b10: sf_dma_dst_offset = AXI_ADDR_WIDTH'('ha40);
          2'b11: sf_dma_dst_offset = AXI_ADDR_WIDTH'('hb40);
          default: ;
        endcase
      end

      SF_TILE2: begin
        // state transfer
        case (run_mode_q)
          FUNC:         sf_state_d = SF_DMA2  ;
          COMPUTE_PWR:  sf_state_d = SF_TILE3 ;
          DMA_PWR:      sf_state_d = SF_DMA0  ;
          ALL_PWR:      sf_state_d = SF_DMA2  ;
          default: ;
        endcase
        sf_cycle_cnt_d = sf_cycle_cnt_q + 16'b1;

        // wire assignments
        sf_valid = 1'b1;
        sf_line0 = sf0_curr_buffer[2];
        sf_line1 = sf1_curr_buffer[2];
      end

      SF_DMA2: begin
        // state transfer
        if (negedge_dma_busy & sf_dma_has_run_q) begin
          case (run_mode_q)
            FUNC:         sf_state_d = SF_TILE3 ;
            COMPUTE_PWR:  sf_state_d = SF_TILE0 ;
            DMA_PWR:      sf_state_d = SF_DMA3  ;
            ALL_PWR:      sf_state_d = SF_TILE3 ;
            default: ;
          endcase
          sf_dma_has_run_d = 1'b0;
        end
        sf_cycle_cnt_d = sf_cycle_cnt_q + 16'b1;
        sf_dma_run_d   = ~sf_dma_has_run_q & ~sf_dma_ready & ~negedge_sf_dma_ready;
        // utilize dma_ready negedge to involve one cycle delay of run signal in dma frontend
        if (negedge_sf_dma_ready) begin
          sf_dma_has_run_d = 1'b1;
        end

        // wire assignments
        sf_dma_length     = AXI_ADDR_WIDTH'('h40); // in 64-bit double words
        sf_dma_src_offset = SF_RESULT_BASE_ADDR;
        case (col_idx_q)
          2'b00: sf_dma_dst_offset = AXI_ADDR_WIDTH'('h880);
          2'b01: sf_dma_dst_offset = AXI_ADDR_WIDTH'('h980);
          2'b10: sf_dma_dst_offset = AXI_ADDR_WIDTH'('ha80);
          2'b11: sf_dma_dst_offset = AXI_ADDR_WIDTH'('hb80);
          default: ;
        endcase
      end

      SF_TILE3: begin
        // state transfer
        if (spattn_has_enabled_q) begin
          case (run_mode_q)
            FUNC:         sf_state_d = SF_DMA3        ;
            COMPUTE_PWR:  sf_state_d = SPATTN_COMPUTE ;
            DMA_PWR:      sf_state_d = SF_DMA0        ;
            ALL_PWR:      sf_state_d = SF_DMA3        ;
            default: ;
          endcase
          spattn_cycle_cnt_d = 16'b0;
        end else begin
          case (run_mode_q)
            FUNC:         sf_state_d = SF_DMA3  ;
            COMPUTE_PWR:  sf_state_d = SF_TILE0 ;
            DMA_PWR:      sf_state_d = SF_DMA0  ;
            ALL_PWR:      sf_state_d = SF_DMA3  ;
            default: ;
          endcase
        end
        sf_cycle_cnt_d = sf_cycle_cnt_q + 16'b1;

        // wire assignments
        sf_valid = 1'b1;
        sf_line0    = sf0_curr_buffer[3];
        sf_line1    = sf1_curr_buffer[3];
        sign_line0  = sign0_buffer[3];
        sign_line1  = sign1_buffer[3];
      end

      SF_DMA3: begin
        // state transfer
        if (negedge_dma_busy & sf_dma_has_run_q) begin
          if (spattn_has_enabled_q) begin
            case (run_mode_q)
              FUNC:         sf_state_d = SPATTN_COMPUTE ;
              COMPUTE_PWR:  sf_state_d = SPATTN_COMPUTE ;
              DMA_PWR:      sf_state_d = SPATTN_DMA     ;
              ALL_PWR:      sf_state_d = SPATTN_COMPUTE ;
              default: ;
            endcase
            spattn_cycle_cnt_d = 16'b0;
          end else begin
            case (run_mode_q)
              FUNC:         sf_state_d = SF_IDLE  ;
              COMPUTE_PWR:  sf_state_d = SF_TILE0 ;
              DMA_PWR:      sf_state_d = SF_DMA0  ;
              ALL_PWR:      sf_state_d = SF_TILE0 ;
              default: ;
            endcase
          end
          sf_dma_has_run_d = 1'b0;
          sf_finish_d      = (run_mode_q == FUNC);
        end
        sf_cycle_cnt_d = sf_cycle_cnt_q + 16'b1;
        sf_dma_run_d   = ~sf_dma_has_run_q & ~sf_dma_ready & ~negedge_sf_dma_ready;
        // utilize dma_ready negedge to involve one cycle delay of run signal in dma frontend
        if (negedge_sf_dma_ready) begin
          sf_dma_has_run_d = 1'b1;
        end

        // wire assignments
        sf_dma_length     = AXI_ADDR_WIDTH'('h40); // in 64-bit double words
        sf_dma_src_offset = SF_RESULT_BASE_ADDR;
        case (col_idx_q)
          2'b00: sf_dma_dst_offset = AXI_ADDR_WIDTH'('h8c0);
          2'b01: sf_dma_dst_offset = AXI_ADDR_WIDTH'('h9c0);
          2'b10: sf_dma_dst_offset = AXI_ADDR_WIDTH'('hac0);
          2'b11: sf_dma_dst_offset = AXI_ADDR_WIDTH'('hbc0);
          default: ;
        endcase
      end

      SPATTN_COMPUTE: begin
        // state transfer
        spattn_cycle_cnt_d = spattn_cycle_cnt_q + 16'b1;
        if (spattn_sum_valid && (spattn_cycle_cnt_q > 1)) begin
          if (sf_has_enabled_q) begin
            case (run_mode_q)
              FUNC:         sf_state_d = SPATTN_DMA     ;
              COMPUTE_PWR:  sf_state_d = SF_TILE0       ;
              DMA_PWR:      sf_state_d = SF_DMA0        ;
              ALL_PWR:      sf_state_d = SPATTN_DMA     ;
              default: ;
            endcase
          end else begin
            case (run_mode_q)
              FUNC:         sf_state_d = SPATTN_DMA     ;
              COMPUTE_PWR:  sf_state_d = SPATTN_COMPUTE ;
              DMA_PWR:      sf_state_d = SF_DMA0        ;
              ALL_PWR:      sf_state_d = SPATTN_DMA     ;
              default: ;
            endcase
            if (run_mode_q == COMPUTE_PWR) begin
              spattn_cycle_cnt_d = 16'b0;
            end
          end
        end

        // wire assignments
        if (spattn_cycle_cnt_q < SF_SPATTN_CNT_MAX) begin
          sf_valid    = 1'b1;
          sf_line0    = sf0_pred_buffer[spattn_cycle_cnt_q[$clog2(SF_SPATTN_CNT_MAX)-1:5]];
          sf_line1    = sf1_pred_buffer[spattn_cycle_cnt_q[$clog2(SF_SPATTN_CNT_MAX)-1:5]];
          sign_line0  = sign0_buffer[spattn_cycle_cnt_q];
          sign_line1  = sign1_buffer[spattn_cycle_cnt_q];
        end
        if (spattn_cycle_cnt_q > 0 &&
            spattn_cycle_cnt_q <= SF_SPATTN_CNT_MAX) begin
          spattn_valid = 1'b1;
        end
        if (spattn_cycle_cnt_q == 1) begin
          spattn_initial = 1'b1;
        end
      end

      SPATTN_DMA: begin
        // state transfer
        if (negedge_dma_busy & spattn_dma_has_run_q) begin
          if (sf_has_enabled_q) begin
            case (run_mode_q)
              FUNC:         sf_state_d = SF_IDLE  ;
              COMPUTE_PWR:  sf_state_d = SF_TILE0 ;
              DMA_PWR:      sf_state_d = SF_DMA0  ;
              ALL_PWR:      sf_state_d = SF_TILE0 ;
              default: ;
            endcase
          end else begin
            case (run_mode_q)
              FUNC:         sf_state_d = SF_IDLE        ;
              COMPUTE_PWR:  sf_state_d = SPATTN_COMPUTE ;
              DMA_PWR:      sf_state_d = SPATTN_DMA     ;
              ALL_PWR:      sf_state_d = SPATTN_COMPUTE ;
              default: ;
            endcase
          end
          spattn_dma_has_run_d = 1'b0;
          spattn_finish_d      = (run_mode_q == FUNC);
        end
        spattn_cycle_cnt_d = spattn_cycle_cnt_q + 16'b1;
        spattn_dma_run_d   = ~spattn_dma_has_run_q & ~spattn_dma_ready & ~negedge_spattn_dma_ready;
        // utilize dma_ready negedge to involve one cycle delay of run signal in dma frontend
        if (negedge_spattn_dma_ready) begin
          spattn_dma_has_run_d = 1'b1;
        end

        // wire assignments
        spattn_dma_length     = AXI_ADDR_WIDTH'('h10); // in 64-bit double words
        spattn_dma_src_offset = SUM_BUCKET_BASE_ADDR;
        case (col_idx_q)
          2'b00: spattn_dma_dst_offset = AXI_ADDR_WIDTH'('hc88);
          2'b01: spattn_dma_dst_offset = AXI_ADDR_WIDTH'('hc98);
          2'b10: spattn_dma_dst_offset = AXI_ADDR_WIDTH'('hca8);
          2'b11: spattn_dma_dst_offset = AXI_ADDR_WIDTH'('hcb8);
          default: ;
        endcase
      end

      default: sf_state_d = SF_IDLE;  // return to IDLE state
    endcase
  end

  // SF array instance
  sf_array #(
    .DATA_WIDTH               ( SF_DATA_WIDTH     ),
    .BUCKET_WIDTH             ( SF_BUCKET_WIDTH   ),
    .ARRAY_SIZE               ( SF_ARRAY_SIZE     ),
    .SPATTN_CNT_MAX           ( SF_SPATTN_CNT_MAX )
  ) sf_array_inst (
    .clk_i                    ( clk_i                     ),
    .rstn_i                   ( rstn_i                    ),
    .sf_valid_i               ( sf_valid                  ),
    .sf_line0_i               ( sf_line0                  ),
    .sf_line1_i               ( sf_line1                  ),
    .sign_line0_i             ( sign_line0                ),
    .sign_line1_i             ( sign_line1                ),
    .spattn_valid_i           ( spattn_valid              ),
    .spattn_initial_i         ( spattn_initial            ),
    .sum_bucket_aligned_o     ( sum_bucket_buffer_aligned ),
    .sum_valid_o              ( spattn_sum_valid          ),
    .exponent_matrix_o        ( sf_result_buffer_aligned  )
  );


  // -----------------------------------
  // DMA request arbitration
  // -----------------------------------
  // 1. Arbiter: Determine the next winner (Round-Robin)
  always_comb begin
    dma_next_winner = DMA_PE; // default

    case (dma_last_winner_q)
      DMA_PE: begin
        if      (sf_dma_run_q)      dma_next_winner = DMA_SF      ;
        else if (spattn_dma_run_q)  dma_next_winner = DMA_SPATTN  ;
        else if (pe_dma_run_q)      dma_next_winner = DMA_PE      ;
      end

      DMA_SF: begin
        if      (spattn_dma_run_q)  dma_next_winner = DMA_SPATTN  ;
        else if (pe_dma_run_q)      dma_next_winner = DMA_PE      ;
        else if (sf_dma_run_q)      dma_next_winner = DMA_SF      ;
      end

      DMA_SPATTN: begin
        if      (pe_dma_run_q)      dma_next_winner = DMA_PE      ;
        else if (sf_dma_run_q)      dma_next_winner = DMA_SF      ;
        else if (spattn_dma_run_q)  dma_next_winner = DMA_SPATTN  ;
      end

      default: dma_next_winner = DMA_PE;
    endcase
  end

  // 2. FSM: Control the handshake flow
  // ---------------------------------------------------
  // We use dma_last_winner_q to hold the "current" winner during the BUSY state.
  // When IDLE, we update dma_last_winner_q to next_winner if a request occurs.
  always_comb begin
    // default values
    dma_state_d       = dma_state_q        ;
    dma_last_winner_d = dma_last_winner_q  ;

    // Internal ready signals (default 0)
    pe_dma_ready      = 1'b0;
    sf_dma_ready      = 1'b0;
    spattn_dma_ready  = 1'b0;

    // External output run signal (to _d)
    dma_run_d         = 1'b0;

    case (dma_state_q)
      DMA_IDLE: begin
        if (pe_dma_run_q | sf_dma_run_q | spattn_dma_run_q) begin
          dma_state_d       = DMA_BUSY;
          dma_last_winner_d = dma_next_winner; // Lock the winner
        end
      end

      DMA_BUSY: begin
        dma_run_d = 1'b1; // Keep request high until handshake

        // Wait for external DMA ready
        if (dma_ready_q) begin
          // Pass the ready signal to the locked winner
          case (dma_last_winner_q)
            DMA_PE:      pe_dma_ready     = 1'b1;
            DMA_SF:      sf_dma_ready     = 1'b1;
            DMA_SPATTN:  spattn_dma_ready = 1'b1;
            default: ;
          endcase

          // Handshake done, go back to IDLE
          // Note: The sub-modules (PE/SF) will deassert their 'run' signal
          // in the next cycle after seeing 'ready'.
          dma_state_d = DMA_IDLE;
        end
      end

      default: dma_state_d = DMA_IDLE;
    endcase
  end

  // 3. Datapath Mux: Route signals based on the winner
  always_comb begin
    dma_length_d      = '0;
    dma_src_offset_d  = '0;
    dma_dst_offset_d  = '0;

    case (dma_last_winner_q)
      DMA_PE: begin
        dma_length_d      = pe_dma_length           ;
        dma_src_offset_d  = pe_dma_src_offset       ;
        dma_dst_offset_d  = pe_dma_dst_offset       ;
      end

      DMA_SF: begin
        dma_length_d      = sf_dma_length           ;
        dma_src_offset_d  = sf_dma_src_offset       ;
        dma_dst_offset_d  = sf_dma_dst_offset       ;
      end

      DMA_SPATTN: begin
        dma_length_d      = spattn_dma_length       ;
        dma_src_offset_d  = spattn_dma_src_offset   ;
        dma_dst_offset_d  = spattn_dma_dst_offset   ;
      end

      default: ;    // do nothing
    endcase
  end


  // -----------------------------------
  // register update
  // -----------------------------------
  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (!rstn_i) begin
      pe_weight_buffer_aligned_q      <= '0;
      pe_activation_buffer_aligned_q  <= '0;
      sf0_curr_buffer_aligned_q       <= '0;
      sf1_curr_buffer_aligned_q       <= '0;
      sf0_pred_buffer_aligned_q       <= '0;
      sf1_pred_buffer_aligned_q       <= '0;
      sign0_buffer_aligned_q          <= '0;
      sign1_buffer_aligned_q          <= '0;
      col_idx_q                       <= '0;
      run_mode_q                      <= '0;
      pe_enable_q                     <= '0;
      pe_finish_q                     <= '0;
      pe_in_valid_q                   <= '0;
      pe_state_q                      <= '0;
      pe_cycle_cnt_q                  <= '0;
      pe_dma_run_q                    <= '0;
      pe_dma_has_run_q                <= '0;
      pe_dma_ready_q                  <= '0;
      sf_enable_q                     <= '0;
      sf_finish_q                     <= '0;
      sf_state_q                      <= '0;
      sf_cycle_cnt_q                  <= '0;
      sf_dma_run_q                    <= '0;
      sf_dma_has_run_q                <= '0;
      sf_dma_ready_q                  <= '0;
      sf_has_enabled_q                <= '0;
      spattn_enable_q                 <= '0;
      spattn_finish_q                 <= '0;
      spattn_cycle_cnt_q              <= '0;
      spattn_dma_run_q                <= '0;
      spattn_dma_has_run_q            <= '0;
      spattn_dma_ready_q              <= '0;
      spattn_has_enabled_q            <= '0;
      dma_last_winner_q               <= '0;
      dma_state_q                     <= '0;
    end else begin
      pe_weight_buffer_aligned_q      <= pe_weight_buffer_aligned_d     ;
      pe_activation_buffer_aligned_q  <= pe_activation_buffer_aligned_d ;
      sf0_curr_buffer_aligned_q       <= sf0_curr_buffer_aligned_d      ;
      sf1_curr_buffer_aligned_q       <= sf1_curr_buffer_aligned_d      ;
      sf0_pred_buffer_aligned_q       <= sf0_pred_buffer_aligned_d      ;
      sf1_pred_buffer_aligned_q       <= sf1_pred_buffer_aligned_d      ;
      sign0_buffer_aligned_q          <= sign0_buffer_aligned_d         ;
      sign1_buffer_aligned_q          <= sign1_buffer_aligned_d         ;
      col_idx_q                       <= col_idx_d                      ;
      run_mode_q                      <= run_mode_d                     ;
      pe_enable_q                     <= pe_enable_d                    ;
      pe_finish_q                     <= pe_finish_d                    ;
      pe_in_valid_q                   <= pe_in_valid_d                  ;
      pe_state_q                      <= pe_state_d                     ;
      pe_cycle_cnt_q                  <= pe_cycle_cnt_d                 ;
      pe_dma_run_q                    <= pe_dma_run_d                   ;
      pe_dma_has_run_q                <= pe_dma_has_run_d               ;
      pe_dma_ready_q                  <= pe_dma_ready_d                 ;
      sf_enable_q                     <= sf_enable_d                    ;
      sf_finish_q                     <= sf_finish_d                    ;
      sf_state_q                      <= sf_state_d                     ;
      sf_cycle_cnt_q                  <= sf_cycle_cnt_d                 ;
      sf_dma_run_q                    <= sf_dma_run_d                   ;
      sf_dma_has_run_q                <= sf_dma_has_run_d               ;
      sf_dma_ready_q                  <= sf_dma_ready_d                 ;
      sf_has_enabled_q                <= sf_has_enabled_d               ;
      spattn_enable_q                 <= spattn_enable_d                ;
      spattn_finish_q                 <= spattn_finish_d                ;
      spattn_cycle_cnt_q              <= spattn_cycle_cnt_d             ;
      spattn_dma_run_q                <= spattn_dma_run_d               ;
      spattn_dma_has_run_q            <= spattn_dma_has_run_d           ;
      spattn_dma_ready_q              <= spattn_dma_ready_d             ;
      spattn_has_enabled_q            <= spattn_has_enabled_d           ;
      dma_last_winner_q               <= dma_last_winner_d              ;
      dma_state_q                     <= dma_state_d                    ;
    end
  end

endmodule

