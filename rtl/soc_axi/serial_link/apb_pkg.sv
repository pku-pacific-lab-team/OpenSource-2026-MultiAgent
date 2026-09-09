// Copyright (c) 2019 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Modified by the PKU_2602 project team (School of Integrated Circuits, Peking University), last changed 2025-12-25:
// adapted for the PKU_2602 SoC integration (upstream revision not identified by content matching).

// Author: Wolfgang Roenninger <wroennin@ethz.ch>

// Description: Package with constant APB v2.0 constants

package apb_pkg;

  typedef logic [2:0]  prot_t;

  localparam RESP_OKAY   = 1'b0;
  localparam RESP_SLVERR = 1'b1;

endpackage