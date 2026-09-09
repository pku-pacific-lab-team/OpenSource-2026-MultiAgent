// Copyright 2025-2026 School of Integrated Circuits, Peking University
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// https://solderpad.org/licenses/SHL-2.1/
//
//------------------------------------------------------------------------------
// Description: DCO configuration and clock-gating registers
// Author:      Zhantong Zhu <zhu_20021122@stu.pku.edu.cn>
// Modifier:    Mingxuan Li <siris-lmx@stu.pku.edu.cn>
//------------------------------------------------------------------------------
// Register map (byte offsets inside the 4 KiB window, 64-bit data):
//   0x000  coarse ring-oscillator control       [5:0]   reset 63
//   0x008  fine ring-oscillator control         [5:0]   reset 63
//   0x010  test-divider selection               [2:0]   reset 4
//   0x018  system frequency selection           [1:0]   reset 3
//   0x020  clock gating: INT cores [31:0], FP cores [39:32], speculative
//          prefill unit [40], auxiliary accelerator slot [44]      reset 0
// Writes honour the byte strobes; unimplemented offsets return an error.
//------------------------------------------------------------------------------

module dco_regs #(
	parameter type reg_req_t = logic,
	parameter type reg_rsp_t = logic
)(
	input  logic       		clk_i									,
	input  logic       		rstn_i								,
	output logic [ 6-1:0] cc_sel_o							,
	output logic [ 6-1:0] fc_sel_o							,
	output logic [ 3-1:0] div_sel_o							,
	output logic [ 2-1:0] freq_sel_o						,
	output logic [32-1:0] int_core_clk_en_o			,
	output logic [ 8-1:0] fp_core_clk_en_o			,
	output logic          sp_core_clk_en_o			,
	output logic          aux_slot_clk_en_o			,

	// Bus Interface
	input  reg_req_t 			req_i									,
	output reg_rsp_t 			rsp_o
);

	logic [6-1:0] 	cc_sel_d							, cc_sel_q							;
	logic [6-1:0] 	fc_sel_d							, fc_sel_q							;
	logic [3-1:0] 	div_sel_d							, div_sel_q							;
	logic [2-1:0] 	freq_sel_d						, freq_sel_q						;
	logic [32-1:0] 	int_core_clk_en_d			, int_core_clk_en_q			;
	logic [ 8-1:0] 	fp_core_clk_en_d			, fp_core_clk_en_q			;
	logic          	sp_core_clk_en_d			, sp_core_clk_en_q			;
	logic          	aux_slot_clk_en_d			, aux_slot_clk_en_q			;

  // reg_bus carries one write strobe per byte. Preserve every unselected byte.
  logic [63:0] write_mask;
  for (genvar byte_idx = 0; byte_idx < 8; byte_idx++) begin : gen_write_mask
    assign write_mask[8*byte_idx +: 8] = {8{req_i.wstrb[byte_idx]}};
  end

	always_comb begin
		rsp_o.ready  					= 1'b1									;
		rsp_o.error  					= 1'b0									;
		rsp_o.rdata  					= '0										;
		cc_sel_d     					= cc_sel_q							;
		fc_sel_d     					= fc_sel_q							;
		div_sel_d    					= div_sel_q							;
		freq_sel_d   					= freq_sel_q						;
		int_core_clk_en_d    	= int_core_clk_en_q			;
		fp_core_clk_en_d     	= fp_core_clk_en_q			;
		sp_core_clk_en_d     	= sp_core_clk_en_q			;
		aux_slot_clk_en_d    	= aux_slot_clk_en_q			;

		if (req_i.valid) begin
			if (req_i.write) begin
				unique case (req_i.addr[12-1:0])
					12'h000: begin
						cc_sel_d = (cc_sel_q & ~write_mask[6-1:0]) |
            (req_i.wdata[6-1:0] & write_mask[6-1:0]);
					end
					12'h008: begin
						fc_sel_d = (fc_sel_q & ~write_mask[6-1:0]) |
            (req_i.wdata[6-1:0] & write_mask[6-1:0]);
					end
					12'h010: begin
						div_sel_d = (div_sel_q & ~write_mask[3-1:0]) |
            (req_i.wdata[3-1:0] & write_mask[3-1:0]);
					end
					12'h018: begin
						freq_sel_d = (freq_sel_q & ~write_mask[2-1:0]) |
            (req_i.wdata[2-1:0] & write_mask[2-1:0]);
					end
					12'h020: begin
						int_core_clk_en_d = (int_core_clk_en_q & ~write_mask[32-1:0]) |
            (req_i.wdata[32-1:0] & write_mask[32-1:0]);
						fp_core_clk_en_d = (fp_core_clk_en_q & ~write_mask[40-1:32]) |
            (req_i.wdata[40-1:32] & write_mask[40-1:32]);
						sp_core_clk_en_d = (sp_core_clk_en_q & ~write_mask[40]) |
            (req_i.wdata[40] & write_mask[40]);
						aux_slot_clk_en_d = (aux_slot_clk_en_q & ~write_mask[44]) |
            (req_i.wdata[44] & write_mask[44]);
					end
					default: rsp_o.error = 1'b1;
				endcase
			end
			else begin
				unique case (req_i.addr[12-1:0])
					12'h000: rsp_o.rdata = {32'b0, 26'b0, cc_sel_q};
					12'h008: rsp_o.rdata = {32'b0, 26'b0, fc_sel_q};
					12'h010: rsp_o.rdata = {32'b0, 29'b0, div_sel_q};
					12'h018: rsp_o.rdata = {32'b0, 30'b0, freq_sel_q};
					12'h020: rsp_o.rdata = {16'b0, 3'b0, aux_slot_clk_en_q, 3'b0, sp_core_clk_en_q, fp_core_clk_en_q, int_core_clk_en_q};
					default: rsp_o.error = 1'b1;
				endcase
			end
		end
	end
	assign cc_sel_o   					= cc_sel_q							;
	assign fc_sel_o   					= fc_sel_q							;
	assign div_sel_o  					= div_sel_q							;
	assign freq_sel_o 					= freq_sel_q						;
	assign int_core_clk_en_o    = int_core_clk_en_q    	;
	assign fp_core_clk_en_o     = fp_core_clk_en_q     	;
	assign sp_core_clk_en_o     = sp_core_clk_en_q     	;
	assign aux_slot_clk_en_o    = aux_slot_clk_en_q    	;


	always_ff @(posedge clk_i or negedge rstn_i) begin
		// Initialization for DCO
		if (~rstn_i) begin
			cc_sel_q 							<= 6'b111_111	;
			fc_sel_q 							<= 6'b111_111	;
			div_sel_q 						<= 3'b100			;
			freq_sel_q 						<= 2'b11			;
			int_core_clk_en_q     <= '0					;
			fp_core_clk_en_q      <= '0					;
			sp_core_clk_en_q      <= '0					;
			aux_slot_clk_en_q     <= '0					;
		end
		else begin
			cc_sel_q 							<= cc_sel_d							;
			fc_sel_q 							<= fc_sel_d							;
			div_sel_q 						<= div_sel_d						;
			freq_sel_q 						<= freq_sel_d						;
			int_core_clk_en_q     <= int_core_clk_en_d   	;
			fp_core_clk_en_q      <= fp_core_clk_en_d    	;
			sp_core_clk_en_q      <= sp_core_clk_en_d    	;
			aux_slot_clk_en_q     <= aux_slot_clk_en_d   	;
		end
	end

endmodule
