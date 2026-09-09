// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
//////////////////////////////////////////////////////////////////////////////////
// Description: Testbench for the Learner FSM of the spec_prefill_unit module
// Author:      Mingxuan Li <siris-lmx@stu.pku.edu.cn> [Peking University]
// Acknowledge: VSCode Copilot + GPT-5 Agent
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module spec_prefill_unit_learner_tb;

    // Parameter definitions
    localparam int unsigned ADDR_WIDTH  = 64;
    localparam int unsigned DATA_WIDTH  = 64;
    localparam int unsigned HDC_DIM        = 2048;
    localparam int unsigned WEIGHT_WIDTH   = 6;
    localparam int unsigned TOKEN_ID_WIDTH = 16;
    localparam int unsigned RANDOM_WIDTH   = 16;
    localparam int unsigned TOKEN_WINDOW   = 4;
    localparam int unsigned HISTORY_WINDOW = 8;
    localparam int unsigned NUM_AGENT = 4;
    localparam int unsigned NUM_INPUT = 192 / WEIGHT_WIDTH; // 32
    localparam int unsigned NUM_ACCESS = HDC_DIM / (192 / WEIGHT_WIDTH); // 256/32=8
    localparam int unsigned BIAS = 128;

    // Base address definitions
    localparam logic [ADDR_WIDTH-1:0] INPUT_SRAM_BASE_ADDRESS             = 64'h0000000000000000;
    localparam logic [ADDR_WIDTH-1:0] WEIGHT_SRAM_BASE_ADDRESS            = 64'h0000000000001000;
    localparam logic [ADDR_WIDTH-1:0] TOKEN_ID_BUF_BASE_ADDRESS           = 64'h0000000000003000;
    localparam logic [ADDR_WIDTH-1:0] PREDICTOR_O_BUF_BASE_ADDRESS        = 64'h0000000000003008;
    localparam logic [ADDR_WIDTH-1:0] CSR_BASE_ADDRESS                    = 64'h0000000000003010;
    localparam logic [ADDR_WIDTH-1:0] STATUS_BASE_ADDRESS                 = 64'h0000000000003018;
    // History base addresses (as defined in spec_prefill_unit.sv)
    // HISTORY_BASE_ADDRESS consistent with the DUT (used as the encoder output storage offset)
    localparam logic [7:0][8:0] HISTORY_BASE_ADDRESS = {9'd84, 9'd72, 9'd60, 9'd48, 9'd36, 9'd24, 9'd12, 9'd0};

    // Command and status definitions
    localparam logic [1:0] CMD_IDLE = 2'b00;
    localparam logic [1:0] CMD_ENCODER = 2'b01;
    localparam logic [1:0] CMD_PREDICTOR = 2'b10;
    localparam logic [1:0] CMD_LEARNER   = 2'b11;
    localparam logic [1:0] POWER_IDLE = 2'b00;
    localparam logic [1:0] POWER_WORK = 2'b01;
    localparam logic [1:0] POWER_POWER_TEST = 2'b10;
    localparam logic [1:0] STATUS_IDLE = 2'b00;
    localparam logic [1:0] STATUS_BUSY = 2'b01;
    localparam logic [1:0] STATUS_FINISHED = 2'b10;

    // Agent base addresses (as defined in spec_prefill_unit.sv)
    localparam logic [NUM_AGENT-1:0][8:0] AGENT_BASE_ADDRESS = {9'd288, 9'd224, 9'd160, 9'd96};

    // Clock and reset signals
    logic clk_i;
    logic rstn_i;

    // AXI-like interface signals
    logic req_i;
    logic we_i;
    logic [ADDR_WIDTH-1:0] addr_i;
    logic be_i;
    logic [1:0] rtsel_i;
    logic [1:0] wtsel_i;
    logic [DATA_WIDTH-1:0] data_i;
    logic [DATA_WIDTH-1:0] data_o;

    // Clock generation (100MHz)
    initial clk_i = 1'b0;
    always #0.5 clk_i = ~clk_i;

    // DUT instantiation
    spec_prefill_unit #(
        .ADDR_WIDTH     (ADDR_WIDTH),
        .DATA_WIDTH     (DATA_WIDTH),
        .HDC_DIM        (HDC_DIM),
        .WEIGHT_WIDTH   (WEIGHT_WIDTH),
        .TOKEN_ID_WIDTH (TOKEN_ID_WIDTH),
        .RANDOM_WIDTH   (RANDOM_WIDTH),
        .TOKEN_WINDOW   (TOKEN_WINDOW),
        .BIAS           (BIAS)
    ) dut (
        .clk_i      (clk_i),
        .rstn_i     (rstn_i),
        .req_i      (req_i),
        .we_i       (we_i),
        .addr_i     (addr_i),
        .be_i       (be_i),
        .rtsel_i    (rtsel_i),
        .wtsel_i    (wtsel_i),
        .data_i     (data_i),
        .data_o     (data_o)
    );

    // Test variables
    logic [DATA_WIDTH-1:0] read_data;
    logic [DATA_WIDTH-1:0] write_data;
    int test_count;
    int error_count;

    // Function: compute the next LFSR value
    function automatic logic [15:0] lfsr_next(input logic [15:0] current);
        logic shift_in;
        shift_in = !(current[15] ^ current[12] ^ current[5] ^ current[1]);
        lfsr_next = {current[14:0], shift_in};
    endfunction

    // Function: generate the HDC hypervector for a single token_id
    // According to the logic in encoder.sv:
    // 1. SEED_LFSR state: lfsr_rstn_i = 0, shift_q <= seed_i (this cycle)
    // 2. GEN_VEC state: lfsr_rstn_i = 1, the LFSR updates once per cycle and the current value is sampled
    // 3. The first word uses the seed (after SEED_LFSR); subsequent words update every cycle
    function automatic logic [HDC_DIM-1:0] generate_hdc_vector(input logic [TOKEN_ID_WIDTH-1:0] token_id);
        localparam int unsigned NUM_WORDS = HDC_DIM / RANDOM_WIDTH;
        logic [15:0] lfsr_state;
        logic [HDC_DIM-1:0] hdc_vec;
        int word_idx;
        
        // SEED_LFSR state: the LFSR is reset to token_id
        lfsr_state = token_id;
        hdc_vec = '0;
        
        // GEN_VEC state: the first word uses the seed, then it updates every cycle
        for (word_idx = 0; word_idx < NUM_WORDS; word_idx++) begin
            // Write the current LFSR state into the corresponding position
            hdc_vec[word_idx*RANDOM_WIDTH +: RANDOM_WIDTH] = lfsr_state;
            // Update the LFSR state (prepare for the next word)
            if (word_idx < NUM_WORDS - 1) begin
                lfsr_state = lfsr_next(lfsr_state);
            end
        end
        
        generate_hdc_vector = hdc_vec;
    endfunction

    // Function: compute the final output vector of the encoder
    function automatic logic [HDC_DIM-1:0] compute_encoder_output(
        input logic [TOKEN_WINDOW-1:0][TOKEN_ID_WIDTH-1:0] token_ids
    );
        logic [HDC_DIM-1:0] partial_vector;
        logic [HDC_DIM-1:0] token_vector;
        int token_idx;
        
        partial_vector = '0;
        
        // Generate a hypervector for each token and combine them
        for (token_idx = 0; token_idx < TOKEN_WINDOW; token_idx++) begin
            token_vector = generate_hdc_vector(token_ids[token_idx]);
            // Combination rule: partial_hdc_vector_d = (partial_hdc_vector_q >> cnt_q) ^ hdc_vector_o
            partial_vector = (partial_vector >> token_idx) ^ token_vector;
        end
        
        compute_encoder_output = partial_vector;
    endfunction

    // Function: compute the xor_adder output
    // add_input[i] = ~(input_a_i[i] ^ input_b_i[i])
    // Then accumulate through a multi-level adder tree
    function automatic logic [$clog2(HDC_DIM)-1:0] compute_xor_adder(
        input logic [NUM_INPUT-1:0] input_a,
        input logic [NUM_INPUT-1:0] input_b,
        input logic [$clog2(HDC_DIM)-1:0] accumulator_init
    );
        logic [NUM_INPUT-1:0] add_input;
        logic [NUM_INPUT/2-1:0][1:0] adder_stage_0;
        logic [NUM_INPUT/4-1:0][2:0] adder_stage_1;
        logic [NUM_INPUT/8-1:0][3:0] adder_stage_2;
        logic [NUM_INPUT/16-1:0][4:0] adder_stage_3;
        logic [NUM_INPUT/32-1:0][5:0] adder_stage_4;
        logic [$clog2(HDC_DIM)-1:0] accumulator_output;
        int i;
        
        // Compute XOR and invert
        for (i = 0; i < NUM_INPUT; i++) begin
            add_input[i] = ~(input_a[i] ^ input_b[i]);
        end
        
        // Multi-level adder tree
        for (i = 0; i < NUM_INPUT/2; i++) begin
            adder_stage_0[i] = add_input[2*i] + add_input[2*i+1];
        end
        
        for (i = 0; i < NUM_INPUT/4; i++) begin
            adder_stage_1[i] = adder_stage_0[2*i] + adder_stage_0[2*i+1];
        end
        
        for (i = 0; i < NUM_INPUT/8; i++) begin
            adder_stage_2[i] = adder_stage_1[2*i] + adder_stage_1[2*i+1];
        end
        
        for (i = 0; i < NUM_INPUT/16; i++) begin
            adder_stage_3[i] = adder_stage_2[2*i] + adder_stage_2[2*i+1];
        end
        
        for (i = 0; i < NUM_INPUT/32; i++) begin
            adder_stage_4[i] = adder_stage_3[2*i] + adder_stage_3[2*i+1];
        end
        
        // Accumulate
        accumulator_output = accumulator_init + adder_stage_4[0];
        
        compute_xor_adder = accumulator_output;
    endfunction

    // Function: compute the expected predictor result
    // The predictor loops NUM_ACCESS times, calling xor_adder each time
    // Final result = accumulated result - BIAS
    function automatic logic [$clog2(HDC_DIM)-1:0] compute_predictor_result(
        input logic [HDC_DIM-1:0] encoder_vector,
        input logic [NUM_ACCESS-1:0][191:0] weight_data
    );
        logic [NUM_INPUT-1:0] hdc_input;
        logic [NUM_INPUT-1:0] weight_input;
        logic [$clog2(HDC_DIM)-1:0] accumulator;
        logic [$clog2(HDC_DIM)-1:0] acc_prev;
        logic [$clog2(HDC_DIM)-1:0] inc;
        logic [$clog2(HDC_DIM):0] final_result;
        int i, j;
        
        accumulator = '0;
        
        // Loop NUM_ACCESS times
        for (i = 0; i < NUM_ACCESS; i++) begin
            // Extract hdc_input: encoder_vector[NUM_INPUT*i +: NUM_INPUT]
            hdc_input = encoder_vector[NUM_INPUT*i +: NUM_INPUT];
            
            // Extract weight_input: the MSB of weight_data[i] (each weight is 6 bits; take the MSB)
            for (j = 0; j < NUM_INPUT; j++) begin
                weight_input[j] = weight_data[i][WEIGHT_WIDTH*j+WEIGHT_WIDTH-1];
            end
            
            // Compute xor_adder (the LOAD state resets the accumulator, but here we model the accumulation process)
            acc_prev = accumulator;
            if (i == 0) begin
                accumulator = compute_xor_adder(hdc_input, weight_input, 0);
            end else begin
                accumulator = compute_xor_adder(hdc_input, weight_input, accumulator);
            end
            inc = accumulator - acc_prev;
            $display("[REF] step=%0d hdc_in = %032h weight = %032h inc=%0d sum_after=%0d", i, hdc_input, weight_input, inc, accumulator);
        end
        
        // FINISH state: result = accumulator - BIAS
        final_result = {1'b0, accumulator} - BIAS;
        $display("[REF] final_after_minus_bias=%0d (bias=%0d)", final_result, BIAS);
        // Consistent with the DUT, take the low bits (natural wrap-around, no saturation)
        compute_predictor_result = final_result[$clog2(HDC_DIM)-1:0];
    endfunction

    // Learner reference: update of a single 192-bit weight row
    function automatic logic [191:0] learner_update_word(
        input logic [NUM_INPUT-1:0] hdc_word,
        input logic [191:0] weight_word,
        input logic reward_bit
    );
        logic signed [1:0] reward_val, rewardn_val;
        logic signed [WEIGHT_WIDTH-1:0] w_in;
        logic signed [WEIGHT_WIDTH-1:0] w_out;
        logic signed [1:0] fb;
        int k;
        begin
            reward_val   = reward_bit ?  1 : -1;
            rewardn_val  = reward_bit ? -1 :  1;
            for (k = 0; k < NUM_INPUT; k++) begin
                fb    = (hdc_word[k] == weight_word[WEIGHT_WIDTH*k + WEIGHT_WIDTH - 1]) ? reward_val : rewardn_val;
                w_in  = weight_word[WEIGHT_WIDTH*k +: WEIGHT_WIDTH];
                w_out = w_in + fb;
                learner_update_word[WEIGHT_WIDTH*k +: WEIGHT_WIDTH] = w_out;
            end
        end
    endfunction

    // Task: AXI write operation
    task automatic axi_write(input logic [ADDR_WIDTH-1:0] addr, input logic [DATA_WIDTH-1:0] data);
        @(posedge clk_i);
        req_i <= 1'b1;
        we_i <= 1'b1;
        addr_i <= addr;
        data_i <= data;
        @(posedge clk_i);
        req_i <= 1'b0;
        we_i <= 1'b0;
        @(posedge clk_i);
    endtask

    // Task: AXI read operation
    // For a read, req_i is asserted for one cycle and data_o is sampled in the next cycle
    task automatic axi_read(input logic [ADDR_WIDTH-1:0] addr, output logic [DATA_WIDTH-1:0] data);
        @(posedge clk_i);
        req_i <= 1'b1;
        we_i <= 1'b0;
        addr_i <= addr;
        @(posedge clk_i);
        req_i <= 1'b0;
        @(posedge clk_i);
        data = data_o;
    endtask

    // Task: wait for predictor status
    task automatic wait_for_predictor_status(input logic [1:0] expected_status, input int max_cycles);
        automatic int count = 0;
        automatic logic [DATA_WIDTH-1:0] status_data;
        
        do begin
            axi_read(STATUS_BASE_ADDRESS, status_data);
            count++;
            if (count > max_cycles) begin
                $error("Timeout waiting for predictor status. Expected: %02b, Got: %02b", expected_status, status_data[3:2]);
                break;
            end
            @(posedge clk_i);
        end while ((status_data[3:2] != expected_status));
    endtask

    // Task: wait for predictor done
    task automatic wait_predictor_finish();
        wait_for_predictor_status(STATUS_FINISHED, 10000);
    endtask

    // Task: wait for encoder status
    task automatic wait_for_encoder_status(input logic [1:0] expected_status);
        automatic logic [DATA_WIDTH-1:0] status_reg;
        do begin
            axi_read(STATUS_BASE_ADDRESS, status_reg);
            if (status_reg[1:0] == expected_status) begin
                break;
            end
            @(posedge clk_i);
        end while ((status_reg[1:0] != expected_status));
    endtask

    // Task: wait for encoder done
    task automatic wait_encoder_finish();
        wait_for_encoder_status(STATUS_FINISHED);
        $display("[%0t] Encoder finished", $time);
    endtask

    // Test: Predictor basic function test
    task automatic test_predictor_basic();
        automatic int agent = 0;
        automatic int WEIGHT_START_ADDRESS = 96;
        automatic logic [ADDR_WIDTH-1:0] read_addr;
        automatic logic [TOKEN_WINDOW-1:0][TOKEN_ID_WIDTH-1:0] token_ids;
        automatic logic [HDC_DIM-1:0] encoder_vector;
        automatic logic [NUM_ACCESS-1:0][191:0] weight_data;
        automatic logic [$clog2(HDC_DIM)-1:0] expected_result;
        automatic logic [$clog2(HDC_DIM)-1:0] actual_result;
        automatic logic [DATA_WIDTH-1:0] predictor_buffer;
        
        $display("\n=== Test 1: Predictor Basic Functionality ===");
        test_count++;
        
        // Step 1: run the encoder first to generate encoder_o_buffer_q
        // Write Token IDs
        write_data = 64'h0004_0003_0002_0001;
        axi_write(TOKEN_ID_BUF_BASE_ADDRESS, write_data);
        $display("[%0t] Wrote Token ID Buffer: 0x%016h", $time, write_data);
        
        // Extract token IDs and compute/compare the encoder output
        for (int j = 0; j < TOKEN_WINDOW; j++) begin
            token_ids[j] = write_data[TOKEN_ID_WIDTH*j +: TOKEN_ID_WIDTH];
        end
        encoder_vector = compute_encoder_output(token_ids);
        $display("  Computed expected encoder vector (first 64 bits): 0x%016h", encoder_vector[63:0]);
        
        // Step 2: configure CSR (history_id=0)
        // CSR format: same as above, encoder_power_mode=POWER_WORK, history_id=0
        write_data = 64'h00000005;
        axi_write(CSR_BASE_ADDRESS, write_data);
        $display("[%0t] Started encoder with history_id=0", $time);
        
        // Wait for the encoder to finish
        wait_encoder_finish();
        $display("[%0t] Encoder finished", $time);
        // Wait two cycles to avoid the one-cycle delay between the encoder writing the SRAM and the CPU reading it
        repeat (2) @(posedge clk_i);

        // Exact comparison: compare the encoder output word by word (64-bit)
        // The encoder writes to weight_sram address HISTORY_BASE_ADDRESS[history_id] + encoder_addr_cnt_q
        // Encoder write logic: every 3 encoder_cnt values correspond to one weight_sram address (3 64-bit parts are written)
        // encoder_bitmask_cnt cycles 0->1->2->0 and controls which part is written
        // encoder_addr_cnt increments when encoder_bitmask_cnt==2
        // The CPU accesses it through the INPUT_SRAM region: addr_offset = (weight_sram_internal_addr << 5) | (part_idx << 3)
        // Because the INPUT_SRAM region maps directly to weight_sram (no offset), addr_offset[13:5] = weight_sram_addr
        $display("  Reading and comparing encoder output from Input SRAM (history_id=0)...");
        // Encoder write logic:
        // - encoder_cnt_q: 0 to (NUM_ACCESS/2)-1, NUM_ACCESS/2 writes in total
        // - encoder_bitmask_cnt_q: 0 -> 1 -> 2 -> 0 -> 1 -> 2 -> ... (cyclic)
        // - encoder_addr_cnt_q: increments when encoder_bitmask_cnt_q == 2'b10 (once every 3 encoder_cnt values)
        // - weight_sram_encoder_address_i = encoder_addr_cnt_q + HISTORY_BASE_ADDRESS[0]
        // - encoder_bitmask_cnt_q determines which part is written (0=part0, 1=part1, 2=part2)
        // 
        // So: when encoder_cnt_q=i, encoder_addr_cnt_q = i/3, encoder_bitmask_cnt_q = i%3
        for (int w = 0; w < (NUM_ACCESS/2); w++) begin  // encoder_cnt from 0 to (NUM_ACCESS/2)-1
            automatic int encoder_addr = (w / 3);   // Every 3 encoder_cnt values correspond to one weight_sram address
            automatic int part_idx = (w % 3);       // Determine which part (0, 1, 2)
            automatic logic [ADDR_WIDTH-1:0] enc_rd_addr;
            automatic logic [63:0] exp_64bit;
            automatic logic [63:0] act_64bit;
            // CPU address computation: addr_offset = (weight_sram_internal_addr << 5) | (part_idx << 3)
            // where weight_sram_internal_addr = HISTORY_BASE_ADDRESS[0] + encoder_addr
            // CPU address = INPUT_SRAM_BASE_ADDRESS + ((HISTORY_BASE_ADDRESS[0] + encoder_addr) << 5) + (part_idx << 3)
            enc_rd_addr = INPUT_SRAM_BASE_ADDRESS + ((HISTORY_BASE_ADDRESS[0] + encoder_addr) << 5) + (part_idx << 3);
            axi_read(enc_rd_addr, predictor_buffer);
            act_64bit = predictor_buffer[63:0];
            
            // The encoder writes 64-bit data taken from encoder_o_buffer_q[64*encoder_cnt_q +: 64]
            // encoder_cnt_q = w, so the data is at encoder_vector[64*w +: 64]
            exp_64bit = encoder_vector[64*w +: 64];
            if (act_64bit !== exp_64bit) begin
                $error("  [%0d] FAIL: Encoder output encoder_cnt[%0d] addr[%0d] part[%0d] (addr=0x%016h): Expected=0x%016h, Got=0x%016h", 
                       w, w, encoder_addr, part_idx, enc_rd_addr, exp_64bit, act_64bit);
                error_count++;
            end else begin
                $display("  [%0d] PASS: Encoder output encoder_cnt[%0d] addr[%0d] part[%0d] (addr=0x%016h): 0x%016h", 
                         w, w, encoder_addr, part_idx, enc_rd_addr, act_64bit);
            end
        end
        
        // Step 2: write Weight SRAM data (for agent_id=0) and store it
        // When the Learner accesses the Weight SRAM it uses weight_sram_learner_address_i = learner_cnt_q + AGENT_BASE_ADDRESS[agent_id]
        // learner_cnt_q goes from 0 to NUM_ACCESS-1, so NUM_ACCESS SRAM addresses need to be written
        // Each SRAM address holds 192 bits of data; the CPU needs 3 accesses (part 0, 1, 2) to fill it
        // The CPU accesses it through the WEIGHT_SRAM region: addr_offset = sp_addr_i - WEIGHT_SRAM_BASE_ADDRESS
        // weight_sram_cpu_address_i = addr_offset[13:5] + WEIGHT_START_ADDRESS (96)
        // So: sram_addr = addr_offset[13:5] + 96, hence addr_offset[13:5] = sram_addr - 96
        // CPU address = WEIGHT_SRAM_BASE_ADDRESS + ((sram_addr - 96) << 5) + (part << 3)
        $display("[%0t] Writing Weight SRAM data for learner (agent=0)...", $time);
        for (int i = 0; i < NUM_ACCESS; i++) begin
            // Compute the SRAM internal address (the address accessed by the learner)
            automatic logic [8:0] sram_addr = AGENT_BASE_ADDRESS[agent] + i;
            automatic logic [63:0] part_data [0:2];
            
            // Write and store the three parts (each SRAM address needs 3 CPU accesses to fill 192 bits)
            for (int part = 0; part < 3; part++) begin
                // CPU address = WEIGHT_SRAM_BASE_ADDRESS + ((sram_addr - WEIGHT_START_ADDRESS) << 5) + (part << 3)
                read_addr = WEIGHT_SRAM_BASE_ADDRESS + ((sram_addr - WEIGHT_START_ADDRESS) << 5) + (part << 3);
                //write_data = {$urandom(), $urandom()}; // Generate 64-bit random data
                write_data = {'0,$urandom()};
                part_data[part] = write_data;
                axi_write(read_addr, write_data);
            end
            
            // Combine into 192-bit data (part 2 in the high bits, part 0 in the low bits)
            weight_data[i] = {part_data[2], part_data[1], part_data[0]};
            $display("  WEIGHT_W sram_addr=%0d parts: %016h | %016h | %016h", sram_addr, part_data[2], part_data[1], part_data[0]);
        end
        
        // Compute the expected predictor result
        expected_result = compute_predictor_result(encoder_vector, weight_data);
        $display("  Computed expected predictor result: 0x%08h (%0d)", expected_result, expected_result);
        
        // Step 3: configure CSR to start the predictor (agent_id=0)
        // CSR format: [1:0]=cmd, [3:2]=power_mode, [5:4]=agent_id, [8:6]=history_id, [9]=reward
        // cmd=CMD_PREDICTOR(10)=2, power_mode=POWER_WORK(01)=1<<2=4, agent_id=0(00)=0
        // CSR = 2 + 4 = 6 = 0x06
        write_data = 64'h00000006; // [1:0]=10(CMD_PREDICTOR), [3:2]=01(POWER_WORK), [5:4]=00(agent_id=0)
        axi_write(CSR_BASE_ADDRESS, write_data);
        // After predictor_en is asserted, the predictor FSM starts feeding the first set of data to the core only in the next cycle
        repeat (2) @(posedge clk_i);
        $display("[%0t] Started predictor with agent_id=0 (inputs begin next cycle)", $time);
        
        // Step 4: wait for the predictor to finish
        wait_predictor_finish();
        $display("[%0t] Predictor finished", $time);
        
        // Step 5: read the predictor output and compare
        axi_read(PREDICTOR_O_BUF_BASE_ADDRESS, predictor_buffer);
        actual_result = predictor_buffer[$clog2(HDC_DIM)*agent +: $clog2(HDC_DIM)];
        
        $display("  Predictor output buffer: 0x%016h", predictor_buffer);
        $display("  Agent[0] actual result: 0x%08h (%0d)", actual_result, actual_result);
        
        if (actual_result == expected_result) begin
            $display("  PASS: Predictor result matches expected value");
        end else begin
            error_count++;
            $error("  FAIL: Predictor result mismatch! Expected=0x%08h (%0d), Got=0x%08h (%0d)", 
                   expected_result, expected_result, actual_result, actual_result);
        end
    endtask

    // Task: wait for learner status
    task automatic wait_for_learner_status(input logic [1:0] expected_status, input int max_cycles);
        automatic int count = 0;
        automatic logic [DATA_WIDTH-1:0] status_data;
        
        do begin
            if (count % 13 == 0) begin // Prevent req from preempting the learner's CSR rewrite
                axi_read(STATUS_BASE_ADDRESS, status_data);
                if (status_data[5:4] == expected_status) begin
                    break;
                end
            end
            count++;
            if (count > max_cycles) begin
                axi_read(STATUS_BASE_ADDRESS, status_data); // Read the status one last time for the error message
                $error("Timeout waiting for learner status. Expected: %02b, Got: %02b", expected_status, status_data[5:4]);
                break;
            end
            @(posedge clk_i);
        end while (1);
    endtask

    task automatic wait_learner_finish();
        wait_for_learner_status(STATUS_FINISHED, 10000);
    endtask

    // Test: Learner POWER_POWER_TEST mode (only asserts power_test, does not actually start learner_en)
    task automatic test_learner_power_test();
        $display("\n=== Test 0: Learner POWER_POWER_TEST Mode ===");
        test_count++;

        // Configure CSR: cmd=CMD_IDLE, learner_power_mode=POWER_POWER_TEST
        // cmd=00, encoder_power=00, predictor_power=00, learner_power=10->[7:6]=2 => 0x80
        write_data = 64'h00000080;
        axi_write(CSR_BASE_ADDRESS, write_data);
        $display("[%0t] Set learner POWER_POWER_TEST mode, CSR=0x%016h", $time, write_data);

        // Wait 512 cycles and then finish (observe internal behavior/waveforms in the power test mode)
        repeat (512) @(posedge clk_i);
    endtask
    // Test: Learner basic function (agent=0, history=0, reward=1)
    task automatic test_learner_basic();
        automatic int agent = 0;
        automatic int history = 0;
        automatic int WEIGHT_START_ADDRESS = 96;
        automatic logic [ADDR_WIDTH-1:0] read_addr;
        automatic logic [NUM_ACCESS-1:0][191:0] weight_before;
        automatic logic [NUM_ACCESS-1:0][191:0] weight_expected;
        automatic logic [NUM_ACCESS-1:0][191:0] weight_after;
        automatic logic [TOKEN_WINDOW-1:0][TOKEN_ID_WIDTH-1:0] token_ids;
        automatic logic [HDC_DIM-1:0] encoder_vector;
        automatic logic [DATA_WIDTH-1:0] predictor_buffer;
        automatic int pass_cnt = 0;
        automatic int fail_cnt = 0;

        $display("\n=== Test: Learner Basic (agent=0, history=0, reward=1) ===");
        test_count++;

        // Step 1: run the encoder first to generate encoder_o_buffer_q
        // Write Token IDs
        write_data = 64'h0001_0002_0003_0004;
        axi_write(TOKEN_ID_BUF_BASE_ADDRESS, write_data);
        $display("[%0t] Wrote Token ID Buffer: 0x%016h", $time, write_data);
        
        // Extract token IDs and compute/compare the encoder output
        for (int j = 0; j < TOKEN_WINDOW; j++) begin
            token_ids[j] = write_data[TOKEN_ID_WIDTH*j +: TOKEN_ID_WIDTH];
        end
        encoder_vector = compute_encoder_output(token_ids);
        $display("  Computed expected encoder vector (first 64 bits): 0x%016h", encoder_vector[63:0]);
        
        // Step 2: configure CSR (history_id=0)
        // CSR format: same as above, encoder_power_mode=POWER_WORK, history_id=0
        write_data = 64'h00000005;
        axi_write(CSR_BASE_ADDRESS, write_data);
        $display("[%0t] Started encoder with history_id=0", $time);
        
        // Wait for the encoder to finish
        wait_encoder_finish();
        $display("[%0t] Encoder finished", $time);
        // Wait two cycles to avoid the one-cycle delay between the encoder writing the SRAM and the CPU reading it
        repeat (2) @(posedge clk_i);

        // 2) Write the Weight SRAM (initial weights) for agent=0 and record weight_before
        // The CPU accesses it through the WEIGHT_SRAM region: CPU address = WEIGHT_SRAM_BASE_ADDRESS + ((sram_addr - 96) << 5) + (part << 3)
        $display("[%0t] Writing Weight SRAM initial data for learner (agent=0)...", $time);
        for (int i = 0; i < NUM_ACCESS; i++) begin
            automatic logic [8:0] sram_addr = AGENT_BASE_ADDRESS[agent] + i;
            automatic logic [63:0] part_data [0:2];
            for (int part = 0; part < 3; part++) begin
                read_addr = WEIGHT_SRAM_BASE_ADDRESS + ((sram_addr - WEIGHT_START_ADDRESS) << 5) + (part << 3);
                write_data = {$urandom(), $urandom()}; // 64-bit random
                part_data[part] = write_data;
                axi_write(read_addr, write_data);
            end
            weight_before[i] = {part_data[2], part_data[1], part_data[0]};
        end

        // 3) Compute the expected learner result (reward=1)
        for (int i = 0; i < NUM_ACCESS; i++) begin
            automatic logic [NUM_INPUT-1:0] hdc_word;
            hdc_word = encoder_vector[NUM_INPUT*i +: NUM_INPUT];
            weight_expected[i] = learner_update_word(hdc_word, weight_before[i], /*reward=*/1'b1);
        end

        // 4) Start the learner: CMD_LEARNER + POWER_WORK(learner_power_mode) + agent_id=0 + history_id=0 + reward=1
        // CSR: [1:0]=11 (CMD_LEARNER=3), encoder_power=[3:2]=00, predictor_power=[5:4]=00,
        //      learner_power=[7:6]=01 (POWER_WORK), agent_id=[9:8]=00, history=[12:10]=000, reward[13]=1
        // Values: cmd=3, learner_power=1<<6=0x40, reward_bit=1<<13=0x2000, total=0x2000+0x40+0x3=0x2043
        write_data = 64'h00002043;
        axi_write(CSR_BASE_ADDRESS, write_data);
        repeat (2) @(posedge clk_i); // Processing starts in the next cycle
        wait_learner_finish();

        // 5) Read the Weight SRAM, assemble 192 bits, and compare against the expected value
        // The CPU accesses it through the WEIGHT_SRAM region: CPU address = WEIGHT_SRAM_BASE_ADDRESS + ((sram_addr - 96) << 5) + (part << 3)
        for (int i = 0; i < NUM_ACCESS; i++) begin
            automatic logic [8:0] sram_addr = AGENT_BASE_ADDRESS[agent] + i;
            automatic logic [63:0] part_rd [0:2];
            for (int part = 0; part < 3; part++) begin
                read_addr = WEIGHT_SRAM_BASE_ADDRESS + ((sram_addr - WEIGHT_START_ADDRESS) << 5) + (part << 3);
                axi_read(read_addr, predictor_buffer);
                part_rd[part] = predictor_buffer;
            end
            weight_after[i] = {part_rd[2], part_rd[1], part_rd[0]};
            if (weight_after[i] !== weight_expected[i]) begin
                fail_cnt++;
                $error("LEARN FAIL addr=%0d exp=%048h got=%048h", sram_addr, weight_expected[i], weight_after[i]);
            end else begin
                pass_cnt++;
                $display("LEARN PASS addr=%0d updated=%048h", sram_addr, weight_after[i]);
            end
        end

        $display("Learner compare summary: pass=%0d fail=%0d", pass_cnt, fail_cnt);
        if (fail_cnt != 0) begin
            error_count += fail_cnt;
        end
    endtask

    // Test: multiple agent_id test
    task automatic test_predictor_multiple_agent();
        automatic int agent;
        automatic int WEIGHT_START_ADDRESS = 96;
        automatic logic [ADDR_WIDTH-1:0] read_addr;
        automatic logic [TOKEN_WINDOW-1:0][TOKEN_ID_WIDTH-1:0] token_ids;
        automatic logic [HDC_DIM-1:0] encoder_vector;
        automatic logic [NUM_AGENT-1:0][NUM_ACCESS-1:0][191:0] weight_data_array;
        automatic logic [$clog2(HDC_DIM)-1:0] expected_result;
        automatic logic [$clog2(HDC_DIM)-1:0] actual_result;
        automatic logic [DATA_WIDTH-1:0] predictor_buffer;
        automatic int pass_count = 0;
        automatic int fail_count = 0;
        automatic int data_pass_count = 0;
        automatic int data_fail_count = 0;
        
        $display("\n=== Test 2: Predictor with Multiple Agent IDs ===");
        test_count++;
        
        // Step 1: run the encoder first to generate encoder_o_buffer_q
        write_data = 64'h0008_0007_0006_0005;
        axi_write(TOKEN_ID_BUF_BASE_ADDRESS, write_data);
        $display("[%0t] Wrote Token ID Buffer: 0x%016h", $time, write_data);
        
        // Extract token IDs and compute/compare the encoder output
        for (int j = 0; j < TOKEN_WINDOW; j++) begin
            token_ids[j] = write_data[TOKEN_ID_WIDTH*j +: TOKEN_ID_WIDTH];
        end
        encoder_vector = compute_encoder_output(token_ids);
        
        // Step 2: configure CSR (history_id=0)
        // CSR format: same as above, encoder_power_mode=POWER_WORK, history_id=0
        write_data = 64'h00000005;
        axi_write(CSR_BASE_ADDRESS, write_data);
        $display("[%0t] Started encoder with history_id=0", $time);
        
        wait_encoder_finish();
        $display("[%0t] Encoder finished", $time);
        
        // Step 2: write Weight SRAM data for all agents and store it
        // When the Predictor accesses the Weight SRAM it uses weight_sram_predictor_address_i = predictor_cnt_q + AGENT_BASE_ADDRESS[agent_id]
        // predictor_cnt_q goes from 0 to NUM_ACCESS-1, so NUM_ACCESS SRAM addresses need to be written
        // Each SRAM address holds 192 bits of data; the CPU needs 3 accesses (part 0, 1, 2) to fill it
        // The CPU accesses it through the WEIGHT_SRAM region: addr_offset = sp_addr_i - WEIGHT_SRAM_BASE_ADDRESS
        // weight_sram_cpu_address_i = addr_offset[13:5] + WEIGHT_START_ADDRESS (96)
        // CPU address = WEIGHT_SRAM_BASE_ADDRESS + ((sram_addr - 96) << 5) + (part << 3)
        for (agent = 0; agent < NUM_AGENT; agent++) begin
            $display("[%0t] Writing Weight SRAM data for agent_id=%0d (sram_addr, part2|part1|part0)...", $time, agent);
            for (int i = 0; i < NUM_ACCESS; i++) begin
                // Compute the SRAM internal address (the address accessed by the predictor)
                automatic logic [8:0] sram_addr = AGENT_BASE_ADDRESS[agent] + i;
                automatic logic [63:0] part_data [0:2];
                
                // Write and store the three parts (each SRAM address needs 3 CPU accesses to fill 192 bits)
                for (int part = 0; part < 3; part++) begin
                    // CPU address = WEIGHT_SRAM_BASE_ADDRESS + ((sram_addr - WEIGHT_START_ADDRESS) << 5) + (part << 3)
                    read_addr = WEIGHT_SRAM_BASE_ADDRESS + ((sram_addr - WEIGHT_START_ADDRESS) << 5) + (part << 3);
                    write_data = {$urandom(), $urandom()}; // Generate 64-bit random data
                    part_data[part] = write_data;
                    axi_write(read_addr, write_data);
                end
                
                // Combine into 192-bit data and store it (part 2 in the high bits, part 0 in the low bits)
                weight_data_array[agent][i] = {part_data[2], part_data[1], part_data[0]};
                $display("  WEIGHT_W agent=%0d sram_addr=%0d parts: %016h | %016h | %016h",
                         agent, sram_addr, part_data[2], part_data[1], part_data[0]);
            end
        end
        
        // Test different agent_id values
        for (agent = 0; agent < NUM_AGENT; agent++) begin
            // Compute the expected predictor result
            expected_result = compute_predictor_result(encoder_vector, weight_data_array[agent]);
            $display("  Agent[%0d] expected result: 0x%08h (%0d)", agent, expected_result, expected_result);
            
            // Step 3: configure CSR to start the predictor
            // CSR format: [1:0]=cmd, [3:2]=power_mode, [5:4]=agent_id, [8:6]=history_id, [9]=reward
            // cmd=CMD_PREDICTOR(10)=2, power_mode=POWER_WORK(01)=1<<2=4, agent_id=agent<<4
            // CSR = 2 + 4 + (agent << 4) = 6 + (agent << 4)
            write_data = 64'h00000006 | (agent << 4); // [1:0]=10(CMD_PREDICTOR), [3:2]=01(POWER_WORK), [5:4]=agent_id
            axi_write(CSR_BASE_ADDRESS, write_data);
            // After predictor_en is asserted, the predictor FSM starts feeding the first set of data to the core only in the next cycle
            repeat (2) @(posedge clk_i);
            $display("[%0t] Started predictor with agent_id=%0d, CSR=0x%016h (inputs begin next cycle)", $time, agent, write_data);
            
            // Step 4: wait for the predictor to finish
            wait_predictor_finish();
            
            // Step 5: check status
            axi_read(STATUS_BASE_ADDRESS, read_data);
            if (read_data[3:2] == STATUS_FINISHED) begin
                pass_count++;
            end else begin
                fail_count++;
                error_count++;
                $error("  FAIL: Predictor with agent_id=%0d failed. Status: 0x%02h", agent, read_data[3:2]);
            end
            
            // Step 6: read the predictor output and compare
            axi_read(PREDICTOR_O_BUF_BASE_ADDRESS, predictor_buffer);
            actual_result = predictor_buffer[$clog2(HDC_DIM)*agent +: $clog2(HDC_DIM)];
            
            $display("  Agent[%0d] actual result: 0x%08h (%0d)", agent, actual_result, actual_result);
            
            if (actual_result == expected_result) begin
                data_pass_count++;
                $display("  PASS: Agent[%0d] result matches expected value", agent);
            end else begin
                data_fail_count++;
                error_count++;
                $error("  FAIL: Agent[%0d] result mismatch! Expected=0x%08h (%0d), Got=0x%08h (%0d)", 
                       agent, expected_result, expected_result, actual_result, actual_result);
            end
            
            // Wait a few cycles before testing the next one
            repeat(10) @(posedge clk_i);
        end
        
        $display("  Test Summary: %0d status checks passed, %0d status checks failed", pass_count, fail_count);
        $display("  Data Verification Summary: %0d passed, %0d failed out of %0d agents", 
                 data_pass_count, data_fail_count, NUM_AGENT);
        if (data_fail_count == 0 && fail_count == 0) begin
            $display("  PASS: All predictor tests completed successfully");
        end else begin
            $error("  FAIL: Predictor tests found %0d errors", data_fail_count + fail_count);
        end
    endtask

    // Main test sequence
    initial begin
        // Initialization
        rstn_i = 1'b0;
        req_i = 1'b0;
        we_i = 1'b0;
        addr_i = '0;
        be_i = 1'b0;
        rtsel_i = 2'b00;
        wtsel_i = 2'b00;
        data_i = '0;
        test_count = 0;
        error_count = 0;
        
        // Reset
        repeat(10) @(posedge clk_i);
        rstn_i = 1'b1;
        repeat(10) @(posedge clk_i);
        
        $display("========================================");
        $display("Learner Testbench Started");
        $display("========================================");
        
        // Run tests
        test_learner_basic();
        #4;
        // test_learner_power_test();
        // #4;
        
        // Test summary
        $display("\n========================================");
        $display("Test Summary");
        $display("========================================");
        $display("Total tests: %0d", test_count);
        $display("Total errors: %0d", error_count);
        if (error_count == 0) begin
            $display("All tests PASSED!");
        end else begin
            $display("Some tests FAILED!");
        end
        $display("========================================");
        
        #100;
        $finish;
    end

endmodule

