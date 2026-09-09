//////////////////////////////////////////////////////////////////////////////////
// Description: Top-Level Module of AXI Last-Level Cache w/ Register Config
// Author:      Siyuan He [Peking University]
// Acknowledge: Cursor Agent
//////////////////////////////////////////////////////////////////////////////////
//
// Modified by the PKU_2602 project team (School of Integrated Circuits, Peking University), last changed 2025-12-28:
// adapted for the PKU_2602 SoC integration (1146 differing lines against the upstream version; see the file inventory in THIRD_PARTY.md at the repository root).
// Upstream: axi_llc (https://github.com/pulp-platform/axi_llc), src/axi_llc_top.sv at tag v0.2.2

`include "axi/typedef.svh"
`include "axi/assign.svh"
`include "reg/typedef.svh"
`include "reg/assign.svh"

module axi_llc_top #(
  /// Set Associativity of the LLC
  parameter int unsigned SetAssociativity   = 32'd8,
  /// Number of cache lines of the LLC
  parameter int unsigned NumLines           = 32'd256,
  /// Number of Blocks per cache line
  parameter int unsigned NumBlocks          = 32'd8,
  /// ID width of the Full AXI slave port, master port has ID `AxiIdWidthFull + 32'd1`
  parameter int unsigned AxiIdWidth     = 32'd6,
  /// Address width of the full AXI bus
  parameter int unsigned AxiAddrWidth   = 32'd64,
  /// Data width of the full AXI bus
  parameter int unsigned AxiDataWidth   = 32'd64,
  /// User width of the full AXI bus
  parameter int unsigned AxiUserWidth   = 32'd1
) (
  input logic     clk_i,
  input logic     rst_ni,
  input logic [AxiAddrWidth-1:0] CachedRegionStart,
  input logic [AxiAddrWidth-1:0] CachedRegionLength,
  input logic [AxiAddrWidth-1:0] SpmRegionStart,
  AXI_BUS.Slave   slv,        //cpu-side AXI interface
  AXI_BUS.Master  mst,        //memory-side AXI interface
  REG_BUS.in      conf_intf   //configuration register interface
);

  /////////////////////////////
  // Axi channel definitions //
  /////////////////////////////

  localparam int unsigned AxiStrbWidth = AxiDataWidth / 32'd8;

  typedef logic [AxiIdWidth-1:0]     axi_slv_id_t;
  typedef logic [AxiIdWidth:0]       axi_mst_id_t;
  typedef logic [AxiAddrWidth-1:0]   axi_addr_t;
  typedef logic [AxiDataWidth-1:0]   axi_data_t;
  typedef logic [AxiStrbWidth-1:0]   axi_strb_t;
  typedef logic [AxiUserWidth-1:0]   axi_user_t;

  `AXI_TYPEDEF_AW_CHAN_T(axi_slv_aw_t, axi_addr_t, axi_slv_id_t, axi_user_t)
  `AXI_TYPEDEF_AW_CHAN_T(axi_mst_aw_t, axi_addr_t, axi_mst_id_t, axi_user_t)
  `AXI_TYPEDEF_W_CHAN_T(axi_w_t, axi_data_t, axi_strb_t, axi_user_t)
  `AXI_TYPEDEF_B_CHAN_T(axi_slv_b_t, axi_slv_id_t, axi_user_t)
  `AXI_TYPEDEF_B_CHAN_T(axi_mst_b_t, axi_mst_id_t, axi_user_t)
  `AXI_TYPEDEF_AR_CHAN_T(axi_slv_ar_t, axi_addr_t, axi_slv_id_t, axi_user_t)
  `AXI_TYPEDEF_AR_CHAN_T(axi_mst_ar_t, axi_addr_t, axi_mst_id_t, axi_user_t)
  `AXI_TYPEDEF_R_CHAN_T(axi_slv_r_t, axi_data_t, axi_slv_id_t, axi_user_t)
  `AXI_TYPEDEF_R_CHAN_T(axi_mst_r_t, axi_data_t, axi_mst_id_t, axi_user_t)

  `AXI_TYPEDEF_REQ_T(axi_slv_req_t, axi_slv_aw_t, axi_w_t, axi_slv_ar_t)
  `AXI_TYPEDEF_RESP_T(axi_slv_resp_t, axi_slv_b_t, axi_slv_r_t)
  `AXI_TYPEDEF_REQ_T(axi_mst_req_t, axi_mst_aw_t, axi_w_t, axi_mst_ar_t)
  `AXI_TYPEDEF_RESP_T(axi_mst_resp_t, axi_mst_b_t, axi_mst_r_t)

  `REG_BUS_TYPEDEF_ALL(conf, logic [31:0], logic [31:0], logic [3:0])

  typedef logic [7:0] byte_t;

  // rule definitions
  typedef struct packed {
    int unsigned idx;
    axi_addr_t   start_addr;
    axi_addr_t   end_addr;
  } rule_full_t;

  // Config register addresses
  typedef enum logic [31:0] {
    CfgSpmLow     = 32'h00,
    CfgSpmHigh    = 32'h04,
    CfgFlushLow   = 32'h08,
    CfgFlushHigh  = 32'h0C,
    CommitCfg     = 32'h10,
    CommitPadding = 32'h14,
    FlushedLow    = 32'h18,
    FlushedHigh   = 32'h1C,
    BistOutLow    = 32'h20,
    BistOutHigh   = 32'h24,
    SetAssoLow    = 32'h28,
    SetAssoHigh   = 32'h2C,
    NumLinesLow   = 32'h30,
    NumLinesHigh  = 32'h34,
    NumBlocksLow  = 32'h38,
    NumBlocksHigh = 32'h3C,
    VersionLow    = 32'h40,
    VersionHigh   = 32'h44,
    BistStatus    = 32'h48
  } llc_cfg_addr_e;


  axi_llc_pkg::events_t llc_events;
  // AXI channels
  axi_slv_req_t  axi_cpu_req;
  axi_slv_resp_t axi_cpu_res;
  axi_mst_req_t  axi_mem_req;
  axi_mst_resp_t axi_mem_res;
  conf_req_t     reg_cfg_req;
  conf_rsp_t     reg_cfg_rsp;


  `AXI_ASSIGN_TO_REQ(axi_cpu_req, slv)
  `AXI_ASSIGN_FROM_RESP(slv, axi_cpu_res)

  `AXI_ASSIGN_FROM_REQ(mst, axi_mem_req)
  `AXI_ASSIGN_TO_RESP(axi_mem_res, mst)

  `REG_BUS_ASSIGN_TO_REQ(reg_cfg_req, conf_intf)
  `REG_BUS_ASSIGN_FROM_RSP(conf_intf, reg_cfg_rsp)

  axi_llc_reg_wrap #(
    .SetAssociativity ( SetAssociativity ),
    .NumLines         ( NumLines         ),
    .NumBlocks        ( NumBlocks        ),
    .AxiIdWidth       ( AxiIdWidth       ),
    .AxiAddrWidth     ( AxiAddrWidth     ),
    .AxiDataWidth     ( AxiDataWidth     ),
    .AxiUserWidth     ( AxiUserWidth     ),
    .slv_req_t        ( axi_slv_req_t      ),
    .slv_resp_t       ( axi_slv_resp_t     ),
    .mst_req_t        ( axi_mst_req_t      ),
    .mst_resp_t       ( axi_mst_resp_t     ),
    .reg_req_t        ( conf_req_t         ),
    .reg_resp_t       ( conf_rsp_t         ),
    .rule_full_t      ( rule_full_t        )
  ) i_axi_llc (
    .clk_i               ( clk_i                                  ),
    .rst_ni              ( rst_ni                                 ),
    .test_i              ( 1'b0                                   ),
    .slv_req_i           ( axi_cpu_req                            ),
    .slv_resp_o          ( axi_cpu_res                            ),
    .mst_req_o           ( axi_mem_req                            ),
    .mst_resp_i          ( axi_mem_res                            ),
    .conf_req_i          ( reg_cfg_req                            ),
    .conf_resp_o         ( reg_cfg_rsp                            ),
    .cached_start_addr_i ( CachedRegionStart                      ),
    .cached_end_addr_i   ( CachedRegionStart + CachedRegionLength ),
    .spm_start_addr_i    ( SpmRegionStart                         ),
    .axi_llc_events_o    ( llc_events                             )
  );

endmodule
