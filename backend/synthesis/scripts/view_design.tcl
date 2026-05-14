# view_design.tcl

# Fetch variables from the Makefile
set freq $env(FREQ_MHZ)
set lib_type $env(LIB_TYPE)
set design $env(DESIGNS)

puts "==============================================================="
puts "Loading Synthesized Design: $design | $freq MHz | $lib_type"
puts "==============================================================="

# 1. Load the technology libraries using your existing tech setup
source ../scripts/common/path.tcl
source ../scripts/common/tech.tcl
set_db [get_db library_domain *$lib_type] .default true

# 2. Define the exact path to the baseline netlist
set netlist_path "../deliverables/${design}_${lib_type}_${freq}_base/${design}.v"

# 3. Check if file exists, read it, and elaborate
if {[file exists $netlist_path]} {
    read_netlist $netlist_path
    
    # Elaborate builds the database needed for the GUI to draw the gates
    elaborate
    
    puts "==============================================================="
    puts "Design loaded successfully!"
    puts "To view the gates, go to the top menu menu: "
    puts "GUI -> Schematic View -> Main Map"
    puts "==============================================================="
    
    # Automatically force the GUI to open
    gui_show
} else {
    puts "==============================================================="
    puts "ERROR: Netlist not found at $netlist_path"
    puts "Please run 'make TL' or base synthesis for these parameters first."
    puts "==============================================================="
    quit
}
