// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
//---------------------------------------------------------------------------------------------
// adder_tree.sv
// Konstantin Pavlov, pavlovconst@gmail.com
//---------------------------------------------------------------------------------------------

// INFO ---------------------------------------------------------------------------------------
// Signed tree adder with parametrized input width written in System Verilog
//
// - Number of inputs is NOT required to be power of two
// - This code can generate entirely combinational/pipelined circuit with minimal editing
//

// Modified by Mingxuan Li <siris-lmx@stu.pku.edu.cn> [Peking University]

module adder_tree #(
  parameter INPUTS_NUM      = 32                        ,
  parameter IDATA_WIDTH     = 16                        ,

  // derived parameters, DO NOT MODIFY!!!
  parameter STAGES_NUM      = $clog2(INPUTS_NUM)        ,
  parameter INPUTS_NUM_INT  = 2 ** STAGES_NUM           ,
  parameter ODATA_WIDTH     = IDATA_WIDTH + STAGES_NUM
)(
  input   logic [INPUTS_NUM-1:0][IDATA_WIDTH-1:0] data_i,
  output  logic [ODATA_WIDTH-1:0]                 data_o
);

  // Each stage owns distinct nets and each node has a single continuous driver.
  // Sign extension adds one bit per stage, preserving the full signed sum.
  for (genvar stage = 0; stage <= STAGES_NUM; stage++) begin : stage_gen
    localparam ST_OUT_NUM = INPUTS_NUM_INT >> stage;
    localparam ST_WIDTH = IDATA_WIDTH + stage;
    wire signed [ST_WIDTH-1:0] node [ST_OUT_NUM];
    for (genvar adder = 0; adder < ST_OUT_NUM; adder++) begin : node_gen
      if (stage == 0) begin : input_node
        if (adder < INPUTS_NUM) begin : valid_input
          assign node[adder] = $signed(data_i[adder]);
        end else begin : padding
          assign node[adder] = '0;
        end
      end else begin : sum_node
        assign node[adder] =
          $signed({stage_gen[stage-1].node[2*adder][ST_WIDTH-2],
                   stage_gen[stage-1].node[2*adder]}) +
          $signed({stage_gen[stage-1].node[2*adder+1][ST_WIDTH-2],
                   stage_gen[stage-1].node[2*adder+1]});
      end
    end
  end
  assign data_o = stage_gen[STAGES_NUM].node[0];
endmodule
