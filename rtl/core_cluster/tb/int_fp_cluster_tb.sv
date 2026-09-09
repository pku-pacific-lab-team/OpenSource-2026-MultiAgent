// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
`timescale 1ns/1ps
module int_fp_cluster_tb;
  logic clk_i=0,rstn_i=0;
  logic[4:0] clk_en_i='1,mem_req_i=0,mem_write_en_i=0,mem_rvalid_o;
  logic[59:0] mem_addr_i=0;
  logic[319:0] mem_wdata_i=0,mem_rdata_o;
  logic[47:0] dma_length_o,dma_src_offset_o,dma_dst_offset_o;
  logic[3:0] dma_run_o,dma_ready_i=0,dma_busy_i=0;
  always #5 clk_i=~clk_i;
  int_fp_cluster dut(.*);
  int delay_count[4]='{default:0};
  int transfers[4]='{default:0};
  // Separate channels accept each core's DMA; fixed varying completion latency.
  always @(negedge clk_i)begin
    for(int i=0;i<4;i++)begin
      dma_ready_i[i]=0;
      if(!rstn_i)begin dma_busy_i[i]=0;delay_count[i]=0;end
      else if(delay_count[i]>0)begin
        delay_count[i]--;
        if(delay_count[i]==0)dma_busy_i[i]=0;
      end else if(dma_run_o[i] && !dma_busy_i[i])begin
        dma_ready_i[i]=1;dma_busy_i[i]=1;delay_count[i]=20+i*3;transfers[i]++;
      end
    end
  end
  task automatic wr(input int core,input logic[11:0] addr,input logic[63:0] data);
    @(posedge clk_i);#1;mem_req_i[core]=1;mem_write_en_i[core]=1;
    mem_addr_i[core*12+:12]=addr;mem_wdata_i[core*64+:64]=data;
    @(posedge clk_i);#1;mem_req_i[core]=0;mem_write_en_i[core]=0;
    repeat(6)@(posedge clk_i);
  endtask
  task automatic rd(input int core,input logic[11:0] addr,output logic[63:0] data);
    @(posedge clk_i);#1;mem_req_i[core]=1;mem_write_en_i[core]=0;mem_addr_i[core*12+:12]=addr;
    @(posedge clk_i);#1;mem_req_i[core]=0;
    begin
      int n=0;
      while(!mem_rvalid_o[core] && n<12)begin @(posedge clk_i);#1;n++;end
      if(!mem_rvalid_o[core])$fatal(1,"cluster read timeout core=%0d",core);
    end
    data=mem_rdata_o[core*64+:64];
    repeat(4)@(posedge clk_i);
  endtask
  logic[63:0] v;
  initial begin
    repeat(4)@(negedge clk_i);rstn_i=1;
    // Independent first input word on every core, then a write with its clock gated.
    for(int c=0;c<5;c++)begin
      wr(c,0,64'h1234567800000000+c);rd(c,0,v);
      if(v!==64'h1234567800000000+c)$fatal(1,"cluster core isolation %d",c);
      @(negedge clk_i);clk_en_i[c]=0;repeat(3)@(posedge clk_i);
      wr(c,0,'1);@(negedge clk_i);clk_en_i[c]=1;
      repeat(6)@(posedge clk_i);rd(c,0,v);
      if(v!==64'h1234567800000000+c)$fatal(1,"gated write changed state core=%0d",c);
    end
    @(negedge clk_i);rstn_i=0;repeat(4)@(negedge clk_i);rstn_i=1;
    // Four INT cores (PE+SF+SpAttn) and one FP core run concurrently on reset-zero inputs.
    for(int c=0;c<4;c++)wr(c,'hf00,7);
    wr(4,'hcd0,10); // start + reserved control bit; output must use the direct quantized format.
    repeat(3000)@(posedge clk_i);
    for(int c=0;c<4;c++)begin
      rd(c,'hf00,v);if(v[50:48]!==3'b111 || v[55:51]!==0)$fatal(1,"INT status core=%0d value=%h",c,v);
      if(transfers[c]!=9)$fatal(1,"DMA count core=%0d count=%0d expected=9",c,transfers[c]);
      rd(c,'h700,v);if(v!==64'd8192)$fatal(1,"SpAttn zero exponent sum core=%0d val=%h",c,v);
      rd(c,'h800,v);if(v!==64'hca11ab1ebadcab1e)$fatal(1,"reserved window core=%0d",c);
    end
    rd(4,'hcd0,v);if(v[3:1]!==3'b010)$fatal(1,"FP cluster status %h",v);
    for(int k=0;k<17;k++)begin rd(4,12'('hc00+8*k),v);if(v!==0)$fatal(1,"FP cluster output %0d",k);end
    $display("[PASS] cluster: five-core isolation/gating; concurrent 4 INT + FP; 36 DMA completions; result/status/MMIO");
    $finish;
  end
  initial begin #1000000;$fatal(1,"cluster timeout");end
endmodule
