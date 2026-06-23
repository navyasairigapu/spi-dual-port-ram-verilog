//=============================================================================
// Project      : SPI-Based Dual Port RAM Interface
// File         : spi_dpram_top.v
// Author       : VLSI Design Team
// Version      : 1.0
// Date         : 2025
// Description  : TOP-LEVEL Integration Module
//                Connects SPI Master → SPI Slave → Dual Port RAM
//
//  System Architecture:
//  ┌─────────────┐  SPI Bus   ┌─────────────┐  Port B   ┌─────────────┐
//  │  SPI Master │ ─────────► │  SPI Slave  │ ─────────►│  Dual Port  │
//  │  (spi_master│ ◄───────── │  (spi_slave)│ ◄─────────│  RAM        │
//  └─────────────┘  MISO      └─────────────┘           │(dual_port   │
//                                                        │ _ram)       │
//  ┌─────────────┐           Port A                      │             │
//  │  CPU / User │ ─────────────────────────────────────►│             │
//  │  Logic      │ ◄────────────────────────────────────-│             │
//  └─────────────┘                                       └─────────────┘
//
// Parameters   : CLK_DIV configures SPI clock frequency
// Constraints  : Both clk_a and clk_b tie to same system clock in this design
//=============================================================================

`timescale 1ns / 1ps

module spi_dpram_top #(
    parameter CLK_DIV   = 4,
    parameter FRAME_LEN = 16,
    parameter DATA_W    = 8,
    parameter ADDR_W    = 7,
    parameter DEPTH     = 128
)(
    //=========================================================================
    // Global Signals
    //=========================================================================
    input  wire        clk,             // System clock
    input  wire        rst_n,           // Global active-low reset

    //=========================================================================
    // SPI Master User Interface (controlled externally / by testbench)
    //=========================================================================
    input  wire        spi_start,       // Start SPI transaction
    input  wire        spi_rw,          // 1=Read, 0=Write
    input  wire [6:0]  spi_addr,        // Target RAM address
    input  wire [7:0]  spi_wdata,       // Data to write
    output wire [7:0]  spi_rdata,       // Data read back
    output wire        spi_busy,        // SPI master busy
    output wire        spi_done,        // Transaction complete (1-clk pulse)

    //=========================================================================
    // Port A — Direct Parallel CPU Interface
    //=========================================================================
    input  wire        porta_en,        // Port A enable
    input  wire        porta_wen,       // Port A write enable
    input  wire [6:0]  porta_addr,      // Port A address
    input  wire [7:0]  porta_wdata,     // Port A write data
    output wire [7:0]  porta_rdata,     // Port A read data

    //=========================================================================
    // Debug / Status
    //=========================================================================
    output wire        slave_rx_valid,  // SPI slave received valid frame
    output wire        slave_frame_err  // SPI framing error
);

    //=========================================================================
    // Internal SPI Bus Wires
    //=========================================================================
    wire sclk_int;
    wire cs_n_int;
    wire mosi_int;
    wire miso_int;

    //=========================================================================
    // SPI Slave ↔ RAM Port B Wires
    //=========================================================================
    wire        ram_wen_b_int;
    wire        ram_ren_b_int;
    wire [6:0]  ram_addr_b_int;
    wire [7:0]  ram_wdata_b_int;
    wire [7:0]  ram_rdata_b_int;

    //=========================================================================
    // Instantiate SPI Master
    //=========================================================================
    spi_master #(
        .CLK_DIV   (CLK_DIV),
        .FRAME_LEN (FRAME_LEN)
    ) u_spi_master (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (spi_start),
        .rw         (spi_rw),
        .addr       (spi_addr),
        .data_in    (spi_wdata),
        .miso_data  (spi_rdata),
        .busy       (spi_busy),
        .done       (spi_done),
        .sclk       (sclk_int),
        .cs_n       (cs_n_int),
        .mosi       (mosi_int),
        .miso       (miso_int)
    );

    //=========================================================================
    // Instantiate SPI Slave
    //=========================================================================
    spi_slave u_spi_slave (
        .clk         (clk),
        .rst_n       (rst_n),
        .sclk        (sclk_int),
        .cs_n        (cs_n_int),
        .mosi        (mosi_int),
        .miso        (miso_int),
        .ram_wen_b   (ram_wen_b_int),
        .ram_addr_b  (ram_addr_b_int),
        .ram_wdata_b (ram_wdata_b_int),
        .ram_ren_b   (ram_ren_b_int),
        .ram_rdata_b (ram_rdata_b_int),
        .rx_valid    (slave_rx_valid),
        .frame_err   (slave_frame_err)
    );

    //=========================================================================
    // Instantiate Dual Port RAM
    //=========================================================================
    dual_port_ram #(
        .DATA_WIDTH (DATA_W),
        .ADDR_WIDTH (ADDR_W),
        .DEPTH      (DEPTH)
    ) u_dpram (
        // Port A (parallel CPU interface)
        .clk_a      (clk),
        .rst_a      (~rst_n),
        .en_a       (porta_en),
        .wen_a      (porta_wen),
        .addr_a     (porta_addr),
        .wdata_a    (porta_wdata),
        .rdata_a    (porta_rdata),

        // Port B (SPI slave interface)
        .clk_b      (clk),
        .rst_b      (~rst_n),
        .en_b       (ram_wen_b_int | ram_ren_b_int),
        .wen_b      (ram_wen_b_int),
        .addr_b     (ram_addr_b_int),
        .wdata_b    (ram_wdata_b_int),
        .rdata_b    (ram_rdata_b_int)
    );

endmodule
