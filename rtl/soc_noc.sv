// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Description: SOC-NOC top-level
// Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>
// Modified by: Hongou Li [Peking University]
//              Mingxuan Li <siris-lmx@stu.pku.edu.cn> [Peking University]

`include "axi/typedef.svh"
`include "axi/assign.svh"
`include "reg/typedef.svh"
`include "reg/assign.svh"
`include "apb/typedef.svh"
`include "apb/assign.svh"

module soc_noc (
`ifdef SIM
	// Virtual CLK
	input   logic       sys_clk_i           ,
`elsif FPGA
	// Virtual CLK
	input   logic       sys_clk_i           ,
`endif // ifdef SIM

`ifndef FPGA // Don't include PAD for FPGA verification
	// DCO input
	input   logic       ext_clk_i           ,

	// System DCO Control
	input   logic       sys_dco_en_i        ,
	input   logic       sys_clk_sel_i       ,
	output  logic       sys_dco_clk_o       ,
`endif // `ifndef FPGA

	input   logic       rstn_i              ,
  input   logic       boot_sel_i          ,
	input   logic [1:0] soc_id_i            ,
	output  logic       clk_led_o           ,

	// JTAG
	input   logic       jtag_tck_i          ,
	input   logic       jtag_tms_i          ,
	input   logic       jtag_tdi_i          ,
	output  logic       jtag_tdo_o          ,

	// UART
	input   logic       uart_rx_i           ,
	output  logic       uart_tx_o           ,

	// FPGA DRAM Serial Link
	output  logic       sl_clk_tx_o         ,
	output  logic [1:0] sl_data_tx_o        ,
	input   logic       sl_clk_rx_i         ,
	input   logic [1:0] sl_data_rx_i        ,

	// Die-to-Die #0 Interface
	output  logic       d2d0_clk_tx_o       ,
	output  logic [1:0] d2d0_data_tx_o      ,
	input   logic       d2d0_clk_rx_i       ,
	input   logic [1:0] d2d0_data_rx_i      ,

	// Die-to-Die #1 Interface
	output  logic       d2d1_clk_tx_o       ,
	output  logic [1:0] d2d1_data_tx_o      ,
	input   logic       d2d1_clk_rx_i       ,
	input   logic [1:0] d2d1_data_rx_i      
);

  // on-chip clock
  logic clk;

  // CVA6 config
  localparam config_pkg::cva6_cfg_t CVA6Cfg = '{
    AxiDataWidth          : unsigned'(64)                   ,
    AxiAddrWidth          : unsigned'(64)                   ,
    AxiIdWidth            : unsigned'(4)                    ,
    AxiUserWidth          : unsigned'(64)                   ,
    NOCType               : config_pkg::NOC_TYPE_AXI4_ATOP  ,

    NrCommitPorts         : unsigned'(2)                    ,
    NrLoadBufEntries      : unsigned'(2)                    ,
    RASDepth              : unsigned'(2)                    ,
    BTBEntries            : unsigned'(32)                   ,
    BHTEntries            : unsigned'(128)                  ,
    NrRgprPorts           : unsigned'(2)                    ,
    NrWbPorts             : unsigned'(4)                    ,
    NrPMPEntries          : unsigned'(2)                    ,
    MaxOutstandingStores  : unsigned'(7)                    ,

    FpuEn                 : bit'(1)                         ,
    CvxifEn               : bit'(0)                         ,
    EnableAccelerator     : bit'(0)                         ,
    DebugEn               : bit'(1)                         ,
    NonIdemPotenceEn      : bit'(1)                         ,
    AxiBurstWriteEn       : bit'(0)                         ,

    XF16                  : bit'(0)                         ,
    XF16ALT               : bit'(0)                         ,
    XF8                   : bit'(0)                         ,
    RVA                   : bit'(0)                         ,
    RVV                   : bit'(0)                         ,
    RVC                   : bit'(0)                         ,
    RVZCB                 : bit'(0)                         ,
    XFVec                 : bit'(0)                         ,
    ZiCondExtEn           : bit'(1)                         ,
    RVF                   : bit'(1)                         ,
    RVD                   : bit'(1)                         ,
    FpPresent             : bit'(1)                         ,
    NSX                   : bit'(0)                         ,
    FLen                  : unsigned'(64)                    ,
    RVFVec                : bit'(0)                         ,
    XF16Vec               : bit'(0)                         ,
    XF16ALTVec            : bit'(0)                         ,
    XF8Vec                : bit'(0)                         ,
    RVS                   : bit'(1)                         ,
    RVU                   : bit'(1)                         ,

    HaltAddress           : dm::HaltAddress                 ,
    ExceptionAddress      : dm::ExceptionAddress            ,
    NrNonIdempotentRules  : unsigned'(4)                    ,
    // Protect the debug windows on all four dies from speculative loads.
    NonIdempotentAddrBase : 1024'({soc_pkg::DebugBase_11, soc_pkg::DebugBase_10,
                                   soc_pkg::DebugBase_01, soc_pkg::DebugBase_00})                  ,
    NonIdempotentLength   : 1024'({4{soc_pkg::DebugLength}})                  ,
    NrExecuteRegionRules  : unsigned'(1)                    ,
    ExecuteRegionAddrBase : 1024'({64'b0})                  ,
    ExecuteRegionLength   : 1024'({64'b0})                  ,
    // Rule [1] is SPM; rule [0] is DRAM. Runtime bases use the same order.
    NrCachedRegionRules   : unsigned'(2)                    ,
    CachedRegionLength    : 1024'({soc_pkg::SPMLength,
                                   soc_pkg::DRAMLength})    ,

    // following parameters are not used!!!
    DmBaseAddress          : 64'({64'b0})                   ,
    CachedRegionAddrBase   : 1024'({64'b0})
  };

  localparam AxiAddrWidth = CVA6Cfg.AxiAddrWidth        ;
  localparam AxiDataWidth = CVA6Cfg.AxiDataWidth        ;
  localparam AxiIdWidth   = CVA6Cfg.AxiIdWidth          ;
  localparam AxiUserWidth = ariane_pkg::AXI_USER_WIDTH  ;
  localparam AxiUserEn    = ariane_pkg::AXI_USER_EN     ;

  logic test_en                       ;
  logic pll_locked                    ;
  logic ndmreset                      ;
  logic ndmreset_n                    ;
  logic [1:0] irq                     ;
  assign test_en    = 1'b0            ;
  assign pll_locked = rstn_i          ;

  rstgen i_rstgen_main (
    .clk_i        ( clk                      ),
    .rst_ni       ( pll_locked & (~ndmreset) ),
    .test_mode_i  ( test_en                  ),
    .rst_no       ( ndmreset_n               ),
    .init_no      (                          ) // keep open
  );

  import floo_agent_noc_pkg::*;

  sam_rule_t [SamNumRules-1:0]                          Sam                   ;
  logic [AxiAddrWidth-1:0]                              hart_id               ;
  logic [AxiAddrWidth-1:0]                              ROMBase               ;
  logic [AxiAddrWidth-1:0]                              DmBaseAddress         ;
  logic [config_pkg::NrMaxRules-1:0][AxiAddrWidth-1:0]  CachedRegionAddrBase  ;
  logic [AxiAddrWidth-1:0]                              LLCCachedRegionBase   ;
  logic [AxiAddrWidth-1:0]                              LLCSpmRegionBase      ;
  always_comb begin
    Sam                   = '0;
    hart_id               = '0;
    ROMBase               = '0;
    DmBaseAddress         = '0;
    CachedRegionAddrBase  = '0;
    LLCCachedRegionBase   = '0;
    LLCSpmRegionBase      = '0;

    case (soc_id_i)
      2'b00: begin
        Sam                   = Sam_00                          ;
        hart_id               = 64'(0)                          ; // one local hart per die (A7)
        ROMBase               = soc_pkg::ROMBase_00             ;
        DmBaseAddress         = soc_pkg::DebugBase_00           ;
        CachedRegionAddrBase  = 1024'({soc_pkg::SPMBase_00, soc_pkg::DRAMBase_00})    ;
        LLCCachedRegionBase   = soc_pkg::DRAMBase_00            ;
        LLCSpmRegionBase      = soc_pkg::SPMBase_00             ;
      end

      2'b01: begin
        Sam                   = Sam_01                          ;
        hart_id               = 64'(0)                          ; // one local hart per die (A7)
        ROMBase               = soc_pkg::ROMBase_01             ;
        DmBaseAddress         = soc_pkg::DebugBase_01           ;
        CachedRegionAddrBase  = 1024'({soc_pkg::SPMBase_01, soc_pkg::DRAMBase_01})    ;
        LLCCachedRegionBase   = soc_pkg::DRAMBase_01            ;
        LLCSpmRegionBase      = soc_pkg::SPMBase_01             ;
      end

      2'b10: begin
        Sam                   = Sam_10                          ;
        hart_id               = 64'(0)                          ; // one local hart per die (A7)
        ROMBase               = soc_pkg::ROMBase_10             ;
        DmBaseAddress         = soc_pkg::DebugBase_10           ;
        CachedRegionAddrBase  = 1024'({soc_pkg::SPMBase_10, soc_pkg::DRAMBase_10})    ;
        LLCCachedRegionBase   = soc_pkg::DRAMBase_10            ;
        LLCSpmRegionBase      = soc_pkg::SPMBase_10             ;
      end

      2'b11: begin
        Sam                   = Sam_11                          ;
        hart_id               = 64'(0)                          ; // one local hart per die (A7)
        ROMBase               = soc_pkg::ROMBase_11             ;
        DmBaseAddress         = soc_pkg::DebugBase_11           ;
        CachedRegionAddrBase  = 1024'({soc_pkg::SPMBase_11, soc_pkg::DRAMBase_11})    ;
        LLCCachedRegionBase   = soc_pkg::DRAMBase_11            ;
        LLCSpmRegionBase      = soc_pkg::SPMBase_11             ;
      end

      default: ;
    endcase
  end


  // ------------------------------------------------------------
  // Floo NoC
  // ------------------------------------------------------------
  mst_axi_req_t             axi_ariane_req_for_noc          ;
  mst_axi_rsp_t             axi_ariane_resp_from_noc        ;
  mst_axi_req_t             dm_axi_m_req_for_noc            ;
  mst_axi_rsp_t             dm_axi_m_resp_from_noc          ;

  mst_axi_req_t [3:0][7:0]  int_core_master_req_for_noc     ;
  mst_axi_rsp_t [3:0][7:0]  int_core_master_resp_from_noc   ;
  slv_axi_req_t [3:0][7:0]  int_core_slave_req_from_noc     ;
  slv_axi_rsp_t [3:0][7:0]  int_core_slave_resp_for_noc     ;

  slv_axi_rsp_t [7:0]       fp_core_slave_resp_for_noc      ;
  slv_axi_req_t [7:0]       fp_core_slave_req_from_noc      ;

  slv_axi_rsp_t             aux_slot_slave_resp_for_noc       ;
  slv_axi_req_t             aux_slot_slave_req_from_noc       ;

  slv_axi_rsp_t             spec_prefill_slave_resp_for_noc ;
  slv_axi_req_t             spec_prefill_slave_req_from_noc ;

  slv_axi_rsp_t             sl_cfg_slave_resp_for_noc       ;
  slv_axi_req_t             sl_cfg_slave_req_from_noc       ;

  slv_axi_rsp_t             d2d0_cfg_slave_resp_for_noc     ;
  slv_axi_req_t             d2d0_cfg_slave_req_from_noc     ;
  slv_axi_rsp_t             d2d1_cfg_slave_resp_for_noc     ;
  slv_axi_req_t             d2d1_cfg_slave_req_from_noc     ;

  slv_axi_rsp_t             d2d0_slave_resp_for_noc         ;
  slv_axi_req_t             d2d0_slave_req_from_noc         ;
  mst_axi_rsp_t             d2d0_master_resp_from_noc       ;
  mst_axi_req_t             d2d0_master_req_for_noc         ;

  slv_axi_rsp_t             d2d1_slave_resp_for_noc         ;
  slv_axi_req_t             d2d1_slave_req_from_noc         ;
  mst_axi_rsp_t             d2d1_master_resp_from_noc       ;
  mst_axi_req_t             d2d1_master_req_for_noc         ;

  slv_axi_req_t             llc_slave_req_from_noc          ;
  slv_axi_rsp_t             llc_slave_resp_for_noc          ;

  slv_axi_req_t             llc_cfg_slave_req_from_noc      ;
  slv_axi_rsp_t             llc_cfg_slave_resp_for_noc      ;

  slv_axi_req_t             rom_slave_req_from_noc          ;
  slv_axi_rsp_t             rom_slave_resp_for_noc          ;

  slv_axi_req_t             dm_slave_req_from_noc           ;
  slv_axi_rsp_t             dm_slave_resp_for_noc           ;

  slv_axi_req_t             clint_slave_req_from_noc        ;
  slv_axi_rsp_t             clint_slave_resp_for_noc        ;

  slv_axi_req_t             plic_slave_req_from_noc         ;
  slv_axi_rsp_t             plic_slave_resp_for_noc         ;

  slv_axi_req_t             uart_slave_req_from_noc         ;
  slv_axi_rsp_t             uart_slave_resp_for_noc         ;

  slv_axi_req_t             timer_slave_req_from_noc        ;
  slv_axi_rsp_t             timer_slave_resp_for_noc        ;

  slv_axi_req_t             sys_dco_slave_req_from_noc      ;
  slv_axi_rsp_t             sys_dco_slave_resp_for_noc      ;

  floo_agent_noc i_floo_noc (
    .clk_i                          ( clk                           ),
    .rst_ni                         ( ndmreset_n                    ),
    .test_enable_i                  ( test_en                       ),
    .cpu_master_mst_req_i           ( axi_ariane_req_for_noc        ),
    .cpu_master_mst_rsp_o           ( axi_ariane_resp_from_noc      ),
    .dm_master_mst_req_i            ( dm_axi_m_req_for_noc          ),
    .dm_master_mst_rsp_o            ( dm_axi_m_resp_from_noc        ),
    .d2d0_master_mst_req_i          ( d2d0_master_req_for_noc       ),
    .d2d0_master_mst_rsp_o          ( d2d0_master_resp_from_noc     ),
    .d2d1_master_mst_req_i          ( d2d1_master_req_for_noc       ),
    .d2d1_master_mst_rsp_o          ( d2d1_master_resp_from_noc     ),
    .int_core_master_mst_req_i      ( int_core_master_req_for_noc   ),
    .int_core_master_mst_rsp_o      ( int_core_master_resp_from_noc ),
    .llc_slave_slv_req_o            ( llc_slave_req_from_noc        ),
    .llc_slave_slv_rsp_i            ( llc_slave_resp_for_noc        ),
    .rom_slave_slv_req_o            ( rom_slave_req_from_noc        ),
    .rom_slave_slv_rsp_i            ( rom_slave_resp_for_noc        ),
    .dm_slave_slv_req_o             ( dm_slave_req_from_noc         ),
    .dm_slave_slv_rsp_i             ( dm_slave_resp_for_noc         ),
    .clint_slave_slv_req_o          ( clint_slave_req_from_noc      ),
    .clint_slave_slv_rsp_i          ( clint_slave_resp_for_noc      ),
    .plic_slave_slv_req_o           ( plic_slave_req_from_noc       ),
    .plic_slave_slv_rsp_i           ( plic_slave_resp_for_noc       ),
    .uart_slave_slv_req_o           ( uart_slave_req_from_noc       ),
    .uart_slave_slv_rsp_i           ( uart_slave_resp_for_noc       ),
    .timer_slave_slv_req_o          ( timer_slave_req_from_noc      ),
    .timer_slave_slv_rsp_i          ( timer_slave_resp_for_noc      ),
    .sys_dco_slave_slv_req_o        ( sys_dco_slave_req_from_noc    ),
    .sys_dco_slave_slv_rsp_i        ( sys_dco_slave_resp_for_noc    ),
    .sl_cfg_slave_slv_req_o         ( sl_cfg_slave_req_from_noc     ),
    .sl_cfg_slave_slv_rsp_i         ( sl_cfg_slave_resp_for_noc     ),
    .d2d0_cfg_slave_slv_req_o       ( d2d0_cfg_slave_req_from_noc   ),
    .d2d0_cfg_slave_slv_rsp_i       ( d2d0_cfg_slave_resp_for_noc   ),
    .d2d1_cfg_slave_slv_req_o       ( d2d1_cfg_slave_req_from_noc   ),
    .d2d1_cfg_slave_slv_rsp_i       ( d2d1_cfg_slave_resp_for_noc   ),
    .llc_cfg_slave_slv_req_o        ( llc_cfg_slave_req_from_noc    ),
    .llc_cfg_slave_slv_rsp_i        ( llc_cfg_slave_resp_for_noc    ),
    .d2d0_slave_slv_req_o           ( d2d0_slave_req_from_noc       ),
    .d2d0_slave_slv_rsp_i           ( d2d0_slave_resp_for_noc       ),
    .d2d1_slave_slv_req_o           ( d2d1_slave_req_from_noc       ),
    .d2d1_slave_slv_rsp_i           ( d2d1_slave_resp_for_noc       ),
    .int_core_slave_slv_req_o       ( int_core_slave_req_from_noc   ),
    .int_core_slave_slv_rsp_i       ( int_core_slave_resp_for_noc   ),
    .fp_core_slave_slv_req_o        ( fp_core_slave_req_from_noc    ),
    .fp_core_slave_slv_rsp_i        ( fp_core_slave_resp_for_noc    ),
    .sp_slave_slv_req_o             ( spec_prefill_slave_req_from_noc ),
    .sp_slave_slv_rsp_i             ( spec_prefill_slave_resp_for_noc ),
    .aux_slot_slave_slv_req_o         ( aux_slot_slave_req_from_noc     ),
    .aux_slot_slave_slv_rsp_i         ( aux_slot_slave_resp_for_noc     ),
    .sam_map_i                      ( Sam                           )
  );


  // ------------------------------------------------------------
  // INT-FP-Core Cluster
  // ------------------------------------------------------------
  logic              [8-1:0][5-1:0] cluster_clk_en;
  ariane_axi::req_t  [8-1:0][5-1:0] cluster_slv_req;
  ariane_axi::resp_t [8-1:0][5-1:0] cluster_slv_rsp;
  ariane_axi::req_t  [8-1:0][4-1:0] cluster_mst_req;
  ariane_axi::resp_t [8-1:0][4-1:0] cluster_mst_rsp;

  for (genvar i = 0; i < 8; i++) begin: row
    for (genvar j = 0; j < 4; j++) begin: col
      `AXI_ASSIGN_REQ_STRUCT(int_core_master_req_for_noc[j][i], cluster_mst_req[i][j])
      `AXI_ASSIGN_RESP_STRUCT(cluster_mst_rsp[i][j], int_core_master_resp_from_noc[j][i])
      `AXI_ASSIGN_REQ_STRUCT(cluster_slv_req[i][j], int_core_slave_req_from_noc[j][i])
      `AXI_ASSIGN_RESP_STRUCT(int_core_slave_resp_for_noc[j][i], cluster_slv_rsp[i][j])
    end
    `AXI_ASSIGN_REQ_STRUCT(cluster_slv_req[i][4], fp_core_slave_req_from_noc[i])
    `AXI_ASSIGN_RESP_STRUCT(fp_core_slave_resp_for_noc[i], cluster_slv_rsp[i][4])

    cluster_top #(
      .axi_req_t      ( ariane_axi::req_t  ),
      .axi_rsp_t      ( ariane_axi::resp_t )
    ) i_cluster_top (
      .clk_i          ( clk                ),
      .rstn_i         ( ndmreset_n         ),
      .clk_en_i       ( cluster_clk_en[i]  ),
      .slv_axi_req_i  ( cluster_slv_req[i] ),
      .slv_axi_rsp_o  ( cluster_slv_rsp[i] ),
      .mst_axi_req_o  ( cluster_mst_req[i] ),
      .mst_axi_rsp_i  ( cluster_mst_rsp[i] )
    );
  end


  // ------------------------------------------------------------
  // Speculative Prefilling Unit
  // ------------------------------------------------------------
  logic              spec_prefill_clk_en;
  ariane_axi::req_t  spec_prefill_slv_req;
  ariane_axi::resp_t spec_prefill_slv_rsp;

  `AXI_ASSIGN_REQ_STRUCT(spec_prefill_slv_req, spec_prefill_slave_req_from_noc)
  `AXI_ASSIGN_RESP_STRUCT(spec_prefill_slave_resp_for_noc, spec_prefill_slv_rsp)

  spec_prefill_top #(
    .AXI_ADDR_WIDTH ( AxiAddrWidth       ),
    .AXI_DATA_WIDTH ( AxiDataWidth       ),
    .AXI_ID_WIDTH   ( AxiIdWidth         ),
    .AXI_USER_WIDTH ( AxiUserWidth       ),
    .axi_req_t      ( ariane_axi::req_t  ),
    .axi_rsp_t      ( ariane_axi::resp_t )
  ) i_spec_prefill_top (
    .clk_i           ( clk                  ),
    .clk_en_i        ( spec_prefill_clk_en  ),
    .rstn_i          ( ndmreset_n           ),
    .slv_axi_req_i   ( spec_prefill_slv_req ),
    .slv_axi_rsp_o   ( spec_prefill_slv_rsp )
  );


  // ------------------------------------------------------------
  // Auxiliary accelerator slot (third-party accelerator of the die, not released)
  // ------------------------------------------------------------
  // The die integrates a third-party accelerator at this NoC endpoint. Its
  // sources are not part of this release; the endpoint is kept and answers
  // every access with SLVERR so that the address map and the NoC topology
  // stay identical to the silicon.
  logic              aux_slot_clk_en;
  ariane_axi::req_t  aux_slot_slv_req;
  ariane_axi::resp_t aux_slot_slv_rsp;

  `AXI_ASSIGN_REQ_STRUCT(aux_slot_slv_req, aux_slot_slave_req_from_noc)
  `AXI_ASSIGN_RESP_STRUCT(aux_slot_slave_resp_for_noc, aux_slot_slv_rsp)
  axi_err_slv #(
    .AxiIdWidth ( AxiIdWidth            ),
    .axi_req_t  ( ariane_axi::req_t     ),
    .axi_resp_t ( ariane_axi::resp_t    ),
    .Resp       ( axi_pkg::RESP_SLVERR  ),
    .ATOPs      ( 1'b1                  ),
    .MaxTrans   ( 4                     )
  ) i_aux_slot_err_slv (
    .clk_i      ( clk                   ),
    .rst_ni     ( ndmreset_n            ),
    .test_i     ( 1'b0                  ),
    .slv_req_i  ( aux_slot_slv_req      ),
    .slv_resp_o ( aux_slot_slv_rsp      )
  );


  // ------------------------------------------------------------
  // Last Level Cache (LLC)
  // ------------------------------------------------------------
  localparam LLCRegAddrWidth  = unsigned'(32);
  localparam LLCRegDataWidth  = unsigned'(32);
  localparam LLCNumSet        = unsigned'(8);
  localparam LLCNumLines      = unsigned'(256);
  localparam LLCNumBlocks     = unsigned'(4);

  ariane_axi::req_t  llc_cfg_axi_slv_req;
  ariane_axi::resp_t llc_cfg_axi_slv_rsp;

  `REG_BUS_TYPEDEF_ALL(llc_cfg_reg, logic[LLCRegAddrWidth-1:0], logic[LLCRegDataWidth-1:0], logic[LLCRegDataWidth/8-1:0])
  llc_cfg_reg_req_t  llc_cfg_reg_req;
  llc_cfg_reg_rsp_t  llc_cfg_reg_rsp;

  AXI_BUS #(
    .AXI_ADDR_WIDTH ( AxiAddrWidth ),
    .AXI_DATA_WIDTH ( AxiDataWidth ),
    .AXI_ID_WIDTH   ( AxiIdWidth   ),
    .AXI_USER_WIDTH ( AxiUserWidth )
  ) llc_noc_axi_if (), llc_dram_axi_if ();

  REG_BUS #(
    .ADDR_WIDTH ( LLCRegAddrWidth ),
    .DATA_WIDTH ( LLCRegDataWidth )
  ) llc_cfg_reg_if ();

  `AXI_ASSIGN_FROM_REQ(llc_noc_axi_if, llc_slave_req_from_noc)
  `AXI_ASSIGN_TO_RESP(llc_slave_resp_for_noc, llc_noc_axi_if)
  `AXI_ASSIGN_REQ_STRUCT(llc_cfg_axi_slv_req, llc_cfg_slave_req_from_noc)
  `AXI_ASSIGN_RESP_STRUCT(llc_cfg_slave_resp_for_noc, llc_cfg_axi_slv_rsp)
  `REG_BUS_ASSIGN_FROM_REQ(llc_cfg_reg_if, llc_cfg_reg_req)
  `REG_BUS_ASSIGN_TO_RSP(llc_cfg_reg_rsp, llc_cfg_reg_if)

  axi_to_reg_v2 #(
    .AxiAddrWidth ( AxiAddrWidth       ),
    .AxiDataWidth ( AxiDataWidth       ),
    .AxiIdWidth   ( AxiIdWidth         ),
    .AxiUserWidth ( AxiUserWidth       ),
    .RegDataWidth ( LLCRegDataWidth    ),
    .CutMemReqs   ( 1'b1               ),
    .CutMemRsps   ( 1'b1               ),
    .axi_req_t    ( ariane_axi::req_t  ),
    .axi_rsp_t    ( ariane_axi::resp_t ),
    .reg_req_t    ( llc_cfg_reg_req_t  ),
    .reg_rsp_t    ( llc_cfg_reg_rsp_t  )
  ) i_llc_cfg_axi_to_reg_intf (
    .clk_i      ( clk                 ),
    .rst_ni     ( ndmreset_n          ),
    .axi_req_i  ( llc_cfg_axi_slv_req ),
    .axi_rsp_o  ( llc_cfg_axi_slv_rsp ),
    .reg_req_o  ( llc_cfg_reg_req     ),
    .reg_rsp_i  ( llc_cfg_reg_rsp     ),
    .reg_id_o   (),
    .busy_o     ()
  );

  axi_llc_top #(
    .SetAssociativity ( LLCNumSet    ),
    .NumLines         ( LLCNumLines  ),
    .NumBlocks        ( LLCNumBlocks ),
    .AxiIdWidth       ( AxiIdWidth   ),
    .AxiAddrWidth     ( AxiAddrWidth ),
    .AxiDataWidth     ( AxiDataWidth ),
    .AxiUserWidth     ( AxiUserWidth )
  ) i_axi_llc_top (
    .clk_i              ( clk                 ),
    .rst_ni             ( ndmreset_n          ),
    .slv                ( llc_noc_axi_if      ),
    .mst                ( llc_dram_axi_if     ),
    .conf_intf          ( llc_cfg_reg_if      ),
    .CachedRegionStart  ( LLCCachedRegionBase ),
    .CachedRegionLength ( soc_pkg::DRAMLength ),
    .SpmRegionStart     ( LLCSpmRegionBase    )
  );


  // ------------------------------------------------------------
  // Serial Link for DRAM, Die-to-Die-0 & Die-to-Die-1
  // ------------------------------------------------------------
  localparam SLNumChannels  = slink_reg_pkg::NumChannels;
  localparam SLNumLanes     = slink_reg_pkg::NumLanes;
  localparam SLRegAddrWidth = unsigned'(32);
  localparam SLRegDataWidth = slink_reg_pkg::SLINK_REG_DATA_WIDTH;
  localparam SLRegStrbWidth = unsigned'(SLRegDataWidth/8);
  `APB_TYPEDEF_ALL(sl_apb, logic[SLRegAddrWidth-1:0], logic[SLRegDataWidth-1:0], logic[SLRegStrbWidth-1:0])

  // DRAM
  AXI_BUS #(
      .AXI_ADDR_WIDTH ( AxiAddrWidth ),
      .AXI_DATA_WIDTH ( AxiDataWidth ),
      .AXI_ID_WIDTH   ( AxiIdWidth   ),
      .AXI_USER_WIDTH ( AxiUserWidth )
    ) dram_cfg_slv_axi_if ();

  sl_apb_req_t       dram_apb_req;
  sl_apb_resp_t      dram_apb_rsp;
  ariane_axi::req_t  dram_slv_req;
  ariane_axi::resp_t dram_slv_rsp;

  `AXI_ASSIGN_FROM_REQ(dram_cfg_slv_axi_if, sl_cfg_slave_req_from_noc)
  `AXI_ASSIGN_TO_RESP(sl_cfg_slave_resp_for_noc, dram_cfg_slv_axi_if)
  `AXI_ASSIGN_TO_REQ(dram_slv_req, llc_dram_axi_if)
  `AXI_ASSIGN_FROM_RESP(llc_dram_axi_if, dram_slv_rsp)

  axi2apb_wrap #(
    .AXI_ADDR_WIDTH ( AxiAddrWidth   ),
    .AXI_DATA_WIDTH ( AxiDataWidth   ),
    .AXI_USER_WIDTH ( AxiUserWidth   ),
    .AXI_ID_WIDTH   ( AxiIdWidth     ),
    .APB_ADDR_WIDTH ( SLRegAddrWidth ),
    .APB_DATA_WIDTH ( SLRegDataWidth )
  ) i_dram_axi2apb (
    .clk_i        ( clk                  ),
    .rst_ni       ( ndmreset_n           ),
    .test_en_i    ( test_en              ),
    .axi_slave    ( dram_cfg_slv_axi_if  ),
    .PENABLE      ( dram_apb_req.penable ),
    .PWRITE       ( dram_apb_req.pwrite  ),
    .PADDR        ( dram_apb_req.paddr   ),
    .PSEL         ( dram_apb_req.psel    ),
    .PWDATA       ( dram_apb_req.pwdata  ),
    .PRDATA       ( dram_apb_rsp.prdata  ),
    .PREADY       ( dram_apb_rsp.pready  ),
    .PSLVERR      ( dram_apb_rsp.pslverr )
  );
  assign dram_apb_req.pprot = '0;   // not used
  assign dram_apb_req.pstrb = '1;

  slink #(
    .NumCredits   (8),
    .axi_req_t    ( ariane_axi::req_t     ),
    .axi_rsp_t    ( ariane_axi::resp_t    ),
    .aw_chan_t    ( ariane_axi::aw_chan_t ),
    .ar_chan_t    ( ariane_axi::ar_chan_t ),
    .r_chan_t     ( ariane_axi::r_chan_t  ),
    .w_chan_t     ( ariane_axi::w_chan_t  ),
    .b_chan_t     ( ariane_axi::b_chan_t  ),
    .apb_req_t    ( sl_apb_req_t          ),
    .apb_rsp_t    ( sl_apb_resp_t         )
  ) i_dram_interface (
    .clk_i          ( clk          ),
    .rst_ni         ( ndmreset_n   ),
    .clk_sl_i       ( clk          ),
    .rst_sl_ni      ( ndmreset_n   ),
    .clk_reg_i      ( clk          ),
    .rst_reg_ni     ( ndmreset_n   ),
    .testmode_i     ( test_en      ),
    .axi_in_req_i   ( dram_slv_req ),
    .axi_in_rsp_o   ( dram_slv_rsp ),
    .axi_out_req_o  (              ),
    .axi_out_rsp_i  ( '0           ),
    .apb_req_i      ( dram_apb_req ),
    .apb_rsp_o      ( dram_apb_rsp ),
    .ddr_rcv_clk_i  ( sl_clk_rx_i  ),
    .ddr_rcv_clk_o  ( sl_clk_tx_o  ),
    .ddr_i          ( sl_data_rx_i ),
    .ddr_o          ( sl_data_tx_o ),
    .isolated_i     ( '0           ),
    .isolate_o      (              ),
    .clk_ena_o      (              ),
    .reset_no       (              )
  );

  // Die-to-Die #0
  AXI_BUS #(
      .AXI_ADDR_WIDTH ( AxiAddrWidth ),
      .AXI_DATA_WIDTH ( AxiDataWidth ),
      .AXI_ID_WIDTH   ( AxiIdWidth   ),
      .AXI_USER_WIDTH ( AxiUserWidth )
    ) d2d0_cfg_slv_axi_if ();

  sl_apb_req_t       d2d0_apb_req;
  sl_apb_resp_t      d2d0_apb_rsp;
  ariane_axi::req_t  d2d0_mst_req;
  ariane_axi::resp_t d2d0_mst_rsp;
  ariane_axi::req_t  d2d0_slv_req;
  ariane_axi::resp_t d2d0_slv_rsp;

  `AXI_ASSIGN_FROM_REQ(d2d0_cfg_slv_axi_if, d2d0_cfg_slave_req_from_noc)
  `AXI_ASSIGN_TO_RESP(d2d0_cfg_slave_resp_for_noc, d2d0_cfg_slv_axi_if)
  `AXI_ASSIGN_REQ_STRUCT(d2d0_master_req_for_noc, d2d0_mst_req)
  `AXI_ASSIGN_RESP_STRUCT(d2d0_mst_rsp, d2d0_master_resp_from_noc)
  `AXI_ASSIGN_REQ_STRUCT(d2d0_slv_req, d2d0_slave_req_from_noc)
  `AXI_ASSIGN_RESP_STRUCT(d2d0_slave_resp_for_noc, d2d0_slv_rsp)

  axi2apb_wrap #(
    .AXI_ADDR_WIDTH ( AxiAddrWidth   ),
    .AXI_DATA_WIDTH ( AxiDataWidth   ),
    .AXI_USER_WIDTH ( AxiUserWidth   ),
    .AXI_ID_WIDTH   ( AxiIdWidth     ),
    .APB_ADDR_WIDTH ( SLRegAddrWidth ),
    .APB_DATA_WIDTH ( SLRegDataWidth )
  ) i_d2d0_axi2apb (
    .clk_i        ( clk                  ),
    .rst_ni       ( ndmreset_n           ),
    .test_en_i    ( test_en              ),
    .axi_slave    ( d2d0_cfg_slv_axi_if  ),
    .PENABLE      ( d2d0_apb_req.penable ),
    .PWRITE       ( d2d0_apb_req.pwrite  ),
    .PADDR        ( d2d0_apb_req.paddr   ),
    .PSEL         ( d2d0_apb_req.psel    ),
    .PWDATA       ( d2d0_apb_req.pwdata  ),
    .PRDATA       ( d2d0_apb_rsp.prdata  ),
    .PREADY       ( d2d0_apb_rsp.pready  ),
    .PSLVERR      ( d2d0_apb_rsp.pslverr )
  );
  assign d2d0_apb_req.pprot = '0;   // not used
  assign d2d0_apb_req.pstrb = '1;

  slink #(
    .NumCredits   (8),
    .axi_req_t    ( ariane_axi::req_t     ),
    .axi_rsp_t    ( ariane_axi::resp_t    ),
    .aw_chan_t    ( ariane_axi::aw_chan_t ),
    .ar_chan_t    ( ariane_axi::ar_chan_t ),
    .r_chan_t     ( ariane_axi::r_chan_t  ),
    .w_chan_t     ( ariane_axi::w_chan_t  ),
    .b_chan_t     ( ariane_axi::b_chan_t  ),
    .apb_req_t    ( sl_apb_req_t          ),
    .apb_rsp_t    ( sl_apb_resp_t         )
  ) i_d2d0_interface (
    .clk_i          ( clk            ),
    .rst_ni         ( ndmreset_n     ),
    .clk_sl_i       ( clk            ),
    .rst_sl_ni      ( ndmreset_n     ),
    .clk_reg_i      ( clk            ),
    .rst_reg_ni     ( ndmreset_n     ),
    .testmode_i     ( test_en        ),
    .axi_in_req_i   ( d2d0_slv_req   ),
    .axi_in_rsp_o   ( d2d0_slv_rsp   ),
    .axi_out_req_o  ( d2d0_mst_req   ),
    .axi_out_rsp_i  ( d2d0_mst_rsp   ),
    .apb_req_i      ( d2d0_apb_req   ),
    .apb_rsp_o      ( d2d0_apb_rsp   ),
    .ddr_rcv_clk_i  ( d2d0_clk_rx_i  ),
    .ddr_rcv_clk_o  ( d2d0_clk_tx_o  ),
    .ddr_i          ( d2d0_data_rx_i ),
    .ddr_o          ( d2d0_data_tx_o ),
    .isolated_i     ( '0             ),
    .isolate_o      (                ),
    .clk_ena_o      (                ),
    .reset_no       (                )
  );

  // Die-to-Die #1
  sl_apb_req_t       d2d1_apb_req;
  sl_apb_resp_t      d2d1_apb_rsp;
  ariane_axi::req_t  d2d1_mst_req;
  ariane_axi::resp_t d2d1_mst_rsp;
  ariane_axi::req_t  d2d1_slv_req;
  ariane_axi::resp_t d2d1_slv_rsp;

  AXI_BUS #(
    .AXI_ADDR_WIDTH ( AxiAddrWidth ),
    .AXI_DATA_WIDTH ( AxiDataWidth ),
    .AXI_ID_WIDTH   ( AxiIdWidth   ),
    .AXI_USER_WIDTH ( AxiUserWidth )
  ) d2d1_cfg_slv_axi_if ();

  `AXI_ASSIGN_FROM_REQ(d2d1_cfg_slv_axi_if, d2d1_cfg_slave_req_from_noc)
  `AXI_ASSIGN_TO_RESP(d2d1_cfg_slave_resp_for_noc, d2d1_cfg_slv_axi_if)
  `AXI_ASSIGN_REQ_STRUCT(d2d1_master_req_for_noc, d2d1_mst_req)
  `AXI_ASSIGN_RESP_STRUCT(d2d1_mst_rsp, d2d1_master_resp_from_noc)
  `AXI_ASSIGN_REQ_STRUCT(d2d1_slv_req, d2d1_slave_req_from_noc)
  `AXI_ASSIGN_RESP_STRUCT(d2d1_slave_resp_for_noc, d2d1_slv_rsp)

  axi2apb_wrap #(
    .AXI_ADDR_WIDTH ( AxiAddrWidth   ),
    .AXI_DATA_WIDTH ( AxiDataWidth   ),
    .AXI_USER_WIDTH ( AxiUserWidth   ),
    .AXI_ID_WIDTH   ( AxiIdWidth     ),
    .APB_ADDR_WIDTH ( SLRegAddrWidth ),
    .APB_DATA_WIDTH ( SLRegDataWidth )
  ) i_d2d1_axi2apb (
    .clk_i        ( clk                  ),
    .rst_ni       ( ndmreset_n           ),
    .test_en_i    ( test_en              ),
    .axi_slave    ( d2d1_cfg_slv_axi_if  ),
    .PENABLE      ( d2d1_apb_req.penable ),
    .PWRITE       ( d2d1_apb_req.pwrite  ),
    .PADDR        ( d2d1_apb_req.paddr   ),
    .PSEL         ( d2d1_apb_req.psel    ),
    .PWDATA       ( d2d1_apb_req.pwdata  ),
    .PRDATA       ( d2d1_apb_rsp.prdata  ),
    .PREADY       ( d2d1_apb_rsp.pready  ),
    .PSLVERR      ( d2d1_apb_rsp.pslverr )
  );
  assign d2d1_apb_req.pprot = '0;   // not used
  assign d2d1_apb_req.pstrb = '1;

  slink #(
    .NumCredits   (8),
    .axi_req_t    ( ariane_axi::req_t     ),
    .axi_rsp_t    ( ariane_axi::resp_t    ),
    .aw_chan_t    ( ariane_axi::aw_chan_t ),
    .ar_chan_t    ( ariane_axi::ar_chan_t ),
    .r_chan_t     ( ariane_axi::r_chan_t  ),
    .w_chan_t     ( ariane_axi::w_chan_t  ),
    .b_chan_t     ( ariane_axi::b_chan_t  ),
    .apb_req_t    ( sl_apb_req_t          ),
    .apb_rsp_t    ( sl_apb_resp_t         )
  ) i_d2d1_interface (
    .clk_i          ( clk            ),
    .rst_ni         ( ndmreset_n     ),
    .clk_sl_i       ( clk            ),
    .rst_sl_ni      ( ndmreset_n     ),
    .clk_reg_i      ( clk            ),
    .rst_reg_ni     ( ndmreset_n     ),
    .testmode_i     ( test_en        ),
    .axi_in_req_i   ( d2d1_slv_req   ),
    .axi_in_rsp_o   ( d2d1_slv_rsp   ),
    .axi_out_req_o  ( d2d1_mst_req   ),
    .axi_out_rsp_i  ( d2d1_mst_rsp   ),
    .apb_req_i      ( d2d1_apb_req   ),
    .apb_rsp_o      ( d2d1_apb_rsp   ),
    .ddr_rcv_clk_i  ( d2d1_clk_rx_i  ),
    .ddr_rcv_clk_o  ( d2d1_clk_tx_o  ),
    .ddr_i          ( d2d1_data_rx_i ),
    .ddr_o          ( d2d1_data_tx_o ),
    .isolated_i     ( '0             ),
    .isolate_o      (                ),
    .clk_ena_o      (                ),
    .reset_no       (                )
  );


  // ------------------------------------------------------------
  // Debug Module
  // ------------------------------------------------------------
  logic          debug_req_valid      ;
  logic          debug_req_ready      ;
  dm::dmi_req_t  debug_req            ;
  logic          debug_resp_valid     ;
  logic          debug_resp_ready     ;
  dm::dmi_resp_t debug_resp           ;

  dmi_jtag i_dmi_jtag (
    .clk_i                ( clk              ),
    .rst_ni               ( rstn_i           ),
    .dmi_rst_no           (                  ), // keep open
    .testmode_i           ( test_en          ),
    .dmi_req_valid_o      ( debug_req_valid  ),
    .dmi_req_ready_i      ( debug_req_ready  ),
    .dmi_req_o            ( debug_req        ),
    .dmi_resp_valid_i     ( debug_resp_valid ),
    .dmi_resp_ready_o     ( debug_resp_ready ),
    .dmi_resp_i           ( debug_resp       ),
    .tck_i                ( jtag_tck_i       ),
    .tms_i                ( jtag_tms_i       ),
    .trst_ni              ( rstn_i           ),
    .td_i                 ( jtag_tdi_i       ),
    .td_o                 ( jtag_tdo_o       ),
    .tdo_oe_o             (                  )
  );

  logic                      dm_slave_req       ;
  logic                      dm_slave_we        ;
  logic [riscv::XLEN-1:0]    dm_slave_addr      ;
  logic [riscv::XLEN/8-1:0]  dm_slave_be        ;
  logic [riscv::XLEN-1:0]    dm_slave_wdata     ;
  logic [riscv::XLEN-1:0]    dm_slave_rdata     ;

  logic                      dm_master_req      ;
  logic [riscv::XLEN-1:0]    dm_master_add      ;
  logic                      dm_master_we       ;
  logic [riscv::XLEN-1:0]    dm_master_wdata    ;
  logic [riscv::XLEN/8-1:0]  dm_master_be       ;
  logic                      dm_master_gnt      ;
  logic                      dm_master_r_valid  ;
  logic [riscv::XLEN-1:0]    dm_master_r_rdata  ;

  logic debug_req_irq   ;
  logic dmactive        ;
  logic [63:0] dm_usr   ;
  assign dm_usr = 64'b0 ;

  AXI_BUS #(
    .AXI_ADDR_WIDTH ( riscv::XLEN  ),
    .AXI_DATA_WIDTH ( riscv::XLEN  ),
    .AXI_ID_WIDTH   ( AxiIdWidth   ),
    .AXI_USER_WIDTH ( AxiUserWidth )
  ) dm_if ();
  `AXI_ASSIGN_FROM_REQ(dm_if, dm_slave_req_from_noc)
  `AXI_ASSIGN_TO_RESP(dm_slave_resp_for_noc, dm_if)

  axi2mem #(
    .AXI_ID_WIDTH   ( AxiIdWidth   ),
    .AXI_ADDR_WIDTH ( riscv::XLEN  ),
    .AXI_DATA_WIDTH ( riscv::XLEN  ),
    .AXI_USER_WIDTH ( AxiUserWidth )
  ) i_dm_axi2mem (
    .clk_i      ( clk            ),
    .rst_ni     ( rstn_i         ),
    .slave      ( dm_if          ),
    .req_o      ( dm_slave_req   ),
    .we_o       ( dm_slave_we    ),
    .addr_o     ( dm_slave_addr  ),
    .be_o       ( dm_slave_be    ),
    .data_o     ( dm_slave_wdata ),
    .data_i     ( dm_slave_rdata ),
    .user_i     ( dm_usr         ),
    .user_o     ( /* Not Used */ )
  );

  ariane_axi::req_t    dm_axi_m_req;
  ariane_axi::resp_t   dm_axi_m_resp;
  `AXI_ASSIGN_REQ_STRUCT(dm_axi_m_req_for_noc, dm_axi_m_req)
  `AXI_ASSIGN_RESP_STRUCT(dm_axi_m_resp, dm_axi_m_resp_from_noc)

  dm_top #(
    .NrHarts          ( 1                           ),
    .BusWidth         ( riscv::XLEN                 ),
    .SelectableHarts  ( 1'b1                        )
  ) i_dm_top (
    .clk_i            ( clk                         ),
    .rst_ni           ( rstn_i                      ), // PoR
    .testmode_i       ( test_en                     ),
    .ndmreset_o       ( ndmreset                    ),
    .dmactive_o       ( dmactive                    ), // active debug session
    .debug_req_o      ( debug_req_irq               ),
    .unavailable_i    ( '0                          ),
    .hartinfo_i       ( {ariane_pkg::DebugHartInfo} ),
    .slave_req_i      ( dm_slave_req                ),
    .slave_we_i       ( dm_slave_we                 ),
    .slave_addr_i     ( dm_slave_addr               ),
    .slave_be_i       ( dm_slave_be                 ),
    .slave_wdata_i    ( dm_slave_wdata              ),
    .slave_rdata_o    ( dm_slave_rdata              ),
    .master_req_o     ( dm_master_req               ),
    .master_add_o     ( dm_master_add               ),
    .master_we_o      ( dm_master_we                ),
    .master_wdata_o   ( dm_master_wdata             ),
    .master_be_o      ( dm_master_be                ),
    .master_gnt_i     ( dm_master_gnt               ),
    .master_r_valid_i ( dm_master_r_valid           ),
    .master_r_rdata_i ( dm_master_r_rdata           ),
    .dmi_rst_ni       ( rstn_i                      ),
    .dmi_req_valid_i  ( debug_req_valid             ),
    .dmi_req_ready_o  ( debug_req_ready             ),
    .dmi_req_i        ( debug_req                   ),
    .dmi_resp_valid_o ( debug_resp_valid            ),
    .dmi_resp_ready_i ( debug_resp_ready            ),
    .dmi_resp_o       ( debug_resp                  )
  );

  logic [1:0] axi_adapter_size;
  assign axi_adapter_size = (riscv::XLEN == 64) ? 2'b11 : 2'b10;

  axi_adapter #(
    .CVA6Cfg               ( CVA6Cfg                ),
    .DATA_WIDTH            ( riscv::XLEN            ),
    .axi_req_t             ( ariane_axi::req_t      ),
    .axi_rsp_t             ( ariane_axi::resp_t     )
  ) i_dm_axi_master (
    .clk_i                 ( clk                    ),
    .rst_ni                ( rstn_i                 ),
    .req_i                 ( dm_master_req          ),
    .type_i                ( ariane_pkg::SINGLE_REQ ),
    .amo_i                 ( ariane_pkg::AMO_NONE   ),
    .gnt_o                 ( dm_master_gnt          ),
    .addr_i                ( dm_master_add          ),
    .we_i                  ( dm_master_we           ),
    .wdata_i               ( dm_master_wdata        ),
    .be_i                  ( dm_master_be           ),
    .size_i                ( axi_adapter_size       ),
    .id_i                  ( '0                     ),
    .valid_o               ( dm_master_r_valid      ),
    .rdata_o               ( dm_master_r_rdata      ),
    .id_o                  (                        ),
    .critical_word_o       (                        ),
    .critical_word_valid_o (                        ),
    .axi_req_o             ( dm_axi_m_req           ),
    .axi_resp_i            ( dm_axi_m_resp          )
  );


  // ------------------------------------------------------------
  // CVA6 CPU Core
  // ------------------------------------------------------------
  ariane_axi::req_t    axi_ariane_req;
  ariane_axi::resp_t   axi_ariane_resp;
  `AXI_ASSIGN_REQ_STRUCT(axi_ariane_req_for_noc, axi_ariane_req)
  `AXI_ASSIGN_RESP_STRUCT(axi_ariane_resp, axi_ariane_resp_from_noc)

  localparam bit IsRVFI = bit'(0)       ;
  localparam type rvfi_instr_t = logic  ;
  logic timer_irq                       ;
  logic ipi                             ;
  logic rtc                             ;

  cva6 #(
    .CVA6Cfg        ( CVA6Cfg        ),
    .IsRVFI         ( IsRVFI         ),
    .rvfi_instr_t   ( rvfi_instr_t   )
  ) i_cpu (
    .clk_i        ( clk              ),
    .rst_ni       ( ndmreset_n       ),
    .boot_addr_i  ( ROMBase          ), // start fetching from ROM
    .hart_id_i    ( hart_id          ),
    .irq_i        ( irq              ),
    .ipi_i        ( ipi              ),
    .time_irq_i   ( timer_irq        ),
    .debug_req_i  ( debug_req_irq    ),
    .noc_req_o    ( axi_ariane_req   ),
    .noc_resp_i   ( axi_ariane_resp  ),
    .DmBaseAddress_i ( DmBaseAddress ),
    .CachedRegionAddrBase_i ( CachedRegionAddrBase )
  );


  // ------------------------------------------------------------
  // BootROM
  // ------------------------------------------------------------
  logic                    rom_req    ;
  logic [AxiAddrWidth-1:0] rom_addr   ;
  logic [AxiDataWidth-1:0] rom_rdata  ;
  logic [63:0] rom_usr;
  assign rom_usr = 64'b0;

  AXI_BUS #(
    .AXI_ADDR_WIDTH ( AxiAddrWidth ),
    .AXI_DATA_WIDTH ( AxiDataWidth ),
    .AXI_ID_WIDTH   ( AxiIdWidth   ),
    .AXI_USER_WIDTH ( AxiUserWidth )
  ) rom_if ();

  `AXI_ASSIGN_FROM_REQ(rom_if, rom_slave_req_from_noc)
  `AXI_ASSIGN_TO_RESP(rom_slave_resp_for_noc, rom_if)

  axi2mem #(
    .AXI_ID_WIDTH   ( AxiIdWidth   ),
    .AXI_ADDR_WIDTH ( AxiAddrWidth ),
    .AXI_DATA_WIDTH ( AxiDataWidth ),
    .AXI_USER_WIDTH ( AxiUserWidth )
  ) i_axi2rom (
    .clk_i  ( clk        ),
    .rst_ni ( ndmreset_n ),
    .slave  ( rom_if     ),
    .req_o  ( rom_req    ),
    .we_o   (            ),
    .addr_o ( rom_addr   ),
    .be_o   (            ),
    .data_o (            ),
    .data_i ( rom_rdata  ),
    .user_i ( rom_usr    ),
    .user_o (            )
  );

  bootrom i_bootrom (
    .clk_i      ( clk        ),
    .req_i      ( rom_req    ),
    .addr_i     ( rom_addr   ),
    .rdata_o    ( rom_rdata  ),
    .soc_id_i   ( soc_id_i   ),
    .jump_sel_i ( boot_sel_i )
  );


  // ------------------------------------------------------------
  // CLINT
  // ------------------------------------------------------------
  ariane_axi::req_t    axi_clint_req;
  ariane_axi::resp_t   axi_clint_resp;
  `AXI_ASSIGN_REQ_STRUCT(axi_clint_req, clint_slave_req_from_noc)
  `AXI_ASSIGN_RESP_STRUCT(clint_slave_resp_for_noc, axi_clint_resp)

  // divide clock by two
  always_ff @(posedge clk or negedge ndmreset_n) begin
    if (~ndmreset_n) begin
    rtc <= 0;
    end else begin
    rtc <= rtc ^ 1'b1;
    end
  end

  clint #(
    .AXI_ADDR_WIDTH ( AxiAddrWidth       ),
    .AXI_DATA_WIDTH ( AxiDataWidth       ),
    .AXI_ID_WIDTH   ( AxiIdWidth         ),
    .NR_CORES       ( 1                  ),
    .axi_req_t      ( ariane_axi::req_t  ),
    .axi_resp_t     ( ariane_axi::resp_t )
  ) i_clint (
    .clk_i       ( clk            ),
    .rst_ni      ( ndmreset_n     ),
    .testmode_i  ( test_en        ),
    .axi_req_i   ( axi_clint_req  ),
    .axi_resp_o  ( axi_clint_resp ),
    .rtc_i       ( rtc            ),
    .timer_irq_o ( timer_irq      ),
    .ipi_o       ( ipi            )
  );


  // ------------------------------------------------------------
  // Peripherals
  // ------------------------------------------------------------
  AXI_BUS #(
    .AXI_ADDR_WIDTH ( AxiAddrWidth ),
    .AXI_DATA_WIDTH ( AxiDataWidth ),
    .AXI_ID_WIDTH   ( AxiIdWidth   ),
    .AXI_USER_WIDTH ( AxiUserWidth )
  ) plic_if (), uart_if (), timer_if ();

  `AXI_ASSIGN_FROM_REQ(plic_if, plic_slave_req_from_noc)
  `AXI_ASSIGN_TO_RESP(plic_slave_resp_for_noc, plic_if)

  `AXI_ASSIGN_FROM_REQ(uart_if, uart_slave_req_from_noc)
  `AXI_ASSIGN_TO_RESP(uart_slave_resp_for_noc, uart_if)

  `AXI_ASSIGN_FROM_REQ(timer_if, timer_slave_req_from_noc)
  `AXI_ASSIGN_TO_RESP(timer_slave_resp_for_noc, timer_if)

  peripheral #(
    .AxiAddrWidth ( AxiAddrWidth ),
    .AxiDataWidth ( AxiDataWidth ),
    .AxiIdWidth   ( AxiIdWidth   ),
    .AxiUserWidth ( AxiUserWidth )
  ) i_peripheral (
    .clk_i        ( clk        ),
    .rst_ni       ( ndmreset_n ),
    .plic         ( plic_if    ),
    .uart         ( uart_if    ),
    .timer        ( timer_if   ),
    .irq_o        ( irq        ),
    .rx_i         ( uart_rx_i  ),
    .tx_o         ( uart_tx_o  )
  );


  // ------------------------------------------------------------
  // System DCO
  // ------------------------------------------------------------
  `REG_BUS_TYPEDEF_ALL(clk_reg, logic[AxiAddrWidth-1:0], logic[AxiDataWidth-1:0], logic[AxiDataWidth/8-1:0])
  ariane_axi::req_t   sys_dco_axi_req;
  ariane_axi::resp_t  sys_dco_axi_rsp;
  clk_reg_req_t       sys_dco_reg_req;
  clk_reg_rsp_t       sys_dco_reg_rsp;
  `AXI_ASSIGN_REQ_STRUCT(sys_dco_axi_req, sys_dco_slave_req_from_noc)
  `AXI_ASSIGN_RESP_STRUCT(sys_dco_slave_resp_for_noc, sys_dco_axi_rsp)

  axi_to_reg_v2 #(
    .AxiAddrWidth ( AxiAddrWidth       ),
    .AxiDataWidth ( AxiDataWidth       ),
    .AxiIdWidth   ( AxiIdWidth         ),
    .AxiUserWidth ( AxiUserWidth       ),
    .RegDataWidth ( AxiDataWidth       ),
    .CutMemReqs   ( 1'b1               ),
    .CutMemRsps   ( 1'b1               ),
    .axi_req_t    ( ariane_axi::req_t  ),
    .axi_rsp_t    ( ariane_axi::resp_t ),
    .reg_req_t    ( clk_reg_req_t      ),
    .reg_rsp_t    ( clk_reg_rsp_t      )
  ) i_axi_to_sys_dco_reg_intf (
    .clk_i      ( clk               ),
    .rst_ni     ( ndmreset_n        ),
    .axi_req_i  ( sys_dco_axi_req   ),
    .axi_rsp_o  ( sys_dco_axi_rsp   ),
    .reg_req_o  ( sys_dco_reg_req   ),
    .reg_rsp_i  ( sys_dco_reg_rsp   ),
    .reg_id_o   (),
    .busy_o     ()
  );

  logic [6-1:0]         sys_dco_cc_sel    ;
  logic [6-1:0]         sys_dco_fc_sel    ;
  logic [3-1:0]         sys_dco_div_sel   ;
  logic [2-1:0]         sys_dco_freq_sel  ;
  logic [8-1:0][4-1:0]  int_core_clk_en   ;
  logic [8-1:0]         fp_core_clk_en    ;

  for (genvar i = 0; i < 8; i++) begin
    assign cluster_clk_en[i] = {fp_core_clk_en[i], int_core_clk_en[i]};
  end

  dco_regs #(
    .reg_req_t ( clk_reg_req_t ),
    .reg_rsp_t ( clk_reg_rsp_t )
  ) i_sys_dco_regs(
    .clk_i                ( clk                 ),
    .rstn_i               ( ndmreset_n          ),
    .cc_sel_o             ( sys_dco_cc_sel      ),
    .fc_sel_o             ( sys_dco_fc_sel      ),
    .freq_sel_o           ( sys_dco_freq_sel    ),
    .div_sel_o            ( sys_dco_div_sel     ),
    .int_core_clk_en_o    ( int_core_clk_en     ),
    .fp_core_clk_en_o     ( fp_core_clk_en      ),
    .sp_core_clk_en_o     ( spec_prefill_clk_en ),
    .aux_slot_clk_en_o    ( aux_slot_clk_en     ),
    .req_i                ( sys_dco_reg_req     ),
    .rsp_o                ( sys_dco_reg_rsp     )
  );

`ifdef SIM
  assign clk = sys_clk_i;
  assign sys_dco_clk_o = sys_clk_i; // Keep the observation output driven in simulation.
`elsif FPGA
  logic sys_clk_div;

  // Instantiate a clock divider/PLL wrapper for the FPGA
  clk_div i_clk_div (
    .sys_clk_div ( sys_clk_div ), // output sys_clk_div
    .resetn      ( rstn_i      ), // input resetn
    .locked      (             ), // output locked (can be left open if unused)
    .sys_clk_i   ( sys_clk_i   )  // input sys_clk_i
  );

  assign clk     = sys_clk_div;
`else
  // --- DCO Clock Generation Hardware ---
  // sys_dco_clk_o is the existing output port; do not redeclare it.

  DCO i_sys_dco(
    .EN       ( sys_dco_en_i      ),
    .CC_SEL   ( sys_dco_cc_sel    ),
    .FC_SEL   ( sys_dco_fc_sel    ),
    .EXT_CLK  ( ext_clk_i    	    ),
    .CLK_SEL  ( sys_clk_sel_i     ),
    .DIV_SEL  ( sys_dco_div_sel   ),
    .FREQ_SEL ( sys_dco_freq_sel  ),
    .CLK      ( sys_dco_clk_o     ), // This is the clock we will use for the system
    .CLK_DIV  (                   ), // Optional monitor divider is not exported by this SoC.
    .RSTN     ( rstn_i            )
  );

  // Final clock assignment for the ASIC target
  assign clk = sys_dco_clk_o;
`endif


  // ------------------------------------------------------------
  // Clock Detector
  // ------------------------------------------------------------
  logic [31:0] timer_cnt;
  always_ff @(posedge clk or negedge rstn_i)
  begin
    if (!rstn_i)
    begin
      clk_led_o <= 1'b0             ;
      timer_cnt <= 32'd0            ;
    end
    else if (timer_cnt == 32'd499_999)
    begin
      clk_led_o <= ~clk_led_o       ;
      timer_cnt <= 32'd0            ;
    end
    else
    begin
      clk_led_o <= clk_led_o        ;
      timer_cnt <= timer_cnt + 32'd1;
    end
  end

endmodule
