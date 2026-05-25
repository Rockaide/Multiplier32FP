
# Last update: 2026/03/08

#-----------------------------------------------------------------------------
# Load vriables set in run_first.tcl
#-----------------------------------------------------------------------------
source ../../synthesis/scripts/common/variables.tcl

#-----------------------------------------------------------------------------
# Load Path File
#-----------------------------------------------------------------------------
source ${PROJECT_DIR}/backend/synthesis/scripts/common/path.tcl

#-----------------------------------------------------------------------------
# Suppressing messages (use with caution)
#-----------------------------------------------------------------------------
set_message -id TECHLIB-302 -suppress
set_message -id IMPDB-6501 -suppress 
set_message -id IMPFP-3961 -suppress 
set_message -id IMPOPT-3195 -suppress
set_message -id IMPSP-9025 -suppress 
set_message -id IMPLF-200 -suppress 
set_message -id IMPEXT-3493 -suppress 
set_message -id IMPEXT-6166 -suppress 
set_message -id IMPSP-5217 -suppress 

#-----------------------------------------------------------------------------
# Initiates the design files (netlist, LEFs, timing libraries)
#-----------------------------------------------------------------------------
set_db init_power_nets $NET_ONE
set_db init_ground_nets $NET_ZERO
read_mmmc ${LAYOUT_DIR}/scripts/${DESIGNS}.view
read_physical -lef $LEF_LIST
read_netlist ../../synthesis/deliverables/${DESIGNS}.v
init_design

#-----------------------------------------------------------------------------
# General settings
#-----------------------------------------------------------------------------
get_db design_top_routing_layer
set_db design_top_routing_layer 11 ;# top layer for the current PDK. Affects the CTS.

#-----------------------------------------------------------------------------
# Net connections
#-----------------------------------------------------------------------------
delete_global_net_connections
connect_global_net $NET_ONE -type pg_pin -pin_base_name $NET_ONE -inst_base_name *
connect_global_net $NET_ZERO -type pg_pin -pin_base_name $NET_ZERO -inst_base_name *
connect_global_net $NET_ONE -type tie_hi
connect_global_net $NET_ZERO -type tie_lo
connect_global_net $NET_ONE -type tie_hi -pin $NET_ONE -inst *
connect_global_net $NET_ZERO -type tie_lo  -pin $NET_ZERO -inst *

#-----------------------------------------------------------------------------
# Tells Innovus the technology being used
#-----------------------------------------------------------------------------
get_db design_process_node
set_db design_process_node 45 ;# specifies the process technology you are designing. Innovus automatically assigns coupling capacitance threshold values to the RC extraction filters.

#-----------------------------------------------------------------------------
# Obtain top design name
#-----------------------------------------------------------------------------
get_db designs .name

#-----------------------------------------------------------------------------
# Specify floorplan: define the dimensions and layout of the floorplan
#-----------------------------------------------------------------------------
create_floorplan -core_margins_by die -core_density_size 1 0.7 2.5 2.5 2.5 2.5
check_floorplan ;# checks the quality of the floorplan

#-----------------------------------------------------------------------------
# Placing core design pins (graphical or command)
#-----------------------------------------------------------------------------
edit_pin -fixed_pin 1 -unit micron -spread_direction clockwise -side Left -layer 1 -spread_type center -spacing 1.0 -pin $LEFT_CORE_PINS
edit_pin -fixed_pin 1 -unit micron -spread_direction clockwise -edge 1 -layer 1 -spread_type center -spacing 1.0 -pin $TOP_CORE_PINS
edit_pin -fixed_pin 1 -unit micron -spread_direction clockwise -edge 2 -layer 1 -spread_type center -spacing 1.0 -pin $RIGHT_CORE_PINS
edit_pin -fixed_pin 1 -unit micron -spread_direction clockwise -edge 3 -layer 1 -spread_type center -spacing 1.0 -pin $BOTTOM_CORE_PINS

#-----------------------------------------------------------------------------
# Add ring (Power planning) 
#-----------------------------------------------------------------------------
set_db add_rings_skip_shared_inner_ring none
set_db add_rings_avoid_short 1
set_db add_rings_ignore_rows 0
set_db add_rings_extend_over_row 0
add_rings -type core_rings -jog_distance 0.6 -threshold 0.6 -nets "$NET_ONE $NET_ZERO" -follow core -layer {bottom Metal11 top Metal11 right Metal10 left Metal10} -width 0.7 -spacing 0.4 -offset 0.6

#-----------------------------------------------------------------------------
# Add stripes (Power planning) 
#-----------------------------------------------------------------------------
add_stripes -nets "$NET_ONE $NET_ZERO" -layer Metal6 -direction vertical -width 0.28 -spacing 0.8 -set_to_set_distance 6 -start_from left -switch_layer_over_obs false -max_same_layer_jog_length 2 -pad_core_ring_top_layer_limit Metal11 -pad_core_ring_bottom_layer_limit Metal1 -block_ring_top_layer_limit Metal11 -block_ring_bottom_layer_limit Metal1 -use_wire_group 0 -snap_wire_center_to_grid none -start_offset 1 ;# Metal6 avoids maxviastack violation later on DRC check

#-----------------------------------------------------------------------------
# Sroute
#-----------------------------------------------------------------------------
route_special -connect core_pin -layer_change_range { Metal1(1) Metal11(11) } -block_pin_target nearest_target -core_pin_target first_after_row_end -allow_jogging 1 -crossover_via_layer_range { Metal1(1) Metal11(11) } -nets "$NET_ONE $NET_ZERO" -allow_layer_change 1 -target_via_layer_range { Metal1(1) Metal11(11) } -stripe_layer_range {1 11}

#-----------------------------------------------------------------------------
# Placement
#-----------------------------------------------------------------------------
place_opt_design ;# Executes pre-CTS flow with both placement and pre-CTS optimization. Performs DRV fixing, WNS, and TNS optimization.

#-----------------------------------------------------------------------------
# Extract RC (after placemement) for timing debug purposes
#-----------------------------------------------------------------------------
set_db extract_rc_engine pre_route ;# {pre_route | post_route}; specifies the extraction engine to use.
extract_rc ;# generates RC database for timing analysis and signal integrity (SI) anaysis

#-----------------------------------------------------------------------------
# Pre-CTS optimization
#-----------------------------------------------------------------------------
set_db opt_drv_fix_max_cap true ; set_db opt_drv_fix_max_tran true ; set_db opt_fix_fanout_load false
opt_design -pre_cts

#-----------------------------------------------------------------------------
# Pre-CTS timing verification
#-----------------------------------------------------------------------------
set_db timing_analysis_type best_case_worst_case ;# {single | best_case_worst_case | ocv}
time_design -pre_cts

#-----------------------------------------------------------------------------
# CTS - Clock Concurrent Optimization Flow
#-----------------------------------------------------------------------------
set_interactive_constraint_modes {normal_genus_slow_max}
reset_ideal_network $MAIN_CLOCK_NAME
get_db clock_trees
set_db cts_buffer_cells $BUFFERS_CTS ;# specifies the buffer cells for CTS
get_db cts_buffer_cells 
set_db cts_inverter_cells $INVERTERS_CTS ;# specifies the inverter cells for CTS
get_db cts_inverter_cells 
create_clock_tree_spec
clock_opt_design

#-----------------------------------------------------------------------------
# Extract RC (pre-route after clock tree synthesis)
#-----------------------------------------------------------------------------
set_db extract_rc_engine pre_route ;# {pre_route | post_route}; specifies the extraction engine to use.
extract_rc ;# generates RC database for timing analysis and signal integrity (SI) anaysis

#-----------------------------------------------------------------------------
# Post-CTS cell verification
#-----------------------------------------------------------------------------
source ../scripts/user_statCCOpt_cui.tcl ;# this tcl file should be at script's directory
user_statCCOpt

#-----------------------------------------------------------------------------
# Post-CTS timing verification
#-----------------------------------------------------------------------------
set_db timing_analysis_type best_case_worst_case
set_db timing_analysis_clock_propagation_mode sdc_control
time_design -post_cts
time_design -post_cts -hold

#-----------------------------------------------------------------------------
# postCTS optimization
#-----------------------------------------------------------------------------
opt_design -post_cts ;# optimize for setup
opt_design -post_cts -hold ;# optimize for hold

#-----------------------------------------------------------------------------
# Routing
#-----------------------------------------------------------------------------
route_design

#-----------------------------------------------------------------------------
# Post-route timing verification
#-----------------------------------------------------------------------------
set_db timing_analysis_type ocv ;# allows for more accurate timing analysis by accounting for variations in manufacturing processes.
time_design -post_route
#
set_interactive_constraint_modes {normal_genus_slow_max} ;# mode name define in ".view" configuration file
set_propagated_clock [all_clocks] 
#
set_db timing_analysis_check_type setup
report_timing
#
set_db timing_analysis_check_type hold
report_timing

#-----------------------------------------------------------------------------
# Filler Cells Insertion
#-----------------------------------------------------------------------------
add_fillers -base_cells {FILL8 FILL64 FILL4 FILL32 FILL2 FILL16 FILL1}

#-----------------------------------------------------------------------------
# Add metal fill
#-----------------------------------------------------------------------------
add_metal_fill -layers {Metal1 Metal2 Metal3 Metal4 Metal5 Metal6 Metal7 Metal8 Metal9 Metal10 Metal11}


#-----------------------------------------------------------------------------
# Save Design: final.enc
#-----------------------------------------------------------------------------
write_db final.enc

#-----------------------------------------------------------------------------
# Write verilog
#-----------------------------------------------------------------------------
write_netlist ../deliverables/${DESIGNS}_layout.v

#-----------------------------------------------------------------------------
# Write SDF for gate level simulation and VCD creation
#-----------------------------------------------------------------------------
write_sdf -edge check_edge -map_setuphold merge_always -map_recrem split -map_removal -version 3.0 ../deliverables/${DESIGNS}_layout.sdf


#-----------------------------------------------------------------------------
# (!) Simulate design and generate VDC file(s) so you can analyse power
#-----------------------------------------------------------------------------
# Xcelium: layout gate level simulation with SDF
# Xcelium: need to create VCD files before use them in the power analysis


#-----------------------------------------------------------------------------
# Reports
#-----------------------------------------------------------------------------
report_gates -out_file ../reports/${DESIGNS}_gates_layout.rpt


#-----------------------------------------------------------------------------
# Power Analysis
#-----------------------------------------------------------------------------
# read VCD
read_activity_file -format VCD -scope ${DESIGNS}_tb(verification)/DUV ../../../frontend/${DESIGNS}_layout_5kns.vcd -reset 
report_power -power_unit uW -view analysis_normal_fast_min > ../reports/layout_power_report_5kns_clkperiod-${period_clk}ns.rpt







