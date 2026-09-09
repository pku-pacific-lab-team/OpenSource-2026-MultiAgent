// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
//////////////////////////////////////////////////////////////////////////////////
// Description:     Behavioural model of the system clock generator (DCO).
//                  The taped-out die contains a ring oscillator built from
//                  foundry standard cells (6 muxed delay stages selected by
//                  CC_SEL, load capacitors selected by FC_SEL), a clock-source
//                  multiplexer, a test divider (DIV_SEL, /1 .. /128) and the
//                  system divider (FREQ_SEL). This release keeps the module
//                  interface and the divider behaviour and replaces the
//                  oscillator by an illustrative simulation-only model. It
//                  makes no claim about the frequency, tuning curve or jitter
//                  of the silicon oscillator. Synthesis targets must drive
//                  the SoC from EXT_CLK (CLK_SEL = 1).
// Author:          Mingxuan Li
// Date:            2026-09 (behavioural release version)
//////////////////////////////////////////////////////////////////////////////////

// The ring-oscillator model below uses delays in nanoseconds.
`timescale 1ns/1ps

// Divide-by-two stage with asynchronous active-low reset (replaces the
// flip-flop based CLK_DIVIDER cell of the die).
module dco_div2 (
  input  wire CLK_IN,
  input  wire FRSTN,
  output wire CLK_OUT
);
  reg q;
  always @(posedge CLK_IN or negedge FRSTN) begin
    if (!FRSTN) q <= 1'b0;
    else        q <= ~q;
  end
  assign CLK_OUT = q;
endmodule

// Test divider: CLK_OUT = CLK_IN / 2**SEL, SEL = 0 .. 7.
module MX_CLK_DIVIDER (
  input  wire       CLK_IN,
  output wire       CLK_OUT,
  input  wire [2:0] SEL,
  input  wire       FRSTN
);
  wire [7:0] stage;
  assign stage[0] = CLK_IN;
  genvar i;
  generate
    for (i = 1; i < 8; i = i + 1) begin : gen_div
      dco_div2 u_div (.CLK_IN(stage[i-1]), .FRSTN(FRSTN), .CLK_OUT(stage[i]));
    end
  endgenerate
  assign CLK_OUT = stage[SEL];
endmodule

// System divider: SEL = 2'b00 -> /1, 2'b01 -> /2, 2'b10 -> /1, 2'b11 -> /4
// (same decoding as the multiplexer tree of the die).
module MX_CLK_DIVIDER_SMALL (
  input  wire       CLK_IN,
  output wire       CLK_OUT,
  input  wire [1:0] SEL,
  input  wire       FRSTN
);
  wire div2, div4, sel_div;
  dco_div2 u_div2 (.CLK_IN(CLK_IN), .FRSTN(FRSTN), .CLK_OUT(div2));
  dco_div2 u_div4 (.CLK_IN(div2),   .FRSTN(FRSTN), .CLK_OUT(div4));
  assign sel_div = SEL[1] ? div4 : div2;
  assign CLK_OUT = SEL[0] ? sel_div : CLK_IN;
endmodule

module DCO (
  input  wire       EN,
  input  wire [5:0] CC_SEL,
  input  wire [5:0] FC_SEL,
  input  wire       EXT_CLK,
  input  wire       CLK_SEL,
  input  wire [2:0] DIV_SEL,
  input  wire [1:0] FREQ_SEL,
  output wire       CLK,
  output wire       CLK_DIV,
  input  wire       RSTN
);

  // ------------------------------------------------------------------
  // Ring oscillator, simulation-only illustrative model.
  // The die selects 1/1/2/4/8/16 buffer delays with CC_SEL[5:0] and adds
  // 1..6 capacitor loads with FC_SEL[5:0]; the model turns these codes into a
  // monotonic half period. The absolute values are placeholders.
  // ------------------------------------------------------------------
  reg ring_clk;
  initial ring_clk = 1'b0;

`ifndef SYNTHESIS
  // half period in ns (time unit of this file: `timescale 1ns/1ps above)
  real half_period_ns;
  integer coarse_units, fine_units;
  always @* begin
    coarse_units = CC_SEL[0] * 1 + CC_SEL[1] * 1 + CC_SEL[2] * 2 + CC_SEL[3] * 4 +
                   CC_SEL[4] * 8 + CC_SEL[5] * 16;
    fine_units   = FC_SEL[0] * 1 + FC_SEL[1] * 2 + FC_SEL[2] * 3 + FC_SEL[3] * 4 +
                   FC_SEL[4] * 5 + FC_SEL[5] * 6;
    half_period_ns = 1.10 + 0.009 * coarse_units + 0.005 * fine_units;
  end

  always begin
    if (EN) begin
      #(half_period_ns) ring_clk = ~ring_clk;
    end else begin
      ring_clk = 1'b0;
      @(posedge EN);
    end
  end
`endif

  // ------------------------------------------------------------------
  // Clock-source multiplexer and dividers (same structure as the die).
  // ------------------------------------------------------------------
  wire clk_select = CLK_SEL ? EXT_CLK : ring_clk;
  wire div_clk_out;
  wire clk_i;

  MX_CLK_DIVIDER       DIVIDER_TEST (.CLK_IN(clk_select), .CLK_OUT(div_clk_out), .SEL(DIV_SEL),  .FRSTN(RSTN));
  MX_CLK_DIVIDER_SMALL DIVIDER_CLK  (.CLK_IN(clk_select), .CLK_OUT(clk_i),       .SEL(FREQ_SEL), .FRSTN(RSTN));

  assign CLK     = clk_i;
  assign CLK_DIV = div_clk_out;

endmodule
