# =============================================================================
# Project      : SPI-Based Dual Port RAM Interface
# File         : run_sim.do
# Description  : ModelSim Simulation Script
#                Run this file from ModelSim: do run_sim.do
# =============================================================================

# ---- Clean up previous run ----
if {[file exists work]} { vdel -lib work -all }
vlib work
vmap work work

# ---- Compile RTL Sources ----
echo "=== Compiling RTL Sources ==="
vlog -work work -timescale "1ns/1ps" \
    +define+SIMULATION \
    ../rtl/dual_port_ram.v \
    ../rtl/spi_slave.v \
    ../rtl/spi_master.v \
    ../rtl/spi_dpram_top.v

# ---- Compile Testbench ----
echo "=== Compiling Testbench ==="
vlog -work work -timescale "1ns/1ps" \
    ../tb/tb_spi_dpram_top.v

# ---- Elaborate & Simulate ----
echo "=== Starting Simulation ==="
vsim -t 1ns -lib work tb_spi_dpram_top \
     -voptargs="+acc" \
     -do "
        add wave -divider {=== SYSTEM ===}
        add wave -color Gold       sim:/tb_spi_dpram_top/clk
        add wave -color Red        sim:/tb_spi_dpram_top/rst_n

        add wave -divider {=== SPI BUS ===}
        add wave -color Cyan       sim:/tb_spi_dpram_top/DUT/sclk_int
        add wave -color Orange     sim:/tb_spi_dpram_top/DUT/cs_n_int
        add wave -color Yellow     sim:/tb_spi_dpram_top/DUT/mosi_int
        add wave -color Green      sim:/tb_spi_dpram_top/DUT/miso_int

        add wave -divider {=== SPI MASTER ===}
        add wave -color White      sim:/tb_spi_dpram_top/spi_start
        add wave -color White      sim:/tb_spi_dpram_top/spi_rw
        add wave -color LightBlue  -radix hex sim:/tb_spi_dpram_top/spi_addr
        add wave -color LightBlue  -radix hex sim:/tb_spi_dpram_top/spi_wdata
        add wave -color LightGreen -radix hex sim:/tb_spi_dpram_top/spi_rdata
        add wave -color Magenta    sim:/tb_spi_dpram_top/spi_busy
        add wave -color Magenta    sim:/tb_spi_dpram_top/spi_done

        add wave -divider {=== SPI SLAVE ===}
        add wave -color White      sim:/tb_spi_dpram_top/slave_rx_valid
        add wave -color Red        sim:/tb_spi_dpram_top/slave_frame_err

        add wave -divider {=== RAM PORT A ===}
        add wave -color White      sim:/tb_spi_dpram_top/porta_en
        add wave -color White      sim:/tb_spi_dpram_top/porta_wen
        add wave -color LightBlue  -radix hex sim:/tb_spi_dpram_top/porta_addr
        add wave -color LightBlue  -radix hex sim:/tb_spi_dpram_top/porta_wdata
        add wave -color LightGreen -radix hex sim:/tb_spi_dpram_top/porta_rdata

        add wave -divider {=== RAM PORT B ===}
        add wave -color White      sim:/tb_spi_dpram_top/DUT/ram_wen_b_int
        add wave -color LightBlue  -radix hex sim:/tb_spi_dpram_top/DUT/ram_addr_b_int
        add wave -color LightBlue  -radix hex sim:/tb_spi_dpram_top/DUT/ram_wdata_b_int
        add wave -color LightGreen -radix hex sim:/tb_spi_dpram_top/DUT/ram_rdata_b_int

        run -all
        wave zoom full
     "
