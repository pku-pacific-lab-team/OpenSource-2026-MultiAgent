// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
//////////////////////////////////////////////////////////////////////////////////
// Description: Agent-based Weight Learner Module
// Author:      Siyuan He [Peking University]
// Acknowledge: Cursor Agent
//////////////////////////////////////////////////////////////////////////////////

module learner #(
    parameter int unsigned NUM_INPUT = 32,
    parameter int unsigned WEIGHT_WIDTH = 6
)(
    input  logic                                        en_i,
    input  logic                                        reward_i,
    input  logic [NUM_INPUT-1:0]                        hdc_input_i,
    input  logic [NUM_INPUT*WEIGHT_WIDTH-1:0]           weight_input_i,
    output logic [NUM_INPUT*WEIGHT_WIDTH-1:0]           updated_weight
);
    logic signed [1:0] reward, rewardn;
    logic signed [NUM_INPUT-1:0][1:0] feedback;
    logic signed [NUM_INPUT-1:0][WEIGHT_WIDTH-1:0] weight_in;
    logic signed [NUM_INPUT-1:0][WEIGHT_WIDTH-1:0] weight_out;

    assign reward  = reward_i ?  1 : -1;
    assign rewardn = reward_i ? -1 : 1;
    genvar i;
    generate
        for (i = 0; i < NUM_INPUT; i++) begin: update_
            assign feedback[i] = (hdc_input_i[i] == weight_input_i[i*WEIGHT_WIDTH + WEIGHT_WIDTH - 1]) ? reward : rewardn;
            assign weight_in[i] = weight_input_i[i*WEIGHT_WIDTH +: WEIGHT_WIDTH];
            assign weight_out[i] = $signed(weight_in[i]) + $signed(feedback[i]);
            assign updated_weight[i*WEIGHT_WIDTH +: WEIGHT_WIDTH] = en_i ? weight_out[i] : '0;
        end
    endgenerate

endmodule