// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
// -----------------------------------------------------------------------------
// Simple 1D iDMA top-level module
// Register-controlled, single-dimension DMA (no midend)
// -----------------------------------------------------------------------------
// Authors:
// - Renati Tuerhong  <renati0423@gmail.com>
// Modified by Mingxuan Li <siris-lmx@stu.pku.edu.cn> [Peking University]

`include "axi/typedef.svh"
`include "idma/typedef.svh"

module idma_top #(
	parameter int unsigned AxiDataWidth    = 32'd0,
	parameter int unsigned AxiAddrWidth    = 32'd0,
	parameter int unsigned AxiUserWidth    = 32'd0,
	parameter int unsigned AxiIdWidth      = 32'd0,
	parameter int unsigned NumAxInFlight   = 32'd4,
	parameter int unsigned NumChannels     = 32'd1,
	parameter type         axi_req_t       = logic,
	parameter type         axi_res_t       = logic
) (
	input  logic                          clk_i					,
	input  logic                          rst_ni				,
	input  logic                          testmode_i		,

	// AXI4 Master interface
	output axi_req_t    [NumChannels-1:0] axi_req_o			,
	input  axi_res_t    [NumChannels-1:0] axi_res_i			,

	// Control register interface
	input  logic                      axi_req_i       	,
	input  logic                      axi_write_en_i  	,
	input  logic [AxiAddrWidth-1:0]   axi_addr_i      	,
	input  logic [AxiDataWidth-1:0]   axi_wdata_i     	,
	output logic [AxiDataWidth-1:0]   axi_rdata_o     	,
	output logic                      axi_rvalid_o    	,

	// Direct interface to internal accelerator
	input  logic [AxiAddrWidth-1:0]   dma_length_i    	,
	input  logic [AxiAddrWidth-1:0]   dma_src_offset_i	,
	input  logic [AxiAddrWidth-1:0]   dma_dst_offset_i	,
	input  logic                      dma_run_i    			,
	output logic                      dma_ready_o       ,
  output logic                      dma_busy_o
);

	// constants
	localparam int unsigned TfIdWidth    = 32'd32;
	localparam int unsigned TFLenWidth   = AxiAddrWidth;
	localparam int unsigned RepWidth     = 32'd32;
	localparam int unsigned NumDim       = 32'd2;
	localparam int unsigned BufferDepth  = 32'd32;

	// derived constants and types
	localparam int unsigned StrbWidth    = AxiDataWidth / 32'd8;
	localparam int unsigned OffsetWidth  = $clog2(StrbWidth);
	localparam type addr_t               = logic[AxiAddrWidth-1:0];
	localparam type data_t               = logic[AxiDataWidth-1:0];
	localparam type strb_t               = logic[StrbWidth-1:0];
	localparam type user_t               = logic[AxiUserWidth-1:0];
	localparam type id_t                 = logic[AxiIdWidth-1:0];
	localparam type tf_len_t             = logic[TFLenWidth-1:0];
	localparam type offset_t             = logic[OffsetWidth-1:0];
	localparam type strides_t            = logic[RepWidth-1:0];
	localparam type reps_t               = logic[RepWidth-1:0];
	localparam type tf_id_t              = logic[TfIdWidth-1:0];

	`AXI_TYPEDEF_AR_CHAN_T(axi_ar_chan_t, addr_t, id_t, user_t)
	`AXI_TYPEDEF_AW_CHAN_T(axi_aw_chan_t, addr_t, id_t, user_t)

	// iDMA backend types
	`IDMA_TYPEDEF_OPTIONS_T(options_t, id_t)
	`IDMA_TYPEDEF_REQ_T(idma_req_t, tf_len_t, addr_t, options_t, user_t)
	`IDMA_TYPEDEF_ERR_PAYLOAD_T(err_payload_t, addr_t)
	`IDMA_TYPEDEF_RSP_T(idma_rsp_t, err_payload_t)

	// iDMA ND
	`IDMA_TYPEDEF_D_REQ_T(idma_d_req_t, reps_t, strides_t)
	`IDMA_TYPEDEF_ND_REQ_T(idma_nd_req_t, idma_req_t, idma_d_req_t)

	// AXI meta channels
	typedef struct packed {
		axi_ar_chan_t ar_chan;
	} axi_read_meta_channel_t;

	typedef struct packed {
		axi_read_meta_channel_t axi;
	} read_meta_channel_t;

	typedef struct packed {
		axi_aw_chan_t aw_chan;
	} axi_write_meta_channel_t;

	typedef struct packed {
		axi_write_meta_channel_t axi;
	} write_meta_channel_t;
	// ----------------------------------------
	// Frontend connections
	// ----------------------------------------
	idma_req_t  dma_req;
	logic       dma_req_valid, dma_req_ready;

	// ----------------------------------------
	// Frontend instantiation
	// ----------------------------------------
	idma_frontend #(
		.AxiDataWidth     ( AxiDataWidth ),
		.AxiAddrWidth     ( AxiAddrWidth ),
		.AxiUserWidth     ( AxiUserWidth ),
		.AxiIdWidth       ( AxiIdWidth   ),
		.dma_req_t        ( idma_req_t )
	)  i_idma_reg64_1d (
		.clk_i						,
		.rst_ni						,

    .dma_length_i   	,
		.dma_src_offset_i ,
		.dma_dst_offset_i ,
    .dma_run_i      	,
    .dma_ready_o    	,
		.axi_req_i      	,
		.axi_write_en_i 	,
		.axi_addr_i     	,
		.axi_wdata_i    	,
		.axi_rdata_o    	,
		.axi_rvalid_o   	,

		.dma_req_o      (dma_req),
		.req_valid_o    (dma_req_valid),
		.req_ready_i    (dma_req_ready)
	);

	// ----------------------------------------
	// Backend instantiation
	// ----------------------------------------
	idma_rsp_t dma_rsp;
  idma_pkg::idma_busy_t dma_busy;
	logic      dma_rsp_valid, dma_rsp_ready;
	axi_req_t   axi_read_req,axi_write_req;
	axi_res_t   axi_read_rsp,axi_write_rsp;

	idma_backend_rw_axi #(
		.DataWidth            ( AxiDataWidth                ),
		.AddrWidth            ( AxiAddrWidth                ),
		.UserWidth            ( AxiUserWidth                ),
		.AxiIdWidth           ( AxiIdWidth                  ),
		.NumAxInFlight        ( NumAxInFlight               ),
		.BufferDepth          ( BufferDepth                 ),
		.TFLenWidth           ( TFLenWidth                  ),
		.MemSysDepth          ( 16                          ),
		.CombinedShifter      ( 1'b1                        ),
		.RAWCouplingAvail     ( 1'b1                        ),
		.MaskInvalidData      ( 1'b0                        ),
		.HardwareLegalizer    ( 1'b1                        ),
		.RejectZeroTransfers  ( 1'b1                        ),
		.ErrorCap             ( idma_pkg::NO_ERROR_HANDLING ),
		.PrintFifoInfo        ( 1'b0                        ),
		.idma_req_t           ( idma_req_t                  ),
		.idma_rsp_t           ( idma_rsp_t                  ),
		.idma_eh_req_t        ( idma_pkg::idma_eh_req_t     ),
		.idma_busy_t          ( idma_pkg::idma_busy_t       ),
		.axi_req_t            ( axi_req_t                   ),
		.axi_rsp_t            ( axi_res_t                   ),
		.read_meta_channel_t  ( read_meta_channel_t         ),
		.write_meta_channel_t ( write_meta_channel_t        )
	) i_idma_backend_rw_axi (
		.clk_i,
		.rst_ni,
		.testmode_i,
		.idma_req_i      ( dma_req        ),
		.req_valid_i     ( dma_req_valid  ),
		.req_ready_o     ( dma_req_ready  ),
		.idma_rsp_o      ( dma_rsp        ),
		.rsp_valid_o     ( dma_rsp_valid  ),
		.rsp_ready_i     ( 1'b1           ),
		.idma_eh_req_i   ( '0                 ),
		.eh_req_valid_i  ( 1'b0               ),
		.eh_req_ready_o  ( /* NC */           ),
		.axi_read_req_o  ( axi_read_req    ),
		.axi_read_rsp_i  ( axi_read_rsp    ),
		.axi_write_req_o ( axi_write_req   ),
		.axi_write_rsp_i ( axi_write_rsp   ),
		.busy_o          ( dma_busy        )
	);

  assign dma_busy_o = |dma_busy;

	axi_rw_join #(
		.axi_req_t  ( axi_req_t ),
		.axi_resp_t ( axi_res_t )
	) i_axi_rw_join (
		.clk_i,
		.rst_ni,
		.slv_read_req_i   ( axi_read_req   ),
		.slv_read_resp_o  ( axi_read_rsp   ),
		.slv_write_req_i  ( axi_write_req  ),
		.slv_write_resp_o ( axi_write_rsp  ),
		.mst_req_o        ( axi_req_o      ),
		.mst_resp_i       ( axi_res_i      )
	);

endmodule
