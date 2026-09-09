// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
`timescale 1ns/1ps
// Reproducible MMIO regression; scalar expected vectors generated outside the DUT.
module tb_fpcore #(parameter int PARALLEL_WIDTH = 8);
  logic clk_i=0, rstn_i=0, req_i=0, we_i=0;
  logic [63:0] addr_i=0,wdata_i=0,rdata_o;
  logic rvalid_o;
  
  always #5 clk_i=~clk_i;
  fp_core #(.PARALLEL_WIDTH(PARALLEL_WIDTH),.AXI_ADDR_WIDTH(64)) dut(.*);
  integer fd,rc,ncases,case_id,mode;
  logic [63:0] input_man[256],input_sf[128],expected[17],got;
  string vectors;
  int checks=0;
  task automatic wr(input logic[63:0] addr,data);
    @(negedge clk_i);req_i=1;we_i=1;addr_i=addr;wdata_i=data;
    @(negedge clk_i);req_i=0;we_i=0;
    begin
      int t=0;
      while(!rvalid_o && t<12)begin @(negedge clk_i);t++;end
      if(!rvalid_o)$fatal(1,"write response timeout");
    end
    @(negedge clk_i);
  endtask
  task automatic rd(input logic[63:0] addr,output logic[63:0] data);
    @(negedge clk_i);req_i=1;we_i=0;addr_i=addr;
    @(negedge clk_i);req_i=0;
    begin
      int t=0;
      while(!rvalid_o && t<12)begin @(negedge clk_i);t++;end
      if(!rvalid_o)$fatal(1,"read response timeout");
    end
    data=rdata_o;
    @(negedge clk_i);
  endtask
  task automatic eq(input logic[63:0] actual,want,input string label);
    if(actual!==want)$fatal(1,"[FAIL] %s actual=%h expected=%h case=%0d",label,actual,want,case_id);
    checks++;
  endtask
  task automatic reset_dut;
    @(negedge clk_i);rstn_i=0;req_i=0;we_i=0;
    repeat(3) @(negedge clk_i);rstn_i=1;
    repeat(2) @(negedge clk_i);
  endtask
  task automatic wait_done;
    int cycles;
    cycles=0;got=0;
    while(!got[2] && cycles<2000)begin rd('hcd0,got);cycles+=3;end
    if(!got[2])$fatal(1,"[FAIL] completion timeout case=%0d",case_id);
    if(got[1]||got[3])$fatal(1,"[FAIL] start/reserved bit not clear");
  endtask
  task automatic check_outputs;
    for(int k=0;k<17;k++)begin rd('hc00+k*8,got);eq(got,expected[k],$sformatf("output[%0d]",k));end
  endtask
  initial begin
    if(!$value$plusargs("vectors=%s",vectors))$fatal(1,"missing +vectors");
    fd=$fopen(vectors,"r");if(!fd)$fatal(1,"cannot open vectors");
    rc=$fscanf(fd,"%d\n",ncases);if(rc!=1)$fatal(1,"bad vector count");
    reset_dut();rd('hcd0,got);eq(got,0,"reset CSR");
    // First/last words of the actual full-word MMIO interface (no byte-enable port).
    for(int region=0;region<2;region++)begin
      for(int edge_id=0;edge_id<2;edge_id++)begin
        logic[63:0] a,e;
        a=region ? (edge_id ? 'hbf8 : 'h800) : (edge_id ? 'h7f8 : 0);
        for(int pattern=0;pattern<4;pattern++)begin
          e=pattern==0 ? 0 : pattern==1 ? '1 : pattern==2 ? 64'h8000000000000001 : 64'hfedcba9876543210;
          wr(a,e);rd(a,got);eq(got,e,"first/last full-word input write");
        end
      end
    end
    wr('hc00,'1);rd('hc00,got);eq(got,0,"read-only output");
    wr('hce0,'1);rd('hce0,got);eq(got,64'hca11ab1ebadcab1e,"unmapped address");
    // Previous CSR bit 3 must be inert; power_mode stays at bit 4.
    wr('hcd0,8);rd('hcd0,got);eq(got,0,"reserved bit write/read");
    for(int c=0;c<ncases;c++)begin
      rc=$fscanf(fd,"%d %d\n",case_id,mode);if(rc!=2)$fatal(1,"bad case header");
      for(int k=0;k<256;k++)begin rc=$fscanf(fd,"%h\n",input_man[k]);if(rc!=1)$fatal;wr(k*8,input_man[k]);end
      for(int k=0;k<128;k++)begin rc=$fscanf(fd,"%h\n",input_sf[k]);if(rc!=1)$fatal;wr('h800+k*8,input_sf[k]);end
      for(int k=0;k<17;k++)begin rc=$fscanf(fd,"%h\n",expected[k]);if(rc!=1)$fatal;end
      wr('hcd0,64'(mode)|2|8); // Deliberately set the reserved control bit on every job.
      wait_done();check_outputs();
      // Back-to-back start without reset: done clears, final output remains correct.
      if(c<4)begin wr('hcd0,64'(mode)|2);wait_done();check_outputs();end
      $display("[PASS] FP case=%0d mode=%0d width=%0d",case_id,mode,PARALLEL_WIDTH);
    end
    $fclose(fd);
    // Calculation registers: signed endpoints, wraparound, and every register/byte lane.
    for(int c=0;c<12;c++)begin
      logic[63:0] words[8];logic signed[31:0] accum;logic[31:0] coeff;
      accum=0;
      for(int k=0;k<8;k++)begin
        words[k]=c==0 ? 64'b0 : c==1 ? '1 : c==2 ? 64'h8000000080000000 : c==3 ? 64'h7fffffff7fffffff : {32'($urandom),32'($urandom)};
        wr('hc88+k*8,words[k]);rd('hc88+k*8,got);eq(got,words[k],"calc reg readback");
        coeff=k%2 ? 256 : 4;accum+=32'(words[k][31:0]*coeff+words[k][63:32]*coeff*2);
      end
      rd('hcc8,got);eq(got,{{32{accum[31]}},accum},"signed calc result modulo 2^32");
    end
    // Power loop on the last vector, then drain to idle. CSR done must stay low while enabled.
    wr('hcd0,64'(mode)|16|8);
    repeat(6)begin
      repeat(300/PARALLEL_WIDTH+15) @(negedge clk_i);
      rd('hcd0,got);if(got[2]||got[3]||!got[4])$fatal(1,"power CSR");
      check_outputs();
    end
    wr('hcd0,64'(mode));wait_done();check_outputs();
    repeat(600/PARALLEL_WIDTH+30) @(negedge clk_i);check_outputs();
    // Reset in-flight, then reuse the core with the zero vector.
    wr('hcd0,2);repeat(2) @(negedge clk_i);reset_dut();
    rd('hcd0,got);eq(got,0,"reset abort CSR");
    for(int k=0;k<17;k++)expected[k]=0;
    wr('hcd0,2);wait_done();check_outputs();
    $display("[PASS] FP regression cases=%0d checks=%0d width=%0d",ncases,checks,PARALLEL_WIDTH);
    $finish;
  end
  initial begin #10000000;$fatal(1,"[FAIL] global timeout");end
endmodule
