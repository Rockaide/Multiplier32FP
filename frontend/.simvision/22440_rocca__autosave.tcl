
# XM-Sim Command File
# TOOL:	xmsim(64)	22.09-s001
#

set tcl_prompt1 {puts -nonewline "xcelium> "}
set tcl_prompt2 {puts -nonewline "> "}
set vlog_format %h
set vhdl_format %v
set real_precision 6
set display_unit auto
set time_unit module
set heap_garbage_size -200
set heap_garbage_time 0
set assert_report_level note
set assert_stop_level error
set autoscope yes
set assert_1164_warnings yes
set pack_assert_off {}
set severity_pack_assert_off {note warning}
set assert_output_stop_level failed
set tcl_debug_level 0
set relax_path_name 1
set vhdl_vcdmap XX01ZX01X
set intovf_severity_level ERROR
set probe_screen_format 0
set rangecnst_severity_level ERROR
set textio_severity_level ERROR
set vital_timing_checks_on 1
set vlog_code_show_force 0
set assert_count_attempts 1
set tcl_all64 false
set tcl_runerror_exit false
set assert_report_incompletes 0
set show_force 1
set force_reset_by_reinvoke 0
set tcl_relaxed_literal 0
set probe_exclude_patterns {}
set probe_packed_limit 4k
set probe_unpacked_limit 16k
set assert_internal_msg no
set svseed 1
set assert_reporting_mode 0
set vcd_compact_mode 0
alias . run
alias quit exit
database -open -shm -into waves.shm waves -default
probe -create -database waves multiplier32FP_tb.dut.i_post_norm_mul:clk_i multiplier32FP_tb.dut.i_post_norm_mul:exp_10_i multiplier32FP_tb.dut.i_post_norm_mul:fract_48_i multiplier32FP_tb.dut.i_post_norm_mul:ine_o multiplier32FP_tb.dut.i_post_norm_mul:opa_i multiplier32FP_tb.dut.i_post_norm_mul:opb_i multiplier32FP_tb.dut.i_post_norm_mul:output_o multiplier32FP_tb.dut.i_post_norm_mul:rmode_i multiplier32FP_tb.dut.i_post_norm_mul:s_carry multiplier32FP_tb.dut.i_post_norm_mul:s_exp_10_i multiplier32FP_tb.dut.i_post_norm_mul:s_exp_10a multiplier32FP_tb.dut.i_post_norm_mul:s_exp_10b multiplier32FP_tb.dut.i_post_norm_mul:s_expa multiplier32FP_tb.dut.i_post_norm_mul:s_expb multiplier32FP_tb.dut.i_post_norm_mul:s_expo1 multiplier32FP_tb.dut.i_post_norm_mul:s_expo2b multiplier32FP_tb.dut.i_post_norm_mul:s_expo3 multiplier32FP_tb.dut.i_post_norm_mul:s_frac2a multiplier32FP_tb.dut.i_post_norm_mul:s_frac3 multiplier32FP_tb.dut.i_post_norm_mul:s_frac_rnd multiplier32FP_tb.dut.i_post_norm_mul:s_fract_48_i multiplier32FP_tb.dut.i_post_norm_mul:s_guard multiplier32FP_tb.dut.i_post_norm_mul:s_ine_o multiplier32FP_tb.dut.i_post_norm_mul:s_infa multiplier32FP_tb.dut.i_post_norm_mul:s_infb multiplier32FP_tb.dut.i_post_norm_mul:s_lost multiplier32FP_tb.dut.i_post_norm_mul:s_nan_a multiplier32FP_tb.dut.i_post_norm_mul:s_nan_b multiplier32FP_tb.dut.i_post_norm_mul:s_nan_in multiplier32FP_tb.dut.i_post_norm_mul:s_nan_op multiplier32FP_tb.dut.i_post_norm_mul:s_op_0 multiplier32FP_tb.dut.i_post_norm_mul:s_opa_i multiplier32FP_tb.dut.i_post_norm_mul:s_opb_i multiplier32FP_tb.dut.i_post_norm_mul:s_output_o multiplier32FP_tb.dut.i_post_norm_mul:s_overflow multiplier32FP_tb.dut.i_post_norm_mul:s_r_zeros multiplier32FP_tb.dut.i_post_norm_mul:s_rmode_i multiplier32FP_tb.dut.i_post_norm_mul:s_round multiplier32FP_tb.dut.i_post_norm_mul:s_roundup multiplier32FP_tb.dut.i_post_norm_mul:s_shl2 multiplier32FP_tb.dut.i_post_norm_mul:s_shr2 multiplier32FP_tb.dut.i_post_norm_mul:s_shr3 multiplier32FP_tb.dut.i_post_norm_mul:s_sign_i multiplier32FP_tb.dut.i_post_norm_mul:s_sticky multiplier32FP_tb.dut.i_post_norm_mul:s_zeros multiplier32FP_tb.dut.i_post_norm_mul:sign_i multiplier32FP_tb.dut.i_pre_norm_mul:clk_i multiplier32FP_tb.dut.i_pre_norm_mul:exp_10_o multiplier32FP_tb.dut.i_pre_norm_mul:fracta_24_o multiplier32FP_tb.dut.i_pre_norm_mul:fractb_24_o multiplier32FP_tb.dut.i_pre_norm_mul:opa_i multiplier32FP_tb.dut.i_pre_norm_mul:opb_i multiplier32FP_tb.dut.i_pre_norm_mul:s_exp_10_o multiplier32FP_tb.dut.i_pre_norm_mul:s_expa multiplier32FP_tb.dut.i_pre_norm_mul:s_expa_in multiplier32FP_tb.dut.i_pre_norm_mul:s_expb multiplier32FP_tb.dut.i_pre_norm_mul:s_expb_in multiplier32FP_tb.dut.i_pre_norm_mul:s_fracta multiplier32FP_tb.dut.i_pre_norm_mul:s_fractb multiplier32FP_tb.dut.i_pre_norm_mul:s_opa_dn multiplier32FP_tb.dut.i_pre_norm_mul:s_opb_dn

simvision -input /home/u32br/rocca/projetos/multiplier32FP/frontend/.simvision/22440_rocca__autosave.tcl.svcf
