// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
`timescale 1ns/1ps
module sum_reduce_tb;
  logic clk_i=0,rstn_i=0,reduce_valid_i=0;
  logic[7:0][7:0][11:0] array_i='0;
  logic[17:0] sum_o;
  logic sum_valid_o;
  always #5 clk_i=~clk_i;
  sum_reduce dut(.*);
  always @(negedge clk_i) if($test$plusargs("debug_sum"))
    $display("TRACE arr=%d pulse=%b rvalid=%b qvalid=%b state=%d s0=%d s1=%d s2=%d tree_in=%d tree_out=%d",array_i[0][0],dut.posedge_reduce_valid,reduce_valid_i,dut.reduce_valid_q,dut.state_q,dut.stage0_psum_q[0][0],dut.stage1_psum_q[0],dut.stage2_psum_q,dut.stage0[0].stage1_adder_tree_inst.data_i[0],dut.stage0[0].stage1_adder_tree_inst.data_o);
  initial begin
    int expected,v;
    repeat(3) @(negedge clk_i);rstn_i=1;
    for(int c=0;c<10;c++)begin
      @(negedge clk_i);expected=0;
      for(int i=0;i<8;i++)for(int j=0;j<8;j++)begin
        v=c==0?1:c==1?-1:c==2?2047:c==3?-2048:((i*8+j)*17+c)%4096-2048;
        array_i[i][j]=12'(v);expected+=v;
      end
      reduce_valid_i=1;
      @(negedge clk_i);reduce_valid_i=0;array_i='0;
      repeat(5)@(negedge clk_i);
      if(!sum_valid_o || $signed(sum_o)!=expected)
        $fatal(1,"[FAIL] sum_reduce c=%0d actual=%0d expected=%0d valid=%b",c,$signed(sum_o),expected,sum_valid_o);
      $display("[PASS] sum_reduce c=%0d sum=%0d",c,$signed(sum_o));
    end
    $finish;
  end
  initial begin #10000;$fatal(1,"timeout");end
endmodule
