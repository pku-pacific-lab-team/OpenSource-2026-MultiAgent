// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
`timescale 1ns/1ps
module dco_clock_tb;
  logic EN=0,RSTN=0,EXT_CLK=0,CLK_SEL=1;
  logic[5:0] CC_SEL=0,FC_SEL=0;
  logic[2:0] DIV_SEL=0;
  logic[1:0] FREQ_SEL=0;
  wire CLK,CLK_DIV;
  always #5 EXT_CLK=~EXT_CLK;
  DCO dut(.*);
  int cases=0;
  initial begin
    for(int control=0;control<2;control++)begin
      for(int f=0;f<4;f++)begin
        for(int d=0;d<8;d++)begin
          int freq_ratio,div_ratio;
          @(negedge EXT_CLK);RSTN=0;FREQ_SEL=2'(f);DIV_SEL=3'(d);
          CC_SEL=control?63:0;FC_SEL=control?63:0;
          repeat(3)@(negedge EXT_CLK);RSTN=1;
          freq_ratio=f==1?2:f==3?4:1;div_ratio=1<<d;
          repeat(260)@(posedge EXT_CLK);
          fork
            begin
              time start_time;
              @(posedge CLK);start_time=$time;@(posedge CLK);
              if($time-start_time!=10*freq_ratio)$fatal(1,"system divider FREQ=%0d period=%0t",f,$time-start_time);
            end
            begin
              time start_time;
              @(posedge CLK_DIV);start_time=$time;@(posedge CLK_DIV);
              if($time-start_time!=10*div_ratio)$fatal(1,"monitor divider DIV=%0d period=%0t",d,$time-start_time);
            end
          join
          cases++;
        end
      end
    end
    $display("[PASS] actual DCO external-clock divider cases=%0d (FREQ 4 x DIV 8 x CC/FC extrema 2)",cases);
    $display("[LIMIT] Ring oscillator kept disabled; no analog frequency/timing claim.");$finish;
  end
  initial begin #1000000;$fatal(1,"DCO clock timeout");end
endmodule
