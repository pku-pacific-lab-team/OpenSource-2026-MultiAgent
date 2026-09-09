// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Florian Zaruba, ETH Zurich
// Description: Contains SoC information as constants
package soc_pkg;
  // M-Mode Hart, S-Mode Hart
  localparam int unsigned NumTargets = 2;
  // Uart, SPI, Ethernet, reserved
  localparam int unsigned NumSources = 30;
  localparam int unsigned MaxPriority = 7;

  localparam logic[63:0] DebugLength    = 64'h1000;
  localparam logic[63:0] ROMLength      = 64'h10000;
  localparam logic[63:0] CLINTLength    = 64'hC0000;
  localparam logic[63:0] PLICLength     = 64'h3FF_FFFF;
  localparam logic[63:0] UARTLength     = 64'h1000;
  localparam logic[63:0] TimerLength    = 64'h1000;
  localparam logic[63:0] SysDCOLength   = 64'h1000;
  localparam logic[63:0] SPMLength      = 64'h1000_0000;
  localparam logic[63:0] DRAMLength     = 64'h1000_0000;

  typedef enum logic [63:0] {
    DebugBase_00    = 64'h0_0000_0000,
    DebugBase_01    = 64'h1_0000_0000,
    DebugBase_10    = 64'h2_0000_0000,
    DebugBase_11    = 64'h3_0000_0000,

    ROMBase_00      = 64'h0_0001_0000,
    ROMBase_01      = 64'h1_0001_0000,
    ROMBase_10      = 64'h2_0001_0000,
    ROMBase_11      = 64'h3_0001_0000,

    CLINTBase_00    = 64'h0_0200_0000,
    CLINTBase_01    = 64'h1_0200_0000,
    CLINTBase_10    = 64'h2_0200_0000,
    CLINTBase_11    = 64'h3_0200_0000,

    PLICBase_00     = 64'h0_0C00_0000,
    PLICBase_01     = 64'h1_0C00_0000,
    PLICBase_10     = 64'h2_0C00_0000,
    PLICBase_11     = 64'h3_0C00_0000,

    UARTBase_00     = 64'h0_1000_0000,
    UARTBase_01     = 64'h1_1000_0000,
    UARTBase_10     = 64'h2_1000_0000,
    UARTBase_11     = 64'h3_1000_0000,

    TimerBase_00    = 64'h0_1800_0000,
    TimerBase_01    = 64'h1_1800_0000,
    TimerBase_10    = 64'h2_1800_0000,
    TimerBase_11    = 64'h3_1800_0000,

    SysDCOBase_00   = 64'h0_2000_0000,
    SysDCOBase_01   = 64'h1_2000_0000,
    SysDCOBase_10   = 64'h2_2000_0000,
    SysDCOBase_11   = 64'h3_2000_0000,

    NPUBase_00      = 64'h0_3000_0000,
    NPUBase_01      = 64'h1_3000_0000,
    NPUBase_10      = 64'h2_3000_0000,
    NPUBase_11      = 64'h3_3000_0000,

    SPMBase_00      = 64'h0_8000_0000,
    SPMBase_01      = 64'h1_8000_0000,
    SPMBase_10      = 64'h2_8000_0000,
    SPMBase_11      = 64'h3_8000_0000,

    DRAMBase_00     = 64'h0_9000_0000,
    DRAMBase_01     = 64'h1_9000_0000,
    DRAMBase_10     = 64'h2_9000_0000,
    DRAMBase_11     = 64'h3_9000_0000
  } soc_bus_start_t;

endpackage
