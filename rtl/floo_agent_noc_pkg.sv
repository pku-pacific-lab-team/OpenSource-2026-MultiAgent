// Copyright 2026 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51

// AUTOMATICALLY GENERATED! DO NOT EDIT!

`include "axi/typedef.svh"
`include "floo_noc/typedef.svh"

package floo_agent_noc_pkg;

  import floo_pkg::*;

  /////////////////////
  //   Address Map   //
  /////////////////////

  typedef enum logic [6:0] {
    CpuMaster = 0,
    DmMaster = 1,
    D2d0Master = 2,
    D2d1Master = 3,
    IntCoreMasterX0Y0 = 4,
    IntCoreMasterX0Y1 = 5,
    IntCoreMasterX0Y2 = 6,
    IntCoreMasterX0Y3 = 7,
    IntCoreMasterX0Y4 = 8,
    IntCoreMasterX0Y5 = 9,
    IntCoreMasterX0Y6 = 10,
    IntCoreMasterX0Y7 = 11,
    IntCoreMasterX1Y0 = 12,
    IntCoreMasterX1Y1 = 13,
    IntCoreMasterX1Y2 = 14,
    IntCoreMasterX1Y3 = 15,
    IntCoreMasterX1Y4 = 16,
    IntCoreMasterX1Y5 = 17,
    IntCoreMasterX1Y6 = 18,
    IntCoreMasterX1Y7 = 19,
    IntCoreMasterX2Y0 = 20,
    IntCoreMasterX2Y1 = 21,
    IntCoreMasterX2Y2 = 22,
    IntCoreMasterX2Y3 = 23,
    IntCoreMasterX2Y4 = 24,
    IntCoreMasterX2Y5 = 25,
    IntCoreMasterX2Y6 = 26,
    IntCoreMasterX2Y7 = 27,
    IntCoreMasterX3Y0 = 28,
    IntCoreMasterX3Y1 = 29,
    IntCoreMasterX3Y2 = 30,
    IntCoreMasterX3Y3 = 31,
    IntCoreMasterX3Y4 = 32,
    IntCoreMasterX3Y5 = 33,
    IntCoreMasterX3Y6 = 34,
    IntCoreMasterX3Y7 = 35,
    LlcSlave = 36,
    RomSlave = 37,
    DmSlave = 38,
    ClintSlave = 39,
    PlicSlave = 40,
    UartSlave = 41,
    TimerSlave = 42,
    SysDcoSlave = 43,
    SlCfgSlave = 44,
    D2d0CfgSlave = 45,
    D2d1CfgSlave = 46,
    LlcCfgSlave = 47,
    D2d0Slave = 48,
    D2d1Slave = 49,
    IntCoreSlaveX0Y0 = 50,
    IntCoreSlaveX0Y1 = 51,
    IntCoreSlaveX0Y2 = 52,
    IntCoreSlaveX0Y3 = 53,
    IntCoreSlaveX0Y4 = 54,
    IntCoreSlaveX0Y5 = 55,
    IntCoreSlaveX0Y6 = 56,
    IntCoreSlaveX0Y7 = 57,
    IntCoreSlaveX1Y0 = 58,
    IntCoreSlaveX1Y1 = 59,
    IntCoreSlaveX1Y2 = 60,
    IntCoreSlaveX1Y3 = 61,
    IntCoreSlaveX1Y4 = 62,
    IntCoreSlaveX1Y5 = 63,
    IntCoreSlaveX1Y6 = 64,
    IntCoreSlaveX1Y7 = 65,
    IntCoreSlaveX2Y0 = 66,
    IntCoreSlaveX2Y1 = 67,
    IntCoreSlaveX2Y2 = 68,
    IntCoreSlaveX2Y3 = 69,
    IntCoreSlaveX2Y4 = 70,
    IntCoreSlaveX2Y5 = 71,
    IntCoreSlaveX2Y6 = 72,
    IntCoreSlaveX2Y7 = 73,
    IntCoreSlaveX3Y0 = 74,
    IntCoreSlaveX3Y1 = 75,
    IntCoreSlaveX3Y2 = 76,
    IntCoreSlaveX3Y3 = 77,
    IntCoreSlaveX3Y4 = 78,
    IntCoreSlaveX3Y5 = 79,
    IntCoreSlaveX3Y6 = 80,
    IntCoreSlaveX3Y7 = 81,
    FpCoreSlaveX0Y0 = 82,
    FpCoreSlaveX0Y1 = 83,
    FpCoreSlaveX0Y2 = 84,
    FpCoreSlaveX0Y3 = 85,
    FpCoreSlaveX0Y4 = 86,
    FpCoreSlaveX0Y5 = 87,
    FpCoreSlaveX0Y6 = 88,
    FpCoreSlaveX0Y7 = 89,
    SpSlave = 90,
    AuxSlotSlave = 91,
    NumEndpoints = 92
  } ep_id_e;



  typedef enum logic [5:0] {
    LlcSlaveSamIdx = 0,
    RomSlaveSamIdx = 1,
    DmSlaveSamIdx = 2,
    ClintSlaveSamIdx = 3,
    PlicSlaveSamIdx = 4,
    UartSlaveSamIdx = 5,
    TimerSlaveSamIdx = 6,
    SysDcoSlaveSamIdx = 7,
    SlCfgSlaveSamIdx = 8,
    D2d0CfgSlaveSamIdx = 9,
    D2d1CfgSlaveSamIdx = 10,
    LlcCfgSlaveSamIdx = 11,
    D2d0SlaveSamIdx = 12,
    D2d1SlaveSamIdx = 13,
    IntCoreSlaveX0Y0SamIdx = 14,
    IntCoreSlaveX0Y1SamIdx = 15,
    IntCoreSlaveX0Y2SamIdx = 16,
    IntCoreSlaveX0Y3SamIdx = 17,
    IntCoreSlaveX0Y4SamIdx = 18,
    IntCoreSlaveX0Y5SamIdx = 19,
    IntCoreSlaveX0Y6SamIdx = 20,
    IntCoreSlaveX0Y7SamIdx = 21,
    IntCoreSlaveX1Y0SamIdx = 22,
    IntCoreSlaveX1Y1SamIdx = 23,
    IntCoreSlaveX1Y2SamIdx = 24,
    IntCoreSlaveX1Y3SamIdx = 25,
    IntCoreSlaveX1Y4SamIdx = 26,
    IntCoreSlaveX1Y5SamIdx = 27,
    IntCoreSlaveX1Y6SamIdx = 28,
    IntCoreSlaveX1Y7SamIdx = 29,
    IntCoreSlaveX2Y0SamIdx = 30,
    IntCoreSlaveX2Y1SamIdx = 31,
    IntCoreSlaveX2Y2SamIdx = 32,
    IntCoreSlaveX2Y3SamIdx = 33,
    IntCoreSlaveX2Y4SamIdx = 34,
    IntCoreSlaveX2Y5SamIdx = 35,
    IntCoreSlaveX2Y6SamIdx = 36,
    IntCoreSlaveX2Y7SamIdx = 37,
    IntCoreSlaveX3Y0SamIdx = 38,
    IntCoreSlaveX3Y1SamIdx = 39,
    IntCoreSlaveX3Y2SamIdx = 40,
    IntCoreSlaveX3Y3SamIdx = 41,
    IntCoreSlaveX3Y4SamIdx = 42,
    IntCoreSlaveX3Y5SamIdx = 43,
    IntCoreSlaveX3Y6SamIdx = 44,
    IntCoreSlaveX3Y7SamIdx = 45,
    FpCoreSlaveX0Y0SamIdx = 46,
    FpCoreSlaveX0Y1SamIdx = 47,
    FpCoreSlaveX0Y2SamIdx = 48,
    FpCoreSlaveX0Y3SamIdx = 49,
    FpCoreSlaveX0Y4SamIdx = 50,
    FpCoreSlaveX0Y5SamIdx = 51,
    FpCoreSlaveX0Y6SamIdx = 52,
    FpCoreSlaveX0Y7SamIdx = 53,
    SpSlaveSamIdx = 54,
    AuxSlotSlaveSamIdx = 55
  } sam_idx_e;



  typedef logic [0:0] rob_idx_t;
  typedef logic [0:0] port_id_t;
  typedef logic [6:0] id_t;
  typedef logic route_t;


  localparam int unsigned SamNumRules = 56;

  typedef struct packed {
    id_t idx;
    logic [63:0] start_addr;
    logic [63:0] end_addr;
  } sam_rule_t;

  localparam sam_rule_t [SamNumRules-1:0] Sam_00 = '{
      '{
          idx: 91,
          start_addr: 64'h0000000030000000,
          end_addr: 64'h0000000040000000
      },  // aux_slot_slave_sam_idx
      '{
          idx: 90,
          start_addr: 64'h0000000040000000,
          end_addr: 64'h0000000050000000
      },  // sp_slave_sam_idx
      '{
          idx: 89,
          start_addr: 64'h0000000057000000,
          end_addr: 64'h0000000058000000
      },  // fp_core_slave_x0_y7_sam_idx
      '{
          idx: 88,
          start_addr: 64'h0000000056000000,
          end_addr: 64'h0000000057000000
      },  // fp_core_slave_x0_y6_sam_idx
      '{
          idx: 87,
          start_addr: 64'h0000000055000000,
          end_addr: 64'h0000000056000000
      },  // fp_core_slave_x0_y5_sam_idx
      '{
          idx: 86,
          start_addr: 64'h0000000054000000,
          end_addr: 64'h0000000055000000
      },  // fp_core_slave_x0_y4_sam_idx
      '{
          idx: 85,
          start_addr: 64'h0000000053000000,
          end_addr: 64'h0000000054000000
      },  // fp_core_slave_x0_y3_sam_idx
      '{
          idx: 84,
          start_addr: 64'h0000000052000000,
          end_addr: 64'h0000000053000000
      },  // fp_core_slave_x0_y2_sam_idx
      '{
          idx: 83,
          start_addr: 64'h0000000051000000,
          end_addr: 64'h0000000052000000
      },  // fp_core_slave_x0_y1_sam_idx
      '{
          idx: 82,
          start_addr: 64'h0000000050000000,
          end_addr: 64'h0000000051000000
      },  // fp_core_slave_x0_y0_sam_idx
      '{
          idx: 81,
          start_addr: 64'h000000007f000000,
          end_addr: 64'h0000000080000000
      },  // int_core_slave_x3_y7_sam_idx
      '{
          idx: 80,
          start_addr: 64'h000000007e000000,
          end_addr: 64'h000000007f000000
      },  // int_core_slave_x3_y6_sam_idx
      '{
          idx: 79,
          start_addr: 64'h000000007d000000,
          end_addr: 64'h000000007e000000
      },  // int_core_slave_x3_y5_sam_idx
      '{
          idx: 78,
          start_addr: 64'h000000007c000000,
          end_addr: 64'h000000007d000000
      },  // int_core_slave_x3_y4_sam_idx
      '{
          idx: 77,
          start_addr: 64'h000000007b000000,
          end_addr: 64'h000000007c000000
      },  // int_core_slave_x3_y3_sam_idx
      '{
          idx: 76,
          start_addr: 64'h000000007a000000,
          end_addr: 64'h000000007b000000
      },  // int_core_slave_x3_y2_sam_idx
      '{
          idx: 75,
          start_addr: 64'h0000000079000000,
          end_addr: 64'h000000007a000000
      },  // int_core_slave_x3_y1_sam_idx
      '{
          idx: 74,
          start_addr: 64'h0000000078000000,
          end_addr: 64'h0000000079000000
      },  // int_core_slave_x3_y0_sam_idx
      '{
          idx: 73,
          start_addr: 64'h0000000077000000,
          end_addr: 64'h0000000078000000
      },  // int_core_slave_x2_y7_sam_idx
      '{
          idx: 72,
          start_addr: 64'h0000000076000000,
          end_addr: 64'h0000000077000000
      },  // int_core_slave_x2_y6_sam_idx
      '{
          idx: 71,
          start_addr: 64'h0000000075000000,
          end_addr: 64'h0000000076000000
      },  // int_core_slave_x2_y5_sam_idx
      '{
          idx: 70,
          start_addr: 64'h0000000074000000,
          end_addr: 64'h0000000075000000
      },  // int_core_slave_x2_y4_sam_idx
      '{
          idx: 69,
          start_addr: 64'h0000000073000000,
          end_addr: 64'h0000000074000000
      },  // int_core_slave_x2_y3_sam_idx
      '{
          idx: 68,
          start_addr: 64'h0000000072000000,
          end_addr: 64'h0000000073000000
      },  // int_core_slave_x2_y2_sam_idx
      '{
          idx: 67,
          start_addr: 64'h0000000071000000,
          end_addr: 64'h0000000072000000
      },  // int_core_slave_x2_y1_sam_idx
      '{
          idx: 66,
          start_addr: 64'h0000000070000000,
          end_addr: 64'h0000000071000000
      },  // int_core_slave_x2_y0_sam_idx
      '{
          idx: 65,
          start_addr: 64'h000000006f000000,
          end_addr: 64'h0000000070000000
      },  // int_core_slave_x1_y7_sam_idx
      '{
          idx: 64,
          start_addr: 64'h000000006e000000,
          end_addr: 64'h000000006f000000
      },  // int_core_slave_x1_y6_sam_idx
      '{
          idx: 63,
          start_addr: 64'h000000006d000000,
          end_addr: 64'h000000006e000000
      },  // int_core_slave_x1_y5_sam_idx
      '{
          idx: 62,
          start_addr: 64'h000000006c000000,
          end_addr: 64'h000000006d000000
      },  // int_core_slave_x1_y4_sam_idx
      '{
          idx: 61,
          start_addr: 64'h000000006b000000,
          end_addr: 64'h000000006c000000
      },  // int_core_slave_x1_y3_sam_idx
      '{
          idx: 60,
          start_addr: 64'h000000006a000000,
          end_addr: 64'h000000006b000000
      },  // int_core_slave_x1_y2_sam_idx
      '{
          idx: 59,
          start_addr: 64'h0000000069000000,
          end_addr: 64'h000000006a000000
      },  // int_core_slave_x1_y1_sam_idx
      '{
          idx: 58,
          start_addr: 64'h0000000068000000,
          end_addr: 64'h0000000069000000
      },  // int_core_slave_x1_y0_sam_idx
      '{
          idx: 57,
          start_addr: 64'h0000000067000000,
          end_addr: 64'h0000000068000000
      },  // int_core_slave_x0_y7_sam_idx
      '{
          idx: 56,
          start_addr: 64'h0000000066000000,
          end_addr: 64'h0000000067000000
      },  // int_core_slave_x0_y6_sam_idx
      '{
          idx: 55,
          start_addr: 64'h0000000065000000,
          end_addr: 64'h0000000066000000
      },  // int_core_slave_x0_y5_sam_idx
      '{
          idx: 54,
          start_addr: 64'h0000000064000000,
          end_addr: 64'h0000000065000000
      },  // int_core_slave_x0_y4_sam_idx
      '{
          idx: 53,
          start_addr: 64'h0000000063000000,
          end_addr: 64'h0000000064000000
      },  // int_core_slave_x0_y3_sam_idx
      '{
          idx: 52,
          start_addr: 64'h0000000062000000,
          end_addr: 64'h0000000063000000
      },  // int_core_slave_x0_y2_sam_idx
      '{
          idx: 51,
          start_addr: 64'h0000000061000000,
          end_addr: 64'h0000000062000000
      },  // int_core_slave_x0_y1_sam_idx
      '{
          idx: 50,
          start_addr: 64'h0000000060000000,
          end_addr: 64'h0000000061000000
      },  // int_core_slave_x0_y0_sam_idx
      '{
          idx: 49,
          start_addr: 64'h0000000200000000,
          end_addr: 64'h0000000400000000
      },  // d2d1_slave_sam_idx
      '{
          idx: 48,
          start_addr: 64'h0000000100000000,
          end_addr: 64'h0000000200000000
      },  // d2d0_slave_sam_idx
      '{
          idx: 47,
          start_addr: 64'h0000000028000000,
          end_addr: 64'h0000000028001000
      },  // llc_cfg_slave_sam_idx
      '{
          idx: 46,
          start_addr: 64'h0000000027000000,
          end_addr: 64'h0000000027001000
      },  // d2d1_cfg_slave_sam_idx
      '{
          idx: 45,
          start_addr: 64'h0000000026000000,
          end_addr: 64'h0000000026001000
      },  // d2d0_cfg_slave_sam_idx
      '{
          idx: 44,
          start_addr: 64'h0000000025000000,
          end_addr: 64'h0000000025001000
      },  // sl_cfg_slave_sam_idx
      '{
          idx: 43,
          start_addr: 64'h0000000020000000,
          end_addr: 64'h0000000020001000
      },  // sys_dco_slave_sam_idx
      '{
          idx: 42,
          start_addr: 64'h0000000018000000,
          end_addr: 64'h0000000018001000
      },  // timer_slave_sam_idx
      '{
          idx: 41,
          start_addr: 64'h0000000010000000,
          end_addr: 64'h0000000010001000
      },  // uart_slave_sam_idx
      '{
          idx: 40,
          start_addr: 64'h000000000c000000,
          end_addr: 64'h000000000fffffff
      },  // plic_slave_sam_idx
      '{
          idx: 39,
          start_addr: 64'h0000000002000000,
          end_addr: 64'h00000000020c0000
      },  // clint_slave_sam_idx
      '{
          idx: 38,
          start_addr: 64'h0000000000000000,
          end_addr: 64'h0000000000001000
      },  // dm_slave_sam_idx
      '{
          idx: 37,
          start_addr: 64'h0000000000010000,
          end_addr: 64'h0000000000020000
      },  // rom_slave_sam_idx
      '{
          idx: 36,
          start_addr: 64'h0000000080000000,
          end_addr: 64'h0000000100000000
      }  // llc_slave_sam_idx

  };

  localparam sam_rule_t [SamNumRules-1:0] Sam_01 = '{
      '{
          idx: 91,
          start_addr: 64'h0000000130000000,
          end_addr: 64'h0000000140000000
      },  // aux_slot_slave_sam_idx
      '{
          idx: 90,
          start_addr: 64'h0000000140000000,
          end_addr: 64'h0000000150000000
      },  // sp_slave_sam_idx
      '{
          idx: 89,
          start_addr: 64'h0000000157000000,
          end_addr: 64'h0000000158000000
      },  // fp_core_slave_x0_y7_sam_idx
      '{
          idx: 88,
          start_addr: 64'h0000000156000000,
          end_addr: 64'h0000000157000000
      },  // fp_core_slave_x0_y6_sam_idx
      '{
          idx: 87,
          start_addr: 64'h0000000155000000,
          end_addr: 64'h0000000156000000
      },  // fp_core_slave_x0_y5_sam_idx
      '{
          idx: 86,
          start_addr: 64'h0000000154000000,
          end_addr: 64'h0000000155000000
      },  // fp_core_slave_x0_y4_sam_idx
      '{
          idx: 85,
          start_addr: 64'h0000000153000000,
          end_addr: 64'h0000000154000000
      },  // fp_core_slave_x0_y3_sam_idx
      '{
          idx: 84,
          start_addr: 64'h0000000152000000,
          end_addr: 64'h0000000153000000
      },  // fp_core_slave_x0_y2_sam_idx
      '{
          idx: 83,
          start_addr: 64'h0000000151000000,
          end_addr: 64'h0000000152000000
      },  // fp_core_slave_x0_y1_sam_idx
      '{
          idx: 82,
          start_addr: 64'h0000000150000000,
          end_addr: 64'h0000000151000000
      },  // fp_core_slave_x0_y0_sam_idx
      '{
          idx: 81,
          start_addr: 64'h000000017f000000,
          end_addr: 64'h0000000180000000
      },  // int_core_slave_x3_y7_sam_idx
      '{
          idx: 80,
          start_addr: 64'h000000017e000000,
          end_addr: 64'h000000017f000000
      },  // int_core_slave_x3_y6_sam_idx
      '{
          idx: 79,
          start_addr: 64'h000000017d000000,
          end_addr: 64'h000000017e000000
      },  // int_core_slave_x3_y5_sam_idx
      '{
          idx: 78,
          start_addr: 64'h000000017c000000,
          end_addr: 64'h000000017d000000
      },  // int_core_slave_x3_y4_sam_idx
      '{
          idx: 77,
          start_addr: 64'h000000017b000000,
          end_addr: 64'h000000017c000000
      },  // int_core_slave_x3_y3_sam_idx
      '{
          idx: 76,
          start_addr: 64'h000000017a000000,
          end_addr: 64'h000000017b000000
      },  // int_core_slave_x3_y2_sam_idx
      '{
          idx: 75,
          start_addr: 64'h0000000179000000,
          end_addr: 64'h000000017a000000
      },  // int_core_slave_x3_y1_sam_idx
      '{
          idx: 74,
          start_addr: 64'h0000000178000000,
          end_addr: 64'h0000000179000000
      },  // int_core_slave_x3_y0_sam_idx
      '{
          idx: 73,
          start_addr: 64'h0000000177000000,
          end_addr: 64'h0000000178000000
      },  // int_core_slave_x2_y7_sam_idx
      '{
          idx: 72,
          start_addr: 64'h0000000176000000,
          end_addr: 64'h0000000177000000
      },  // int_core_slave_x2_y6_sam_idx
      '{
          idx: 71,
          start_addr: 64'h0000000175000000,
          end_addr: 64'h0000000176000000
      },  // int_core_slave_x2_y5_sam_idx
      '{
          idx: 70,
          start_addr: 64'h0000000174000000,
          end_addr: 64'h0000000175000000
      },  // int_core_slave_x2_y4_sam_idx
      '{
          idx: 69,
          start_addr: 64'h0000000173000000,
          end_addr: 64'h0000000174000000
      },  // int_core_slave_x2_y3_sam_idx
      '{
          idx: 68,
          start_addr: 64'h0000000172000000,
          end_addr: 64'h0000000173000000
      },  // int_core_slave_x2_y2_sam_idx
      '{
          idx: 67,
          start_addr: 64'h0000000171000000,
          end_addr: 64'h0000000172000000
      },  // int_core_slave_x2_y1_sam_idx
      '{
          idx: 66,
          start_addr: 64'h0000000170000000,
          end_addr: 64'h0000000171000000
      },  // int_core_slave_x2_y0_sam_idx
      '{
          idx: 65,
          start_addr: 64'h000000016f000000,
          end_addr: 64'h0000000170000000
      },  // int_core_slave_x1_y7_sam_idx
      '{
          idx: 64,
          start_addr: 64'h000000016e000000,
          end_addr: 64'h000000016f000000
      },  // int_core_slave_x1_y6_sam_idx
      '{
          idx: 63,
          start_addr: 64'h000000016d000000,
          end_addr: 64'h000000016e000000
      },  // int_core_slave_x1_y5_sam_idx
      '{
          idx: 62,
          start_addr: 64'h000000016c000000,
          end_addr: 64'h000000016d000000
      },  // int_core_slave_x1_y4_sam_idx
      '{
          idx: 61,
          start_addr: 64'h000000016b000000,
          end_addr: 64'h000000016c000000
      },  // int_core_slave_x1_y3_sam_idx
      '{
          idx: 60,
          start_addr: 64'h000000016a000000,
          end_addr: 64'h000000016b000000
      },  // int_core_slave_x1_y2_sam_idx
      '{
          idx: 59,
          start_addr: 64'h0000000169000000,
          end_addr: 64'h000000016a000000
      },  // int_core_slave_x1_y1_sam_idx
      '{
          idx: 58,
          start_addr: 64'h0000000168000000,
          end_addr: 64'h0000000169000000
      },  // int_core_slave_x1_y0_sam_idx
      '{
          idx: 57,
          start_addr: 64'h0000000167000000,
          end_addr: 64'h0000000168000000
      },  // int_core_slave_x0_y7_sam_idx
      '{
          idx: 56,
          start_addr: 64'h0000000166000000,
          end_addr: 64'h0000000167000000
      },  // int_core_slave_x0_y6_sam_idx
      '{
          idx: 55,
          start_addr: 64'h0000000165000000,
          end_addr: 64'h0000000166000000
      },  // int_core_slave_x0_y5_sam_idx
      '{
          idx: 54,
          start_addr: 64'h0000000164000000,
          end_addr: 64'h0000000165000000
      },  // int_core_slave_x0_y4_sam_idx
      '{
          idx: 53,
          start_addr: 64'h0000000163000000,
          end_addr: 64'h0000000164000000
      },  // int_core_slave_x0_y3_sam_idx
      '{
          idx: 52,
          start_addr: 64'h0000000162000000,
          end_addr: 64'h0000000163000000
      },  // int_core_slave_x0_y2_sam_idx
      '{
          idx: 51,
          start_addr: 64'h0000000161000000,
          end_addr: 64'h0000000162000000
      },  // int_core_slave_x0_y1_sam_idx
      '{
          idx: 50,
          start_addr: 64'h0000000160000000,
          end_addr: 64'h0000000161000000
      },  // int_core_slave_x0_y0_sam_idx
      '{
          idx: 49,
          start_addr: 64'h0000000000000000,
          end_addr: 64'h0000000100000000
      },  // d2d1_slave_sam_idx
      '{
          idx: 48,
          start_addr: 64'h0000000200000000,
          end_addr: 64'h0000000400000000
      },  // d2d0_slave_sam_idx
      '{
          idx: 47,
          start_addr: 64'h0000000128000000,
          end_addr: 64'h0000000128001000
      },  // llc_cfg_slave_sam_idx
      '{
          idx: 46,
          start_addr: 64'h0000000127000000,
          end_addr: 64'h0000000127001000
      },  // d2d1_cfg_slave_sam_idx
      '{
          idx: 45,
          start_addr: 64'h0000000126000000,
          end_addr: 64'h0000000126001000
      },  // d2d0_cfg_slave_sam_idx
      '{
          idx: 44,
          start_addr: 64'h0000000125000000,
          end_addr: 64'h0000000125001000
      },  // sl_cfg_slave_sam_idx
      '{
          idx: 43,
          start_addr: 64'h0000000120000000,
          end_addr: 64'h0000000120001000
      },  // sys_dco_slave_sam_idx
      '{
          idx: 42,
          start_addr: 64'h0000000118000000,
          end_addr: 64'h0000000118001000
      },  // timer_slave_sam_idx
      '{
          idx: 41,
          start_addr: 64'h0000000110000000,
          end_addr: 64'h0000000110001000
      },  // uart_slave_sam_idx
      '{
          idx: 40,
          start_addr: 64'h000000010c000000,
          end_addr: 64'h000000010fffffff
      },  // plic_slave_sam_idx
      '{
          idx: 39,
          start_addr: 64'h0000000102000000,
          end_addr: 64'h00000001020c0000
      },  // clint_slave_sam_idx
      '{
          idx: 38,
          start_addr: 64'h0000000100000000,
          end_addr: 64'h0000000100001000
      },  // dm_slave_sam_idx
      '{
          idx: 37,
          start_addr: 64'h0000000100010000,
          end_addr: 64'h0000000100020000
      },  // rom_slave_sam_idx
      '{
          idx: 36,
          start_addr: 64'h0000000180000000,
          end_addr: 64'h0000000200000000
      }  // llc_slave_sam_idx

  };

  localparam sam_rule_t [SamNumRules-1:0] Sam_10 = '{
      '{
          idx: 91,
          start_addr: 64'h0000000230000000,
          end_addr: 64'h0000000240000000
      },  // aux_slot_slave_sam_idx
      '{
          idx: 90,
          start_addr: 64'h0000000240000000,
          end_addr: 64'h0000000250000000
      },  // sp_slave_sam_idx
      '{
          idx: 89,
          start_addr: 64'h0000000257000000,
          end_addr: 64'h0000000258000000
      },  // fp_core_slave_x0_y7_sam_idx
      '{
          idx: 88,
          start_addr: 64'h0000000256000000,
          end_addr: 64'h0000000257000000
      },  // fp_core_slave_x0_y6_sam_idx
      '{
          idx: 87,
          start_addr: 64'h0000000255000000,
          end_addr: 64'h0000000256000000
      },  // fp_core_slave_x0_y5_sam_idx
      '{
          idx: 86,
          start_addr: 64'h0000000254000000,
          end_addr: 64'h0000000255000000
      },  // fp_core_slave_x0_y4_sam_idx
      '{
          idx: 85,
          start_addr: 64'h0000000253000000,
          end_addr: 64'h0000000254000000
      },  // fp_core_slave_x0_y3_sam_idx
      '{
          idx: 84,
          start_addr: 64'h0000000252000000,
          end_addr: 64'h0000000253000000
      },  // fp_core_slave_x0_y2_sam_idx
      '{
          idx: 83,
          start_addr: 64'h0000000251000000,
          end_addr: 64'h0000000252000000
      },  // fp_core_slave_x0_y1_sam_idx
      '{
          idx: 82,
          start_addr: 64'h0000000250000000,
          end_addr: 64'h0000000251000000
      },  // fp_core_slave_x0_y0_sam_idx
      '{
          idx: 81,
          start_addr: 64'h000000027f000000,
          end_addr: 64'h0000000280000000
      },  // int_core_slave_x3_y7_sam_idx
      '{
          idx: 80,
          start_addr: 64'h000000027e000000,
          end_addr: 64'h000000027f000000
      },  // int_core_slave_x3_y6_sam_idx
      '{
          idx: 79,
          start_addr: 64'h000000027d000000,
          end_addr: 64'h000000027e000000
      },  // int_core_slave_x3_y5_sam_idx
      '{
          idx: 78,
          start_addr: 64'h000000027c000000,
          end_addr: 64'h000000027d000000
      },  // int_core_slave_x3_y4_sam_idx
      '{
          idx: 77,
          start_addr: 64'h000000027b000000,
          end_addr: 64'h000000027c000000
      },  // int_core_slave_x3_y3_sam_idx
      '{
          idx: 76,
          start_addr: 64'h000000027a000000,
          end_addr: 64'h000000027b000000
      },  // int_core_slave_x3_y2_sam_idx
      '{
          idx: 75,
          start_addr: 64'h0000000279000000,
          end_addr: 64'h000000027a000000
      },  // int_core_slave_x3_y1_sam_idx
      '{
          idx: 74,
          start_addr: 64'h0000000278000000,
          end_addr: 64'h0000000279000000
      },  // int_core_slave_x3_y0_sam_idx
      '{
          idx: 73,
          start_addr: 64'h0000000277000000,
          end_addr: 64'h0000000278000000
      },  // int_core_slave_x2_y7_sam_idx
      '{
          idx: 72,
          start_addr: 64'h0000000276000000,
          end_addr: 64'h0000000277000000
      },  // int_core_slave_x2_y6_sam_idx
      '{
          idx: 71,
          start_addr: 64'h0000000275000000,
          end_addr: 64'h0000000276000000
      },  // int_core_slave_x2_y5_sam_idx
      '{
          idx: 70,
          start_addr: 64'h0000000274000000,
          end_addr: 64'h0000000275000000
      },  // int_core_slave_x2_y4_sam_idx
      '{
          idx: 69,
          start_addr: 64'h0000000273000000,
          end_addr: 64'h0000000274000000
      },  // int_core_slave_x2_y3_sam_idx
      '{
          idx: 68,
          start_addr: 64'h0000000272000000,
          end_addr: 64'h0000000273000000
      },  // int_core_slave_x2_y2_sam_idx
      '{
          idx: 67,
          start_addr: 64'h0000000271000000,
          end_addr: 64'h0000000272000000
      },  // int_core_slave_x2_y1_sam_idx
      '{
          idx: 66,
          start_addr: 64'h0000000270000000,
          end_addr: 64'h0000000271000000
      },  // int_core_slave_x2_y0_sam_idx
      '{
          idx: 65,
          start_addr: 64'h000000026f000000,
          end_addr: 64'h0000000270000000
      },  // int_core_slave_x1_y7_sam_idx
      '{
          idx: 64,
          start_addr: 64'h000000026e000000,
          end_addr: 64'h000000026f000000
      },  // int_core_slave_x1_y6_sam_idx
      '{
          idx: 63,
          start_addr: 64'h000000026d000000,
          end_addr: 64'h000000026e000000
      },  // int_core_slave_x1_y5_sam_idx
      '{
          idx: 62,
          start_addr: 64'h000000026c000000,
          end_addr: 64'h000000026d000000
      },  // int_core_slave_x1_y4_sam_idx
      '{
          idx: 61,
          start_addr: 64'h000000026b000000,
          end_addr: 64'h000000026c000000
      },  // int_core_slave_x1_y3_sam_idx
      '{
          idx: 60,
          start_addr: 64'h000000026a000000,
          end_addr: 64'h000000026b000000
      },  // int_core_slave_x1_y2_sam_idx
      '{
          idx: 59,
          start_addr: 64'h0000000269000000,
          end_addr: 64'h000000026a000000
      },  // int_core_slave_x1_y1_sam_idx
      '{
          idx: 58,
          start_addr: 64'h0000000268000000,
          end_addr: 64'h0000000269000000
      },  // int_core_slave_x1_y0_sam_idx
      '{
          idx: 57,
          start_addr: 64'h0000000267000000,
          end_addr: 64'h0000000268000000
      },  // int_core_slave_x0_y7_sam_idx
      '{
          idx: 56,
          start_addr: 64'h0000000266000000,
          end_addr: 64'h0000000267000000
      },  // int_core_slave_x0_y6_sam_idx
      '{
          idx: 55,
          start_addr: 64'h0000000265000000,
          end_addr: 64'h0000000266000000
      },  // int_core_slave_x0_y5_sam_idx
      '{
          idx: 54,
          start_addr: 64'h0000000264000000,
          end_addr: 64'h0000000265000000
      },  // int_core_slave_x0_y4_sam_idx
      '{
          idx: 53,
          start_addr: 64'h0000000263000000,
          end_addr: 64'h0000000264000000
      },  // int_core_slave_x0_y3_sam_idx
      '{
          idx: 52,
          start_addr: 64'h0000000262000000,
          end_addr: 64'h0000000263000000
      },  // int_core_slave_x0_y2_sam_idx
      '{
          idx: 51,
          start_addr: 64'h0000000261000000,
          end_addr: 64'h0000000262000000
      },  // int_core_slave_x0_y1_sam_idx
      '{
          idx: 50,
          start_addr: 64'h0000000260000000,
          end_addr: 64'h0000000261000000
      },  // int_core_slave_x0_y0_sam_idx
      '{
          idx: 49,
          start_addr: 64'h0000000300000000,
          end_addr: 64'h0000000400000000
      },  // d2d1_slave_sam_idx
      '{
          idx: 48,
          start_addr: 64'h0000000000000000,
          end_addr: 64'h0000000200000000
      },  // d2d0_slave_sam_idx
      '{
          idx: 47,
          start_addr: 64'h0000000228000000,
          end_addr: 64'h0000000228001000
      },  // llc_cfg_slave_sam_idx
      '{
          idx: 46,
          start_addr: 64'h0000000227000000,
          end_addr: 64'h0000000227001000
      },  // d2d1_cfg_slave_sam_idx
      '{
          idx: 45,
          start_addr: 64'h0000000226000000,
          end_addr: 64'h0000000226001000
      },  // d2d0_cfg_slave_sam_idx
      '{
          idx: 44,
          start_addr: 64'h0000000225000000,
          end_addr: 64'h0000000225001000
      },  // sl_cfg_slave_sam_idx
      '{
          idx: 43,
          start_addr: 64'h0000000220000000,
          end_addr: 64'h0000000220001000
      },  // sys_dco_slave_sam_idx
      '{
          idx: 42,
          start_addr: 64'h0000000218000000,
          end_addr: 64'h0000000218001000
      },  // timer_slave_sam_idx
      '{
          idx: 41,
          start_addr: 64'h0000000210000000,
          end_addr: 64'h0000000210001000
      },  // uart_slave_sam_idx
      '{
          idx: 40,
          start_addr: 64'h000000020c000000,
          end_addr: 64'h000000020fffffff
      },  // plic_slave_sam_idx
      '{
          idx: 39,
          start_addr: 64'h0000000202000000,
          end_addr: 64'h00000002020c0000
      },  // clint_slave_sam_idx
      '{
          idx: 38,
          start_addr: 64'h0000000200000000,
          end_addr: 64'h0000000200001000
      },  // dm_slave_sam_idx
      '{
          idx: 37,
          start_addr: 64'h0000000200010000,
          end_addr: 64'h0000000200020000
      },  // rom_slave_sam_idx
      '{
          idx: 36,
          start_addr: 64'h0000000280000000,
          end_addr: 64'h0000000300000000
      }  // llc_slave_sam_idx

  };

  localparam sam_rule_t [SamNumRules-1:0] Sam_11 = '{
      '{
          idx: 91,
          start_addr: 64'h0000000330000000,
          end_addr: 64'h0000000340000000
      },  // aux_slot_slave_sam_idx
      '{
          idx: 90,
          start_addr: 64'h0000000340000000,
          end_addr: 64'h0000000350000000
      },  // sp_slave_sam_idx
      '{
          idx: 89,
          start_addr: 64'h0000000357000000,
          end_addr: 64'h0000000358000000
      },  // fp_core_slave_x0_y7_sam_idx
      '{
          idx: 88,
          start_addr: 64'h0000000356000000,
          end_addr: 64'h0000000357000000
      },  // fp_core_slave_x0_y6_sam_idx
      '{
          idx: 87,
          start_addr: 64'h0000000355000000,
          end_addr: 64'h0000000356000000
      },  // fp_core_slave_x0_y5_sam_idx
      '{
          idx: 86,
          start_addr: 64'h0000000354000000,
          end_addr: 64'h0000000355000000
      },  // fp_core_slave_x0_y4_sam_idx
      '{
          idx: 85,
          start_addr: 64'h0000000353000000,
          end_addr: 64'h0000000354000000
      },  // fp_core_slave_x0_y3_sam_idx
      '{
          idx: 84,
          start_addr: 64'h0000000352000000,
          end_addr: 64'h0000000353000000
      },  // fp_core_slave_x0_y2_sam_idx
      '{
          idx: 83,
          start_addr: 64'h0000000351000000,
          end_addr: 64'h0000000352000000
      },  // fp_core_slave_x0_y1_sam_idx
      '{
          idx: 82,
          start_addr: 64'h0000000350000000,
          end_addr: 64'h0000000351000000
      },  // fp_core_slave_x0_y0_sam_idx
      '{
          idx: 81,
          start_addr: 64'h000000037f000000,
          end_addr: 64'h0000000380000000
      },  // int_core_slave_x3_y7_sam_idx
      '{
          idx: 80,
          start_addr: 64'h000000037e000000,
          end_addr: 64'h000000037f000000
      },  // int_core_slave_x3_y6_sam_idx
      '{
          idx: 79,
          start_addr: 64'h000000037d000000,
          end_addr: 64'h000000037e000000
      },  // int_core_slave_x3_y5_sam_idx
      '{
          idx: 78,
          start_addr: 64'h000000037c000000,
          end_addr: 64'h000000037d000000
      },  // int_core_slave_x3_y4_sam_idx
      '{
          idx: 77,
          start_addr: 64'h000000037b000000,
          end_addr: 64'h000000037c000000
      },  // int_core_slave_x3_y3_sam_idx
      '{
          idx: 76,
          start_addr: 64'h000000037a000000,
          end_addr: 64'h000000037b000000
      },  // int_core_slave_x3_y2_sam_idx
      '{
          idx: 75,
          start_addr: 64'h0000000379000000,
          end_addr: 64'h000000037a000000
      },  // int_core_slave_x3_y1_sam_idx
      '{
          idx: 74,
          start_addr: 64'h0000000378000000,
          end_addr: 64'h0000000379000000
      },  // int_core_slave_x3_y0_sam_idx
      '{
          idx: 73,
          start_addr: 64'h0000000377000000,
          end_addr: 64'h0000000378000000
      },  // int_core_slave_x2_y7_sam_idx
      '{
          idx: 72,
          start_addr: 64'h0000000376000000,
          end_addr: 64'h0000000377000000
      },  // int_core_slave_x2_y6_sam_idx
      '{
          idx: 71,
          start_addr: 64'h0000000375000000,
          end_addr: 64'h0000000376000000
      },  // int_core_slave_x2_y5_sam_idx
      '{
          idx: 70,
          start_addr: 64'h0000000374000000,
          end_addr: 64'h0000000375000000
      },  // int_core_slave_x2_y4_sam_idx
      '{
          idx: 69,
          start_addr: 64'h0000000373000000,
          end_addr: 64'h0000000374000000
      },  // int_core_slave_x2_y3_sam_idx
      '{
          idx: 68,
          start_addr: 64'h0000000372000000,
          end_addr: 64'h0000000373000000
      },  // int_core_slave_x2_y2_sam_idx
      '{
          idx: 67,
          start_addr: 64'h0000000371000000,
          end_addr: 64'h0000000372000000
      },  // int_core_slave_x2_y1_sam_idx
      '{
          idx: 66,
          start_addr: 64'h0000000370000000,
          end_addr: 64'h0000000371000000
      },  // int_core_slave_x2_y0_sam_idx
      '{
          idx: 65,
          start_addr: 64'h000000036f000000,
          end_addr: 64'h0000000370000000
      },  // int_core_slave_x1_y7_sam_idx
      '{
          idx: 64,
          start_addr: 64'h000000036e000000,
          end_addr: 64'h000000036f000000
      },  // int_core_slave_x1_y6_sam_idx
      '{
          idx: 63,
          start_addr: 64'h000000036d000000,
          end_addr: 64'h000000036e000000
      },  // int_core_slave_x1_y5_sam_idx
      '{
          idx: 62,
          start_addr: 64'h000000036c000000,
          end_addr: 64'h000000036d000000
      },  // int_core_slave_x1_y4_sam_idx
      '{
          idx: 61,
          start_addr: 64'h000000036b000000,
          end_addr: 64'h000000036c000000
      },  // int_core_slave_x1_y3_sam_idx
      '{
          idx: 60,
          start_addr: 64'h000000036a000000,
          end_addr: 64'h000000036b000000
      },  // int_core_slave_x1_y2_sam_idx
      '{
          idx: 59,
          start_addr: 64'h0000000369000000,
          end_addr: 64'h000000036a000000
      },  // int_core_slave_x1_y1_sam_idx
      '{
          idx: 58,
          start_addr: 64'h0000000368000000,
          end_addr: 64'h0000000369000000
      },  // int_core_slave_x1_y0_sam_idx
      '{
          idx: 57,
          start_addr: 64'h0000000367000000,
          end_addr: 64'h0000000368000000
      },  // int_core_slave_x0_y7_sam_idx
      '{
          idx: 56,
          start_addr: 64'h0000000366000000,
          end_addr: 64'h0000000367000000
      },  // int_core_slave_x0_y6_sam_idx
      '{
          idx: 55,
          start_addr: 64'h0000000365000000,
          end_addr: 64'h0000000366000000
      },  // int_core_slave_x0_y5_sam_idx
      '{
          idx: 54,
          start_addr: 64'h0000000364000000,
          end_addr: 64'h0000000365000000
      },  // int_core_slave_x0_y4_sam_idx
      '{
          idx: 53,
          start_addr: 64'h0000000363000000,
          end_addr: 64'h0000000364000000
      },  // int_core_slave_x0_y3_sam_idx
      '{
          idx: 52,
          start_addr: 64'h0000000362000000,
          end_addr: 64'h0000000363000000
      },  // int_core_slave_x0_y2_sam_idx
      '{
          idx: 51,
          start_addr: 64'h0000000361000000,
          end_addr: 64'h0000000362000000
      },  // int_core_slave_x0_y1_sam_idx
      '{
          idx: 50,
          start_addr: 64'h0000000360000000,
          end_addr: 64'h0000000361000000
      },  // int_core_slave_x0_y0_sam_idx
      '{
          idx: 49,
          start_addr: 64'h0000000000000000,
          end_addr: 64'h0000000200000000
      },  // d2d1_slave_sam_idx
      '{
          idx: 48,
          start_addr: 64'h0000000200000000,
          end_addr: 64'h0000000300000000
      },  // d2d0_slave_sam_idx
      '{
          idx: 47,
          start_addr: 64'h0000000328000000,
          end_addr: 64'h0000000328001000
      },  // llc_cfg_slave_sam_idx
      '{
          idx: 46,
          start_addr: 64'h0000000327000000,
          end_addr: 64'h0000000327001000
      },  // d2d1_cfg_slave_sam_idx
      '{
          idx: 45,
          start_addr: 64'h0000000326000000,
          end_addr: 64'h0000000326001000
      },  // d2d0_cfg_slave_sam_idx
      '{
          idx: 44,
          start_addr: 64'h0000000325000000,
          end_addr: 64'h0000000325001000
      },  // sl_cfg_slave_sam_idx
      '{
          idx: 43,
          start_addr: 64'h0000000320000000,
          end_addr: 64'h0000000320001000
      },  // sys_dco_slave_sam_idx
      '{
          idx: 42,
          start_addr: 64'h0000000318000000,
          end_addr: 64'h0000000318001000
      },  // timer_slave_sam_idx
      '{
          idx: 41,
          start_addr: 64'h0000000310000000,
          end_addr: 64'h0000000310001000
      },  // uart_slave_sam_idx
      '{
          idx: 40,
          start_addr: 64'h000000030c000000,
          end_addr: 64'h000000030fffffff
      },  // plic_slave_sam_idx
      '{
          idx: 39,
          start_addr: 64'h0000000302000000,
          end_addr: 64'h00000003020c0000
      },  // clint_slave_sam_idx
      '{
          idx: 38,
          start_addr: 64'h0000000300000000,
          end_addr: 64'h0000000300001000
      },  // dm_slave_sam_idx
      '{
          idx: 37,
          start_addr: 64'h0000000300010000,
          end_addr: 64'h0000000300020000
      },  // rom_slave_sam_idx
      '{
          idx: 36,
          start_addr: 64'h0000000380000000,
          end_addr: 64'h0000000400000000
      }  // llc_slave_sam_idx

  };

  localparam route_cfg_t RouteCfg = '{
      RouteAlgo: IdTable,
      UseIdTable: 1'b1,
      XYAddrOffsetX: 0,
      XYAddrOffsetY: 0,
      IdAddrOffset: 0,
      NumSamRules: 56,
      NumRoutes: 1
  };


  typedef logic [63:0] mst_axi_addr_t;
  typedef logic [63:0] mst_axi_data_t;
  typedef logic [7:0] mst_axi_strb_t;
  typedef logic [3:0] mst_axi_id_t;
  typedef logic [0:0] mst_axi_user_t;
  `AXI_TYPEDEF_ALL_CT(mst_axi, mst_axi_req_t, mst_axi_rsp_t, mst_axi_addr_t, mst_axi_id_t,
                      mst_axi_data_t, mst_axi_strb_t, mst_axi_user_t)


  typedef logic [63:0] slv_axi_addr_t;
  typedef logic [63:0] slv_axi_data_t;
  typedef logic [7:0] slv_axi_strb_t;
  typedef logic [3:0] slv_axi_id_t;
  typedef logic [0:0] slv_axi_user_t;
  `AXI_TYPEDEF_ALL_CT(slv_axi, slv_axi_req_t, slv_axi_rsp_t, slv_axi_addr_t, slv_axi_id_t,
                      slv_axi_data_t, slv_axi_strb_t, slv_axi_user_t)



  `FLOO_TYPEDEF_HDR_T(hdr_t, id_t, id_t, axi_ch_e, rob_idx_t)
  localparam axi_cfg_t AxiCfg = '{
      AddrWidth: 64,
      DataWidth: 64,
      UserWidth: 1,
      InIdWidth: 4,
      OutIdWidth: 4
  };
  `FLOO_TYPEDEF_AXI_CHAN_ALL(axi, req, rsp, mst_axi, AxiCfg, hdr_t)

  `FLOO_TYPEDEF_AXI_LINK_ALL(req, rsp, req, rsp)


endpackage
