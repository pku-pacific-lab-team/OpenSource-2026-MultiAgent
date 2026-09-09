// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Description: Self-checking regression of the DCO configuration and
//              clock-gating register block (byte strobes, read-back, invalid
//              offsets, asynchronous reset).

`timescale 1ns/1ps
`include "reg/typedef.svh"
module dco_regs_tb;
  logic clk_i=0,rstn_i=0;
  `REG_BUS_TYPEDEF_ALL(test_reg,logic[63:0],logic[63:0],logic[7:0])
  test_reg_req_t req_i='0;
  test_reg_rsp_t rsp_o;
  logic[5:0] cc_sel_o,fc_sel_o;
  logic[2:0] div_sel_o;
  logic[1:0] freq_sel_o;
  logic[31:0] int_core_clk_en_o;
  logic[7:0] fp_core_clk_en_o;
  logic sp_core_clk_en_o,aux_slot_clk_en_o;
  dco_regs #(.reg_req_t(test_reg_req_t),.reg_rsp_t(test_reg_rsp_t)) dut(.*);
  always #5 clk_i=~clk_i;
  localparam int NumRegs=5;
  logic[63:0] expected[NumRegs],mask[NumRegs];
  int checks=0,writes=0;
  task automatic eq(input logic[63:0] actual,want,input string label);
    if(actual!==want)$fatal(1,"[FAIL] %s actual=%h expected=%h",label,actual,want);
    checks++;
  endtask
  task automatic check_outputs;
    eq(cc_sel_o,expected[0],"CC");eq(fc_sel_o,expected[1],"FC");
    eq(div_sel_o,expected[2],"DIV");eq(freq_sel_o,expected[3],"FREQ");
    eq(int_core_clk_en_o,expected[4][31:0],"INT enable");
    eq(fp_core_clk_en_o,expected[4][39:32],"FP enable");
    eq(sp_core_clk_en_o,expected[4][40],"SP enable");
    eq(aux_slot_clk_en_o,expected[4][44],"auxiliary slot enable");
  endtask
  task automatic init_expected;
    expected[0]=63;expected[1]=63;expected[2]=4;expected[3]=3;
    expected[4]=0;
  endtask
  task automatic wr(input int reg_id,input logic[63:0] data,input logic[7:0] strobes,input logic[63:0] base=0);
    logic[63:0] byte_mask;
    byte_mask=0;for(int k=0;k<8;k++)if(strobes[k])byte_mask|=64'hff<<(8*k);
    @(negedge clk_i);req_i='{addr:base+64'(8*reg_id),write:1,valid:1,wdata:data,wstrb:strobes};
    #1;eq(rsp_o.ready,1,"write ready");eq(rsp_o.error,0,"write error");
    @(posedge clk_i);#1;
    expected[reg_id]=((expected[reg_id]&~byte_mask)|(data&byte_mask))&mask[reg_id];
    check_outputs();writes++;
  endtask
  task automatic rd(input int reg_id,input logic[63:0] base=0);
    @(negedge clk_i);req_i='{addr:base+64'(8*reg_id),write:0,valid:1,wdata:'1,wstrb:0};
    #1;eq(rsp_o.ready,1,"read ready");eq(rsp_o.error,0,"read error");eq(rsp_o.rdata,expected[reg_id],"readback/unused bits");
  endtask
  initial begin
    mask[0]='h3f;mask[1]='h3f;mask[2]=7;mask[3]=3;
    mask[4]=64'hffffffff|(64'hff<<32)|(64'h1<<40)|(64'h1<<44);
    init_expected();repeat(3)@(negedge clk_i);rstn_i=1;#1;check_outputs();
    for(int r=0;r<NumRegs;r++)rd(r);
    // Zero strobe must not change even the reset defaults (negative test on the old RTL).
    for(int r=0;r<NumRegs;r++)begin wr(r,~expected[r],0);rd(r);end
    for(int r=0;r<NumRegs;r++)begin
      for(int pattern=0;pattern<4;pattern++)begin
        for(int st=0;st<256;st++)begin
          logic[63:0] data;
          data=pattern==0 ? 0 : pattern==1 ? '1 : pattern==2 ? 64'ha55a0123fedccafe : {32'($urandom),32'($urandom)};
          wr(r,data,8'(st));rd(r);
        end
      end
      $display("[PASS] register offset=%h: all 256 strobes x 4 patterns",8*r);
    end
    // Consecutive requests without idle cycles; distinct bytes in the clock-enable word.
    wr(4,0,255);wr(4,64'h11ff89abcdef,255);
    wr(4,0,1);wr(4,0,16);wr(4,0,32);rd(4);
    // Upper address bits do not change the existing local 4KiB decode.
    for(int die=0;die<4;die++)begin wr(4,64'(die)<<32,255,(64'(die)<<32)+'h20000000);rd(4);end
    // valid=0 and invalid local offsets must not cause side effects.
    // Offset 0x28 (the former sensor register of the die) is unimplemented in this release.
    @(negedge clk_i);req_i='{addr:'h20,write:1,valid:0,wdata:'1,wstrb:'1};
    repeat(3)@(posedge clk_i);#1;check_outputs();eq(rsp_o.error,0,"idle error");
    for(int c=0;c<6;c++)begin
      logic[63:0] addr;
      addr=c==0?1:c==1?7:c==2?'h28:c==3?'h30:c==4?'hff8:'hfff;
      for(int we=0;we<2;we++)begin
        @(negedge clk_i);req_i='{addr:addr,write:1'(we),valid:1,wdata:'1,wstrb:'1};
        #1;eq(rsp_o.ready,1,"invalid ready");eq(rsp_o.error,1,"invalid error");
        @(posedge clk_i);#1;check_outputs();
      end
    end
    // Asynchronous reset while a write is present; reset wins until released.
    @(negedge clk_i);req_i='{addr:'h20,write:1,valid:1,wdata:'1,wstrb:'1};rstn_i=0;
    init_expected();#1;check_outputs();repeat(2)@(posedge clk_i);#1;check_outputs();
    @(negedge clk_i);req_i='0;rstn_i=1;for(int r=0;r<NumRegs;r++)rd(r);
    $display("[PASS] DCO register regression writes=%0d checks=%0d seed=97282",writes,checks);$finish;
  end
  initial begin #1000000;$fatal(1,"[FAIL] DCO register timeout");end
endmodule
