// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
//////////////////////////////////////////////////////////////////////////////////
// Description: Testbench for the Encoder FSM of the spec_prefill_unit module
// Author:      Mingxuan Li <siris-lmx@stu.pku.edu.cn> [Peking University]
// Acknowledge: VSCode Copilot + GPT-5 Agent
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module spec_prefill_unit_encoder_tb;

    // Parameter definitions
    localparam int unsigned ADDR_WIDTH  = 64;
    localparam int unsigned DATA_WIDTH  = 64;
    localparam int unsigned HDC_DIM        = 256;
    localparam int unsigned WEIGHT_WIDTH   = 6;
    localparam int unsigned TOKEN_ID_WIDTH = 16;
    localparam int unsigned RANDOM_WIDTH   = 16;
    localparam int unsigned TOKEN_WINDOW   = 4;
    localparam int unsigned HISTORY_WINDOW = 8;
    localparam int unsigned BIAS = 128;
    localparam int unsigned NUM_ACCESS = HDC_DIM / (192 / WEIGHT_WIDTH); // 2048/32=64

    // Base address definitions
    localparam logic [ADDR_WIDTH-1:0] INPUT_SRAM_BASE_ADDRESS             = 64'h0000000000000000;
    localparam logic [ADDR_WIDTH-1:0] TOKEN_ID_BUF_BASE_ADDRESS           = 64'h0000000000003000;
    localparam logic [ADDR_WIDTH-1:0] CSR_BASE_ADDRESS                    = 64'h0000000000003010;
    localparam logic [ADDR_WIDTH-1:0] STATUS_BASE_ADDRESS                 = 64'h0000000000003018;

    // Command and status definitions
    localparam logic [1:0] CMD_IDLE = 2'b00;
    localparam logic [1:0] CMD_ENCODER = 2'b01;
    localparam logic [1:0] POWER_IDLE = 2'b00;
    localparam logic [1:0] POWER_WORK = 2'b01;
    localparam logic [1:0] POWER_POWER_TEST = 2'b10;
    localparam logic [1:0] STATUS_IDLE = 2'b00;
    localparam logic [1:0] STATUS_BUSY = 2'b01;
    localparam logic [1:0] STATUS_FINISHED = 2'b10;

    // History base addresses (as defined in spec_prefill_unit.sv)
    // HISTORY_BASE_ADDRESS consistent with the DUT (used as the encoder output storage offset)
    localparam logic [HISTORY_WINDOW-1:0][8:0] HISTORY_BASE_ADDRESS = {9'd84, 9'd72, 9'd60, 9'd48, 9'd36, 9'd24, 9'd12, 9'd0};

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
    always #5 clk_i = ~clk_i;

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

    // Test: Encoder POWER_POWER_TEST function (only asserts power_test, does not actually start encoder_en)
    task automatic test_encoder_power_test();
        $display("\n=== Test 0: Encoder POWER_POWER_TEST Mode ===");
        test_count++;

        // Write Token IDs (arbitrary values)
        write_data = 64'hDEAD_BEEF_CAFE_F00D;
        axi_write(TOKEN_ID_BUF_BASE_ADDRESS, write_data);

        // Configure CSR: cmd=CMD_IDLE, encoder_power_mode=POWER_POWER_TEST
        // cmd=00, encoder_power=10->[3:2]=2 => 0x8
        write_data = 64'h00000008;
        axi_write(CSR_BASE_ADDRESS, write_data);
        $display("[%0t] Set encoder POWER_POWER_TEST mode, CSR=0x%016h", $time, write_data);
        // Wait 512 cycles and then finish (observe internal behavior/waveforms in the power test mode)
        repeat (512) @(posedge clk_i);
    endtask

    // Task: AXI read operation
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

    // Task: wait for encoder status
    task automatic wait_for_encoder_status(input logic [1:0] expected_status, input int timeout = 10000);
        logic [DATA_WIDTH-1:0] status_reg;
        automatic int count = 0;
        do begin
            axi_read(STATUS_BASE_ADDRESS, status_reg);
            count++;
            if (count > timeout) begin
                $error("Timeout waiting for encoder status. Expected: %02b, Got: %02b", expected_status, status_reg[1:0]);
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

    // Test: Encoder FSM basic function test
    task automatic test_encoder_basic();
        $display("\n=== Test 1: Encoder FSM Basic Test ===");
        test_count++;
        
        // Step 1: write Token IDs
        write_data = 64'h0004_0003_0002_0001; // token[0]=1, token[1]=2, token[2]=3, token[3]=4
        axi_write(TOKEN_ID_BUF_BASE_ADDRESS, write_data);
        $display("[%0t] Wrote Token ID Buffer: 0x%016h", $time, write_data);
        
        // Step 2: configure CSR (normal work mode)
        // CSR format: [1:0]=cmd, [3:2]=encoder_power_mode, [5:4]=predictor_power_mode, [7:6]=learner_power_mode,
        //           [9:8]=agent_id, [12:10]=history_id, [13]=reward
        // cmd=CMD_ENCODER(01), encoder_power_mode=POWER_WORK(01), other power_mode=IDLE(00), agent_id=0(00), history_id=0(000), reward=0
        // CSR = {[13]=0,[12:10]=000,[9:8]=00,[7:6]=00,[5:4]=00,[3:2]=01,[1:0]=01} = 0x00000005
        write_data = 64'h00000005;
        axi_write(CSR_BASE_ADDRESS, write_data);
        $display("[%0t] Started encoder: CSR=0x%016h (cmd=ENCODER, power_mode=WORK, agent_id=0, history_id=0)", $time, write_data);
        
        // Step 3: check that the encoder status becomes BUSY
        wait_for_encoder_status(STATUS_BUSY, 1000);
        $display("[%0t] Encoder status changed to BUSY", $time);
        
        // Step 4: wait for the encoder to finish
        wait_encoder_finish();
        
        // Step 5: check the status register
        axi_read(STATUS_BASE_ADDRESS, read_data);
        if (read_data[1:0] == STATUS_FINISHED) begin
            $display("  PASS: Encoder status is FINISHED");
        end else begin
            $error("  FAIL: Encoder status incorrect: 0x%02h", read_data[1:0]);
            error_count++;
        end
        
        // Step 6: check whether the CSR command has been cleared (should become CMD_IDLE)
        axi_read(CSR_BASE_ADDRESS, read_data);
        if (read_data[1:0] == CMD_IDLE) begin
            $display("  PASS: CSR command cleared to IDLE after completion");
        end else begin
            $error("  FAIL: CSR command not cleared. Expected: 0x%02h, Got: 0x%02h", CMD_IDLE, read_data[1:0]);
            error_count++;
        end
    endtask

    // Function: compute the next LFSR value
    // LFSR update rule: shift_in = !(shift_q[15] ^ shift_q[12] ^ shift_q[5] ^ shift_q[1])
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

    // Test: verify the data the Encoder writes into the Input SRAM
    task automatic test_encoder_output();
        automatic int i;
        automatic logic [ADDR_WIDTH-1:0] read_addr;
        automatic logic [TOKEN_WINDOW-1:0][TOKEN_ID_WIDTH-1:0] token_ids;
        automatic logic [HDC_DIM-1:0] expected_vector;
        automatic logic [31:0] expected_data_32;
        automatic logic [31:0] read_data_32;
        automatic int pass_count = 0;
        automatic int fail_count = 0;
        
        $display("\n=== Test 2: Encoder Output to Input SRAM ===");
        test_count++;
        
        // Step 1: write Token IDs
        write_data = 64'h0008_0007_0006_0005; // token[0]=5, token[1]=6, token[2]=7, token[3]=8
        axi_write(TOKEN_ID_BUF_BASE_ADDRESS, write_data);
        $display("[%0t] Wrote Token ID Buffer: 0x%016h", $time, write_data);
        
        // Extract token IDs
        for (int j = 0; j < TOKEN_WINDOW; j++) begin
            token_ids[j] = write_data[TOKEN_ID_WIDTH*j +: TOKEN_ID_WIDTH];
        end
        
        // Compute the expected encoder output
        expected_vector = compute_encoder_output(token_ids);
        $display("  Computed expected encoder vector (first 64 bits): 0x%016h", expected_vector[63:0]);
        
        // Step 2: configure CSR (history_id=0)
        // CSR format: same as above, encoder_power_mode=POWER_WORK, history_id=0
        write_data = 64'h00000005;
        axi_write(CSR_BASE_ADDRESS, write_data);
        $display("[%0t] Started encoder with history_id=0", $time);
        
        // Step 3: wait for the encoder to finish
        wait_encoder_finish();
        
        // Step 4: read back the data written by the encoder and compare
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
        for (i = 0; i < (NUM_ACCESS/2); i++) begin  // encoder_cnt from 0 to (NUM_ACCESS/2)-1
            automatic int encoder_addr = (i / 3);   // Every 3 encoder_cnt values correspond to one weight_sram address
            automatic int part_idx = (i % 3);       // Determine which part (0, 1, 2)
            automatic logic [63:0] expected_64bit;
            
            // CPU address computation: addr_offset = (weight_sram_internal_addr << 5) | (part_idx << 3)
            // where weight_sram_internal_addr = HISTORY_BASE_ADDRESS[0] + encoder_addr
            // CPU address = INPUT_SRAM_BASE_ADDRESS + ((HISTORY_BASE_ADDRESS[0] + encoder_addr) << 5) + (part_idx << 3)
            read_addr = INPUT_SRAM_BASE_ADDRESS + ((HISTORY_BASE_ADDRESS[0] + encoder_addr) << 5) + (part_idx << 3);
            axi_read(read_addr, read_data);
            
            // The encoder writes 64-bit data taken from encoder_o_buffer_q[64*encoder_cnt_q +: 64]
            // encoder_cnt_q = i, so the data is at expected_vector[64*i +: 64]
            expected_64bit = expected_vector[64*i +: 64];
            
            // Compare the 64-bit data read back
            if (read_data == expected_64bit) begin
                pass_count++;
                if (i < 12 || (i % 32 == 0)) begin  // Show progress for the first 12 and every 32nd
                    $display("  [%0d] PASS: Encoder output encoder_cnt[%0d] addr[%0d] part[%0d] (addr=0x%016h): 0x%016h", 
                             i, i, encoder_addr, part_idx, read_addr, expected_64bit);
                end
            end else begin
                fail_count++;
                error_count++;
                $error("  [%0d] FAIL: Encoder output encoder_cnt[%0d] addr[%0d] part[%0d] (addr=0x%016h): Expected=0x%016h, Got=0x%016h", 
                       i, i, encoder_addr, part_idx, read_addr, expected_64bit, read_data);
            end
        end
        
        $display("  Verification Summary: %0d passed, %0d failed out of %0d encoder writes checked", 
                 pass_count, fail_count, NUM_ACCESS/2);
        if (fail_count == 0) begin
            $display("  PASS: Encoder output verification completed successfully");
        end else begin
            $error("  FAIL: Encoder output verification found %0d errors", fail_count);
        end
    endtask

    // Test: multiple history_id test
    task automatic test_encoder_multiple_history();
    automatic int i;
        automatic int pass_count = 0;
        automatic int fail_count = 0;
        automatic int history;
        automatic logic [ADDR_WIDTH-1:0] read_addr;
        automatic logic [TOKEN_WINDOW-1:0][TOKEN_ID_WIDTH-1:0] token_ids;
        automatic logic [HDC_DIM-1:0] expected_vector;
        automatic logic [31:0] expected_data_32;
        automatic logic [31:0] read_data_32;
        automatic int data_pass_count;
        automatic int data_fail_count;
        
        $display("\n=== Test 3: Encoder with Multiple History IDs ===");
        test_count++;
        
        // Test different history_id values
        for (history = 0; history < 8; history++) begin
            // Step 1: write Token IDs
            write_data = 64'h0004_0003_0002_0001 + history;
            axi_write(TOKEN_ID_BUF_BASE_ADDRESS, write_data);
            $display("[%0t] Test history_id=%0d: Wrote Token ID: 0x%016h", $time, history, write_data);
            
            // Extract token IDs
            for (int j = 0; j < TOKEN_WINDOW; j++) begin
                token_ids[j] = write_data[TOKEN_ID_WIDTH*j +: TOKEN_ID_WIDTH];
            end
            
            // Compute the expected encoder output
            expected_vector = compute_encoder_output(token_ids);
            
        // Step 2: configure CSR
        // cmd=CMD_ENCODER(01), encoder_power_mode=POWER_WORK(01), other power_mode=IDLE, history_id=history
        write_data = 64'h00000005 | (history << 10);
            axi_write(CSR_BASE_ADDRESS, write_data);
            $display("[%0t] Started encoder with history_id=%0d, CSR=0x%016h", $time, history, write_data);
            
            // Step 3: wait for the encoder to finish
            wait_encoder_finish();
            
            // Step 4: check status
            axi_read(STATUS_BASE_ADDRESS, read_data);
            if (read_data[1:0] == STATUS_FINISHED) begin
                pass_count++;
                $display("  PASS: Encoder with history_id=%0d completed", history);
            end else begin
                fail_count++;
                error_count++;
                $error("  FAIL: Encoder with history_id=%0d failed. Status: 0x%02h", history, read_data[1:0]);
            end
            
            // Step 5: read back the data written by the encoder and compare
            // Encoder write logic: every 3 encoder_cnt values correspond to one weight_sram address (3 64-bit parts are written)
            // The CPU accesses it through the INPUT_SRAM region: CPU address = (weight_sram_internal_addr) << 3 + part * 8
            $display("  Reading and comparing encoder output from Input SRAM (history_id=%0d)...", history);
            for (i = 0; i < (NUM_ACCESS/2); i++) begin  // encoder_cnt from 0 to (NUM_ACCESS/2)-1
                automatic int encoder_addr = (i / 3);   // Every 3 encoder_cnt values correspond to one weight_sram address
                automatic int part_idx = (i % 3);       // Determine which part (0, 1, 2)
                automatic logic [63:0] expected_64bit;
                
                // CPU address computation: addr_offset = (weight_sram_internal_addr << 5) | (part_idx << 3)
                // where weight_sram_internal_addr = HISTORY_BASE_ADDRESS[history] + encoder_addr
                // CPU address = INPUT_SRAM_BASE_ADDRESS + ((HISTORY_BASE_ADDRESS[history] + encoder_addr) << 5) + (part_idx << 3)
                read_addr = INPUT_SRAM_BASE_ADDRESS + ((HISTORY_BASE_ADDRESS[history] + encoder_addr) << 5) + (part_idx << 3);
                axi_read(read_addr, read_data);
                
                // The encoder writes 64-bit data
                expected_64bit = expected_vector[64*i +: 64];
                
                // Compare the 64-bit data read back
                if (read_data == expected_64bit) begin
                    data_pass_count++;
                    if (i < 12 || (i % 32 == 0)) begin
                        $display("  [history_id=%0d][%0d] PASS: encoder_cnt[%0d] addr[%0d] part[%0d] = 0x%016h", 
                                 history, i, i, encoder_addr, part_idx, expected_64bit);
                    end
                end else begin
                    data_fail_count++;
                    error_count++;
                    $error("  [history_id=%0d][%0d] FAIL: encoder_cnt[%0d] addr[%0d] part[%0d]: Expected=0x%016h, Got=0x%016h", 
                           history, i, i, encoder_addr, part_idx, expected_64bit, read_data);
                end
            end
            
            // Wait a few cycles before testing the next one
            repeat(10) @(posedge clk_i);
        end
        
        $display("  Test Summary: %0d status checks passed, %0d status checks failed", pass_count, fail_count);
        $display("  Data Verification Summary: %0d passed, %0d failed out of %0d encoder writes checked across %0d history IDs", 
                 data_pass_count, data_fail_count, (NUM_ACCESS/2) * 8, 8);
        if (data_fail_count == 0 && fail_count == 0) begin
            $display("  PASS: All encoder tests completed successfully");
        end else begin
            $error("  FAIL: Encoder tests found %0d errors", data_fail_count + fail_count);
        end
    endtask


    // Main test sequence
    initial begin
        $display("\n========================================");
        $display("  spec_prefill_unit Encoder FSM Testbench");
        $display("========================================\n");
        
        // Initialization
        rstn_i = 1'b0;
        req_i = 1'b0;
        we_i = 1'b0;
        addr_i = '0;
        data_i = '0;
        be_i = 1'b0;
        rtsel_i = 2'b00;
        wtsel_i = 2'b00;
        test_count = 0;
        error_count = 0;
        
        // Reset
        #4;
        rstn_i = 1'b1;
        #4;
        
        $display("[%0t] Starting encoder FSM tests...\n", $time);
        
        // Run tests
        test_encoder_multiple_history();
        #4;
         test_encoder_power_test();
        #4;       
        
        // Test summary
        $display("\n========================================");
        $display("  Test Summary");
        $display("========================================");
        $display("  Total tests:  %0d", test_count);
        $display("  Errors:        %0d", error_count);
        if (error_count == 0) begin
            $display("  Result:        ALL TESTS PASSED!");
        end else begin
            $display("  Result:        SOME TESTS FAILED");
        end
        $display("========================================\n");
        
        #4;
        $finish;
    end

endmodule

