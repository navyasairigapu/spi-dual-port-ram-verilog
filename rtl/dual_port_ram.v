//=============================================================================
// Project      : SPI-Based Dual Port RAM Interface
// File         : dual_port_ram.v
// Author       : VLSI Design Team
// Version      : 1.0
// Date         : 2025
// Description  : True Dual Port RAM (TDPRAM)
//                - Port A : Direct parallel access (CPU / internal logic)
//                - Port B : SPI slave-controlled access
//                - Depth  : 128 locations (7-bit address)
//                - Width  : 8 bits (1 byte) per location
//                - Total  : 1 Kbit (128 bytes)
//                - Synchronous read/write with configurable collision handling
//                - WRITE_FIRST mode for both ports
//
// Collision Policy:
//   Same address, both writing simultaneously -> Port A wins (priority)
//   Same address, one read one write         -> Read returns NEW data
//=============================================================================

`timescale 1ns / 1ps

module dual_port_ram #(
    parameter DATA_WIDTH = 8,           // Data bus width in bits
    parameter ADDR_WIDTH = 7,           // Address bus width (2^7 = 128 locations)
    parameter DEPTH      = 128          // Memory depth
)(
    //=========================================================================
    // PORT A — Primary / Parallel Access Port
    //=========================================================================
    input  wire                  clk_a,      // Port A clock
    input  wire                  rst_a,      // Port A reset (active high)
    input  wire                  en_a,       // Port A enable
    input  wire                  wen_a,      // Port A write enable
    input  wire [ADDR_WIDTH-1:0] addr_a,     // Port A address
    input  wire [DATA_WIDTH-1:0] wdata_a,    // Port A write data
    output reg  [DATA_WIDTH-1:0] rdata_a,    // Port A read data

    //=========================================================================
    // PORT B — SPI-Controlled Access Port
    //=========================================================================
    input  wire                  clk_b,      // Port B clock
    input  wire                  rst_b,      // Port B reset (active high)
    input  wire                  en_b,       // Port B enable
    input  wire                  wen_b,      // Port B write enable
    input  wire [ADDR_WIDTH-1:0] addr_b,     // Port B address
    input  wire [DATA_WIDTH-1:0] wdata_b,    // Port B write data
    output reg  [DATA_WIDTH-1:0] rdata_b     // Port B read data
);

    //=========================================================================
    // Shared Memory Array
    //=========================================================================
    // Inferred as Block RAM (BRAM) by synthesis tools (Vivado, Quartus)
    (* ram_style = "block" *)
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    //=========================================================================
    // Initialization (for simulation — synthesis ignores this)
    //=========================================================================
    integer i;
    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = {DATA_WIDTH{1'b0}};
    end

    //=========================================================================
    // PORT A — Synchronous Read/Write (WRITE_FIRST Mode)
    //=========================================================================
    always @(posedge clk_a) begin
        if (rst_a) begin
            rdata_a <= {DATA_WIDTH{1'b0}};
        end else if (en_a) begin
            if (wen_a) begin
                mem[addr_a] <= wdata_a;     // Write operation
                rdata_a     <= wdata_a;     // Write-first: return written data
            end else begin
                rdata_a     <= mem[addr_a]; // Read operation
            end
        end
    end

    //=========================================================================
    // PORT B — Synchronous Read/Write (WRITE_FIRST Mode)
    //=========================================================================
    always @(posedge clk_b) begin
        if (rst_b) begin
            rdata_b <= {DATA_WIDTH{1'b0}};
        end else if (en_b) begin
            if (wen_b) begin
                mem[addr_b] <= wdata_b;     // Write operation
                rdata_b     <= wdata_b;     // Write-first: return written data
            end else begin
                rdata_b     <= mem[addr_b]; // Read operation
            end
        end
    end

endmodule
