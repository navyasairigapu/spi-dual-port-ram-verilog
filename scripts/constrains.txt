# =============================================================================
# Project     : SPI-Based Dual Port RAM Interface
# File        : constraints.xdc
# Description : Xilinx Vivado Timing Constraints (Artix-7 example)
# Target      : xc7a35tcpg236-1
# =============================================================================

# ---- System Clock ----
create_clock -period 10.000 -name sys_clk -waveform {0.000 5.000} [get_ports clk]

# ---- SPI Clock (virtual — comes from master, not a physical clock port here) ----
# create_clock -period 80.000 -name spi_clk [get_ports sclk]

# ---- Input Delay (SPI signals relative to system clock) ----
set_input_delay -clock sys_clk -max 2.0 [get_ports {spi_start spi_rw spi_addr[*] spi_wdata[*]}]
set_input_delay -clock sys_clk -min 0.5 [get_ports {spi_start spi_rw spi_addr[*] spi_wdata[*]}]

# ---- Output Delay ----
set_output_delay -clock sys_clk -max 2.0 [get_ports {spi_rdata[*] spi_done spi_busy}]
set_output_delay -clock sys_clk -min 0.5 [get_ports {spi_rdata[*] spi_done spi_busy}]

# ---- Port A Interface ----
set_input_delay  -clock sys_clk -max 2.0 [get_ports {porta_en porta_wen porta_addr[*] porta_wdata[*]}]
set_output_delay -clock sys_clk -max 2.0 [get_ports {porta_rdata[*]}]

# ---- False Paths (synchronizers handle CDC) ----
# set_false_path -from [get_clocks spi_clk] -to [get_clocks sys_clk]

# ---- Maximum Delay for 2-FF Synchronizer ----
# set_max_delay -datapath_only 8.0 -from [get_pins u_spi_slave/sclk_s1_reg/C] \
#               -to [get_pins u_spi_slave/sclk_s2_reg/D]
