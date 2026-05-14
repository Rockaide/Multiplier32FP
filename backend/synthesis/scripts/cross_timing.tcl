# backend/synthesis/scripts/cross_timing.tcl

set synth_freq $env(SYNTH_FREQ)
set test_freq $env(TEST_FREQ)
set lib_type $env(LIB_TYPE)
set design $env(DESIGNS)
set PROJECT_DIR $env(PROJECT_DIR)
set BACKEND_DIR $env(BACKEND_DIR)

puts "==============================================================="
puts "Cross-Timing Analysis: Netlist @ ${synth_freq}MHz | Testing @ ${test_freq}MHz"
puts "==============================================================="

source ../scripts/common/path.tcl
source ../scripts/common/tech.tcl
set_db [get_db library_domain *$lib_type] .default true

set netlist_path "../deliverables/${design}_${lib_type}_${synth_freq}_base/${design}.v"

if {![file exists $netlist_path]} {
    puts "ERROR: Netlist not found at $netlist_path. Run base synthesis first."
    quit
}

read_netlist $netlist_path
elaborate
set_top_module $design

set freq_mhz $test_freq
set period_clk [expr {1000.0 / $freq_mhz}]

set MAIN_CLOCK_NAME clk
set MAIN_RST_NAME rst_n
set clk_uncertainty 0.05
set clk_latency 0.10
set in_delay 0.30
set out_delay 0.30
set out_load 0.045
set slew "146 164 264 252"
set slew_min_rise 0.146
set slew_min_fall 0.164
set slew_max_rise 0.264
set slew_max_fall 0.252

read_sdc ${BACKEND_DIR}/synthesis/constraints/${design}.sdc

# 5. Generate Timing Report
set output_rpt "../reports/${design}_synth${synth_freq}_tested${test_freq}_timing.rpt"
set output_rpt_pwr "../reports/${design}_synth${synth_freq}_tested${test_freq}_pwr.rpt"
report_timing > $output_rpt
report_power > $output_rpt_pwr

puts "==============================================================="
puts "Cross-timing complete. Report saved to:"
puts "$output_rpt"
puts "==============================================================="
quit
