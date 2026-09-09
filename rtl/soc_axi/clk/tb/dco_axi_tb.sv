// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
`timescale 1ns/1ps
`include "axi/typedef.svh"
`include "reg/typedef.svh"
module dco_axi_tb #(
  parameter bit CUT_MEM_REQS = 1,
  parameter bit CUT_MEM_RSPS = 1
);
  logic clk=0,rstn=0;
  always #5 clk=~clk;
  typedef logic[63:0] addr_t;
  typedef logic[63:0] data_t;
  typedef logic[63:0] user_t;
  typedef logic[3:0] id_t;
  typedef logic[7:0] strb_t;
  `AXI_TYPEDEF_ALL(bus,addr_t,id_t,data_t,strb_t,user_t)
  `REG_BUS_TYPEDEF_ALL(regbus,addr_t,data_t,strb_t)
  bus_req_t req='0;bus_resp_t rsp;
  regbus_req_t reg_req;regbus_rsp_t reg_rsp;
  axi_to_reg_v2 #(.AxiAddrWidth(64),.AxiDataWidth(64),.AxiIdWidth(4),.AxiUserWidth(64),
    .RegDataWidth(64),.CutMemReqs(CUT_MEM_REQS),.CutMemRsps(CUT_MEM_RSPS),.axi_req_t(bus_req_t),.axi_rsp_t(bus_resp_t),
    .reg_req_t(regbus_req_t),.reg_rsp_t(regbus_rsp_t)) bridge(
    .clk_i(clk),.rst_ni(rstn),.axi_req_i(req),.axi_rsp_o(rsp),.reg_req_o(reg_req),.reg_rsp_i(reg_rsp),.reg_id_o(),.busy_o());
  dco_regs #(.reg_req_t(regbus_req_t),.reg_rsp_t(regbus_rsp_t)) dut(.clk_i(clk),.rstn_i(rstn),.req_i(reg_req),.rsp_o(reg_rsp));
  int reg_writes=0,transactions=0;
  // Positive skew starts AW first; negative skew starts W first.
  int write_skew=0,response_stall=3;
  always @(posedge clk)if(!rstn)reg_writes<=0;else if(reg_req.valid&&reg_req.write&&reg_rsp.ready)reg_writes<=reg_writes+1;
  task automatic axi_write(input logic[63:0] addr,data,input logic[7:0] strobe,input logic[1:0] expected_resp=axi_pkg::RESP_OKAY);
    bit awdone=0,wdone=0;
    int cycle=0;
    @(negedge clk);req.aw='{id:4'd3,addr:addr,len:0,size:3,burst:axi_pkg::BURST_INCR,default:'0};
    req.w='{data:data,strb:strobe,last:1,default:'0};
    req.aw_valid=(write_skew>=0);req.w_valid=(write_skew<=0);
    while(!awdone||!wdone)begin
      @(posedge clk);if(req.aw_valid&&rsp.aw_ready)awdone=1;if(req.w_valid&&rsp.w_ready)wdone=1;
      @(negedge clk);cycle++;
      req.aw_valid=!awdone&&(write_skew>=0||cycle>=-write_skew);
      req.w_valid=!wdone&&(write_skew<=0||cycle>=write_skew);
    end
    while(!rsp.b_valid)@(negedge clk);
    repeat(response_stall+1)begin
      if(!rsp.b_valid||rsp.b.resp!==expected_resp||rsp.b.id!==3)$fatal(1,"AXI B valid=%b id=%h resp=%h expected_resp=%h strobe=%h",rsp.b_valid,rsp.b.id,rsp.b.resp,expected_resp,strobe);
      @(negedge clk);
    end
    req.b_ready=1;@(negedge clk);req.b_ready=0;transactions++;
  endtask
  task automatic axi_read(input logic[63:0] addr,expected,input logic[1:0] expected_resp=axi_pkg::RESP_OKAY);
    @(negedge clk);req.ar='{id:4'd7,addr:addr,len:0,size:3,burst:axi_pkg::BURST_INCR,default:'0};req.ar_valid=1;
    do @(posedge clk);while(!rsp.ar_ready);
    @(negedge clk);req.ar_valid=0;
    while(!rsp.r_valid)@(negedge clk);
    repeat(response_stall+1)begin
      if(!rsp.r_valid||rsp.r.resp!==expected_resp||rsp.r.id!==7||!rsp.r.last||rsp.r.data!==expected)
        $fatal(1,"AXI R actual=%h expected=%h resp=%d",rsp.r.data,expected,rsp.r.resp);
      @(negedge clk);
    end
    req.r_ready=1;@(negedge clk);req.r_ready=0;transactions++;
  endtask
  task automatic burst_four;
    bit awdone=0;
    int sent=0;
    logic [63:0] values[4]='{64'h25,64'h1a,64'h5,64'h2};
    @(negedge clk);
    req.aw='{id:4'd11,addr:64'h20000000,len:3,size:3,burst:axi_pkg::BURST_INCR,default:'0};
    req.aw_valid=1;
    req.w='{data:values[0],strb:8'hff,last:0,default:'0};req.w_valid=1;
    while(!awdone||sent<4)begin
      @(posedge clk);
      if(req.aw_valid&&rsp.aw_ready)awdone=1;
      if(req.w_valid&&rsp.w_ready)sent++;
      @(negedge clk);req.aw_valid=!awdone;req.w_valid=(sent<4);
      if(sent<4)req.w='{data:values[sent],strb:8'hff,last:(sent==3),default:'0};
    end
    while(!rsp.b_valid)@(negedge clk);
    repeat(8)begin
      if(!rsp.b_valid||rsp.b.id!==11||rsp.b.resp!==axi_pkg::RESP_OKAY)$fatal(1,"burst B mismatch");
      @(negedge clk);
    end
    req.b_ready=1;@(negedge clk);req.b_ready=0;transactions++;
    req.ar='{id:4'd13,addr:64'h20000000,len:3,size:3,burst:axi_pkg::BURST_INCR,default:'0};req.ar_valid=1;
    do @(posedge clk);while(!rsp.ar_ready);
    @(negedge clk);req.ar_valid=0;
    for(int beat=0;beat<4;beat++)begin
      while(!rsp.r_valid)@(negedge clk);
      repeat(beat*3+1)begin
        if(!rsp.r_valid||rsp.r.id!==13||rsp.r.resp!==axi_pkg::RESP_OKAY||
           rsp.r.last!==(beat==3)||rsp.r.data!==values[beat])$fatal(1,"burst R beat %0d mismatch: %h",beat,rsp.r.data);
        @(negedge clk);
      end
      req.r_ready=1;@(negedge clk);req.r_ready=0;
    end
    transactions++;
    $display("[PASS] four-beat INCR write/read: address progression, data, IDs, RLAST, per-beat stalls");
  endtask

  task automatic reset_pending_response;
    bit awdone=0,wdone=0;
    @(negedge clk);
    req.aw='{id:4'd9,addr:64'h20000020,len:0,size:3,burst:axi_pkg::BURST_INCR,default:'0};req.aw_valid=1;
    req.w='{data:64'h000011ffffffffff,strb:8'hff,last:1,default:'0};req.w_valid=1;
    while(!awdone||!wdone)begin
      @(posedge clk);if(req.aw_valid&&rsp.aw_ready)awdone=1;if(req.w_valid&&rsp.w_ready)wdone=1;
      @(negedge clk);req.aw_valid=!awdone;req.w_valid=!wdone;
    end
    while(!rsp.b_valid)@(negedge clk);
    if(rsp.b.resp!==axi_pkg::RESP_OKAY||rsp.b.id!==9)$fatal(1,"pre-reset B mismatch");
    rstn=0;req='0;
    repeat(4)@(negedge clk);rstn=1;
    repeat(4)begin
      @(negedge clk);if(rsp.b_valid||rsp.r_valid)$fatal(1,"stale AXI response after reset");
    end
    axi_read('h20000000,63);axi_read('h20000008,63);
    axi_read('h20000010,4);axi_read('h20000018,3);
    axi_read('h20000020,0);
    // Offset 0x28 (the former sensor register of the die) is unimplemented in this release.
    axi_read('h20000028,0,axi_pkg::RESP_SLVERR);
    axi_write('h20000020,'h12345678,255);axi_read('h20000020,'h12345678);
    $display("[PASS] reset with B pending: no stale response, five defaults restored, next transaction succeeds");
  endtask
  initial begin
    logic[63:0] allowed,expected,mask,data;
    logic[7:0] strobes;
    int before_count;
    allowed=64'h000011ffffffffff;
    repeat(3)@(negedge clk);rstn=1;
    for(int c=0;c<12;c++)begin
      axi_write('h20000020,allowed,255);axi_read('h20000020,allowed);
      strobes=c<8 ? 8'(1<<c):c==8 ? 0:c==9 ? 15:c==10 ? 240:255;
      data=c<9 ? 0:64'h000001aa87654321;
      mask=0;for(int k=0;k<8;k++)if(strobes[k])mask|=64'hff<<(8*k);
      expected=((allowed&~mask)|(data&mask))&allowed;
      before_count=reg_writes;
      axi_write('h20000020,data,strobes);axi_read('h20000020,expected);
      if(reg_writes-before_count!=(strobes==0 ? 0:1))$fatal(1,"zero-strobe filter/register handshake count");
      $display("[PASS] AXI partial write strobe=%h preserved=%h",strobes,expected);
    end
    axi_write('h20000030,'1,255,axi_pkg::RESP_SLVERR);
    axi_read('h20000030,0,axi_pkg::RESP_SLVERR);
    for(int order=0;order<3;order++)begin
      write_skew=order==0 ? 0:order==1 ? 5:-7;
      for(int stall=0;stall<3;stall++)begin
        response_stall=stall==0 ? 0:stall==1 ? 7:31;
        data=64'h0000110012345600|64'(order*16+stall);
        axi_write('h20000020,data,255);axi_read('h20000020,data);
        axi_write('h20000020,'1,0);axi_read('h20000020,data);
        axi_write('h20000030,'1,255,axi_pkg::RESP_SLVERR);
        axi_read('h20000030,0,axi_pkg::RESP_SLVERR);
        $display("[PASS] AW/W skew=%0d cycles, additional response stalls=%0d: full/zero strobe and SLVERR",write_skew,response_stall);
      end
    end
    write_skew=0;response_stall=3;
    burst_four();reset_pending_response();
    $display("[PASS] AXI-to-DCO integration transactions=%0d; CutMemReqs=%0d CutMemRsps=%0d",transactions,CUT_MEM_REQS,CUT_MEM_RSPS);
    $finish;
  end
  initial begin #1000000;$fatal(1,"AXI DCO timeout");end
endmodule
