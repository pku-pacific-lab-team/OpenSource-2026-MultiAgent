// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
//////////////////////////////////////////////////////////////////////////////////
// Description: SoC Top Module with I/O Pads
// Author:      Mingxuan Li <siris-lmx@stu.pku.edu.cn> [Peking University]
// Acknowledge: VSCode Copilot + Gemini-3-Pro Agent
//////////////////////////////////////////////////////////////////////////////////

module soc_noc_top (
`ifdef SIM
	input   wire    sys_clk_i             ,
`endif

	inout   wire    ext_clk_pad_i         ,
	inout   wire    rstn_pad_i            ,
  inout   wire    boot_sel_pad_i        ,
  inout   wire    chiplet_sel0_pad_i    ,
  inout   wire    chiplet_sel1_pad_i    ,
	inout   wire    clk_led_pad_o         ,

	// JTAG
	inout   wire    jtag_tck_pad_i        ,
	inout   wire    jtag_tms_pad_i        ,
	inout   wire    jtag_tdi_pad_i        ,
	inout   wire    jtag_tdo_pad_o        ,

	// UART
	inout   wire    uart_rx_pad_i         ,
	inout   wire    uart_tx_pad_o         ,

	// System DCO Control
	inout   wire    sys_dco_en_pad_i      ,
	inout   wire    sys_clk_sel_pad_i     ,
	inout   wire    sys_dco_clk_pad_o     ,

	// FPGA Serial Link
	inout   wire    sl_clk_rx_pad_i       ,
	inout   wire    sl_ddr_rx0_pad_i      ,
	inout   wire    sl_ddr_rx1_pad_i      ,
	inout   wire    sl_clk_tx_pad_o       ,
	inout   wire    sl_ddr_tx0_pad_o      ,
	inout   wire    sl_ddr_tx1_pad_o      ,

	// Die-to-Die Interface #0
	inout   wire    d2d0_clk_rx_pad_i     ,
	inout   wire    d2d0_ddr_rx0_pad_i    ,
	inout   wire    d2d0_ddr_rx1_pad_i    ,
	inout   wire    d2d0_clk_tx_pad_o     ,
	inout   wire    d2d0_ddr_tx0_pad_o    ,
	inout   wire    d2d0_ddr_tx1_pad_o    ,

  // Die-to-Die Interface #1
	inout   wire    d2d1_clk_rx_pad_i     ,
	inout   wire    d2d1_ddr_rx0_pad_i    ,
	inout   wire    d2d1_ddr_rx1_pad_i    ,
	inout   wire    d2d1_clk_tx_pad_o     ,
	inout   wire    d2d1_ddr_tx0_pad_o    ,
	inout   wire    d2d1_ddr_tx1_pad_o		
);

	logic       ext_clk_i       ;
	logic       rstn_i          ;
  logic [1:0] soc_id_i        ;
  logic       boot_sel_i      ;
	logic       clk_led_o       ;
	logic       jtag_tck_i      ;
	logic       jtag_tms_i      ;
	logic       jtag_tdi_i      ;
	logic       jtag_tdo_o      ;
	logic       uart_rx_i       ;
	logic       uart_tx_o       ;
	logic       sys_dco_en_i    ;
	logic       sys_clk_sel_i   ;
	logic       sys_dco_clk_o   ;
  logic       sl_clk_rx_i     ;
  logic [1:0] sl_data_rx_i    ;
  logic       sl_clk_tx_o     ;
  logic [1:0] sl_data_tx_o    ;
  logic       d2d0_clk_rx_i   ;
  logic [1:0] d2d0_data_rx_i  ;
  logic       d2d0_clk_tx_o   ;
  logic [1:0] d2d0_data_tx_o  ;
  logic       d2d1_clk_rx_i   ;
  logic [1:0] d2d1_data_rx_i  ;
  logic       d2d1_clk_tx_o   ;
  logic [1:0] d2d1_data_tx_o  ;


	soc_noc soc_noc_inst (
`ifdef SIM
		.sys_clk_i      ,
`endif
		.ext_clk_i      ,
		.rstn_i         ,
    .soc_id_i       ,
    .boot_sel_i     ,
		.clk_led_o      ,
		.jtag_tck_i     ,
		.jtag_tms_i     ,
		.jtag_tdi_i     ,
		.jtag_tdo_o     ,
		.uart_rx_i      ,
		.uart_tx_o      ,
		.sys_dco_en_i   ,
		.sys_clk_sel_i  ,
		.sys_dco_clk_o  ,
    .sl_clk_rx_i    ,
    .sl_data_rx_i   ,
    .sl_clk_tx_o    ,
    .sl_data_tx_o   ,
    .d2d0_clk_rx_i  ,
    .d2d0_data_rx_i ,
    .d2d0_clk_tx_o  ,
    .d2d0_data_tx_o ,
    .d2d1_clk_rx_i  ,
    .d2d1_data_rx_i ,
    .d2d1_clk_tx_o  ,
    .d2d1_data_tx_o
	);

	// refer to src/tech_specific/signal_io_pad.v for port definition
	retention_cell_vertical retention_cell_inst (
		.rte_i  ( 1'b0 )
	);

	signal_io_pad_horizontal jtag_tck_pad_inst (
		.OEN    ( 1'b1               ),
		.IN     ( 1'b0               ),
		.OUT    ( jtag_tck_i         ),
		.PAD    ( jtag_tck_pad_i     )
	);

	signal_io_pad_horizontal jtag_tms_pad_inst (
		.OEN    ( 1'b1               ),
		.IN     ( 1'b0               ),
		.OUT    ( jtag_tms_i         ),
		.PAD    ( jtag_tms_pad_i     )
	);

	signal_io_pad_horizontal jtag_tdi_pad_inst (
		.OEN    ( 1'b1               ),
		.IN     ( 1'b0               ),
		.OUT    ( jtag_tdi_i         ),
		.PAD    ( jtag_tdi_pad_i     )
	);

	signal_io_pad_horizontal jtag_tdo_pad_inst (
		.OEN    ( 1'b0               ),
		.IN     ( jtag_tdo_o         ),
		.OUT    ( /*unused*/         ),
		.PAD    ( jtag_tdo_pad_o     )
	);

	signal_io_pad_horizontal uart_rx_pad_inst (
		.OEN    ( 1'b1               ),
		.IN     ( 1'b0               ),
		.OUT    ( uart_rx_i          ),
		.PAD    ( uart_rx_pad_i      )
	);

	signal_io_pad_horizontal uart_tx_pad_inst (
		.OEN    ( 1'b0               ),
		.IN     ( uart_tx_o          ),
		.OUT    ( /*unused*/         ),
		.PAD    ( uart_tx_pad_o      )
	);

  signal_io_pad_horizontal d2d0_ddr_rx1_pad_inst (
    .OEN    ( 1'b1                ),
    .IN     ( 1'b0                ),
    .OUT    ( d2d0_data_rx_i[1]   ),
    .PAD    ( d2d0_ddr_rx1_pad_i  )
  );

  signal_io_pad_horizontal d2d1_clk_rx_pad_inst (
    .OEN    ( 1'b1                ),
    .IN     ( 1'b0                ),
    .OUT    ( d2d1_clk_rx_i       ),
    .PAD    ( d2d1_clk_rx_pad_i   )
  );


  signal_io_pad_horizontal d2d1_ddr_rx0_pad_inst (
    .OEN    ( 1'b1                ),
    .IN     ( 1'b0                ),
    .OUT    ( d2d1_data_rx_i[0]   ),
    .PAD    ( d2d1_ddr_rx0_pad_i  )
  );

  signal_io_pad_horizontal d2d1_ddr_rx1_pad_inst (
    .OEN    ( 1'b1                ),
    .IN     ( 1'b0                ),
    .OUT    ( d2d1_data_rx_i[1]   ),
    .PAD    ( d2d1_ddr_rx1_pad_i  )
  );

  signal_io_pad_horizontal d2d0_ddr_tx1_pad_inst (
    .OEN    ( 1'b0                ),
    .IN     ( d2d0_data_tx_o[1]   ),
    .OUT    (  /*unused*/         ),
    .PAD    ( d2d0_ddr_tx1_pad_o  )
  );

  signal_io_pad_horizontal d2d1_clk_tx_pad_inst (
    .OEN    ( 1'b0                ),
    .IN     ( d2d1_clk_tx_o       ),
    .OUT    (  /*unused*/         ),
    .PAD    ( d2d1_clk_tx_pad_o   )
  );

  signal_io_pad_horizontal d2d1_ddr_tx0_pad_inst (
    .OEN    ( 1'b0                ),
    .IN     ( d2d1_data_tx_o[0]   ),
    .OUT    ( /*unused*/          ),
    .PAD    ( d2d1_ddr_tx0_pad_o  )
  );

  signal_io_pad_horizontal d2d1_ddr_tx1_pad_inst (
    .OEN    ( 1'b0                ),
    .IN     ( d2d1_data_tx_o[1]   ),
    .OUT    ( /*unused*/          ),
    .PAD    ( d2d1_ddr_tx1_pad_o  )
  );

	signal_io_pad_vertical ext_clk_pad_inst (
		.OEN    ( 1'b1               ),
		.IN     ( 1'b0               ),
		.OUT    ( ext_clk_i          ),
		.PAD    ( ext_clk_pad_i      )
	);

	signal_io_pad_vertical rstn_pad_inst (
		.OEN    ( 1'b1               ),
		.IN     ( 1'b0               ),
		.OUT    ( rstn_i             ),
		.PAD    ( rstn_pad_i         )
	);

	signal_io_pad_vertical boot_sel_pad_inst (
		.OEN    ( 1'b1               ),
		.IN     ( 1'b0               ),
		.OUT    ( boot_sel_i         ),
		.PAD    ( boot_sel_pad_i     )
	);

	signal_io_pad_vertical chiplet_sel0_pad_inst (
		.OEN    ( 1'b1               ),
		.IN     ( 1'b0               ),
		.OUT    ( soc_id_i[0]        ),
		.PAD    ( chiplet_sel0_pad_i )
	);

	signal_io_pad_vertical chiplet_sel1_pad_inst (
		.OEN    ( 1'b1               ),
		.IN     ( 1'b0               ),
		.OUT    ( soc_id_i[1]        ),
		.PAD    ( chiplet_sel1_pad_i )
	);

	signal_io_pad_vertical clk_led_pad_inst (
		.OEN    ( 1'b0               ),
		.IN     ( clk_led_o          ),
		.OUT    ( /*unused*/         ),
		.PAD    ( clk_led_pad_o      )
	);

	signal_io_pad_vertical sys_dco_en_pad_inst (
		.OEN    ( 1'b1               ),
		.IN     ( 1'b0               ),
		.OUT    ( sys_dco_en_i       ),
		.PAD    ( sys_dco_en_pad_i   )
	);

	signal_io_pad_vertical sys_clk_sel_pad_inst (
		.OEN    ( 1'b1               ),
		.IN     ( 1'b0               ),
		.OUT    ( sys_clk_sel_i      ),
		.PAD    ( sys_clk_sel_pad_i  )
	);

	signal_io_pad_vertical sys_dco_clk_pad_inst (
		.OEN    ( 1'b0               ),
		.IN     ( sys_dco_clk_o      ),
		.OUT    ( /*unused*/         ),
		.PAD    ( sys_dco_clk_pad_o  )
	);

  signal_io_pad_vertical sl_clk_rx_pad_inst (
    .OEN    ( 1'b1               ),
    .IN     ( 1'b0               ),
    .OUT    ( sl_clk_rx_i        ),
    .PAD    ( sl_clk_rx_pad_i    )
  );

  signal_io_pad_vertical sl_ddr_rx0_pad_inst (
    .OEN    ( 1'b1               ),
    .IN     ( 1'b0               ),
    .OUT    ( sl_data_rx_i[0]    ),
    .PAD    ( sl_ddr_rx0_pad_i   )
  );

  signal_io_pad_vertical sl_ddr_rx1_pad_inst (
    .OEN    ( 1'b1               ),
    .IN     ( 1'b0               ),
    .OUT    ( sl_data_rx_i[1]    ),
    .PAD    ( sl_ddr_rx1_pad_i   )
  );

  signal_io_pad_vertical sl_clk_tx_pad_inst (
    .OEN    ( 1'b0               ),
    .IN     ( sl_clk_tx_o        ),
    .OUT    ( /*unused*/         ),
    .PAD    ( sl_clk_tx_pad_o    )
  );

  signal_io_pad_vertical sl_ddr_tx0_pad_inst (
    .OEN    ( 1'b0               ),
    .IN     ( sl_data_tx_o[0]    ),
    .OUT    ( /*unused*/         ),
    .PAD    ( sl_ddr_tx0_pad_o   )
  );

  signal_io_pad_vertical sl_ddr_tx1_pad_inst (
    .OEN    ( 1'b0               ),
    .IN     ( sl_data_tx_o[1]    ),
    .OUT    ( /*unused*/         ),
    .PAD    ( sl_ddr_tx1_pad_o   )
  );

  signal_io_pad_vertical d2d0_clk_tx_pad_inst (
    .OEN    ( 1'b0               ),
    .IN     ( d2d0_clk_tx_o      ),
    .OUT    ( /*unused*/         ),
    .PAD    ( d2d0_clk_tx_pad_o  )
  );

  signal_io_pad_vertical d2d0_ddr_tx0_pad_inst (
    .OEN    ( 1'b0               ),
    .IN     ( d2d0_data_tx_o[0]  ),
    .OUT    ( /*unused*/         ),
    .PAD    ( d2d0_ddr_tx0_pad_o )
  );

  signal_io_pad_vertical d2d0_clk_rx_pad_inst (
    .OEN    ( 1'b1               ),
    .IN     ( 1'b0               ),
    .OUT    ( d2d0_clk_rx_i      ),
    .PAD    ( d2d0_clk_rx_pad_i  )
  );

  signal_io_pad_vertical d2d0_ddr_rx0_pad_inst (
    .OEN    ( 1'b1               ),
    .IN     ( 1'b0               ),
    .OUT    ( d2d0_data_rx_i[0]  ),
    .PAD    ( d2d0_ddr_rx0_pad_i )
  );

endmodule
