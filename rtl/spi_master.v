//=============================================================================
// Project      : SPI-Based Dual Port RAM Interface
// File         : spi_master.v
// Author       : VLSI Design Team
// Version      : 1.0
// Date         : 2025
// Description  : SPI Master Controller - Initiates read/write transactions
//                to the Dual Port RAM via SPI protocol.
//                Supports CPOL=0, CPHA=0 (SPI Mode 0)
//                Frame Format: [1-bit RW | 7-bit ADDR | 8-bit DATA] = 16 bits
//
// Inputs       : clk, rst_n, start, rw, addr[6:0], data_in[7:0]
// Outputs      : sclk, cs_n, mosi, miso_data[7:0], busy, done
//=============================================================================

`timescale 1ns / 1ps

module spi_master #(
    parameter CLK_DIV   = 4,        // SPI clock = sys_clk / (2 * CLK_DIV)
    parameter FRAME_LEN = 16        // Total bits per SPI frame
)(
    // System Signals
    input  wire        clk,         // System clock
    input  wire        rst_n,       // Active-low synchronous reset

    // User Interface
    input  wire        start,       // Pulse high to begin transaction
    input  wire        rw,          // 1 = Read, 0 = Write
    input  wire [6:0]  addr,        // 7-bit RAM address
    input  wire [7:0]  data_in,     // Data to write (ignored on read)
    output reg  [7:0]  miso_data,   // Data received from slave (read result)
    output reg         busy,        // High while transaction in progress
    output reg         done,        // Pulses high for 1 clk when transaction done

    // SPI Bus Interface
    output reg         sclk,        // SPI Clock
    output reg         cs_n,        // Chip Select (active low)
    output reg         mosi,        // Master Out Slave In
    input  wire        miso         // Master In Slave Out
);

    //=========================================================================
    // State Machine Encoding (One-Hot for speed)
    //=========================================================================
    localparam [2:0]
        ST_IDLE     = 3'b001,
        ST_ACTIVE   = 3'b010,
        ST_DONE     = 3'b100;

    reg [2:0]  state, next_state;

    //=========================================================================
    // Internal Registers
    //=========================================================================
    reg [15:0] tx_shift;        // Transmit shift register [RW|ADDR|DATA]
    reg [15:0] rx_shift;        // Receive shift register
    reg [4:0]  bit_cnt;         // Bit counter (0-15)
    reg [3:0]  clk_div_cnt;     // Clock divider counter
    reg        sclk_en;         // SPI clock enable
    reg        sclk_r;          // Registered SCLK for edge detection

    //=========================================================================
    // SPI Clock Generation
    //=========================================================================
    always @(posedge clk) begin
        if (!rst_n) begin
            clk_div_cnt <= 4'h0;
            sclk        <= 1'b0;
        end else if (sclk_en) begin
            if (clk_div_cnt == (CLK_DIV - 1)) begin
                clk_div_cnt <= 4'h0;
                sclk        <= ~sclk;
            end else begin
                clk_div_cnt <= clk_div_cnt + 1'b1;
            end
        end else begin
            sclk        <= 1'b0;
            clk_div_cnt <= 4'h0;
        end
    end

    //=========================================================================
    // Rising/Falling Edge Detection of SCLK
    //=========================================================================
    wire sclk_rise = (sclk && !sclk_r);
    wire sclk_fall = (!sclk && sclk_r);

    always @(posedge clk) sclk_r <= sclk;

    //=========================================================================
    // State Register
    //=========================================================================
    always @(posedge clk) begin
        if (!rst_n)
            state <= ST_IDLE;
        else
            state <= next_state;
    end

    //=========================================================================
    // Next-State Logic
    //=========================================================================
    always @(*) begin
        next_state = state;
        case (state)
            ST_IDLE:   if (start)              next_state = ST_ACTIVE;
            ST_ACTIVE: if (bit_cnt == FRAME_LEN && sclk_fall)
                                               next_state = ST_DONE;
            ST_DONE:                           next_state = ST_IDLE;
            default:                           next_state = ST_IDLE;
        endcase
    end

    //=========================================================================
    // Output / Datapath Logic
    //=========================================================================
    always @(posedge clk) begin
        if (!rst_n) begin
            tx_shift  <= 16'h0000;
            rx_shift  <= 16'h0000;
            bit_cnt   <= 5'd0;
            cs_n      <= 1'b1;
            mosi      <= 1'b0;
            sclk_en   <= 1'b0;
            busy      <= 1'b0;
            done      <= 1'b0;
            miso_data <= 8'h00;
        end else begin
            done <= 1'b0; // Default: done is a pulse

            case (state)
                //-------------------------------------------------------------
                ST_IDLE: begin
                    cs_n    <= 1'b1;
                    sclk_en <= 1'b0;
                    busy    <= 1'b0;
                    bit_cnt <= 5'd0;
                    if (start) begin
                        // Pack frame: {RW[15], ADDR[14:8], DATA[7:0]}
                        tx_shift <= {rw, addr, data_in};
                        cs_n     <= 1'b0;
                        sclk_en  <= 1'b1;
                        busy     <= 1'b1;
                    end
                end

                //-------------------------------------------------------------
                ST_ACTIVE: begin
                    // Drive MOSI on falling edge, sample MISO on rising edge
                    if (sclk_fall) begin
                        mosi     <= tx_shift[15];      // MSB first
                        tx_shift <= {tx_shift[14:0], 1'b0};
                        bit_cnt  <= bit_cnt + 1'b1;
                    end
                    if (sclk_rise) begin
                        rx_shift <= {rx_shift[14:0], miso}; // Shift in MISO
                    end
                end

                //-------------------------------------------------------------
                ST_DONE: begin
                    cs_n      <= 1'b1;
                    sclk_en   <= 1'b0;
                    mosi      <= 1'b0;
                    miso_data <= rx_shift[7:0]; // Lower 8 bits = read data
                    done      <= 1'b1;
                    busy      <= 1'b0;
                end

                default: ;
            endcase
        end
    end

endmodule
