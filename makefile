# Define bash as the shell to allow module loading
SHELL := /bin/bash

# Define default synthesis parameters
export FREQ_MHZ ?= 100
export LIB_TYPE ?= worst
export RUNTIME ?= 500

# --- Translate Frequency to Clock Half-Period and Wait Time ---
# Use 'strip' to protect against invisible trailing spaces breaking the ifeq
CLEAN_FREQ = $(strip $(FREQ_MHZ))

ifeq ($(CLEAN_FREQ), 100)
    HALF_PERIOD_PS = 5000
    WAIT_TIME_NS = 5000
    PERIOD_CLK = 10.0
else ifeq ($(CLEAN_FREQ), 500)
    HALF_PERIOD_PS = 1000
    WAIT_TIME_NS = 100
    PERIOD_CLK = 2.0
else ifeq ($(CLEAN_FREQ), 1000)
    HALF_PERIOD_PS = 500
    WAIT_TIME_NS = 50
    PERIOD_CLK = 1.0
else
    HALF_PERIOD_PS = 50000
    WAIT_TIME_NS = 5000
    PERIOD_CLK = 100.0
endif

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

export LEFT_CORE_PINS = {a_i[0]} {a_i[1]} {a_i[2]} {a_i[3]} {a_i[4]} {a_i[5]} {a_i[6]} {a_i[7]}
export TOP_CORE_PINS = {b_i[0]} {b_i[1]} {b_i[2]} {b_i[3]} {b_i[4]} {b_i[5]} {b_i[6]} {b_i[7]}
export RIGHT_CORE_PINS = {sum_o[0]} {sum_o[1]} {sum_o[2]} {sum_o[3]} {sum_o[4]} {sum_o[5]} {sum_o[6]} {sum_o[7]}
export BOTTOM_CORE_PINS = carry_i carry_o clk rst_n

#-----------------------------------------------------------------------------
# Directories & Modules
#-----------------------------------------------------------------------------
FRONTEND_DIR = frontend
HDL_TEMP_DIR = $(FRONTEND_DIR)/hdl_temp
DUMP_DIR = $(FRONTEND_DIR)/simulation
BACKEND_SYNTH_DIR = backend/synthesis/work
BACKEND_LAYOUT_DIR = backend/layout/work
CSVS_DIR = CSVs

XCELIUM_MOD = cdn/xcelium/xcelium2509
GENUS_MOD = cdn/genus/genus211
INNOVUS_MOD = cdn/innovus/innovus211
INNOVUS_MOD_DDI = cdn/ddi/ddi251
IMC_MOD = cdn/vmanager/vmanager239

#===================================================================================================
# UVM & Verification Directories
VERIF_DIR = verification
VHD_PATHS = $(FRONTEND_DIR)/Util_package.vhd $(FRONTEND_DIR)/$(DESIGNS).vhd
UVM_FILELIST = $(VERIF_DIR)/filelist.f

# UVM specific Xcelium flags
XRUN_UVM_FLAGS = -clean -64bit -sv -v200x -v93 -uvm -sv $(VHD_PATHS) -f $(UVM_FILELIST) -top somador_top -access +rwc $(GUI_FLAG) -coverage u -covoverwrite +VETOR_PATH=$(PROJECT_DIR)/frontend/vetor.txt
#===================================================================================================

# GUI Control
GUI ?= 0
ifeq ($(GUI), 1)
    GUI_FLAG = -gui
else
    GUI_FLAG = -exit
endif

GUI_VCD ?= 0
ifeq ($(GUI_VCD), 1)
    GUI_FLAG_VCD = -gui
else
    GUI_FLAG_VCD = -input $(PROJECT_DIR)/frontend/generate_vcd.tcl
endif

# Xcelium (Frontend generic RTL simulation with filelist)
RTL_FILELIST = $(PROJECT_DIR)/$(FRONTEND_DIR)/filelist.f
XRUN_FLAGS = -input ${SCRIPT_DIR}/suppress.tcl -clean -64bit -sv -v200x -v93 -f $(RTL_FILELIST) -top $(DESIGNS)_tb -access +rwc ${GUI_FLAG} #-generic \"somador_tb:HALF_PERIOD_PS=>$(HALF_PERIOD_PS)\" -generic \"somador_tb:WAIT_TIME_NS=>$(WAIT_TIME_NS)\"

# Genus (Synthesis flags)
SYNTH_SCRIPT = ../scripts/synth.tcl
GENUS_FLAGS = -abort_on_error -lic_startup Genus_Synthesis -lic_startup_options Genus_Physical_Opt -log genus_$(FREQ_MHZ)MHz_$(LIB_TYPE) -overwrite -f $(SYNTH_SCRIPT)

# Post-Synthesis Monitor flags
XRUN_POST_FLAGS = -timescale 1ns/10ps -mess -64bit -sv -v200x -v93 -iocondsort -access +rwc -clean -input $(PROJECT_DIR)/frontend/monitor.tcl -generic \"somador_tb:HALF_PERIOD_PS=>$(HALF_PERIOD_PS)\" -generic \"somador_tb:WAIT_TIME_NS=>$(WAIT_TIME_NS)\"

# Top-level and SDF configurations for parameterized gate-level simulations
TOP_MODULE      = -top $(DESIGNS)_tb
SDF_CMD         = -sdf_cmd_file $(PROJECT_DIR)/frontend/sdf_cmd_file.cmd
SDF_FILE        = $(BACKEND_DIR)/layout/deliverables/$(DESIGNS)_$(LIB_TYPE)_$(FREQ_MHZ)_base/$(DESIGNS).sdf.X

# Tech files & netlists
TECH_V_LIB      = $(TECH_DIR)/gsclib045_all_v4.4/gsclib045/verilog/slow_vdd1v0_basicCells.v
NETLIST_FILE    = $(BACKEND_DIR)/synthesis/deliverables/$(DESIGNS)_$(LIB_TYPE)_$(FREQ_MHZ)_base/$(DESIGNS).v
TB_FILES        = $(PROJECT_DIR)/$(FRONTEND_DIR)/Util_package.vhd $(PROJECT_DIR)/$(FRONTEND_DIR)/$(DESIGNS)_tb.vhd
NETLIST_FILE_POST_LAYOUT = $(BACKEND_DIR)/synthesis/deliverables/$(DESIGNS)_$(LIB_TYPE)_$(FREQ_MHZ)_base/$(DESIGNS).v

# Post-Synthesis VCD Generation flags
XRUN_GLS_VCD_FLAGS = -timescale 1ns/10ps -mess -64bit -sv -v200x -v93 -iocondsort -access +rwc -clean ${GUI_FLAG_VCD} -generic \"somador_tb:HALF_PERIOD_PS=>$(HALF_PERIOD_PS)\" -generic \"somador_tb:WAIT_TIME_NS=>$(WAIT_TIME_NS)\"

# Layout and Post-Layout Simulation flags
LAYOUT_SCRIPT = ${SCRIPT_DIR}/layout.tcl
POWER_SCRIPT  = ${SCRIPT_DIR}/power.tcl
INNOVUS_FLAGS = -stylus -no_gui -init $(LAYOUT_SCRIPT) -overwrite -log innovus_$(FREQ_MHZ)MHz_$(LIB_TYPE).log
XRUN_POST_LAYOUT_FLAGS = -timescale 1ns/10ps -mess -64bit -sv -v200x -v93 -iocondsort -access +rwc -clean ${GUI_FLAG_VCD} -generic \"somador_tb:HALF_PERIOD_PS=>$(HALF_PERIOD_PS)\" -generic \"somador_tb:WAIT_TIME_NS=>$(WAIT_TIME_NS)\" 

GENUS_LAYOUT_FLAGS = -abort_on_error -lic_startup Genus_Synthesis -lic_startup_options Genus_Physical_Opt -log genus_$(FREQ_MHZ)MHz_$(LIB_TYPE) -overwrite -f $(LAYOUT_SCRIPT)

# Default target
all: sim_rtl

# =========================================================================
# Execution Commands
# =========================================================================

sim_rtl:
	bash -l -c "module add $(XCELIUM_MOD) && cd $(FRONTEND_DIR) && xrun $(XRUN_FLAGS)"

synth:
	@mkdir -p $(BACKEND_DIR)/synthesis/reports/$(DESIGNS)_$(LIB_TYPE)_$(FREQ_MHZ)_$(RUNTIME)
	@mkdir -p $(BACKEND_DIR)/synthesis/deliverables/$(DESIGNS)_$(LIB_TYPE)_$(FREQ_MHZ)_$(RUNTIME)
	bash -l -c "module add $(GENUS_MOD) && cd $(BACKEND_SYNTH_DIR) && genus $(GENUS_FLAGS)"

layout_innovus:
	@mkdir -p $(LAYOUT_DIR)/work
	@mkdir -p $(LAYOUT_DIR)/reports/$(DESIGNS)_$(LIB_TYPE)_$(FREQ_MHZ)_$(RUNTIME)
	@mkdir -p $(LAYOUT_DIR)/deliverables/$(DESIGNS)_$(LIB_TYPE)_$(FREQ_MHZ)_$(RUNTIME)
	bash -l -c "module add $(INNOVUS_MOD_DDI) && cd $(LAYOUT_DIR)/work && innovus $(INNOVUS_FLAGS)"
	
layout_genus:
	@mkdir -p $(BACKEND_DIR)/synthesis/reports/$(DESIGNS)_$(LIB_TYPE)_$(FREQ_MHZ)_$(RUNTIME)
	@mkdir -p $(BACKEND_DIR)/synthesis/deliverables/$(DESIGNS)_$(LIB_TYPE)_$(FREQ_MHZ)_$(RUNTIME)
	bash -l -c "module add $(INNOVUS_MOD_DDI) && cd $(BACKEND_LAYOUT_DIR) && genus $(GENUS_LAYOUT_FLAGS)"

sim_gls_monitor: sim_rtl
	@mkdir -p $(DUMP_DIR)
	@mkdir -p $(CSVS_DIR)
	@echo "Generating dynamic SDF command file..."
	@echo 'COMPILED_SDF_FILE = "$(SDF_FILE)",' > $(PROJECT_DIR)/frontend/sdf_cmd_file.cmd
	@echo 'SCOPE = :DUV,' >> $(PROJECT_DIR)/frontend/sdf_cmd_file.cmd
	@echo 'LOG_FILE = "sdf.log",' >> $(PROJECT_DIR)/frontend/sdf_cmd_file.cmd
	@echo 'MTM_CONTROL = "MAXIMUM",' >> $(PROJECT_DIR)/frontend/sdf_cmd_file.cmd
	@echo 'SCALE_FACTORS = "1.0:1.0:1.0",' >> $(PROJECT_DIR)/frontend/sdf_cmd_file.cmd
	@echo 'SCALE_TYPE = "FROM_MTM";' >> $(PROJECT_DIR)/frontend/sdf_cmd_file.cmd
	bash -l -c "module add $(XCELIUM_MOD) && \
			cd $(FRONTEND_DIR) && \
			xrun $(XRUN_POST_FLAGS) \
			$(TECH_V_LIB) \
			$(NETLIST_FILE) \
			$(TB_FILES) \
			$(TOP_MODULE) \
			$(SDF_CMD)"

sim_gls_vcd: sim_rtl
	@mkdir -p $(DUMP_DIR)
	@mkdir -p $(CSVS_DIR)
	@echo "Generating dynamic SDF command file..."
	@echo 'COMPILED_SDF_FILE = "$(SDF_FILE)",' > $(PROJECT_DIR)/frontend/sdf_cmd_file.cmd
	@echo 'SCOPE = :DUV,' >> $(PROJECT_DIR)/frontend/sdf_cmd_file.cmd
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
			
sim_post_layout: sim_rtl
	@mkdir -p $(DUMP_DIR)
	@mkdir -p $(CSVS_DIR)
	@echo "Generating dynamic SDF command file..."
	@echo 'COMPILED_SDF_FILE = "$(SDF_FILE)",' > $(PROJECT_DIR)/frontend/sdf_cmd_file.cmd
	@echo 'SCOPE = :DUV,' >> $(PROJECT_DIR)/frontend/sdf_cmd_file.cmd
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

sweep_synth_csv: sim_rtl
	@mkdir -p $(CSVS_DIR)
	@for freq in 10 100 500 1000; do \
		for lib in worst best; do \
			echo "=================================================="; \
			echo "Running synthesis for $$freq MHz with $$lib library"; \
			echo "=================================================="; \
			$(MAKE) synth FREQ_MHZ=$$freq LIB_TYPE=$$lib; \
		done \
	done
	@echo "=================================================="
	@echo "Extracting synthesis data to CSV..."
	@echo "=================================================="
	python3 $(SCRIPTS_DIR)/Report_extractor.py

sweep_gls_monitor:
	@mkdir -p $(CSVS_DIR)
	@for freq in 10 100 500 1000; do \
		for lib in worst best; do \
			echo "=================================================="; \
			echo "Running Post-Synth Simulation: $$freq MHz | $$lib"; \
			echo "=================================================="; \
			$(MAKE) sim_gls_monitor FREQ_MHZ=$$freq LIB_TYPE=$$lib; \
		done \
	done
	@echo "=================================================="
	@echo "Extracting stability times to CSV..."
	@echo "=================================================="
	python3 $(SCRIPTS_DIR)/stable_extractor.py

sweep_gls_vcd:
	@mkdir -p $(CSVS_DIR)
	@for freq in 100 ; do \
		for lib in worst; do \
			for runtime in 5000; do \
				echo "==============================================================="; \
				echo "Running Post-Synth Simulation: $$freq MHz | $$lib | $$runtime"; \
				echo "==============================================================="; \
				$(MAKE) sim_gls_vcd FREQ_MHZ=$$freq LIB_TYPE=$$lib RUNTIME=$$runtime; \
				$(MAKE) synth FREQ_MHZ=$$freq LIB_TYPE=$$lib RUNTIME=$$runtime; \
			done \
		done \
	done

sweep_full_power_analysis:
	@mkdir -p $(CSVS_DIR)
	@echo "========================================================="
	@echo "          GENERATING BASE SYNTHESIS FILES                "
	@echo "========================================================="
	@for freq in 100 500 1000; do \
		for lib in worst; do \
			echo "Running base synthesis for $$freq MHz | $$lib"; \
			$(MAKE) synth FREQ_MHZ=$$freq LIB_TYPE=$$lib RUNTIME=base; \
		done \
	done
	@echo "========================================================="
	@echo "         STARTING GATE-LEVEL VCD SWEEPS                  "
	@echo "========================================================="
	@for freq in 100 ; do \
		for lib in worst; do \
			for runtime in 0 500 1000; do \
				echo "==============================================================="; \
				echo "Running Post-Synth Simulation: $$freq MHz | $$lib | $$runtime"; \
				echo "==============================================================="; \
				$(MAKE) sim_gls_vcd FREQ_MHZ=$$freq LIB_TYPE=$$lib RUNTIME=$$runtime; \
				$(MAKE) synth FREQ_MHZ=$$freq LIB_TYPE=$$lib RUNTIME=$$runtime; \
			done \
		done \
	done
	@for freq in 500 ; do \
		for lib in worst; do \
			for runtime in 0 100 200; do \
				echo "==============================================================="; \
				echo "Running Post-Synth Simulation: $$freq MHz | $$lib | $$runtime"; \
				echo "==============================================================="; \
				$(MAKE) sim_gls_vcd FREQ_MHZ=$$freq LIB_TYPE=$$lib RUNTIME=$$runtime; \
				$(MAKE) synth FREQ_MHZ=$$freq LIB_TYPE=$$lib RUNTIME=$$runtime; \
			done \
		done \
	done
	@for freq in 1000 ; do \
		for lib in worst; do \
			for runtime in 0 50 100; do \
				echo "==============================================================="; \
				echo "Running Post-Synth Simulation: $$freq MHz | $$lib | $$runtime"; \
				echo "==============================================================="; \
				$(MAKE) sim_gls_vcd FREQ_MHZ=$$freq LIB_TYPE=$$lib RUNTIME=$$runtime; \
				$(MAKE) synth FREQ_MHZ=$$freq LIB_TYPE=$$lib RUNTIME=$$runtime; \
			done \
		done \
	done
	@echo "================================================================"
	@echo "Extracting synthesis data to CSV and writting to latex table..."
	@echo "================================================================"
	python3 $(SCRIPTS_DIR)/Report_extractor_TL.py
	python3 $(SCRIPTS_DIR)/latex_table_builder.py
    
sweep_short_power_analysis:
	@echo "========================================================="
	@echo "         STARTING GATE-LEVEL VCD SWEEPS                  "
	@echo "========================================================="
	@for freq in 100 ; do \
		for lib in worst; do \
			for runtime in 500; do \
				echo "==============================================================="; \
				echo "Running Post-Synth Simulation: $$freq MHz | $$lib | $$runtime"; \
				echo "==============================================================="; \
				$(MAKE) sim_gls_vcd FREQ_MHZ=$$freq LIB_TYPE=$$lib RUNTIME=$$runtime; \
				$(MAKE) synth FREQ_MHZ=$$freq LIB_TYPE=$$lib RUNTIME=$$runtime; \
			done \
		done \
	done
	@for freq in 1000 ; do \
		for lib in worst; do \
			for runtime in 50; do \
				echo "==============================================================="; \
				echo "Running Post-Synth Simulation: $$freq MHz | $$lib | $$runtime"; \
				echo "==============================================================="; \
				$(MAKE) sim_gls_vcd FREQ_MHZ=$$freq LIB_TYPE=$$lib RUNTIME=$$runtime; \
				$(MAKE) synth FREQ_MHZ=$$freq LIB_TYPE=$$lib RUNTIME=$$runtime; \
			done \
		done \
	done
    
nnovus_power:
	@mkdir -p $(LAYOUT_DIR)/reports/$(DESIGNS)_$(LIB_TYPE)_$(FREQ_MHZ)_$(RUNTIME)
	bash -l -c "module add $(INNOVUS_MOD_DDI) && cd $(LAYOUT_DIR)/work && innovus -stylus -no_gui -init $(POWER_SCRIPT) -overwrite -log innovus_power_$(FREQ_MHZ)MHz.log"

# --- Complete Flow Execution ---
flow_full_single_config:
	@echo "========================================================="
	@echo "          STEP 1: BASE LOGICAL SYNTHESIS (GENUS)         "
	@echo "========================================================="
	$(MAKE) synth FREQ_MHZ=$(FREQ_MHZ) LIB_TYPE=$(LIB_TYPE) RUNTIME=base
	@echo "========================================================="
	@echo "          STEP 2: PHYSICAL SYNTHESIS (INNOVUS)           "
	@echo "========================================================="
	$(MAKE) layout_innovus FREQ_MHZ=$(FREQ_MHZ) LIB_TYPE=$(LIB_TYPE) RUNTIME=$(RUNTIME)
	@echo "========================================================="
	@echo "          STEP 3: POST-LAYOUT SIMULATION (XCELIUM)       "
	@echo "========================================================="
	$(MAKE) sim_post_layout FREQ_MHZ=$(FREQ_MHZ) LIB_TYPE=$(LIB_TYPE) RUNTIME=$(RUNTIME)
	@echo "========================================================="
	@echo "          STEP 4: POST-LAYOUT POWER ANALYSIS (INNOVUS)   "
	@echo "========================================================="
	$(MAKE) innovus_power FREQ_MHZ=$(FREQ_MHZ) LIB_TYPE=$(LIB_TYPE) RUNTIME=$(RUNTIME)
# =========================================================================
# Utilities & Visualizers
# =========================================================================

latex:
	@echo "================================================================"
	@echo "Extracting synthesis data to CSV and writting to latex table..."
	@echo "================================================================"
	python3 $(SCRIPTS_DIR)/Report_extractor_TL.py
	python3 $(SCRIPTS_DIR)/latex_table_builder.py
    
genus_gui:
	@echo "==============================================================="
	@echo "Launching Genus Schematic Viewer: $(FREQ_MHZ) MHz | $(LIB_TYPE)"
	@echo "==============================================================="
	bash -l -c "module add $(GENUS_MOD) && cd $(BACKEND_SYNTH_DIR) && genus -gui -f ../scripts/view_design.tcl"

innovus_gui:
	@echo "==============================================================="
	@echo "Launching Innovus for: $(FREQ_MHZ) MHz | $(LIB_TYPE) library"
	@echo "Netlist path: ../deliverables/$(DESIGNS)_$(LIB_TYPE)_$(FREQ_MHZ)_base/$(DESIGNS).v"
	@echo "==============================================================="
	bash -l -c "module add $(INNOVUS_MOD) && cd $(BACKEND_SYNTH_DIR) && innovus"
    
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
        
uvm_sim:
	@echo "=================================================="
	@echo "Running UVM Mixed-Language Simulation..."
	@echo "=================================================="
	bash -l -c "module add $(INNOVUS_MOD_DDI) && xrun $(XRUN_UVM_FLAGS)"
    
cov_gui:
	@echo "=================================================="
	@echo "Launching Cadence IMC Coverage Viewer..."
	@echo "=================================================="
	bash -l -c "module add $(IMC_MOD) && module add $(XCELIUM_MOD) && imc -load cov_work/scope/test"

clean:
	rm -rf $(FRONTEND_DIR)/xcelium.d $(FRONTEND_DIR)/xrun.history $(FRONTEND_DIR)/xrun.log
	rm -rf $(BACKEND_SYNTH_DIR)/genus* $(BACKEND_SYNTH_DIR)/fv


# =========================================================================
# Help Menu
# =========================================================================

help:
	@echo "========================================================================================="
	@echo "                                MAKEFILE COMMAND REFERENCE                               "
	@echo "========================================================================================="
	@echo "Usage: make <target> [VARIABLE=value]"
	@echo "Example: make sim_gls_vcd FREQ_MHZ=500 LIB_TYPE=worst RUNTIME=200"
	@echo ""
	@echo "Key Variables (can be overridden from command line):"
	@echo "  FREQ_MHZ    : Target frequency in MHz (Default: 100). "
	@echo "  LIB_TYPE    : Library operating condition (Default: worst). Options: worst, best"
	@echo "  RUNTIME     : Simulation runtime in ns (Default: 500)"
	@echo "  GUI         : Set to 1 to open Xcelium GUI for RTL sim (Default: 0)"
	@echo "  GUI_VCD     : Set to 1 to open Xcelium GUI for GLS/VCD sim (Default: 0)"
	@echo ""
	@echo "Core Execution Targets:"
	@echo "  flow_full_single_config : Execute the complete flow (synth -> layout -> sim -> power)."
	@echo "  sim_rtl              	 : Run standard frontend RTL simulation in Xcelium."
	@echo "  synth                 	 : Run logic synthesis using Genus."
	@echo "  layout_innovus        	 : Run physical design layout using Innovus."
	@echo "  layout_genus          	 : Run layout scripts via Genus."
	@echo "  innovus_power        	 : Run post-layout power analysis using Innovus and VCD."
	@echo "" 
	@echo "Gate-Level Simulation (GLS) Targets:"
	@echo "  sim_gls_monitor      : Post-synthesis simulation using a monitor script."
	@echo "  sim_gls_vcd          : Post-synthesis simulation with VCD generation."
	@echo "  sim_post_layout      : Post-layout simulation using Innovus SDF."
	@echo ""
	@echo "Parameter Sweeps & Batch Analysis:"
	@echo "  sweep_synth_csv      : Sweep synthesis across frequencies/libs and extract to CSV."
	@echo "  sweep_gls_monitor    : Sweep post-synth monitor simulations across frequencies."
	@echo "  sweep_gls_vcd        : Sweep post-synth VCD simulations for specific runtimes."
	@echo "  sweep_full_power     : Full multi-frequency base generation and analysis sweep."
	@echo "  sweep_short_power_analysis : Short gate-level VCD sweep for specific runtimes."
	@echo ""
	@echo "Utilities & Visualizers:"
	@echo "  genus_gui            : Open the Genus Schematic Viewer for the current parameters."
	@echo "  innovus_gui          : Open the Innovus GUI with the generated netlist."
	@echo "  cross_sta            : Run Static Timing Analysis (requires SYNTH_FREQ & TEST_FREQ)."
	@echo "  uvm_sim              : Run UVM mixed-language simulation."
	@echo "  cov_gui              : Open Cadence IMC Coverage Viewer."
	@echo "  latex                : Extract synthesis data and build a LaTeX table."
	@echo "  clean                : Remove simulation logs, history, and temporary folders."
	@echo "========================================================================================="
	@echo "Example: make synth FREQ_MHZ=500 LIB_TYPE=best"
	@echo "========================================================================================="
	@echo "RUN THE COMMAND ' make setup_dirs ' TO CREATE THE DIRECTORY TREE"


# =========================================================================
# Workspace Setup
# =========================================================================

setup_dirs:
	@echo "=================================================="
	@echo "Initializing project directory tree..."
	@echo "=================================================="
	@mkdir -p $(HDL_TEMP_DIR)
	@mkdir -p $(DUMP_DIR)
	@mkdir -p backend/layout/constraints
	@mkdir -p backend/layout/deliverables
	@mkdir -p backend/layout/reports
	@mkdir -p backend/layout/scripts
	@mkdir -p backend/layout/work
	@mkdir -p backend/synthesis/constraints
	@mkdir -p backend/synthesis/deliverables
	@mkdir -p backend/synthesis/reports
	@mkdir -p backend/synthesis/scripts
	@mkdir -p backend/synthesis/work
