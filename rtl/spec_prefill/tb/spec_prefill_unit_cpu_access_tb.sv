// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
//////////////////////////////////////////////////////////////////////////////////
// Description: Testbench for the CPU access function of the spec_prefill_unit module
// Author:      Mingxuan Li <siris-lmx@stu.pku.edu.cn> [Peking University]
// Acknowledge: VSCode Copilot + GPT-5 Agent
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module spec_prefill_unit_cpu_access_tb;

    // Parameter definitions
    localparam int unsigned ADDR_WIDTH  = 64;
    localparam int unsigned DATA_WIDTH  = 64;
    localparam int unsigned HDC_DIM        = 2048;
    localparam int unsigned WEIGHT_WIDTH   = 6;
    localparam int unsigned TOKEN_ID_WIDTH = 16;
    localparam int unsigned RANDOM_WIDTH   = 16;
    localparam int unsigned TOKEN_WINDOW   = 4;

    // Base address definitions
    localparam logic [ADDR_WIDTH-1:0] INPUT_SRAM_BASE_ADDRESS             = 64'h0000000000000000;
    localparam logic [ADDR_WIDTH-1:0] WEIGHT_SRAM_BASE_ADDRESS            = 64'h0000000000001000;
    localparam logic [ADDR_WIDTH-1:0] TOKEN_ID_BUF_BASE_ADDRESS           = 64'h0000000000003000;
    localparam logic [ADDR_WIDTH-1:0] PREDICTOR_O_BUF_BASE_ADDRESS        = 64'h0000000000003008;
    localparam logic [ADDR_WIDTH-1:0] CSR_BASE_ADDRESS                    = 64'h0000000000003010;
    localparam logic [ADDR_WIDTH-1:0] STATUS_BASE_ADDRESS                 = 64'h0000000000003018;

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
        .TOKEN_WINDOW   (TOKEN_WINDOW)
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
    // req_i is asserted for one cycle; data_i is held during this cycle and the following two cycles
    task automatic axi_write(input logic [ADDR_WIDTH-1:0] addr, input logic [DATA_WIDTH-1:0] data);
        @(posedge clk_i);
        req_i <= 1'b1;
        we_i <= 1'b1;
        addr_i <= addr;
        data_i <= data;
        @(posedge clk_i);
        req_i <= 1'b0;
        we_i <= 1'b0;
        // data_i is held for two cycles
        @(posedge clk_i);
    endtask

    // Task: AXI read operation
    // req_i is asserted for one cycle; data_o is sampled in the next cycle
    task automatic axi_read(input logic [ADDR_WIDTH-1:0] addr, output logic [DATA_WIDTH-1:0] data);
        @(posedge clk_i);
        req_i <= 1'b1;
        we_i <= 1'b0;
        addr_i <= addr;
        @(posedge clk_i);
        req_i <= 1'b0;
        @(posedge clk_i); // Sample in the next cycle
        data = data_o;
    endtask

    // Test 1: CPU access - read/write the control/status register
    task automatic test_cpu_access_csr();
        $display("\n=== Test 1: CPU Access - CSR Read/Write ===");
        test_count++;
        
        // Write CSR: set the encoder command, agent_id=0, history_id=0
        write_data = 64'h00000000; // cmd=encoder(00), agent_id=0, history_id=0
        axi_write(CSR_BASE_ADDRESS, write_data);
        $display("[%0t] Wrote CSR: 0x%016h", $time, write_data);
        
        // Read back CSR
        axi_read(CSR_BASE_ADDRESS, read_data);
        $display("[%0t] Read CSR: 0x%016h", $time, read_data);
        
        if (read_data == write_data) begin
            $display("  PASS: CSR read/write match");
        end else begin
            $error("  FAIL: CSR read/write mismatch. Expected: 0x%016h, Got: 0x%016h", write_data, read_data);
            error_count++;
        end
        
        // Write CSR: set the predictor command, agent_id=1, history_id=2
        // CSR format: [8]=reward, [7:5]=history_id, [4:3]=agent_id, [1:0]=cmd
        // cmd=predictor(01), agent_id=1(01), history_id=2(010) -> 0x00000029
        write_data = 64'h00000029; // Bits: [8]=0, [7:5]=010(2), [4:3]=01(1), [1:0]=01
        axi_write(CSR_BASE_ADDRESS, write_data);
        axi_read(CSR_BASE_ADDRESS, read_data);
        $display("[%0t] Wrote CSR: 0x%016h", $time, write_data);
        
        // Read back CSR
        axi_read(CSR_BASE_ADDRESS, read_data);
        $display("[%0t] Read CSR: 0x%016h", $time, read_data);

        if (read_data == write_data) begin
            $display("  PASS: CSR write with agent_id and history_id");
        end else begin
            $error("  FAIL: CSR mismatch. Expected: 0x%016h, Got: 0x%016h", write_data, read_data);
            error_count++;
        end

        // Write CSR: set the encoder command, agent_id=0, history_id=0
        write_data = 64'h00000000; // cmd=encoder(00), agent_id=0, history_id=0
        axi_write(CSR_BASE_ADDRESS, write_data);
        $display("[%0t] Wrote CSR: 0x%016h", $time, write_data);
        
        // Read back CSR
        axi_read(CSR_BASE_ADDRESS, read_data);
        $display("[%0t] Read CSR: 0x%016h", $time, read_data);

    endtask

    // Test 2: CPU access - read/write the input SRAM (test all addresses with random data)
    task automatic test_cpu_access_input_sram();
        // The INPUT_SRAM region maps to weight_sram, address range [0x0000:0x0FFF]
        // CPU address mapping: addr_offset = sp_addr_i - INPUT_SRAM_BASE_ADDRESS
        // weight_sram_cpu_address_i = addr_offset[13:5] (direct mapping, no offset)
        // addr_offset[4:3] selects the 64-bit part of the 192-bit data (0=low 64 bits, 1=middle 64 bits, 2=high 64 bits)
        // Each SRAM address holds 192 bits of data; 3 accesses (part 0, 1, 2) are needed to fill it
        // Addresses are 8-byte aligned (addr_offset[2:0] = 0)
        // 
        // Note: different history_id values use different start addresses (HISTORY_BASE_ADDRESS),
        // when the encoder writes, each history uses about (NUM_ACCESS/2)/3 SRAM addresses
        // HISTORY_BASE_ADDRESS = {84, 72, 60, 48, 36, 24, 12, 0}
        // But the CPU address space is contiguous and maps directly to weight_sram addresses 0-127
        // This test covers all accessible addresses, although some addresses may fall outside the range used by the histories
        // There are 128 SRAM addresses in total, each with 3 parts, giving 384 CPU access addresses
        
        localparam int NUM_SRAM_ADDRS = 128;  // addr_offset[13:5] range 0-127
        localparam int NUM_PARTS = 3;  // Each SRAM address has 3 64-bit parts
        localparam int TOTAL_TESTS = NUM_SRAM_ADDRS * NUM_PARTS;  // 384 access addresses
        
        automatic int pass_count = 0;
        automatic int fail_count = 0;
        
        // Store the written data for verification
        automatic logic [DATA_WIDTH-1:0] write_data_array [0:127][0:2];
        
        $display("\n=== Test 2: CPU Access - Input SRAM Read/Write (All Addresses, Random Data) ===");
        test_count++;
        
        $display("  Testing all %0d Input SRAM addresses (%0d SRAM locations x %0d parts) with random data...", 
                 TOTAL_TESTS, NUM_SRAM_ADDRS, NUM_PARTS);
        $display("  Note: CPU can access all addresses in INPUT_SRAM region (0x0000-0x0FFF),");
        $display("        even though encoder/learner only use specific ranges for different history_id");
        
        // Set the random seed for reproducibility
        $urandom(12345);
        
        // First write all parts of all addresses
        for (int sram_addr = 0; sram_addr < NUM_SRAM_ADDRS; sram_addr++) begin
            for (int part = 0; part < NUM_PARTS; part++) begin
                automatic logic [ADDR_WIDTH-1:0] addr_offset;
                automatic logic [ADDR_WIDTH-1:0] test_addr;
                
                // Compute the address offset: sram_addr in [13:5], part in [4:3]
                // addr_offset[13:5] = sram_addr, addr_offset[4:3] = part, addr_offset[2:0] = 0
                addr_offset = (sram_addr << 5) | (part << 3);
                test_addr = INPUT_SRAM_BASE_ADDRESS + addr_offset;
                
                // Generate random data and store it
                write_data = {$urandom(), $urandom()};
                write_data_array[sram_addr][part] = write_data;
                
                // Write
                axi_write(test_addr, write_data);
            end
        end
        
        // Then read back and verify all parts of all addresses
        for (int sram_addr = 0; sram_addr < NUM_SRAM_ADDRS; sram_addr++) begin
            for (int part = 0; part < NUM_PARTS; part++) begin
                automatic logic [ADDR_WIDTH-1:0] addr_offset;
                automatic logic [ADDR_WIDTH-1:0] test_addr;
                automatic int test_idx = sram_addr * NUM_PARTS + part;
                
                // Compute the address offset
                addr_offset = (sram_addr << 5) | (part << 3);
                test_addr = INPUT_SRAM_BASE_ADDRESS + addr_offset;
                
                // Get the previously written data
                write_data = write_data_array[sram_addr][part];
                
                // Read back
                axi_read(test_addr, read_data);
                
                // Compare
                if (read_data == write_data) begin
                    pass_count++;
                    if (test_idx < 12 || (test_idx % 192 == 0)) begin  // Show progress for the first 12 tests and every 192nd test
                        $display("  [%0d/%0d] PASS: SRAM[%0d] Part[%0d] Addr=0x%016h, Data=0x%016h", 
                                 test_idx+1, TOTAL_TESTS, sram_addr, part, test_addr, write_data);
                    end
                end else begin
                    fail_count++;
                    error_count++;
                    $error("  [%0d/%0d] FAIL: SRAM[%0d] Part[%0d] Addr=0x%016h, Expected=0x%016h, Got=0x%016h", 
                           test_idx+1, TOTAL_TESTS, sram_addr, part, test_addr, write_data, read_data);
                end
            end
        end
        
        $display("  Input SRAM Test Summary: %0d passed, %0d failed out of %0d tests", 
                 pass_count, fail_count, TOTAL_TESTS);
        if (fail_count == 0) begin
            $display("  PASS: All Input SRAM addresses tested successfully");
        end else begin
            $error("  FAIL: %0d Input SRAM tests failed", fail_count);
        end
    endtask

    // Test 3: CPU access - read/write the weight SRAM (test all addresses with random data)
    task automatic test_cpu_access_weight_sram();
        // The weight SRAM is 192 bits wide and is accessed in 3 parts (64 bits each)
        // According to the address map, the WEIGHT_SRAM address range is [WEIGHT_SRAM_BASE_ADDRESS:TOKEN_ID_BUF_BASE_ADDRESS-1], i.e. [0x1000:0x2FFF]
        // CPU address mapping to the weight_sram internal address: addr_offset = sp_addr_i - WEIGHT_SRAM_BASE_ADDRESS
        // weight_sram_cpu_address_i = addr_offset[13:5] + WEIGHT_START_ADDRESS (96)
        // Bits [4:3] of the address offset select the 64-bit part (0=low 64 bits, 1=middle 64 bits, 2=high 64 bits)
        // Each SRAM address corresponds to 3 64-bit parts; address offset [4:3] must match
        // Address offset [4:0] must be a multiple of 8 (8-byte aligned)
        // CPU address range 0x1000-0x2FFF corresponds to weight_sram addresses 96-351
        
        automatic int num_sram_addrs = 256;  // weight_sram_cpu_address_i uses [12:5], 256 addresses in total
        automatic int num_parts = 3;  // Each SRAM address has 3 parts
        automatic int total_tests = num_sram_addrs * num_parts;
        automatic int pass_count = 0;
        automatic int fail_count = 0;
        
        // Store the written data for verification (constants used as array bounds)
        automatic logic [DATA_WIDTH-1:0] write_data_array [0:255][0:2];
        
        $display("\n=== Test 3: CPU Access - Weight SRAM Read/Write (All Addresses, Random Data) ===");
        test_count++;
        
        $display("  Testing all %0d Weight SRAM addresses (%0d SRAM locations x %0d parts) with random data...", 
                 total_tests, num_sram_addrs, num_parts);
        
        // Set the random seed for reproducibility
        $urandom(54321);
        
        // First write all parts of all addresses
        for (int sram_addr = 0; sram_addr < num_sram_addrs; sram_addr++) begin
            for (int part = 0; part < num_parts; part++) begin
                automatic logic [ADDR_WIDTH-1:0] addr_offset;
                automatic logic [ADDR_WIDTH-1:0] test_addr;
                
                // Compute the address offset: sram_addr in [12:5], part in [4:3]
                // addr_offset[12:5] = sram_addr, addr_offset[4:3] = part, addr_offset[2:0] = 0
                addr_offset = (sram_addr << 5) | (part << 3);
                test_addr = WEIGHT_SRAM_BASE_ADDRESS + addr_offset;
                
                // Generate random data and store it
                write_data = {$urandom(), $urandom()};
                write_data_array[sram_addr][part] = write_data;
                
                // Write
                axi_write(test_addr, write_data);
            end
        end
        
        // Then read back and verify all parts of all addresses
        for (int sram_addr = 0; sram_addr < num_sram_addrs; sram_addr++) begin
            for (int part = 0; part < num_parts; part++) begin
                automatic logic [ADDR_WIDTH-1:0] addr_offset;
                automatic logic [ADDR_WIDTH-1:0] test_addr;
                automatic int test_idx = sram_addr * num_parts + part;
                
                // Compute the address offset
                addr_offset = (sram_addr << 5) | (part << 3);
                test_addr = WEIGHT_SRAM_BASE_ADDRESS + addr_offset;
                
                // Get the previously written data
                write_data = write_data_array[sram_addr][part];
                
                // Read back
                axi_read(test_addr, read_data);
                
                // Compare
                if (read_data == write_data) begin
                    pass_count++;
                    if (test_idx < 4 || (test_idx % 192 == 0)) begin  // Show progress for the first 4 tests and every 192nd test
                        $display("  [%0d/%0d] PASS: SRAM[%0d] Part[%0d] Addr=0x%016h, Data=0x%016h", 
                                 test_idx+1, total_tests, sram_addr, part, test_addr, write_data);
                    end
                end else begin
                    fail_count++;
                    error_count++;
                    $error("  [%0d/%0d] FAIL: SRAM[%0d] Part[%0d] Addr=0x%016h, Expected=0x%016h, Got=0x%016h", 
                           test_idx+1, total_tests, sram_addr, part, test_addr, write_data, read_data);
                end
            end
        end
        
        $display("  Weight SRAM Test Summary: %0d passed, %0d failed out of %0d tests", 
                 pass_count, fail_count, total_tests);
        if (fail_count == 0) begin
            $display("  PASS: All Weight SRAM addresses tested successfully");
        end else begin
            $error("  FAIL: %0d Weight SRAM tests failed", fail_count);
        end
    endtask

    // Test 4: CPU access - read/write the Token ID buffer
    task automatic test_cpu_access_token_buffer();
        $display("\n=== Test 4: CPU Access - Token ID Buffer Read/Write ===");
        test_count++;
        
        // Write Token IDs: 4 tokens, 16 bits each
        write_data = 64'h0004_0003_0002_0001; // token[0]=1, token[1]=2, token[2]=3, token[3]=4
        axi_write(TOKEN_ID_BUF_BASE_ADDRESS, write_data);
        $display("[%0t] Wrote Token ID Buffer: 0x%016h", $time, write_data);
        
        // Read back
        axi_read(TOKEN_ID_BUF_BASE_ADDRESS, read_data);
        $display("[%0t] Read Token ID Buffer: 0x%016h", $time, read_data);
        
        if (read_data == write_data) begin
            $display("  PASS: Token ID Buffer read/write match");
        end else begin
            $error("  FAIL: Token ID Buffer mismatch. Expected: 0x%016h, Got: 0x%016h", write_data, read_data);
            error_count++;
        end
    endtask

    // Test 5: CPU access - read the predictor output buffer
    task automatic test_cpu_access_predictor_buffer();
        $display("\n=== Test 5: CPU Access - Predictor Output Buffer Read ===");
        test_count++;
        
        // The predictor output buffer is read-only
        axi_read(PREDICTOR_O_BUF_BASE_ADDRESS, read_data);
        $display("[%0t] Read Predictor Output Buffer: 0x%016h", $time, read_data);
        $display("  INFO: Predictor output buffer read test completed");
    endtask

    // Test 6: CPU access - read the status register
    task automatic test_cpu_access_status();
        $display("\n=== Test 6: CPU Access - Status Register Read ===");
        test_count++;
        
        axi_read(STATUS_BASE_ADDRESS, read_data);
        $display("[%0t] Status Register: 0x%016h", $time, read_data);
        $display("  Encoder status:    %02b", read_data[1:0]);
        $display("  Predictor status:  %02b", read_data[3:2]);
        $display("  Learner status:    %02b", read_data[5:4]);
        $display("  Access status:     %02b", read_data[7:6]);
        $display("  INFO: Status register read test completed");
    endtask

    // Main test sequence
    initial begin
        $display("\n========================================");
        $display("  spec_prefill_unit CPU Access Testbench");
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
        #100;
        rstn_i = 1'b1;
        #100;
        
        $display("[%0t] Starting CPU access tests...\n", $time);
        
        // Run tests
        test_cpu_access_csr();
        #100;
        
        test_cpu_access_input_sram();
        #100;
        
        test_cpu_access_weight_sram();
        #100;
        
        test_cpu_access_token_buffer();
        #100;
        
        test_cpu_access_predictor_buffer();
        #100;
        
        test_cpu_access_status();
        #100;
        
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
        
        #100;
        $finish;
    end

endmodule

