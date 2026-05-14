

# Last update: 2026/02/26

#-----------------------------------------------------------------------------
# General Comments
#-----------------------------------------------------------------------------
puts "  "
puts "  "
puts "  "
puts "  "

#-----------------------------------------------------------------------------
# Main Custom Variables Design Dependent (set local)
#-----------------------------------------------------------------------------
set PROJECT_DIR $env(PROJECT_DIR)
set TECH_DIR $env(TECH_DIR)
set DESIGNS $env(DESIGNS)
set HDL_NAME $env(HDL_NAME)
set INTERCONNECT_MODE ple


#-----------------------------------------------------------------------------
# MAIN Custom Variables to be used in SDC (constraints file)
#-----------------------------------------------------------------------------
set MAIN_CLOCK_NAME clk
set MAIN_RST_NAME rst_n
set BEST_LIB_OPERATING_CONDITION PVT_1P32V_0C
set WORST_LIB_OPERATING_CONDITION PVT_0P9V_125C

# Read from Makefile environment and calculate period (1000 / MHz = ns)
set freq_mhz $env(FREQ_MHZ)
set period_clk [expr {1000.0 / $freq_mhz}]; # (100 ns = 10 MHz) (10 ns = 100 MHz) (2 ns = 500 MHz) (1 ns = 1 GHz)
set clk_uncertainty 0.05 ;# ns (“a guess”)
set clk_latency 0.10 ;# ns (“a guess”)
set in_delay 0.30 ;# ns
set out_delay 0.30;#ns 
set out_load 0.045 ;#pF 
set slew "146 164 264 252" ;#minimum rise, minimum fall, maximum rise and maximum fall 
set slew_min_rise 0.146 ;# ns
set slew_min_fall 0.164 ;# ns
set slew_max_rise 0.264 ;# ns
set slew_max_fall 0.252 ;# ns
#
set WORST_LIST {slow_vdd1v0_basicCells.lib} 
set BEST_LIST {fast_vdd1v2_basicCells.lib} 
set LEF_LIST {gsclib045_tech.lef gsclib045_macro.lef}
set WORST_CAP_LIST ${TECH_DIR}/gpdk045_v_6_0/soce/gpdk045.basic.CapTbl
set QRC_LIST ${TECH_DIR}/gpdk045_v_6_0/qrc/rcworst/qrcTechFile



#-----------------------------------------------------------------------------
# Load Path File
#-----------------------------------------------------------------------------
source ${PROJECT_DIR}/backend/synthesis/scripts/common/path.tcl

#-----------------------------------------------------------------------------
# Load Tech File
#-----------------------------------------------------------------------------
source ${SCRIPT_DIR}/common/tech.tcl

# Set the active library dynamically based on the Makefile parameter
set lib_type $env(LIB_TYPE)
set_db [get_db library_domain *$lib_type] .default true
#set_db [get_db library_domain *best] .default true
#set_db [get_db library_domain *worst] .default true

#-----------------------------------------------------------------------------
# Analyze RTL source (manually set; file_list.tcl is not covered in ELC1054)
#-----------------------------------------------------------------------------
#set_db init_hdl_search_path "${DEV_DIR} ${FRONTEND_DIR}"
#set rtl_files ${DESIGNS}.vhd
#read_hdl -language vhdl $rtl_files

set_db init_hdl_search_path "${DEV_DIR} ${FRONTEND_DIR}"
#set rtl_files "Util_package.vhd ${DESIGNS}.vhd"
#read_hdl -language vhdl $rtl_files 
#Da pra fazer um -f filelist
# Read VHDL files
read_hdl -vhdl {serial_mul.vhd pre_norm_mul.vhd}

# Read SystemVerilog files
read_hdl -sv {multiplier32FP_fsm.sv multiplier32FP.sv}


#-----------------------------------------------------------------------------
# Elaborate Design
#-----------------------------------------------------------------------------
elaborate ${HDL_NAME}
set_top_module ${HDL_NAME}
check_design -unresolved ${HDL_NAME}
get_db current_design
check_library


#-----------------------------------------------------------------------------
# Constraints
#-----------------------------------------------------------------------------
read_sdc ${BACKEND_DIR}/synthesis/constraints/${HDL_NAME}.sdc
#report timing -from a_i[0] -to sum_temp_reg[7]/D
#gui_show

#-----------------------------------------------------------------------------
# Pos "Elaborate" Attributes (manually set)
#-----------------------------------------------------------------------------
set_db auto_ungroup none ;# (none|both) ungrouping will not be performed

#-----------------------------------------------------------------------------
# Generic optimization (technology independent)
#-----------------------------------------------------------------------------
syn_generic ${HDL_NAME} 

#-----------------------------------------------------------------------------
# Agressively optimization (area, timing, power) and mapping
#-----------------------------------------------------------------------------
syn_map ${HDL_NAME} 
get_db insts .base_cell.name -u ;# List all cell names used in the current design.


#-----------------------------------------------------------------------------
# Preparing and generating output data (reports, verilog netlist)
#-----------------------------------------------------------------------------
# Fetch runtime from environment early
set runtime $env(RUNTIME)

# Folders names (Ta no makefile)
set RUN_DIR "${HDL_NAME}_${lib_type}_${freq_mhz}_${runtime}"
set RUN_RPT_DIR "${RPT_DIR}/${RUN_DIR}"
set RUN_DEV_DIR "${DEV_DIR}/${RUN_DIR}"

report_design_rules > ${RUN_RPT_DIR}/${HDL_NAME}_drc.rpt
report_area > ${RUN_RPT_DIR}/${HDL_NAME}_area.rpt
report_area -normalize_with_gate NAND2X1 > ${RUN_RPT_DIR}/${HDL_NAME}_normalized_area.rpt
report_timing > ${RUN_RPT_DIR}/${HDL_NAME}_timing.rpt
report_gates > ${RUN_RPT_DIR}/${HDL_NAME}_gates.rpt
report_qor > ${RUN_RPT_DIR}/${HDL_NAME}_qor.rpt

#source ../scripts/common/sdf_width_wa.etf

# Output SDF and HDL directly to the dynamic RUN_DEV_DIR
write_sdf -edge check_edge -setuphold split -recrem split -version 3.0 -design ${HDL_NAME} > ${RUN_DEV_DIR}/${HDL_NAME}.sdf
write_hdl ${HDL_NAME} > ${RUN_DEV_DIR}/${HDL_NAME}.v

#-----------------------------------------------------------------------------
# Lab 6: Power Analysis
#-----------------------------------------------------------------------------
# Point to the dynamically generated VCD file from the Xcelium simulation
#-----------------------------------------------------------------------------
# Lab 6: Power Analysis (Conditional Execution)
#-----------------------------------------------------------------------------
set vcd_path "${PROJECT_DIR}/frontend/VCDs/${HDL_NAME}_${lib_type}_${freq_mhz}_${runtime}.vcd"

if { [file exists $vcd_path] } {
    puts "==============================================================="
    puts "INFO: VCD file found. Executing Power Analysis."
    puts "==============================================================="
    
    # Point to the dynamically generated VCD file from the Xcelium simulation
    read_stimulus -allow_n_nets -format vcd -file $vcd_path

    # Set the power engine and generate reports into the dynamic run directory
    set_db power_engine joules
    report_sdb_annotation > ${RUN_RPT_DIR}/${HDL_NAME}_sdb_annotation.rpt
    report_power -unit uW > ${RUN_RPT_DIR}/${HDL_NAME}_power.rpt

    #-----------------------------------------------------------------------------
    # Extracting Specific Signal Probabilities and Toggle Rates
    #-----------------------------------------------------------------------------
    # Fetch sum_o[7]
    set prob_sum [get_db hnet:sum_o[7] .lp_computed_probability]
    set tr_sum   [get_db hnet:sum_o[7] .lp_computed_toggle_rate]

    # Fetch a_i[1]
    set prob_a   [get_db hnet:a_i[1] .lp_computed_probability]
    set tr_a     [get_db hnet:a_i[1] .lp_computed_toggle_rate]

    # Write out using unique keys matching the Python regex
    set prob_file [open "${RUN_RPT_DIR}/${HDL_NAME}_probabilities.rpt" w]
    puts $prob_file "sum_o[7]_prob : $prob_sum"
    puts $prob_file "sum_o[7]_tr : $tr_sum"
    puts $prob_file "a_i[1]_prob : $prob_a"
    puts $prob_file "a_i[1]_tr : $tr_a"
    close $prob_file

} else {
    puts "==============================================================="
    puts "INFO: No VCD file found at $vcd_path. Skipping Power Analysis."
    puts "==============================================================="
}

quit

quit



































if {0} {


#01 
report_power -unit uW

@genus:design:somador 94> get_db hnet:a_i[0] .lp_computed_probability
0.50000
@genus:design:somador 95> get_db hnet:a_i[0] .lp_computed_toggle_rate
0.002
@genus:design:somador 96> get_db hnet:a_i[0] .lp_probability_type
default
@genus:design:somador 97> get_db hnet:a_i[0] .lp_toggle_rate_type
default
@genus:design:somador 103> set_db hnet:a_i[0] .lp_asserted_probability 0.5
  Setting attribute of hnet 'a_i[0]': 'lp_asserted_probability' = 0.50000
1 0.50000
@genus:design:somador 104> set_db hnet:a_i[0] .lp_asserted_toggle_rate 0.002  
  Setting attribute of hnet 'a_i[0]': 'lp_asserted_toggle_rate' = 0.002
1 0.002



#02 mudei manualmente o lp_asserted_toggle_rate de 0.002 para 0.02 (aumento de 10 vezes)
@genus:design:somador 110> set_db hnet:a_i[0] .lp_asserted_toggle_rate 0.02 
  Setting attribute of hnet 'a_i[0]': 'lp_asserted_toggle_rate' = 0.02
1 0.02
report_power -unit uW

#03 diminui de 100 ns para 10 ns o período do clock, depois voltei a 100 ns
@genus:design:somador 92> dc::create_clock -name clk -period 10 [dc::get_ports clk]                                                                                        
Warning : Replacing existing clock definition. [TIM-101]
        : The clock name is 'clk'
report_power -unit uW


#04 ler o vcd e relatório de potência
read_vcd ${PROJECT_DIR}/frontend/${DESIGNS}_5kns.vcd
report_power -unit uW

get_db hnet:a_i[0] .lp_computed_probability
0.79000
get_db hnet:a_i[0] .lp_computed_toggle_rate
0.0022
get_db hnet:a_i[0] .lp_probability_type
asserted
get_db hnet:a_i[0] .lp_toggle_rate_type
asserted


#05 ler o vcd e relatório de potência
read_vcd ${PROJECT_DIR}/frontend/${DESIGNS}_10kns.vcd
report_power -unit uW
get_db hnet:a_i[0] .lp_computed_probability
get_db hnet:a_i[0] .lp_computed_toggle_rate

@genus:design:somador 106> get_db hnet:a_i[0] .lp_computed_probability
0.39500
@genus:design:somador 107> get_db hnet:a_i[0] .lp_computed_toggle_rate
0.0011
@genus:design:somador 108> 






Better the annotation, better is the accuracy of the estimated power.

You can report the list of instances with activity either unasserted or computed by using the following command:

report_sdb_annotation -stims /stim#1 -show_details seq:unasserted
report_sdb_annotation -stims /stim#1 -show_details seq:computed
report_sdb_annotation -stims /stim#1 -show_details icgc:all




read_stimulus -allow_n_nets ${PROJECT_DIR}/frontend/${DESIGNS}_5kns.vcd


report_area
get_db [vfind / -libcell NAND2X1] .area
report_area -normalize_with_gate NAND2X1
report_area -detail 
report_gates



report_units
get_db timing_report_time_unit
set_db timing_report_load_unit pf



To write out a design session (database or db), use the following:

write_db -script my.db.tcl -to_file my.db

Writing out the db with the -script option lets you modify paths to the libraries, which is useful if there is a need to send a testcase to Cadence.

To read this db in another Genus session, use the following:

genus -f my.db.tcl -post "read_db my.db"





# Comandos abril 2025

#Use report_stim_hierarchy command to check design hierarchy
report_design_hierarchy
#Use report_stim_hierarchy command to check stimulus hierarchy
report_stim_hierarchy -file ${PROJECT_DIR}/frontend/${DESIGNS}_5kns.vcd -format vcd


report_sdb_annotation -show_details unasserted


}



