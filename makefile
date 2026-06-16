# THIS MAKEFILE WAS MADE BY: Vinícius Rocca Ferrari dos Santos Lima

# Define bash as the shell to allow module loading
SHELL := /bin/bash

# Define default synthesis parameters
export FREQ_MHZ ?= 100
export LIB_TYPE ?= worst
export RUNTIME ?= 0

# --- Translate Frequency to Clock Half-Period and Wait Time Dynamically ---
CLEAN_FREQ = $(strip $(FREQ_MHZ))

PERIOD_CLK := $(shell awk "BEGIN {printf \"%.3f\", 1000.0 / $(CLEAN_FREQ)}")
HALF_PERIOD_PS := $(shell awk "BEGIN {printf \"%d\", 1000000.0 / (2 * $(CLEAN_FREQ))}")

# Set wait times scaling with the frequency (assuming WAIT_TIME is 1/2 of Period in ns as a base, multiplied by scaling factor)
WAIT_TIME_NS := $(shell awk "BEGIN {printf \"%d\", 500000.0 / $(CLEAN_FREQ)}")

# Calculate exact runtime required for VCD generation based on frequency (1604500 base + 101ns buffer for rounding)
CALC_RUNTIME := $(shell awk "BEGIN {printf \"%d\", (1604500.0 / $(CLEAN_FREQ)) + 101}")
CALC_RUNTIME2 := $(shell awk "BEGIN {printf \"%d\", ((1604500.0 / $(CLEAN_FREQ)) + 101) * 2}")

# Export the calculated period so variables.tcl and SDC files can read it
export period_clk = $(PERIOD_CLK)

#-----------------------------------------------------------------------------
# General design dependent variables
#-----------------------------------------------------------------------------
export DESIGNS = multiplier32FP
export HDL_NAME = $(DESIGNS)
export PROJECT_DIR := $(shell pwd)
export BACKEND_DIR = $(PROJECT_DIR)/backend
export TECH_DIR = /home/tools/design_kits/cadence/GPDK045
export LIB_DIR = $(TECH_DIR)/gsclib045_svt_v4.4/gsclib045/timing
export LEF_DIR = $(TECH_DIR)/gsclib045_svt_v4.4/gsclib045/lef
export SCRIPT_DIR = $(BACKEND_DIR)/synthesis/scripts
export LAYOUT_DIR = $(BACKEND_DIR)/layout


export RTL_FILES = $(DESIGNS).vhd
export VLOG_LIST = $(BACKEND_DIR)/synthesis/deliverables/$(DESIGNS).v $(BACKEND_DIR)/synthesis/deliverables/$(DESIGNS)_io.v $(BACKEND_DIR)/synthesis/deliverables/$(DESIGNS)_chip.v

#-----------------------------------------------------------------------------
# Custom Variables to be used in SDC (constraints file)
#-----------------------------------------------------------------------------
export MAIN_CLOCK_NAME = clk
export MAIN_RST_NAME = rst_n
export BEST_LIB_OPERATING_CONDITION = PVT_1P32V_0C
export WORST_LIB_OPERATING_CONDITION = PVT_0P9V_125C
export clk_uncertainty = 0.05
export clk_latency = 0.10
export in_delay = 0.30
export out_delay = 0.30
export out_load = 0.045
export slew = 146 164 264 252
export slew_min_rise = 0.146
export slew_min_fall = 0.164
export slew_max_rise = 0.264
export slew_max_fall = 0.252

#-----------------------------------------------------------------------------
# TECH Custom Variables
#-----------------------------------------------------------------------------
export WORST_LIST = $(LIB_DIR)/slow_vdd1v0_basicCells.lib
export BEST_LIST = $(LIB_DIR)/fast_vdd1v2_basicCells.lib
export LEF_LIST = $(LEF_DIR)/gsclib045_tech.lef $(LEF_DIR)/gsclib045_macro.lef
export WORST_CAP_LIST = $(TECH_DIR)/gpdk045_v_6_0/soce/gpdk045.basic.CapTbl
export QRC_LIST = $(TECH_DIR)/gpdk045_v_6_0/qrc/rcworst/qrcTechFile
export CAP_MAX = $(WORST_CAP_LIST)
export CAP_MIN = $(WORST_CAP_LIST)

#-----------------------------------------------------------------------------
# Layout, CTS, and Floorplan Variables
#-----------------------------------------------------------------------------
export NET_ZERO = VSS
export NET_ONE = VDD

export BUFFERS_CTS = CLKBUFX20 CLKBUFX16 CLKBUFX12 CLKBUFX8 CLKBUFX6 CLKBUFX4 CLKBUFX3 CLKBUFX2
export INVERTERS_CTS = INVX20 CLKINVX20 INVX16 INVX12 INVX8 INVX6 INVX4 INVX3 INVX2 INVX1 INVXL

#export LEFT_CORE_PINS = {a_i[0]} {a_i[1]} {a_i[2]} {a_i[3]} {a_i[4]} {a_i[5]} {a_i[6]} {a_i[7]}
#export TOP_CORE_PINS = {b_i[0]} {b_i[1]} {b_i[2]} {b_i[3]} {b_i[4]} {b_i[5]} {b_i[6]} {b_i[7]}
#export RIGHT_CORE_PINS = {sum_o[0]} {sum_o[1]} {sum_o[2]} {sum_o[3]} {sum_o[4]} {sum_o[5]} {sum_o[6]} {sum_o[7]}
#export BOTTOM_CORE_PINS = carry_i carry_o clk rst_n

# Pins para o multiplier
export LEFT_CORE_PINS = {a_i[0]} {a_i[1]} {a_i[2]} {a_i[3]} {a_i[4]} {a_i[5]} {a_i[6]} {a_i[7]} {a_i[8]} {a_i[9]} {a_i[10]} {a_i[11]} {a_i[12]} {a_i[13]} {a_i[14]} {a_i[15]} {a_i[16]} {a_i[17]} {a_i[18]} {a_i[19]} {a_i[20]} {a_i[21]} {a_i[22]} {a_i[23]} {a_i[24]} {a_i[25]} {a_i[26]} {a_i[27]} {a_i[28]} {a_i[29]} {a_i[30]} {a_i[31]}
export TOP_CORE_PINS = {b_i[0]} {b_i[1]} {b_i[2]} {b_i[3]} {b_i[4]} {b_i[5]} {b_i[6]} {b_i[7]} {b_i[8]} {b_i[9]} {b_i[10]} {b_i[11]} {b_i[12]} {b_i[13]} {b_i[14]} {b_i[15]} {b_i[16]} {b_i[17]} {b_i[18]} {b_i[19]} {b_i[20]} {b_i[21]} {b_i[22]} {b_i[23]} {b_i[24]} {b_i[25]} {b_i[26]} {b_i[27]} {b_i[28]} {b_i[29]} {b_i[30]} {b_i[31]}
export RIGHT_CORE_PINS = {product_o[0]} {product_o[1]} {product_o[2]} {product_o[3]} {product_o[4]} {product_o[5]} {product_o[6]} {product_o[7]} {product_o[8]} {product_o[9]} {product_o[10]} {product_o[11]} {product_o[12]} {product_o[13]} {product_o[14]} {product_o[15]} {product_o[16]} {product_o[17]} {product_o[18]} {product_o[19]} {product_o[20]} {product_o[21]} {product_o[22]} {product_o[23]} {product_o[24]} {product_o[25]} {product_o[26]} {product_o[27]} {product_o[28]} {product_o[29]} {product_o[30]} {product_o[31]}
export BOTTOM_CORE_PINS = clk rst_n start_i done_o nan_o infinit_o overflow_o underflow_o

#-----------------------------------------------------------------------------
# Directories & Modules
#-----------------------------------------------------------------------------
FRONTEND_DIR = frontend
HDL_TEMP_DIR = $(FRONTEND_DIR)/hdl_temp
DUMP_DIR = $(FRONTEND_DIR)/simulation
BACKEND_SYNTH_DIR = backend/synthesis/work
BACKEND_LAYOUT_DIR = $(BACKEND_DIR)/layout
BACKEND_LAYOUT_WORK_DIR = $(BACKEND_DIR)/layout/work
CSVS_DIR = CSVs
LAYOUTKRL = backend/layout/scripts/layout.tcl

XCELIUM_MOD = cdn/xcelium/xcelium2509
GENUS_MOD = cdn/genus/genus211
INNOVUS_MOD = cdn/innovus/innovus211
INNOVUS_MOD_DDI = cdn/ddi/ddi251
IMC_MOD = cdn/vmanager/vmanager239

#===================================================================================================
# UVM & Verification Directories - Currently not useful for the Multiplier32FP project as the files
# for it (i.e. UVM item, sequencer, driver, monitor...) aren't implemented.
VERIF_DIR = verification
VHD_PATHS = $(FRONTEND_DIR)/$(DESIGNS).vhd
UVM_FILELIST = $(VERIF_DIR)/filelist.f

# UVM specific Xcelium flags
XRUN_UVM_FLAGS = -clean -64bit -sv -v200x -v93 -uvm -sv $(VHD_PATHS) -f $(UVM_FILELIST) -top somador_top -access +rwc $(GUI_FLAG) -coverage u -covoverwrite +VETOR_PATH=$(PROJECT_DIR)/frontend/vetor.txt
#===================================================================================================

# GUI Control
GUI ?= 0
ifeq ($(GUI), 1)
	GUI_FLAG = -gui
else
	GUI_FLAG =
endif

GUI_VCD ?= 0
ifeq ($(GUI_VCD), 1)
	GUI_FLAG_VCD = -gui
else
	GUI_FLAG_VCD = -input $(PROJECT_DIR)/frontend/generate_vcd.tcl
endif

# --- Testbench Selection ---
# VECT=1 : Usa o vetor de testes.
# VECT=0 : Usa o testbench funcional
VECT ?= 0
ifeq ($(VECT), 1)
	TB_MODULE_NAME = $(DESIGNS)_vect_tb
	TB_MAIN_FILE = $(PROJECT_DIR)/$(FRONTEND_DIR)/$(TB_MODULE_NAME).sv
	TB_DUV = $(TB_MODULE_NAME).DUV
else
	TB_MODULE_NAME = $(DESIGNS)_tb
	TB_MAIN_FILE = $(PROJECT_DIR)/$(FRONTEND_DIR)/$(TB_MODULE_NAME).sv
	TB_DUV = :DUV
endif

# Xcelium (Frontend generic RTL simulation with filelist)
RTL_FILELIST = $(PROJECT_DIR)/$(FRONTEND_DIR)/filelist.f

# Example of the corrected parameter syntax:
XRUN_FLAGS = -clean -64bit -sv -v200x -v93 -f $(RTL_FILELIST) -top $(TB_MODULE_NAME) -access +rwc ${GUI_FLAG} -defparam $(TB_MODULE_NAME).HALF_PERIOD_PS=$(HALF_PERIOD_PS) -defparam $(TB_MODULE_NAME).WAIT_TIME_NS=$(WAIT_TIME_NS)
# Genus (Synthesis flags)
SYNTH_SCRIPT = ../scripts/synth.tcl
GENUS_FLAGS = -abort_on_error -lic_startup Genus_Synthesis -lic_startup_options Genus_Physical_Opt -log genus_$(FREQ_MHZ)MHz_$(LIB_TYPE) -overwrite -f $(SYNTH_SCRIPT)

# Post-Synthesis Monitor flags
XRUN_POST_FLAGS = -timescale 1ns/10ps -mess -64bit -sv -v200x -v93 -iocondsort -access +rwc -clean -input $(PROJECT_DIR)/frontend/monitor.tcl -defparam $(TB_MODULE_NAME).HALF_PERIOD_PS=$(HALF_PERIOD_PS) -defparam $(TB_MODULE_NAME).WAIT_TIME_NS=$(WAIT_TIME_NS) -defparam $(TB_MODULE_NAME).SIM_RUNTIME=$(RUNTIME)

# Top-level and SDF configurations for parameterized gate-level simulations
TOP_MODULE	  = -top $(TB_MODULE_NAME)
SDF_CMD		 = -sdf_cmd_file $(PROJECT_DIR)/frontend/sdf_cmd_file.cmd
SDF_FILE		= $(BACKEND_DIR)/layout/deliverables/$(DESIGNS)_$(LIB_TYPE)_$(FREQ_MHZ)_0/$(DESIGNS).sdf.X
SDF_FILE_SYNTH  = $(BACKEND_DIR)/synthesis/deliverables/$(DESIGNS)_$(LIB_TYPE)_$(FREQ_MHZ)_0/$(DESIGNS).sdf

# Tech files & netlists
TECH_V_LIB	  = $(TECH_DIR)/gsclib045_all_v4.4/gsclib045/verilog/slow_vdd1v0_basicCells.v
NETLIST_FILE	= $(BACKEND_DIR)/synthesis/deliverables/$(DESIGNS)_$(LIB_TYPE)_$(FREQ_MHZ)_0/$(DESIGNS).v
TB_FILES		= $(TB_MAIN_FILE)
NETLIST_FILE_POST_LAYOUT = $(BACKEND_DIR)/layout/deliverables/$(DESIGNS)_$(LIB_TYPE)_$(FREQ_MHZ)_0/$(DESIGNS).v

# Post-Synthesis VCD Generation flags
XRUN_GLS_VCD_FLAGS = -timescale 1ns/10ps -mess -64bit -sv -v200x -v93 -iocondsort -access +rwc ${GUI_FLAG_VCD} -clean -defparam $(TB_MODULE_NAME).HALF_PERIOD_PS=$(HALF_PERIOD_PS) -defparam $(TB_MODULE_NAME).WAIT_TIME_NS=$(WAIT_TIME_NS) -defparam $(TB_MODULE_NAME).SIM_RUNTIME=$(RUNTIME)

# Layout and Post-Layout Simulation flags
LAYOUT_SCRIPT = ${BACKEND_LAYOUT_DIR}/scripts/layout.tcl
POWER_SCRIPT  = ${BACKEND_LAYOUT_DIR}/scripts/power.tcl
POWER_SCRIPT_RUNTIME0  = ${BACKEND_LAYOUT_DIR}/scripts/power_runtime0.tcl
INNOVUS_FLAGS = -stylus -no_gui -init $(LAYOUT_SCRIPT) -overwrite -log innovus_$(FREQ_MHZ)MHz_$(LIB_TYPE).log
XRUN_POST_LAYOUT_FLAGS = -timescale 1ns/10ps -mess -64bit -sv -v200x -v93 -iocondsort -access +rwc -clean ${GUI_FLAG_VCD} -defparam $(TB_MODULE_NAME).HALF_PERIOD_PS=$(HALF_PERIOD_PS) -defparam $(TB_MODULE_NAME).WAIT_TIME_NS=$(WAIT_TIME_NS) -defparam $(TB_MODULE_NAME).SIM_RUNTIME=$(RUNTIME)
GENUS_LAYOUT_FLAGS = -abort_on_error -lic_startup Genus_Synthesis -lic_startup_options Genus_Physical_Opt -log genus_$(FREQ_MHZ)MHz_$(LIB_TYPE) -overwrite -f $(LAYOUT_SCRIPT)

# Default target
all: sim_rtl

# =========================================================================
# Execution Commands
# =========================================================================

# Runs the RTL simulation using Xcelium with the specified flags. 
sim_rtl:
	bash -l -c "module add $(XCELIUM_MOD) && cd $(FRONTEND_DIR) && xrun $(XRUN_FLAGS)"

# Checks if a synthesis folder already exists for the given frequency and runtime. If it does, it skips synthesis; 
# otherwise, it runs Genus with the specified flags.
synth:
	@MATCHING_DIR=$$(find $(BACKEND_DIR)/synthesis/reports -maxdepth 1 -type d -name "$(DESIGNS)_$(LIB_TYPE)_$(FREQ_MHZ)_$(RUNTIME)" 2>/dev/null | head -n 1); \
	if [ -n "$$MATCHING_DIR" ] && [ "$(VCD)" != "1" ]; then \
		echo "==============================================================="; \
		echo "INFO: Synthesis folder for $(FREQ_MHZ) MHz and runtime $(RUNTIME) already exists."; \
		echo "Found: $$MATCHING_DIR"; \
		echo "Skipping Genus."; \
		echo "==============================================================="; \
	else \
		mkdir -p $(BACKEND_DIR)/synthesis/reports/$(DESIGNS)_$(LIB_TYPE)_$(FREQ_MHZ)_$(RUNTIME); \
		mkdir -p $(BACKEND_DIR)/synthesis/deliverables/$(DESIGNS)_$(LIB_TYPE)_$(FREQ_MHZ)_$(RUNTIME); \
		bash -l -c "module add $(GENUS_MOD) && cd $(BACKEND_SYNTH_DIR) && genus $(GENUS_FLAGS)"; \
	fi

# Calculates power using Genus with the generated VCD (if RUNTIME > 0) or vectorless (if RUNTIME = 0)
power_synth:
	@mkdir -p $(BACKEND_DIR)/synthesis/reports/$(DESIGNS)_$(LIB_TYPE)_$(FREQ_MHZ)_$(RUNTIME)
	@echo "==============================================================="
	@echo "Running Fast Power Analysis via Genus DB: $(FREQ_MHZ) MHz | $(RUNTIME)ns"
	@echo "==============================================================="
	bash -l -c "module add $(GENUS_MOD) && cd $(BACKEND_SYNTH_DIR) && genus -abort_on_error -lic_startup Genus_Synthesis -lic_startup_options Genus_Physical_Opt -log genus_power_$(FREQ_MHZ)MHz_$(RUNTIME) -overwrite -f ../scripts/power_genus.tcl"


# Checks if a layout folder already exists for the given frequency and runtime. If it does, it skips Innovus Layout; 
# otherwise, it runs Innovus with the specified flags.
layout_innovus:
	@MATCHING_DIR=$$(find $(LAYOUT_DIR)/reports -maxdepth 1 -type d -name "$(DESIGNS)_$(LIB_TYPE)_$(FREQ_MHZ)_$(RUNTIME)" 2>/dev/null | head -n 1); \
	if [ -n "$$MATCHING_DIR" ]; then \
		echo "==============================================================="; \
		echo "INFO: Layout folder for $(FREQ_MHZ) MHz and runtime $(RUNTIME) already exists."; \
		echo "Found: $$MATCHING_DIR"; \
		echo "Skipping Innovus Layout."; \
		echo "==============================================================="; \
	else \
		mkdir -p $(LAYOUT_DIR)/work; \
		mkdir -p $(LAYOUT_DIR)/reports/$(DESIGNS)_$(LIB_TYPE)_$(FREQ_MHZ)_$(RUNTIME); \
		mkdir -p $(LAYOUT_DIR)/deliverables/$(DESIGNS)_$(LIB_TYPE)_$(FREQ_MHZ)_$(RUNTIME); \
		bash -l -c "module add $(INNOVUS_MOD_DDI) && cd $(LAYOUT_DIR)/work && innovus $(INNOVUS_FLAGS)"; \
	fi

# Calculates power using Innovus with the generated VCD (if RUNTIME > 0) or vectorless (if RUNTIME = 0)
innovus_power:
	@mkdir -p $(LAYOUT_DIR)/reports/$(DESIGNS)_$(LIB_TYPE)_$(FREQ_MHZ)_$(RUNTIME)
	@if [ "$(RUNTIME)" = "0" ]; then \
		echo "==============================================================="; \
		echo "INFO: RUNTIME is 0. Running vectorless power analysis."; \
		echo "Script: power_runtime0.tcl"; \
		echo "==============================================================="; \
		bash -l -c "module add $(INNOVUS_MOD_DDI) && cd $(LAYOUT_DIR)/work && innovus -stylus -no_gui -init $(POWER_SCRIPT_RUNTIME0) -overwrite -log innovus_power_$(FREQ_MHZ)MHz_0.log"; \
	else \
		echo "==============================================================="; \
		echo "INFO: RUNTIME is $(RUNTIME). Running VCD-based power analysis."; \
		echo "Script: power.tcl"; \
		echo "==============================================================="; \
		bash -l -c "module add $(INNOVUS_MOD_DDI) && cd $(LAYOUT_DIR)/work && innovus -stylus -no_gui -init $(POWER_SCRIPT) -overwrite -log innovus_power_$(FREQ_MHZ)MHz_$(RUNTIME).log"; \
	fi

# Simulation for generation of the VCD after logic synthesis (with SDF from synthesis)
sim_gls_vcd: sim_rtl
	@mkdir -p $(DUMP_DIR)
	@mkdir -p $(CSVS_DIR)
	@echo "Generating dynamic SDF command file..."
	@echo 'COMPILED_SDF_FILE = "$(SDF_FILE_SYNTH)",' > $(PROJECT_DIR)/frontend/sdf_cmd_file.cmd
	@echo 'SCOPE = $(TB_DUV),' >> $(PROJECT_DIR)/frontend/sdf_cmd_file.cmd
	@echo 'LOG_FILE = "sdf.log",' >> $(PROJECT_DIR)/frontend/sdf_cmd_file.cmd
	@echo 'MTM_CONTROL = "MAXIMUM",' >> $(PROJECT_DIR)/frontend/sdf_cmd_file.cmd
	@echo 'SCALE_FACTORS = "1.0:1.0:1.0",' >> $(PROJECT_DIR)/frontend/sdf_cmd_file.cmd
	@echo 'SCALE_TYPE = "FROM_MTM";' >> $(PROJECT_DIR)/frontend/sdf_cmd_file.cmd
	bash -l -c "module add $(XCELIUM_MOD) && \
			cd $(FRONTEND_DIR) && \
			xrun $(XRUN_GLS_VCD_FLAGS) \
			$(TECH_V_LIB) \
			$(NETLIST_FILE) \
			$(TB_FILES) \
			$(TOP_MODULE) \
			$(SDF_CMD)"
			
# Simulation for generation of the VCD after physical synthesis
sim_post_layout: sim_rtl
	@mkdir -p $(DUMP_DIR)
	@mkdir -p $(CSVS_DIR)
	@echo "Generating dynamic SDF command file..."
	@echo 'COMPILED_SDF_FILE = "$(SDF_FILE)",' > $(PROJECT_DIR)/frontend/sdf_cmd_file.cmd
	@echo 'SCOPE = $(TB_DUV),' >> $(PROJECT_DIR)/frontend/sdf_cmd_file.cmd
	@echo 'LOG_FILE = "sdf.log",' >> $(PROJECT_DIR)/frontend/sdf_cmd_file.cmd
	@echo 'MTM_CONTROL = "MAXIMUM",' >> $(PROJECT_DIR)/frontend/sdf_cmd_file.cmd
	@echo 'SCALE_FACTORS = "1.0:1.0:1.0",' >> $(PROJECT_DIR)/frontend/sdf_cmd_file.cmd
	@echo 'SCALE_TYPE = "FROM_MTM";' >> $(PROJECT_DIR)/frontend/sdf_cmd_file.cmd
	bash -l -c "module add $(XCELIUM_MOD) && \
			cd $(FRONTEND_DIR) && \
			xrun $(XRUN_POST_LAYOUT_FLAGS) \
			$(TECH_V_LIB) \
			$(NETLIST_FILE_POST_LAYOUT) \
			$(TB_FILES) \
			$(TOP_MODULE) \
			$(SDF_CMD)"

# =========================================================================
# Parameter Sweeps & Extractions
# =========================================================================

# Faz a síntese base e gera os VCDs e os power reports para X e 2X
vcd_synth:
	@echo "=================================================="
	@echo "1. Running base synthesis to generate netlist and SDF, and running base power analysis"
	@echo "=================================================="
	$(MAKE) synth FREQ_MHZ=$(FREQ_MHZ) LIB_TYPE=$(LIB_TYPE) RUNTIME=0
	$(MAKE) power_synth FREQ_MHZ=$(FREQ_MHZ) LIB_TYPE=$(LIB_TYPE) RUNTIME=0
	@echo "=================================================="
	@echo "2. Running simulation for $(FREQ_MHZ) MHz to generate VCD"
	@echo "=================================================="
	@mkdir -p $(FRONTEND_DIR)/VCDs
	$(MAKE) sim_gls_vcd FREQ_MHZ=$(FREQ_MHZ) LIB_TYPE=$(LIB_TYPE) RUNTIME=$(CALC_RUNTIME) VECT=1
	@echo "=================================================="
	@echo "3. Running fast power analysis with VCD"
	@echo "=================================================="
	$(MAKE) power_synth FREQ_MHZ=$(FREQ_MHZ) LIB_TYPE=$(LIB_TYPE) RUNTIME=$(CALC_RUNTIME)
	@echo "=================================================="
	@echo "4. Running simulation for $(FREQ_MHZ) MHz to generate VCD with 2X Runtime"
	@echo "=================================================="
	@mkdir -p $(FRONTEND_DIR)/VCDs
	$(MAKE) sim_gls_vcd FREQ_MHZ=$(FREQ_MHZ) LIB_TYPE=$(LIB_TYPE) RUNTIME=$(CALC_RUNTIME2) VECT=1
	@echo "=================================================="
	@echo "5. Running fast power analysis with VCD and 2X Runtime"
	@echo "=================================================="
	$(MAKE) power_synth FREQ_MHZ=$(FREQ_MHZ) LIB_TYPE=$(LIB_TYPE) RUNTIME=$(CALC_RUNTIME2)

# Runs logic synthesis -> physical synthesis -> post layout simulation for VCD (X and 2X) -> generates power reports
vcd_layout:
	@echo "=================================================="
	@echo "1. Running base layout (requires base synth first)"
	@echo "=================================================="
	$(MAKE) synth FREQ_MHZ=$(FREQ_MHZ) LIB_TYPE=$(LIB_TYPE) RUNTIME=0
	$(MAKE) layout_innovus FREQ_MHZ=$(FREQ_MHZ) LIB_TYPE=$(LIB_TYPE) RUNTIME=0
	@mkdir -p $(FRONTEND_DIR)/VCDs
	@echo "=================================================="
	@echo "2. Running Post-Layout power analysis with VCD"
	@echo "=================================================="
	$(MAKE) innovus_power FREQ_MHZ=$(FREQ_MHZ) LIB_TYPE=$(LIB_TYPE) RUNTIME=0
	@echo "=================================================="
	@echo "3. Running Post-Layout simulation for $(FREQ_MHZ) MHz to generate VCD with X Runtime"
	@echo "=================================================="
	$(MAKE) sim_post_layout FREQ_MHZ=$(FREQ_MHZ) LIB_TYPE=$(LIB_TYPE) RUNTIME=$(CALC_RUNTIME) VECT=1
	@echo "=================================================="
	@echo "4. Running Post-Layout power analysis with VCD"
	@echo "=================================================="
	$(MAKE) innovus_power FREQ_MHZ=$(FREQ_MHZ) LIB_TYPE=$(LIB_TYPE) RUNTIME=$(CALC_RUNTIME)
	@echo "=================================================="
	@echo "5. Running Post-Layout simulation for $(FREQ_MHZ) MHz to generate VCD with 2X Runtime"
	@echo "=================================================="
	$(MAKE) sim_post_layout FREQ_MHZ=$(FREQ_MHZ) LIB_TYPE=$(LIB_TYPE) RUNTIME=$(CALC_RUNTIME2) VECT=1
	@echo "=================================================="
	@echo "6. Running Post-Layout power analysis with VCD and 2X Runtime"
	@echo "=================================================="
	$(MAKE) innovus_power FREQ_MHZ=$(FREQ_MHZ) LIB_TYPE=$(LIB_TYPE) RUNTIME=$(CALC_RUNTIME2)

# Performs the full flow of synthesis, layout, post-layout simulation, and power analysis for a single configuration of frequency and library type.
flow_full_single_config:
	@echo "========================================================="
	@echo "       STEP 1: BASE LOGICAL SYNTHESIS (GENUS)         "
	@echo "========================================================="
	$(MAKE) synth FREQ_MHZ=$(FREQ_MHZ) LIB_TYPE=$(LIB_TYPE) RUNTIME=0
	@echo "========================================================="
	@echo "       STEP 2: BASE PHYSICAL SYNTHESIS (INNOVUS)      "
	@echo "========================================================="
	$(MAKE) layout_innovus FREQ_MHZ=$(FREQ_MHZ) LIB_TYPE=$(LIB_TYPE) RUNTIME=0
	@echo "========================================================="
	@echo "       STEP 3: POST-LAYOUT SIMULATION (XCELIUM)       "
	@echo "========================================================="
	@mkdir -p $(FRONTEND_DIR)/VCDs
	$(MAKE) sim_post_layout FREQ_MHZ=$(FREQ_MHZ) LIB_TYPE=$(LIB_TYPE) RUNTIME=$(RUNTIME) VECT=1
	@echo "========================================================="
	@echo "       STEP 4: POST-LAYOUT POWER ANALYSIS (INNOVUS)   "
	@echo "========================================================="
	$(MAKE) innovus_power FREQ_MHZ=$(FREQ_MHZ) LIB_TYPE=$(LIB_TYPE) RUNTIME=$(RUNTIME)

# These targets perform a frequency sweep to find the maximum operational frequency for both synthesis and layout. 
# The synthesis sweep starts from a defined frequency and increments until negative slack is reached. 
# The layout sweep starts from a high frequency and decrements until negative slack is found.

# =========================================================================
# Maximum Frequency Finder Sweep
# =========================================================================

# Values for START_FREQ_SYNTH and FREQ_STEP_SYNTH can be overridden when invoking make, e.g.:
# make find_max_freq START_FREQ=50 FREQ_STEP=5
# Will start the synthesis frequency sweep at 50 MHz and increment by 5 MHz each step.
export START_FREQ_SYNTH ?= 100
export FREQ_STEP_SYNTH ?= 1

find_max_freq:
	@echo "==============================================================="
	@echo "Starting frequency sweep to find maximum operational frequency."
	@echo "==============================================================="
	@freq=$(START_FREQ_SYNTH); \
	step=$(FREQ_STEP_SYNTH); \
	while true; do \
		echo "Testing FREQ_MHZ=$$freq MHz..."; \
		$(MAKE) synth FREQ_MHZ=$$freq; \
		rpt_file="$(BACKEND_DIR)/synthesis/reports/$(DESIGNS)_$(LIB_TYPE)_$${freq}_$(RUNTIME)/$(DESIGNS)_timing.rpt"; \
		if [ ! -f "$$rpt_file" ]; then \
			echo "Error: Timing report not found ($$rpt_file). Did synthesis fail?"; \
			break; \
		fi; \
		slack=$$(grep -i -E "^\s*Slack:=" "$$rpt_file" | head -n 1 | awk -F'[:=]+' '{print $$2}' | tr -d '[:space:]'); \
		if [ -z "$$slack" ]; then \
			echo "Error: Could not extract slack from report."; \
			break; \
		fi; \
		echo "Result: $$freq MHz -> Slack: $$slack ps"; \
		if echo "$$slack" | awk '{if ($$1 <= -50) exit 0; else exit 1}'; then \
			echo "==============================================================="; \
			echo "Negative slack reached at $$freq MHz."; \
			prev_freq=$$((freq - step)); \
			echo "Max positive slack frequency is approximately $$prev_freq MHz."; \
			echo "==============================================================="; \
			break; \
		fi; \
		freq=$$((freq + step)); \
	done

# =========================================================================
# Layout Maximum Frequency Finder Sweep
# =========================================================================

# Values for START_FREQ_LAYOUT and FREQ_STEP_LAYOUT can be overridden when invoking make, e.g.:
# make find_max_freq_layout START_FREQ_LAYOUT=50 FREQ_STEP_LAYOUT=5
# Will start the layout frequency reverse-sweep at 50 MHz and decrement by 5 MHz each step.
export START_FREQ_LAYOUT ?= 372
export FREQ_STEP_LAYOUT ?= 25

find_max_freq_layout:
	@echo "==============================================================="
	@echo "Starting layout frequency reverse-sweep."
	@echo "==============================================================="
	@freq=$(START_FREQ_LAYOUT); \
	step=$(FREQ_STEP_LAYOUT); \
	while true; do \
		if [ $$freq -le 0 ]; then \
			echo "Reached 0 MHz. Failing out."; \
			break; \
		fi; \
		echo "Testing FREQ_MHZ=$$freq MHz..."; \
		$(MAKE) synth FREQ_MHZ=$$freq RUNTIME=0; \
		$(MAKE) layout_innovus FREQ_MHZ=$$freq RUNTIME=0; \
		setup_rpt="$(BACKEND_DIR)/layout/reports/$(DESIGNS)_$(LIB_TYPE)_$${freq}_0/setup_timing.rpt"; \
		hold_rpt="$(BACKEND_DIR)/layout/reports/$(DESIGNS)_$(LIB_TYPE)_$${freq}_0/hold_timing.rpt"; \
		if [ ! -f "$$setup_rpt" ] || [ ! -f "$$hold_rpt" ]; then \
			echo "Error: Layout timing reports not found. Did Innovus fail?"; \
			break; \
		fi; \
		setup_slack=$$(grep -i -E "^\s*Slack\s*[:=]+" "$$setup_rpt" | head -n 1 | awk -F'[:=]+' '{print $$2}' | tr -d '[:space:]psns'); \
		hold_slack=$$(grep -i -E "^\s*Slack\s*[:=]+" "$$hold_rpt" | head -n 1 | awk -F'[:=]+' '{print $$2}' | tr -d '[:space:]psns'); \
		echo "Result: $$freq MHz -> Setup Slack: $$setup_slack | Hold Slack: $$hold_slack"; \
		if echo "$$setup_slack" | grep -q "^-" || echo "$$hold_slack" | grep -q "^-"; then \
			echo "Negative slack found. Lowering frequency..."; \
			freq=$$((freq - step)); \
		else \
			echo "==============================================================="; \
			echo "Max operational layout frequency found: $$freq MHz."; \
			echo "==============================================================="; \
			break; \
		fi; \
	done


# =========================================================================
# Utilities & Visualizers
# =========================================================================
		
# Launches the Genus Schematic Viewer with the specified frequency and library type. 
genus_gui:
	@echo "==============================================================="
	@echo "Launching Genus Schematic Viewer: $(FREQ_MHZ) MHz | $(LIB_TYPE)"
	@echo "==============================================================="
	bash -l -c "module add $(GENUS_MOD) && cd $(BACKEND_SYNTH_DIR) && genus -gui -f ../scripts/view_design.tcl"

# Launches the Innovus GUI for layout visualization with the specified frequency and library type. # It provides informational messages about the launch and uses a bash command to load the Innovus module and execute the viewer with the appropriate script.
innovus_gui:
	@echo "==============================================================="
	@echo "Launching Innovus GUI for: $(FREQ_MHZ) MHz | $(LIB_TYPE) library"
	@echo "Script: ../scripts/view_layout.tcl"
	@echo "==============================================================="
	bash -l -c "module add $(INNOVUS_MOD_DDI) && cd $(BACKEND_LAYOUT_WORK_DIR) && innovus -stylus -init ../scripts/view_layout.tcl"
		
# Old target, not tested.
# Used to evaluate timing slack when a netlist synthesized for one frequency
# is analyzed at another target frequency. This helps compare the margin
# available against a design synthesized for the target frequency.
# E.g. if you synthesize for 372 MHz but want to see how it performs at 300 MHz, you can set SYNTH_FREQ=372 and TEST_FREQ=300 when invoking this target.
# and it will run the timing analysis with the netlist synthesized at 372 MHz but using a test frequency of 300 MHz to see the slack margin.
# Probably needs to be refactored to work with the current environment structure
cross_sta:
	@echo "==============================================================="
	@echo "Running Static Timing Analysis"
	@echo "Netlist: $(SYNTH_FREQ) MHz  |  Testing at: $(TEST_FREQ) MHz"
	@echo "==============================================================="
	bash -l -c "module add $(GENUS_MOD) && \
		export SYNTH_FREQ=$(SYNTH_FREQ) && \
		export TEST_FREQ=$(TEST_FREQ) && \
		cd $(BACKEND_SYNTH_DIR) && \
		genus -abort_on_error -log genus_cross_sta -overwrite -f ../scripts/cross_timing.tcl"
		
# Old target, not tested. 
# Used for running UVM mixed-language simulations. 
# The actual implementation of the UVM testbench and files is not present in the current project structure, so this target serves as a placeholder for future UVM integration.
uvm_sim:
	@echo "=================================================="
	@echo "Running UVM Mixed-Language Simulation..."
	@echo "=================================================="
	bash -l -c "module add $(INNOVUS_MOD_DDI) && xrun $(XRUN_UVM_FLAGS)"

# Old target, not tested.
# Used to launch the Cadence IMC Coverage Viewer for analyzing coverage data generated from simulations.
# Mut be run after uvm_sim
cov_gui:
	@echo "=================================================="
	@echo "Launching Cadence IMC Coverage Viewer..."
	@echo "=================================================="
	bash -l -c "module add $(IMC_MOD) && module add $(XCELIUM_MOD) && imc -load cov_work/scope/test"

# =========================================================================
# Cleaning Targets
# =========================================================================

# Basic clean target that removes temporary logs, simulation data, and history files generated by Xcelium, Genus, and Innovus. It also provides an informational message about the 'clean_all' target for deeper cleaning.
clean:
	@echo "=================================================="
	@echo "Cleaning temporary logs, simulation data, and history..."
	@echo "=================================================="
	rm -rf $(FRONTEND_DIR)/xcelium.d $(FRONTEND_DIR)/xrun.history $(FRONTEND_DIR)/xrun.log*
	rm -rf $(FRONTEND_DIR)/.simvision $(FRONTEND_DIR)/xrun.key $(FRONTEND_DIR)/waves.shm
	rm -rf $(FRONTEND_DIR)/work/* $(FRONTEND_DIR)/sdf.log $(FRONTEND_DIR)/vcd_sim.log $(FRONTEND_DIR)/*.sdf.X
	rm -rf $(BACKEND_SYNTH_DIR)/genus* $(BACKEND_SYNTH_DIR)/fv $(BACKEND_SYNTH_DIR)/rc*
	rm -rf $(BACKEND_LAYOUT_DIR)/innovus* $(BACKEND_LAYOUT_DIR)/*.log* $(BACKEND_LAYOUT_DIR)/*.cmd*
	rm -rf $(BACKEND_LAYOUT_DIR)/work/* $(BACKEND_SYNTH_DIR)/work/* $(FRONTEND_DIR)/VCDs
	@echo "=================================================="
	@echo "INFO: Run 'make clean_all' to permanently delete all VCDs, .db files, and reports."
	@echo "=================================================="

# The 'clean_all' target performs a deep clean by removing all VCD files, 
# synthesis and layout reports, deliverables, and any generated .db files. 
# This is intended for users who want to completely reset the project state and free up disk space after multiple runs.
# BE WARNED THAT THIS WILL DELETE ALL GENERATED DATA INCLUDING VCDs, REPORTS, DELIVERABLES, AND .DB FILES WITHOUT PROMPTING FOR CONFIRMATION.
# YOU WILL LOSE ALL SYNTHESIS AND LAYOUT RESULTS, POWER REPORTS, AND SIMULATION VCDs. USE THIS TARGET ONLY IF YOU ARE SURE YOU WANT TO PERMANENTLY DELETE ALL GENERATED DATA.
clean_all: clean
	@echo "=================================================="
	@echo "Deep cleaning: Removing all VCDs, Reports, CSVs, and Deliverables..."
	@echo "=================================================="
	rm -rf $(FRONTEND_DIR)/VCDs
	rm -rf $(CSVS_DIR)
	rm -rf $(BACKEND_DIR)/synthesis/reports/*
	rm -rf $(BACKEND_DIR)/synthesis/deliverables/*
	rm -rf $(BACKEND_DIR)/layout/reports/*
	rm -rf $(BACKEND_DIR)/layout/deliverables/*
	@echo "Project reset complete."

# =========================================================================
# Help Menu
# =========================================================================

help:
	@echo "========================================================================================="
	@echo "                             MAKEFILE COMMAND REFERENCE                             "
	@echo "========================================================================================="
	@echo "Usage: make <target> [VARIABLE=value]"
	@echo "Example: make vcd_layout FREQ_MHZ=372 LIB_TYPE=worst"
	@echo ""
	@echo "Key Variables (can be overridden from command line):"
	@echo "  FREQ_MHZ          : Target frequency in MHz (Default: 100)."
	@echo "  LIB_TYPE          : Library operating condition (Default: worst). Options: worst, best."
	@echo "  RUNTIME           : Simulation runtime in ns (Default: dynamically calculated or 0)."
	@echo "  VECT              : Set to 1 to use the vector-based testbench (Default: 0)."
	@echo "  GUI               : Set to 1 to open Xcelium GUI for RTL sim (Default: 0)."
	@echo "  GUI_VCD           : Set to 1 to open Xcelium GUI for GLS/VCD sim (Default: 0)."
	@echo "  START_FREQ_SYNTH  : Starting frequency (MHz) for logical find_max_freq (Default: 100)."
	@echo "  FREQ_STEP_SYNTH   : Step size (MHz) for logical find_max_freq (Default: 1)."
	@echo "  START_FREQ_LAYOUT : Starting frequency (MHz) for physical find_max_freq_layout (Default: 372)."
	@echo "  FREQ_STEP_LAYOUT  : Step size (MHz) for physical find_max_freq_layout (Default: 25)."
	@echo ""
	@echo "Core Execution Targets:"
	@echo "  all                     : Default target, runs sim_rtl."
	@echo "  flow_full_single_config : Execute complete flow (synth -> layout -> sim -> power)."
	@echo "  sim_rtl                 : Run standard frontend RTL simulation in Xcelium."
	@echo "  synth                   : Run logic synthesis using Genus (generates .db for power analysis)."
	@echo "  power_synth             : Run fast power analysis using a saved Genus .db and VCD file."
	@echo "  vcd_synth               : Run base synth, VCD generation (X and 2X), and logical power analysis."
	@echo "  layout_innovus          : Run physical design layout using Innovus."
	@echo "  innovus_power           : Run post-layout power analysis using Innovus and VCD."
	@echo "  vcd_layout              : Run base layout, VCD generation (X and 2X), and physical power analysis."
	@echo "" 
	@echo "Gate-Level Simulation (GLS) Targets:"
	@echo "  sim_gls_vcd             : Post-synthesis simulation with VCD generation."
	@echo "  sim_post_layout         : Post-layout simulation using Innovus SDF."
	@echo ""
	@echo "Parameter Sweeps & Batch Analysis:"
	@echo "  find_max_freq           : Sweep frequencies upward to find max logical synthesis freq."
	@echo "  find_max_freq_layout    : Sweep frequencies downward to find max physical layout freq."
	@echo ""
	@echo "Utilities & Visualizers:"
	@echo "  setup_dirs              : Initialize the project directory tree."
	@echo "  genus_gui               : Open the Genus Schematic Viewer for the current parameters."
	@echo "  innovus_gui             : Open the Innovus GUI with the generated netlist."
	@echo "  clean                   : Remove simulator logs, history, and workspace temp files."
	@echo "  clean_all               : Deep clean. Removes ALL deliverables, reports, .db files, and VCDs."
	@echo ""
	@echo "Legacy / Untested Targets:"
	@echo "  cross_sta               : Run Static Timing Analysis (requires SYNTH_FREQ & TEST_FREQ)."
	@echo "  uvm_sim                 : Run UVM mixed-language simulation."
	@echo "  cov_gui                 : Open Cadence IMC Coverage Viewer."
	@echo "========================================================================================="
	@echo "Example: make vcd_layout FREQ_MHZ=372 LIB_TYPE=worst"
	@echo "========================================================================================="

# =========================================================================
# Workspace Setup
# =========================================================================

setup_dirs:
	@echo "=================================================="
	@echo "Initializing project directory tree..."
	@echo "=================================================="
	@mkdir -p $(HDL_TEMP_DIR)
	@mkdir -p $(DUMP_DIR)
	@mkdir -p $(FRONTEND_DIR)/VCDs
	@mkdir -p $(CSVS_DIR)
	@mkdir -p $(BACKEND_DIR)/layout/constraints
	@mkdir -p $(BACKEND_DIR)/layout/deliverables
	@mkdir -p $(BACKEND_DIR)/layout/reports
	@mkdir -p $(BACKEND_DIR)/layout/scripts
	@mkdir -p $(BACKEND_DIR)/layout/work
	@mkdir -p $(BACKEND_DIR)/synthesis/constraints
	@mkdir -p $(BACKEND_DIR)/synthesis/deliverables
	@mkdir -p $(BACKEND_DIR)/synthesis/reports
	@mkdir -p $(BACKEND_DIR)/synthesis/scripts
	@mkdir -p $(BACKEND_DIR)/synthesis/work
	@echo "Directory tree initialized."
