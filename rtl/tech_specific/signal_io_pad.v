// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
//////////////////////////////////////////////////////////////////////////////////
// Description:     Behavioural signal I/O pads. The taped-out die uses foundry
//                  bidirectional pad cells with the same ports; this release
//                  replaces them with technology-independent pass-through
//                  models so that the pad-level top can be elaborated and
//                  simulated without a foundry library. Drive-strength,
//                  slew, Schmitt and pull-up/pull-down controls of the real
//                  cells are fixed and are not modelled.
// Author:          Mingxuan Li
// Date:            2026-09 (behavioural release version)
//////////////////////////////////////////////////////////////////////////////////

// Dataflow of the modelled pad:
//   OEN = 0 : output mode, IN drives PAD, OUT is forced to 0
//   OEN = 1 : input mode, PAD is high-impedance from the core, OUT follows PAD
module signal_io_pad_horizontal (
  input  wire  OEN,
  input  wire  IN,
  output wire  OUT,
  inout  wire  PAD
);

  assign PAD = OEN ? 1'bz : IN;
  assign OUT = OEN ? PAD  : 1'b0;

endmodule


module signal_io_pad_vertical (
  input  wire  OEN,
  input  wire  IN,
  output wire  OUT,
  inout  wire  PAD
);

  assign PAD = OEN ? 1'bz : IN;
  assign OUT = OEN ? PAD  : 1'b0;

endmodule

// Retention-enable distribution cells of the pad ring. They carry no logic
// function in the release model.
module retention_cell_horizontal (
  input  wire  rte_i,
  output wire  rte_o
);

  assign rte_o = rte_i;

endmodule

module retention_cell_vertical (
  input  wire  rte_i
);

endmodule
