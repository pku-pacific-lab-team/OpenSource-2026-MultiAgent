///////////////////////////////////////////////////////////////////////////////
// Description:  RTL Source Filelist
// Author:       Mingxuan Li <siris-lmx@stu.pku.edu.cn> [Peking University]
// Acknowledge:  Zhantong Zhu [Peking University]
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// Variable {SRC_DIR} is defined in config/global_config.tcl,
// default ${SRC_DIR} == src/
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// Include & Package
///////////////////////////////////////////////////////////////////////////////

+incdir+${SRC_DIR}/include

// WARNING: ORDER is important !!!
${SRC_DIR}/misc_common/cb_filter_pkg.sv
${SRC_DIR}/misc_common/cdc_reset_ctrlr_pkg.sv
${SRC_DIR}/misc_common/cf_math_pkg.sv
${SRC_DIR}/misc_common/ecc_pkg.sv
${SRC_DIR}/cpu_cva6/package/config_pkg.sv
${SRC_DIR}/cpu_cva6/package/cv64a6_config_pkg.sv
${SRC_DIR}/cpu_cva6/package/riscv_pkg.sv
${SRC_DIR}/cpu_cva6/package/ariane_pkg.sv
${SRC_DIR}/cpu_cva6/package/wt_cache_pkg.sv
${SRC_DIR}/cpu_cva6/package/std_cache_pkg.sv
${SRC_DIR}/cpu_cva6/package/instr_tracer_pkg.sv
${SRC_DIR}/cpu_cva6/package/fpnew_pkg.sv
${SRC_DIR}/cpu_cva6/package/acc_pkg.sv
${SRC_DIR}/cpu_cva6/package/cvxif_pkg.sv
${SRC_DIR}/cpu_cva6/package/cvxif_instr_pkg.sv
${SRC_DIR}/soc_axi/axi_bus/axi_pkg.sv
${SRC_DIR}/soc_axi/axi_bus/ariane_axi_pkg.sv
${SRC_DIR}/soc_axi/axi_llc/axi_llc_pkg.sv
${SRC_DIR}/soc_axi/axi_llc/axi_llc_reg_pkg.sv
${SRC_DIR}/soc_axi/serial_link/apb_pkg.sv
${SRC_DIR}/soc_axi/serial_link/slink_pkg.sv
${SRC_DIR}/soc_axi/serial_link/regs/slink_reg_pkg.sv
${SRC_DIR}/soc_axi/riscv-dbg/dm_pkg.sv
${SRC_DIR}/floo_noc/floo_pkg.sv
${SRC_DIR}/idma/idma_pkg.sv
${SRC_DIR}/floo_agent_noc_pkg.sv
${SRC_DIR}/soc_pkg.sv


///////////////////////////////////////////////////////////////////////////////
// CVA6 CPU Core
///////////////////////////////////////////////////////////////////////////////

${SRC_DIR}/cpu_cva6/cva6.sv

// Floating Point Unit
${SRC_DIR}/cpu_cva6/fpu/fpnew_cast_multi.sv
${SRC_DIR}/cpu_cva6/fpu/fpnew_classifier.sv
${SRC_DIR}/cpu_cva6/fpu/fpnew_divsqrt_multi.sv
${SRC_DIR}/cpu_cva6/fpu/fpnew_fma_multi.sv
${SRC_DIR}/cpu_cva6/fpu/fpnew_fma.sv
${SRC_DIR}/cpu_cva6/fpu/fpnew_noncomp.sv
${SRC_DIR}/cpu_cva6/fpu/fpnew_opgroup_block.sv
${SRC_DIR}/cpu_cva6/fpu/fpnew_opgroup_fmt_slice.sv
${SRC_DIR}/cpu_cva6/fpu/fpnew_opgroup_multifmt_slice.sv
${SRC_DIR}/cpu_cva6/fpu/fpnew_rounding.sv
${SRC_DIR}/cpu_cva6/fpu/fpnew_top.sv
${SRC_DIR}/cpu_cva6/fpu/fpu_div_sqrt_mvp/defs_div_sqrt_mvp.sv
${SRC_DIR}/cpu_cva6/fpu/fpu_div_sqrt_mvp/control_mvp.sv
${SRC_DIR}/cpu_cva6/fpu/fpu_div_sqrt_mvp/div_sqrt_top_mvp.sv
${SRC_DIR}/cpu_cva6/fpu/fpu_div_sqrt_mvp/iteration_div_sqrt_mvp.sv
${SRC_DIR}/cpu_cva6/fpu/fpu_div_sqrt_mvp/norm_div_sqrt_mvp.sv
${SRC_DIR}/cpu_cva6/fpu/fpu_div_sqrt_mvp/nrbd_nrsc_mvp.sv
${SRC_DIR}/cpu_cva6/fpu/fpu_div_sqrt_mvp/preprocess_mvp.sv

// CVXIF
${SRC_DIR}/cpu_cva6/cvxif_fu.sv
${SRC_DIR}/cpu_cva6/cvxif_example/cvxif_example_coprocessor.sv
${SRC_DIR}/cpu_cva6/cvxif_example/instr_decoder.sv

// Top-level Source Files (not necessarily instantiated at the top of the cva6).
${SRC_DIR}/cpu_cva6/alu.sv
${SRC_DIR}/cpu_cva6/fpu_wrap.sv
${SRC_DIR}/cpu_cva6/branch_unit.sv
${SRC_DIR}/cpu_cva6/compressed_decoder.sv
${SRC_DIR}/cpu_cva6/controller.sv
${SRC_DIR}/cpu_cva6/csr_buffer.sv
${SRC_DIR}/cpu_cva6/csr_regfile.sv
${SRC_DIR}/cpu_cva6/decoder.sv
${SRC_DIR}/cpu_cva6/ex_stage.sv
${SRC_DIR}/cpu_cva6/instr_realign.sv
${SRC_DIR}/cpu_cva6/id_stage.sv
${SRC_DIR}/cpu_cva6/issue_read_operands.sv
${SRC_DIR}/cpu_cva6/issue_stage.sv
${SRC_DIR}/cpu_cva6/load_unit.sv
${SRC_DIR}/cpu_cva6/load_store_unit.sv
${SRC_DIR}/cpu_cva6/lsu_bypass.sv
${SRC_DIR}/cpu_cva6/mult.sv
${SRC_DIR}/cpu_cva6/multiplier.sv
${SRC_DIR}/cpu_cva6/serdiv.sv
${SRC_DIR}/cpu_cva6/perf_counters.sv
${SRC_DIR}/cpu_cva6/ariane_regfile_ff.sv
${SRC_DIR}/cpu_cva6/ariane_regfile_fpga.sv
${SRC_DIR}/cpu_cva6/scoreboard.sv
${SRC_DIR}/cpu_cva6/store_buffer.sv
${SRC_DIR}/cpu_cva6/amo_buffer.sv
${SRC_DIR}/cpu_cva6/store_unit.sv
${SRC_DIR}/cpu_cva6/commit_stage.sv
${SRC_DIR}/cpu_cva6/axi_shim.sv
${SRC_DIR}/cpu_cva6/cva6_accel_first_pass_decoder_stub.sv
${SRC_DIR}/cpu_cva6/acc_dispatcher.sv

// Frontend
${SRC_DIR}/cpu_cva6/frontend/btb.sv
${SRC_DIR}/cpu_cva6/frontend/bht.sv
${SRC_DIR}/cpu_cva6/frontend/ras.sv
${SRC_DIR}/cpu_cva6/frontend/instr_scan.sv
${SRC_DIR}/cpu_cva6/frontend/instr_queue.sv
${SRC_DIR}/cpu_cva6/frontend/frontend.sv

// Cache Subsystem
${SRC_DIR}/cpu_cva6/cache_subsystem/wt_dcache_ctrl.sv
${SRC_DIR}/cpu_cva6/cache_subsystem/wt_dcache_mem.sv
${SRC_DIR}/cpu_cva6/cache_subsystem/wt_dcache_missunit.sv
${SRC_DIR}/cpu_cva6/cache_subsystem/wt_dcache_wbuffer.sv
${SRC_DIR}/cpu_cva6/cache_subsystem/wt_dcache.sv
${SRC_DIR}/cpu_cva6/cache_subsystem/cva6_icache.sv
${SRC_DIR}/cpu_cva6/cache_subsystem/wt_cache_subsystem.sv
${SRC_DIR}/cpu_cva6/cache_subsystem/wt_axi_adapter.sv
${SRC_DIR}/cpu_cva6/cache_subsystem/tag_cmp.sv
${SRC_DIR}/cpu_cva6/cache_subsystem/axi_adapter.sv
${SRC_DIR}/cpu_cva6/cache_subsystem/miss_handler.sv
${SRC_DIR}/cpu_cva6/cache_subsystem/cache_ctrl.sv
${SRC_DIR}/cpu_cva6/cache_subsystem/cva6_icache_axi_wrapper.sv
${SRC_DIR}/cpu_cva6/cache_subsystem/std_cache_subsystem.sv
${SRC_DIR}/cpu_cva6/cache_subsystem/std_nbdcache.sv

// Physical Memory Protection
${SRC_DIR}/cpu_cva6/pmp/src/pmp.sv
${SRC_DIR}/cpu_cva6/pmp/src/pmp_entry.sv

// MMU Sv39
${SRC_DIR}/cpu_cva6/mmu_sv39/mmu.sv
${SRC_DIR}/cpu_cva6/mmu_sv39/ptw.sv
${SRC_DIR}/cpu_cva6/mmu_sv39/tlb.sv

// MMU Sv32
${SRC_DIR}/cpu_cva6/mmu_sv32/cva6_mmu_sv32.sv
${SRC_DIR}/cpu_cva6/mmu_sv32/cva6_ptw_sv32.sv
${SRC_DIR}/cpu_cva6/mmu_sv32/cva6_tlb_sv32.sv
${SRC_DIR}/cpu_cva6/mmu_sv32/cva6_shared_tlb_sv32.sv


///////////////////////////////////////////////////////////////////////////////
// NoC
///////////////////////////////////////////////////////////////////////////////

${SRC_DIR}/floo_noc/floo_fifo.sv
${SRC_DIR}/floo_noc/floo_cdc.sv
${SRC_DIR}/floo_noc/floo_route_select.sv
${SRC_DIR}/floo_noc/floo_route_comp.sv
${SRC_DIR}/floo_noc/floo_vc_arbiter.sv
${SRC_DIR}/floo_noc/floo_wormhole_arbiter.sv
${SRC_DIR}/floo_noc/floo_simple_rob.sv
${SRC_DIR}/floo_noc/floo_cut.sv
${SRC_DIR}/floo_noc/floo_meta_buffer.sv
${SRC_DIR}/floo_noc/floo_rob.sv
${SRC_DIR}/floo_noc/floo_rob_wrapper.sv
${SRC_DIR}/floo_noc/floo_nw_join.sv
${SRC_DIR}/floo_noc/floo_router.sv
${SRC_DIR}/floo_noc/floo_axi_chimney.sv
${SRC_DIR}/floo_noc/floo_nw_chimney.sv
${SRC_DIR}/floo_noc/floo_axi_router.sv
${SRC_DIR}/floo_noc/floo_nw_router.sv
${SRC_DIR}/floo_noc/vc_router_util/floo_credit_counter.sv
${SRC_DIR}/floo_noc/vc_router_util/floo_input_fifo.sv
${SRC_DIR}/floo_noc/vc_router_util/floo_input_port.sv
${SRC_DIR}/floo_noc/vc_router_util/floo_look_ahead_routing.sv
${SRC_DIR}/floo_noc/vc_router_util/floo_mux.sv
${SRC_DIR}/floo_noc/vc_router_util/floo_rr_arbiter.sv
${SRC_DIR}/floo_noc/vc_router_util/floo_sa_global.sv
${SRC_DIR}/floo_noc/vc_router_util/floo_sa_local.sv
${SRC_DIR}/floo_noc/vc_router_util/floo_vc_assignment.sv
${SRC_DIR}/floo_noc/vc_router_util/floo_vc_router_switch.sv
${SRC_DIR}/floo_noc/vc_router_util/floo_vc_selection.sv
${SRC_DIR}/floo_noc/floo_vc_router.sv
${SRC_DIR}/floo_noc/floo_nw_vc_chimney.sv
${SRC_DIR}/floo_noc/floo_nw_vc_router.sv
${SRC_DIR}/floo_agent_noc.sv


///////////////////////////////////////////////////////////////////////////////
// SoC
///////////////////////////////////////////////////////////////////////////////

${SRC_DIR}/soc_noc_top.sv
${SRC_DIR}/soc_noc.sv
${SRC_DIR}/soc_axi/peripheral.sv

// AXI Bus
${SRC_DIR}/soc_axi/axi_bus/axi_intf.sv
${SRC_DIR}/soc_axi/axi_bus/axi_atop_filter.sv
${SRC_DIR}/soc_axi/axi_bus/axi_burst_splitter.sv
${SRC_DIR}/soc_axi/axi_bus/axi_bus_compare.sv
${SRC_DIR}/soc_axi/axi_bus/axi_cdc_dst.sv
${SRC_DIR}/soc_axi/axi_bus/axi_cdc_src.sv
${SRC_DIR}/soc_axi/axi_bus/axi_cut.sv
${SRC_DIR}/soc_axi/axi_bus/axi_delayer.sv
${SRC_DIR}/soc_axi/axi_bus/axi_demux_simple.sv
${SRC_DIR}/soc_axi/axi_bus/axi_dw_downsizer.sv
${SRC_DIR}/soc_axi/axi_bus/axi_dw_upsizer.sv
${SRC_DIR}/soc_axi/axi_bus/axi_fifo.sv
${SRC_DIR}/soc_axi/axi_bus/axi_id_remap.sv
${SRC_DIR}/soc_axi/axi_bus/axi_id_prepend.sv
${SRC_DIR}/soc_axi/axi_bus/axi_isolate.sv
${SRC_DIR}/soc_axi/axi_bus/axi_join.sv
${SRC_DIR}/soc_axi/axi_bus/axi_lite_demux.sv
${SRC_DIR}/soc_axi/axi_bus/axi_lite_dw_converter.sv
${SRC_DIR}/soc_axi/axi_bus/axi_lite_from_mem.sv
${SRC_DIR}/soc_axi/axi_bus/axi_lite_join.sv
${SRC_DIR}/soc_axi/axi_bus/axi_lite_lfsr.sv
${SRC_DIR}/soc_axi/axi_bus/axi_lite_mailbox.sv
${SRC_DIR}/soc_axi/axi_bus/axi_lite_mux.sv
${SRC_DIR}/soc_axi/axi_bus/axi_lite_regs.sv
${SRC_DIR}/soc_axi/axi_bus/axi_modify_address.sv
${SRC_DIR}/soc_axi/axi_bus/axi_mux.sv
${SRC_DIR}/soc_axi/axi_bus/axi_rw_join.sv
${SRC_DIR}/soc_axi/axi_bus/axi_rw_split.sv
${SRC_DIR}/soc_axi/axi_bus/axi_serializer.sv
${SRC_DIR}/soc_axi/axi_bus/axi_slave_compare.sv
${SRC_DIR}/soc_axi/axi_bus/axi_throttle.sv
${SRC_DIR}/soc_axi/axi_bus/axi_cdc.sv
${SRC_DIR}/soc_axi/axi_bus/axi_demux.sv
${SRC_DIR}/soc_axi/axi_bus/axi_err_slv.sv
${SRC_DIR}/soc_axi/axi_bus/axi_dw_converter.sv
${SRC_DIR}/soc_axi/axi_bus/axi_id_serialize.sv
${SRC_DIR}/soc_axi/axi_bus/axi_lfsr.sv
${SRC_DIR}/soc_axi/axi_bus/axi_multicut.sv
${SRC_DIR}/soc_axi/axi_bus/axi_interleaved_xbar.sv
${SRC_DIR}/soc_axi/axi_bus/axi_iw_converter.sv
${SRC_DIR}/soc_axi/axi_bus/axi_lite_xbar.sv
${SRC_DIR}/soc_axi/axi_bus/axi_xbar.sv
${SRC_DIR}/soc_axi/axi_bus/axi_xp.sv
${SRC_DIR}/soc_axi/axi_bus/axi_lite_interface.sv
${SRC_DIR}/soc_axi/axi_bus/axi_slice/axi_ar_buffer.sv
${SRC_DIR}/soc_axi/axi_bus/axi_slice/axi_aw_buffer.sv
${SRC_DIR}/soc_axi/axi_bus/axi_slice/axi_b_buffer.sv
${SRC_DIR}/soc_axi/axi_bus/axi_slice/axi_r_buffer.sv
${SRC_DIR}/soc_axi/axi_bus/axi_slice/axi_w_buffer.sv
${SRC_DIR}/soc_axi/axi_bus/axi_slice/axi_single_slice.sv
${SRC_DIR}/soc_axi/axi_bus/axi_slice/axi_slice.sv
${SRC_DIR}/soc_axi/axi_bus/axi_slice/axi_slice_wrap.sv
${SRC_DIR}/soc_axi/axi_bus/axi_riscv_atomics/axi_res_tbl.sv
${SRC_DIR}/soc_axi/axi_bus/axi_riscv_atomics/axi_riscv_amos_alu.sv
${SRC_DIR}/soc_axi/axi_bus/axi_riscv_atomics/axi_riscv_amos.sv
${SRC_DIR}/soc_axi/axi_bus/axi_riscv_atomics/axi_riscv_lrsc.sv
${SRC_DIR}/soc_axi/axi_bus/axi_riscv_atomics/axi_riscv_atomics.sv
${SRC_DIR}/soc_axi/axi_bus/axi_riscv_atomics/axi_riscv_lrsc_wrap.sv
${SRC_DIR}/soc_axi/axi_bus/axi_riscv_atomics/axi_riscv_amos_wrap.sv
${SRC_DIR}/soc_axi/axi_bus/axi_riscv_atomics/axi_riscv_atomics_wrap.sv
${SRC_DIR}/soc_axi/axi_bus/axi_riscv_atomics/axi_riscv_atomics_structs.sv

// Register Bus
${SRC_DIR}/soc_axi/reg_bus/pulp/reg_intf.sv
${SRC_DIR}/soc_axi/reg_bus/pulp/reg_cdc.sv
${SRC_DIR}/soc_axi/reg_bus/pulp/reg_cut.sv
${SRC_DIR}/soc_axi/reg_bus/pulp/reg_demux.sv
${SRC_DIR}/soc_axi/reg_bus/pulp/reg_err_slv.sv
${SRC_DIR}/soc_axi/reg_bus/pulp/reg_filter_empty_writes.sv
${SRC_DIR}/soc_axi/reg_bus/pulp/reg_mux.sv
${SRC_DIR}/soc_axi/reg_bus/pulp/reg_uniform.sv
${SRC_DIR}/soc_axi/reg_bus/lowrisc/prim_subreg_arb.sv
${SRC_DIR}/soc_axi/reg_bus/lowrisc/prim_subreg_ext.sv
${SRC_DIR}/soc_axi/reg_bus/lowrisc/prim_subreg_shadow.sv
${SRC_DIR}/soc_axi/reg_bus/lowrisc/prim_subreg.sv

// Bus Converter
${SRC_DIR}/soc_axi/bus_converter/axi2mem.sv
${SRC_DIR}/soc_axi/bus_converter/axi_to_axi_lite.sv
${SRC_DIR}/soc_axi/bus_converter/axi_to_detailed_mem.sv
${SRC_DIR}/soc_axi/bus_converter/axi_to_mem_banked.sv
${SRC_DIR}/soc_axi/bus_converter/axi_to_mem_interleaved.sv
${SRC_DIR}/soc_axi/bus_converter/axi_to_mem_split.sv
${SRC_DIR}/soc_axi/bus_converter/axi_to_mem.sv
${SRC_DIR}/soc_axi/bus_converter/axi_from_mem.sv
${SRC_DIR}/soc_axi/bus_converter/axi_zero_mem.sv
${SRC_DIR}/soc_axi/bus_converter/axi_to_reg.sv
${SRC_DIR}/soc_axi/bus_converter/axi_to_reg_v2.sv
${SRC_DIR}/soc_axi/bus_converter/axi2apb_wrap.sv
${SRC_DIR}/soc_axi/bus_converter/axi2apb_64_32.sv
${SRC_DIR}/soc_axi/bus_converter/axi_lite_to_apb.sv
${SRC_DIR}/soc_axi/bus_converter/axi_lite_to_axi.sv
${SRC_DIR}/soc_axi/bus_converter/apb_to_reg.sv
${SRC_DIR}/soc_axi/bus_converter/axi_lite_to_reg.sv
${SRC_DIR}/soc_axi/bus_converter/periph_to_reg.sv
${SRC_DIR}/soc_axi/bus_converter/reg_to_apb.sv
${SRC_DIR}/soc_axi/bus_converter/reg_to_mem.sv
${SRC_DIR}/soc_axi/bus_converter/reg_to_tlul.sv
${SRC_DIR}/soc_axi/bus_converter/reg_to_axi.sv

// iDMA Engine
${SRC_DIR}/idma/idma_top.sv
${SRC_DIR}/idma/idma_frontend.sv
${SRC_DIR}/idma/backend/idma_axil_read.sv
${SRC_DIR}/idma/backend/idma_axil_write.sv
${SRC_DIR}/idma/backend/idma_axi_read.sv
${SRC_DIR}/idma/backend/idma_axi_write.sv
${SRC_DIR}/idma/backend/idma_axis_read.sv
${SRC_DIR}/idma/backend/idma_axis_write.sv
${SRC_DIR}/idma/backend/idma_backend_rw_axi.sv
${SRC_DIR}/idma/backend/idma_channel_coupler.sv
${SRC_DIR}/idma/backend/idma_dataflow_element.sv
${SRC_DIR}/idma/backend/idma_error_handler.sv
${SRC_DIR}/idma/backend/idma_init_read.sv
${SRC_DIR}/idma/backend/idma_init_write.sv
${SRC_DIR}/idma/backend/idma_legalizer_page_splitter.sv
${SRC_DIR}/idma/backend/idma_legalizer_pow2_splitter.sv
${SRC_DIR}/idma/backend/idma_legalizer_rw_axi.sv
${SRC_DIR}/idma/backend/idma_obi_read.sv
${SRC_DIR}/idma/backend/idma_obi_write.sv
${SRC_DIR}/idma/backend/idma_tilelink_read.sv
${SRC_DIR}/idma/backend/idma_tilelink_write.sv
${SRC_DIR}/idma/backend/idma_transport_layer_rw_axi.sv

// AXI Last Level Cache (LLC)
${SRC_DIR}/soc_axi/axi_llc/axi_llc_config.sv
${SRC_DIR}/soc_axi/axi_llc/axi_llc_chan_splitter.sv
${SRC_DIR}/soc_axi/axi_llc/axi_llc_burst_cutter.sv
${SRC_DIR}/soc_axi/axi_llc/axi_llc_hit_miss.sv
${SRC_DIR}/soc_axi/axi_llc/axi_llc_data_way.sv
${SRC_DIR}/soc_axi/axi_llc/axi_llc_ways.sv
${SRC_DIR}/soc_axi/axi_llc/axi_llc_read_unit.sv
${SRC_DIR}/soc_axi/axi_llc/axi_llc_write_unit.sv
${SRC_DIR}/soc_axi/axi_llc/axi_llc_merge_unit.sv
${SRC_DIR}/soc_axi/axi_llc/axi_llc_evict_unit.sv
${SRC_DIR}/soc_axi/axi_llc/axi_llc_refill_unit.sv
${SRC_DIR}/soc_axi/axi_llc/hit_miss_detect/axi_llc_tag_store.sv
${SRC_DIR}/soc_axi/axi_llc/hit_miss_detect/axi_llc_tag_pattern_gen.sv
${SRC_DIR}/soc_axi/axi_llc/hit_miss_detect/axi_llc_evict_box.sv
${SRC_DIR}/soc_axi/axi_llc/hit_miss_detect/axi_llc_lock_box_bloom.sv
${SRC_DIR}/soc_axi/axi_llc/hit_miss_detect/axi_llc_miss_counters.sv
${SRC_DIR}/soc_axi/axi_llc/eviction_refill/axi_llc_ax_master.sv
${SRC_DIR}/soc_axi/axi_llc/eviction_refill/axi_llc_r_master.sv
${SRC_DIR}/soc_axi/axi_llc/eviction_refill/axi_llc_w_master.sv
${SRC_DIR}/soc_axi/axi_llc/axi_llc_reg.sv
${SRC_DIR}/soc_axi/axi_llc/axi_llc_reg_wrap.sv
${SRC_DIR}/soc_axi/axi_llc/axi_llc.sv
${SRC_DIR}/soc_axi/axi_llc/axi_llc_top.sv

// Serial Link
${SRC_DIR}/soc_axi/serial_link/channel_allocator/slink_ch_alloc.sv
${SRC_DIR}/soc_axi/serial_link/channel_allocator/slink_channel_despread_sfr.sv
${SRC_DIR}/soc_axi/serial_link/channel_allocator/slink_channel_spread_sfr.sv
${SRC_DIR}/soc_axi/serial_link/channel_allocator/slink_stream_chopper.sv
${SRC_DIR}/soc_axi/serial_link/channel_allocator/slink_stream_dechopper.sv
${SRC_DIR}/soc_axi/serial_link/regs/slink_reg.sv
${SRC_DIR}/soc_axi/serial_link/slink_isolate.sv
${SRC_DIR}/soc_axi/serial_link/slink_link_layer.sv
${SRC_DIR}/soc_axi/serial_link/slink_phys_layer.sv
${SRC_DIR}/soc_axi/serial_link/slink_prot_layer.sv
${SRC_DIR}/soc_axi/serial_link/slink.sv

// RISC-V Debug Module
${SRC_DIR}/soc_axi/riscv-dbg/dm_csrs.sv
${SRC_DIR}/soc_axi/riscv-dbg/dmi_cdc.sv
${SRC_DIR}/soc_axi/riscv-dbg/dmi_jtag.sv
${SRC_DIR}/soc_axi/riscv-dbg/dmi_jtag_tap.sv
${SRC_DIR}/soc_axi/riscv-dbg/dm_mem.sv
${SRC_DIR}/soc_axi/riscv-dbg/dm_sba.sv
${SRC_DIR}/soc_axi/riscv-dbg/dm_top.sv
${SRC_DIR}/soc_axi/riscv-dbg/debug_rom.sv

// Core-local Interrupt Controller
${SRC_DIR}/soc_axi/clint.sv

// BootROM
${SRC_DIR}/soc_axi/bootrom.sv

// Main Memory
${SRC_DIR}/soc_axi/main_mem/main_mem_wrapper.sv

// Platform-Level Interrupt Controller
${SRC_DIR}/soc_axi/rv_plic/plic_regmap.sv
${SRC_DIR}/soc_axi/rv_plic/rv_plic_gateway.sv
${SRC_DIR}/soc_axi/rv_plic/rv_plic_target.sv
${SRC_DIR}/soc_axi/rv_plic/plic_top.sv

// Timer
${SRC_DIR}/soc_axi/apb_timer/apb_timer.sv
${SRC_DIR}/soc_axi/apb_timer/timer.sv

// UART
${SRC_DIR}/soc_axi/apb_uart/apb_uart.sv
${SRC_DIR}/soc_axi/apb_uart/slib_clock_div.sv
${SRC_DIR}/soc_axi/apb_uart/slib_counter.sv
${SRC_DIR}/soc_axi/apb_uart/slib_edge_detect.sv
${SRC_DIR}/soc_axi/apb_uart/slib_fifo.sv
${SRC_DIR}/soc_axi/apb_uart/slib_input_filter.sv
${SRC_DIR}/soc_axi/apb_uart/slib_input_sync.sv
${SRC_DIR}/soc_axi/apb_uart/slib_mv_filter.sv
${SRC_DIR}/soc_axi/apb_uart/uart_baudgen.sv
${SRC_DIR}/soc_axi/apb_uart/uart_interrupt.sv
${SRC_DIR}/soc_axi/apb_uart/uart_receiver.sv
${SRC_DIR}/soc_axi/apb_uart/uart_transmitter.sv

// Clk
${SRC_DIR}/soc_axi/clk/dco_regs.sv


///////////////////////////////////////////////////////////////////////////////
// Common Cell
///////////////////////////////////////////////////////////////////////////////

${SRC_DIR}/misc_common/binary_to_gray.sv
${SRC_DIR}/misc_common/cc_onehot.sv
${SRC_DIR}/misc_common/clk_int_div.sv
${SRC_DIR}/misc_common/delta_counter.sv
${SRC_DIR}/misc_common/edge_propagator_tx.sv
${SRC_DIR}/misc_common/exp_backoff.sv
${SRC_DIR}/misc_common/fifo_v3.sv
${SRC_DIR}/misc_common/gray_to_binary.sv
${SRC_DIR}/misc_common/isochronous_4phase_handshake.sv
${SRC_DIR}/misc_common/isochronous_spill_register.sv
${SRC_DIR}/misc_common/lfsr.sv
${SRC_DIR}/misc_common/lfsr_16bit.sv
${SRC_DIR}/misc_common/lfsr_8bit.sv
${SRC_DIR}/misc_common/lossy_valid_to_stream.sv
${SRC_DIR}/misc_common/mv_filter.sv
${SRC_DIR}/misc_common/onehot_to_bin.sv
${SRC_DIR}/misc_common/plru_tree.sv
${SRC_DIR}/misc_common/passthrough_stream_fifo.sv
${SRC_DIR}/misc_common/popcount.sv
${SRC_DIR}/misc_common/rr_arb_tree.sv
${SRC_DIR}/misc_common/rstgen_bypass.sv
${SRC_DIR}/misc_common/serial_deglitch.sv
${SRC_DIR}/misc_common/shift_reg.sv
${SRC_DIR}/misc_common/shift_reg_gated.sv
${SRC_DIR}/misc_common/spill_register_flushable.sv
${SRC_DIR}/misc_common/stream_demux.sv
${SRC_DIR}/misc_common/stream_filter.sv
${SRC_DIR}/misc_common/stream_fork.sv
${SRC_DIR}/misc_common/stream_join_dynamic.sv
${SRC_DIR}/misc_common/stream_mux.sv
${SRC_DIR}/misc_common/stream_throttle.sv
${SRC_DIR}/misc_common/sub_per_hash.sv
${SRC_DIR}/misc_common/sync.sv
${SRC_DIR}/misc_common/sync_wedge.sv
${SRC_DIR}/misc_common/unread.sv
${SRC_DIR}/misc_common/read.sv
${SRC_DIR}/misc_common/addr_decode_dync.sv
${SRC_DIR}/misc_common/cdc_2phase.sv
${SRC_DIR}/misc_common/cdc_4phase.sv
${SRC_DIR}/misc_common/clk_int_div_static.sv
${SRC_DIR}/misc_common/cb_filter.sv
${SRC_DIR}/misc_common/cdc_fifo_2phase.sv
${SRC_DIR}/misc_common/clk_mux_glitch_free.sv
${SRC_DIR}/misc_common/counter.sv
${SRC_DIR}/misc_common/ecc_decode.sv
${SRC_DIR}/misc_common/ecc_encode.sv
${SRC_DIR}/misc_common/edge_detect.sv
${SRC_DIR}/misc_common/lzc.sv
${SRC_DIR}/misc_common/max_counter.sv
${SRC_DIR}/misc_common/rstgen.sv
${SRC_DIR}/misc_common/spill_register.sv
${SRC_DIR}/misc_common/stream_delay.sv
${SRC_DIR}/misc_common/stream_fifo.sv
${SRC_DIR}/misc_common/stream_fork_dynamic.sv
${SRC_DIR}/misc_common/stream_join.sv
${SRC_DIR}/misc_common/addr_decode.sv
${SRC_DIR}/misc_common/addr_decode_napot.sv
${SRC_DIR}/misc_common/multiaddr_decode.sv
${SRC_DIR}/misc_common/cdc_reset_ctrlr.sv
${SRC_DIR}/misc_common/cdc_fifo_gray.sv
${SRC_DIR}/misc_common/fall_through_register.sv
${SRC_DIR}/misc_common/id_queue.sv
${SRC_DIR}/misc_common/stream_to_mem.sv
${SRC_DIR}/misc_common/stream_arbiter_flushable.sv
${SRC_DIR}/misc_common/stream_fifo_optimal_wrap.sv
${SRC_DIR}/misc_common/stream_register.sv
${SRC_DIR}/misc_common/stream_xbar.sv
${SRC_DIR}/misc_common/cdc_fifo_gray_clearable.sv
${SRC_DIR}/misc_common/cdc_2phase_clearable.sv
${SRC_DIR}/misc_common/mem_to_banks_detailed.sv
${SRC_DIR}/misc_common/stream_arbiter.sv
${SRC_DIR}/misc_common/stream_omega_net.sv
${SRC_DIR}/misc_common/mem_to_banks.sv
${SRC_DIR}/misc_common/fifo_v1.sv
${SRC_DIR}/misc_common/fifo_v2.sv
${SRC_DIR}/misc_common/cluster_clk_cells.sv
${SRC_DIR}/misc_common/pulp_clk_cells.sv
${SRC_DIR}/misc_common/tc_sram_wrapper.sv
${SRC_DIR}/misc_common/tc_sram.sv
${SRC_DIR}/misc_common/sram.sv


///////////////////////////////////////////////////////////////////////////////
// Technology Specific Cell
///////////////////////////////////////////////////////////////////////////////

${SRC_DIR}/tech_specific/DCO.v
${SRC_DIR}/tech_specific/tc_clk.v
${SRC_DIR}/tech_specific/tc_sram.v
${SRC_DIR}/tech_specific/signal_io_pad.v


///////////////////////////////////////////////////////////////////////////////
// INT Core
///////////////////////////////////////////////////////////////////////////////

${SRC_DIR}/int_core/src/int_core_top.sv
${SRC_DIR}/int_core/src/int_core.sv
${SRC_DIR}/int_core/src/sf_array.sv
${SRC_DIR}/int_core/src/sum_reduce.sv
${SRC_DIR}/int_core/src/adder_tree.sv
${SRC_DIR}/int_core/src/sf.sv
${SRC_DIR}/int_core/src/pe_array.sv
${SRC_DIR}/int_core/src/pe.sv


///////////////////////////////////////////////////////////////////////////////
// FP Core
///////////////////////////////////////////////////////////////////////////////

${SRC_DIR}/fp_core/src/fp_core_top.sv
${SRC_DIR}/fp_core/src/fp_core.sv
${SRC_DIR}/fp_core/src/int2bf.sv
${SRC_DIR}/fp_core/src/quant.sv
${SRC_DIR}/fp_core/src/fp_adder.sv


///////////////////////////////////////////////////////////////////////////////
// INT-FP Cluster
///////////////////////////////////////////////////////////////////////////////

${SRC_DIR}/core_cluster/cluster_top.sv
${SRC_DIR}/core_cluster/int_fp_cluster.sv




///////////////////////////////////////////////////////////////////////////////
// Speculative Prefill Unit
///////////////////////////////////////////////////////////////////////////////

${SRC_DIR}/spec_prefill/src/spec_prefill_top.sv
${SRC_DIR}/spec_prefill/src/spec_prefill_unit.sv
${SRC_DIR}/spec_prefill/src/encoder.sv
${SRC_DIR}/spec_prefill/src/learner.sv
${SRC_DIR}/spec_prefill/src/predictor.sv


