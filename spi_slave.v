//=============================================================================
// Project      : SPI-Based Dual Port RAM Interface
// File         : spi_slave.v
// Author       : VLSI Design Team
// Version      : 1.0
// Date         : 2025
// Description  : SPI Slave Controller - Receives SPI frames and interfaces
//                with Port B of the Dual Port RAM.
//                Decodes: [RW(1) | ADDR(7) | DATA(8)] = 16-bit frame
//                On Write: drives RAM Port-B write signals
//                On Read : captures RAM Port-B read data and shifts out MISO
//=============================================================================

`timescale 1ns / 1ps

module spi_slave (
    // System Signals
    input  wire        clk,         // System clock (for synchronization)
    input  wire        rst_n,       // Active-low synchronous reset

    // SPI Bus Interface
    input  wire        sclk,        // SPI Clock from master
    input  wire        cs_n,        // Chip Select (active low)
    input  wire        mosi,        // Master Out Slave In
    output reg         miso,        // Master In Slave Out

    // RAM Port B Interface (write side)
    output reg         ram_wen_b,   // RAM Port B write enable
    output reg  [6:0]  ram_addr_b,  // RAM Port B address
    output reg  [7:0]  ram_wdata_b, // RAM Port B write data

    // RAM Port B Interface (read side)
    output reg         ram_ren_b,   // RAM Port B read enable
    input  wire [7:0]  ram_rdata_b, // RAM Port B read data

    // Status
    output reg         rx_valid,    // Frame successfully received
    output reg         frame_err    // Frame error flag
);

    //=========================================================================
    // Internal Registers
    //=========================================================================
    reg [15:0] rx_shift;        // MOSI shift register
    reg [15:0] tx_shift;        // MISO shift register (for readback)
    reg [4:0]  bit_cnt;         // Bit counter

    // Synchronized SPI signals (metastability protection)
    reg sclk_s1, sclk_s2;
    reg cs_n_s1, cs_n_s2;
    reg mosi_s1, mosi_s2;

    wire sclk_rise = ( sclk_s2 && !sclk_s1); // Wait — corrected below
    wire sclk_fall = (!sclk_s2 &&  sclk_s1);
    // Note: Using 2-FF synchronizer for SPI signals crossing clock domains

    //=========================================================================
    // 2-FF Synchronizer for SPI Signals
    //=========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {sclk_s1, sclk_s2} <= 2'b00;
            {cs_n_s1, cs_n_s2} <= 2'b11;
            {mosi_s1, mosi_s2} <= 2'b00;
        end else begin
            sclk_s1 <= sclk;   sclk_s2 <= sclk_s1;
            cs_n_s1 <= cs_n;   cs_n_s2 <= cs_n_s1;
            mosi_s1 <= mosi;   mosi_s2 <= mosi_s1;
        end
    end

    // Correct edge detect (use s1/s2 — s2 is older)
    wire sclk_posedge = ( sclk_s1 && !sclk_s2);
    wire sclk_negedge = (!sclk_s1 &&  sclk_s2);
    wire cs_active    = !cs_n_s2;

    //=========================================================================
    // SPI Frame Reception (Sample on SCLK rising edge)
    //=========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_shift   <= 16'h0000;
            tx_shift   <= 16'h0000;
            bit_cnt    <= 5'd0;
            miso       <= 1'b0;
            rx_valid   <= 1'b0;
            frame_err  <= 1'b0;
            ram_wen_b  <= 1'b0;
            ram_ren_b  <= 1'b0;
            ram_addr_b <= 7'h00;
            ram_wdata_b<= 8'h00;
        end else begin
            rx_valid  <= 1'b0;
            ram_wen_b <= 1'b0;
            ram_ren_b <= 1'b0;
            frame_err <= 1'b0;

            if (!cs_active) begin
                // CS deasserted: reset for next frame
                bit_cnt  <= 5'd0;
                rx_shift <= 16'h0000;
                miso     <= 1'b0;
            end else begin
                // ---- Sample MOSI on rising edge ----
                if (sclk_posedge) begin
                    rx_shift <= {rx_shift[14:0], mosi_s2}; // Shift in MSB first
                    bit_cnt  <= bit_cnt + 1'b1;
                end

                // ---- Shift out MISO on falling edge ----
                if (sclk_negedge) begin
                    miso     <= tx_shift[15];
                    tx_shift <= {tx_shift[14:0], 1'b0};
                end

                // ---- Frame Complete: decode after 16th rising edge ----
                if (bit_cnt == 5'd16 && sclk_posedge) begin
                    rx_valid <= 1'b1;
                    bit_cnt  <= 5'd0;

                    if (rx_shift[15] == 1'b0) begin
                        // WRITE operation
                        ram_addr_b  <= rx_shift[14:8];
                        ram_wdata_b <= rx_shift[7:0];
                        ram_wen_b   <= 1'b1;
                    end else begin
                        // READ operation
                        ram_addr_b  <= rx_shift[14:8];
                        ram_ren_b   <= 1'b1;
                        // Preload tx_shift with read data for next frame
                        tx_shift    <= {8'h00, ram_rdata_b};
                    end
                end
            end
        end
    end

endmodule
