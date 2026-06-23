#=============================================================================
# Project : SPI-Based Dual Port RAM Interface
# File    : Makefile
# Usage   : make sim      — Run ModelSim simulation
#           make wave     — Open GTKWave
#           make lint     — Run Verilator lint check
#           make clean    — Remove generated files
#=============================================================================

TOPLEVEL    = spi_dpram_top
TB          = tb_spi_dpram_top
RTL_DIR     = ../rtl
TB_DIR      = ../tb
SIM_DIR     = ../sim

RTL_SRCS    = $(RTL_DIR)/dual_port_ram.v \
              $(RTL_DIR)/spi_slave.v      \
              $(RTL_DIR)/spi_master.v     \
              $(RTL_DIR)/spi_dpram_top.v

TB_SRCS     = $(TB_DIR)/tb_spi_dpram_top.v

VCD_FILE    = $(SIM_DIR)/spi_dpram_waves.vcd

# ---- Icarus Verilog (free simulator) ----
iverilog:
	iverilog -o $(SIM_DIR)/sim_out -Wall -g2012 \
		$(RTL_SRCS) $(TB_SRCS)
	cd $(SIM_DIR) && vvp sim_out

# ---- GTKWave ----
wave:
	gtkwave $(VCD_FILE) &

# ---- ModelSim ----
modelsim:
	cd $(SIM_DIR) && vsim -do run_sim.do

# ---- Verilator Lint ----
lint:
	verilator --lint-only -Wall $(RTL_SRCS) --top-module $(TOPLEVEL)

# ---- Clean ----
clean:
	rm -rf $(SIM_DIR)/work $(SIM_DIR)/sim_out $(SIM_DIR)/*.vcd \
	       $(SIM_DIR)/transcript $(SIM_DIR)/*.wlf

.PHONY: iverilog wave modelsim lint clean
