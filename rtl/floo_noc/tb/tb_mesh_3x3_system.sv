// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Tim Fischer <fischeti@iis.ee.ethz.ch>
//
// Modified by the PKU_2602 project team (School of Integrated Circuits, Peking University), last changed 2025-12-23:
// adapted for the PKU_2602 SoC integration (upstream revision not identified by content matching).

`include "axi/typedef.svh"
`include "floo_noc/typedef.svh"

module tb_mesh_3x3_system;

  import floo_pkg::*;
  import floo_mesh_3x3_system_noc_pkg::*;

  localparam time CyclTime = 10ns;
  localparam time ApplTime = 2ns;
  localparam time TestTime = 8ns;

  localparam int unsigned NumX = 3;
  localparam int unsigned NumY = 3;
  localparam int unsigned NumHBMChannels = NumY;
  localparam int unsigned NumMax = (NumX > NumY) ? NumX : NumY;

  // Add a buffer before the AXI monitors. Otherwise transactions
  // are stalled which skews the latency measurements
  localparam int unsigned FifoDepth = 100;

  // typedef bus_mgr_addr_t addr_t;

  logic clk, rst_n;
  logic [NumX-1:0][NumY-1:0] end_of_sim;

  clk_rst_gen #(
    .ClkPeriod    ( CyclTime ),
    .RstClkCycles ( 5        )
  ) i_clk_gen (
    .clk_o  ( clk   ),
    .rst_no ( rst_n )
  );

  /////////////////////
  //   Axi Signals   //
  /////////////////////

  bus_mgr_req_t  [NumX-1:0][NumY-1:0] cluster_in_req;
  bus_mgr_rsp_t  [NumX-1:0][NumY-1:0] cluster_in_rsp;
  bus_sbr_req_t [NumX-1:0][NumY-1:0] cluster_out_req;
  bus_sbr_rsp_t [NumX-1:0][NumY-1:0] cluster_out_rsp;

  bus_mgr_req_t [NumX-1:0][NumY-1:0] cluster_in_buf_req;
  bus_mgr_rsp_t [NumX-1:0][NumY-1:0] cluster_in_buf_rsp;


  ////////////////////////
  //   DMA Model Mesh   //
  ////////////////////////

  for (genvar x = 0; x < NumX; x++) begin : gen_x
    for (genvar y = 0; y < NumY; y++) begin : gen_y
      localparam string DmaName = $sformatf("dma_%0d_%0d", x, y);

      localparam int unsigned Index = x * NumY + y;
      localparam logic [31:0] MemBaseAddr = Sam[ClusterX0Y0+Index].start_addr;

      floo_dma_test_node #(
        .TA             ( ApplTime                                  ),
        .TT             ( TestTime                                  ),
        .AxiCfg         ( axi_cfg_swap_iw(AxiCfg)                   ),
        .MemBaseAddr    ( MemBaseAddr                               ),
        .MemSize        ( 32'h100000                                ),
        .NumAxInFlight  ( 2*floo_test_pkg::ChimneyCfg.MaxTxnsPerId  ),
        .axi_in_req_t   ( bus_sbr_req_t                             ),
        .axi_in_rsp_t   ( bus_sbr_rsp_t                             ),
        .axi_out_req_t  ( bus_mgr_req_t                              ),
        .axi_out_rsp_t  ( bus_mgr_rsp_t                              ),
        .JobId          ( Index                                     )
      ) i_dma_node (
        .clk_i          ( clk                   ),
        .rst_ni         ( rst_n                 ),
        .axi_in_req_i   ( cluster_out_req[x][y] ),
        .axi_in_rsp_o   ( cluster_out_rsp[x][y] ),
        .axi_out_req_o  ( cluster_in_req[x][y]  ),
        .axi_out_rsp_i  ( cluster_in_rsp[x][y]  ),
        .end_of_sim_o   ( end_of_sim[x][y]      )
      );

      axi_fifo #(
        .Depth        ( FifoDepth         ),
        .FallThrough  ( 1'b1              ),
        .aw_chan_t    ( bus_mgr_aw_chan_t  ),
        .w_chan_t     ( bus_mgr_w_chan_t   ),
        .b_chan_t     ( bus_mgr_b_chan_t   ),
        .ar_chan_t    ( bus_mgr_ar_chan_t  ),
        .r_chan_t     ( bus_mgr_r_chan_t   ),
        .axi_req_t    ( bus_mgr_req_t      ),
        .axi_resp_t   ( bus_mgr_rsp_t      )
      ) i_axi_narrow_buffer (
        .clk_i      ( clk                      ),
        .rst_ni     ( rst_n                    ),
        .test_i     ( 1'b0                     ),
        .slv_req_i  ( cluster_in_req[x][y]     ),
        .slv_resp_o ( cluster_in_rsp[x][y]     ),
        .mst_req_o  ( cluster_in_buf_req[x][y] ),
        .mst_resp_i ( cluster_in_buf_rsp[x][y] )
      );

      axi_bw_monitor #(
        .req_t      ( bus_mgr_req_t      ),
        .rsp_t      ( bus_mgr_rsp_t      ),
        .AxiIdWidth ( AxiCfg.InIdWidth  ),
        .Name       ( DmaName           )
      ) i_axi_bw_monitor (
        .clk_i          ( clk                   ),
        .en_i           ( rst_n                 ),
        .end_of_sim_i   ( end_of_sim[x][y]      ),
        .req_i          ( cluster_in_req[x][y]  ),
        .rsp_i          ( cluster_in_rsp[x][y]  ),
        .ar_in_flight_o (                       ),
        .aw_in_flight_o (                       )
        );
    end
  end


  /////////////////////////
  //   Network-on-Chip   //
  /////////////////////////

  floo_mesh_3x3_system_noc i_floo_axi_mesh_noc (
    .clk_i                  ( clk                 ),
    .rst_ni                 ( rst_n               ),
    .test_enable_i          ( 1'b0                ),
    .cluster_bus_mgr_req_i   ( cluster_in_buf_req  ),
    .cluster_bus_mgr_rsp_o   ( cluster_in_buf_rsp  ),
    .cluster_bus_sbr_req_o  ( cluster_out_req     ),
    .cluster_bus_sbr_rsp_i  ( cluster_out_rsp     )
  );


  initial begin
    wait(&end_of_sim);
    // Wait for some time
    repeat (2) @(posedge clk);
    // Stop the simulation
    $stop;
  end

endmodule
