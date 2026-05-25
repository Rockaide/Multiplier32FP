# power.tcl

#-----------------------------------------------------------------------------
# Fetch Dynamic Environment Variables from Makefile
#-----------------------------------------------------------------------------
set design      $env(DESIGNS)
set freq        $env(FREQ_MHZ)
set lib         $env(LIB_TYPE)
set runtime     $env(RUNTIME)
set PROJECT_DIR $env(PROJECT_DIR)
set BACKEND_DIR $env(BACKEND_DIR)
set LAYOUT_DIR  $env(LAYOUT_DIR)

# Define dynamic output paths
set OUT_DELIV   "${LAYOUT_DIR}/deliverables/${design}_${lib}_${freq}_${runtime}"
set OUT_RPT     "${LAYOUT_DIR}/reports/${design}_${lib}_${freq}_${runtime}"

#-----------------------------------------------------------------------------
# Load existing layout database
#-----------------------------------------------------------------------------
set db_path "${OUT_DELIV}/final.enc"

if { [file exists $db_path] } {
    puts "==============================================================="
    puts " Loading existing layout database from $db_path"
    puts "==============================================================="
    read_db $db_path
} else {
    puts "ERROR: Layout database not found. Run physical synthesis first."
    exit
}

#-----------------------------------------------------------------------------
# Power Analysis
#-----------------------------------------------------------------------------
set vcd_path "${PROJECT_DIR}/frontend/VCDs/${design}_lab8_${lib}_${freq}_${runtime}.vcd"

if { [file exists $vcd_path] } {
    puts "==============================================================="
    puts " VCD found! Running accurate post-layout power analysis..."
    puts "==============================================================="
    read_activity_file -format VCD -scope ${design}_tb.DUV $vcd_path -reset 
    report_power -power_unit uW -view analysis_normal_fast_min > ${OUT_RPT}/${design}_power_${runtime}ns.rpt
} else {
    puts "WARNING: VCD not found at $vcd_path. Cannot perform accurate power analysis."
}

exit