// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
`timescale 1ns/1ps
module adder_fixture #(parameter int N=8)(output bit done=0);
  logic [N-1:0][11:0] data_i;
  logic [11+$clog2(N):0] data_o;
  adder_tree #(.INPUTS_NUM(N),.IDATA_WIDTH(12)) dut(.*);
  initial begin
    int expected,v;
    for(int c=0;c<105;c++)begin
      expected=0;
      for(int i=0;i<N;i++)begin
        v=c==0 ? -2048 : c==1 ? 2047 : c==2 ? -1 : c==3 ? (i%2 ? -2048:2047) : c==4 ? 0 : int'($urandom_range(0,4095))-2048;
        data_i[i]=12'(v);expected+=v;
      end
      #1;
      if(int'($signed(data_o))!=expected)$fatal(1,"[FAIL] adder N=%0d case=%0d got=%0d want=%0d",N,c,$signed(data_o),expected);
    end
    $display("[PASS] adder N=%0d cases=105 extrema/signed/random",N);done=1;
  end
endmodule
module adder_tree_tb;
  bit [4:0] done;
  adder_fixture #(.N(1)) f1(done[0]);
  adder_fixture #(.N(3)) f3(done[1]);
  adder_fixture #(.N(5)) f5(done[2]);
  adder_fixture #(.N(8)) f8(done[3]);
  adder_fixture #(.N(32)) f32(done[4]);
  initial begin wait(&done);$display("[PASS] adder regression 525 cases");$finish;end
endmodule
