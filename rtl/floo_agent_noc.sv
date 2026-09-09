// Copyright 2026 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// AUTOMATICALLY GENERATED! DO NOT EDIT!

module floo_agent_noc
  import floo_pkg::*;
  import floo_agent_noc_pkg::*;
(
    input  logic                                clk_i,
    input  logic                                rst_ni,
    input  logic                                test_enable_i,
    input  mst_axi_req_t                        cpu_master_mst_req_i,
    output mst_axi_rsp_t                        cpu_master_mst_rsp_o,
    input  mst_axi_req_t                        dm_master_mst_req_i,
    output mst_axi_rsp_t                        dm_master_mst_rsp_o,
    input  mst_axi_req_t                        d2d0_master_mst_req_i,
    output mst_axi_rsp_t                        d2d0_master_mst_rsp_o,
    input  mst_axi_req_t                        d2d1_master_mst_req_i,
    output mst_axi_rsp_t                        d2d1_master_mst_rsp_o,
    input  mst_axi_req_t [            3:0][7:0] int_core_master_mst_req_i,
    output mst_axi_rsp_t [            3:0][7:0] int_core_master_mst_rsp_o,
    output slv_axi_req_t                        llc_slave_slv_req_o,
    input  slv_axi_rsp_t                        llc_slave_slv_rsp_i,
    output slv_axi_req_t                        rom_slave_slv_req_o,
    input  slv_axi_rsp_t                        rom_slave_slv_rsp_i,
    output slv_axi_req_t                        dm_slave_slv_req_o,
    input  slv_axi_rsp_t                        dm_slave_slv_rsp_i,
    output slv_axi_req_t                        clint_slave_slv_req_o,
    input  slv_axi_rsp_t                        clint_slave_slv_rsp_i,
    output slv_axi_req_t                        plic_slave_slv_req_o,
    input  slv_axi_rsp_t                        plic_slave_slv_rsp_i,
    output slv_axi_req_t                        uart_slave_slv_req_o,
    input  slv_axi_rsp_t                        uart_slave_slv_rsp_i,
    output slv_axi_req_t                        timer_slave_slv_req_o,
    input  slv_axi_rsp_t                        timer_slave_slv_rsp_i,
    output slv_axi_req_t                        sys_dco_slave_slv_req_o,
    input  slv_axi_rsp_t                        sys_dco_slave_slv_rsp_i,
    output slv_axi_req_t                        sl_cfg_slave_slv_req_o,
    input  slv_axi_rsp_t                        sl_cfg_slave_slv_rsp_i,
    output slv_axi_req_t                        d2d0_cfg_slave_slv_req_o,
    input  slv_axi_rsp_t                        d2d0_cfg_slave_slv_rsp_i,
    output slv_axi_req_t                        d2d1_cfg_slave_slv_req_o,
    input  slv_axi_rsp_t                        d2d1_cfg_slave_slv_rsp_i,
    output slv_axi_req_t                        llc_cfg_slave_slv_req_o,
    input  slv_axi_rsp_t                        llc_cfg_slave_slv_rsp_i,
    output slv_axi_req_t                        d2d0_slave_slv_req_o,
    input  slv_axi_rsp_t                        d2d0_slave_slv_rsp_i,
    output slv_axi_req_t                        d2d1_slave_slv_req_o,
    input  slv_axi_rsp_t                        d2d1_slave_slv_rsp_i,
    output slv_axi_req_t [            3:0][7:0] int_core_slave_slv_req_o,
    input  slv_axi_rsp_t [            3:0][7:0] int_core_slave_slv_rsp_i,
    output slv_axi_req_t [            7:0]      fp_core_slave_slv_req_o,
    input  slv_axi_rsp_t [            7:0]      fp_core_slave_slv_rsp_i,
    output slv_axi_req_t                        sp_slave_slv_req_o,
    input  slv_axi_rsp_t                        sp_slave_slv_rsp_i,
    output slv_axi_req_t                        aux_slot_slave_slv_req_o,
    input  slv_axi_rsp_t                        aux_slot_slave_slv_rsp_i,
    input  sam_rule_t    [SamNumRules-1:0]      sam_map_i
);

  floo_req_t central_router_to_cpu_master_ni_req;
  floo_rsp_t cpu_master_ni_to_central_router_rsp;

  floo_req_t central_router_to_dm_master_ni_req;
  floo_rsp_t dm_master_ni_to_central_router_rsp;

  floo_req_t central_router_to_d2d0_master_ni_req;
  floo_rsp_t d2d0_master_ni_to_central_router_rsp;

  floo_req_t central_router_to_d2d1_master_ni_req;
  floo_rsp_t d2d1_master_ni_to_central_router_rsp;

  floo_req_t central_router_to_mesh_router_0_0_req;
  floo_rsp_t mesh_router_0_0_to_central_router_rsp;

  floo_req_t central_router_to_llc_slave_ni_req;
  floo_rsp_t llc_slave_ni_to_central_router_rsp;

  floo_req_t central_router_to_rom_slave_ni_req;
  floo_rsp_t rom_slave_ni_to_central_router_rsp;

  floo_req_t central_router_to_dm_slave_ni_req;
  floo_rsp_t dm_slave_ni_to_central_router_rsp;

  floo_req_t central_router_to_clint_slave_ni_req;
  floo_rsp_t clint_slave_ni_to_central_router_rsp;

  floo_req_t central_router_to_plic_slave_ni_req;
  floo_rsp_t plic_slave_ni_to_central_router_rsp;

  floo_req_t central_router_to_uart_slave_ni_req;
  floo_rsp_t uart_slave_ni_to_central_router_rsp;

  floo_req_t central_router_to_timer_slave_ni_req;
  floo_rsp_t timer_slave_ni_to_central_router_rsp;

  floo_req_t central_router_to_sys_dco_slave_ni_req;
  floo_rsp_t sys_dco_slave_ni_to_central_router_rsp;

  floo_req_t central_router_to_sl_cfg_slave_ni_req;
  floo_rsp_t sl_cfg_slave_ni_to_central_router_rsp;

  floo_req_t central_router_to_d2d0_slave_ni_req;
  floo_rsp_t d2d0_slave_ni_to_central_router_rsp;

  floo_req_t central_router_to_d2d1_slave_ni_req;
  floo_rsp_t d2d1_slave_ni_to_central_router_rsp;

  floo_req_t central_router_to_d2d0_cfg_slave_ni_req;
  floo_rsp_t d2d0_cfg_slave_ni_to_central_router_rsp;

  floo_req_t central_router_to_d2d1_cfg_slave_ni_req;
  floo_rsp_t d2d1_cfg_slave_ni_to_central_router_rsp;

  floo_req_t central_router_to_llc_cfg_slave_ni_req;
  floo_rsp_t llc_cfg_slave_ni_to_central_router_rsp;

  floo_req_t central_router_to_sp_slave_ni_req;
  floo_rsp_t sp_slave_ni_to_central_router_rsp;

  floo_req_t central_router_to_aux_slot_slave_ni_req;
  floo_rsp_t aux_slot_slave_ni_to_central_router_rsp;

  floo_req_t mesh_router_0_0_to_mesh_router_0_1_req;
  floo_rsp_t mesh_router_0_1_to_mesh_router_0_0_rsp;

  floo_req_t mesh_router_0_0_to_mesh_router_1_0_req;
  floo_rsp_t mesh_router_1_0_to_mesh_router_0_0_rsp;

  floo_req_t mesh_router_0_0_to_central_router_req;
  floo_rsp_t central_router_to_mesh_router_0_0_rsp;

  floo_req_t mesh_router_0_0_to_int_core_slave_ni_0_0_req;
  floo_rsp_t int_core_slave_ni_0_0_to_mesh_router_0_0_rsp;

  floo_req_t mesh_router_0_0_to_int_core_master_ni_0_0_req;
  floo_rsp_t int_core_master_ni_0_0_to_mesh_router_0_0_rsp;

  floo_req_t mesh_router_0_1_to_mesh_router_0_0_req;
  floo_rsp_t mesh_router_0_0_to_mesh_router_0_1_rsp;

  floo_req_t mesh_router_0_1_to_mesh_router_0_2_req;
  floo_rsp_t mesh_router_0_2_to_mesh_router_0_1_rsp;

  floo_req_t mesh_router_0_1_to_mesh_router_1_1_req;
  floo_rsp_t mesh_router_1_1_to_mesh_router_0_1_rsp;

  floo_req_t mesh_router_0_1_to_int_core_slave_ni_0_1_req;
  floo_rsp_t int_core_slave_ni_0_1_to_mesh_router_0_1_rsp;

  floo_req_t mesh_router_0_1_to_int_core_master_ni_0_1_req;
  floo_rsp_t int_core_master_ni_0_1_to_mesh_router_0_1_rsp;

  floo_req_t mesh_router_0_2_to_mesh_router_0_1_req;
  floo_rsp_t mesh_router_0_1_to_mesh_router_0_2_rsp;

  floo_req_t mesh_router_0_2_to_mesh_router_0_3_req;
  floo_rsp_t mesh_router_0_3_to_mesh_router_0_2_rsp;

  floo_req_t mesh_router_0_2_to_mesh_router_1_2_req;
  floo_rsp_t mesh_router_1_2_to_mesh_router_0_2_rsp;

  floo_req_t mesh_router_0_2_to_int_core_slave_ni_0_2_req;
  floo_rsp_t int_core_slave_ni_0_2_to_mesh_router_0_2_rsp;

  floo_req_t mesh_router_0_2_to_int_core_master_ni_0_2_req;
  floo_rsp_t int_core_master_ni_0_2_to_mesh_router_0_2_rsp;

  floo_req_t mesh_router_0_3_to_mesh_router_0_2_req;
  floo_rsp_t mesh_router_0_2_to_mesh_router_0_3_rsp;

  floo_req_t mesh_router_0_3_to_mesh_router_0_4_req;
  floo_rsp_t mesh_router_0_4_to_mesh_router_0_3_rsp;

  floo_req_t mesh_router_0_3_to_mesh_router_1_3_req;
  floo_rsp_t mesh_router_1_3_to_mesh_router_0_3_rsp;

  floo_req_t mesh_router_0_3_to_int_core_slave_ni_0_3_req;
  floo_rsp_t int_core_slave_ni_0_3_to_mesh_router_0_3_rsp;

  floo_req_t mesh_router_0_3_to_int_core_master_ni_0_3_req;
  floo_rsp_t int_core_master_ni_0_3_to_mesh_router_0_3_rsp;

  floo_req_t mesh_router_0_4_to_mesh_router_0_3_req;
  floo_rsp_t mesh_router_0_3_to_mesh_router_0_4_rsp;

  floo_req_t mesh_router_0_4_to_mesh_router_0_5_req;
  floo_rsp_t mesh_router_0_5_to_mesh_router_0_4_rsp;

  floo_req_t mesh_router_0_4_to_mesh_router_1_4_req;
  floo_rsp_t mesh_router_1_4_to_mesh_router_0_4_rsp;

  floo_req_t mesh_router_0_4_to_int_core_slave_ni_0_4_req;
  floo_rsp_t int_core_slave_ni_0_4_to_mesh_router_0_4_rsp;

  floo_req_t mesh_router_0_4_to_int_core_master_ni_0_4_req;
  floo_rsp_t int_core_master_ni_0_4_to_mesh_router_0_4_rsp;

  floo_req_t mesh_router_0_5_to_mesh_router_0_4_req;
  floo_rsp_t mesh_router_0_4_to_mesh_router_0_5_rsp;

  floo_req_t mesh_router_0_5_to_mesh_router_0_6_req;
  floo_rsp_t mesh_router_0_6_to_mesh_router_0_5_rsp;

  floo_req_t mesh_router_0_5_to_mesh_router_1_5_req;
  floo_rsp_t mesh_router_1_5_to_mesh_router_0_5_rsp;

  floo_req_t mesh_router_0_5_to_int_core_slave_ni_0_5_req;
  floo_rsp_t int_core_slave_ni_0_5_to_mesh_router_0_5_rsp;

  floo_req_t mesh_router_0_5_to_int_core_master_ni_0_5_req;
  floo_rsp_t int_core_master_ni_0_5_to_mesh_router_0_5_rsp;

  floo_req_t mesh_router_0_6_to_mesh_router_0_5_req;
  floo_rsp_t mesh_router_0_5_to_mesh_router_0_6_rsp;

  floo_req_t mesh_router_0_6_to_mesh_router_0_7_req;
  floo_rsp_t mesh_router_0_7_to_mesh_router_0_6_rsp;

  floo_req_t mesh_router_0_6_to_mesh_router_1_6_req;
  floo_rsp_t mesh_router_1_6_to_mesh_router_0_6_rsp;

  floo_req_t mesh_router_0_6_to_int_core_slave_ni_0_6_req;
  floo_rsp_t int_core_slave_ni_0_6_to_mesh_router_0_6_rsp;

  floo_req_t mesh_router_0_6_to_int_core_master_ni_0_6_req;
  floo_rsp_t int_core_master_ni_0_6_to_mesh_router_0_6_rsp;

  floo_req_t mesh_router_0_7_to_mesh_router_0_6_req;
  floo_rsp_t mesh_router_0_6_to_mesh_router_0_7_rsp;

  floo_req_t mesh_router_0_7_to_mesh_router_1_7_req;
  floo_rsp_t mesh_router_1_7_to_mesh_router_0_7_rsp;

  floo_req_t mesh_router_0_7_to_int_core_slave_ni_0_7_req;
  floo_rsp_t int_core_slave_ni_0_7_to_mesh_router_0_7_rsp;

  floo_req_t mesh_router_0_7_to_int_core_master_ni_0_7_req;
  floo_rsp_t int_core_master_ni_0_7_to_mesh_router_0_7_rsp;

  floo_req_t mesh_router_1_0_to_mesh_router_0_0_req;
  floo_rsp_t mesh_router_0_0_to_mesh_router_1_0_rsp;

  floo_req_t mesh_router_1_0_to_mesh_router_1_1_req;
  floo_rsp_t mesh_router_1_1_to_mesh_router_1_0_rsp;

  floo_req_t mesh_router_1_0_to_mesh_router_2_0_req;
  floo_rsp_t mesh_router_2_0_to_mesh_router_1_0_rsp;

  floo_req_t mesh_router_1_0_to_int_core_slave_ni_1_0_req;
  floo_rsp_t int_core_slave_ni_1_0_to_mesh_router_1_0_rsp;

  floo_req_t mesh_router_1_0_to_int_core_master_ni_1_0_req;
  floo_rsp_t int_core_master_ni_1_0_to_mesh_router_1_0_rsp;

  floo_req_t mesh_router_1_1_to_mesh_router_0_1_req;
  floo_rsp_t mesh_router_0_1_to_mesh_router_1_1_rsp;

  floo_req_t mesh_router_1_1_to_mesh_router_1_0_req;
  floo_rsp_t mesh_router_1_0_to_mesh_router_1_1_rsp;

  floo_req_t mesh_router_1_1_to_mesh_router_1_2_req;
  floo_rsp_t mesh_router_1_2_to_mesh_router_1_1_rsp;

  floo_req_t mesh_router_1_1_to_mesh_router_2_1_req;
  floo_rsp_t mesh_router_2_1_to_mesh_router_1_1_rsp;

  floo_req_t mesh_router_1_1_to_int_core_slave_ni_1_1_req;
  floo_rsp_t int_core_slave_ni_1_1_to_mesh_router_1_1_rsp;

  floo_req_t mesh_router_1_1_to_int_core_master_ni_1_1_req;
  floo_rsp_t int_core_master_ni_1_1_to_mesh_router_1_1_rsp;

  floo_req_t mesh_router_1_2_to_mesh_router_0_2_req;
  floo_rsp_t mesh_router_0_2_to_mesh_router_1_2_rsp;

  floo_req_t mesh_router_1_2_to_mesh_router_1_1_req;
  floo_rsp_t mesh_router_1_1_to_mesh_router_1_2_rsp;

  floo_req_t mesh_router_1_2_to_mesh_router_1_3_req;
  floo_rsp_t mesh_router_1_3_to_mesh_router_1_2_rsp;

  floo_req_t mesh_router_1_2_to_mesh_router_2_2_req;
  floo_rsp_t mesh_router_2_2_to_mesh_router_1_2_rsp;

  floo_req_t mesh_router_1_2_to_int_core_slave_ni_1_2_req;
  floo_rsp_t int_core_slave_ni_1_2_to_mesh_router_1_2_rsp;

  floo_req_t mesh_router_1_2_to_int_core_master_ni_1_2_req;
  floo_rsp_t int_core_master_ni_1_2_to_mesh_router_1_2_rsp;

  floo_req_t mesh_router_1_3_to_mesh_router_0_3_req;
  floo_rsp_t mesh_router_0_3_to_mesh_router_1_3_rsp;

  floo_req_t mesh_router_1_3_to_mesh_router_1_2_req;
  floo_rsp_t mesh_router_1_2_to_mesh_router_1_3_rsp;

  floo_req_t mesh_router_1_3_to_mesh_router_1_4_req;
  floo_rsp_t mesh_router_1_4_to_mesh_router_1_3_rsp;

  floo_req_t mesh_router_1_3_to_mesh_router_2_3_req;
  floo_rsp_t mesh_router_2_3_to_mesh_router_1_3_rsp;

  floo_req_t mesh_router_1_3_to_int_core_slave_ni_1_3_req;
  floo_rsp_t int_core_slave_ni_1_3_to_mesh_router_1_3_rsp;

  floo_req_t mesh_router_1_3_to_int_core_master_ni_1_3_req;
  floo_rsp_t int_core_master_ni_1_3_to_mesh_router_1_3_rsp;

  floo_req_t mesh_router_1_4_to_mesh_router_0_4_req;
  floo_rsp_t mesh_router_0_4_to_mesh_router_1_4_rsp;

  floo_req_t mesh_router_1_4_to_mesh_router_1_3_req;
  floo_rsp_t mesh_router_1_3_to_mesh_router_1_4_rsp;

  floo_req_t mesh_router_1_4_to_mesh_router_1_5_req;
  floo_rsp_t mesh_router_1_5_to_mesh_router_1_4_rsp;

  floo_req_t mesh_router_1_4_to_mesh_router_2_4_req;
  floo_rsp_t mesh_router_2_4_to_mesh_router_1_4_rsp;

  floo_req_t mesh_router_1_4_to_int_core_slave_ni_1_4_req;
  floo_rsp_t int_core_slave_ni_1_4_to_mesh_router_1_4_rsp;

  floo_req_t mesh_router_1_4_to_int_core_master_ni_1_4_req;
  floo_rsp_t int_core_master_ni_1_4_to_mesh_router_1_4_rsp;

  floo_req_t mesh_router_1_5_to_mesh_router_0_5_req;
  floo_rsp_t mesh_router_0_5_to_mesh_router_1_5_rsp;

  floo_req_t mesh_router_1_5_to_mesh_router_1_4_req;
  floo_rsp_t mesh_router_1_4_to_mesh_router_1_5_rsp;

  floo_req_t mesh_router_1_5_to_mesh_router_1_6_req;
  floo_rsp_t mesh_router_1_6_to_mesh_router_1_5_rsp;

  floo_req_t mesh_router_1_5_to_mesh_router_2_5_req;
  floo_rsp_t mesh_router_2_5_to_mesh_router_1_5_rsp;

  floo_req_t mesh_router_1_5_to_int_core_slave_ni_1_5_req;
  floo_rsp_t int_core_slave_ni_1_5_to_mesh_router_1_5_rsp;

  floo_req_t mesh_router_1_5_to_int_core_master_ni_1_5_req;
  floo_rsp_t int_core_master_ni_1_5_to_mesh_router_1_5_rsp;

  floo_req_t mesh_router_1_6_to_mesh_router_0_6_req;
  floo_rsp_t mesh_router_0_6_to_mesh_router_1_6_rsp;

  floo_req_t mesh_router_1_6_to_mesh_router_1_5_req;
  floo_rsp_t mesh_router_1_5_to_mesh_router_1_6_rsp;

  floo_req_t mesh_router_1_6_to_mesh_router_1_7_req;
  floo_rsp_t mesh_router_1_7_to_mesh_router_1_6_rsp;

  floo_req_t mesh_router_1_6_to_mesh_router_2_6_req;
  floo_rsp_t mesh_router_2_6_to_mesh_router_1_6_rsp;

  floo_req_t mesh_router_1_6_to_int_core_slave_ni_1_6_req;
  floo_rsp_t int_core_slave_ni_1_6_to_mesh_router_1_6_rsp;

  floo_req_t mesh_router_1_6_to_int_core_master_ni_1_6_req;
  floo_rsp_t int_core_master_ni_1_6_to_mesh_router_1_6_rsp;

  floo_req_t mesh_router_1_7_to_mesh_router_0_7_req;
  floo_rsp_t mesh_router_0_7_to_mesh_router_1_7_rsp;

  floo_req_t mesh_router_1_7_to_mesh_router_1_6_req;
  floo_rsp_t mesh_router_1_6_to_mesh_router_1_7_rsp;

  floo_req_t mesh_router_1_7_to_mesh_router_2_7_req;
  floo_rsp_t mesh_router_2_7_to_mesh_router_1_7_rsp;

  floo_req_t mesh_router_1_7_to_int_core_slave_ni_1_7_req;
  floo_rsp_t int_core_slave_ni_1_7_to_mesh_router_1_7_rsp;

  floo_req_t mesh_router_1_7_to_int_core_master_ni_1_7_req;
  floo_rsp_t int_core_master_ni_1_7_to_mesh_router_1_7_rsp;

  floo_req_t mesh_router_2_0_to_mesh_router_1_0_req;
  floo_rsp_t mesh_router_1_0_to_mesh_router_2_0_rsp;

  floo_req_t mesh_router_2_0_to_mesh_router_2_1_req;
  floo_rsp_t mesh_router_2_1_to_mesh_router_2_0_rsp;

  floo_req_t mesh_router_2_0_to_mesh_router_3_0_req;
  floo_rsp_t mesh_router_3_0_to_mesh_router_2_0_rsp;

  floo_req_t mesh_router_2_0_to_int_core_slave_ni_2_0_req;
  floo_rsp_t int_core_slave_ni_2_0_to_mesh_router_2_0_rsp;

  floo_req_t mesh_router_2_0_to_int_core_master_ni_2_0_req;
  floo_rsp_t int_core_master_ni_2_0_to_mesh_router_2_0_rsp;

  floo_req_t mesh_router_2_1_to_mesh_router_1_1_req;
  floo_rsp_t mesh_router_1_1_to_mesh_router_2_1_rsp;

  floo_req_t mesh_router_2_1_to_mesh_router_2_0_req;
  floo_rsp_t mesh_router_2_0_to_mesh_router_2_1_rsp;

  floo_req_t mesh_router_2_1_to_mesh_router_2_2_req;
  floo_rsp_t mesh_router_2_2_to_mesh_router_2_1_rsp;

  floo_req_t mesh_router_2_1_to_mesh_router_3_1_req;
  floo_rsp_t mesh_router_3_1_to_mesh_router_2_1_rsp;

  floo_req_t mesh_router_2_1_to_int_core_slave_ni_2_1_req;
  floo_rsp_t int_core_slave_ni_2_1_to_mesh_router_2_1_rsp;

  floo_req_t mesh_router_2_1_to_int_core_master_ni_2_1_req;
  floo_rsp_t int_core_master_ni_2_1_to_mesh_router_2_1_rsp;

  floo_req_t mesh_router_2_2_to_mesh_router_1_2_req;
  floo_rsp_t mesh_router_1_2_to_mesh_router_2_2_rsp;

  floo_req_t mesh_router_2_2_to_mesh_router_2_1_req;
  floo_rsp_t mesh_router_2_1_to_mesh_router_2_2_rsp;

  floo_req_t mesh_router_2_2_to_mesh_router_2_3_req;
  floo_rsp_t mesh_router_2_3_to_mesh_router_2_2_rsp;

  floo_req_t mesh_router_2_2_to_mesh_router_3_2_req;
  floo_rsp_t mesh_router_3_2_to_mesh_router_2_2_rsp;

  floo_req_t mesh_router_2_2_to_int_core_slave_ni_2_2_req;
  floo_rsp_t int_core_slave_ni_2_2_to_mesh_router_2_2_rsp;

  floo_req_t mesh_router_2_2_to_int_core_master_ni_2_2_req;
  floo_rsp_t int_core_master_ni_2_2_to_mesh_router_2_2_rsp;

  floo_req_t mesh_router_2_3_to_mesh_router_1_3_req;
  floo_rsp_t mesh_router_1_3_to_mesh_router_2_3_rsp;

  floo_req_t mesh_router_2_3_to_mesh_router_2_2_req;
  floo_rsp_t mesh_router_2_2_to_mesh_router_2_3_rsp;

  floo_req_t mesh_router_2_3_to_mesh_router_2_4_req;
  floo_rsp_t mesh_router_2_4_to_mesh_router_2_3_rsp;

  floo_req_t mesh_router_2_3_to_mesh_router_3_3_req;
  floo_rsp_t mesh_router_3_3_to_mesh_router_2_3_rsp;

  floo_req_t mesh_router_2_3_to_int_core_slave_ni_2_3_req;
  floo_rsp_t int_core_slave_ni_2_3_to_mesh_router_2_3_rsp;

  floo_req_t mesh_router_2_3_to_int_core_master_ni_2_3_req;
  floo_rsp_t int_core_master_ni_2_3_to_mesh_router_2_3_rsp;

  floo_req_t mesh_router_2_4_to_mesh_router_1_4_req;
  floo_rsp_t mesh_router_1_4_to_mesh_router_2_4_rsp;

  floo_req_t mesh_router_2_4_to_mesh_router_2_3_req;
  floo_rsp_t mesh_router_2_3_to_mesh_router_2_4_rsp;

  floo_req_t mesh_router_2_4_to_mesh_router_2_5_req;
  floo_rsp_t mesh_router_2_5_to_mesh_router_2_4_rsp;

  floo_req_t mesh_router_2_4_to_mesh_router_3_4_req;
  floo_rsp_t mesh_router_3_4_to_mesh_router_2_4_rsp;

  floo_req_t mesh_router_2_4_to_int_core_slave_ni_2_4_req;
  floo_rsp_t int_core_slave_ni_2_4_to_mesh_router_2_4_rsp;

  floo_req_t mesh_router_2_4_to_int_core_master_ni_2_4_req;
  floo_rsp_t int_core_master_ni_2_4_to_mesh_router_2_4_rsp;

  floo_req_t mesh_router_2_5_to_mesh_router_1_5_req;
  floo_rsp_t mesh_router_1_5_to_mesh_router_2_5_rsp;

  floo_req_t mesh_router_2_5_to_mesh_router_2_4_req;
  floo_rsp_t mesh_router_2_4_to_mesh_router_2_5_rsp;

  floo_req_t mesh_router_2_5_to_mesh_router_2_6_req;
  floo_rsp_t mesh_router_2_6_to_mesh_router_2_5_rsp;

  floo_req_t mesh_router_2_5_to_mesh_router_3_5_req;
  floo_rsp_t mesh_router_3_5_to_mesh_router_2_5_rsp;

  floo_req_t mesh_router_2_5_to_int_core_slave_ni_2_5_req;
  floo_rsp_t int_core_slave_ni_2_5_to_mesh_router_2_5_rsp;

  floo_req_t mesh_router_2_5_to_int_core_master_ni_2_5_req;
  floo_rsp_t int_core_master_ni_2_5_to_mesh_router_2_5_rsp;

  floo_req_t mesh_router_2_6_to_mesh_router_1_6_req;
  floo_rsp_t mesh_router_1_6_to_mesh_router_2_6_rsp;

  floo_req_t mesh_router_2_6_to_mesh_router_2_5_req;
  floo_rsp_t mesh_router_2_5_to_mesh_router_2_6_rsp;

  floo_req_t mesh_router_2_6_to_mesh_router_2_7_req;
  floo_rsp_t mesh_router_2_7_to_mesh_router_2_6_rsp;

  floo_req_t mesh_router_2_6_to_mesh_router_3_6_req;
  floo_rsp_t mesh_router_3_6_to_mesh_router_2_6_rsp;

  floo_req_t mesh_router_2_6_to_int_core_slave_ni_2_6_req;
  floo_rsp_t int_core_slave_ni_2_6_to_mesh_router_2_6_rsp;

  floo_req_t mesh_router_2_6_to_int_core_master_ni_2_6_req;
  floo_rsp_t int_core_master_ni_2_6_to_mesh_router_2_6_rsp;

  floo_req_t mesh_router_2_7_to_mesh_router_1_7_req;
  floo_rsp_t mesh_router_1_7_to_mesh_router_2_7_rsp;

  floo_req_t mesh_router_2_7_to_mesh_router_2_6_req;
  floo_rsp_t mesh_router_2_6_to_mesh_router_2_7_rsp;

  floo_req_t mesh_router_2_7_to_mesh_router_3_7_req;
  floo_rsp_t mesh_router_3_7_to_mesh_router_2_7_rsp;

  floo_req_t mesh_router_2_7_to_int_core_slave_ni_2_7_req;
  floo_rsp_t int_core_slave_ni_2_7_to_mesh_router_2_7_rsp;

  floo_req_t mesh_router_2_7_to_int_core_master_ni_2_7_req;
  floo_rsp_t int_core_master_ni_2_7_to_mesh_router_2_7_rsp;

  floo_req_t mesh_router_3_0_to_mesh_router_2_0_req;
  floo_rsp_t mesh_router_2_0_to_mesh_router_3_0_rsp;

  floo_req_t mesh_router_3_0_to_mesh_router_3_1_req;
  floo_rsp_t mesh_router_3_1_to_mesh_router_3_0_rsp;

  floo_req_t mesh_router_3_0_to_int_core_slave_ni_3_0_req;
  floo_rsp_t int_core_slave_ni_3_0_to_mesh_router_3_0_rsp;

  floo_req_t mesh_router_3_0_to_int_core_master_ni_3_0_req;
  floo_rsp_t int_core_master_ni_3_0_to_mesh_router_3_0_rsp;

  floo_req_t mesh_router_3_0_to_fp_core_slave_ni_0_0_req;
  floo_rsp_t fp_core_slave_ni_0_0_to_mesh_router_3_0_rsp;

  floo_req_t mesh_router_3_1_to_mesh_router_2_1_req;
  floo_rsp_t mesh_router_2_1_to_mesh_router_3_1_rsp;

  floo_req_t mesh_router_3_1_to_mesh_router_3_0_req;
  floo_rsp_t mesh_router_3_0_to_mesh_router_3_1_rsp;

  floo_req_t mesh_router_3_1_to_mesh_router_3_2_req;
  floo_rsp_t mesh_router_3_2_to_mesh_router_3_1_rsp;

  floo_req_t mesh_router_3_1_to_int_core_slave_ni_3_1_req;
  floo_rsp_t int_core_slave_ni_3_1_to_mesh_router_3_1_rsp;

  floo_req_t mesh_router_3_1_to_int_core_master_ni_3_1_req;
  floo_rsp_t int_core_master_ni_3_1_to_mesh_router_3_1_rsp;

  floo_req_t mesh_router_3_1_to_fp_core_slave_ni_0_1_req;
  floo_rsp_t fp_core_slave_ni_0_1_to_mesh_router_3_1_rsp;

  floo_req_t mesh_router_3_2_to_mesh_router_2_2_req;
  floo_rsp_t mesh_router_2_2_to_mesh_router_3_2_rsp;

  floo_req_t mesh_router_3_2_to_mesh_router_3_1_req;
  floo_rsp_t mesh_router_3_1_to_mesh_router_3_2_rsp;

  floo_req_t mesh_router_3_2_to_mesh_router_3_3_req;
  floo_rsp_t mesh_router_3_3_to_mesh_router_3_2_rsp;

  floo_req_t mesh_router_3_2_to_int_core_slave_ni_3_2_req;
  floo_rsp_t int_core_slave_ni_3_2_to_mesh_router_3_2_rsp;

  floo_req_t mesh_router_3_2_to_int_core_master_ni_3_2_req;
  floo_rsp_t int_core_master_ni_3_2_to_mesh_router_3_2_rsp;

  floo_req_t mesh_router_3_2_to_fp_core_slave_ni_0_2_req;
  floo_rsp_t fp_core_slave_ni_0_2_to_mesh_router_3_2_rsp;

  floo_req_t mesh_router_3_3_to_mesh_router_2_3_req;
  floo_rsp_t mesh_router_2_3_to_mesh_router_3_3_rsp;

  floo_req_t mesh_router_3_3_to_mesh_router_3_2_req;
  floo_rsp_t mesh_router_3_2_to_mesh_router_3_3_rsp;

  floo_req_t mesh_router_3_3_to_mesh_router_3_4_req;
  floo_rsp_t mesh_router_3_4_to_mesh_router_3_3_rsp;

  floo_req_t mesh_router_3_3_to_int_core_slave_ni_3_3_req;
  floo_rsp_t int_core_slave_ni_3_3_to_mesh_router_3_3_rsp;

  floo_req_t mesh_router_3_3_to_int_core_master_ni_3_3_req;
  floo_rsp_t int_core_master_ni_3_3_to_mesh_router_3_3_rsp;

  floo_req_t mesh_router_3_3_to_fp_core_slave_ni_0_3_req;
  floo_rsp_t fp_core_slave_ni_0_3_to_mesh_router_3_3_rsp;

  floo_req_t mesh_router_3_4_to_mesh_router_2_4_req;
  floo_rsp_t mesh_router_2_4_to_mesh_router_3_4_rsp;

  floo_req_t mesh_router_3_4_to_mesh_router_3_3_req;
  floo_rsp_t mesh_router_3_3_to_mesh_router_3_4_rsp;

  floo_req_t mesh_router_3_4_to_mesh_router_3_5_req;
  floo_rsp_t mesh_router_3_5_to_mesh_router_3_4_rsp;

  floo_req_t mesh_router_3_4_to_int_core_slave_ni_3_4_req;
  floo_rsp_t int_core_slave_ni_3_4_to_mesh_router_3_4_rsp;

  floo_req_t mesh_router_3_4_to_int_core_master_ni_3_4_req;
  floo_rsp_t int_core_master_ni_3_4_to_mesh_router_3_4_rsp;

  floo_req_t mesh_router_3_4_to_fp_core_slave_ni_0_4_req;
  floo_rsp_t fp_core_slave_ni_0_4_to_mesh_router_3_4_rsp;

  floo_req_t mesh_router_3_5_to_mesh_router_2_5_req;
  floo_rsp_t mesh_router_2_5_to_mesh_router_3_5_rsp;

  floo_req_t mesh_router_3_5_to_mesh_router_3_4_req;
  floo_rsp_t mesh_router_3_4_to_mesh_router_3_5_rsp;

  floo_req_t mesh_router_3_5_to_mesh_router_3_6_req;
  floo_rsp_t mesh_router_3_6_to_mesh_router_3_5_rsp;

  floo_req_t mesh_router_3_5_to_int_core_slave_ni_3_5_req;
  floo_rsp_t int_core_slave_ni_3_5_to_mesh_router_3_5_rsp;

  floo_req_t mesh_router_3_5_to_int_core_master_ni_3_5_req;
  floo_rsp_t int_core_master_ni_3_5_to_mesh_router_3_5_rsp;

  floo_req_t mesh_router_3_5_to_fp_core_slave_ni_0_5_req;
  floo_rsp_t fp_core_slave_ni_0_5_to_mesh_router_3_5_rsp;

  floo_req_t mesh_router_3_6_to_mesh_router_2_6_req;
  floo_rsp_t mesh_router_2_6_to_mesh_router_3_6_rsp;

  floo_req_t mesh_router_3_6_to_mesh_router_3_5_req;
  floo_rsp_t mesh_router_3_5_to_mesh_router_3_6_rsp;

  floo_req_t mesh_router_3_6_to_mesh_router_3_7_req;
  floo_rsp_t mesh_router_3_7_to_mesh_router_3_6_rsp;

  floo_req_t mesh_router_3_6_to_int_core_slave_ni_3_6_req;
  floo_rsp_t int_core_slave_ni_3_6_to_mesh_router_3_6_rsp;

  floo_req_t mesh_router_3_6_to_int_core_master_ni_3_6_req;
  floo_rsp_t int_core_master_ni_3_6_to_mesh_router_3_6_rsp;

  floo_req_t mesh_router_3_6_to_fp_core_slave_ni_0_6_req;
  floo_rsp_t fp_core_slave_ni_0_6_to_mesh_router_3_6_rsp;

  floo_req_t mesh_router_3_7_to_mesh_router_2_7_req;
  floo_rsp_t mesh_router_2_7_to_mesh_router_3_7_rsp;

  floo_req_t mesh_router_3_7_to_mesh_router_3_6_req;
  floo_rsp_t mesh_router_3_6_to_mesh_router_3_7_rsp;

  floo_req_t mesh_router_3_7_to_int_core_slave_ni_3_7_req;
  floo_rsp_t int_core_slave_ni_3_7_to_mesh_router_3_7_rsp;

  floo_req_t mesh_router_3_7_to_int_core_master_ni_3_7_req;
  floo_rsp_t int_core_master_ni_3_7_to_mesh_router_3_7_rsp;

  floo_req_t mesh_router_3_7_to_fp_core_slave_ni_0_7_req;
  floo_rsp_t fp_core_slave_ni_0_7_to_mesh_router_3_7_rsp;

  floo_req_t cpu_master_ni_to_central_router_req;
  floo_rsp_t central_router_to_cpu_master_ni_rsp;

  floo_req_t dm_master_ni_to_central_router_req;
  floo_rsp_t central_router_to_dm_master_ni_rsp;

  floo_req_t d2d0_master_ni_to_central_router_req;
  floo_rsp_t central_router_to_d2d0_master_ni_rsp;

  floo_req_t d2d1_master_ni_to_central_router_req;
  floo_rsp_t central_router_to_d2d1_master_ni_rsp;

  floo_req_t int_core_master_ni_0_0_to_mesh_router_0_0_req;
  floo_rsp_t mesh_router_0_0_to_int_core_master_ni_0_0_rsp;

  floo_req_t int_core_master_ni_0_1_to_mesh_router_0_1_req;
  floo_rsp_t mesh_router_0_1_to_int_core_master_ni_0_1_rsp;

  floo_req_t int_core_master_ni_0_2_to_mesh_router_0_2_req;
  floo_rsp_t mesh_router_0_2_to_int_core_master_ni_0_2_rsp;

  floo_req_t int_core_master_ni_0_3_to_mesh_router_0_3_req;
  floo_rsp_t mesh_router_0_3_to_int_core_master_ni_0_3_rsp;

  floo_req_t int_core_master_ni_0_4_to_mesh_router_0_4_req;
  floo_rsp_t mesh_router_0_4_to_int_core_master_ni_0_4_rsp;

  floo_req_t int_core_master_ni_0_5_to_mesh_router_0_5_req;
  floo_rsp_t mesh_router_0_5_to_int_core_master_ni_0_5_rsp;

  floo_req_t int_core_master_ni_0_6_to_mesh_router_0_6_req;
  floo_rsp_t mesh_router_0_6_to_int_core_master_ni_0_6_rsp;

  floo_req_t int_core_master_ni_0_7_to_mesh_router_0_7_req;
  floo_rsp_t mesh_router_0_7_to_int_core_master_ni_0_7_rsp;

  floo_req_t int_core_master_ni_1_0_to_mesh_router_1_0_req;
  floo_rsp_t mesh_router_1_0_to_int_core_master_ni_1_0_rsp;

  floo_req_t int_core_master_ni_1_1_to_mesh_router_1_1_req;
  floo_rsp_t mesh_router_1_1_to_int_core_master_ni_1_1_rsp;

  floo_req_t int_core_master_ni_1_2_to_mesh_router_1_2_req;
  floo_rsp_t mesh_router_1_2_to_int_core_master_ni_1_2_rsp;

  floo_req_t int_core_master_ni_1_3_to_mesh_router_1_3_req;
  floo_rsp_t mesh_router_1_3_to_int_core_master_ni_1_3_rsp;

  floo_req_t int_core_master_ni_1_4_to_mesh_router_1_4_req;
  floo_rsp_t mesh_router_1_4_to_int_core_master_ni_1_4_rsp;

  floo_req_t int_core_master_ni_1_5_to_mesh_router_1_5_req;
  floo_rsp_t mesh_router_1_5_to_int_core_master_ni_1_5_rsp;

  floo_req_t int_core_master_ni_1_6_to_mesh_router_1_6_req;
  floo_rsp_t mesh_router_1_6_to_int_core_master_ni_1_6_rsp;

  floo_req_t int_core_master_ni_1_7_to_mesh_router_1_7_req;
  floo_rsp_t mesh_router_1_7_to_int_core_master_ni_1_7_rsp;

  floo_req_t int_core_master_ni_2_0_to_mesh_router_2_0_req;
  floo_rsp_t mesh_router_2_0_to_int_core_master_ni_2_0_rsp;

  floo_req_t int_core_master_ni_2_1_to_mesh_router_2_1_req;
  floo_rsp_t mesh_router_2_1_to_int_core_master_ni_2_1_rsp;

  floo_req_t int_core_master_ni_2_2_to_mesh_router_2_2_req;
  floo_rsp_t mesh_router_2_2_to_int_core_master_ni_2_2_rsp;

  floo_req_t int_core_master_ni_2_3_to_mesh_router_2_3_req;
  floo_rsp_t mesh_router_2_3_to_int_core_master_ni_2_3_rsp;

  floo_req_t int_core_master_ni_2_4_to_mesh_router_2_4_req;
  floo_rsp_t mesh_router_2_4_to_int_core_master_ni_2_4_rsp;

  floo_req_t int_core_master_ni_2_5_to_mesh_router_2_5_req;
  floo_rsp_t mesh_router_2_5_to_int_core_master_ni_2_5_rsp;

  floo_req_t int_core_master_ni_2_6_to_mesh_router_2_6_req;
  floo_rsp_t mesh_router_2_6_to_int_core_master_ni_2_6_rsp;

  floo_req_t int_core_master_ni_2_7_to_mesh_router_2_7_req;
  floo_rsp_t mesh_router_2_7_to_int_core_master_ni_2_7_rsp;

  floo_req_t int_core_master_ni_3_0_to_mesh_router_3_0_req;
  floo_rsp_t mesh_router_3_0_to_int_core_master_ni_3_0_rsp;

  floo_req_t int_core_master_ni_3_1_to_mesh_router_3_1_req;
  floo_rsp_t mesh_router_3_1_to_int_core_master_ni_3_1_rsp;

  floo_req_t int_core_master_ni_3_2_to_mesh_router_3_2_req;
  floo_rsp_t mesh_router_3_2_to_int_core_master_ni_3_2_rsp;

  floo_req_t int_core_master_ni_3_3_to_mesh_router_3_3_req;
  floo_rsp_t mesh_router_3_3_to_int_core_master_ni_3_3_rsp;

  floo_req_t int_core_master_ni_3_4_to_mesh_router_3_4_req;
  floo_rsp_t mesh_router_3_4_to_int_core_master_ni_3_4_rsp;

  floo_req_t int_core_master_ni_3_5_to_mesh_router_3_5_req;
  floo_rsp_t mesh_router_3_5_to_int_core_master_ni_3_5_rsp;

  floo_req_t int_core_master_ni_3_6_to_mesh_router_3_6_req;
  floo_rsp_t mesh_router_3_6_to_int_core_master_ni_3_6_rsp;

  floo_req_t int_core_master_ni_3_7_to_mesh_router_3_7_req;
  floo_rsp_t mesh_router_3_7_to_int_core_master_ni_3_7_rsp;

  floo_req_t llc_slave_ni_to_central_router_req;
  floo_rsp_t central_router_to_llc_slave_ni_rsp;

  floo_req_t rom_slave_ni_to_central_router_req;
  floo_rsp_t central_router_to_rom_slave_ni_rsp;

  floo_req_t dm_slave_ni_to_central_router_req;
  floo_rsp_t central_router_to_dm_slave_ni_rsp;

  floo_req_t clint_slave_ni_to_central_router_req;
  floo_rsp_t central_router_to_clint_slave_ni_rsp;

  floo_req_t plic_slave_ni_to_central_router_req;
  floo_rsp_t central_router_to_plic_slave_ni_rsp;

  floo_req_t uart_slave_ni_to_central_router_req;
  floo_rsp_t central_router_to_uart_slave_ni_rsp;

  floo_req_t timer_slave_ni_to_central_router_req;
  floo_rsp_t central_router_to_timer_slave_ni_rsp;

  floo_req_t sys_dco_slave_ni_to_central_router_req;
  floo_rsp_t central_router_to_sys_dco_slave_ni_rsp;

  floo_req_t sl_cfg_slave_ni_to_central_router_req;
  floo_rsp_t central_router_to_sl_cfg_slave_ni_rsp;

  floo_req_t d2d0_cfg_slave_ni_to_central_router_req;
  floo_rsp_t central_router_to_d2d0_cfg_slave_ni_rsp;

  floo_req_t d2d1_cfg_slave_ni_to_central_router_req;
  floo_rsp_t central_router_to_d2d1_cfg_slave_ni_rsp;

  floo_req_t llc_cfg_slave_ni_to_central_router_req;
  floo_rsp_t central_router_to_llc_cfg_slave_ni_rsp;

  floo_req_t d2d0_slave_ni_to_central_router_req;
  floo_rsp_t central_router_to_d2d0_slave_ni_rsp;

  floo_req_t d2d1_slave_ni_to_central_router_req;
  floo_rsp_t central_router_to_d2d1_slave_ni_rsp;

  floo_req_t int_core_slave_ni_0_0_to_mesh_router_0_0_req;
  floo_rsp_t mesh_router_0_0_to_int_core_slave_ni_0_0_rsp;

  floo_req_t int_core_slave_ni_0_1_to_mesh_router_0_1_req;
  floo_rsp_t mesh_router_0_1_to_int_core_slave_ni_0_1_rsp;

  floo_req_t int_core_slave_ni_0_2_to_mesh_router_0_2_req;
  floo_rsp_t mesh_router_0_2_to_int_core_slave_ni_0_2_rsp;

  floo_req_t int_core_slave_ni_0_3_to_mesh_router_0_3_req;
  floo_rsp_t mesh_router_0_3_to_int_core_slave_ni_0_3_rsp;

  floo_req_t int_core_slave_ni_0_4_to_mesh_router_0_4_req;
  floo_rsp_t mesh_router_0_4_to_int_core_slave_ni_0_4_rsp;

  floo_req_t int_core_slave_ni_0_5_to_mesh_router_0_5_req;
  floo_rsp_t mesh_router_0_5_to_int_core_slave_ni_0_5_rsp;

  floo_req_t int_core_slave_ni_0_6_to_mesh_router_0_6_req;
  floo_rsp_t mesh_router_0_6_to_int_core_slave_ni_0_6_rsp;

  floo_req_t int_core_slave_ni_0_7_to_mesh_router_0_7_req;
  floo_rsp_t mesh_router_0_7_to_int_core_slave_ni_0_7_rsp;

  floo_req_t int_core_slave_ni_1_0_to_mesh_router_1_0_req;
  floo_rsp_t mesh_router_1_0_to_int_core_slave_ni_1_0_rsp;

  floo_req_t int_core_slave_ni_1_1_to_mesh_router_1_1_req;
  floo_rsp_t mesh_router_1_1_to_int_core_slave_ni_1_1_rsp;

  floo_req_t int_core_slave_ni_1_2_to_mesh_router_1_2_req;
  floo_rsp_t mesh_router_1_2_to_int_core_slave_ni_1_2_rsp;

  floo_req_t int_core_slave_ni_1_3_to_mesh_router_1_3_req;
  floo_rsp_t mesh_router_1_3_to_int_core_slave_ni_1_3_rsp;

  floo_req_t int_core_slave_ni_1_4_to_mesh_router_1_4_req;
  floo_rsp_t mesh_router_1_4_to_int_core_slave_ni_1_4_rsp;

  floo_req_t int_core_slave_ni_1_5_to_mesh_router_1_5_req;
  floo_rsp_t mesh_router_1_5_to_int_core_slave_ni_1_5_rsp;

  floo_req_t int_core_slave_ni_1_6_to_mesh_router_1_6_req;
  floo_rsp_t mesh_router_1_6_to_int_core_slave_ni_1_6_rsp;

  floo_req_t int_core_slave_ni_1_7_to_mesh_router_1_7_req;
  floo_rsp_t mesh_router_1_7_to_int_core_slave_ni_1_7_rsp;

  floo_req_t int_core_slave_ni_2_0_to_mesh_router_2_0_req;
  floo_rsp_t mesh_router_2_0_to_int_core_slave_ni_2_0_rsp;

  floo_req_t int_core_slave_ni_2_1_to_mesh_router_2_1_req;
  floo_rsp_t mesh_router_2_1_to_int_core_slave_ni_2_1_rsp;

  floo_req_t int_core_slave_ni_2_2_to_mesh_router_2_2_req;
  floo_rsp_t mesh_router_2_2_to_int_core_slave_ni_2_2_rsp;

  floo_req_t int_core_slave_ni_2_3_to_mesh_router_2_3_req;
  floo_rsp_t mesh_router_2_3_to_int_core_slave_ni_2_3_rsp;

  floo_req_t int_core_slave_ni_2_4_to_mesh_router_2_4_req;
  floo_rsp_t mesh_router_2_4_to_int_core_slave_ni_2_4_rsp;

  floo_req_t int_core_slave_ni_2_5_to_mesh_router_2_5_req;
  floo_rsp_t mesh_router_2_5_to_int_core_slave_ni_2_5_rsp;

  floo_req_t int_core_slave_ni_2_6_to_mesh_router_2_6_req;
  floo_rsp_t mesh_router_2_6_to_int_core_slave_ni_2_6_rsp;

  floo_req_t int_core_slave_ni_2_7_to_mesh_router_2_7_req;
  floo_rsp_t mesh_router_2_7_to_int_core_slave_ni_2_7_rsp;

  floo_req_t int_core_slave_ni_3_0_to_mesh_router_3_0_req;
  floo_rsp_t mesh_router_3_0_to_int_core_slave_ni_3_0_rsp;

  floo_req_t int_core_slave_ni_3_1_to_mesh_router_3_1_req;
  floo_rsp_t mesh_router_3_1_to_int_core_slave_ni_3_1_rsp;

  floo_req_t int_core_slave_ni_3_2_to_mesh_router_3_2_req;
  floo_rsp_t mesh_router_3_2_to_int_core_slave_ni_3_2_rsp;

  floo_req_t int_core_slave_ni_3_3_to_mesh_router_3_3_req;
  floo_rsp_t mesh_router_3_3_to_int_core_slave_ni_3_3_rsp;

  floo_req_t int_core_slave_ni_3_4_to_mesh_router_3_4_req;
  floo_rsp_t mesh_router_3_4_to_int_core_slave_ni_3_4_rsp;

  floo_req_t int_core_slave_ni_3_5_to_mesh_router_3_5_req;
  floo_rsp_t mesh_router_3_5_to_int_core_slave_ni_3_5_rsp;

  floo_req_t int_core_slave_ni_3_6_to_mesh_router_3_6_req;
  floo_rsp_t mesh_router_3_6_to_int_core_slave_ni_3_6_rsp;

  floo_req_t int_core_slave_ni_3_7_to_mesh_router_3_7_req;
  floo_rsp_t mesh_router_3_7_to_int_core_slave_ni_3_7_rsp;

  floo_req_t fp_core_slave_ni_0_0_to_mesh_router_3_0_req;
  floo_rsp_t mesh_router_3_0_to_fp_core_slave_ni_0_0_rsp;

  floo_req_t fp_core_slave_ni_0_1_to_mesh_router_3_1_req;
  floo_rsp_t mesh_router_3_1_to_fp_core_slave_ni_0_1_rsp;

  floo_req_t fp_core_slave_ni_0_2_to_mesh_router_3_2_req;
  floo_rsp_t mesh_router_3_2_to_fp_core_slave_ni_0_2_rsp;

  floo_req_t fp_core_slave_ni_0_3_to_mesh_router_3_3_req;
  floo_rsp_t mesh_router_3_3_to_fp_core_slave_ni_0_3_rsp;

  floo_req_t fp_core_slave_ni_0_4_to_mesh_router_3_4_req;
  floo_rsp_t mesh_router_3_4_to_fp_core_slave_ni_0_4_rsp;

  floo_req_t fp_core_slave_ni_0_5_to_mesh_router_3_5_req;
  floo_rsp_t mesh_router_3_5_to_fp_core_slave_ni_0_5_rsp;

  floo_req_t fp_core_slave_ni_0_6_to_mesh_router_3_6_req;
  floo_rsp_t mesh_router_3_6_to_fp_core_slave_ni_0_6_rsp;

  floo_req_t fp_core_slave_ni_0_7_to_mesh_router_3_7_req;
  floo_rsp_t mesh_router_3_7_to_fp_core_slave_ni_0_7_rsp;

  floo_req_t sp_slave_ni_to_central_router_req;
  floo_rsp_t central_router_to_sp_slave_ni_rsp;

  floo_req_t aux_slot_slave_ni_to_central_router_req;
  floo_rsp_t central_router_to_aux_slot_slave_ni_rsp;



  localparam id_t CPU_MASTER_NI_ID = id_t'(0);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b0, 1'b1)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) cpu_master_ni (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i (cpu_master_mst_req_i),
      .axi_in_rsp_o (cpu_master_mst_rsp_o),
      .axi_out_req_o(),
      .axi_out_rsp_i('0),
      .id_i         (CPU_MASTER_NI_ID),
      .route_table_i('0),
      .floo_req_o   (cpu_master_ni_to_central_router_req),
      .floo_rsp_i   (central_router_to_cpu_master_ni_rsp),
      .floo_req_i   (central_router_to_cpu_master_ni_req),
      .floo_rsp_o   (cpu_master_ni_to_central_router_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t DM_MASTER_NI_ID = id_t'(1);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b0, 1'b1)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) dm_master_ni (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i (dm_master_mst_req_i),
      .axi_in_rsp_o (dm_master_mst_rsp_o),
      .axi_out_req_o(),
      .axi_out_rsp_i('0),
      .id_i         (DM_MASTER_NI_ID),
      .route_table_i('0),
      .floo_req_o   (dm_master_ni_to_central_router_req),
      .floo_rsp_i   (central_router_to_dm_master_ni_rsp),
      .floo_req_i   (central_router_to_dm_master_ni_req),
      .floo_rsp_o   (dm_master_ni_to_central_router_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t D2D0_MASTER_NI_ID = id_t'(2);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b0, 1'b1)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) d2d0_master_ni (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i (d2d0_master_mst_req_i),
      .axi_in_rsp_o (d2d0_master_mst_rsp_o),
      .axi_out_req_o(),
      .axi_out_rsp_i('0),
      .id_i         (D2D0_MASTER_NI_ID),
      .route_table_i('0),
      .floo_req_o   (d2d0_master_ni_to_central_router_req),
      .floo_rsp_i   (central_router_to_d2d0_master_ni_rsp),
      .floo_req_i   (central_router_to_d2d0_master_ni_req),
      .floo_rsp_o   (d2d0_master_ni_to_central_router_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t D2D1_MASTER_NI_ID = id_t'(3);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b0, 1'b1)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) d2d1_master_ni (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i (d2d1_master_mst_req_i),
      .axi_in_rsp_o (d2d1_master_mst_rsp_o),
      .axi_out_req_o(),
      .axi_out_rsp_i('0),
      .id_i         (D2D1_MASTER_NI_ID),
      .route_table_i('0),
      .floo_req_o   (d2d1_master_ni_to_central_router_req),
      .floo_rsp_i   (central_router_to_d2d1_master_ni_rsp),
      .floo_req_i   (central_router_to_d2d1_master_ni_req),
      .floo_rsp_o   (d2d1_master_ni_to_central_router_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_MASTER_NI_0_0_ID = id_t'(4);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b0, 1'b1)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_master_ni_0_0 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i (int_core_master_mst_req_i[0][0]),
      .axi_in_rsp_o (int_core_master_mst_rsp_o[0][0]),
      .axi_out_req_o(),
      .axi_out_rsp_i('0),
      .id_i         (INT_CORE_MASTER_NI_0_0_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_master_ni_0_0_to_mesh_router_0_0_req),
      .floo_rsp_i   (mesh_router_0_0_to_int_core_master_ni_0_0_rsp),
      .floo_req_i   (mesh_router_0_0_to_int_core_master_ni_0_0_req),
      .floo_rsp_o   (int_core_master_ni_0_0_to_mesh_router_0_0_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_MASTER_NI_0_1_ID = id_t'(5);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b0, 1'b1)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_master_ni_0_1 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i (int_core_master_mst_req_i[0][1]),
      .axi_in_rsp_o (int_core_master_mst_rsp_o[0][1]),
      .axi_out_req_o(),
      .axi_out_rsp_i('0),
      .id_i         (INT_CORE_MASTER_NI_0_1_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_master_ni_0_1_to_mesh_router_0_1_req),
      .floo_rsp_i   (mesh_router_0_1_to_int_core_master_ni_0_1_rsp),
      .floo_req_i   (mesh_router_0_1_to_int_core_master_ni_0_1_req),
      .floo_rsp_o   (int_core_master_ni_0_1_to_mesh_router_0_1_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_MASTER_NI_0_2_ID = id_t'(6);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b0, 1'b1)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_master_ni_0_2 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i (int_core_master_mst_req_i[0][2]),
      .axi_in_rsp_o (int_core_master_mst_rsp_o[0][2]),
      .axi_out_req_o(),
      .axi_out_rsp_i('0),
      .id_i         (INT_CORE_MASTER_NI_0_2_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_master_ni_0_2_to_mesh_router_0_2_req),
      .floo_rsp_i   (mesh_router_0_2_to_int_core_master_ni_0_2_rsp),
      .floo_req_i   (mesh_router_0_2_to_int_core_master_ni_0_2_req),
      .floo_rsp_o   (int_core_master_ni_0_2_to_mesh_router_0_2_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_MASTER_NI_0_3_ID = id_t'(7);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b0, 1'b1)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_master_ni_0_3 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i (int_core_master_mst_req_i[0][3]),
      .axi_in_rsp_o (int_core_master_mst_rsp_o[0][3]),
      .axi_out_req_o(),
      .axi_out_rsp_i('0),
      .id_i         (INT_CORE_MASTER_NI_0_3_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_master_ni_0_3_to_mesh_router_0_3_req),
      .floo_rsp_i   (mesh_router_0_3_to_int_core_master_ni_0_3_rsp),
      .floo_req_i   (mesh_router_0_3_to_int_core_master_ni_0_3_req),
      .floo_rsp_o   (int_core_master_ni_0_3_to_mesh_router_0_3_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_MASTER_NI_0_4_ID = id_t'(8);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b0, 1'b1)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_master_ni_0_4 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i (int_core_master_mst_req_i[0][4]),
      .axi_in_rsp_o (int_core_master_mst_rsp_o[0][4]),
      .axi_out_req_o(),
      .axi_out_rsp_i('0),
      .id_i         (INT_CORE_MASTER_NI_0_4_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_master_ni_0_4_to_mesh_router_0_4_req),
      .floo_rsp_i   (mesh_router_0_4_to_int_core_master_ni_0_4_rsp),
      .floo_req_i   (mesh_router_0_4_to_int_core_master_ni_0_4_req),
      .floo_rsp_o   (int_core_master_ni_0_4_to_mesh_router_0_4_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_MASTER_NI_0_5_ID = id_t'(9);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b0, 1'b1)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_master_ni_0_5 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i (int_core_master_mst_req_i[0][5]),
      .axi_in_rsp_o (int_core_master_mst_rsp_o[0][5]),
      .axi_out_req_o(),
      .axi_out_rsp_i('0),
      .id_i         (INT_CORE_MASTER_NI_0_5_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_master_ni_0_5_to_mesh_router_0_5_req),
      .floo_rsp_i   (mesh_router_0_5_to_int_core_master_ni_0_5_rsp),
      .floo_req_i   (mesh_router_0_5_to_int_core_master_ni_0_5_req),
      .floo_rsp_o   (int_core_master_ni_0_5_to_mesh_router_0_5_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_MASTER_NI_0_6_ID = id_t'(10);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b0, 1'b1)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_master_ni_0_6 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i (int_core_master_mst_req_i[0][6]),
      .axi_in_rsp_o (int_core_master_mst_rsp_o[0][6]),
      .axi_out_req_o(),
      .axi_out_rsp_i('0),
      .id_i         (INT_CORE_MASTER_NI_0_6_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_master_ni_0_6_to_mesh_router_0_6_req),
      .floo_rsp_i   (mesh_router_0_6_to_int_core_master_ni_0_6_rsp),
      .floo_req_i   (mesh_router_0_6_to_int_core_master_ni_0_6_req),
      .floo_rsp_o   (int_core_master_ni_0_6_to_mesh_router_0_6_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_MASTER_NI_0_7_ID = id_t'(11);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b0, 1'b1)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_master_ni_0_7 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i (int_core_master_mst_req_i[0][7]),
      .axi_in_rsp_o (int_core_master_mst_rsp_o[0][7]),
      .axi_out_req_o(),
      .axi_out_rsp_i('0),
      .id_i         (INT_CORE_MASTER_NI_0_7_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_master_ni_0_7_to_mesh_router_0_7_req),
      .floo_rsp_i   (mesh_router_0_7_to_int_core_master_ni_0_7_rsp),
      .floo_req_i   (mesh_router_0_7_to_int_core_master_ni_0_7_req),
      .floo_rsp_o   (int_core_master_ni_0_7_to_mesh_router_0_7_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_MASTER_NI_1_0_ID = id_t'(12);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b0, 1'b1)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_master_ni_1_0 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i (int_core_master_mst_req_i[1][0]),
      .axi_in_rsp_o (int_core_master_mst_rsp_o[1][0]),
      .axi_out_req_o(),
      .axi_out_rsp_i('0),
      .id_i         (INT_CORE_MASTER_NI_1_0_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_master_ni_1_0_to_mesh_router_1_0_req),
      .floo_rsp_i   (mesh_router_1_0_to_int_core_master_ni_1_0_rsp),
      .floo_req_i   (mesh_router_1_0_to_int_core_master_ni_1_0_req),
      .floo_rsp_o   (int_core_master_ni_1_0_to_mesh_router_1_0_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_MASTER_NI_1_1_ID = id_t'(13);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b0, 1'b1)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_master_ni_1_1 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i (int_core_master_mst_req_i[1][1]),
      .axi_in_rsp_o (int_core_master_mst_rsp_o[1][1]),
      .axi_out_req_o(),
      .axi_out_rsp_i('0),
      .id_i         (INT_CORE_MASTER_NI_1_1_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_master_ni_1_1_to_mesh_router_1_1_req),
      .floo_rsp_i   (mesh_router_1_1_to_int_core_master_ni_1_1_rsp),
      .floo_req_i   (mesh_router_1_1_to_int_core_master_ni_1_1_req),
      .floo_rsp_o   (int_core_master_ni_1_1_to_mesh_router_1_1_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_MASTER_NI_1_2_ID = id_t'(14);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b0, 1'b1)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_master_ni_1_2 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i (int_core_master_mst_req_i[1][2]),
      .axi_in_rsp_o (int_core_master_mst_rsp_o[1][2]),
      .axi_out_req_o(),
      .axi_out_rsp_i('0),
      .id_i         (INT_CORE_MASTER_NI_1_2_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_master_ni_1_2_to_mesh_router_1_2_req),
      .floo_rsp_i   (mesh_router_1_2_to_int_core_master_ni_1_2_rsp),
      .floo_req_i   (mesh_router_1_2_to_int_core_master_ni_1_2_req),
      .floo_rsp_o   (int_core_master_ni_1_2_to_mesh_router_1_2_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_MASTER_NI_1_3_ID = id_t'(15);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b0, 1'b1)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_master_ni_1_3 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i (int_core_master_mst_req_i[1][3]),
      .axi_in_rsp_o (int_core_master_mst_rsp_o[1][3]),
      .axi_out_req_o(),
      .axi_out_rsp_i('0),
      .id_i         (INT_CORE_MASTER_NI_1_3_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_master_ni_1_3_to_mesh_router_1_3_req),
      .floo_rsp_i   (mesh_router_1_3_to_int_core_master_ni_1_3_rsp),
      .floo_req_i   (mesh_router_1_3_to_int_core_master_ni_1_3_req),
      .floo_rsp_o   (int_core_master_ni_1_3_to_mesh_router_1_3_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_MASTER_NI_1_4_ID = id_t'(16);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b0, 1'b1)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_master_ni_1_4 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i (int_core_master_mst_req_i[1][4]),
      .axi_in_rsp_o (int_core_master_mst_rsp_o[1][4]),
      .axi_out_req_o(),
      .axi_out_rsp_i('0),
      .id_i         (INT_CORE_MASTER_NI_1_4_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_master_ni_1_4_to_mesh_router_1_4_req),
      .floo_rsp_i   (mesh_router_1_4_to_int_core_master_ni_1_4_rsp),
      .floo_req_i   (mesh_router_1_4_to_int_core_master_ni_1_4_req),
      .floo_rsp_o   (int_core_master_ni_1_4_to_mesh_router_1_4_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_MASTER_NI_1_5_ID = id_t'(17);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b0, 1'b1)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_master_ni_1_5 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i (int_core_master_mst_req_i[1][5]),
      .axi_in_rsp_o (int_core_master_mst_rsp_o[1][5]),
      .axi_out_req_o(),
      .axi_out_rsp_i('0),
      .id_i         (INT_CORE_MASTER_NI_1_5_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_master_ni_1_5_to_mesh_router_1_5_req),
      .floo_rsp_i   (mesh_router_1_5_to_int_core_master_ni_1_5_rsp),
      .floo_req_i   (mesh_router_1_5_to_int_core_master_ni_1_5_req),
      .floo_rsp_o   (int_core_master_ni_1_5_to_mesh_router_1_5_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_MASTER_NI_1_6_ID = id_t'(18);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b0, 1'b1)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_master_ni_1_6 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i (int_core_master_mst_req_i[1][6]),
      .axi_in_rsp_o (int_core_master_mst_rsp_o[1][6]),
      .axi_out_req_o(),
      .axi_out_rsp_i('0),
      .id_i         (INT_CORE_MASTER_NI_1_6_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_master_ni_1_6_to_mesh_router_1_6_req),
      .floo_rsp_i   (mesh_router_1_6_to_int_core_master_ni_1_6_rsp),
      .floo_req_i   (mesh_router_1_6_to_int_core_master_ni_1_6_req),
      .floo_rsp_o   (int_core_master_ni_1_6_to_mesh_router_1_6_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_MASTER_NI_1_7_ID = id_t'(19);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b0, 1'b1)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_master_ni_1_7 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i (int_core_master_mst_req_i[1][7]),
      .axi_in_rsp_o (int_core_master_mst_rsp_o[1][7]),
      .axi_out_req_o(),
      .axi_out_rsp_i('0),
      .id_i         (INT_CORE_MASTER_NI_1_7_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_master_ni_1_7_to_mesh_router_1_7_req),
      .floo_rsp_i   (mesh_router_1_7_to_int_core_master_ni_1_7_rsp),
      .floo_req_i   (mesh_router_1_7_to_int_core_master_ni_1_7_req),
      .floo_rsp_o   (int_core_master_ni_1_7_to_mesh_router_1_7_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_MASTER_NI_2_0_ID = id_t'(20);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b0, 1'b1)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_master_ni_2_0 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i (int_core_master_mst_req_i[2][0]),
      .axi_in_rsp_o (int_core_master_mst_rsp_o[2][0]),
      .axi_out_req_o(),
      .axi_out_rsp_i('0),
      .id_i         (INT_CORE_MASTER_NI_2_0_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_master_ni_2_0_to_mesh_router_2_0_req),
      .floo_rsp_i   (mesh_router_2_0_to_int_core_master_ni_2_0_rsp),
      .floo_req_i   (mesh_router_2_0_to_int_core_master_ni_2_0_req),
      .floo_rsp_o   (int_core_master_ni_2_0_to_mesh_router_2_0_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_MASTER_NI_2_1_ID = id_t'(21);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b0, 1'b1)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_master_ni_2_1 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i (int_core_master_mst_req_i[2][1]),
      .axi_in_rsp_o (int_core_master_mst_rsp_o[2][1]),
      .axi_out_req_o(),
      .axi_out_rsp_i('0),
      .id_i         (INT_CORE_MASTER_NI_2_1_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_master_ni_2_1_to_mesh_router_2_1_req),
      .floo_rsp_i   (mesh_router_2_1_to_int_core_master_ni_2_1_rsp),
      .floo_req_i   (mesh_router_2_1_to_int_core_master_ni_2_1_req),
      .floo_rsp_o   (int_core_master_ni_2_1_to_mesh_router_2_1_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_MASTER_NI_2_2_ID = id_t'(22);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b0, 1'b1)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_master_ni_2_2 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i (int_core_master_mst_req_i[2][2]),
      .axi_in_rsp_o (int_core_master_mst_rsp_o[2][2]),
      .axi_out_req_o(),
      .axi_out_rsp_i('0),
      .id_i         (INT_CORE_MASTER_NI_2_2_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_master_ni_2_2_to_mesh_router_2_2_req),
      .floo_rsp_i   (mesh_router_2_2_to_int_core_master_ni_2_2_rsp),
      .floo_req_i   (mesh_router_2_2_to_int_core_master_ni_2_2_req),
      .floo_rsp_o   (int_core_master_ni_2_2_to_mesh_router_2_2_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_MASTER_NI_2_3_ID = id_t'(23);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b0, 1'b1)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_master_ni_2_3 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i (int_core_master_mst_req_i[2][3]),
      .axi_in_rsp_o (int_core_master_mst_rsp_o[2][3]),
      .axi_out_req_o(),
      .axi_out_rsp_i('0),
      .id_i         (INT_CORE_MASTER_NI_2_3_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_master_ni_2_3_to_mesh_router_2_3_req),
      .floo_rsp_i   (mesh_router_2_3_to_int_core_master_ni_2_3_rsp),
      .floo_req_i   (mesh_router_2_3_to_int_core_master_ni_2_3_req),
      .floo_rsp_o   (int_core_master_ni_2_3_to_mesh_router_2_3_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_MASTER_NI_2_4_ID = id_t'(24);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b0, 1'b1)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_master_ni_2_4 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i (int_core_master_mst_req_i[2][4]),
      .axi_in_rsp_o (int_core_master_mst_rsp_o[2][4]),
      .axi_out_req_o(),
      .axi_out_rsp_i('0),
      .id_i         (INT_CORE_MASTER_NI_2_4_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_master_ni_2_4_to_mesh_router_2_4_req),
      .floo_rsp_i   (mesh_router_2_4_to_int_core_master_ni_2_4_rsp),
      .floo_req_i   (mesh_router_2_4_to_int_core_master_ni_2_4_req),
      .floo_rsp_o   (int_core_master_ni_2_4_to_mesh_router_2_4_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_MASTER_NI_2_5_ID = id_t'(25);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b0, 1'b1)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_master_ni_2_5 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i (int_core_master_mst_req_i[2][5]),
      .axi_in_rsp_o (int_core_master_mst_rsp_o[2][5]),
      .axi_out_req_o(),
      .axi_out_rsp_i('0),
      .id_i         (INT_CORE_MASTER_NI_2_5_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_master_ni_2_5_to_mesh_router_2_5_req),
      .floo_rsp_i   (mesh_router_2_5_to_int_core_master_ni_2_5_rsp),
      .floo_req_i   (mesh_router_2_5_to_int_core_master_ni_2_5_req),
      .floo_rsp_o   (int_core_master_ni_2_5_to_mesh_router_2_5_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_MASTER_NI_2_6_ID = id_t'(26);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b0, 1'b1)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_master_ni_2_6 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i (int_core_master_mst_req_i[2][6]),
      .axi_in_rsp_o (int_core_master_mst_rsp_o[2][6]),
      .axi_out_req_o(),
      .axi_out_rsp_i('0),
      .id_i         (INT_CORE_MASTER_NI_2_6_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_master_ni_2_6_to_mesh_router_2_6_req),
      .floo_rsp_i   (mesh_router_2_6_to_int_core_master_ni_2_6_rsp),
      .floo_req_i   (mesh_router_2_6_to_int_core_master_ni_2_6_req),
      .floo_rsp_o   (int_core_master_ni_2_6_to_mesh_router_2_6_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_MASTER_NI_2_7_ID = id_t'(27);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b0, 1'b1)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_master_ni_2_7 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i (int_core_master_mst_req_i[2][7]),
      .axi_in_rsp_o (int_core_master_mst_rsp_o[2][7]),
      .axi_out_req_o(),
      .axi_out_rsp_i('0),
      .id_i         (INT_CORE_MASTER_NI_2_7_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_master_ni_2_7_to_mesh_router_2_7_req),
      .floo_rsp_i   (mesh_router_2_7_to_int_core_master_ni_2_7_rsp),
      .floo_req_i   (mesh_router_2_7_to_int_core_master_ni_2_7_req),
      .floo_rsp_o   (int_core_master_ni_2_7_to_mesh_router_2_7_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_MASTER_NI_3_0_ID = id_t'(28);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b0, 1'b1)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_master_ni_3_0 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i (int_core_master_mst_req_i[3][0]),
      .axi_in_rsp_o (int_core_master_mst_rsp_o[3][0]),
      .axi_out_req_o(),
      .axi_out_rsp_i('0),
      .id_i         (INT_CORE_MASTER_NI_3_0_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_master_ni_3_0_to_mesh_router_3_0_req),
      .floo_rsp_i   (mesh_router_3_0_to_int_core_master_ni_3_0_rsp),
      .floo_req_i   (mesh_router_3_0_to_int_core_master_ni_3_0_req),
      .floo_rsp_o   (int_core_master_ni_3_0_to_mesh_router_3_0_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_MASTER_NI_3_1_ID = id_t'(29);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b0, 1'b1)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_master_ni_3_1 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i (int_core_master_mst_req_i[3][1]),
      .axi_in_rsp_o (int_core_master_mst_rsp_o[3][1]),
      .axi_out_req_o(),
      .axi_out_rsp_i('0),
      .id_i         (INT_CORE_MASTER_NI_3_1_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_master_ni_3_1_to_mesh_router_3_1_req),
      .floo_rsp_i   (mesh_router_3_1_to_int_core_master_ni_3_1_rsp),
      .floo_req_i   (mesh_router_3_1_to_int_core_master_ni_3_1_req),
      .floo_rsp_o   (int_core_master_ni_3_1_to_mesh_router_3_1_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_MASTER_NI_3_2_ID = id_t'(30);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b0, 1'b1)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_master_ni_3_2 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i (int_core_master_mst_req_i[3][2]),
      .axi_in_rsp_o (int_core_master_mst_rsp_o[3][2]),
      .axi_out_req_o(),
      .axi_out_rsp_i('0),
      .id_i         (INT_CORE_MASTER_NI_3_2_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_master_ni_3_2_to_mesh_router_3_2_req),
      .floo_rsp_i   (mesh_router_3_2_to_int_core_master_ni_3_2_rsp),
      .floo_req_i   (mesh_router_3_2_to_int_core_master_ni_3_2_req),
      .floo_rsp_o   (int_core_master_ni_3_2_to_mesh_router_3_2_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_MASTER_NI_3_3_ID = id_t'(31);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b0, 1'b1)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_master_ni_3_3 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i (int_core_master_mst_req_i[3][3]),
      .axi_in_rsp_o (int_core_master_mst_rsp_o[3][3]),
      .axi_out_req_o(),
      .axi_out_rsp_i('0),
      .id_i         (INT_CORE_MASTER_NI_3_3_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_master_ni_3_3_to_mesh_router_3_3_req),
      .floo_rsp_i   (mesh_router_3_3_to_int_core_master_ni_3_3_rsp),
      .floo_req_i   (mesh_router_3_3_to_int_core_master_ni_3_3_req),
      .floo_rsp_o   (int_core_master_ni_3_3_to_mesh_router_3_3_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_MASTER_NI_3_4_ID = id_t'(32);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b0, 1'b1)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_master_ni_3_4 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i (int_core_master_mst_req_i[3][4]),
      .axi_in_rsp_o (int_core_master_mst_rsp_o[3][4]),
      .axi_out_req_o(),
      .axi_out_rsp_i('0),
      .id_i         (INT_CORE_MASTER_NI_3_4_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_master_ni_3_4_to_mesh_router_3_4_req),
      .floo_rsp_i   (mesh_router_3_4_to_int_core_master_ni_3_4_rsp),
      .floo_req_i   (mesh_router_3_4_to_int_core_master_ni_3_4_req),
      .floo_rsp_o   (int_core_master_ni_3_4_to_mesh_router_3_4_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_MASTER_NI_3_5_ID = id_t'(33);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b0, 1'b1)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_master_ni_3_5 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i (int_core_master_mst_req_i[3][5]),
      .axi_in_rsp_o (int_core_master_mst_rsp_o[3][5]),
      .axi_out_req_o(),
      .axi_out_rsp_i('0),
      .id_i         (INT_CORE_MASTER_NI_3_5_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_master_ni_3_5_to_mesh_router_3_5_req),
      .floo_rsp_i   (mesh_router_3_5_to_int_core_master_ni_3_5_rsp),
      .floo_req_i   (mesh_router_3_5_to_int_core_master_ni_3_5_req),
      .floo_rsp_o   (int_core_master_ni_3_5_to_mesh_router_3_5_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_MASTER_NI_3_6_ID = id_t'(34);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b0, 1'b1)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_master_ni_3_6 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i (int_core_master_mst_req_i[3][6]),
      .axi_in_rsp_o (int_core_master_mst_rsp_o[3][6]),
      .axi_out_req_o(),
      .axi_out_rsp_i('0),
      .id_i         (INT_CORE_MASTER_NI_3_6_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_master_ni_3_6_to_mesh_router_3_6_req),
      .floo_rsp_i   (mesh_router_3_6_to_int_core_master_ni_3_6_rsp),
      .floo_req_i   (mesh_router_3_6_to_int_core_master_ni_3_6_req),
      .floo_rsp_o   (int_core_master_ni_3_6_to_mesh_router_3_6_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_MASTER_NI_3_7_ID = id_t'(35);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b0, 1'b1)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_master_ni_3_7 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i (int_core_master_mst_req_i[3][7]),
      .axi_in_rsp_o (int_core_master_mst_rsp_o[3][7]),
      .axi_out_req_o(),
      .axi_out_rsp_i('0),
      .id_i         (INT_CORE_MASTER_NI_3_7_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_master_ni_3_7_to_mesh_router_3_7_req),
      .floo_rsp_i   (mesh_router_3_7_to_int_core_master_ni_3_7_rsp),
      .floo_req_i   (mesh_router_3_7_to_int_core_master_ni_3_7_req),
      .floo_rsp_o   (int_core_master_ni_3_7_to_mesh_router_3_7_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t LLC_SLAVE_NI_ID = id_t'(36);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) llc_slave_ni (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(llc_slave_slv_req_o),
      .axi_out_rsp_i(llc_slave_slv_rsp_i),
      .id_i         (LLC_SLAVE_NI_ID),
      .route_table_i('0),
      .floo_req_o   (llc_slave_ni_to_central_router_req),
      .floo_rsp_i   (central_router_to_llc_slave_ni_rsp),
      .floo_req_i   (central_router_to_llc_slave_ni_req),
      .floo_rsp_o   (llc_slave_ni_to_central_router_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t ROM_SLAVE_NI_ID = id_t'(37);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) rom_slave_ni (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(rom_slave_slv_req_o),
      .axi_out_rsp_i(rom_slave_slv_rsp_i),
      .id_i         (ROM_SLAVE_NI_ID),
      .route_table_i('0),
      .floo_req_o   (rom_slave_ni_to_central_router_req),
      .floo_rsp_i   (central_router_to_rom_slave_ni_rsp),
      .floo_req_i   (central_router_to_rom_slave_ni_req),
      .floo_rsp_o   (rom_slave_ni_to_central_router_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t DM_SLAVE_NI_ID = id_t'(38);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) dm_slave_ni (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(dm_slave_slv_req_o),
      .axi_out_rsp_i(dm_slave_slv_rsp_i),
      .id_i         (DM_SLAVE_NI_ID),
      .route_table_i('0),
      .floo_req_o   (dm_slave_ni_to_central_router_req),
      .floo_rsp_i   (central_router_to_dm_slave_ni_rsp),
      .floo_req_i   (central_router_to_dm_slave_ni_req),
      .floo_rsp_o   (dm_slave_ni_to_central_router_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t CLINT_SLAVE_NI_ID = id_t'(39);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) clint_slave_ni (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(clint_slave_slv_req_o),
      .axi_out_rsp_i(clint_slave_slv_rsp_i),
      .id_i         (CLINT_SLAVE_NI_ID),
      .route_table_i('0),
      .floo_req_o   (clint_slave_ni_to_central_router_req),
      .floo_rsp_i   (central_router_to_clint_slave_ni_rsp),
      .floo_req_i   (central_router_to_clint_slave_ni_req),
      .floo_rsp_o   (clint_slave_ni_to_central_router_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t PLIC_SLAVE_NI_ID = id_t'(40);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) plic_slave_ni (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(plic_slave_slv_req_o),
      .axi_out_rsp_i(plic_slave_slv_rsp_i),
      .id_i         (PLIC_SLAVE_NI_ID),
      .route_table_i('0),
      .floo_req_o   (plic_slave_ni_to_central_router_req),
      .floo_rsp_i   (central_router_to_plic_slave_ni_rsp),
      .floo_req_i   (central_router_to_plic_slave_ni_req),
      .floo_rsp_o   (plic_slave_ni_to_central_router_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t UART_SLAVE_NI_ID = id_t'(41);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) uart_slave_ni (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(uart_slave_slv_req_o),
      .axi_out_rsp_i(uart_slave_slv_rsp_i),
      .id_i         (UART_SLAVE_NI_ID),
      .route_table_i('0),
      .floo_req_o   (uart_slave_ni_to_central_router_req),
      .floo_rsp_i   (central_router_to_uart_slave_ni_rsp),
      .floo_req_i   (central_router_to_uart_slave_ni_req),
      .floo_rsp_o   (uart_slave_ni_to_central_router_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t TIMER_SLAVE_NI_ID = id_t'(42);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) timer_slave_ni (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(timer_slave_slv_req_o),
      .axi_out_rsp_i(timer_slave_slv_rsp_i),
      .id_i         (TIMER_SLAVE_NI_ID),
      .route_table_i('0),
      .floo_req_o   (timer_slave_ni_to_central_router_req),
      .floo_rsp_i   (central_router_to_timer_slave_ni_rsp),
      .floo_req_i   (central_router_to_timer_slave_ni_req),
      .floo_rsp_o   (timer_slave_ni_to_central_router_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t SYS_DCO_SLAVE_NI_ID = id_t'(43);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) sys_dco_slave_ni (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(sys_dco_slave_slv_req_o),
      .axi_out_rsp_i(sys_dco_slave_slv_rsp_i),
      .id_i         (SYS_DCO_SLAVE_NI_ID),
      .route_table_i('0),
      .floo_req_o   (sys_dco_slave_ni_to_central_router_req),
      .floo_rsp_i   (central_router_to_sys_dco_slave_ni_rsp),
      .floo_req_i   (central_router_to_sys_dco_slave_ni_req),
      .floo_rsp_o   (sys_dco_slave_ni_to_central_router_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t SL_CFG_SLAVE_NI_ID = id_t'(44);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) sl_cfg_slave_ni (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(sl_cfg_slave_slv_req_o),
      .axi_out_rsp_i(sl_cfg_slave_slv_rsp_i),
      .id_i         (SL_CFG_SLAVE_NI_ID),
      .route_table_i('0),
      .floo_req_o   (sl_cfg_slave_ni_to_central_router_req),
      .floo_rsp_i   (central_router_to_sl_cfg_slave_ni_rsp),
      .floo_req_i   (central_router_to_sl_cfg_slave_ni_req),
      .floo_rsp_o   (sl_cfg_slave_ni_to_central_router_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t D2D0_CFG_SLAVE_NI_ID = id_t'(45);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) d2d0_cfg_slave_ni (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(d2d0_cfg_slave_slv_req_o),
      .axi_out_rsp_i(d2d0_cfg_slave_slv_rsp_i),
      .id_i         (D2D0_CFG_SLAVE_NI_ID),
      .route_table_i('0),
      .floo_req_o   (d2d0_cfg_slave_ni_to_central_router_req),
      .floo_rsp_i   (central_router_to_d2d0_cfg_slave_ni_rsp),
      .floo_req_i   (central_router_to_d2d0_cfg_slave_ni_req),
      .floo_rsp_o   (d2d0_cfg_slave_ni_to_central_router_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t D2D1_CFG_SLAVE_NI_ID = id_t'(46);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) d2d1_cfg_slave_ni (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(d2d1_cfg_slave_slv_req_o),
      .axi_out_rsp_i(d2d1_cfg_slave_slv_rsp_i),
      .id_i         (D2D1_CFG_SLAVE_NI_ID),
      .route_table_i('0),
      .floo_req_o   (d2d1_cfg_slave_ni_to_central_router_req),
      .floo_rsp_i   (central_router_to_d2d1_cfg_slave_ni_rsp),
      .floo_req_i   (central_router_to_d2d1_cfg_slave_ni_req),
      .floo_rsp_o   (d2d1_cfg_slave_ni_to_central_router_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t LLC_CFG_SLAVE_NI_ID = id_t'(47);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) llc_cfg_slave_ni (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(llc_cfg_slave_slv_req_o),
      .axi_out_rsp_i(llc_cfg_slave_slv_rsp_i),
      .id_i         (LLC_CFG_SLAVE_NI_ID),
      .route_table_i('0),
      .floo_req_o   (llc_cfg_slave_ni_to_central_router_req),
      .floo_rsp_i   (central_router_to_llc_cfg_slave_ni_rsp),
      .floo_req_i   (central_router_to_llc_cfg_slave_ni_req),
      .floo_rsp_o   (llc_cfg_slave_ni_to_central_router_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t D2D0_SLAVE_NI_ID = id_t'(48);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) d2d0_slave_ni (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(d2d0_slave_slv_req_o),
      .axi_out_rsp_i(d2d0_slave_slv_rsp_i),
      .id_i         (D2D0_SLAVE_NI_ID),
      .route_table_i('0),
      .floo_req_o   (d2d0_slave_ni_to_central_router_req),
      .floo_rsp_i   (central_router_to_d2d0_slave_ni_rsp),
      .floo_req_i   (central_router_to_d2d0_slave_ni_req),
      .floo_rsp_o   (d2d0_slave_ni_to_central_router_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t D2D1_SLAVE_NI_ID = id_t'(49);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) d2d1_slave_ni (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(d2d1_slave_slv_req_o),
      .axi_out_rsp_i(d2d1_slave_slv_rsp_i),
      .id_i         (D2D1_SLAVE_NI_ID),
      .route_table_i('0),
      .floo_req_o   (d2d1_slave_ni_to_central_router_req),
      .floo_rsp_i   (central_router_to_d2d1_slave_ni_rsp),
      .floo_req_i   (central_router_to_d2d1_slave_ni_req),
      .floo_rsp_o   (d2d1_slave_ni_to_central_router_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_SLAVE_NI_0_0_ID = id_t'(50);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_slave_ni_0_0 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(int_core_slave_slv_req_o[0][0]),
      .axi_out_rsp_i(int_core_slave_slv_rsp_i[0][0]),
      .id_i         (INT_CORE_SLAVE_NI_0_0_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_slave_ni_0_0_to_mesh_router_0_0_req),
      .floo_rsp_i   (mesh_router_0_0_to_int_core_slave_ni_0_0_rsp),
      .floo_req_i   (mesh_router_0_0_to_int_core_slave_ni_0_0_req),
      .floo_rsp_o   (int_core_slave_ni_0_0_to_mesh_router_0_0_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_SLAVE_NI_0_1_ID = id_t'(51);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_slave_ni_0_1 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(int_core_slave_slv_req_o[0][1]),
      .axi_out_rsp_i(int_core_slave_slv_rsp_i[0][1]),
      .id_i         (INT_CORE_SLAVE_NI_0_1_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_slave_ni_0_1_to_mesh_router_0_1_req),
      .floo_rsp_i   (mesh_router_0_1_to_int_core_slave_ni_0_1_rsp),
      .floo_req_i   (mesh_router_0_1_to_int_core_slave_ni_0_1_req),
      .floo_rsp_o   (int_core_slave_ni_0_1_to_mesh_router_0_1_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_SLAVE_NI_0_2_ID = id_t'(52);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_slave_ni_0_2 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(int_core_slave_slv_req_o[0][2]),
      .axi_out_rsp_i(int_core_slave_slv_rsp_i[0][2]),
      .id_i         (INT_CORE_SLAVE_NI_0_2_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_slave_ni_0_2_to_mesh_router_0_2_req),
      .floo_rsp_i   (mesh_router_0_2_to_int_core_slave_ni_0_2_rsp),
      .floo_req_i   (mesh_router_0_2_to_int_core_slave_ni_0_2_req),
      .floo_rsp_o   (int_core_slave_ni_0_2_to_mesh_router_0_2_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_SLAVE_NI_0_3_ID = id_t'(53);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_slave_ni_0_3 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(int_core_slave_slv_req_o[0][3]),
      .axi_out_rsp_i(int_core_slave_slv_rsp_i[0][3]),
      .id_i         (INT_CORE_SLAVE_NI_0_3_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_slave_ni_0_3_to_mesh_router_0_3_req),
      .floo_rsp_i   (mesh_router_0_3_to_int_core_slave_ni_0_3_rsp),
      .floo_req_i   (mesh_router_0_3_to_int_core_slave_ni_0_3_req),
      .floo_rsp_o   (int_core_slave_ni_0_3_to_mesh_router_0_3_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_SLAVE_NI_0_4_ID = id_t'(54);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_slave_ni_0_4 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(int_core_slave_slv_req_o[0][4]),
      .axi_out_rsp_i(int_core_slave_slv_rsp_i[0][4]),
      .id_i         (INT_CORE_SLAVE_NI_0_4_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_slave_ni_0_4_to_mesh_router_0_4_req),
      .floo_rsp_i   (mesh_router_0_4_to_int_core_slave_ni_0_4_rsp),
      .floo_req_i   (mesh_router_0_4_to_int_core_slave_ni_0_4_req),
      .floo_rsp_o   (int_core_slave_ni_0_4_to_mesh_router_0_4_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_SLAVE_NI_0_5_ID = id_t'(55);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_slave_ni_0_5 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(int_core_slave_slv_req_o[0][5]),
      .axi_out_rsp_i(int_core_slave_slv_rsp_i[0][5]),
      .id_i         (INT_CORE_SLAVE_NI_0_5_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_slave_ni_0_5_to_mesh_router_0_5_req),
      .floo_rsp_i   (mesh_router_0_5_to_int_core_slave_ni_0_5_rsp),
      .floo_req_i   (mesh_router_0_5_to_int_core_slave_ni_0_5_req),
      .floo_rsp_o   (int_core_slave_ni_0_5_to_mesh_router_0_5_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_SLAVE_NI_0_6_ID = id_t'(56);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_slave_ni_0_6 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(int_core_slave_slv_req_o[0][6]),
      .axi_out_rsp_i(int_core_slave_slv_rsp_i[0][6]),
      .id_i         (INT_CORE_SLAVE_NI_0_6_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_slave_ni_0_6_to_mesh_router_0_6_req),
      .floo_rsp_i   (mesh_router_0_6_to_int_core_slave_ni_0_6_rsp),
      .floo_req_i   (mesh_router_0_6_to_int_core_slave_ni_0_6_req),
      .floo_rsp_o   (int_core_slave_ni_0_6_to_mesh_router_0_6_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_SLAVE_NI_0_7_ID = id_t'(57);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_slave_ni_0_7 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(int_core_slave_slv_req_o[0][7]),
      .axi_out_rsp_i(int_core_slave_slv_rsp_i[0][7]),
      .id_i         (INT_CORE_SLAVE_NI_0_7_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_slave_ni_0_7_to_mesh_router_0_7_req),
      .floo_rsp_i   (mesh_router_0_7_to_int_core_slave_ni_0_7_rsp),
      .floo_req_i   (mesh_router_0_7_to_int_core_slave_ni_0_7_req),
      .floo_rsp_o   (int_core_slave_ni_0_7_to_mesh_router_0_7_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_SLAVE_NI_1_0_ID = id_t'(58);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_slave_ni_1_0 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(int_core_slave_slv_req_o[1][0]),
      .axi_out_rsp_i(int_core_slave_slv_rsp_i[1][0]),
      .id_i         (INT_CORE_SLAVE_NI_1_0_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_slave_ni_1_0_to_mesh_router_1_0_req),
      .floo_rsp_i   (mesh_router_1_0_to_int_core_slave_ni_1_0_rsp),
      .floo_req_i   (mesh_router_1_0_to_int_core_slave_ni_1_0_req),
      .floo_rsp_o   (int_core_slave_ni_1_0_to_mesh_router_1_0_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_SLAVE_NI_1_1_ID = id_t'(59);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_slave_ni_1_1 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(int_core_slave_slv_req_o[1][1]),
      .axi_out_rsp_i(int_core_slave_slv_rsp_i[1][1]),
      .id_i         (INT_CORE_SLAVE_NI_1_1_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_slave_ni_1_1_to_mesh_router_1_1_req),
      .floo_rsp_i   (mesh_router_1_1_to_int_core_slave_ni_1_1_rsp),
      .floo_req_i   (mesh_router_1_1_to_int_core_slave_ni_1_1_req),
      .floo_rsp_o   (int_core_slave_ni_1_1_to_mesh_router_1_1_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_SLAVE_NI_1_2_ID = id_t'(60);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_slave_ni_1_2 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(int_core_slave_slv_req_o[1][2]),
      .axi_out_rsp_i(int_core_slave_slv_rsp_i[1][2]),
      .id_i         (INT_CORE_SLAVE_NI_1_2_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_slave_ni_1_2_to_mesh_router_1_2_req),
      .floo_rsp_i   (mesh_router_1_2_to_int_core_slave_ni_1_2_rsp),
      .floo_req_i   (mesh_router_1_2_to_int_core_slave_ni_1_2_req),
      .floo_rsp_o   (int_core_slave_ni_1_2_to_mesh_router_1_2_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_SLAVE_NI_1_3_ID = id_t'(61);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_slave_ni_1_3 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(int_core_slave_slv_req_o[1][3]),
      .axi_out_rsp_i(int_core_slave_slv_rsp_i[1][3]),
      .id_i         (INT_CORE_SLAVE_NI_1_3_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_slave_ni_1_3_to_mesh_router_1_3_req),
      .floo_rsp_i   (mesh_router_1_3_to_int_core_slave_ni_1_3_rsp),
      .floo_req_i   (mesh_router_1_3_to_int_core_slave_ni_1_3_req),
      .floo_rsp_o   (int_core_slave_ni_1_3_to_mesh_router_1_3_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_SLAVE_NI_1_4_ID = id_t'(62);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_slave_ni_1_4 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(int_core_slave_slv_req_o[1][4]),
      .axi_out_rsp_i(int_core_slave_slv_rsp_i[1][4]),
      .id_i         (INT_CORE_SLAVE_NI_1_4_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_slave_ni_1_4_to_mesh_router_1_4_req),
      .floo_rsp_i   (mesh_router_1_4_to_int_core_slave_ni_1_4_rsp),
      .floo_req_i   (mesh_router_1_4_to_int_core_slave_ni_1_4_req),
      .floo_rsp_o   (int_core_slave_ni_1_4_to_mesh_router_1_4_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_SLAVE_NI_1_5_ID = id_t'(63);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_slave_ni_1_5 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(int_core_slave_slv_req_o[1][5]),
      .axi_out_rsp_i(int_core_slave_slv_rsp_i[1][5]),
      .id_i         (INT_CORE_SLAVE_NI_1_5_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_slave_ni_1_5_to_mesh_router_1_5_req),
      .floo_rsp_i   (mesh_router_1_5_to_int_core_slave_ni_1_5_rsp),
      .floo_req_i   (mesh_router_1_5_to_int_core_slave_ni_1_5_req),
      .floo_rsp_o   (int_core_slave_ni_1_5_to_mesh_router_1_5_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_SLAVE_NI_1_6_ID = id_t'(64);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_slave_ni_1_6 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(int_core_slave_slv_req_o[1][6]),
      .axi_out_rsp_i(int_core_slave_slv_rsp_i[1][6]),
      .id_i         (INT_CORE_SLAVE_NI_1_6_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_slave_ni_1_6_to_mesh_router_1_6_req),
      .floo_rsp_i   (mesh_router_1_6_to_int_core_slave_ni_1_6_rsp),
      .floo_req_i   (mesh_router_1_6_to_int_core_slave_ni_1_6_req),
      .floo_rsp_o   (int_core_slave_ni_1_6_to_mesh_router_1_6_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_SLAVE_NI_1_7_ID = id_t'(65);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_slave_ni_1_7 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(int_core_slave_slv_req_o[1][7]),
      .axi_out_rsp_i(int_core_slave_slv_rsp_i[1][7]),
      .id_i         (INT_CORE_SLAVE_NI_1_7_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_slave_ni_1_7_to_mesh_router_1_7_req),
      .floo_rsp_i   (mesh_router_1_7_to_int_core_slave_ni_1_7_rsp),
      .floo_req_i   (mesh_router_1_7_to_int_core_slave_ni_1_7_req),
      .floo_rsp_o   (int_core_slave_ni_1_7_to_mesh_router_1_7_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_SLAVE_NI_2_0_ID = id_t'(66);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_slave_ni_2_0 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(int_core_slave_slv_req_o[2][0]),
      .axi_out_rsp_i(int_core_slave_slv_rsp_i[2][0]),
      .id_i         (INT_CORE_SLAVE_NI_2_0_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_slave_ni_2_0_to_mesh_router_2_0_req),
      .floo_rsp_i   (mesh_router_2_0_to_int_core_slave_ni_2_0_rsp),
      .floo_req_i   (mesh_router_2_0_to_int_core_slave_ni_2_0_req),
      .floo_rsp_o   (int_core_slave_ni_2_0_to_mesh_router_2_0_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_SLAVE_NI_2_1_ID = id_t'(67);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_slave_ni_2_1 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(int_core_slave_slv_req_o[2][1]),
      .axi_out_rsp_i(int_core_slave_slv_rsp_i[2][1]),
      .id_i         (INT_CORE_SLAVE_NI_2_1_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_slave_ni_2_1_to_mesh_router_2_1_req),
      .floo_rsp_i   (mesh_router_2_1_to_int_core_slave_ni_2_1_rsp),
      .floo_req_i   (mesh_router_2_1_to_int_core_slave_ni_2_1_req),
      .floo_rsp_o   (int_core_slave_ni_2_1_to_mesh_router_2_1_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_SLAVE_NI_2_2_ID = id_t'(68);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_slave_ni_2_2 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(int_core_slave_slv_req_o[2][2]),
      .axi_out_rsp_i(int_core_slave_slv_rsp_i[2][2]),
      .id_i         (INT_CORE_SLAVE_NI_2_2_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_slave_ni_2_2_to_mesh_router_2_2_req),
      .floo_rsp_i   (mesh_router_2_2_to_int_core_slave_ni_2_2_rsp),
      .floo_req_i   (mesh_router_2_2_to_int_core_slave_ni_2_2_req),
      .floo_rsp_o   (int_core_slave_ni_2_2_to_mesh_router_2_2_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_SLAVE_NI_2_3_ID = id_t'(69);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_slave_ni_2_3 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(int_core_slave_slv_req_o[2][3]),
      .axi_out_rsp_i(int_core_slave_slv_rsp_i[2][3]),
      .id_i         (INT_CORE_SLAVE_NI_2_3_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_slave_ni_2_3_to_mesh_router_2_3_req),
      .floo_rsp_i   (mesh_router_2_3_to_int_core_slave_ni_2_3_rsp),
      .floo_req_i   (mesh_router_2_3_to_int_core_slave_ni_2_3_req),
      .floo_rsp_o   (int_core_slave_ni_2_3_to_mesh_router_2_3_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_SLAVE_NI_2_4_ID = id_t'(70);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_slave_ni_2_4 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(int_core_slave_slv_req_o[2][4]),
      .axi_out_rsp_i(int_core_slave_slv_rsp_i[2][4]),
      .id_i         (INT_CORE_SLAVE_NI_2_4_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_slave_ni_2_4_to_mesh_router_2_4_req),
      .floo_rsp_i   (mesh_router_2_4_to_int_core_slave_ni_2_4_rsp),
      .floo_req_i   (mesh_router_2_4_to_int_core_slave_ni_2_4_req),
      .floo_rsp_o   (int_core_slave_ni_2_4_to_mesh_router_2_4_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_SLAVE_NI_2_5_ID = id_t'(71);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_slave_ni_2_5 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(int_core_slave_slv_req_o[2][5]),
      .axi_out_rsp_i(int_core_slave_slv_rsp_i[2][5]),
      .id_i         (INT_CORE_SLAVE_NI_2_5_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_slave_ni_2_5_to_mesh_router_2_5_req),
      .floo_rsp_i   (mesh_router_2_5_to_int_core_slave_ni_2_5_rsp),
      .floo_req_i   (mesh_router_2_5_to_int_core_slave_ni_2_5_req),
      .floo_rsp_o   (int_core_slave_ni_2_5_to_mesh_router_2_5_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_SLAVE_NI_2_6_ID = id_t'(72);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_slave_ni_2_6 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(int_core_slave_slv_req_o[2][6]),
      .axi_out_rsp_i(int_core_slave_slv_rsp_i[2][6]),
      .id_i         (INT_CORE_SLAVE_NI_2_6_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_slave_ni_2_6_to_mesh_router_2_6_req),
      .floo_rsp_i   (mesh_router_2_6_to_int_core_slave_ni_2_6_rsp),
      .floo_req_i   (mesh_router_2_6_to_int_core_slave_ni_2_6_req),
      .floo_rsp_o   (int_core_slave_ni_2_6_to_mesh_router_2_6_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_SLAVE_NI_2_7_ID = id_t'(73);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_slave_ni_2_7 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(int_core_slave_slv_req_o[2][7]),
      .axi_out_rsp_i(int_core_slave_slv_rsp_i[2][7]),
      .id_i         (INT_CORE_SLAVE_NI_2_7_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_slave_ni_2_7_to_mesh_router_2_7_req),
      .floo_rsp_i   (mesh_router_2_7_to_int_core_slave_ni_2_7_rsp),
      .floo_req_i   (mesh_router_2_7_to_int_core_slave_ni_2_7_req),
      .floo_rsp_o   (int_core_slave_ni_2_7_to_mesh_router_2_7_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_SLAVE_NI_3_0_ID = id_t'(74);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_slave_ni_3_0 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(int_core_slave_slv_req_o[3][0]),
      .axi_out_rsp_i(int_core_slave_slv_rsp_i[3][0]),
      .id_i         (INT_CORE_SLAVE_NI_3_0_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_slave_ni_3_0_to_mesh_router_3_0_req),
      .floo_rsp_i   (mesh_router_3_0_to_int_core_slave_ni_3_0_rsp),
      .floo_req_i   (mesh_router_3_0_to_int_core_slave_ni_3_0_req),
      .floo_rsp_o   (int_core_slave_ni_3_0_to_mesh_router_3_0_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_SLAVE_NI_3_1_ID = id_t'(75);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_slave_ni_3_1 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(int_core_slave_slv_req_o[3][1]),
      .axi_out_rsp_i(int_core_slave_slv_rsp_i[3][1]),
      .id_i         (INT_CORE_SLAVE_NI_3_1_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_slave_ni_3_1_to_mesh_router_3_1_req),
      .floo_rsp_i   (mesh_router_3_1_to_int_core_slave_ni_3_1_rsp),
      .floo_req_i   (mesh_router_3_1_to_int_core_slave_ni_3_1_req),
      .floo_rsp_o   (int_core_slave_ni_3_1_to_mesh_router_3_1_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_SLAVE_NI_3_2_ID = id_t'(76);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_slave_ni_3_2 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(int_core_slave_slv_req_o[3][2]),
      .axi_out_rsp_i(int_core_slave_slv_rsp_i[3][2]),
      .id_i         (INT_CORE_SLAVE_NI_3_2_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_slave_ni_3_2_to_mesh_router_3_2_req),
      .floo_rsp_i   (mesh_router_3_2_to_int_core_slave_ni_3_2_rsp),
      .floo_req_i   (mesh_router_3_2_to_int_core_slave_ni_3_2_req),
      .floo_rsp_o   (int_core_slave_ni_3_2_to_mesh_router_3_2_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_SLAVE_NI_3_3_ID = id_t'(77);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_slave_ni_3_3 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(int_core_slave_slv_req_o[3][3]),
      .axi_out_rsp_i(int_core_slave_slv_rsp_i[3][3]),
      .id_i         (INT_CORE_SLAVE_NI_3_3_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_slave_ni_3_3_to_mesh_router_3_3_req),
      .floo_rsp_i   (mesh_router_3_3_to_int_core_slave_ni_3_3_rsp),
      .floo_req_i   (mesh_router_3_3_to_int_core_slave_ni_3_3_req),
      .floo_rsp_o   (int_core_slave_ni_3_3_to_mesh_router_3_3_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_SLAVE_NI_3_4_ID = id_t'(78);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_slave_ni_3_4 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(int_core_slave_slv_req_o[3][4]),
      .axi_out_rsp_i(int_core_slave_slv_rsp_i[3][4]),
      .id_i         (INT_CORE_SLAVE_NI_3_4_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_slave_ni_3_4_to_mesh_router_3_4_req),
      .floo_rsp_i   (mesh_router_3_4_to_int_core_slave_ni_3_4_rsp),
      .floo_req_i   (mesh_router_3_4_to_int_core_slave_ni_3_4_req),
      .floo_rsp_o   (int_core_slave_ni_3_4_to_mesh_router_3_4_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_SLAVE_NI_3_5_ID = id_t'(79);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_slave_ni_3_5 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(int_core_slave_slv_req_o[3][5]),
      .axi_out_rsp_i(int_core_slave_slv_rsp_i[3][5]),
      .id_i         (INT_CORE_SLAVE_NI_3_5_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_slave_ni_3_5_to_mesh_router_3_5_req),
      .floo_rsp_i   (mesh_router_3_5_to_int_core_slave_ni_3_5_rsp),
      .floo_req_i   (mesh_router_3_5_to_int_core_slave_ni_3_5_req),
      .floo_rsp_o   (int_core_slave_ni_3_5_to_mesh_router_3_5_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_SLAVE_NI_3_6_ID = id_t'(80);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_slave_ni_3_6 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(int_core_slave_slv_req_o[3][6]),
      .axi_out_rsp_i(int_core_slave_slv_rsp_i[3][6]),
      .id_i         (INT_CORE_SLAVE_NI_3_6_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_slave_ni_3_6_to_mesh_router_3_6_req),
      .floo_rsp_i   (mesh_router_3_6_to_int_core_slave_ni_3_6_rsp),
      .floo_req_i   (mesh_router_3_6_to_int_core_slave_ni_3_6_req),
      .floo_rsp_o   (int_core_slave_ni_3_6_to_mesh_router_3_6_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t INT_CORE_SLAVE_NI_3_7_ID = id_t'(81);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) int_core_slave_ni_3_7 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(int_core_slave_slv_req_o[3][7]),
      .axi_out_rsp_i(int_core_slave_slv_rsp_i[3][7]),
      .id_i         (INT_CORE_SLAVE_NI_3_7_ID),
      .route_table_i('0),
      .floo_req_o   (int_core_slave_ni_3_7_to_mesh_router_3_7_req),
      .floo_rsp_i   (mesh_router_3_7_to_int_core_slave_ni_3_7_rsp),
      .floo_req_i   (mesh_router_3_7_to_int_core_slave_ni_3_7_req),
      .floo_rsp_o   (int_core_slave_ni_3_7_to_mesh_router_3_7_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t FP_CORE_SLAVE_NI_0_0_ID = id_t'(82);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) fp_core_slave_ni_0_0 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(fp_core_slave_slv_req_o[0]),
      .axi_out_rsp_i(fp_core_slave_slv_rsp_i[0]),
      .id_i         (FP_CORE_SLAVE_NI_0_0_ID),
      .route_table_i('0),
      .floo_req_o   (fp_core_slave_ni_0_0_to_mesh_router_3_0_req),
      .floo_rsp_i   (mesh_router_3_0_to_fp_core_slave_ni_0_0_rsp),
      .floo_req_i   (mesh_router_3_0_to_fp_core_slave_ni_0_0_req),
      .floo_rsp_o   (fp_core_slave_ni_0_0_to_mesh_router_3_0_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t FP_CORE_SLAVE_NI_0_1_ID = id_t'(83);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) fp_core_slave_ni_0_1 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(fp_core_slave_slv_req_o[1]),
      .axi_out_rsp_i(fp_core_slave_slv_rsp_i[1]),
      .id_i         (FP_CORE_SLAVE_NI_0_1_ID),
      .route_table_i('0),
      .floo_req_o   (fp_core_slave_ni_0_1_to_mesh_router_3_1_req),
      .floo_rsp_i   (mesh_router_3_1_to_fp_core_slave_ni_0_1_rsp),
      .floo_req_i   (mesh_router_3_1_to_fp_core_slave_ni_0_1_req),
      .floo_rsp_o   (fp_core_slave_ni_0_1_to_mesh_router_3_1_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t FP_CORE_SLAVE_NI_0_2_ID = id_t'(84);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) fp_core_slave_ni_0_2 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(fp_core_slave_slv_req_o[2]),
      .axi_out_rsp_i(fp_core_slave_slv_rsp_i[2]),
      .id_i         (FP_CORE_SLAVE_NI_0_2_ID),
      .route_table_i('0),
      .floo_req_o   (fp_core_slave_ni_0_2_to_mesh_router_3_2_req),
      .floo_rsp_i   (mesh_router_3_2_to_fp_core_slave_ni_0_2_rsp),
      .floo_req_i   (mesh_router_3_2_to_fp_core_slave_ni_0_2_req),
      .floo_rsp_o   (fp_core_slave_ni_0_2_to_mesh_router_3_2_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t FP_CORE_SLAVE_NI_0_3_ID = id_t'(85);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) fp_core_slave_ni_0_3 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(fp_core_slave_slv_req_o[3]),
      .axi_out_rsp_i(fp_core_slave_slv_rsp_i[3]),
      .id_i         (FP_CORE_SLAVE_NI_0_3_ID),
      .route_table_i('0),
      .floo_req_o   (fp_core_slave_ni_0_3_to_mesh_router_3_3_req),
      .floo_rsp_i   (mesh_router_3_3_to_fp_core_slave_ni_0_3_rsp),
      .floo_req_i   (mesh_router_3_3_to_fp_core_slave_ni_0_3_req),
      .floo_rsp_o   (fp_core_slave_ni_0_3_to_mesh_router_3_3_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t FP_CORE_SLAVE_NI_0_4_ID = id_t'(86);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) fp_core_slave_ni_0_4 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(fp_core_slave_slv_req_o[4]),
      .axi_out_rsp_i(fp_core_slave_slv_rsp_i[4]),
      .id_i         (FP_CORE_SLAVE_NI_0_4_ID),
      .route_table_i('0),
      .floo_req_o   (fp_core_slave_ni_0_4_to_mesh_router_3_4_req),
      .floo_rsp_i   (mesh_router_3_4_to_fp_core_slave_ni_0_4_rsp),
      .floo_req_i   (mesh_router_3_4_to_fp_core_slave_ni_0_4_req),
      .floo_rsp_o   (fp_core_slave_ni_0_4_to_mesh_router_3_4_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t FP_CORE_SLAVE_NI_0_5_ID = id_t'(87);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) fp_core_slave_ni_0_5 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(fp_core_slave_slv_req_o[5]),
      .axi_out_rsp_i(fp_core_slave_slv_rsp_i[5]),
      .id_i         (FP_CORE_SLAVE_NI_0_5_ID),
      .route_table_i('0),
      .floo_req_o   (fp_core_slave_ni_0_5_to_mesh_router_3_5_req),
      .floo_rsp_i   (mesh_router_3_5_to_fp_core_slave_ni_0_5_rsp),
      .floo_req_i   (mesh_router_3_5_to_fp_core_slave_ni_0_5_req),
      .floo_rsp_o   (fp_core_slave_ni_0_5_to_mesh_router_3_5_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t FP_CORE_SLAVE_NI_0_6_ID = id_t'(88);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) fp_core_slave_ni_0_6 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(fp_core_slave_slv_req_o[6]),
      .axi_out_rsp_i(fp_core_slave_slv_rsp_i[6]),
      .id_i         (FP_CORE_SLAVE_NI_0_6_ID),
      .route_table_i('0),
      .floo_req_o   (fp_core_slave_ni_0_6_to_mesh_router_3_6_req),
      .floo_rsp_i   (mesh_router_3_6_to_fp_core_slave_ni_0_6_rsp),
      .floo_req_i   (mesh_router_3_6_to_fp_core_slave_ni_0_6_req),
      .floo_rsp_o   (fp_core_slave_ni_0_6_to_mesh_router_3_6_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t FP_CORE_SLAVE_NI_0_7_ID = id_t'(89);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) fp_core_slave_ni_0_7 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(fp_core_slave_slv_req_o[7]),
      .axi_out_rsp_i(fp_core_slave_slv_rsp_i[7]),
      .id_i         (FP_CORE_SLAVE_NI_0_7_ID),
      .route_table_i('0),
      .floo_req_o   (fp_core_slave_ni_0_7_to_mesh_router_3_7_req),
      .floo_rsp_i   (mesh_router_3_7_to_fp_core_slave_ni_0_7_rsp),
      .floo_req_i   (mesh_router_3_7_to_fp_core_slave_ni_0_7_req),
      .floo_rsp_o   (fp_core_slave_ni_0_7_to_mesh_router_3_7_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t SP_SLAVE_NI_ID = id_t'(90);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) sp_slave_ni (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(sp_slave_slv_req_o),
      .axi_out_rsp_i(sp_slave_slv_rsp_i),
      .id_i         (SP_SLAVE_NI_ID),
      .route_table_i('0),
      .floo_req_o   (sp_slave_ni_to_central_router_req),
      .floo_rsp_i   (central_router_to_sp_slave_ni_rsp),
      .floo_req_i   (central_router_to_sp_slave_ni_req),
      .floo_rsp_o   (sp_slave_ni_to_central_router_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam id_t AUX_SLOT_SLAVE_NI_ID = id_t'(91);

  floo_axi_chimney #(
      .AxiCfg(AxiCfg),
      .ChimneyCfg(set_ports(ChimneyDefaultCfg, 1'b1, 1'b0)),
      .RouteCfg(RouteCfg),
      .id_t(id_t),
      .rob_idx_t(rob_idx_t),
      .hdr_t(hdr_t),
      .sam_rule_t(sam_rule_t),
      // .Sam(Sam),
      .axi_in_req_t(mst_axi_req_t),
      .axi_in_rsp_t(mst_axi_rsp_t),
      .axi_out_req_t(slv_axi_req_t),
      .axi_out_rsp_t(slv_axi_rsp_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) aux_slot_slave_ni (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .sram_cfg_i   ('0),
      .axi_in_req_i ('0),
      .axi_in_rsp_o (),
      .axi_out_req_o(aux_slot_slave_slv_req_o),
      .axi_out_rsp_i(aux_slot_slave_slv_rsp_i),
      .id_i         (AUX_SLOT_SLAVE_NI_ID),
      .route_table_i('0),
      .floo_req_o   (aux_slot_slave_ni_to_central_router_req),
      .floo_rsp_i   (central_router_to_aux_slot_slave_ni_rsp),
      .floo_req_i   (central_router_to_aux_slot_slave_ni_req),
      .floo_rsp_o   (aux_slot_slave_ni_to_central_router_rsp),
      .sam_map_i    (sam_map_i)
  );

  localparam int unsigned CentralRouterMapNumRules = 22;

  typedef struct packed {
    id_t idx;
    id_t start_addr;
    id_t end_addr;
  } central_router_map_rule_t;

  localparam central_router_map_rule_t [CentralRouterMapNumRules-1:0] CentralRouterMap = '{
      '{idx: 1, start_addr: 0, end_addr: 1},  // cpu_master_ni
      '{idx: 8, start_addr: 1, end_addr: 2},  // dm_master_ni
      '{idx: 3, start_addr: 2, end_addr: 3},  // d2d0_master_ni
      '{idx: 6, start_addr: 3, end_addr: 4},  // d2d1_master_ni
      '{idx: 13, start_addr: 4, end_addr: 36},  // int_core_master_ni_0_0
      '{idx: 13, start_addr: 50, end_addr: 90},  // int_core_slave_ni_0_0
      '{idx: 11, start_addr: 36, end_addr: 37},  // llc_slave_ni
      '{idx: 15, start_addr: 37, end_addr: 38},  // rom_slave_ni
      '{idx: 9, start_addr: 38, end_addr: 39},  // dm_slave_ni
      '{idx: 0, start_addr: 39, end_addr: 40},  // clint_slave_ni
      '{idx: 14, start_addr: 40, end_addr: 41},  // plic_slave_ni
      '{idx: 20, start_addr: 41, end_addr: 42},  // uart_slave_ni
      '{idx: 19, start_addr: 42, end_addr: 43},  // timer_slave_ni
      '{idx: 18, start_addr: 43, end_addr: 44},  // sys_dco_slave_ni
      '{idx: 16, start_addr: 44, end_addr: 45},  // sl_cfg_slave_ni
      '{idx: 2, start_addr: 45, end_addr: 46},  // d2d0_cfg_slave_ni
      '{idx: 5, start_addr: 46, end_addr: 47},  // d2d1_cfg_slave_ni
      '{idx: 10, start_addr: 47, end_addr: 48},  // llc_cfg_slave_ni
      '{idx: 4, start_addr: 48, end_addr: 49},  // d2d0_slave_ni
      '{idx: 7, start_addr: 49, end_addr: 50},  // d2d1_slave_ni
      '{idx: 17, start_addr: 90, end_addr: 91},  // sp_slave_ni
      '{idx: 12, start_addr: 91, end_addr: 92}  // aux_slot_slave_ni

  };


  floo_req_t [20:0] central_router_req_in;
  floo_rsp_t [20:0] central_router_rsp_out;
  floo_req_t [20:0] central_router_req_out;
  floo_rsp_t [20:0] central_router_rsp_in;

  assign central_router_req_in[0] = clint_slave_ni_to_central_router_req;
  assign central_router_req_in[1] = cpu_master_ni_to_central_router_req;
  assign central_router_req_in[2] = d2d0_cfg_slave_ni_to_central_router_req;
  assign central_router_req_in[3] = d2d0_master_ni_to_central_router_req;
  assign central_router_req_in[4] = d2d0_slave_ni_to_central_router_req;
  assign central_router_req_in[5] = d2d1_cfg_slave_ni_to_central_router_req;
  assign central_router_req_in[6] = d2d1_master_ni_to_central_router_req;
  assign central_router_req_in[7] = d2d1_slave_ni_to_central_router_req;
  assign central_router_req_in[8] = dm_master_ni_to_central_router_req;
  assign central_router_req_in[9] = dm_slave_ni_to_central_router_req;
  assign central_router_req_in[10] = llc_cfg_slave_ni_to_central_router_req;
  assign central_router_req_in[11] = llc_slave_ni_to_central_router_req;
  assign central_router_req_in[12] = aux_slot_slave_ni_to_central_router_req;
  assign central_router_req_in[13] = mesh_router_0_0_to_central_router_req;
  assign central_router_req_in[14] = plic_slave_ni_to_central_router_req;
  assign central_router_req_in[15] = rom_slave_ni_to_central_router_req;
  assign central_router_req_in[16] = sl_cfg_slave_ni_to_central_router_req;
  assign central_router_req_in[17] = sp_slave_ni_to_central_router_req;
  assign central_router_req_in[18] = sys_dco_slave_ni_to_central_router_req;
  assign central_router_req_in[19] = timer_slave_ni_to_central_router_req;
  assign central_router_req_in[20] = uart_slave_ni_to_central_router_req;

  assign central_router_to_clint_slave_ni_rsp = central_router_rsp_out[0];
  assign central_router_to_cpu_master_ni_rsp = central_router_rsp_out[1];
  assign central_router_to_d2d0_cfg_slave_ni_rsp = central_router_rsp_out[2];
  assign central_router_to_d2d0_master_ni_rsp = central_router_rsp_out[3];
  assign central_router_to_d2d0_slave_ni_rsp = central_router_rsp_out[4];
  assign central_router_to_d2d1_cfg_slave_ni_rsp = central_router_rsp_out[5];
  assign central_router_to_d2d1_master_ni_rsp = central_router_rsp_out[6];
  assign central_router_to_d2d1_slave_ni_rsp = central_router_rsp_out[7];
  assign central_router_to_dm_master_ni_rsp = central_router_rsp_out[8];
  assign central_router_to_dm_slave_ni_rsp = central_router_rsp_out[9];
  assign central_router_to_llc_cfg_slave_ni_rsp = central_router_rsp_out[10];
  assign central_router_to_llc_slave_ni_rsp = central_router_rsp_out[11];
  assign central_router_to_aux_slot_slave_ni_rsp = central_router_rsp_out[12];
  assign central_router_to_mesh_router_0_0_rsp = central_router_rsp_out[13];
  assign central_router_to_plic_slave_ni_rsp = central_router_rsp_out[14];
  assign central_router_to_rom_slave_ni_rsp = central_router_rsp_out[15];
  assign central_router_to_sl_cfg_slave_ni_rsp = central_router_rsp_out[16];
  assign central_router_to_sp_slave_ni_rsp = central_router_rsp_out[17];
  assign central_router_to_sys_dco_slave_ni_rsp = central_router_rsp_out[18];
  assign central_router_to_timer_slave_ni_rsp = central_router_rsp_out[19];
  assign central_router_to_uart_slave_ni_rsp = central_router_rsp_out[20];

  assign central_router_to_clint_slave_ni_req = central_router_req_out[0];
  assign central_router_to_cpu_master_ni_req = central_router_req_out[1];
  assign central_router_to_d2d0_cfg_slave_ni_req = central_router_req_out[2];
  assign central_router_to_d2d0_master_ni_req = central_router_req_out[3];
  assign central_router_to_d2d0_slave_ni_req = central_router_req_out[4];
  assign central_router_to_d2d1_cfg_slave_ni_req = central_router_req_out[5];
  assign central_router_to_d2d1_master_ni_req = central_router_req_out[6];
  assign central_router_to_d2d1_slave_ni_req = central_router_req_out[7];
  assign central_router_to_dm_master_ni_req = central_router_req_out[8];
  assign central_router_to_dm_slave_ni_req = central_router_req_out[9];
  assign central_router_to_llc_cfg_slave_ni_req = central_router_req_out[10];
  assign central_router_to_llc_slave_ni_req = central_router_req_out[11];
  assign central_router_to_aux_slot_slave_ni_req = central_router_req_out[12];
  assign central_router_to_mesh_router_0_0_req = central_router_req_out[13];
  assign central_router_to_plic_slave_ni_req = central_router_req_out[14];
  assign central_router_to_rom_slave_ni_req = central_router_req_out[15];
  assign central_router_to_sl_cfg_slave_ni_req = central_router_req_out[16];
  assign central_router_to_sp_slave_ni_req = central_router_req_out[17];
  assign central_router_to_sys_dco_slave_ni_req = central_router_req_out[18];
  assign central_router_to_timer_slave_ni_req = central_router_req_out[19];
  assign central_router_to_uart_slave_ni_req = central_router_req_out[20];

  assign central_router_rsp_in[0] = clint_slave_ni_to_central_router_rsp;
  assign central_router_rsp_in[1] = cpu_master_ni_to_central_router_rsp;
  assign central_router_rsp_in[2] = d2d0_cfg_slave_ni_to_central_router_rsp;
  assign central_router_rsp_in[3] = d2d0_master_ni_to_central_router_rsp;
  assign central_router_rsp_in[4] = d2d0_slave_ni_to_central_router_rsp;
  assign central_router_rsp_in[5] = d2d1_cfg_slave_ni_to_central_router_rsp;
  assign central_router_rsp_in[6] = d2d1_master_ni_to_central_router_rsp;
  assign central_router_rsp_in[7] = d2d1_slave_ni_to_central_router_rsp;
  assign central_router_rsp_in[8] = dm_master_ni_to_central_router_rsp;
  assign central_router_rsp_in[9] = dm_slave_ni_to_central_router_rsp;
  assign central_router_rsp_in[10] = llc_cfg_slave_ni_to_central_router_rsp;
  assign central_router_rsp_in[11] = llc_slave_ni_to_central_router_rsp;
  assign central_router_rsp_in[12] = aux_slot_slave_ni_to_central_router_rsp;
  assign central_router_rsp_in[13] = mesh_router_0_0_to_central_router_rsp;
  assign central_router_rsp_in[14] = plic_slave_ni_to_central_router_rsp;
  assign central_router_rsp_in[15] = rom_slave_ni_to_central_router_rsp;
  assign central_router_rsp_in[16] = sl_cfg_slave_ni_to_central_router_rsp;
  assign central_router_rsp_in[17] = sp_slave_ni_to_central_router_rsp;
  assign central_router_rsp_in[18] = sys_dco_slave_ni_to_central_router_rsp;
  assign central_router_rsp_in[19] = timer_slave_ni_to_central_router_rsp;
  assign central_router_rsp_in[20] = uart_slave_ni_to_central_router_rsp;


  floo_axi_router #(
      .AxiCfg(AxiCfg),
      .RouteAlgo(IdTable),
      .NumRoutes(21),
      .NumInputs(21),
      .NumOutputs(21),
      .InFifoDepth(2),
      .OutFifoDepth(2),
      .id_t(id_t),
      .hdr_t(hdr_t),
      .NumAddrRules(22),
      .addr_rule_t(central_router_map_rule_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) central_router (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('0),
      .id_route_map_i(CentralRouterMap),
      .floo_req_i(central_router_req_in),
      .floo_rsp_o(central_router_rsp_out),
      .floo_req_o(central_router_req_out),
      .floo_rsp_i(central_router_rsp_in)
  );

  localparam int unsigned MeshRouter00MapNumRules = 21;

  typedef struct packed {
    id_t idx;
    id_t start_addr;
    id_t end_addr;
  } mesh_router_0_0_map_rule_t;

  localparam mesh_router_0_0_map_rule_t [MeshRouter00MapNumRules-1:0] MeshRouter00Map = '{
      '{idx: 0, start_addr: 0, end_addr: 4},  // cpu_master_ni
      '{idx: 0, start_addr: 36, end_addr: 50},  // llc_slave_ni
      '{idx: 0, start_addr: 90, end_addr: 92},  // sp_slave_ni
      '{idx: 1, start_addr: 4, end_addr: 5},  // int_core_master_ni_0_0
      '{idx: 3, start_addr: 5, end_addr: 12},  // int_core_master_ni_0_1
      '{idx: 3, start_addr: 13, end_addr: 20},  // int_core_master_ni_1_1
      '{idx: 3, start_addr: 21, end_addr: 28},  // int_core_master_ni_2_1
      '{idx: 3, start_addr: 29, end_addr: 36},  // int_core_master_ni_3_1
      '{idx: 3, start_addr: 51, end_addr: 58},  // int_core_slave_ni_0_1
      '{idx: 3, start_addr: 59, end_addr: 66},  // int_core_slave_ni_1_1
      '{idx: 3, start_addr: 67, end_addr: 74},  // int_core_slave_ni_2_1
      '{idx: 3, start_addr: 75, end_addr: 82},  // int_core_slave_ni_3_1
      '{idx: 3, start_addr: 83, end_addr: 90},  // fp_core_slave_ni_0_1
      '{idx: 4, start_addr: 12, end_addr: 13},  // int_core_master_ni_1_0
      '{idx: 4, start_addr: 20, end_addr: 21},  // int_core_master_ni_2_0
      '{idx: 4, start_addr: 28, end_addr: 29},  // int_core_master_ni_3_0
      '{idx: 4, start_addr: 58, end_addr: 59},  // int_core_slave_ni_1_0
      '{idx: 4, start_addr: 66, end_addr: 67},  // int_core_slave_ni_2_0
      '{idx: 4, start_addr: 74, end_addr: 75},  // int_core_slave_ni_3_0
      '{idx: 4, start_addr: 82, end_addr: 83},  // fp_core_slave_ni_0_0
      '{idx: 2, start_addr: 50, end_addr: 51}  // int_core_slave_ni_0_0

  };


  floo_req_t [4:0] mesh_router_0_0_req_in;
  floo_rsp_t [4:0] mesh_router_0_0_rsp_out;
  floo_req_t [4:0] mesh_router_0_0_req_out;
  floo_rsp_t [4:0] mesh_router_0_0_rsp_in;

  assign mesh_router_0_0_req_in[0] = central_router_to_mesh_router_0_0_req;
  assign mesh_router_0_0_req_in[1] = int_core_master_ni_0_0_to_mesh_router_0_0_req;
  assign mesh_router_0_0_req_in[2] = int_core_slave_ni_0_0_to_mesh_router_0_0_req;
  assign mesh_router_0_0_req_in[3] = mesh_router_0_1_to_mesh_router_0_0_req;
  assign mesh_router_0_0_req_in[4] = mesh_router_1_0_to_mesh_router_0_0_req;

  assign mesh_router_0_0_to_central_router_rsp = mesh_router_0_0_rsp_out[0];
  assign mesh_router_0_0_to_int_core_master_ni_0_0_rsp = mesh_router_0_0_rsp_out[1];
  assign mesh_router_0_0_to_int_core_slave_ni_0_0_rsp = mesh_router_0_0_rsp_out[2];
  assign mesh_router_0_0_to_mesh_router_0_1_rsp = mesh_router_0_0_rsp_out[3];
  assign mesh_router_0_0_to_mesh_router_1_0_rsp = mesh_router_0_0_rsp_out[4];

  assign mesh_router_0_0_to_central_router_req = mesh_router_0_0_req_out[0];
  assign mesh_router_0_0_to_int_core_master_ni_0_0_req = mesh_router_0_0_req_out[1];
  assign mesh_router_0_0_to_int_core_slave_ni_0_0_req = mesh_router_0_0_req_out[2];
  assign mesh_router_0_0_to_mesh_router_0_1_req = mesh_router_0_0_req_out[3];
  assign mesh_router_0_0_to_mesh_router_1_0_req = mesh_router_0_0_req_out[4];

  assign mesh_router_0_0_rsp_in[0] = central_router_to_mesh_router_0_0_rsp;
  assign mesh_router_0_0_rsp_in[1] = int_core_master_ni_0_0_to_mesh_router_0_0_rsp;
  assign mesh_router_0_0_rsp_in[2] = int_core_slave_ni_0_0_to_mesh_router_0_0_rsp;
  assign mesh_router_0_0_rsp_in[3] = mesh_router_0_1_to_mesh_router_0_0_rsp;
  assign mesh_router_0_0_rsp_in[4] = mesh_router_1_0_to_mesh_router_0_0_rsp;


  floo_axi_router #(
      .AxiCfg(AxiCfg),
      .RouteAlgo(IdTable),
      .NumRoutes(5),
      .NumInputs(5),
      .NumOutputs(5),
      .InFifoDepth(2),
      .OutFifoDepth(2),
      .id_t(id_t),
      .hdr_t(hdr_t),
      .NumAddrRules(21),
      .addr_rule_t(mesh_router_0_0_map_rule_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) mesh_router_0_0 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('0),
      .id_route_map_i(MeshRouter00Map),
      .floo_req_i(mesh_router_0_0_req_in),
      .floo_rsp_o(mesh_router_0_0_rsp_out),
      .floo_req_o(mesh_router_0_0_req_out),
      .floo_rsp_i(mesh_router_0_0_rsp_in)
  );

  localparam int unsigned MeshRouter01MapNumRules = 28;

  typedef struct packed {
    id_t idx;
    id_t start_addr;
    id_t end_addr;
  } mesh_router_0_1_map_rule_t;

  localparam mesh_router_0_1_map_rule_t [MeshRouter01MapNumRules-1:0] MeshRouter01Map = '{
      '{idx: 2, start_addr: 0, end_addr: 5},  // cpu_master_ni
      '{idx: 2, start_addr: 12, end_addr: 13},  // int_core_master_ni_1_0
      '{idx: 2, start_addr: 20, end_addr: 21},  // int_core_master_ni_2_0
      '{idx: 2, start_addr: 28, end_addr: 29},  // int_core_master_ni_3_0
      '{idx: 2, start_addr: 36, end_addr: 51},  // llc_slave_ni
      '{idx: 2, start_addr: 58, end_addr: 59},  // int_core_slave_ni_1_0
      '{idx: 2, start_addr: 66, end_addr: 67},  // int_core_slave_ni_2_0
      '{idx: 2, start_addr: 74, end_addr: 75},  // int_core_slave_ni_3_0
      '{idx: 2, start_addr: 82, end_addr: 83},  // fp_core_slave_ni_0_0
      '{idx: 2, start_addr: 90, end_addr: 92},  // sp_slave_ni
      '{idx: 0, start_addr: 5, end_addr: 6},  // int_core_master_ni_0_1
      '{idx: 3, start_addr: 6, end_addr: 12},  // int_core_master_ni_0_2
      '{idx: 3, start_addr: 14, end_addr: 20},  // int_core_master_ni_1_2
      '{idx: 3, start_addr: 22, end_addr: 28},  // int_core_master_ni_2_2
      '{idx: 3, start_addr: 30, end_addr: 36},  // int_core_master_ni_3_2
      '{idx: 3, start_addr: 52, end_addr: 58},  // int_core_slave_ni_0_2
      '{idx: 3, start_addr: 60, end_addr: 66},  // int_core_slave_ni_1_2
      '{idx: 3, start_addr: 68, end_addr: 74},  // int_core_slave_ni_2_2
      '{idx: 3, start_addr: 76, end_addr: 82},  // int_core_slave_ni_3_2
      '{idx: 3, start_addr: 84, end_addr: 90},  // fp_core_slave_ni_0_2
      '{idx: 4, start_addr: 13, end_addr: 14},  // int_core_master_ni_1_1
      '{idx: 4, start_addr: 21, end_addr: 22},  // int_core_master_ni_2_1
      '{idx: 4, start_addr: 29, end_addr: 30},  // int_core_master_ni_3_1
      '{idx: 4, start_addr: 59, end_addr: 60},  // int_core_slave_ni_1_1
      '{idx: 4, start_addr: 67, end_addr: 68},  // int_core_slave_ni_2_1
      '{idx: 4, start_addr: 75, end_addr: 76},  // int_core_slave_ni_3_1
      '{idx: 4, start_addr: 83, end_addr: 84},  // fp_core_slave_ni_0_1
      '{idx: 1, start_addr: 51, end_addr: 52}  // int_core_slave_ni_0_1

  };


  floo_req_t [4:0] mesh_router_0_1_req_in;
  floo_rsp_t [4:0] mesh_router_0_1_rsp_out;
  floo_req_t [4:0] mesh_router_0_1_req_out;
  floo_rsp_t [4:0] mesh_router_0_1_rsp_in;

  assign mesh_router_0_1_req_in[0] = int_core_master_ni_0_1_to_mesh_router_0_1_req;
  assign mesh_router_0_1_req_in[1] = int_core_slave_ni_0_1_to_mesh_router_0_1_req;
  assign mesh_router_0_1_req_in[2] = mesh_router_0_0_to_mesh_router_0_1_req;
  assign mesh_router_0_1_req_in[3] = mesh_router_0_2_to_mesh_router_0_1_req;
  assign mesh_router_0_1_req_in[4] = mesh_router_1_1_to_mesh_router_0_1_req;

  assign mesh_router_0_1_to_int_core_master_ni_0_1_rsp = mesh_router_0_1_rsp_out[0];
  assign mesh_router_0_1_to_int_core_slave_ni_0_1_rsp = mesh_router_0_1_rsp_out[1];
  assign mesh_router_0_1_to_mesh_router_0_0_rsp = mesh_router_0_1_rsp_out[2];
  assign mesh_router_0_1_to_mesh_router_0_2_rsp = mesh_router_0_1_rsp_out[3];
  assign mesh_router_0_1_to_mesh_router_1_1_rsp = mesh_router_0_1_rsp_out[4];

  assign mesh_router_0_1_to_int_core_master_ni_0_1_req = mesh_router_0_1_req_out[0];
  assign mesh_router_0_1_to_int_core_slave_ni_0_1_req = mesh_router_0_1_req_out[1];
  assign mesh_router_0_1_to_mesh_router_0_0_req = mesh_router_0_1_req_out[2];
  assign mesh_router_0_1_to_mesh_router_0_2_req = mesh_router_0_1_req_out[3];
  assign mesh_router_0_1_to_mesh_router_1_1_req = mesh_router_0_1_req_out[4];

  assign mesh_router_0_1_rsp_in[0] = int_core_master_ni_0_1_to_mesh_router_0_1_rsp;
  assign mesh_router_0_1_rsp_in[1] = int_core_slave_ni_0_1_to_mesh_router_0_1_rsp;
  assign mesh_router_0_1_rsp_in[2] = mesh_router_0_0_to_mesh_router_0_1_rsp;
  assign mesh_router_0_1_rsp_in[3] = mesh_router_0_2_to_mesh_router_0_1_rsp;
  assign mesh_router_0_1_rsp_in[4] = mesh_router_1_1_to_mesh_router_0_1_rsp;


  floo_axi_router #(
      .AxiCfg(AxiCfg),
      .RouteAlgo(IdTable),
      .NumRoutes(5),
      .NumInputs(5),
      .NumOutputs(5),
      .InFifoDepth(2),
      .OutFifoDepth(2),
      .id_t(id_t),
      .hdr_t(hdr_t),
      .NumAddrRules(28),
      .addr_rule_t(mesh_router_0_1_map_rule_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) mesh_router_0_1 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('0),
      .id_route_map_i(MeshRouter01Map),
      .floo_req_i(mesh_router_0_1_req_in),
      .floo_rsp_o(mesh_router_0_1_rsp_out),
      .floo_req_o(mesh_router_0_1_req_out),
      .floo_rsp_i(mesh_router_0_1_rsp_in)
  );

  localparam int unsigned MeshRouter02MapNumRules = 28;

  typedef struct packed {
    id_t idx;
    id_t start_addr;
    id_t end_addr;
  } mesh_router_0_2_map_rule_t;

  localparam mesh_router_0_2_map_rule_t [MeshRouter02MapNumRules-1:0] MeshRouter02Map = '{
      '{idx: 2, start_addr: 0, end_addr: 6},  // cpu_master_ni
      '{idx: 2, start_addr: 12, end_addr: 14},  // int_core_master_ni_1_0
      '{idx: 2, start_addr: 20, end_addr: 22},  // int_core_master_ni_2_0
      '{idx: 2, start_addr: 28, end_addr: 30},  // int_core_master_ni_3_0
      '{idx: 2, start_addr: 36, end_addr: 52},  // llc_slave_ni
      '{idx: 2, start_addr: 58, end_addr: 60},  // int_core_slave_ni_1_0
      '{idx: 2, start_addr: 66, end_addr: 68},  // int_core_slave_ni_2_0
      '{idx: 2, start_addr: 74, end_addr: 76},  // int_core_slave_ni_3_0
      '{idx: 2, start_addr: 82, end_addr: 84},  // fp_core_slave_ni_0_0
      '{idx: 2, start_addr: 90, end_addr: 92},  // sp_slave_ni
      '{idx: 0, start_addr: 6, end_addr: 7},  // int_core_master_ni_0_2
      '{idx: 3, start_addr: 7, end_addr: 12},  // int_core_master_ni_0_3
      '{idx: 3, start_addr: 15, end_addr: 20},  // int_core_master_ni_1_3
      '{idx: 3, start_addr: 23, end_addr: 28},  // int_core_master_ni_2_3
      '{idx: 3, start_addr: 31, end_addr: 36},  // int_core_master_ni_3_3
      '{idx: 3, start_addr: 53, end_addr: 58},  // int_core_slave_ni_0_3
      '{idx: 3, start_addr: 61, end_addr: 66},  // int_core_slave_ni_1_3
      '{idx: 3, start_addr: 69, end_addr: 74},  // int_core_slave_ni_2_3
      '{idx: 3, start_addr: 77, end_addr: 82},  // int_core_slave_ni_3_3
      '{idx: 3, start_addr: 85, end_addr: 90},  // fp_core_slave_ni_0_3
      '{idx: 4, start_addr: 14, end_addr: 15},  // int_core_master_ni_1_2
      '{idx: 4, start_addr: 22, end_addr: 23},  // int_core_master_ni_2_2
      '{idx: 4, start_addr: 30, end_addr: 31},  // int_core_master_ni_3_2
      '{idx: 4, start_addr: 60, end_addr: 61},  // int_core_slave_ni_1_2
      '{idx: 4, start_addr: 68, end_addr: 69},  // int_core_slave_ni_2_2
      '{idx: 4, start_addr: 76, end_addr: 77},  // int_core_slave_ni_3_2
      '{idx: 4, start_addr: 84, end_addr: 85},  // fp_core_slave_ni_0_2
      '{idx: 1, start_addr: 52, end_addr: 53}  // int_core_slave_ni_0_2

  };


  floo_req_t [4:0] mesh_router_0_2_req_in;
  floo_rsp_t [4:0] mesh_router_0_2_rsp_out;
  floo_req_t [4:0] mesh_router_0_2_req_out;
  floo_rsp_t [4:0] mesh_router_0_2_rsp_in;

  assign mesh_router_0_2_req_in[0] = int_core_master_ni_0_2_to_mesh_router_0_2_req;
  assign mesh_router_0_2_req_in[1] = int_core_slave_ni_0_2_to_mesh_router_0_2_req;
  assign mesh_router_0_2_req_in[2] = mesh_router_0_1_to_mesh_router_0_2_req;
  assign mesh_router_0_2_req_in[3] = mesh_router_0_3_to_mesh_router_0_2_req;
  assign mesh_router_0_2_req_in[4] = mesh_router_1_2_to_mesh_router_0_2_req;

  assign mesh_router_0_2_to_int_core_master_ni_0_2_rsp = mesh_router_0_2_rsp_out[0];
  assign mesh_router_0_2_to_int_core_slave_ni_0_2_rsp = mesh_router_0_2_rsp_out[1];
  assign mesh_router_0_2_to_mesh_router_0_1_rsp = mesh_router_0_2_rsp_out[2];
  assign mesh_router_0_2_to_mesh_router_0_3_rsp = mesh_router_0_2_rsp_out[3];
  assign mesh_router_0_2_to_mesh_router_1_2_rsp = mesh_router_0_2_rsp_out[4];

  assign mesh_router_0_2_to_int_core_master_ni_0_2_req = mesh_router_0_2_req_out[0];
  assign mesh_router_0_2_to_int_core_slave_ni_0_2_req = mesh_router_0_2_req_out[1];
  assign mesh_router_0_2_to_mesh_router_0_1_req = mesh_router_0_2_req_out[2];
  assign mesh_router_0_2_to_mesh_router_0_3_req = mesh_router_0_2_req_out[3];
  assign mesh_router_0_2_to_mesh_router_1_2_req = mesh_router_0_2_req_out[4];

  assign mesh_router_0_2_rsp_in[0] = int_core_master_ni_0_2_to_mesh_router_0_2_rsp;
  assign mesh_router_0_2_rsp_in[1] = int_core_slave_ni_0_2_to_mesh_router_0_2_rsp;
  assign mesh_router_0_2_rsp_in[2] = mesh_router_0_1_to_mesh_router_0_2_rsp;
  assign mesh_router_0_2_rsp_in[3] = mesh_router_0_3_to_mesh_router_0_2_rsp;
  assign mesh_router_0_2_rsp_in[4] = mesh_router_1_2_to_mesh_router_0_2_rsp;


  floo_axi_router #(
      .AxiCfg(AxiCfg),
      .RouteAlgo(IdTable),
      .NumRoutes(5),
      .NumInputs(5),
      .NumOutputs(5),
      .InFifoDepth(2),
      .OutFifoDepth(2),
      .id_t(id_t),
      .hdr_t(hdr_t),
      .NumAddrRules(28),
      .addr_rule_t(mesh_router_0_2_map_rule_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) mesh_router_0_2 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('0),
      .id_route_map_i(MeshRouter02Map),
      .floo_req_i(mesh_router_0_2_req_in),
      .floo_rsp_o(mesh_router_0_2_rsp_out),
      .floo_req_o(mesh_router_0_2_req_out),
      .floo_rsp_i(mesh_router_0_2_rsp_in)
  );

  localparam int unsigned MeshRouter03MapNumRules = 28;

  typedef struct packed {
    id_t idx;
    id_t start_addr;
    id_t end_addr;
  } mesh_router_0_3_map_rule_t;

  localparam mesh_router_0_3_map_rule_t [MeshRouter03MapNumRules-1:0] MeshRouter03Map = '{
      '{idx: 2, start_addr: 0, end_addr: 7},  // cpu_master_ni
      '{idx: 2, start_addr: 12, end_addr: 15},  // int_core_master_ni_1_0
      '{idx: 2, start_addr: 20, end_addr: 23},  // int_core_master_ni_2_0
      '{idx: 2, start_addr: 28, end_addr: 31},  // int_core_master_ni_3_0
      '{idx: 2, start_addr: 36, end_addr: 53},  // llc_slave_ni
      '{idx: 2, start_addr: 58, end_addr: 61},  // int_core_slave_ni_1_0
      '{idx: 2, start_addr: 66, end_addr: 69},  // int_core_slave_ni_2_0
      '{idx: 2, start_addr: 74, end_addr: 77},  // int_core_slave_ni_3_0
      '{idx: 2, start_addr: 82, end_addr: 85},  // fp_core_slave_ni_0_0
      '{idx: 2, start_addr: 90, end_addr: 92},  // sp_slave_ni
      '{idx: 0, start_addr: 7, end_addr: 8},  // int_core_master_ni_0_3
      '{idx: 3, start_addr: 8, end_addr: 12},  // int_core_master_ni_0_4
      '{idx: 3, start_addr: 16, end_addr: 20},  // int_core_master_ni_1_4
      '{idx: 3, start_addr: 24, end_addr: 28},  // int_core_master_ni_2_4
      '{idx: 3, start_addr: 32, end_addr: 36},  // int_core_master_ni_3_4
      '{idx: 3, start_addr: 54, end_addr: 58},  // int_core_slave_ni_0_4
      '{idx: 3, start_addr: 62, end_addr: 66},  // int_core_slave_ni_1_4
      '{idx: 3, start_addr: 70, end_addr: 74},  // int_core_slave_ni_2_4
      '{idx: 3, start_addr: 78, end_addr: 82},  // int_core_slave_ni_3_4
      '{idx: 3, start_addr: 86, end_addr: 90},  // fp_core_slave_ni_0_4
      '{idx: 4, start_addr: 15, end_addr: 16},  // int_core_master_ni_1_3
      '{idx: 4, start_addr: 23, end_addr: 24},  // int_core_master_ni_2_3
      '{idx: 4, start_addr: 31, end_addr: 32},  // int_core_master_ni_3_3
      '{idx: 4, start_addr: 61, end_addr: 62},  // int_core_slave_ni_1_3
      '{idx: 4, start_addr: 69, end_addr: 70},  // int_core_slave_ni_2_3
      '{idx: 4, start_addr: 77, end_addr: 78},  // int_core_slave_ni_3_3
      '{idx: 4, start_addr: 85, end_addr: 86},  // fp_core_slave_ni_0_3
      '{idx: 1, start_addr: 53, end_addr: 54}  // int_core_slave_ni_0_3

  };


  floo_req_t [4:0] mesh_router_0_3_req_in;
  floo_rsp_t [4:0] mesh_router_0_3_rsp_out;
  floo_req_t [4:0] mesh_router_0_3_req_out;
  floo_rsp_t [4:0] mesh_router_0_3_rsp_in;

  assign mesh_router_0_3_req_in[0] = int_core_master_ni_0_3_to_mesh_router_0_3_req;
  assign mesh_router_0_3_req_in[1] = int_core_slave_ni_0_3_to_mesh_router_0_3_req;
  assign mesh_router_0_3_req_in[2] = mesh_router_0_2_to_mesh_router_0_3_req;
  assign mesh_router_0_3_req_in[3] = mesh_router_0_4_to_mesh_router_0_3_req;
  assign mesh_router_0_3_req_in[4] = mesh_router_1_3_to_mesh_router_0_3_req;

  assign mesh_router_0_3_to_int_core_master_ni_0_3_rsp = mesh_router_0_3_rsp_out[0];
  assign mesh_router_0_3_to_int_core_slave_ni_0_3_rsp = mesh_router_0_3_rsp_out[1];
  assign mesh_router_0_3_to_mesh_router_0_2_rsp = mesh_router_0_3_rsp_out[2];
  assign mesh_router_0_3_to_mesh_router_0_4_rsp = mesh_router_0_3_rsp_out[3];
  assign mesh_router_0_3_to_mesh_router_1_3_rsp = mesh_router_0_3_rsp_out[4];

  assign mesh_router_0_3_to_int_core_master_ni_0_3_req = mesh_router_0_3_req_out[0];
  assign mesh_router_0_3_to_int_core_slave_ni_0_3_req = mesh_router_0_3_req_out[1];
  assign mesh_router_0_3_to_mesh_router_0_2_req = mesh_router_0_3_req_out[2];
  assign mesh_router_0_3_to_mesh_router_0_4_req = mesh_router_0_3_req_out[3];
  assign mesh_router_0_3_to_mesh_router_1_3_req = mesh_router_0_3_req_out[4];

  assign mesh_router_0_3_rsp_in[0] = int_core_master_ni_0_3_to_mesh_router_0_3_rsp;
  assign mesh_router_0_3_rsp_in[1] = int_core_slave_ni_0_3_to_mesh_router_0_3_rsp;
  assign mesh_router_0_3_rsp_in[2] = mesh_router_0_2_to_mesh_router_0_3_rsp;
  assign mesh_router_0_3_rsp_in[3] = mesh_router_0_4_to_mesh_router_0_3_rsp;
  assign mesh_router_0_3_rsp_in[4] = mesh_router_1_3_to_mesh_router_0_3_rsp;


  floo_axi_router #(
      .AxiCfg(AxiCfg),
      .RouteAlgo(IdTable),
      .NumRoutes(5),
      .NumInputs(5),
      .NumOutputs(5),
      .InFifoDepth(2),
      .OutFifoDepth(2),
      .id_t(id_t),
      .hdr_t(hdr_t),
      .NumAddrRules(28),
      .addr_rule_t(mesh_router_0_3_map_rule_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) mesh_router_0_3 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('0),
      .id_route_map_i(MeshRouter03Map),
      .floo_req_i(mesh_router_0_3_req_in),
      .floo_rsp_o(mesh_router_0_3_rsp_out),
      .floo_req_o(mesh_router_0_3_req_out),
      .floo_rsp_i(mesh_router_0_3_rsp_in)
  );

  localparam int unsigned MeshRouter04MapNumRules = 28;

  typedef struct packed {
    id_t idx;
    id_t start_addr;
    id_t end_addr;
  } mesh_router_0_4_map_rule_t;

  localparam mesh_router_0_4_map_rule_t [MeshRouter04MapNumRules-1:0] MeshRouter04Map = '{
      '{idx: 2, start_addr: 0, end_addr: 8},  // cpu_master_ni
      '{idx: 2, start_addr: 12, end_addr: 16},  // int_core_master_ni_1_0
      '{idx: 2, start_addr: 20, end_addr: 24},  // int_core_master_ni_2_0
      '{idx: 2, start_addr: 28, end_addr: 32},  // int_core_master_ni_3_0
      '{idx: 2, start_addr: 36, end_addr: 54},  // llc_slave_ni
      '{idx: 2, start_addr: 58, end_addr: 62},  // int_core_slave_ni_1_0
      '{idx: 2, start_addr: 66, end_addr: 70},  // int_core_slave_ni_2_0
      '{idx: 2, start_addr: 74, end_addr: 78},  // int_core_slave_ni_3_0
      '{idx: 2, start_addr: 82, end_addr: 86},  // fp_core_slave_ni_0_0
      '{idx: 2, start_addr: 90, end_addr: 92},  // sp_slave_ni
      '{idx: 0, start_addr: 8, end_addr: 9},  // int_core_master_ni_0_4
      '{idx: 3, start_addr: 9, end_addr: 12},  // int_core_master_ni_0_5
      '{idx: 3, start_addr: 17, end_addr: 20},  // int_core_master_ni_1_5
      '{idx: 3, start_addr: 25, end_addr: 28},  // int_core_master_ni_2_5
      '{idx: 3, start_addr: 33, end_addr: 36},  // int_core_master_ni_3_5
      '{idx: 3, start_addr: 55, end_addr: 58},  // int_core_slave_ni_0_5
      '{idx: 3, start_addr: 63, end_addr: 66},  // int_core_slave_ni_1_5
      '{idx: 3, start_addr: 71, end_addr: 74},  // int_core_slave_ni_2_5
      '{idx: 3, start_addr: 79, end_addr: 82},  // int_core_slave_ni_3_5
      '{idx: 3, start_addr: 87, end_addr: 90},  // fp_core_slave_ni_0_5
      '{idx: 4, start_addr: 16, end_addr: 17},  // int_core_master_ni_1_4
      '{idx: 4, start_addr: 24, end_addr: 25},  // int_core_master_ni_2_4
      '{idx: 4, start_addr: 32, end_addr: 33},  // int_core_master_ni_3_4
      '{idx: 4, start_addr: 62, end_addr: 63},  // int_core_slave_ni_1_4
      '{idx: 4, start_addr: 70, end_addr: 71},  // int_core_slave_ni_2_4
      '{idx: 4, start_addr: 78, end_addr: 79},  // int_core_slave_ni_3_4
      '{idx: 4, start_addr: 86, end_addr: 87},  // fp_core_slave_ni_0_4
      '{idx: 1, start_addr: 54, end_addr: 55}  // int_core_slave_ni_0_4

  };


  floo_req_t [4:0] mesh_router_0_4_req_in;
  floo_rsp_t [4:0] mesh_router_0_4_rsp_out;
  floo_req_t [4:0] mesh_router_0_4_req_out;
  floo_rsp_t [4:0] mesh_router_0_4_rsp_in;

  assign mesh_router_0_4_req_in[0] = int_core_master_ni_0_4_to_mesh_router_0_4_req;
  assign mesh_router_0_4_req_in[1] = int_core_slave_ni_0_4_to_mesh_router_0_4_req;
  assign mesh_router_0_4_req_in[2] = mesh_router_0_3_to_mesh_router_0_4_req;
  assign mesh_router_0_4_req_in[3] = mesh_router_0_5_to_mesh_router_0_4_req;
  assign mesh_router_0_4_req_in[4] = mesh_router_1_4_to_mesh_router_0_4_req;

  assign mesh_router_0_4_to_int_core_master_ni_0_4_rsp = mesh_router_0_4_rsp_out[0];
  assign mesh_router_0_4_to_int_core_slave_ni_0_4_rsp = mesh_router_0_4_rsp_out[1];
  assign mesh_router_0_4_to_mesh_router_0_3_rsp = mesh_router_0_4_rsp_out[2];
  assign mesh_router_0_4_to_mesh_router_0_5_rsp = mesh_router_0_4_rsp_out[3];
  assign mesh_router_0_4_to_mesh_router_1_4_rsp = mesh_router_0_4_rsp_out[4];

  assign mesh_router_0_4_to_int_core_master_ni_0_4_req = mesh_router_0_4_req_out[0];
  assign mesh_router_0_4_to_int_core_slave_ni_0_4_req = mesh_router_0_4_req_out[1];
  assign mesh_router_0_4_to_mesh_router_0_3_req = mesh_router_0_4_req_out[2];
  assign mesh_router_0_4_to_mesh_router_0_5_req = mesh_router_0_4_req_out[3];
  assign mesh_router_0_4_to_mesh_router_1_4_req = mesh_router_0_4_req_out[4];

  assign mesh_router_0_4_rsp_in[0] = int_core_master_ni_0_4_to_mesh_router_0_4_rsp;
  assign mesh_router_0_4_rsp_in[1] = int_core_slave_ni_0_4_to_mesh_router_0_4_rsp;
  assign mesh_router_0_4_rsp_in[2] = mesh_router_0_3_to_mesh_router_0_4_rsp;
  assign mesh_router_0_4_rsp_in[3] = mesh_router_0_5_to_mesh_router_0_4_rsp;
  assign mesh_router_0_4_rsp_in[4] = mesh_router_1_4_to_mesh_router_0_4_rsp;


  floo_axi_router #(
      .AxiCfg(AxiCfg),
      .RouteAlgo(IdTable),
      .NumRoutes(5),
      .NumInputs(5),
      .NumOutputs(5),
      .InFifoDepth(2),
      .OutFifoDepth(2),
      .id_t(id_t),
      .hdr_t(hdr_t),
      .NumAddrRules(28),
      .addr_rule_t(mesh_router_0_4_map_rule_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) mesh_router_0_4 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('0),
      .id_route_map_i(MeshRouter04Map),
      .floo_req_i(mesh_router_0_4_req_in),
      .floo_rsp_o(mesh_router_0_4_rsp_out),
      .floo_req_o(mesh_router_0_4_req_out),
      .floo_rsp_i(mesh_router_0_4_rsp_in)
  );

  localparam int unsigned MeshRouter05MapNumRules = 28;

  typedef struct packed {
    id_t idx;
    id_t start_addr;
    id_t end_addr;
  } mesh_router_0_5_map_rule_t;

  localparam mesh_router_0_5_map_rule_t [MeshRouter05MapNumRules-1:0] MeshRouter05Map = '{
      '{idx: 2, start_addr: 0, end_addr: 9},  // cpu_master_ni
      '{idx: 2, start_addr: 12, end_addr: 17},  // int_core_master_ni_1_0
      '{idx: 2, start_addr: 20, end_addr: 25},  // int_core_master_ni_2_0
      '{idx: 2, start_addr: 28, end_addr: 33},  // int_core_master_ni_3_0
      '{idx: 2, start_addr: 36, end_addr: 55},  // llc_slave_ni
      '{idx: 2, start_addr: 58, end_addr: 63},  // int_core_slave_ni_1_0
      '{idx: 2, start_addr: 66, end_addr: 71},  // int_core_slave_ni_2_0
      '{idx: 2, start_addr: 74, end_addr: 79},  // int_core_slave_ni_3_0
      '{idx: 2, start_addr: 82, end_addr: 87},  // fp_core_slave_ni_0_0
      '{idx: 2, start_addr: 90, end_addr: 92},  // sp_slave_ni
      '{idx: 0, start_addr: 9, end_addr: 10},  // int_core_master_ni_0_5
      '{idx: 3, start_addr: 10, end_addr: 12},  // int_core_master_ni_0_6
      '{idx: 3, start_addr: 18, end_addr: 20},  // int_core_master_ni_1_6
      '{idx: 3, start_addr: 26, end_addr: 28},  // int_core_master_ni_2_6
      '{idx: 3, start_addr: 34, end_addr: 36},  // int_core_master_ni_3_6
      '{idx: 3, start_addr: 56, end_addr: 58},  // int_core_slave_ni_0_6
      '{idx: 3, start_addr: 64, end_addr: 66},  // int_core_slave_ni_1_6
      '{idx: 3, start_addr: 72, end_addr: 74},  // int_core_slave_ni_2_6
      '{idx: 3, start_addr: 80, end_addr: 82},  // int_core_slave_ni_3_6
      '{idx: 3, start_addr: 88, end_addr: 90},  // fp_core_slave_ni_0_6
      '{idx: 4, start_addr: 17, end_addr: 18},  // int_core_master_ni_1_5
      '{idx: 4, start_addr: 25, end_addr: 26},  // int_core_master_ni_2_5
      '{idx: 4, start_addr: 33, end_addr: 34},  // int_core_master_ni_3_5
      '{idx: 4, start_addr: 63, end_addr: 64},  // int_core_slave_ni_1_5
      '{idx: 4, start_addr: 71, end_addr: 72},  // int_core_slave_ni_2_5
      '{idx: 4, start_addr: 79, end_addr: 80},  // int_core_slave_ni_3_5
      '{idx: 4, start_addr: 87, end_addr: 88},  // fp_core_slave_ni_0_5
      '{idx: 1, start_addr: 55, end_addr: 56}  // int_core_slave_ni_0_5

  };


  floo_req_t [4:0] mesh_router_0_5_req_in;
  floo_rsp_t [4:0] mesh_router_0_5_rsp_out;
  floo_req_t [4:0] mesh_router_0_5_req_out;
  floo_rsp_t [4:0] mesh_router_0_5_rsp_in;

  assign mesh_router_0_5_req_in[0] = int_core_master_ni_0_5_to_mesh_router_0_5_req;
  assign mesh_router_0_5_req_in[1] = int_core_slave_ni_0_5_to_mesh_router_0_5_req;
  assign mesh_router_0_5_req_in[2] = mesh_router_0_4_to_mesh_router_0_5_req;
  assign mesh_router_0_5_req_in[3] = mesh_router_0_6_to_mesh_router_0_5_req;
  assign mesh_router_0_5_req_in[4] = mesh_router_1_5_to_mesh_router_0_5_req;

  assign mesh_router_0_5_to_int_core_master_ni_0_5_rsp = mesh_router_0_5_rsp_out[0];
  assign mesh_router_0_5_to_int_core_slave_ni_0_5_rsp = mesh_router_0_5_rsp_out[1];
  assign mesh_router_0_5_to_mesh_router_0_4_rsp = mesh_router_0_5_rsp_out[2];
  assign mesh_router_0_5_to_mesh_router_0_6_rsp = mesh_router_0_5_rsp_out[3];
  assign mesh_router_0_5_to_mesh_router_1_5_rsp = mesh_router_0_5_rsp_out[4];

  assign mesh_router_0_5_to_int_core_master_ni_0_5_req = mesh_router_0_5_req_out[0];
  assign mesh_router_0_5_to_int_core_slave_ni_0_5_req = mesh_router_0_5_req_out[1];
  assign mesh_router_0_5_to_mesh_router_0_4_req = mesh_router_0_5_req_out[2];
  assign mesh_router_0_5_to_mesh_router_0_6_req = mesh_router_0_5_req_out[3];
  assign mesh_router_0_5_to_mesh_router_1_5_req = mesh_router_0_5_req_out[4];

  assign mesh_router_0_5_rsp_in[0] = int_core_master_ni_0_5_to_mesh_router_0_5_rsp;
  assign mesh_router_0_5_rsp_in[1] = int_core_slave_ni_0_5_to_mesh_router_0_5_rsp;
  assign mesh_router_0_5_rsp_in[2] = mesh_router_0_4_to_mesh_router_0_5_rsp;
  assign mesh_router_0_5_rsp_in[3] = mesh_router_0_6_to_mesh_router_0_5_rsp;
  assign mesh_router_0_5_rsp_in[4] = mesh_router_1_5_to_mesh_router_0_5_rsp;


  floo_axi_router #(
      .AxiCfg(AxiCfg),
      .RouteAlgo(IdTable),
      .NumRoutes(5),
      .NumInputs(5),
      .NumOutputs(5),
      .InFifoDepth(2),
      .OutFifoDepth(2),
      .id_t(id_t),
      .hdr_t(hdr_t),
      .NumAddrRules(28),
      .addr_rule_t(mesh_router_0_5_map_rule_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) mesh_router_0_5 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('0),
      .id_route_map_i(MeshRouter05Map),
      .floo_req_i(mesh_router_0_5_req_in),
      .floo_rsp_o(mesh_router_0_5_rsp_out),
      .floo_req_o(mesh_router_0_5_req_out),
      .floo_rsp_i(mesh_router_0_5_rsp_in)
  );

  localparam int unsigned MeshRouter06MapNumRules = 28;

  typedef struct packed {
    id_t idx;
    id_t start_addr;
    id_t end_addr;
  } mesh_router_0_6_map_rule_t;

  localparam mesh_router_0_6_map_rule_t [MeshRouter06MapNumRules-1:0] MeshRouter06Map = '{
      '{idx: 2, start_addr: 0, end_addr: 10},  // cpu_master_ni
      '{idx: 2, start_addr: 12, end_addr: 18},  // int_core_master_ni_1_0
      '{idx: 2, start_addr: 20, end_addr: 26},  // int_core_master_ni_2_0
      '{idx: 2, start_addr: 28, end_addr: 34},  // int_core_master_ni_3_0
      '{idx: 2, start_addr: 36, end_addr: 56},  // llc_slave_ni
      '{idx: 2, start_addr: 58, end_addr: 64},  // int_core_slave_ni_1_0
      '{idx: 2, start_addr: 66, end_addr: 72},  // int_core_slave_ni_2_0
      '{idx: 2, start_addr: 74, end_addr: 80},  // int_core_slave_ni_3_0
      '{idx: 2, start_addr: 82, end_addr: 88},  // fp_core_slave_ni_0_0
      '{idx: 2, start_addr: 90, end_addr: 92},  // sp_slave_ni
      '{idx: 0, start_addr: 10, end_addr: 11},  // int_core_master_ni_0_6
      '{idx: 3, start_addr: 11, end_addr: 12},  // int_core_master_ni_0_7
      '{idx: 3, start_addr: 19, end_addr: 20},  // int_core_master_ni_1_7
      '{idx: 3, start_addr: 27, end_addr: 28},  // int_core_master_ni_2_7
      '{idx: 3, start_addr: 35, end_addr: 36},  // int_core_master_ni_3_7
      '{idx: 3, start_addr: 57, end_addr: 58},  // int_core_slave_ni_0_7
      '{idx: 3, start_addr: 65, end_addr: 66},  // int_core_slave_ni_1_7
      '{idx: 3, start_addr: 73, end_addr: 74},  // int_core_slave_ni_2_7
      '{idx: 3, start_addr: 81, end_addr: 82},  // int_core_slave_ni_3_7
      '{idx: 3, start_addr: 89, end_addr: 90},  // fp_core_slave_ni_0_7
      '{idx: 4, start_addr: 18, end_addr: 19},  // int_core_master_ni_1_6
      '{idx: 4, start_addr: 26, end_addr: 27},  // int_core_master_ni_2_6
      '{idx: 4, start_addr: 34, end_addr: 35},  // int_core_master_ni_3_6
      '{idx: 4, start_addr: 64, end_addr: 65},  // int_core_slave_ni_1_6
      '{idx: 4, start_addr: 72, end_addr: 73},  // int_core_slave_ni_2_6
      '{idx: 4, start_addr: 80, end_addr: 81},  // int_core_slave_ni_3_6
      '{idx: 4, start_addr: 88, end_addr: 89},  // fp_core_slave_ni_0_6
      '{idx: 1, start_addr: 56, end_addr: 57}  // int_core_slave_ni_0_6

  };


  floo_req_t [4:0] mesh_router_0_6_req_in;
  floo_rsp_t [4:0] mesh_router_0_6_rsp_out;
  floo_req_t [4:0] mesh_router_0_6_req_out;
  floo_rsp_t [4:0] mesh_router_0_6_rsp_in;

  assign mesh_router_0_6_req_in[0] = int_core_master_ni_0_6_to_mesh_router_0_6_req;
  assign mesh_router_0_6_req_in[1] = int_core_slave_ni_0_6_to_mesh_router_0_6_req;
  assign mesh_router_0_6_req_in[2] = mesh_router_0_5_to_mesh_router_0_6_req;
  assign mesh_router_0_6_req_in[3] = mesh_router_0_7_to_mesh_router_0_6_req;
  assign mesh_router_0_6_req_in[4] = mesh_router_1_6_to_mesh_router_0_6_req;

  assign mesh_router_0_6_to_int_core_master_ni_0_6_rsp = mesh_router_0_6_rsp_out[0];
  assign mesh_router_0_6_to_int_core_slave_ni_0_6_rsp = mesh_router_0_6_rsp_out[1];
  assign mesh_router_0_6_to_mesh_router_0_5_rsp = mesh_router_0_6_rsp_out[2];
  assign mesh_router_0_6_to_mesh_router_0_7_rsp = mesh_router_0_6_rsp_out[3];
  assign mesh_router_0_6_to_mesh_router_1_6_rsp = mesh_router_0_6_rsp_out[4];

  assign mesh_router_0_6_to_int_core_master_ni_0_6_req = mesh_router_0_6_req_out[0];
  assign mesh_router_0_6_to_int_core_slave_ni_0_6_req = mesh_router_0_6_req_out[1];
  assign mesh_router_0_6_to_mesh_router_0_5_req = mesh_router_0_6_req_out[2];
  assign mesh_router_0_6_to_mesh_router_0_7_req = mesh_router_0_6_req_out[3];
  assign mesh_router_0_6_to_mesh_router_1_6_req = mesh_router_0_6_req_out[4];

  assign mesh_router_0_6_rsp_in[0] = int_core_master_ni_0_6_to_mesh_router_0_6_rsp;
  assign mesh_router_0_6_rsp_in[1] = int_core_slave_ni_0_6_to_mesh_router_0_6_rsp;
  assign mesh_router_0_6_rsp_in[2] = mesh_router_0_5_to_mesh_router_0_6_rsp;
  assign mesh_router_0_6_rsp_in[3] = mesh_router_0_7_to_mesh_router_0_6_rsp;
  assign mesh_router_0_6_rsp_in[4] = mesh_router_1_6_to_mesh_router_0_6_rsp;


  floo_axi_router #(
      .AxiCfg(AxiCfg),
      .RouteAlgo(IdTable),
      .NumRoutes(5),
      .NumInputs(5),
      .NumOutputs(5),
      .InFifoDepth(2),
      .OutFifoDepth(2),
      .id_t(id_t),
      .hdr_t(hdr_t),
      .NumAddrRules(28),
      .addr_rule_t(mesh_router_0_6_map_rule_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) mesh_router_0_6 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('0),
      .id_route_map_i(MeshRouter06Map),
      .floo_req_i(mesh_router_0_6_req_in),
      .floo_rsp_o(mesh_router_0_6_rsp_out),
      .floo_req_o(mesh_router_0_6_req_out),
      .floo_rsp_i(mesh_router_0_6_rsp_in)
  );

  localparam int unsigned MeshRouter07MapNumRules = 19;

  typedef struct packed {
    id_t idx;
    id_t start_addr;
    id_t end_addr;
  } mesh_router_0_7_map_rule_t;

  localparam mesh_router_0_7_map_rule_t [MeshRouter07MapNumRules-1:0] MeshRouter07Map = '{
      '{idx: 2, start_addr: 0, end_addr: 11},  // cpu_master_ni
      '{idx: 2, start_addr: 12, end_addr: 19},  // int_core_master_ni_1_0
      '{idx: 2, start_addr: 20, end_addr: 27},  // int_core_master_ni_2_0
      '{idx: 2, start_addr: 28, end_addr: 35},  // int_core_master_ni_3_0
      '{idx: 2, start_addr: 36, end_addr: 57},  // llc_slave_ni
      '{idx: 2, start_addr: 58, end_addr: 65},  // int_core_slave_ni_1_0
      '{idx: 2, start_addr: 66, end_addr: 73},  // int_core_slave_ni_2_0
      '{idx: 2, start_addr: 74, end_addr: 81},  // int_core_slave_ni_3_0
      '{idx: 2, start_addr: 82, end_addr: 89},  // fp_core_slave_ni_0_0
      '{idx: 2, start_addr: 90, end_addr: 92},  // sp_slave_ni
      '{idx: 0, start_addr: 11, end_addr: 12},  // int_core_master_ni_0_7
      '{idx: 3, start_addr: 19, end_addr: 20},  // int_core_master_ni_1_7
      '{idx: 3, start_addr: 27, end_addr: 28},  // int_core_master_ni_2_7
      '{idx: 3, start_addr: 35, end_addr: 36},  // int_core_master_ni_3_7
      '{idx: 3, start_addr: 65, end_addr: 66},  // int_core_slave_ni_1_7
      '{idx: 3, start_addr: 73, end_addr: 74},  // int_core_slave_ni_2_7
      '{idx: 3, start_addr: 81, end_addr: 82},  // int_core_slave_ni_3_7
      '{idx: 3, start_addr: 89, end_addr: 90},  // fp_core_slave_ni_0_7
      '{idx: 1, start_addr: 57, end_addr: 58}  // int_core_slave_ni_0_7

  };


  floo_req_t [3:0] mesh_router_0_7_req_in;
  floo_rsp_t [3:0] mesh_router_0_7_rsp_out;
  floo_req_t [3:0] mesh_router_0_7_req_out;
  floo_rsp_t [3:0] mesh_router_0_7_rsp_in;

  assign mesh_router_0_7_req_in[0] = int_core_master_ni_0_7_to_mesh_router_0_7_req;
  assign mesh_router_0_7_req_in[1] = int_core_slave_ni_0_7_to_mesh_router_0_7_req;
  assign mesh_router_0_7_req_in[2] = mesh_router_0_6_to_mesh_router_0_7_req;
  assign mesh_router_0_7_req_in[3] = mesh_router_1_7_to_mesh_router_0_7_req;

  assign mesh_router_0_7_to_int_core_master_ni_0_7_rsp = mesh_router_0_7_rsp_out[0];
  assign mesh_router_0_7_to_int_core_slave_ni_0_7_rsp = mesh_router_0_7_rsp_out[1];
  assign mesh_router_0_7_to_mesh_router_0_6_rsp = mesh_router_0_7_rsp_out[2];
  assign mesh_router_0_7_to_mesh_router_1_7_rsp = mesh_router_0_7_rsp_out[3];

  assign mesh_router_0_7_to_int_core_master_ni_0_7_req = mesh_router_0_7_req_out[0];
  assign mesh_router_0_7_to_int_core_slave_ni_0_7_req = mesh_router_0_7_req_out[1];
  assign mesh_router_0_7_to_mesh_router_0_6_req = mesh_router_0_7_req_out[2];
  assign mesh_router_0_7_to_mesh_router_1_7_req = mesh_router_0_7_req_out[3];

  assign mesh_router_0_7_rsp_in[0] = int_core_master_ni_0_7_to_mesh_router_0_7_rsp;
  assign mesh_router_0_7_rsp_in[1] = int_core_slave_ni_0_7_to_mesh_router_0_7_rsp;
  assign mesh_router_0_7_rsp_in[2] = mesh_router_0_6_to_mesh_router_0_7_rsp;
  assign mesh_router_0_7_rsp_in[3] = mesh_router_1_7_to_mesh_router_0_7_rsp;


  floo_axi_router #(
      .AxiCfg(AxiCfg),
      .RouteAlgo(IdTable),
      .NumRoutes(4),
      .NumInputs(4),
      .NumOutputs(4),
      .InFifoDepth(2),
      .OutFifoDepth(2),
      .id_t(id_t),
      .hdr_t(hdr_t),
      .NumAddrRules(19),
      .addr_rule_t(mesh_router_0_7_map_rule_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) mesh_router_0_7 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('0),
      .id_route_map_i(MeshRouter07Map),
      .floo_req_i(mesh_router_0_7_req_in),
      .floo_rsp_o(mesh_router_0_7_rsp_out),
      .floo_req_o(mesh_router_0_7_req_out),
      .floo_rsp_i(mesh_router_0_7_rsp_in)
  );

  localparam int unsigned MeshRouter10MapNumRules = 17;

  typedef struct packed {
    id_t idx;
    id_t start_addr;
    id_t end_addr;
  } mesh_router_1_0_map_rule_t;

  localparam mesh_router_1_0_map_rule_t [MeshRouter10MapNumRules-1:0] MeshRouter10Map = '{
      '{idx: 2, start_addr: 0, end_addr: 12},  // cpu_master_ni
      '{idx: 2, start_addr: 36, end_addr: 58},  // llc_slave_ni
      '{idx: 2, start_addr: 90, end_addr: 92},  // sp_slave_ni
      '{idx: 0, start_addr: 12, end_addr: 13},  // int_core_master_ni_1_0
      '{idx: 3, start_addr: 13, end_addr: 20},  // int_core_master_ni_1_1
      '{idx: 3, start_addr: 21, end_addr: 28},  // int_core_master_ni_2_1
      '{idx: 3, start_addr: 29, end_addr: 36},  // int_core_master_ni_3_1
      '{idx: 3, start_addr: 59, end_addr: 66},  // int_core_slave_ni_1_1
      '{idx: 3, start_addr: 67, end_addr: 74},  // int_core_slave_ni_2_1
      '{idx: 3, start_addr: 75, end_addr: 82},  // int_core_slave_ni_3_1
      '{idx: 3, start_addr: 83, end_addr: 90},  // fp_core_slave_ni_0_1
      '{idx: 4, start_addr: 20, end_addr: 21},  // int_core_master_ni_2_0
      '{idx: 4, start_addr: 28, end_addr: 29},  // int_core_master_ni_3_0
      '{idx: 4, start_addr: 66, end_addr: 67},  // int_core_slave_ni_2_0
      '{idx: 4, start_addr: 74, end_addr: 75},  // int_core_slave_ni_3_0
      '{idx: 4, start_addr: 82, end_addr: 83},  // fp_core_slave_ni_0_0
      '{idx: 1, start_addr: 58, end_addr: 59}  // int_core_slave_ni_1_0

  };


  floo_req_t [4:0] mesh_router_1_0_req_in;
  floo_rsp_t [4:0] mesh_router_1_0_rsp_out;
  floo_req_t [4:0] mesh_router_1_0_req_out;
  floo_rsp_t [4:0] mesh_router_1_0_rsp_in;

  assign mesh_router_1_0_req_in[0] = int_core_master_ni_1_0_to_mesh_router_1_0_req;
  assign mesh_router_1_0_req_in[1] = int_core_slave_ni_1_0_to_mesh_router_1_0_req;
  assign mesh_router_1_0_req_in[2] = mesh_router_0_0_to_mesh_router_1_0_req;
  assign mesh_router_1_0_req_in[3] = mesh_router_1_1_to_mesh_router_1_0_req;
  assign mesh_router_1_0_req_in[4] = mesh_router_2_0_to_mesh_router_1_0_req;

  assign mesh_router_1_0_to_int_core_master_ni_1_0_rsp = mesh_router_1_0_rsp_out[0];
  assign mesh_router_1_0_to_int_core_slave_ni_1_0_rsp = mesh_router_1_0_rsp_out[1];
  assign mesh_router_1_0_to_mesh_router_0_0_rsp = mesh_router_1_0_rsp_out[2];
  assign mesh_router_1_0_to_mesh_router_1_1_rsp = mesh_router_1_0_rsp_out[3];
  assign mesh_router_1_0_to_mesh_router_2_0_rsp = mesh_router_1_0_rsp_out[4];

  assign mesh_router_1_0_to_int_core_master_ni_1_0_req = mesh_router_1_0_req_out[0];
  assign mesh_router_1_0_to_int_core_slave_ni_1_0_req = mesh_router_1_0_req_out[1];
  assign mesh_router_1_0_to_mesh_router_0_0_req = mesh_router_1_0_req_out[2];
  assign mesh_router_1_0_to_mesh_router_1_1_req = mesh_router_1_0_req_out[3];
  assign mesh_router_1_0_to_mesh_router_2_0_req = mesh_router_1_0_req_out[4];

  assign mesh_router_1_0_rsp_in[0] = int_core_master_ni_1_0_to_mesh_router_1_0_rsp;
  assign mesh_router_1_0_rsp_in[1] = int_core_slave_ni_1_0_to_mesh_router_1_0_rsp;
  assign mesh_router_1_0_rsp_in[2] = mesh_router_0_0_to_mesh_router_1_0_rsp;
  assign mesh_router_1_0_rsp_in[3] = mesh_router_1_1_to_mesh_router_1_0_rsp;
  assign mesh_router_1_0_rsp_in[4] = mesh_router_2_0_to_mesh_router_1_0_rsp;


  floo_axi_router #(
      .AxiCfg(AxiCfg),
      .RouteAlgo(IdTable),
      .NumRoutes(5),
      .NumInputs(5),
      .NumOutputs(5),
      .InFifoDepth(2),
      .OutFifoDepth(2),
      .id_t(id_t),
      .hdr_t(hdr_t),
      .NumAddrRules(17),
      .addr_rule_t(mesh_router_1_0_map_rule_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) mesh_router_1_0 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('0),
      .id_route_map_i(MeshRouter10Map),
      .floo_req_i(mesh_router_1_0_req_in),
      .floo_rsp_o(mesh_router_1_0_rsp_out),
      .floo_req_o(mesh_router_1_0_req_out),
      .floo_rsp_i(mesh_router_1_0_rsp_in)
  );

  localparam int unsigned MeshRouter11MapNumRules = 24;

  typedef struct packed {
    id_t idx;
    id_t start_addr;
    id_t end_addr;
  } mesh_router_1_1_map_rule_t;

  localparam mesh_router_1_1_map_rule_t [MeshRouter11MapNumRules-1:0] MeshRouter11Map = '{
      '{idx: 2, start_addr: 0, end_addr: 12},  // cpu_master_ni
      '{idx: 2, start_addr: 36, end_addr: 58},  // llc_slave_ni
      '{idx: 2, start_addr: 90, end_addr: 92},  // sp_slave_ni
      '{idx: 3, start_addr: 12, end_addr: 13},  // int_core_master_ni_1_0
      '{idx: 3, start_addr: 20, end_addr: 21},  // int_core_master_ni_2_0
      '{idx: 3, start_addr: 28, end_addr: 29},  // int_core_master_ni_3_0
      '{idx: 3, start_addr: 58, end_addr: 59},  // int_core_slave_ni_1_0
      '{idx: 3, start_addr: 66, end_addr: 67},  // int_core_slave_ni_2_0
      '{idx: 3, start_addr: 74, end_addr: 75},  // int_core_slave_ni_3_0
      '{idx: 3, start_addr: 82, end_addr: 83},  // fp_core_slave_ni_0_0
      '{idx: 0, start_addr: 13, end_addr: 14},  // int_core_master_ni_1_1
      '{idx: 4, start_addr: 14, end_addr: 20},  // int_core_master_ni_1_2
      '{idx: 4, start_addr: 22, end_addr: 28},  // int_core_master_ni_2_2
      '{idx: 4, start_addr: 30, end_addr: 36},  // int_core_master_ni_3_2
      '{idx: 4, start_addr: 60, end_addr: 66},  // int_core_slave_ni_1_2
      '{idx: 4, start_addr: 68, end_addr: 74},  // int_core_slave_ni_2_2
      '{idx: 4, start_addr: 76, end_addr: 82},  // int_core_slave_ni_3_2
      '{idx: 4, start_addr: 84, end_addr: 90},  // fp_core_slave_ni_0_2
      '{idx: 5, start_addr: 21, end_addr: 22},  // int_core_master_ni_2_1
      '{idx: 5, start_addr: 29, end_addr: 30},  // int_core_master_ni_3_1
      '{idx: 5, start_addr: 67, end_addr: 68},  // int_core_slave_ni_2_1
      '{idx: 5, start_addr: 75, end_addr: 76},  // int_core_slave_ni_3_1
      '{idx: 5, start_addr: 83, end_addr: 84},  // fp_core_slave_ni_0_1
      '{idx: 1, start_addr: 59, end_addr: 60}  // int_core_slave_ni_1_1

  };


  floo_req_t [5:0] mesh_router_1_1_req_in;
  floo_rsp_t [5:0] mesh_router_1_1_rsp_out;
  floo_req_t [5:0] mesh_router_1_1_req_out;
  floo_rsp_t [5:0] mesh_router_1_1_rsp_in;

  assign mesh_router_1_1_req_in[0] = int_core_master_ni_1_1_to_mesh_router_1_1_req;
  assign mesh_router_1_1_req_in[1] = int_core_slave_ni_1_1_to_mesh_router_1_1_req;
  assign mesh_router_1_1_req_in[2] = mesh_router_0_1_to_mesh_router_1_1_req;
  assign mesh_router_1_1_req_in[3] = mesh_router_1_0_to_mesh_router_1_1_req;
  assign mesh_router_1_1_req_in[4] = mesh_router_1_2_to_mesh_router_1_1_req;
  assign mesh_router_1_1_req_in[5] = mesh_router_2_1_to_mesh_router_1_1_req;

  assign mesh_router_1_1_to_int_core_master_ni_1_1_rsp = mesh_router_1_1_rsp_out[0];
  assign mesh_router_1_1_to_int_core_slave_ni_1_1_rsp = mesh_router_1_1_rsp_out[1];
  assign mesh_router_1_1_to_mesh_router_0_1_rsp = mesh_router_1_1_rsp_out[2];
  assign mesh_router_1_1_to_mesh_router_1_0_rsp = mesh_router_1_1_rsp_out[3];
  assign mesh_router_1_1_to_mesh_router_1_2_rsp = mesh_router_1_1_rsp_out[4];
  assign mesh_router_1_1_to_mesh_router_2_1_rsp = mesh_router_1_1_rsp_out[5];

  assign mesh_router_1_1_to_int_core_master_ni_1_1_req = mesh_router_1_1_req_out[0];
  assign mesh_router_1_1_to_int_core_slave_ni_1_1_req = mesh_router_1_1_req_out[1];
  assign mesh_router_1_1_to_mesh_router_0_1_req = mesh_router_1_1_req_out[2];
  assign mesh_router_1_1_to_mesh_router_1_0_req = mesh_router_1_1_req_out[3];
  assign mesh_router_1_1_to_mesh_router_1_2_req = mesh_router_1_1_req_out[4];
  assign mesh_router_1_1_to_mesh_router_2_1_req = mesh_router_1_1_req_out[5];

  assign mesh_router_1_1_rsp_in[0] = int_core_master_ni_1_1_to_mesh_router_1_1_rsp;
  assign mesh_router_1_1_rsp_in[1] = int_core_slave_ni_1_1_to_mesh_router_1_1_rsp;
  assign mesh_router_1_1_rsp_in[2] = mesh_router_0_1_to_mesh_router_1_1_rsp;
  assign mesh_router_1_1_rsp_in[3] = mesh_router_1_0_to_mesh_router_1_1_rsp;
  assign mesh_router_1_1_rsp_in[4] = mesh_router_1_2_to_mesh_router_1_1_rsp;
  assign mesh_router_1_1_rsp_in[5] = mesh_router_2_1_to_mesh_router_1_1_rsp;


  floo_axi_router #(
      .AxiCfg(AxiCfg),
      .RouteAlgo(IdTable),
      .NumRoutes(6),
      .NumInputs(6),
      .NumOutputs(6),
      .InFifoDepth(2),
      .OutFifoDepth(2),
      .id_t(id_t),
      .hdr_t(hdr_t),
      .NumAddrRules(24),
      .addr_rule_t(mesh_router_1_1_map_rule_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) mesh_router_1_1 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('0),
      .id_route_map_i(MeshRouter11Map),
      .floo_req_i(mesh_router_1_1_req_in),
      .floo_rsp_o(mesh_router_1_1_rsp_out),
      .floo_req_o(mesh_router_1_1_req_out),
      .floo_rsp_i(mesh_router_1_1_rsp_in)
  );

  localparam int unsigned MeshRouter12MapNumRules = 24;

  typedef struct packed {
    id_t idx;
    id_t start_addr;
    id_t end_addr;
  } mesh_router_1_2_map_rule_t;

  localparam mesh_router_1_2_map_rule_t [MeshRouter12MapNumRules-1:0] MeshRouter12Map = '{
      '{idx: 2, start_addr: 0, end_addr: 12},  // cpu_master_ni
      '{idx: 2, start_addr: 36, end_addr: 58},  // llc_slave_ni
      '{idx: 2, start_addr: 90, end_addr: 92},  // sp_slave_ni
      '{idx: 3, start_addr: 12, end_addr: 14},  // int_core_master_ni_1_0
      '{idx: 3, start_addr: 20, end_addr: 22},  // int_core_master_ni_2_0
      '{idx: 3, start_addr: 28, end_addr: 30},  // int_core_master_ni_3_0
      '{idx: 3, start_addr: 58, end_addr: 60},  // int_core_slave_ni_1_0
      '{idx: 3, start_addr: 66, end_addr: 68},  // int_core_slave_ni_2_0
      '{idx: 3, start_addr: 74, end_addr: 76},  // int_core_slave_ni_3_0
      '{idx: 3, start_addr: 82, end_addr: 84},  // fp_core_slave_ni_0_0
      '{idx: 0, start_addr: 14, end_addr: 15},  // int_core_master_ni_1_2
      '{idx: 4, start_addr: 15, end_addr: 20},  // int_core_master_ni_1_3
      '{idx: 4, start_addr: 23, end_addr: 28},  // int_core_master_ni_2_3
      '{idx: 4, start_addr: 31, end_addr: 36},  // int_core_master_ni_3_3
      '{idx: 4, start_addr: 61, end_addr: 66},  // int_core_slave_ni_1_3
      '{idx: 4, start_addr: 69, end_addr: 74},  // int_core_slave_ni_2_3
      '{idx: 4, start_addr: 77, end_addr: 82},  // int_core_slave_ni_3_3
      '{idx: 4, start_addr: 85, end_addr: 90},  // fp_core_slave_ni_0_3
      '{idx: 5, start_addr: 22, end_addr: 23},  // int_core_master_ni_2_2
      '{idx: 5, start_addr: 30, end_addr: 31},  // int_core_master_ni_3_2
      '{idx: 5, start_addr: 68, end_addr: 69},  // int_core_slave_ni_2_2
      '{idx: 5, start_addr: 76, end_addr: 77},  // int_core_slave_ni_3_2
      '{idx: 5, start_addr: 84, end_addr: 85},  // fp_core_slave_ni_0_2
      '{idx: 1, start_addr: 60, end_addr: 61}  // int_core_slave_ni_1_2

  };


  floo_req_t [5:0] mesh_router_1_2_req_in;
  floo_rsp_t [5:0] mesh_router_1_2_rsp_out;
  floo_req_t [5:0] mesh_router_1_2_req_out;
  floo_rsp_t [5:0] mesh_router_1_2_rsp_in;

  assign mesh_router_1_2_req_in[0] = int_core_master_ni_1_2_to_mesh_router_1_2_req;
  assign mesh_router_1_2_req_in[1] = int_core_slave_ni_1_2_to_mesh_router_1_2_req;
  assign mesh_router_1_2_req_in[2] = mesh_router_0_2_to_mesh_router_1_2_req;
  assign mesh_router_1_2_req_in[3] = mesh_router_1_1_to_mesh_router_1_2_req;
  assign mesh_router_1_2_req_in[4] = mesh_router_1_3_to_mesh_router_1_2_req;
  assign mesh_router_1_2_req_in[5] = mesh_router_2_2_to_mesh_router_1_2_req;

  assign mesh_router_1_2_to_int_core_master_ni_1_2_rsp = mesh_router_1_2_rsp_out[0];
  assign mesh_router_1_2_to_int_core_slave_ni_1_2_rsp = mesh_router_1_2_rsp_out[1];
  assign mesh_router_1_2_to_mesh_router_0_2_rsp = mesh_router_1_2_rsp_out[2];
  assign mesh_router_1_2_to_mesh_router_1_1_rsp = mesh_router_1_2_rsp_out[3];
  assign mesh_router_1_2_to_mesh_router_1_3_rsp = mesh_router_1_2_rsp_out[4];
  assign mesh_router_1_2_to_mesh_router_2_2_rsp = mesh_router_1_2_rsp_out[5];

  assign mesh_router_1_2_to_int_core_master_ni_1_2_req = mesh_router_1_2_req_out[0];
  assign mesh_router_1_2_to_int_core_slave_ni_1_2_req = mesh_router_1_2_req_out[1];
  assign mesh_router_1_2_to_mesh_router_0_2_req = mesh_router_1_2_req_out[2];
  assign mesh_router_1_2_to_mesh_router_1_1_req = mesh_router_1_2_req_out[3];
  assign mesh_router_1_2_to_mesh_router_1_3_req = mesh_router_1_2_req_out[4];
  assign mesh_router_1_2_to_mesh_router_2_2_req = mesh_router_1_2_req_out[5];

  assign mesh_router_1_2_rsp_in[0] = int_core_master_ni_1_2_to_mesh_router_1_2_rsp;
  assign mesh_router_1_2_rsp_in[1] = int_core_slave_ni_1_2_to_mesh_router_1_2_rsp;
  assign mesh_router_1_2_rsp_in[2] = mesh_router_0_2_to_mesh_router_1_2_rsp;
  assign mesh_router_1_2_rsp_in[3] = mesh_router_1_1_to_mesh_router_1_2_rsp;
  assign mesh_router_1_2_rsp_in[4] = mesh_router_1_3_to_mesh_router_1_2_rsp;
  assign mesh_router_1_2_rsp_in[5] = mesh_router_2_2_to_mesh_router_1_2_rsp;


  floo_axi_router #(
      .AxiCfg(AxiCfg),
      .RouteAlgo(IdTable),
      .NumRoutes(6),
      .NumInputs(6),
      .NumOutputs(6),
      .InFifoDepth(2),
      .OutFifoDepth(2),
      .id_t(id_t),
      .hdr_t(hdr_t),
      .NumAddrRules(24),
      .addr_rule_t(mesh_router_1_2_map_rule_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) mesh_router_1_2 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('0),
      .id_route_map_i(MeshRouter12Map),
      .floo_req_i(mesh_router_1_2_req_in),
      .floo_rsp_o(mesh_router_1_2_rsp_out),
      .floo_req_o(mesh_router_1_2_req_out),
      .floo_rsp_i(mesh_router_1_2_rsp_in)
  );

  localparam int unsigned MeshRouter13MapNumRules = 24;

  typedef struct packed {
    id_t idx;
    id_t start_addr;
    id_t end_addr;
  } mesh_router_1_3_map_rule_t;

  localparam mesh_router_1_3_map_rule_t [MeshRouter13MapNumRules-1:0] MeshRouter13Map = '{
      '{idx: 2, start_addr: 0, end_addr: 12},  // cpu_master_ni
      '{idx: 2, start_addr: 36, end_addr: 58},  // llc_slave_ni
      '{idx: 2, start_addr: 90, end_addr: 92},  // sp_slave_ni
      '{idx: 3, start_addr: 12, end_addr: 15},  // int_core_master_ni_1_0
      '{idx: 3, start_addr: 20, end_addr: 23},  // int_core_master_ni_2_0
      '{idx: 3, start_addr: 28, end_addr: 31},  // int_core_master_ni_3_0
      '{idx: 3, start_addr: 58, end_addr: 61},  // int_core_slave_ni_1_0
      '{idx: 3, start_addr: 66, end_addr: 69},  // int_core_slave_ni_2_0
      '{idx: 3, start_addr: 74, end_addr: 77},  // int_core_slave_ni_3_0
      '{idx: 3, start_addr: 82, end_addr: 85},  // fp_core_slave_ni_0_0
      '{idx: 0, start_addr: 15, end_addr: 16},  // int_core_master_ni_1_3
      '{idx: 4, start_addr: 16, end_addr: 20},  // int_core_master_ni_1_4
      '{idx: 4, start_addr: 24, end_addr: 28},  // int_core_master_ni_2_4
      '{idx: 4, start_addr: 32, end_addr: 36},  // int_core_master_ni_3_4
      '{idx: 4, start_addr: 62, end_addr: 66},  // int_core_slave_ni_1_4
      '{idx: 4, start_addr: 70, end_addr: 74},  // int_core_slave_ni_2_4
      '{idx: 4, start_addr: 78, end_addr: 82},  // int_core_slave_ni_3_4
      '{idx: 4, start_addr: 86, end_addr: 90},  // fp_core_slave_ni_0_4
      '{idx: 5, start_addr: 23, end_addr: 24},  // int_core_master_ni_2_3
      '{idx: 5, start_addr: 31, end_addr: 32},  // int_core_master_ni_3_3
      '{idx: 5, start_addr: 69, end_addr: 70},  // int_core_slave_ni_2_3
      '{idx: 5, start_addr: 77, end_addr: 78},  // int_core_slave_ni_3_3
      '{idx: 5, start_addr: 85, end_addr: 86},  // fp_core_slave_ni_0_3
      '{idx: 1, start_addr: 61, end_addr: 62}  // int_core_slave_ni_1_3

  };


  floo_req_t [5:0] mesh_router_1_3_req_in;
  floo_rsp_t [5:0] mesh_router_1_3_rsp_out;
  floo_req_t [5:0] mesh_router_1_3_req_out;
  floo_rsp_t [5:0] mesh_router_1_3_rsp_in;

  assign mesh_router_1_3_req_in[0] = int_core_master_ni_1_3_to_mesh_router_1_3_req;
  assign mesh_router_1_3_req_in[1] = int_core_slave_ni_1_3_to_mesh_router_1_3_req;
  assign mesh_router_1_3_req_in[2] = mesh_router_0_3_to_mesh_router_1_3_req;
  assign mesh_router_1_3_req_in[3] = mesh_router_1_2_to_mesh_router_1_3_req;
  assign mesh_router_1_3_req_in[4] = mesh_router_1_4_to_mesh_router_1_3_req;
  assign mesh_router_1_3_req_in[5] = mesh_router_2_3_to_mesh_router_1_3_req;

  assign mesh_router_1_3_to_int_core_master_ni_1_3_rsp = mesh_router_1_3_rsp_out[0];
  assign mesh_router_1_3_to_int_core_slave_ni_1_3_rsp = mesh_router_1_3_rsp_out[1];
  assign mesh_router_1_3_to_mesh_router_0_3_rsp = mesh_router_1_3_rsp_out[2];
  assign mesh_router_1_3_to_mesh_router_1_2_rsp = mesh_router_1_3_rsp_out[3];
  assign mesh_router_1_3_to_mesh_router_1_4_rsp = mesh_router_1_3_rsp_out[4];
  assign mesh_router_1_3_to_mesh_router_2_3_rsp = mesh_router_1_3_rsp_out[5];

  assign mesh_router_1_3_to_int_core_master_ni_1_3_req = mesh_router_1_3_req_out[0];
  assign mesh_router_1_3_to_int_core_slave_ni_1_3_req = mesh_router_1_3_req_out[1];
  assign mesh_router_1_3_to_mesh_router_0_3_req = mesh_router_1_3_req_out[2];
  assign mesh_router_1_3_to_mesh_router_1_2_req = mesh_router_1_3_req_out[3];
  assign mesh_router_1_3_to_mesh_router_1_4_req = mesh_router_1_3_req_out[4];
  assign mesh_router_1_3_to_mesh_router_2_3_req = mesh_router_1_3_req_out[5];

  assign mesh_router_1_3_rsp_in[0] = int_core_master_ni_1_3_to_mesh_router_1_3_rsp;
  assign mesh_router_1_3_rsp_in[1] = int_core_slave_ni_1_3_to_mesh_router_1_3_rsp;
  assign mesh_router_1_3_rsp_in[2] = mesh_router_0_3_to_mesh_router_1_3_rsp;
  assign mesh_router_1_3_rsp_in[3] = mesh_router_1_2_to_mesh_router_1_3_rsp;
  assign mesh_router_1_3_rsp_in[4] = mesh_router_1_4_to_mesh_router_1_3_rsp;
  assign mesh_router_1_3_rsp_in[5] = mesh_router_2_3_to_mesh_router_1_3_rsp;


  floo_axi_router #(
      .AxiCfg(AxiCfg),
      .RouteAlgo(IdTable),
      .NumRoutes(6),
      .NumInputs(6),
      .NumOutputs(6),
      .InFifoDepth(2),
      .OutFifoDepth(2),
      .id_t(id_t),
      .hdr_t(hdr_t),
      .NumAddrRules(24),
      .addr_rule_t(mesh_router_1_3_map_rule_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) mesh_router_1_3 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('0),
      .id_route_map_i(MeshRouter13Map),
      .floo_req_i(mesh_router_1_3_req_in),
      .floo_rsp_o(mesh_router_1_3_rsp_out),
      .floo_req_o(mesh_router_1_3_req_out),
      .floo_rsp_i(mesh_router_1_3_rsp_in)
  );

  localparam int unsigned MeshRouter14MapNumRules = 24;

  typedef struct packed {
    id_t idx;
    id_t start_addr;
    id_t end_addr;
  } mesh_router_1_4_map_rule_t;

  localparam mesh_router_1_4_map_rule_t [MeshRouter14MapNumRules-1:0] MeshRouter14Map = '{
      '{idx: 2, start_addr: 0, end_addr: 12},  // cpu_master_ni
      '{idx: 2, start_addr: 36, end_addr: 58},  // llc_slave_ni
      '{idx: 2, start_addr: 90, end_addr: 92},  // sp_slave_ni
      '{idx: 3, start_addr: 12, end_addr: 16},  // int_core_master_ni_1_0
      '{idx: 3, start_addr: 20, end_addr: 24},  // int_core_master_ni_2_0
      '{idx: 3, start_addr: 28, end_addr: 32},  // int_core_master_ni_3_0
      '{idx: 3, start_addr: 58, end_addr: 62},  // int_core_slave_ni_1_0
      '{idx: 3, start_addr: 66, end_addr: 70},  // int_core_slave_ni_2_0
      '{idx: 3, start_addr: 74, end_addr: 78},  // int_core_slave_ni_3_0
      '{idx: 3, start_addr: 82, end_addr: 86},  // fp_core_slave_ni_0_0
      '{idx: 0, start_addr: 16, end_addr: 17},  // int_core_master_ni_1_4
      '{idx: 4, start_addr: 17, end_addr: 20},  // int_core_master_ni_1_5
      '{idx: 4, start_addr: 25, end_addr: 28},  // int_core_master_ni_2_5
      '{idx: 4, start_addr: 33, end_addr: 36},  // int_core_master_ni_3_5
      '{idx: 4, start_addr: 63, end_addr: 66},  // int_core_slave_ni_1_5
      '{idx: 4, start_addr: 71, end_addr: 74},  // int_core_slave_ni_2_5
      '{idx: 4, start_addr: 79, end_addr: 82},  // int_core_slave_ni_3_5
      '{idx: 4, start_addr: 87, end_addr: 90},  // fp_core_slave_ni_0_5
      '{idx: 5, start_addr: 24, end_addr: 25},  // int_core_master_ni_2_4
      '{idx: 5, start_addr: 32, end_addr: 33},  // int_core_master_ni_3_4
      '{idx: 5, start_addr: 70, end_addr: 71},  // int_core_slave_ni_2_4
      '{idx: 5, start_addr: 78, end_addr: 79},  // int_core_slave_ni_3_4
      '{idx: 5, start_addr: 86, end_addr: 87},  // fp_core_slave_ni_0_4
      '{idx: 1, start_addr: 62, end_addr: 63}  // int_core_slave_ni_1_4

  };


  floo_req_t [5:0] mesh_router_1_4_req_in;
  floo_rsp_t [5:0] mesh_router_1_4_rsp_out;
  floo_req_t [5:0] mesh_router_1_4_req_out;
  floo_rsp_t [5:0] mesh_router_1_4_rsp_in;

  assign mesh_router_1_4_req_in[0] = int_core_master_ni_1_4_to_mesh_router_1_4_req;
  assign mesh_router_1_4_req_in[1] = int_core_slave_ni_1_4_to_mesh_router_1_4_req;
  assign mesh_router_1_4_req_in[2] = mesh_router_0_4_to_mesh_router_1_4_req;
  assign mesh_router_1_4_req_in[3] = mesh_router_1_3_to_mesh_router_1_4_req;
  assign mesh_router_1_4_req_in[4] = mesh_router_1_5_to_mesh_router_1_4_req;
  assign mesh_router_1_4_req_in[5] = mesh_router_2_4_to_mesh_router_1_4_req;

  assign mesh_router_1_4_to_int_core_master_ni_1_4_rsp = mesh_router_1_4_rsp_out[0];
  assign mesh_router_1_4_to_int_core_slave_ni_1_4_rsp = mesh_router_1_4_rsp_out[1];
  assign mesh_router_1_4_to_mesh_router_0_4_rsp = mesh_router_1_4_rsp_out[2];
  assign mesh_router_1_4_to_mesh_router_1_3_rsp = mesh_router_1_4_rsp_out[3];
  assign mesh_router_1_4_to_mesh_router_1_5_rsp = mesh_router_1_4_rsp_out[4];
  assign mesh_router_1_4_to_mesh_router_2_4_rsp = mesh_router_1_4_rsp_out[5];

  assign mesh_router_1_4_to_int_core_master_ni_1_4_req = mesh_router_1_4_req_out[0];
  assign mesh_router_1_4_to_int_core_slave_ni_1_4_req = mesh_router_1_4_req_out[1];
  assign mesh_router_1_4_to_mesh_router_0_4_req = mesh_router_1_4_req_out[2];
  assign mesh_router_1_4_to_mesh_router_1_3_req = mesh_router_1_4_req_out[3];
  assign mesh_router_1_4_to_mesh_router_1_5_req = mesh_router_1_4_req_out[4];
  assign mesh_router_1_4_to_mesh_router_2_4_req = mesh_router_1_4_req_out[5];

  assign mesh_router_1_4_rsp_in[0] = int_core_master_ni_1_4_to_mesh_router_1_4_rsp;
  assign mesh_router_1_4_rsp_in[1] = int_core_slave_ni_1_4_to_mesh_router_1_4_rsp;
  assign mesh_router_1_4_rsp_in[2] = mesh_router_0_4_to_mesh_router_1_4_rsp;
  assign mesh_router_1_4_rsp_in[3] = mesh_router_1_3_to_mesh_router_1_4_rsp;
  assign mesh_router_1_4_rsp_in[4] = mesh_router_1_5_to_mesh_router_1_4_rsp;
  assign mesh_router_1_4_rsp_in[5] = mesh_router_2_4_to_mesh_router_1_4_rsp;


  floo_axi_router #(
      .AxiCfg(AxiCfg),
      .RouteAlgo(IdTable),
      .NumRoutes(6),
      .NumInputs(6),
      .NumOutputs(6),
      .InFifoDepth(2),
      .OutFifoDepth(2),
      .id_t(id_t),
      .hdr_t(hdr_t),
      .NumAddrRules(24),
      .addr_rule_t(mesh_router_1_4_map_rule_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) mesh_router_1_4 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('0),
      .id_route_map_i(MeshRouter14Map),
      .floo_req_i(mesh_router_1_4_req_in),
      .floo_rsp_o(mesh_router_1_4_rsp_out),
      .floo_req_o(mesh_router_1_4_req_out),
      .floo_rsp_i(mesh_router_1_4_rsp_in)
  );

  localparam int unsigned MeshRouter15MapNumRules = 24;

  typedef struct packed {
    id_t idx;
    id_t start_addr;
    id_t end_addr;
  } mesh_router_1_5_map_rule_t;

  localparam mesh_router_1_5_map_rule_t [MeshRouter15MapNumRules-1:0] MeshRouter15Map = '{
      '{idx: 2, start_addr: 0, end_addr: 12},  // cpu_master_ni
      '{idx: 2, start_addr: 36, end_addr: 58},  // llc_slave_ni
      '{idx: 2, start_addr: 90, end_addr: 92},  // sp_slave_ni
      '{idx: 3, start_addr: 12, end_addr: 17},  // int_core_master_ni_1_0
      '{idx: 3, start_addr: 20, end_addr: 25},  // int_core_master_ni_2_0
      '{idx: 3, start_addr: 28, end_addr: 33},  // int_core_master_ni_3_0
      '{idx: 3, start_addr: 58, end_addr: 63},  // int_core_slave_ni_1_0
      '{idx: 3, start_addr: 66, end_addr: 71},  // int_core_slave_ni_2_0
      '{idx: 3, start_addr: 74, end_addr: 79},  // int_core_slave_ni_3_0
      '{idx: 3, start_addr: 82, end_addr: 87},  // fp_core_slave_ni_0_0
      '{idx: 0, start_addr: 17, end_addr: 18},  // int_core_master_ni_1_5
      '{idx: 4, start_addr: 18, end_addr: 20},  // int_core_master_ni_1_6
      '{idx: 4, start_addr: 26, end_addr: 28},  // int_core_master_ni_2_6
      '{idx: 4, start_addr: 34, end_addr: 36},  // int_core_master_ni_3_6
      '{idx: 4, start_addr: 64, end_addr: 66},  // int_core_slave_ni_1_6
      '{idx: 4, start_addr: 72, end_addr: 74},  // int_core_slave_ni_2_6
      '{idx: 4, start_addr: 80, end_addr: 82},  // int_core_slave_ni_3_6
      '{idx: 4, start_addr: 88, end_addr: 90},  // fp_core_slave_ni_0_6
      '{idx: 5, start_addr: 25, end_addr: 26},  // int_core_master_ni_2_5
      '{idx: 5, start_addr: 33, end_addr: 34},  // int_core_master_ni_3_5
      '{idx: 5, start_addr: 71, end_addr: 72},  // int_core_slave_ni_2_5
      '{idx: 5, start_addr: 79, end_addr: 80},  // int_core_slave_ni_3_5
      '{idx: 5, start_addr: 87, end_addr: 88},  // fp_core_slave_ni_0_5
      '{idx: 1, start_addr: 63, end_addr: 64}  // int_core_slave_ni_1_5

  };


  floo_req_t [5:0] mesh_router_1_5_req_in;
  floo_rsp_t [5:0] mesh_router_1_5_rsp_out;
  floo_req_t [5:0] mesh_router_1_5_req_out;
  floo_rsp_t [5:0] mesh_router_1_5_rsp_in;

  assign mesh_router_1_5_req_in[0] = int_core_master_ni_1_5_to_mesh_router_1_5_req;
  assign mesh_router_1_5_req_in[1] = int_core_slave_ni_1_5_to_mesh_router_1_5_req;
  assign mesh_router_1_5_req_in[2] = mesh_router_0_5_to_mesh_router_1_5_req;
  assign mesh_router_1_5_req_in[3] = mesh_router_1_4_to_mesh_router_1_5_req;
  assign mesh_router_1_5_req_in[4] = mesh_router_1_6_to_mesh_router_1_5_req;
  assign mesh_router_1_5_req_in[5] = mesh_router_2_5_to_mesh_router_1_5_req;

  assign mesh_router_1_5_to_int_core_master_ni_1_5_rsp = mesh_router_1_5_rsp_out[0];
  assign mesh_router_1_5_to_int_core_slave_ni_1_5_rsp = mesh_router_1_5_rsp_out[1];
  assign mesh_router_1_5_to_mesh_router_0_5_rsp = mesh_router_1_5_rsp_out[2];
  assign mesh_router_1_5_to_mesh_router_1_4_rsp = mesh_router_1_5_rsp_out[3];
  assign mesh_router_1_5_to_mesh_router_1_6_rsp = mesh_router_1_5_rsp_out[4];
  assign mesh_router_1_5_to_mesh_router_2_5_rsp = mesh_router_1_5_rsp_out[5];

  assign mesh_router_1_5_to_int_core_master_ni_1_5_req = mesh_router_1_5_req_out[0];
  assign mesh_router_1_5_to_int_core_slave_ni_1_5_req = mesh_router_1_5_req_out[1];
  assign mesh_router_1_5_to_mesh_router_0_5_req = mesh_router_1_5_req_out[2];
  assign mesh_router_1_5_to_mesh_router_1_4_req = mesh_router_1_5_req_out[3];
  assign mesh_router_1_5_to_mesh_router_1_6_req = mesh_router_1_5_req_out[4];
  assign mesh_router_1_5_to_mesh_router_2_5_req = mesh_router_1_5_req_out[5];

  assign mesh_router_1_5_rsp_in[0] = int_core_master_ni_1_5_to_mesh_router_1_5_rsp;
  assign mesh_router_1_5_rsp_in[1] = int_core_slave_ni_1_5_to_mesh_router_1_5_rsp;
  assign mesh_router_1_5_rsp_in[2] = mesh_router_0_5_to_mesh_router_1_5_rsp;
  assign mesh_router_1_5_rsp_in[3] = mesh_router_1_4_to_mesh_router_1_5_rsp;
  assign mesh_router_1_5_rsp_in[4] = mesh_router_1_6_to_mesh_router_1_5_rsp;
  assign mesh_router_1_5_rsp_in[5] = mesh_router_2_5_to_mesh_router_1_5_rsp;


  floo_axi_router #(
      .AxiCfg(AxiCfg),
      .RouteAlgo(IdTable),
      .NumRoutes(6),
      .NumInputs(6),
      .NumOutputs(6),
      .InFifoDepth(2),
      .OutFifoDepth(2),
      .id_t(id_t),
      .hdr_t(hdr_t),
      .NumAddrRules(24),
      .addr_rule_t(mesh_router_1_5_map_rule_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) mesh_router_1_5 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('0),
      .id_route_map_i(MeshRouter15Map),
      .floo_req_i(mesh_router_1_5_req_in),
      .floo_rsp_o(mesh_router_1_5_rsp_out),
      .floo_req_o(mesh_router_1_5_req_out),
      .floo_rsp_i(mesh_router_1_5_rsp_in)
  );

  localparam int unsigned MeshRouter16MapNumRules = 24;

  typedef struct packed {
    id_t idx;
    id_t start_addr;
    id_t end_addr;
  } mesh_router_1_6_map_rule_t;

  localparam mesh_router_1_6_map_rule_t [MeshRouter16MapNumRules-1:0] MeshRouter16Map = '{
      '{idx: 2, start_addr: 0, end_addr: 12},  // cpu_master_ni
      '{idx: 2, start_addr: 36, end_addr: 58},  // llc_slave_ni
      '{idx: 2, start_addr: 90, end_addr: 92},  // sp_slave_ni
      '{idx: 3, start_addr: 12, end_addr: 18},  // int_core_master_ni_1_0
      '{idx: 3, start_addr: 20, end_addr: 26},  // int_core_master_ni_2_0
      '{idx: 3, start_addr: 28, end_addr: 34},  // int_core_master_ni_3_0
      '{idx: 3, start_addr: 58, end_addr: 64},  // int_core_slave_ni_1_0
      '{idx: 3, start_addr: 66, end_addr: 72},  // int_core_slave_ni_2_0
      '{idx: 3, start_addr: 74, end_addr: 80},  // int_core_slave_ni_3_0
      '{idx: 3, start_addr: 82, end_addr: 88},  // fp_core_slave_ni_0_0
      '{idx: 0, start_addr: 18, end_addr: 19},  // int_core_master_ni_1_6
      '{idx: 4, start_addr: 19, end_addr: 20},  // int_core_master_ni_1_7
      '{idx: 4, start_addr: 27, end_addr: 28},  // int_core_master_ni_2_7
      '{idx: 4, start_addr: 35, end_addr: 36},  // int_core_master_ni_3_7
      '{idx: 4, start_addr: 65, end_addr: 66},  // int_core_slave_ni_1_7
      '{idx: 4, start_addr: 73, end_addr: 74},  // int_core_slave_ni_2_7
      '{idx: 4, start_addr: 81, end_addr: 82},  // int_core_slave_ni_3_7
      '{idx: 4, start_addr: 89, end_addr: 90},  // fp_core_slave_ni_0_7
      '{idx: 5, start_addr: 26, end_addr: 27},  // int_core_master_ni_2_6
      '{idx: 5, start_addr: 34, end_addr: 35},  // int_core_master_ni_3_6
      '{idx: 5, start_addr: 72, end_addr: 73},  // int_core_slave_ni_2_6
      '{idx: 5, start_addr: 80, end_addr: 81},  // int_core_slave_ni_3_6
      '{idx: 5, start_addr: 88, end_addr: 89},  // fp_core_slave_ni_0_6
      '{idx: 1, start_addr: 64, end_addr: 65}  // int_core_slave_ni_1_6

  };


  floo_req_t [5:0] mesh_router_1_6_req_in;
  floo_rsp_t [5:0] mesh_router_1_6_rsp_out;
  floo_req_t [5:0] mesh_router_1_6_req_out;
  floo_rsp_t [5:0] mesh_router_1_6_rsp_in;

  assign mesh_router_1_6_req_in[0] = int_core_master_ni_1_6_to_mesh_router_1_6_req;
  assign mesh_router_1_6_req_in[1] = int_core_slave_ni_1_6_to_mesh_router_1_6_req;
  assign mesh_router_1_6_req_in[2] = mesh_router_0_6_to_mesh_router_1_6_req;
  assign mesh_router_1_6_req_in[3] = mesh_router_1_5_to_mesh_router_1_6_req;
  assign mesh_router_1_6_req_in[4] = mesh_router_1_7_to_mesh_router_1_6_req;
  assign mesh_router_1_6_req_in[5] = mesh_router_2_6_to_mesh_router_1_6_req;

  assign mesh_router_1_6_to_int_core_master_ni_1_6_rsp = mesh_router_1_6_rsp_out[0];
  assign mesh_router_1_6_to_int_core_slave_ni_1_6_rsp = mesh_router_1_6_rsp_out[1];
  assign mesh_router_1_6_to_mesh_router_0_6_rsp = mesh_router_1_6_rsp_out[2];
  assign mesh_router_1_6_to_mesh_router_1_5_rsp = mesh_router_1_6_rsp_out[3];
  assign mesh_router_1_6_to_mesh_router_1_7_rsp = mesh_router_1_6_rsp_out[4];
  assign mesh_router_1_6_to_mesh_router_2_6_rsp = mesh_router_1_6_rsp_out[5];

  assign mesh_router_1_6_to_int_core_master_ni_1_6_req = mesh_router_1_6_req_out[0];
  assign mesh_router_1_6_to_int_core_slave_ni_1_6_req = mesh_router_1_6_req_out[1];
  assign mesh_router_1_6_to_mesh_router_0_6_req = mesh_router_1_6_req_out[2];
  assign mesh_router_1_6_to_mesh_router_1_5_req = mesh_router_1_6_req_out[3];
  assign mesh_router_1_6_to_mesh_router_1_7_req = mesh_router_1_6_req_out[4];
  assign mesh_router_1_6_to_mesh_router_2_6_req = mesh_router_1_6_req_out[5];

  assign mesh_router_1_6_rsp_in[0] = int_core_master_ni_1_6_to_mesh_router_1_6_rsp;
  assign mesh_router_1_6_rsp_in[1] = int_core_slave_ni_1_6_to_mesh_router_1_6_rsp;
  assign mesh_router_1_6_rsp_in[2] = mesh_router_0_6_to_mesh_router_1_6_rsp;
  assign mesh_router_1_6_rsp_in[3] = mesh_router_1_5_to_mesh_router_1_6_rsp;
  assign mesh_router_1_6_rsp_in[4] = mesh_router_1_7_to_mesh_router_1_6_rsp;
  assign mesh_router_1_6_rsp_in[5] = mesh_router_2_6_to_mesh_router_1_6_rsp;


  floo_axi_router #(
      .AxiCfg(AxiCfg),
      .RouteAlgo(IdTable),
      .NumRoutes(6),
      .NumInputs(6),
      .NumOutputs(6),
      .InFifoDepth(2),
      .OutFifoDepth(2),
      .id_t(id_t),
      .hdr_t(hdr_t),
      .NumAddrRules(24),
      .addr_rule_t(mesh_router_1_6_map_rule_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) mesh_router_1_6 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('0),
      .id_route_map_i(MeshRouter16Map),
      .floo_req_i(mesh_router_1_6_req_in),
      .floo_rsp_o(mesh_router_1_6_rsp_out),
      .floo_req_o(mesh_router_1_6_req_out),
      .floo_rsp_i(mesh_router_1_6_rsp_in)
  );

  localparam int unsigned MeshRouter17MapNumRules = 17;

  typedef struct packed {
    id_t idx;
    id_t start_addr;
    id_t end_addr;
  } mesh_router_1_7_map_rule_t;

  localparam mesh_router_1_7_map_rule_t [MeshRouter17MapNumRules-1:0] MeshRouter17Map = '{
      '{idx: 2, start_addr: 0, end_addr: 12},  // cpu_master_ni
      '{idx: 2, start_addr: 36, end_addr: 58},  // llc_slave_ni
      '{idx: 2, start_addr: 90, end_addr: 92},  // sp_slave_ni
      '{idx: 3, start_addr: 12, end_addr: 19},  // int_core_master_ni_1_0
      '{idx: 3, start_addr: 20, end_addr: 27},  // int_core_master_ni_2_0
      '{idx: 3, start_addr: 28, end_addr: 35},  // int_core_master_ni_3_0
      '{idx: 3, start_addr: 58, end_addr: 65},  // int_core_slave_ni_1_0
      '{idx: 3, start_addr: 66, end_addr: 73},  // int_core_slave_ni_2_0
      '{idx: 3, start_addr: 74, end_addr: 81},  // int_core_slave_ni_3_0
      '{idx: 3, start_addr: 82, end_addr: 89},  // fp_core_slave_ni_0_0
      '{idx: 0, start_addr: 19, end_addr: 20},  // int_core_master_ni_1_7
      '{idx: 4, start_addr: 27, end_addr: 28},  // int_core_master_ni_2_7
      '{idx: 4, start_addr: 35, end_addr: 36},  // int_core_master_ni_3_7
      '{idx: 4, start_addr: 73, end_addr: 74},  // int_core_slave_ni_2_7
      '{idx: 4, start_addr: 81, end_addr: 82},  // int_core_slave_ni_3_7
      '{idx: 4, start_addr: 89, end_addr: 90},  // fp_core_slave_ni_0_7
      '{idx: 1, start_addr: 65, end_addr: 66}  // int_core_slave_ni_1_7

  };


  floo_req_t [4:0] mesh_router_1_7_req_in;
  floo_rsp_t [4:0] mesh_router_1_7_rsp_out;
  floo_req_t [4:0] mesh_router_1_7_req_out;
  floo_rsp_t [4:0] mesh_router_1_7_rsp_in;

  assign mesh_router_1_7_req_in[0] = int_core_master_ni_1_7_to_mesh_router_1_7_req;
  assign mesh_router_1_7_req_in[1] = int_core_slave_ni_1_7_to_mesh_router_1_7_req;
  assign mesh_router_1_7_req_in[2] = mesh_router_0_7_to_mesh_router_1_7_req;
  assign mesh_router_1_7_req_in[3] = mesh_router_1_6_to_mesh_router_1_7_req;
  assign mesh_router_1_7_req_in[4] = mesh_router_2_7_to_mesh_router_1_7_req;

  assign mesh_router_1_7_to_int_core_master_ni_1_7_rsp = mesh_router_1_7_rsp_out[0];
  assign mesh_router_1_7_to_int_core_slave_ni_1_7_rsp = mesh_router_1_7_rsp_out[1];
  assign mesh_router_1_7_to_mesh_router_0_7_rsp = mesh_router_1_7_rsp_out[2];
  assign mesh_router_1_7_to_mesh_router_1_6_rsp = mesh_router_1_7_rsp_out[3];
  assign mesh_router_1_7_to_mesh_router_2_7_rsp = mesh_router_1_7_rsp_out[4];

  assign mesh_router_1_7_to_int_core_master_ni_1_7_req = mesh_router_1_7_req_out[0];
  assign mesh_router_1_7_to_int_core_slave_ni_1_7_req = mesh_router_1_7_req_out[1];
  assign mesh_router_1_7_to_mesh_router_0_7_req = mesh_router_1_7_req_out[2];
  assign mesh_router_1_7_to_mesh_router_1_6_req = mesh_router_1_7_req_out[3];
  assign mesh_router_1_7_to_mesh_router_2_7_req = mesh_router_1_7_req_out[4];

  assign mesh_router_1_7_rsp_in[0] = int_core_master_ni_1_7_to_mesh_router_1_7_rsp;
  assign mesh_router_1_7_rsp_in[1] = int_core_slave_ni_1_7_to_mesh_router_1_7_rsp;
  assign mesh_router_1_7_rsp_in[2] = mesh_router_0_7_to_mesh_router_1_7_rsp;
  assign mesh_router_1_7_rsp_in[3] = mesh_router_1_6_to_mesh_router_1_7_rsp;
  assign mesh_router_1_7_rsp_in[4] = mesh_router_2_7_to_mesh_router_1_7_rsp;


  floo_axi_router #(
      .AxiCfg(AxiCfg),
      .RouteAlgo(IdTable),
      .NumRoutes(5),
      .NumInputs(5),
      .NumOutputs(5),
      .InFifoDepth(2),
      .OutFifoDepth(2),
      .id_t(id_t),
      .hdr_t(hdr_t),
      .NumAddrRules(17),
      .addr_rule_t(mesh_router_1_7_map_rule_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) mesh_router_1_7 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('0),
      .id_route_map_i(MeshRouter17Map),
      .floo_req_i(mesh_router_1_7_req_in),
      .floo_rsp_o(mesh_router_1_7_rsp_out),
      .floo_req_o(mesh_router_1_7_req_out),
      .floo_rsp_i(mesh_router_1_7_rsp_in)
  );

  localparam int unsigned MeshRouter20MapNumRules = 13;

  typedef struct packed {
    id_t idx;
    id_t start_addr;
    id_t end_addr;
  } mesh_router_2_0_map_rule_t;

  localparam mesh_router_2_0_map_rule_t [MeshRouter20MapNumRules-1:0] MeshRouter20Map = '{
      '{idx: 2, start_addr: 0, end_addr: 20},  // cpu_master_ni
      '{idx: 2, start_addr: 36, end_addr: 66},  // llc_slave_ni
      '{idx: 2, start_addr: 90, end_addr: 92},  // sp_slave_ni
      '{idx: 0, start_addr: 20, end_addr: 21},  // int_core_master_ni_2_0
      '{idx: 3, start_addr: 21, end_addr: 28},  // int_core_master_ni_2_1
      '{idx: 3, start_addr: 29, end_addr: 36},  // int_core_master_ni_3_1
      '{idx: 3, start_addr: 67, end_addr: 74},  // int_core_slave_ni_2_1
      '{idx: 3, start_addr: 75, end_addr: 82},  // int_core_slave_ni_3_1
      '{idx: 3, start_addr: 83, end_addr: 90},  // fp_core_slave_ni_0_1
      '{idx: 4, start_addr: 28, end_addr: 29},  // int_core_master_ni_3_0
      '{idx: 4, start_addr: 74, end_addr: 75},  // int_core_slave_ni_3_0
      '{idx: 4, start_addr: 82, end_addr: 83},  // fp_core_slave_ni_0_0
      '{idx: 1, start_addr: 66, end_addr: 67}  // int_core_slave_ni_2_0

  };


  floo_req_t [4:0] mesh_router_2_0_req_in;
  floo_rsp_t [4:0] mesh_router_2_0_rsp_out;
  floo_req_t [4:0] mesh_router_2_0_req_out;
  floo_rsp_t [4:0] mesh_router_2_0_rsp_in;

  assign mesh_router_2_0_req_in[0] = int_core_master_ni_2_0_to_mesh_router_2_0_req;
  assign mesh_router_2_0_req_in[1] = int_core_slave_ni_2_0_to_mesh_router_2_0_req;
  assign mesh_router_2_0_req_in[2] = mesh_router_1_0_to_mesh_router_2_0_req;
  assign mesh_router_2_0_req_in[3] = mesh_router_2_1_to_mesh_router_2_0_req;
  assign mesh_router_2_0_req_in[4] = mesh_router_3_0_to_mesh_router_2_0_req;

  assign mesh_router_2_0_to_int_core_master_ni_2_0_rsp = mesh_router_2_0_rsp_out[0];
  assign mesh_router_2_0_to_int_core_slave_ni_2_0_rsp = mesh_router_2_0_rsp_out[1];
  assign mesh_router_2_0_to_mesh_router_1_0_rsp = mesh_router_2_0_rsp_out[2];
  assign mesh_router_2_0_to_mesh_router_2_1_rsp = mesh_router_2_0_rsp_out[3];
  assign mesh_router_2_0_to_mesh_router_3_0_rsp = mesh_router_2_0_rsp_out[4];

  assign mesh_router_2_0_to_int_core_master_ni_2_0_req = mesh_router_2_0_req_out[0];
  assign mesh_router_2_0_to_int_core_slave_ni_2_0_req = mesh_router_2_0_req_out[1];
  assign mesh_router_2_0_to_mesh_router_1_0_req = mesh_router_2_0_req_out[2];
  assign mesh_router_2_0_to_mesh_router_2_1_req = mesh_router_2_0_req_out[3];
  assign mesh_router_2_0_to_mesh_router_3_0_req = mesh_router_2_0_req_out[4];

  assign mesh_router_2_0_rsp_in[0] = int_core_master_ni_2_0_to_mesh_router_2_0_rsp;
  assign mesh_router_2_0_rsp_in[1] = int_core_slave_ni_2_0_to_mesh_router_2_0_rsp;
  assign mesh_router_2_0_rsp_in[2] = mesh_router_1_0_to_mesh_router_2_0_rsp;
  assign mesh_router_2_0_rsp_in[3] = mesh_router_2_1_to_mesh_router_2_0_rsp;
  assign mesh_router_2_0_rsp_in[4] = mesh_router_3_0_to_mesh_router_2_0_rsp;


  floo_axi_router #(
      .AxiCfg(AxiCfg),
      .RouteAlgo(IdTable),
      .NumRoutes(5),
      .NumInputs(5),
      .NumOutputs(5),
      .InFifoDepth(2),
      .OutFifoDepth(2),
      .id_t(id_t),
      .hdr_t(hdr_t),
      .NumAddrRules(13),
      .addr_rule_t(mesh_router_2_0_map_rule_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) mesh_router_2_0 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('0),
      .id_route_map_i(MeshRouter20Map),
      .floo_req_i(mesh_router_2_0_req_in),
      .floo_rsp_o(mesh_router_2_0_rsp_out),
      .floo_req_o(mesh_router_2_0_req_out),
      .floo_rsp_i(mesh_router_2_0_rsp_in)
  );

  localparam int unsigned MeshRouter21MapNumRules = 18;

  typedef struct packed {
    id_t idx;
    id_t start_addr;
    id_t end_addr;
  } mesh_router_2_1_map_rule_t;

  localparam mesh_router_2_1_map_rule_t [MeshRouter21MapNumRules-1:0] MeshRouter21Map = '{
      '{idx: 2, start_addr: 0, end_addr: 20},  // cpu_master_ni
      '{idx: 2, start_addr: 36, end_addr: 66},  // llc_slave_ni
      '{idx: 2, start_addr: 90, end_addr: 92},  // sp_slave_ni
      '{idx: 3, start_addr: 20, end_addr: 21},  // int_core_master_ni_2_0
      '{idx: 3, start_addr: 28, end_addr: 29},  // int_core_master_ni_3_0
      '{idx: 3, start_addr: 66, end_addr: 67},  // int_core_slave_ni_2_0
      '{idx: 3, start_addr: 74, end_addr: 75},  // int_core_slave_ni_3_0
      '{idx: 3, start_addr: 82, end_addr: 83},  // fp_core_slave_ni_0_0
      '{idx: 0, start_addr: 21, end_addr: 22},  // int_core_master_ni_2_1
      '{idx: 4, start_addr: 22, end_addr: 28},  // int_core_master_ni_2_2
      '{idx: 4, start_addr: 30, end_addr: 36},  // int_core_master_ni_3_2
      '{idx: 4, start_addr: 68, end_addr: 74},  // int_core_slave_ni_2_2
      '{idx: 4, start_addr: 76, end_addr: 82},  // int_core_slave_ni_3_2
      '{idx: 4, start_addr: 84, end_addr: 90},  // fp_core_slave_ni_0_2
      '{idx: 5, start_addr: 29, end_addr: 30},  // int_core_master_ni_3_1
      '{idx: 5, start_addr: 75, end_addr: 76},  // int_core_slave_ni_3_1
      '{idx: 5, start_addr: 83, end_addr: 84},  // fp_core_slave_ni_0_1
      '{idx: 1, start_addr: 67, end_addr: 68}  // int_core_slave_ni_2_1

  };


  floo_req_t [5:0] mesh_router_2_1_req_in;
  floo_rsp_t [5:0] mesh_router_2_1_rsp_out;
  floo_req_t [5:0] mesh_router_2_1_req_out;
  floo_rsp_t [5:0] mesh_router_2_1_rsp_in;

  assign mesh_router_2_1_req_in[0] = int_core_master_ni_2_1_to_mesh_router_2_1_req;
  assign mesh_router_2_1_req_in[1] = int_core_slave_ni_2_1_to_mesh_router_2_1_req;
  assign mesh_router_2_1_req_in[2] = mesh_router_1_1_to_mesh_router_2_1_req;
  assign mesh_router_2_1_req_in[3] = mesh_router_2_0_to_mesh_router_2_1_req;
  assign mesh_router_2_1_req_in[4] = mesh_router_2_2_to_mesh_router_2_1_req;
  assign mesh_router_2_1_req_in[5] = mesh_router_3_1_to_mesh_router_2_1_req;

  assign mesh_router_2_1_to_int_core_master_ni_2_1_rsp = mesh_router_2_1_rsp_out[0];
  assign mesh_router_2_1_to_int_core_slave_ni_2_1_rsp = mesh_router_2_1_rsp_out[1];
  assign mesh_router_2_1_to_mesh_router_1_1_rsp = mesh_router_2_1_rsp_out[2];
  assign mesh_router_2_1_to_mesh_router_2_0_rsp = mesh_router_2_1_rsp_out[3];
  assign mesh_router_2_1_to_mesh_router_2_2_rsp = mesh_router_2_1_rsp_out[4];
  assign mesh_router_2_1_to_mesh_router_3_1_rsp = mesh_router_2_1_rsp_out[5];

  assign mesh_router_2_1_to_int_core_master_ni_2_1_req = mesh_router_2_1_req_out[0];
  assign mesh_router_2_1_to_int_core_slave_ni_2_1_req = mesh_router_2_1_req_out[1];
  assign mesh_router_2_1_to_mesh_router_1_1_req = mesh_router_2_1_req_out[2];
  assign mesh_router_2_1_to_mesh_router_2_0_req = mesh_router_2_1_req_out[3];
  assign mesh_router_2_1_to_mesh_router_2_2_req = mesh_router_2_1_req_out[4];
  assign mesh_router_2_1_to_mesh_router_3_1_req = mesh_router_2_1_req_out[5];

  assign mesh_router_2_1_rsp_in[0] = int_core_master_ni_2_1_to_mesh_router_2_1_rsp;
  assign mesh_router_2_1_rsp_in[1] = int_core_slave_ni_2_1_to_mesh_router_2_1_rsp;
  assign mesh_router_2_1_rsp_in[2] = mesh_router_1_1_to_mesh_router_2_1_rsp;
  assign mesh_router_2_1_rsp_in[3] = mesh_router_2_0_to_mesh_router_2_1_rsp;
  assign mesh_router_2_1_rsp_in[4] = mesh_router_2_2_to_mesh_router_2_1_rsp;
  assign mesh_router_2_1_rsp_in[5] = mesh_router_3_1_to_mesh_router_2_1_rsp;


  floo_axi_router #(
      .AxiCfg(AxiCfg),
      .RouteAlgo(IdTable),
      .NumRoutes(6),
      .NumInputs(6),
      .NumOutputs(6),
      .InFifoDepth(2),
      .OutFifoDepth(2),
      .id_t(id_t),
      .hdr_t(hdr_t),
      .NumAddrRules(18),
      .addr_rule_t(mesh_router_2_1_map_rule_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) mesh_router_2_1 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('0),
      .id_route_map_i(MeshRouter21Map),
      .floo_req_i(mesh_router_2_1_req_in),
      .floo_rsp_o(mesh_router_2_1_rsp_out),
      .floo_req_o(mesh_router_2_1_req_out),
      .floo_rsp_i(mesh_router_2_1_rsp_in)
  );

  localparam int unsigned MeshRouter22MapNumRules = 18;

  typedef struct packed {
    id_t idx;
    id_t start_addr;
    id_t end_addr;
  } mesh_router_2_2_map_rule_t;

  localparam mesh_router_2_2_map_rule_t [MeshRouter22MapNumRules-1:0] MeshRouter22Map = '{
      '{idx: 2, start_addr: 0, end_addr: 20},  // cpu_master_ni
      '{idx: 2, start_addr: 36, end_addr: 66},  // llc_slave_ni
      '{idx: 2, start_addr: 90, end_addr: 92},  // sp_slave_ni
      '{idx: 3, start_addr: 20, end_addr: 22},  // int_core_master_ni_2_0
      '{idx: 3, start_addr: 28, end_addr: 30},  // int_core_master_ni_3_0
      '{idx: 3, start_addr: 66, end_addr: 68},  // int_core_slave_ni_2_0
      '{idx: 3, start_addr: 74, end_addr: 76},  // int_core_slave_ni_3_0
      '{idx: 3, start_addr: 82, end_addr: 84},  // fp_core_slave_ni_0_0
      '{idx: 0, start_addr: 22, end_addr: 23},  // int_core_master_ni_2_2
      '{idx: 4, start_addr: 23, end_addr: 28},  // int_core_master_ni_2_3
      '{idx: 4, start_addr: 31, end_addr: 36},  // int_core_master_ni_3_3
      '{idx: 4, start_addr: 69, end_addr: 74},  // int_core_slave_ni_2_3
      '{idx: 4, start_addr: 77, end_addr: 82},  // int_core_slave_ni_3_3
      '{idx: 4, start_addr: 85, end_addr: 90},  // fp_core_slave_ni_0_3
      '{idx: 5, start_addr: 30, end_addr: 31},  // int_core_master_ni_3_2
      '{idx: 5, start_addr: 76, end_addr: 77},  // int_core_slave_ni_3_2
      '{idx: 5, start_addr: 84, end_addr: 85},  // fp_core_slave_ni_0_2
      '{idx: 1, start_addr: 68, end_addr: 69}  // int_core_slave_ni_2_2

  };


  floo_req_t [5:0] mesh_router_2_2_req_in;
  floo_rsp_t [5:0] mesh_router_2_2_rsp_out;
  floo_req_t [5:0] mesh_router_2_2_req_out;
  floo_rsp_t [5:0] mesh_router_2_2_rsp_in;

  assign mesh_router_2_2_req_in[0] = int_core_master_ni_2_2_to_mesh_router_2_2_req;
  assign mesh_router_2_2_req_in[1] = int_core_slave_ni_2_2_to_mesh_router_2_2_req;
  assign mesh_router_2_2_req_in[2] = mesh_router_1_2_to_mesh_router_2_2_req;
  assign mesh_router_2_2_req_in[3] = mesh_router_2_1_to_mesh_router_2_2_req;
  assign mesh_router_2_2_req_in[4] = mesh_router_2_3_to_mesh_router_2_2_req;
  assign mesh_router_2_2_req_in[5] = mesh_router_3_2_to_mesh_router_2_2_req;

  assign mesh_router_2_2_to_int_core_master_ni_2_2_rsp = mesh_router_2_2_rsp_out[0];
  assign mesh_router_2_2_to_int_core_slave_ni_2_2_rsp = mesh_router_2_2_rsp_out[1];
  assign mesh_router_2_2_to_mesh_router_1_2_rsp = mesh_router_2_2_rsp_out[2];
  assign mesh_router_2_2_to_mesh_router_2_1_rsp = mesh_router_2_2_rsp_out[3];
  assign mesh_router_2_2_to_mesh_router_2_3_rsp = mesh_router_2_2_rsp_out[4];
  assign mesh_router_2_2_to_mesh_router_3_2_rsp = mesh_router_2_2_rsp_out[5];

  assign mesh_router_2_2_to_int_core_master_ni_2_2_req = mesh_router_2_2_req_out[0];
  assign mesh_router_2_2_to_int_core_slave_ni_2_2_req = mesh_router_2_2_req_out[1];
  assign mesh_router_2_2_to_mesh_router_1_2_req = mesh_router_2_2_req_out[2];
  assign mesh_router_2_2_to_mesh_router_2_1_req = mesh_router_2_2_req_out[3];
  assign mesh_router_2_2_to_mesh_router_2_3_req = mesh_router_2_2_req_out[4];
  assign mesh_router_2_2_to_mesh_router_3_2_req = mesh_router_2_2_req_out[5];

  assign mesh_router_2_2_rsp_in[0] = int_core_master_ni_2_2_to_mesh_router_2_2_rsp;
  assign mesh_router_2_2_rsp_in[1] = int_core_slave_ni_2_2_to_mesh_router_2_2_rsp;
  assign mesh_router_2_2_rsp_in[2] = mesh_router_1_2_to_mesh_router_2_2_rsp;
  assign mesh_router_2_2_rsp_in[3] = mesh_router_2_1_to_mesh_router_2_2_rsp;
  assign mesh_router_2_2_rsp_in[4] = mesh_router_2_3_to_mesh_router_2_2_rsp;
  assign mesh_router_2_2_rsp_in[5] = mesh_router_3_2_to_mesh_router_2_2_rsp;


  floo_axi_router #(
      .AxiCfg(AxiCfg),
      .RouteAlgo(IdTable),
      .NumRoutes(6),
      .NumInputs(6),
      .NumOutputs(6),
      .InFifoDepth(2),
      .OutFifoDepth(2),
      .id_t(id_t),
      .hdr_t(hdr_t),
      .NumAddrRules(18),
      .addr_rule_t(mesh_router_2_2_map_rule_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) mesh_router_2_2 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('0),
      .id_route_map_i(MeshRouter22Map),
      .floo_req_i(mesh_router_2_2_req_in),
      .floo_rsp_o(mesh_router_2_2_rsp_out),
      .floo_req_o(mesh_router_2_2_req_out),
      .floo_rsp_i(mesh_router_2_2_rsp_in)
  );

  localparam int unsigned MeshRouter23MapNumRules = 18;

  typedef struct packed {
    id_t idx;
    id_t start_addr;
    id_t end_addr;
  } mesh_router_2_3_map_rule_t;

  localparam mesh_router_2_3_map_rule_t [MeshRouter23MapNumRules-1:0] MeshRouter23Map = '{
      '{idx: 2, start_addr: 0, end_addr: 20},  // cpu_master_ni
      '{idx: 2, start_addr: 36, end_addr: 66},  // llc_slave_ni
      '{idx: 2, start_addr: 90, end_addr: 92},  // sp_slave_ni
      '{idx: 3, start_addr: 20, end_addr: 23},  // int_core_master_ni_2_0
      '{idx: 3, start_addr: 28, end_addr: 31},  // int_core_master_ni_3_0
      '{idx: 3, start_addr: 66, end_addr: 69},  // int_core_slave_ni_2_0
      '{idx: 3, start_addr: 74, end_addr: 77},  // int_core_slave_ni_3_0
      '{idx: 3, start_addr: 82, end_addr: 85},  // fp_core_slave_ni_0_0
      '{idx: 0, start_addr: 23, end_addr: 24},  // int_core_master_ni_2_3
      '{idx: 4, start_addr: 24, end_addr: 28},  // int_core_master_ni_2_4
      '{idx: 4, start_addr: 32, end_addr: 36},  // int_core_master_ni_3_4
      '{idx: 4, start_addr: 70, end_addr: 74},  // int_core_slave_ni_2_4
      '{idx: 4, start_addr: 78, end_addr: 82},  // int_core_slave_ni_3_4
      '{idx: 4, start_addr: 86, end_addr: 90},  // fp_core_slave_ni_0_4
      '{idx: 5, start_addr: 31, end_addr: 32},  // int_core_master_ni_3_3
      '{idx: 5, start_addr: 77, end_addr: 78},  // int_core_slave_ni_3_3
      '{idx: 5, start_addr: 85, end_addr: 86},  // fp_core_slave_ni_0_3
      '{idx: 1, start_addr: 69, end_addr: 70}  // int_core_slave_ni_2_3

  };


  floo_req_t [5:0] mesh_router_2_3_req_in;
  floo_rsp_t [5:0] mesh_router_2_3_rsp_out;
  floo_req_t [5:0] mesh_router_2_3_req_out;
  floo_rsp_t [5:0] mesh_router_2_3_rsp_in;

  assign mesh_router_2_3_req_in[0] = int_core_master_ni_2_3_to_mesh_router_2_3_req;
  assign mesh_router_2_3_req_in[1] = int_core_slave_ni_2_3_to_mesh_router_2_3_req;
  assign mesh_router_2_3_req_in[2] = mesh_router_1_3_to_mesh_router_2_3_req;
  assign mesh_router_2_3_req_in[3] = mesh_router_2_2_to_mesh_router_2_3_req;
  assign mesh_router_2_3_req_in[4] = mesh_router_2_4_to_mesh_router_2_3_req;
  assign mesh_router_2_3_req_in[5] = mesh_router_3_3_to_mesh_router_2_3_req;

  assign mesh_router_2_3_to_int_core_master_ni_2_3_rsp = mesh_router_2_3_rsp_out[0];
  assign mesh_router_2_3_to_int_core_slave_ni_2_3_rsp = mesh_router_2_3_rsp_out[1];
  assign mesh_router_2_3_to_mesh_router_1_3_rsp = mesh_router_2_3_rsp_out[2];
  assign mesh_router_2_3_to_mesh_router_2_2_rsp = mesh_router_2_3_rsp_out[3];
  assign mesh_router_2_3_to_mesh_router_2_4_rsp = mesh_router_2_3_rsp_out[4];
  assign mesh_router_2_3_to_mesh_router_3_3_rsp = mesh_router_2_3_rsp_out[5];

  assign mesh_router_2_3_to_int_core_master_ni_2_3_req = mesh_router_2_3_req_out[0];
  assign mesh_router_2_3_to_int_core_slave_ni_2_3_req = mesh_router_2_3_req_out[1];
  assign mesh_router_2_3_to_mesh_router_1_3_req = mesh_router_2_3_req_out[2];
  assign mesh_router_2_3_to_mesh_router_2_2_req = mesh_router_2_3_req_out[3];
  assign mesh_router_2_3_to_mesh_router_2_4_req = mesh_router_2_3_req_out[4];
  assign mesh_router_2_3_to_mesh_router_3_3_req = mesh_router_2_3_req_out[5];

  assign mesh_router_2_3_rsp_in[0] = int_core_master_ni_2_3_to_mesh_router_2_3_rsp;
  assign mesh_router_2_3_rsp_in[1] = int_core_slave_ni_2_3_to_mesh_router_2_3_rsp;
  assign mesh_router_2_3_rsp_in[2] = mesh_router_1_3_to_mesh_router_2_3_rsp;
  assign mesh_router_2_3_rsp_in[3] = mesh_router_2_2_to_mesh_router_2_3_rsp;
  assign mesh_router_2_3_rsp_in[4] = mesh_router_2_4_to_mesh_router_2_3_rsp;
  assign mesh_router_2_3_rsp_in[5] = mesh_router_3_3_to_mesh_router_2_3_rsp;


  floo_axi_router #(
      .AxiCfg(AxiCfg),
      .RouteAlgo(IdTable),
      .NumRoutes(6),
      .NumInputs(6),
      .NumOutputs(6),
      .InFifoDepth(2),
      .OutFifoDepth(2),
      .id_t(id_t),
      .hdr_t(hdr_t),
      .NumAddrRules(18),
      .addr_rule_t(mesh_router_2_3_map_rule_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) mesh_router_2_3 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('0),
      .id_route_map_i(MeshRouter23Map),
      .floo_req_i(mesh_router_2_3_req_in),
      .floo_rsp_o(mesh_router_2_3_rsp_out),
      .floo_req_o(mesh_router_2_3_req_out),
      .floo_rsp_i(mesh_router_2_3_rsp_in)
  );

  localparam int unsigned MeshRouter24MapNumRules = 18;

  typedef struct packed {
    id_t idx;
    id_t start_addr;
    id_t end_addr;
  } mesh_router_2_4_map_rule_t;

  localparam mesh_router_2_4_map_rule_t [MeshRouter24MapNumRules-1:0] MeshRouter24Map = '{
      '{idx: 2, start_addr: 0, end_addr: 20},  // cpu_master_ni
      '{idx: 2, start_addr: 36, end_addr: 66},  // llc_slave_ni
      '{idx: 2, start_addr: 90, end_addr: 92},  // sp_slave_ni
      '{idx: 3, start_addr: 20, end_addr: 24},  // int_core_master_ni_2_0
      '{idx: 3, start_addr: 28, end_addr: 32},  // int_core_master_ni_3_0
      '{idx: 3, start_addr: 66, end_addr: 70},  // int_core_slave_ni_2_0
      '{idx: 3, start_addr: 74, end_addr: 78},  // int_core_slave_ni_3_0
      '{idx: 3, start_addr: 82, end_addr: 86},  // fp_core_slave_ni_0_0
      '{idx: 0, start_addr: 24, end_addr: 25},  // int_core_master_ni_2_4
      '{idx: 4, start_addr: 25, end_addr: 28},  // int_core_master_ni_2_5
      '{idx: 4, start_addr: 33, end_addr: 36},  // int_core_master_ni_3_5
      '{idx: 4, start_addr: 71, end_addr: 74},  // int_core_slave_ni_2_5
      '{idx: 4, start_addr: 79, end_addr: 82},  // int_core_slave_ni_3_5
      '{idx: 4, start_addr: 87, end_addr: 90},  // fp_core_slave_ni_0_5
      '{idx: 5, start_addr: 32, end_addr: 33},  // int_core_master_ni_3_4
      '{idx: 5, start_addr: 78, end_addr: 79},  // int_core_slave_ni_3_4
      '{idx: 5, start_addr: 86, end_addr: 87},  // fp_core_slave_ni_0_4
      '{idx: 1, start_addr: 70, end_addr: 71}  // int_core_slave_ni_2_4

  };


  floo_req_t [5:0] mesh_router_2_4_req_in;
  floo_rsp_t [5:0] mesh_router_2_4_rsp_out;
  floo_req_t [5:0] mesh_router_2_4_req_out;
  floo_rsp_t [5:0] mesh_router_2_4_rsp_in;

  assign mesh_router_2_4_req_in[0] = int_core_master_ni_2_4_to_mesh_router_2_4_req;
  assign mesh_router_2_4_req_in[1] = int_core_slave_ni_2_4_to_mesh_router_2_4_req;
  assign mesh_router_2_4_req_in[2] = mesh_router_1_4_to_mesh_router_2_4_req;
  assign mesh_router_2_4_req_in[3] = mesh_router_2_3_to_mesh_router_2_4_req;
  assign mesh_router_2_4_req_in[4] = mesh_router_2_5_to_mesh_router_2_4_req;
  assign mesh_router_2_4_req_in[5] = mesh_router_3_4_to_mesh_router_2_4_req;

  assign mesh_router_2_4_to_int_core_master_ni_2_4_rsp = mesh_router_2_4_rsp_out[0];
  assign mesh_router_2_4_to_int_core_slave_ni_2_4_rsp = mesh_router_2_4_rsp_out[1];
  assign mesh_router_2_4_to_mesh_router_1_4_rsp = mesh_router_2_4_rsp_out[2];
  assign mesh_router_2_4_to_mesh_router_2_3_rsp = mesh_router_2_4_rsp_out[3];
  assign mesh_router_2_4_to_mesh_router_2_5_rsp = mesh_router_2_4_rsp_out[4];
  assign mesh_router_2_4_to_mesh_router_3_4_rsp = mesh_router_2_4_rsp_out[5];

  assign mesh_router_2_4_to_int_core_master_ni_2_4_req = mesh_router_2_4_req_out[0];
  assign mesh_router_2_4_to_int_core_slave_ni_2_4_req = mesh_router_2_4_req_out[1];
  assign mesh_router_2_4_to_mesh_router_1_4_req = mesh_router_2_4_req_out[2];
  assign mesh_router_2_4_to_mesh_router_2_3_req = mesh_router_2_4_req_out[3];
  assign mesh_router_2_4_to_mesh_router_2_5_req = mesh_router_2_4_req_out[4];
  assign mesh_router_2_4_to_mesh_router_3_4_req = mesh_router_2_4_req_out[5];

  assign mesh_router_2_4_rsp_in[0] = int_core_master_ni_2_4_to_mesh_router_2_4_rsp;
  assign mesh_router_2_4_rsp_in[1] = int_core_slave_ni_2_4_to_mesh_router_2_4_rsp;
  assign mesh_router_2_4_rsp_in[2] = mesh_router_1_4_to_mesh_router_2_4_rsp;
  assign mesh_router_2_4_rsp_in[3] = mesh_router_2_3_to_mesh_router_2_4_rsp;
  assign mesh_router_2_4_rsp_in[4] = mesh_router_2_5_to_mesh_router_2_4_rsp;
  assign mesh_router_2_4_rsp_in[5] = mesh_router_3_4_to_mesh_router_2_4_rsp;


  floo_axi_router #(
      .AxiCfg(AxiCfg),
      .RouteAlgo(IdTable),
      .NumRoutes(6),
      .NumInputs(6),
      .NumOutputs(6),
      .InFifoDepth(2),
      .OutFifoDepth(2),
      .id_t(id_t),
      .hdr_t(hdr_t),
      .NumAddrRules(18),
      .addr_rule_t(mesh_router_2_4_map_rule_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) mesh_router_2_4 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('0),
      .id_route_map_i(MeshRouter24Map),
      .floo_req_i(mesh_router_2_4_req_in),
      .floo_rsp_o(mesh_router_2_4_rsp_out),
      .floo_req_o(mesh_router_2_4_req_out),
      .floo_rsp_i(mesh_router_2_4_rsp_in)
  );

  localparam int unsigned MeshRouter25MapNumRules = 18;

  typedef struct packed {
    id_t idx;
    id_t start_addr;
    id_t end_addr;
  } mesh_router_2_5_map_rule_t;

  localparam mesh_router_2_5_map_rule_t [MeshRouter25MapNumRules-1:0] MeshRouter25Map = '{
      '{idx: 2, start_addr: 0, end_addr: 20},  // cpu_master_ni
      '{idx: 2, start_addr: 36, end_addr: 66},  // llc_slave_ni
      '{idx: 2, start_addr: 90, end_addr: 92},  // sp_slave_ni
      '{idx: 3, start_addr: 20, end_addr: 25},  // int_core_master_ni_2_0
      '{idx: 3, start_addr: 28, end_addr: 33},  // int_core_master_ni_3_0
      '{idx: 3, start_addr: 66, end_addr: 71},  // int_core_slave_ni_2_0
      '{idx: 3, start_addr: 74, end_addr: 79},  // int_core_slave_ni_3_0
      '{idx: 3, start_addr: 82, end_addr: 87},  // fp_core_slave_ni_0_0
      '{idx: 0, start_addr: 25, end_addr: 26},  // int_core_master_ni_2_5
      '{idx: 4, start_addr: 26, end_addr: 28},  // int_core_master_ni_2_6
      '{idx: 4, start_addr: 34, end_addr: 36},  // int_core_master_ni_3_6
      '{idx: 4, start_addr: 72, end_addr: 74},  // int_core_slave_ni_2_6
      '{idx: 4, start_addr: 80, end_addr: 82},  // int_core_slave_ni_3_6
      '{idx: 4, start_addr: 88, end_addr: 90},  // fp_core_slave_ni_0_6
      '{idx: 5, start_addr: 33, end_addr: 34},  // int_core_master_ni_3_5
      '{idx: 5, start_addr: 79, end_addr: 80},  // int_core_slave_ni_3_5
      '{idx: 5, start_addr: 87, end_addr: 88},  // fp_core_slave_ni_0_5
      '{idx: 1, start_addr: 71, end_addr: 72}  // int_core_slave_ni_2_5

  };


  floo_req_t [5:0] mesh_router_2_5_req_in;
  floo_rsp_t [5:0] mesh_router_2_5_rsp_out;
  floo_req_t [5:0] mesh_router_2_5_req_out;
  floo_rsp_t [5:0] mesh_router_2_5_rsp_in;

  assign mesh_router_2_5_req_in[0] = int_core_master_ni_2_5_to_mesh_router_2_5_req;
  assign mesh_router_2_5_req_in[1] = int_core_slave_ni_2_5_to_mesh_router_2_5_req;
  assign mesh_router_2_5_req_in[2] = mesh_router_1_5_to_mesh_router_2_5_req;
  assign mesh_router_2_5_req_in[3] = mesh_router_2_4_to_mesh_router_2_5_req;
  assign mesh_router_2_5_req_in[4] = mesh_router_2_6_to_mesh_router_2_5_req;
  assign mesh_router_2_5_req_in[5] = mesh_router_3_5_to_mesh_router_2_5_req;

  assign mesh_router_2_5_to_int_core_master_ni_2_5_rsp = mesh_router_2_5_rsp_out[0];
  assign mesh_router_2_5_to_int_core_slave_ni_2_5_rsp = mesh_router_2_5_rsp_out[1];
  assign mesh_router_2_5_to_mesh_router_1_5_rsp = mesh_router_2_5_rsp_out[2];
  assign mesh_router_2_5_to_mesh_router_2_4_rsp = mesh_router_2_5_rsp_out[3];
  assign mesh_router_2_5_to_mesh_router_2_6_rsp = mesh_router_2_5_rsp_out[4];
  assign mesh_router_2_5_to_mesh_router_3_5_rsp = mesh_router_2_5_rsp_out[5];

  assign mesh_router_2_5_to_int_core_master_ni_2_5_req = mesh_router_2_5_req_out[0];
  assign mesh_router_2_5_to_int_core_slave_ni_2_5_req = mesh_router_2_5_req_out[1];
  assign mesh_router_2_5_to_mesh_router_1_5_req = mesh_router_2_5_req_out[2];
  assign mesh_router_2_5_to_mesh_router_2_4_req = mesh_router_2_5_req_out[3];
  assign mesh_router_2_5_to_mesh_router_2_6_req = mesh_router_2_5_req_out[4];
  assign mesh_router_2_5_to_mesh_router_3_5_req = mesh_router_2_5_req_out[5];

  assign mesh_router_2_5_rsp_in[0] = int_core_master_ni_2_5_to_mesh_router_2_5_rsp;
  assign mesh_router_2_5_rsp_in[1] = int_core_slave_ni_2_5_to_mesh_router_2_5_rsp;
  assign mesh_router_2_5_rsp_in[2] = mesh_router_1_5_to_mesh_router_2_5_rsp;
  assign mesh_router_2_5_rsp_in[3] = mesh_router_2_4_to_mesh_router_2_5_rsp;
  assign mesh_router_2_5_rsp_in[4] = mesh_router_2_6_to_mesh_router_2_5_rsp;
  assign mesh_router_2_5_rsp_in[5] = mesh_router_3_5_to_mesh_router_2_5_rsp;


  floo_axi_router #(
      .AxiCfg(AxiCfg),
      .RouteAlgo(IdTable),
      .NumRoutes(6),
      .NumInputs(6),
      .NumOutputs(6),
      .InFifoDepth(2),
      .OutFifoDepth(2),
      .id_t(id_t),
      .hdr_t(hdr_t),
      .NumAddrRules(18),
      .addr_rule_t(mesh_router_2_5_map_rule_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) mesh_router_2_5 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('0),
      .id_route_map_i(MeshRouter25Map),
      .floo_req_i(mesh_router_2_5_req_in),
      .floo_rsp_o(mesh_router_2_5_rsp_out),
      .floo_req_o(mesh_router_2_5_req_out),
      .floo_rsp_i(mesh_router_2_5_rsp_in)
  );

  localparam int unsigned MeshRouter26MapNumRules = 18;

  typedef struct packed {
    id_t idx;
    id_t start_addr;
    id_t end_addr;
  } mesh_router_2_6_map_rule_t;

  localparam mesh_router_2_6_map_rule_t [MeshRouter26MapNumRules-1:0] MeshRouter26Map = '{
      '{idx: 2, start_addr: 0, end_addr: 20},  // cpu_master_ni
      '{idx: 2, start_addr: 36, end_addr: 66},  // llc_slave_ni
      '{idx: 2, start_addr: 90, end_addr: 92},  // sp_slave_ni
      '{idx: 3, start_addr: 20, end_addr: 26},  // int_core_master_ni_2_0
      '{idx: 3, start_addr: 28, end_addr: 34},  // int_core_master_ni_3_0
      '{idx: 3, start_addr: 66, end_addr: 72},  // int_core_slave_ni_2_0
      '{idx: 3, start_addr: 74, end_addr: 80},  // int_core_slave_ni_3_0
      '{idx: 3, start_addr: 82, end_addr: 88},  // fp_core_slave_ni_0_0
      '{idx: 0, start_addr: 26, end_addr: 27},  // int_core_master_ni_2_6
      '{idx: 4, start_addr: 27, end_addr: 28},  // int_core_master_ni_2_7
      '{idx: 4, start_addr: 35, end_addr: 36},  // int_core_master_ni_3_7
      '{idx: 4, start_addr: 73, end_addr: 74},  // int_core_slave_ni_2_7
      '{idx: 4, start_addr: 81, end_addr: 82},  // int_core_slave_ni_3_7
      '{idx: 4, start_addr: 89, end_addr: 90},  // fp_core_slave_ni_0_7
      '{idx: 5, start_addr: 34, end_addr: 35},  // int_core_master_ni_3_6
      '{idx: 5, start_addr: 80, end_addr: 81},  // int_core_slave_ni_3_6
      '{idx: 5, start_addr: 88, end_addr: 89},  // fp_core_slave_ni_0_6
      '{idx: 1, start_addr: 72, end_addr: 73}  // int_core_slave_ni_2_6

  };


  floo_req_t [5:0] mesh_router_2_6_req_in;
  floo_rsp_t [5:0] mesh_router_2_6_rsp_out;
  floo_req_t [5:0] mesh_router_2_6_req_out;
  floo_rsp_t [5:0] mesh_router_2_6_rsp_in;

  assign mesh_router_2_6_req_in[0] = int_core_master_ni_2_6_to_mesh_router_2_6_req;
  assign mesh_router_2_6_req_in[1] = int_core_slave_ni_2_6_to_mesh_router_2_6_req;
  assign mesh_router_2_6_req_in[2] = mesh_router_1_6_to_mesh_router_2_6_req;
  assign mesh_router_2_6_req_in[3] = mesh_router_2_5_to_mesh_router_2_6_req;
  assign mesh_router_2_6_req_in[4] = mesh_router_2_7_to_mesh_router_2_6_req;
  assign mesh_router_2_6_req_in[5] = mesh_router_3_6_to_mesh_router_2_6_req;

  assign mesh_router_2_6_to_int_core_master_ni_2_6_rsp = mesh_router_2_6_rsp_out[0];
  assign mesh_router_2_6_to_int_core_slave_ni_2_6_rsp = mesh_router_2_6_rsp_out[1];
  assign mesh_router_2_6_to_mesh_router_1_6_rsp = mesh_router_2_6_rsp_out[2];
  assign mesh_router_2_6_to_mesh_router_2_5_rsp = mesh_router_2_6_rsp_out[3];
  assign mesh_router_2_6_to_mesh_router_2_7_rsp = mesh_router_2_6_rsp_out[4];
  assign mesh_router_2_6_to_mesh_router_3_6_rsp = mesh_router_2_6_rsp_out[5];

  assign mesh_router_2_6_to_int_core_master_ni_2_6_req = mesh_router_2_6_req_out[0];
  assign mesh_router_2_6_to_int_core_slave_ni_2_6_req = mesh_router_2_6_req_out[1];
  assign mesh_router_2_6_to_mesh_router_1_6_req = mesh_router_2_6_req_out[2];
  assign mesh_router_2_6_to_mesh_router_2_5_req = mesh_router_2_6_req_out[3];
  assign mesh_router_2_6_to_mesh_router_2_7_req = mesh_router_2_6_req_out[4];
  assign mesh_router_2_6_to_mesh_router_3_6_req = mesh_router_2_6_req_out[5];

  assign mesh_router_2_6_rsp_in[0] = int_core_master_ni_2_6_to_mesh_router_2_6_rsp;
  assign mesh_router_2_6_rsp_in[1] = int_core_slave_ni_2_6_to_mesh_router_2_6_rsp;
  assign mesh_router_2_6_rsp_in[2] = mesh_router_1_6_to_mesh_router_2_6_rsp;
  assign mesh_router_2_6_rsp_in[3] = mesh_router_2_5_to_mesh_router_2_6_rsp;
  assign mesh_router_2_6_rsp_in[4] = mesh_router_2_7_to_mesh_router_2_6_rsp;
  assign mesh_router_2_6_rsp_in[5] = mesh_router_3_6_to_mesh_router_2_6_rsp;


  floo_axi_router #(
      .AxiCfg(AxiCfg),
      .RouteAlgo(IdTable),
      .NumRoutes(6),
      .NumInputs(6),
      .NumOutputs(6),
      .InFifoDepth(2),
      .OutFifoDepth(2),
      .id_t(id_t),
      .hdr_t(hdr_t),
      .NumAddrRules(18),
      .addr_rule_t(mesh_router_2_6_map_rule_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) mesh_router_2_6 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('0),
      .id_route_map_i(MeshRouter26Map),
      .floo_req_i(mesh_router_2_6_req_in),
      .floo_rsp_o(mesh_router_2_6_rsp_out),
      .floo_req_o(mesh_router_2_6_req_out),
      .floo_rsp_i(mesh_router_2_6_rsp_in)
  );

  localparam int unsigned MeshRouter27MapNumRules = 13;

  typedef struct packed {
    id_t idx;
    id_t start_addr;
    id_t end_addr;
  } mesh_router_2_7_map_rule_t;

  localparam mesh_router_2_7_map_rule_t [MeshRouter27MapNumRules-1:0] MeshRouter27Map = '{
      '{idx: 2, start_addr: 0, end_addr: 20},  // cpu_master_ni
      '{idx: 2, start_addr: 36, end_addr: 66},  // llc_slave_ni
      '{idx: 2, start_addr: 90, end_addr: 92},  // sp_slave_ni
      '{idx: 3, start_addr: 20, end_addr: 27},  // int_core_master_ni_2_0
      '{idx: 3, start_addr: 28, end_addr: 35},  // int_core_master_ni_3_0
      '{idx: 3, start_addr: 66, end_addr: 73},  // int_core_slave_ni_2_0
      '{idx: 3, start_addr: 74, end_addr: 81},  // int_core_slave_ni_3_0
      '{idx: 3, start_addr: 82, end_addr: 89},  // fp_core_slave_ni_0_0
      '{idx: 0, start_addr: 27, end_addr: 28},  // int_core_master_ni_2_7
      '{idx: 4, start_addr: 35, end_addr: 36},  // int_core_master_ni_3_7
      '{idx: 4, start_addr: 81, end_addr: 82},  // int_core_slave_ni_3_7
      '{idx: 4, start_addr: 89, end_addr: 90},  // fp_core_slave_ni_0_7
      '{idx: 1, start_addr: 73, end_addr: 74}  // int_core_slave_ni_2_7

  };


  floo_req_t [4:0] mesh_router_2_7_req_in;
  floo_rsp_t [4:0] mesh_router_2_7_rsp_out;
  floo_req_t [4:0] mesh_router_2_7_req_out;
  floo_rsp_t [4:0] mesh_router_2_7_rsp_in;

  assign mesh_router_2_7_req_in[0] = int_core_master_ni_2_7_to_mesh_router_2_7_req;
  assign mesh_router_2_7_req_in[1] = int_core_slave_ni_2_7_to_mesh_router_2_7_req;
  assign mesh_router_2_7_req_in[2] = mesh_router_1_7_to_mesh_router_2_7_req;
  assign mesh_router_2_7_req_in[3] = mesh_router_2_6_to_mesh_router_2_7_req;
  assign mesh_router_2_7_req_in[4] = mesh_router_3_7_to_mesh_router_2_7_req;

  assign mesh_router_2_7_to_int_core_master_ni_2_7_rsp = mesh_router_2_7_rsp_out[0];
  assign mesh_router_2_7_to_int_core_slave_ni_2_7_rsp = mesh_router_2_7_rsp_out[1];
  assign mesh_router_2_7_to_mesh_router_1_7_rsp = mesh_router_2_7_rsp_out[2];
  assign mesh_router_2_7_to_mesh_router_2_6_rsp = mesh_router_2_7_rsp_out[3];
  assign mesh_router_2_7_to_mesh_router_3_7_rsp = mesh_router_2_7_rsp_out[4];

  assign mesh_router_2_7_to_int_core_master_ni_2_7_req = mesh_router_2_7_req_out[0];
  assign mesh_router_2_7_to_int_core_slave_ni_2_7_req = mesh_router_2_7_req_out[1];
  assign mesh_router_2_7_to_mesh_router_1_7_req = mesh_router_2_7_req_out[2];
  assign mesh_router_2_7_to_mesh_router_2_6_req = mesh_router_2_7_req_out[3];
  assign mesh_router_2_7_to_mesh_router_3_7_req = mesh_router_2_7_req_out[4];

  assign mesh_router_2_7_rsp_in[0] = int_core_master_ni_2_7_to_mesh_router_2_7_rsp;
  assign mesh_router_2_7_rsp_in[1] = int_core_slave_ni_2_7_to_mesh_router_2_7_rsp;
  assign mesh_router_2_7_rsp_in[2] = mesh_router_1_7_to_mesh_router_2_7_rsp;
  assign mesh_router_2_7_rsp_in[3] = mesh_router_2_6_to_mesh_router_2_7_rsp;
  assign mesh_router_2_7_rsp_in[4] = mesh_router_3_7_to_mesh_router_2_7_rsp;


  floo_axi_router #(
      .AxiCfg(AxiCfg),
      .RouteAlgo(IdTable),
      .NumRoutes(5),
      .NumInputs(5),
      .NumOutputs(5),
      .InFifoDepth(2),
      .OutFifoDepth(2),
      .id_t(id_t),
      .hdr_t(hdr_t),
      .NumAddrRules(13),
      .addr_rule_t(mesh_router_2_7_map_rule_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) mesh_router_2_7 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('0),
      .id_route_map_i(MeshRouter27Map),
      .floo_req_i(mesh_router_2_7_req_in),
      .floo_rsp_o(mesh_router_2_7_rsp_out),
      .floo_req_o(mesh_router_2_7_req_out),
      .floo_rsp_i(mesh_router_2_7_rsp_in)
  );

  localparam int unsigned MeshRouter30MapNumRules = 9;

  typedef struct packed {
    id_t idx;
    id_t start_addr;
    id_t end_addr;
  } mesh_router_3_0_map_rule_t;

  localparam mesh_router_3_0_map_rule_t [MeshRouter30MapNumRules-1:0] MeshRouter30Map = '{
      '{idx: 3, start_addr: 0, end_addr: 28},  // cpu_master_ni
      '{idx: 3, start_addr: 36, end_addr: 74},  // llc_slave_ni
      '{idx: 3, start_addr: 90, end_addr: 92},  // sp_slave_ni
      '{idx: 1, start_addr: 28, end_addr: 29},  // int_core_master_ni_3_0
      '{idx: 4, start_addr: 29, end_addr: 36},  // int_core_master_ni_3_1
      '{idx: 4, start_addr: 75, end_addr: 82},  // int_core_slave_ni_3_1
      '{idx: 4, start_addr: 83, end_addr: 90},  // fp_core_slave_ni_0_1
      '{idx: 2, start_addr: 74, end_addr: 75},  // int_core_slave_ni_3_0
      '{idx: 0, start_addr: 82, end_addr: 83}  // fp_core_slave_ni_0_0

  };


  floo_req_t [4:0] mesh_router_3_0_req_in;
  floo_rsp_t [4:0] mesh_router_3_0_rsp_out;
  floo_req_t [4:0] mesh_router_3_0_req_out;
  floo_rsp_t [4:0] mesh_router_3_0_rsp_in;

  assign mesh_router_3_0_req_in[0] = fp_core_slave_ni_0_0_to_mesh_router_3_0_req;
  assign mesh_router_3_0_req_in[1] = int_core_master_ni_3_0_to_mesh_router_3_0_req;
  assign mesh_router_3_0_req_in[2] = int_core_slave_ni_3_0_to_mesh_router_3_0_req;
  assign mesh_router_3_0_req_in[3] = mesh_router_2_0_to_mesh_router_3_0_req;
  assign mesh_router_3_0_req_in[4] = mesh_router_3_1_to_mesh_router_3_0_req;

  assign mesh_router_3_0_to_fp_core_slave_ni_0_0_rsp = mesh_router_3_0_rsp_out[0];
  assign mesh_router_3_0_to_int_core_master_ni_3_0_rsp = mesh_router_3_0_rsp_out[1];
  assign mesh_router_3_0_to_int_core_slave_ni_3_0_rsp = mesh_router_3_0_rsp_out[2];
  assign mesh_router_3_0_to_mesh_router_2_0_rsp = mesh_router_3_0_rsp_out[3];
  assign mesh_router_3_0_to_mesh_router_3_1_rsp = mesh_router_3_0_rsp_out[4];

  assign mesh_router_3_0_to_fp_core_slave_ni_0_0_req = mesh_router_3_0_req_out[0];
  assign mesh_router_3_0_to_int_core_master_ni_3_0_req = mesh_router_3_0_req_out[1];
  assign mesh_router_3_0_to_int_core_slave_ni_3_0_req = mesh_router_3_0_req_out[2];
  assign mesh_router_3_0_to_mesh_router_2_0_req = mesh_router_3_0_req_out[3];
  assign mesh_router_3_0_to_mesh_router_3_1_req = mesh_router_3_0_req_out[4];

  assign mesh_router_3_0_rsp_in[0] = fp_core_slave_ni_0_0_to_mesh_router_3_0_rsp;
  assign mesh_router_3_0_rsp_in[1] = int_core_master_ni_3_0_to_mesh_router_3_0_rsp;
  assign mesh_router_3_0_rsp_in[2] = int_core_slave_ni_3_0_to_mesh_router_3_0_rsp;
  assign mesh_router_3_0_rsp_in[3] = mesh_router_2_0_to_mesh_router_3_0_rsp;
  assign mesh_router_3_0_rsp_in[4] = mesh_router_3_1_to_mesh_router_3_0_rsp;


  floo_axi_router #(
      .AxiCfg(AxiCfg),
      .RouteAlgo(IdTable),
      .NumRoutes(5),
      .NumInputs(5),
      .NumOutputs(5),
      .InFifoDepth(2),
      .OutFifoDepth(2),
      .id_t(id_t),
      .hdr_t(hdr_t),
      .NumAddrRules(9),
      .addr_rule_t(mesh_router_3_0_map_rule_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) mesh_router_3_0 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('0),
      .id_route_map_i(MeshRouter30Map),
      .floo_req_i(mesh_router_3_0_req_in),
      .floo_rsp_o(mesh_router_3_0_rsp_out),
      .floo_req_o(mesh_router_3_0_req_out),
      .floo_rsp_i(mesh_router_3_0_rsp_in)
  );

  localparam int unsigned MeshRouter31MapNumRules = 12;

  typedef struct packed {
    id_t idx;
    id_t start_addr;
    id_t end_addr;
  } mesh_router_3_1_map_rule_t;

  localparam mesh_router_3_1_map_rule_t [MeshRouter31MapNumRules-1:0] MeshRouter31Map = '{
      '{idx: 3, start_addr: 0, end_addr: 28},  // cpu_master_ni
      '{idx: 3, start_addr: 36, end_addr: 74},  // llc_slave_ni
      '{idx: 3, start_addr: 90, end_addr: 92},  // sp_slave_ni
      '{idx: 4, start_addr: 28, end_addr: 29},  // int_core_master_ni_3_0
      '{idx: 4, start_addr: 74, end_addr: 75},  // int_core_slave_ni_3_0
      '{idx: 4, start_addr: 82, end_addr: 83},  // fp_core_slave_ni_0_0
      '{idx: 1, start_addr: 29, end_addr: 30},  // int_core_master_ni_3_1
      '{idx: 5, start_addr: 30, end_addr: 36},  // int_core_master_ni_3_2
      '{idx: 5, start_addr: 76, end_addr: 82},  // int_core_slave_ni_3_2
      '{idx: 5, start_addr: 84, end_addr: 90},  // fp_core_slave_ni_0_2
      '{idx: 2, start_addr: 75, end_addr: 76},  // int_core_slave_ni_3_1
      '{idx: 0, start_addr: 83, end_addr: 84}  // fp_core_slave_ni_0_1

  };


  floo_req_t [5:0] mesh_router_3_1_req_in;
  floo_rsp_t [5:0] mesh_router_3_1_rsp_out;
  floo_req_t [5:0] mesh_router_3_1_req_out;
  floo_rsp_t [5:0] mesh_router_3_1_rsp_in;

  assign mesh_router_3_1_req_in[0] = fp_core_slave_ni_0_1_to_mesh_router_3_1_req;
  assign mesh_router_3_1_req_in[1] = int_core_master_ni_3_1_to_mesh_router_3_1_req;
  assign mesh_router_3_1_req_in[2] = int_core_slave_ni_3_1_to_mesh_router_3_1_req;
  assign mesh_router_3_1_req_in[3] = mesh_router_2_1_to_mesh_router_3_1_req;
  assign mesh_router_3_1_req_in[4] = mesh_router_3_0_to_mesh_router_3_1_req;
  assign mesh_router_3_1_req_in[5] = mesh_router_3_2_to_mesh_router_3_1_req;

  assign mesh_router_3_1_to_fp_core_slave_ni_0_1_rsp = mesh_router_3_1_rsp_out[0];
  assign mesh_router_3_1_to_int_core_master_ni_3_1_rsp = mesh_router_3_1_rsp_out[1];
  assign mesh_router_3_1_to_int_core_slave_ni_3_1_rsp = mesh_router_3_1_rsp_out[2];
  assign mesh_router_3_1_to_mesh_router_2_1_rsp = mesh_router_3_1_rsp_out[3];
  assign mesh_router_3_1_to_mesh_router_3_0_rsp = mesh_router_3_1_rsp_out[4];
  assign mesh_router_3_1_to_mesh_router_3_2_rsp = mesh_router_3_1_rsp_out[5];

  assign mesh_router_3_1_to_fp_core_slave_ni_0_1_req = mesh_router_3_1_req_out[0];
  assign mesh_router_3_1_to_int_core_master_ni_3_1_req = mesh_router_3_1_req_out[1];
  assign mesh_router_3_1_to_int_core_slave_ni_3_1_req = mesh_router_3_1_req_out[2];
  assign mesh_router_3_1_to_mesh_router_2_1_req = mesh_router_3_1_req_out[3];
  assign mesh_router_3_1_to_mesh_router_3_0_req = mesh_router_3_1_req_out[4];
  assign mesh_router_3_1_to_mesh_router_3_2_req = mesh_router_3_1_req_out[5];

  assign mesh_router_3_1_rsp_in[0] = fp_core_slave_ni_0_1_to_mesh_router_3_1_rsp;
  assign mesh_router_3_1_rsp_in[1] = int_core_master_ni_3_1_to_mesh_router_3_1_rsp;
  assign mesh_router_3_1_rsp_in[2] = int_core_slave_ni_3_1_to_mesh_router_3_1_rsp;
  assign mesh_router_3_1_rsp_in[3] = mesh_router_2_1_to_mesh_router_3_1_rsp;
  assign mesh_router_3_1_rsp_in[4] = mesh_router_3_0_to_mesh_router_3_1_rsp;
  assign mesh_router_3_1_rsp_in[5] = mesh_router_3_2_to_mesh_router_3_1_rsp;


  floo_axi_router #(
      .AxiCfg(AxiCfg),
      .RouteAlgo(IdTable),
      .NumRoutes(6),
      .NumInputs(6),
      .NumOutputs(6),
      .InFifoDepth(2),
      .OutFifoDepth(2),
      .id_t(id_t),
      .hdr_t(hdr_t),
      .NumAddrRules(12),
      .addr_rule_t(mesh_router_3_1_map_rule_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) mesh_router_3_1 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('0),
      .id_route_map_i(MeshRouter31Map),
      .floo_req_i(mesh_router_3_1_req_in),
      .floo_rsp_o(mesh_router_3_1_rsp_out),
      .floo_req_o(mesh_router_3_1_req_out),
      .floo_rsp_i(mesh_router_3_1_rsp_in)
  );

  localparam int unsigned MeshRouter32MapNumRules = 12;

  typedef struct packed {
    id_t idx;
    id_t start_addr;
    id_t end_addr;
  } mesh_router_3_2_map_rule_t;

  localparam mesh_router_3_2_map_rule_t [MeshRouter32MapNumRules-1:0] MeshRouter32Map = '{
      '{idx: 3, start_addr: 0, end_addr: 28},  // cpu_master_ni
      '{idx: 3, start_addr: 36, end_addr: 74},  // llc_slave_ni
      '{idx: 3, start_addr: 90, end_addr: 92},  // sp_slave_ni
      '{idx: 4, start_addr: 28, end_addr: 30},  // int_core_master_ni_3_0
      '{idx: 4, start_addr: 74, end_addr: 76},  // int_core_slave_ni_3_0
      '{idx: 4, start_addr: 82, end_addr: 84},  // fp_core_slave_ni_0_0
      '{idx: 1, start_addr: 30, end_addr: 31},  // int_core_master_ni_3_2
      '{idx: 5, start_addr: 31, end_addr: 36},  // int_core_master_ni_3_3
      '{idx: 5, start_addr: 77, end_addr: 82},  // int_core_slave_ni_3_3
      '{idx: 5, start_addr: 85, end_addr: 90},  // fp_core_slave_ni_0_3
      '{idx: 2, start_addr: 76, end_addr: 77},  // int_core_slave_ni_3_2
      '{idx: 0, start_addr: 84, end_addr: 85}  // fp_core_slave_ni_0_2

  };


  floo_req_t [5:0] mesh_router_3_2_req_in;
  floo_rsp_t [5:0] mesh_router_3_2_rsp_out;
  floo_req_t [5:0] mesh_router_3_2_req_out;
  floo_rsp_t [5:0] mesh_router_3_2_rsp_in;

  assign mesh_router_3_2_req_in[0] = fp_core_slave_ni_0_2_to_mesh_router_3_2_req;
  assign mesh_router_3_2_req_in[1] = int_core_master_ni_3_2_to_mesh_router_3_2_req;
  assign mesh_router_3_2_req_in[2] = int_core_slave_ni_3_2_to_mesh_router_3_2_req;
  assign mesh_router_3_2_req_in[3] = mesh_router_2_2_to_mesh_router_3_2_req;
  assign mesh_router_3_2_req_in[4] = mesh_router_3_1_to_mesh_router_3_2_req;
  assign mesh_router_3_2_req_in[5] = mesh_router_3_3_to_mesh_router_3_2_req;

  assign mesh_router_3_2_to_fp_core_slave_ni_0_2_rsp = mesh_router_3_2_rsp_out[0];
  assign mesh_router_3_2_to_int_core_master_ni_3_2_rsp = mesh_router_3_2_rsp_out[1];
  assign mesh_router_3_2_to_int_core_slave_ni_3_2_rsp = mesh_router_3_2_rsp_out[2];
  assign mesh_router_3_2_to_mesh_router_2_2_rsp = mesh_router_3_2_rsp_out[3];
  assign mesh_router_3_2_to_mesh_router_3_1_rsp = mesh_router_3_2_rsp_out[4];
  assign mesh_router_3_2_to_mesh_router_3_3_rsp = mesh_router_3_2_rsp_out[5];

  assign mesh_router_3_2_to_fp_core_slave_ni_0_2_req = mesh_router_3_2_req_out[0];
  assign mesh_router_3_2_to_int_core_master_ni_3_2_req = mesh_router_3_2_req_out[1];
  assign mesh_router_3_2_to_int_core_slave_ni_3_2_req = mesh_router_3_2_req_out[2];
  assign mesh_router_3_2_to_mesh_router_2_2_req = mesh_router_3_2_req_out[3];
  assign mesh_router_3_2_to_mesh_router_3_1_req = mesh_router_3_2_req_out[4];
  assign mesh_router_3_2_to_mesh_router_3_3_req = mesh_router_3_2_req_out[5];

  assign mesh_router_3_2_rsp_in[0] = fp_core_slave_ni_0_2_to_mesh_router_3_2_rsp;
  assign mesh_router_3_2_rsp_in[1] = int_core_master_ni_3_2_to_mesh_router_3_2_rsp;
  assign mesh_router_3_2_rsp_in[2] = int_core_slave_ni_3_2_to_mesh_router_3_2_rsp;
  assign mesh_router_3_2_rsp_in[3] = mesh_router_2_2_to_mesh_router_3_2_rsp;
  assign mesh_router_3_2_rsp_in[4] = mesh_router_3_1_to_mesh_router_3_2_rsp;
  assign mesh_router_3_2_rsp_in[5] = mesh_router_3_3_to_mesh_router_3_2_rsp;


  floo_axi_router #(
      .AxiCfg(AxiCfg),
      .RouteAlgo(IdTable),
      .NumRoutes(6),
      .NumInputs(6),
      .NumOutputs(6),
      .InFifoDepth(2),
      .OutFifoDepth(2),
      .id_t(id_t),
      .hdr_t(hdr_t),
      .NumAddrRules(12),
      .addr_rule_t(mesh_router_3_2_map_rule_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) mesh_router_3_2 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('0),
      .id_route_map_i(MeshRouter32Map),
      .floo_req_i(mesh_router_3_2_req_in),
      .floo_rsp_o(mesh_router_3_2_rsp_out),
      .floo_req_o(mesh_router_3_2_req_out),
      .floo_rsp_i(mesh_router_3_2_rsp_in)
  );

  localparam int unsigned MeshRouter33MapNumRules = 12;

  typedef struct packed {
    id_t idx;
    id_t start_addr;
    id_t end_addr;
  } mesh_router_3_3_map_rule_t;

  localparam mesh_router_3_3_map_rule_t [MeshRouter33MapNumRules-1:0] MeshRouter33Map = '{
      '{idx: 3, start_addr: 0, end_addr: 28},  // cpu_master_ni
      '{idx: 3, start_addr: 36, end_addr: 74},  // llc_slave_ni
      '{idx: 3, start_addr: 90, end_addr: 92},  // sp_slave_ni
      '{idx: 4, start_addr: 28, end_addr: 31},  // int_core_master_ni_3_0
      '{idx: 4, start_addr: 74, end_addr: 77},  // int_core_slave_ni_3_0
      '{idx: 4, start_addr: 82, end_addr: 85},  // fp_core_slave_ni_0_0
      '{idx: 1, start_addr: 31, end_addr: 32},  // int_core_master_ni_3_3
      '{idx: 5, start_addr: 32, end_addr: 36},  // int_core_master_ni_3_4
      '{idx: 5, start_addr: 78, end_addr: 82},  // int_core_slave_ni_3_4
      '{idx: 5, start_addr: 86, end_addr: 90},  // fp_core_slave_ni_0_4
      '{idx: 2, start_addr: 77, end_addr: 78},  // int_core_slave_ni_3_3
      '{idx: 0, start_addr: 85, end_addr: 86}  // fp_core_slave_ni_0_3

  };


  floo_req_t [5:0] mesh_router_3_3_req_in;
  floo_rsp_t [5:0] mesh_router_3_3_rsp_out;
  floo_req_t [5:0] mesh_router_3_3_req_out;
  floo_rsp_t [5:0] mesh_router_3_3_rsp_in;

  assign mesh_router_3_3_req_in[0] = fp_core_slave_ni_0_3_to_mesh_router_3_3_req;
  assign mesh_router_3_3_req_in[1] = int_core_master_ni_3_3_to_mesh_router_3_3_req;
  assign mesh_router_3_3_req_in[2] = int_core_slave_ni_3_3_to_mesh_router_3_3_req;
  assign mesh_router_3_3_req_in[3] = mesh_router_2_3_to_mesh_router_3_3_req;
  assign mesh_router_3_3_req_in[4] = mesh_router_3_2_to_mesh_router_3_3_req;
  assign mesh_router_3_3_req_in[5] = mesh_router_3_4_to_mesh_router_3_3_req;

  assign mesh_router_3_3_to_fp_core_slave_ni_0_3_rsp = mesh_router_3_3_rsp_out[0];
  assign mesh_router_3_3_to_int_core_master_ni_3_3_rsp = mesh_router_3_3_rsp_out[1];
  assign mesh_router_3_3_to_int_core_slave_ni_3_3_rsp = mesh_router_3_3_rsp_out[2];
  assign mesh_router_3_3_to_mesh_router_2_3_rsp = mesh_router_3_3_rsp_out[3];
  assign mesh_router_3_3_to_mesh_router_3_2_rsp = mesh_router_3_3_rsp_out[4];
  assign mesh_router_3_3_to_mesh_router_3_4_rsp = mesh_router_3_3_rsp_out[5];

  assign mesh_router_3_3_to_fp_core_slave_ni_0_3_req = mesh_router_3_3_req_out[0];
  assign mesh_router_3_3_to_int_core_master_ni_3_3_req = mesh_router_3_3_req_out[1];
  assign mesh_router_3_3_to_int_core_slave_ni_3_3_req = mesh_router_3_3_req_out[2];
  assign mesh_router_3_3_to_mesh_router_2_3_req = mesh_router_3_3_req_out[3];
  assign mesh_router_3_3_to_mesh_router_3_2_req = mesh_router_3_3_req_out[4];
  assign mesh_router_3_3_to_mesh_router_3_4_req = mesh_router_3_3_req_out[5];

  assign mesh_router_3_3_rsp_in[0] = fp_core_slave_ni_0_3_to_mesh_router_3_3_rsp;
  assign mesh_router_3_3_rsp_in[1] = int_core_master_ni_3_3_to_mesh_router_3_3_rsp;
  assign mesh_router_3_3_rsp_in[2] = int_core_slave_ni_3_3_to_mesh_router_3_3_rsp;
  assign mesh_router_3_3_rsp_in[3] = mesh_router_2_3_to_mesh_router_3_3_rsp;
  assign mesh_router_3_3_rsp_in[4] = mesh_router_3_2_to_mesh_router_3_3_rsp;
  assign mesh_router_3_3_rsp_in[5] = mesh_router_3_4_to_mesh_router_3_3_rsp;


  floo_axi_router #(
      .AxiCfg(AxiCfg),
      .RouteAlgo(IdTable),
      .NumRoutes(6),
      .NumInputs(6),
      .NumOutputs(6),
      .InFifoDepth(2),
      .OutFifoDepth(2),
      .id_t(id_t),
      .hdr_t(hdr_t),
      .NumAddrRules(12),
      .addr_rule_t(mesh_router_3_3_map_rule_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) mesh_router_3_3 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('0),
      .id_route_map_i(MeshRouter33Map),
      .floo_req_i(mesh_router_3_3_req_in),
      .floo_rsp_o(mesh_router_3_3_rsp_out),
      .floo_req_o(mesh_router_3_3_req_out),
      .floo_rsp_i(mesh_router_3_3_rsp_in)
  );

  localparam int unsigned MeshRouter34MapNumRules = 12;

  typedef struct packed {
    id_t idx;
    id_t start_addr;
    id_t end_addr;
  } mesh_router_3_4_map_rule_t;

  localparam mesh_router_3_4_map_rule_t [MeshRouter34MapNumRules-1:0] MeshRouter34Map = '{
      '{idx: 3, start_addr: 0, end_addr: 28},  // cpu_master_ni
      '{idx: 3, start_addr: 36, end_addr: 74},  // llc_slave_ni
      '{idx: 3, start_addr: 90, end_addr: 92},  // sp_slave_ni
      '{idx: 4, start_addr: 28, end_addr: 32},  // int_core_master_ni_3_0
      '{idx: 4, start_addr: 74, end_addr: 78},  // int_core_slave_ni_3_0
      '{idx: 4, start_addr: 82, end_addr: 86},  // fp_core_slave_ni_0_0
      '{idx: 1, start_addr: 32, end_addr: 33},  // int_core_master_ni_3_4
      '{idx: 5, start_addr: 33, end_addr: 36},  // int_core_master_ni_3_5
      '{idx: 5, start_addr: 79, end_addr: 82},  // int_core_slave_ni_3_5
      '{idx: 5, start_addr: 87, end_addr: 90},  // fp_core_slave_ni_0_5
      '{idx: 2, start_addr: 78, end_addr: 79},  // int_core_slave_ni_3_4
      '{idx: 0, start_addr: 86, end_addr: 87}  // fp_core_slave_ni_0_4

  };


  floo_req_t [5:0] mesh_router_3_4_req_in;
  floo_rsp_t [5:0] mesh_router_3_4_rsp_out;
  floo_req_t [5:0] mesh_router_3_4_req_out;
  floo_rsp_t [5:0] mesh_router_3_4_rsp_in;

  assign mesh_router_3_4_req_in[0] = fp_core_slave_ni_0_4_to_mesh_router_3_4_req;
  assign mesh_router_3_4_req_in[1] = int_core_master_ni_3_4_to_mesh_router_3_4_req;
  assign mesh_router_3_4_req_in[2] = int_core_slave_ni_3_4_to_mesh_router_3_4_req;
  assign mesh_router_3_4_req_in[3] = mesh_router_2_4_to_mesh_router_3_4_req;
  assign mesh_router_3_4_req_in[4] = mesh_router_3_3_to_mesh_router_3_4_req;
  assign mesh_router_3_4_req_in[5] = mesh_router_3_5_to_mesh_router_3_4_req;

  assign mesh_router_3_4_to_fp_core_slave_ni_0_4_rsp = mesh_router_3_4_rsp_out[0];
  assign mesh_router_3_4_to_int_core_master_ni_3_4_rsp = mesh_router_3_4_rsp_out[1];
  assign mesh_router_3_4_to_int_core_slave_ni_3_4_rsp = mesh_router_3_4_rsp_out[2];
  assign mesh_router_3_4_to_mesh_router_2_4_rsp = mesh_router_3_4_rsp_out[3];
  assign mesh_router_3_4_to_mesh_router_3_3_rsp = mesh_router_3_4_rsp_out[4];
  assign mesh_router_3_4_to_mesh_router_3_5_rsp = mesh_router_3_4_rsp_out[5];

  assign mesh_router_3_4_to_fp_core_slave_ni_0_4_req = mesh_router_3_4_req_out[0];
  assign mesh_router_3_4_to_int_core_master_ni_3_4_req = mesh_router_3_4_req_out[1];
  assign mesh_router_3_4_to_int_core_slave_ni_3_4_req = mesh_router_3_4_req_out[2];
  assign mesh_router_3_4_to_mesh_router_2_4_req = mesh_router_3_4_req_out[3];
  assign mesh_router_3_4_to_mesh_router_3_3_req = mesh_router_3_4_req_out[4];
  assign mesh_router_3_4_to_mesh_router_3_5_req = mesh_router_3_4_req_out[5];

  assign mesh_router_3_4_rsp_in[0] = fp_core_slave_ni_0_4_to_mesh_router_3_4_rsp;
  assign mesh_router_3_4_rsp_in[1] = int_core_master_ni_3_4_to_mesh_router_3_4_rsp;
  assign mesh_router_3_4_rsp_in[2] = int_core_slave_ni_3_4_to_mesh_router_3_4_rsp;
  assign mesh_router_3_4_rsp_in[3] = mesh_router_2_4_to_mesh_router_3_4_rsp;
  assign mesh_router_3_4_rsp_in[4] = mesh_router_3_3_to_mesh_router_3_4_rsp;
  assign mesh_router_3_4_rsp_in[5] = mesh_router_3_5_to_mesh_router_3_4_rsp;


  floo_axi_router #(
      .AxiCfg(AxiCfg),
      .RouteAlgo(IdTable),
      .NumRoutes(6),
      .NumInputs(6),
      .NumOutputs(6),
      .InFifoDepth(2),
      .OutFifoDepth(2),
      .id_t(id_t),
      .hdr_t(hdr_t),
      .NumAddrRules(12),
      .addr_rule_t(mesh_router_3_4_map_rule_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) mesh_router_3_4 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('0),
      .id_route_map_i(MeshRouter34Map),
      .floo_req_i(mesh_router_3_4_req_in),
      .floo_rsp_o(mesh_router_3_4_rsp_out),
      .floo_req_o(mesh_router_3_4_req_out),
      .floo_rsp_i(mesh_router_3_4_rsp_in)
  );

  localparam int unsigned MeshRouter35MapNumRules = 12;

  typedef struct packed {
    id_t idx;
    id_t start_addr;
    id_t end_addr;
  } mesh_router_3_5_map_rule_t;

  localparam mesh_router_3_5_map_rule_t [MeshRouter35MapNumRules-1:0] MeshRouter35Map = '{
      '{idx: 3, start_addr: 0, end_addr: 28},  // cpu_master_ni
      '{idx: 3, start_addr: 36, end_addr: 74},  // llc_slave_ni
      '{idx: 3, start_addr: 90, end_addr: 92},  // sp_slave_ni
      '{idx: 4, start_addr: 28, end_addr: 33},  // int_core_master_ni_3_0
      '{idx: 4, start_addr: 74, end_addr: 79},  // int_core_slave_ni_3_0
      '{idx: 4, start_addr: 82, end_addr: 87},  // fp_core_slave_ni_0_0
      '{idx: 1, start_addr: 33, end_addr: 34},  // int_core_master_ni_3_5
      '{idx: 5, start_addr: 34, end_addr: 36},  // int_core_master_ni_3_6
      '{idx: 5, start_addr: 80, end_addr: 82},  // int_core_slave_ni_3_6
      '{idx: 5, start_addr: 88, end_addr: 90},  // fp_core_slave_ni_0_6
      '{idx: 2, start_addr: 79, end_addr: 80},  // int_core_slave_ni_3_5
      '{idx: 0, start_addr: 87, end_addr: 88}  // fp_core_slave_ni_0_5

  };


  floo_req_t [5:0] mesh_router_3_5_req_in;
  floo_rsp_t [5:0] mesh_router_3_5_rsp_out;
  floo_req_t [5:0] mesh_router_3_5_req_out;
  floo_rsp_t [5:0] mesh_router_3_5_rsp_in;

  assign mesh_router_3_5_req_in[0] = fp_core_slave_ni_0_5_to_mesh_router_3_5_req;
  assign mesh_router_3_5_req_in[1] = int_core_master_ni_3_5_to_mesh_router_3_5_req;
  assign mesh_router_3_5_req_in[2] = int_core_slave_ni_3_5_to_mesh_router_3_5_req;
  assign mesh_router_3_5_req_in[3] = mesh_router_2_5_to_mesh_router_3_5_req;
  assign mesh_router_3_5_req_in[4] = mesh_router_3_4_to_mesh_router_3_5_req;
  assign mesh_router_3_5_req_in[5] = mesh_router_3_6_to_mesh_router_3_5_req;

  assign mesh_router_3_5_to_fp_core_slave_ni_0_5_rsp = mesh_router_3_5_rsp_out[0];
  assign mesh_router_3_5_to_int_core_master_ni_3_5_rsp = mesh_router_3_5_rsp_out[1];
  assign mesh_router_3_5_to_int_core_slave_ni_3_5_rsp = mesh_router_3_5_rsp_out[2];
  assign mesh_router_3_5_to_mesh_router_2_5_rsp = mesh_router_3_5_rsp_out[3];
  assign mesh_router_3_5_to_mesh_router_3_4_rsp = mesh_router_3_5_rsp_out[4];
  assign mesh_router_3_5_to_mesh_router_3_6_rsp = mesh_router_3_5_rsp_out[5];

  assign mesh_router_3_5_to_fp_core_slave_ni_0_5_req = mesh_router_3_5_req_out[0];
  assign mesh_router_3_5_to_int_core_master_ni_3_5_req = mesh_router_3_5_req_out[1];
  assign mesh_router_3_5_to_int_core_slave_ni_3_5_req = mesh_router_3_5_req_out[2];
  assign mesh_router_3_5_to_mesh_router_2_5_req = mesh_router_3_5_req_out[3];
  assign mesh_router_3_5_to_mesh_router_3_4_req = mesh_router_3_5_req_out[4];
  assign mesh_router_3_5_to_mesh_router_3_6_req = mesh_router_3_5_req_out[5];

  assign mesh_router_3_5_rsp_in[0] = fp_core_slave_ni_0_5_to_mesh_router_3_5_rsp;
  assign mesh_router_3_5_rsp_in[1] = int_core_master_ni_3_5_to_mesh_router_3_5_rsp;
  assign mesh_router_3_5_rsp_in[2] = int_core_slave_ni_3_5_to_mesh_router_3_5_rsp;
  assign mesh_router_3_5_rsp_in[3] = mesh_router_2_5_to_mesh_router_3_5_rsp;
  assign mesh_router_3_5_rsp_in[4] = mesh_router_3_4_to_mesh_router_3_5_rsp;
  assign mesh_router_3_5_rsp_in[5] = mesh_router_3_6_to_mesh_router_3_5_rsp;


  floo_axi_router #(
      .AxiCfg(AxiCfg),
      .RouteAlgo(IdTable),
      .NumRoutes(6),
      .NumInputs(6),
      .NumOutputs(6),
      .InFifoDepth(2),
      .OutFifoDepth(2),
      .id_t(id_t),
      .hdr_t(hdr_t),
      .NumAddrRules(12),
      .addr_rule_t(mesh_router_3_5_map_rule_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) mesh_router_3_5 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('0),
      .id_route_map_i(MeshRouter35Map),
      .floo_req_i(mesh_router_3_5_req_in),
      .floo_rsp_o(mesh_router_3_5_rsp_out),
      .floo_req_o(mesh_router_3_5_req_out),
      .floo_rsp_i(mesh_router_3_5_rsp_in)
  );

  localparam int unsigned MeshRouter36MapNumRules = 12;

  typedef struct packed {
    id_t idx;
    id_t start_addr;
    id_t end_addr;
  } mesh_router_3_6_map_rule_t;

  localparam mesh_router_3_6_map_rule_t [MeshRouter36MapNumRules-1:0] MeshRouter36Map = '{
      '{idx: 3, start_addr: 0, end_addr: 28},  // cpu_master_ni
      '{idx: 3, start_addr: 36, end_addr: 74},  // llc_slave_ni
      '{idx: 3, start_addr: 90, end_addr: 92},  // sp_slave_ni
      '{idx: 4, start_addr: 28, end_addr: 34},  // int_core_master_ni_3_0
      '{idx: 4, start_addr: 74, end_addr: 80},  // int_core_slave_ni_3_0
      '{idx: 4, start_addr: 82, end_addr: 88},  // fp_core_slave_ni_0_0
      '{idx: 1, start_addr: 34, end_addr: 35},  // int_core_master_ni_3_6
      '{idx: 5, start_addr: 35, end_addr: 36},  // int_core_master_ni_3_7
      '{idx: 5, start_addr: 81, end_addr: 82},  // int_core_slave_ni_3_7
      '{idx: 5, start_addr: 89, end_addr: 90},  // fp_core_slave_ni_0_7
      '{idx: 2, start_addr: 80, end_addr: 81},  // int_core_slave_ni_3_6
      '{idx: 0, start_addr: 88, end_addr: 89}  // fp_core_slave_ni_0_6

  };


  floo_req_t [5:0] mesh_router_3_6_req_in;
  floo_rsp_t [5:0] mesh_router_3_6_rsp_out;
  floo_req_t [5:0] mesh_router_3_6_req_out;
  floo_rsp_t [5:0] mesh_router_3_6_rsp_in;

  assign mesh_router_3_6_req_in[0] = fp_core_slave_ni_0_6_to_mesh_router_3_6_req;
  assign mesh_router_3_6_req_in[1] = int_core_master_ni_3_6_to_mesh_router_3_6_req;
  assign mesh_router_3_6_req_in[2] = int_core_slave_ni_3_6_to_mesh_router_3_6_req;
  assign mesh_router_3_6_req_in[3] = mesh_router_2_6_to_mesh_router_3_6_req;
  assign mesh_router_3_6_req_in[4] = mesh_router_3_5_to_mesh_router_3_6_req;
  assign mesh_router_3_6_req_in[5] = mesh_router_3_7_to_mesh_router_3_6_req;

  assign mesh_router_3_6_to_fp_core_slave_ni_0_6_rsp = mesh_router_3_6_rsp_out[0];
  assign mesh_router_3_6_to_int_core_master_ni_3_6_rsp = mesh_router_3_6_rsp_out[1];
  assign mesh_router_3_6_to_int_core_slave_ni_3_6_rsp = mesh_router_3_6_rsp_out[2];
  assign mesh_router_3_6_to_mesh_router_2_6_rsp = mesh_router_3_6_rsp_out[3];
  assign mesh_router_3_6_to_mesh_router_3_5_rsp = mesh_router_3_6_rsp_out[4];
  assign mesh_router_3_6_to_mesh_router_3_7_rsp = mesh_router_3_6_rsp_out[5];

  assign mesh_router_3_6_to_fp_core_slave_ni_0_6_req = mesh_router_3_6_req_out[0];
  assign mesh_router_3_6_to_int_core_master_ni_3_6_req = mesh_router_3_6_req_out[1];
  assign mesh_router_3_6_to_int_core_slave_ni_3_6_req = mesh_router_3_6_req_out[2];
  assign mesh_router_3_6_to_mesh_router_2_6_req = mesh_router_3_6_req_out[3];
  assign mesh_router_3_6_to_mesh_router_3_5_req = mesh_router_3_6_req_out[4];
  assign mesh_router_3_6_to_mesh_router_3_7_req = mesh_router_3_6_req_out[5];

  assign mesh_router_3_6_rsp_in[0] = fp_core_slave_ni_0_6_to_mesh_router_3_6_rsp;
  assign mesh_router_3_6_rsp_in[1] = int_core_master_ni_3_6_to_mesh_router_3_6_rsp;
  assign mesh_router_3_6_rsp_in[2] = int_core_slave_ni_3_6_to_mesh_router_3_6_rsp;
  assign mesh_router_3_6_rsp_in[3] = mesh_router_2_6_to_mesh_router_3_6_rsp;
  assign mesh_router_3_6_rsp_in[4] = mesh_router_3_5_to_mesh_router_3_6_rsp;
  assign mesh_router_3_6_rsp_in[5] = mesh_router_3_7_to_mesh_router_3_6_rsp;


  floo_axi_router #(
      .AxiCfg(AxiCfg),
      .RouteAlgo(IdTable),
      .NumRoutes(6),
      .NumInputs(6),
      .NumOutputs(6),
      .InFifoDepth(2),
      .OutFifoDepth(2),
      .id_t(id_t),
      .hdr_t(hdr_t),
      .NumAddrRules(12),
      .addr_rule_t(mesh_router_3_6_map_rule_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) mesh_router_3_6 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('0),
      .id_route_map_i(MeshRouter36Map),
      .floo_req_i(mesh_router_3_6_req_in),
      .floo_rsp_o(mesh_router_3_6_rsp_out),
      .floo_req_o(mesh_router_3_6_req_out),
      .floo_rsp_i(mesh_router_3_6_rsp_in)
  );

  localparam int unsigned MeshRouter37MapNumRules = 9;

  typedef struct packed {
    id_t idx;
    id_t start_addr;
    id_t end_addr;
  } mesh_router_3_7_map_rule_t;

  localparam mesh_router_3_7_map_rule_t [MeshRouter37MapNumRules-1:0] MeshRouter37Map = '{
      '{idx: 3, start_addr: 0, end_addr: 28},  // cpu_master_ni
      '{idx: 3, start_addr: 36, end_addr: 74},  // llc_slave_ni
      '{idx: 3, start_addr: 90, end_addr: 92},  // sp_slave_ni
      '{idx: 4, start_addr: 28, end_addr: 35},  // int_core_master_ni_3_0
      '{idx: 4, start_addr: 74, end_addr: 81},  // int_core_slave_ni_3_0
      '{idx: 4, start_addr: 82, end_addr: 89},  // fp_core_slave_ni_0_0
      '{idx: 1, start_addr: 35, end_addr: 36},  // int_core_master_ni_3_7
      '{idx: 2, start_addr: 81, end_addr: 82},  // int_core_slave_ni_3_7
      '{idx: 0, start_addr: 89, end_addr: 90}  // fp_core_slave_ni_0_7

  };


  floo_req_t [4:0] mesh_router_3_7_req_in;
  floo_rsp_t [4:0] mesh_router_3_7_rsp_out;
  floo_req_t [4:0] mesh_router_3_7_req_out;
  floo_rsp_t [4:0] mesh_router_3_7_rsp_in;

  assign mesh_router_3_7_req_in[0] = fp_core_slave_ni_0_7_to_mesh_router_3_7_req;
  assign mesh_router_3_7_req_in[1] = int_core_master_ni_3_7_to_mesh_router_3_7_req;
  assign mesh_router_3_7_req_in[2] = int_core_slave_ni_3_7_to_mesh_router_3_7_req;
  assign mesh_router_3_7_req_in[3] = mesh_router_2_7_to_mesh_router_3_7_req;
  assign mesh_router_3_7_req_in[4] = mesh_router_3_6_to_mesh_router_3_7_req;

  assign mesh_router_3_7_to_fp_core_slave_ni_0_7_rsp = mesh_router_3_7_rsp_out[0];
  assign mesh_router_3_7_to_int_core_master_ni_3_7_rsp = mesh_router_3_7_rsp_out[1];
  assign mesh_router_3_7_to_int_core_slave_ni_3_7_rsp = mesh_router_3_7_rsp_out[2];
  assign mesh_router_3_7_to_mesh_router_2_7_rsp = mesh_router_3_7_rsp_out[3];
  assign mesh_router_3_7_to_mesh_router_3_6_rsp = mesh_router_3_7_rsp_out[4];

  assign mesh_router_3_7_to_fp_core_slave_ni_0_7_req = mesh_router_3_7_req_out[0];
  assign mesh_router_3_7_to_int_core_master_ni_3_7_req = mesh_router_3_7_req_out[1];
  assign mesh_router_3_7_to_int_core_slave_ni_3_7_req = mesh_router_3_7_req_out[2];
  assign mesh_router_3_7_to_mesh_router_2_7_req = mesh_router_3_7_req_out[3];
  assign mesh_router_3_7_to_mesh_router_3_6_req = mesh_router_3_7_req_out[4];

  assign mesh_router_3_7_rsp_in[0] = fp_core_slave_ni_0_7_to_mesh_router_3_7_rsp;
  assign mesh_router_3_7_rsp_in[1] = int_core_master_ni_3_7_to_mesh_router_3_7_rsp;
  assign mesh_router_3_7_rsp_in[2] = int_core_slave_ni_3_7_to_mesh_router_3_7_rsp;
  assign mesh_router_3_7_rsp_in[3] = mesh_router_2_7_to_mesh_router_3_7_rsp;
  assign mesh_router_3_7_rsp_in[4] = mesh_router_3_6_to_mesh_router_3_7_rsp;


  floo_axi_router #(
      .AxiCfg(AxiCfg),
      .RouteAlgo(IdTable),
      .NumRoutes(5),
      .NumInputs(5),
      .NumOutputs(5),
      .InFifoDepth(2),
      .OutFifoDepth(2),
      .id_t(id_t),
      .hdr_t(hdr_t),
      .NumAddrRules(9),
      .addr_rule_t(mesh_router_3_7_map_rule_t),
      .floo_req_t(floo_req_t),
      .floo_rsp_t(floo_rsp_t)
  ) mesh_router_3_7 (
      .clk_i,
      .rst_ni,
      .test_enable_i,
      .id_i('0),
      .id_route_map_i(MeshRouter37Map),
      .floo_req_i(mesh_router_3_7_req_in),
      .floo_rsp_o(mesh_router_3_7_rsp_out),
      .floo_req_o(mesh_router_3_7_req_out),
      .floo_rsp_i(mesh_router_3_7_rsp_in)
  );



endmodule
