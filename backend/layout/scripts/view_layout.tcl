# view_layout.tcl

# Fetch variables from the Makefile
set freq $env(FREQ_MHZ)
set lib_type $env(LIB_TYPE)
set design $env(DESIGNS)
set runtime $env(RUNTIME)

puts "==============================================================="
puts "Loading Routed Design: $design | $freq MHz | $lib_type | Runtime: $runtime ns"
puts "==============================================================="

# Define the path to the final Stylus database
# Assuming Innovus is launched from the layout/work directory
set db_path "../deliverables/${design}_${lib_type}_${freq}_${runtime}/final.enc"

# Check if the database exists and read it
if {[file exists $db_path]} {
    read_db $db_path
    
    puts "==============================================================="
    puts "Layout database loaded successfully!"
    puts "==============================================================="
    
    # Automatically force the GUI to open
    gui_show
} else {
    puts "==============================================================="
    puts "ERROR: Layout database not found at $db_path"
    puts "Please run 'make layout_innovus' for these parameters first."
    puts "==============================================================="
    exit
}