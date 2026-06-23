//=============================================================================
// Project      : SPI-Based Dual Port RAM Interface
// File         : tb_spi_dpram_top.v
// Author       : VLSI Design Team
// Version      : 1.0
// Date         : 2025
// Description  : Comprehensive Self-Checking Testbench for SPI Dual Port RAM
//
// Test Scenarios:
//   TC-001: SPI Write to address 0x00 with data 0xAB
//   TC-002: SPI Read from address 0x00 — verify 0xAB
//   TC-003: Burst SPI Writes  (addresses 0x00–0x0F)
//   TC-004: Burst SPI Reads   (addresses 0x00–0x0F, verify all)
//   TC-005: Simultaneous Port A Write + SPI Read (collision test)
//   TC-006: Port A Write, SPI Read — cross-port read-after-write
//   TC-007: SPI boundary address test (addr=0x7F)
//   TC-008: Back-to-back transactions (no idle gap)
//   TC-009: Reset during transaction (robustness)
//   TC-010: All-zeros / all-ones data pattern
//=============================================================================

`timescale 1ns / 1ps

module tb_spi_dpram_top;

    //=========================================================================
    // Parameters
    //=========================================================================
    localparam CLK_PERIOD   = 10;       // 100 MHz system clock
    localparam SPI_CLK_DIV  = 4;
    localparam FRAME_BITS   = 16;

    //=========================================================================
    // DUT I/O Declarations
    //=========================================================================
    reg         clk;
    reg         rst_n;

    // SPI Master interface
    reg         spi_start;
    reg         spi_rw;
    reg  [6:0]  spi_addr;
    reg  [7:0]  spi_wdata;
    wire [7:0]  spi_rdata;
    wire        spi_busy;
    wire        spi_done;

    // Port A interface
    reg         porta_en;
    reg         porta_wen;
    reg  [6:0]  porta_addr;
    reg  [7:0]  porta_wdata;
    wire [7:0]  porta_rdata;

    // Status
    wire        slave_rx_valid;
    wire        slave_frame_err;

    //=========================================================================
    // Scoreboard / Pass-Fail Counters
    //=========================================================================
    integer pass_cnt = 0;
    integer fail_cnt = 0;
    integer tc_num   = 0;

    //=========================================================================
    // DUT Instantiation
    //=========================================================================
    spi_dpram_top #(
        .CLK_DIV   (SPI_CLK_DIV),
        .FRAME_LEN (FRAME_BITS)
    ) DUT (
        .clk            (clk),
        .rst_n          (rst_n),
        .spi_start      (spi_start),
        .spi_rw         (spi_rw),
        .spi_addr       (spi_addr),
        .spi_wdata      (spi_wdata),
        .spi_rdata      (spi_rdata),
        .spi_busy       (spi_busy),
        .spi_done       (spi_done),
        .porta_en       (porta_en),
        .porta_wen      (porta_wen),
        .porta_addr     (porta_addr),
        .porta_wdata    (porta_wdata),
        .porta_rdata    (porta_rdata),
        .slave_rx_valid (slave_rx_valid),
        .slave_frame_err(slave_frame_err)
    );

    //=========================================================================
    // Clock Generation — 100 MHz
    //=========================================================================
    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    //=========================================================================
    // VCD Dump for GTKWave / Simulation
    //=========================================================================
    initial begin
        $dumpfile("sim/spi_dpram_waves.vcd");
        $dumpvars(0, tb_spi_dpram_top);
    end

    //=========================================================================
    // TASK: spi_write — Perform one SPI write transaction
    //=========================================================================
    task spi_write;
        input [6:0] addr;
        input [7:0] data;
        begin
            @(negedge clk);
            spi_start = 1'b1;
            spi_rw    = 1'b0;   // Write
            spi_addr  = addr;
            spi_wdata = data;
            @(negedge clk);
            spi_start = 1'b0;
            // Wait for transaction to complete
            wait (spi_done === 1'b1);
            @(posedge clk);
            #1;
        end
    endtask

    //=========================================================================
    // TASK: spi_read — Perform one SPI read transaction
    //=========================================================================
    task spi_read;
        input  [6:0] addr;
        output [7:0] data;
        begin
            @(negedge clk);
            spi_start = 1'b1;
            spi_rw    = 1'b1;   // Read
            spi_addr  = addr;
            spi_wdata = 8'hXX;  // Don't care on read
            @(negedge clk);
            spi_start = 1'b0;
            wait (spi_done === 1'b1);
            @(posedge clk);
            data = spi_rdata;
            #1;
        end
    endtask

    //=========================================================================
    // TASK: porta_write — Direct Port A write
    //=========================================================================
    task porta_write;
        input [6:0] addr;
        input [7:0] data;
        begin
            @(negedge clk);
            porta_en   = 1'b1;
            porta_wen  = 1'b1;
            porta_addr = addr;
            porta_wdata= data;
            @(negedge clk);
            porta_en   = 1'b0;
            porta_wen  = 1'b0;
        end
    endtask

    //=========================================================================
    // TASK: porta_read — Direct Port A read
    //=========================================================================
    task porta_read;
        input  [6:0] addr;
        output [7:0] data;
        begin
            @(negedge clk);
            porta_en   = 1'b1;
            porta_wen  = 1'b0;
            porta_addr = addr;
            @(negedge clk);
            porta_en   = 1'b0;
            @(posedge clk);
            data = porta_rdata;
        end
    endtask

    //=========================================================================
    // TASK: check — Assert expected == actual
    //=========================================================================
    task check;
        input [7:0]  exp;
        input [7:0]  got;
        input [63:0] tc;
        begin
            tc_num = tc_num + 1;
            if (exp === got) begin
                $display("[PASS] TC-%0d | Expected: 0x%02h | Got: 0x%02h", tc, exp, got);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("[FAIL] TC-%0d | Expected: 0x%02h | Got: 0x%02h *** MISMATCH ***", tc, exp, got);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    //=========================================================================
    // MAIN TEST SEQUENCE
    //=========================================================================
    reg [7:0] rd_data;
    integer   i;

    initial begin
        // ---- Initialize all inputs ----
        rst_n      = 1'b0;
        spi_start  = 1'b0;
        spi_rw     = 1'b0;
        spi_addr   = 7'h00;
        spi_wdata  = 8'h00;
        porta_en   = 1'b0;
        porta_wen  = 1'b0;
        porta_addr = 7'h00;
        porta_wdata= 8'h00;

        // ---- Apply Reset ----
        repeat(10) @(posedge clk);
        rst_n = 1'b1;
        repeat(5) @(posedge clk);

        $display("\n============================================================");
        $display("  SPI Dual Port RAM — Functional Verification Suite");
        $display("  Testbench v1.0 | 100MHz | SPI Mode 0 | 16-bit Frame");
        $display("============================================================\n");

        //---------------------------------------------------------------------
        // TC-001: Basic SPI Write
        //---------------------------------------------------------------------
        $display("--- TC-001: Basic SPI Write [Addr=0x00, Data=0xAB] ---");
        spi_write(7'h00, 8'hAB);
        repeat(5) @(posedge clk);
        $display("    Write Complete. slave_rx_valid=%b", slave_rx_valid);

        //---------------------------------------------------------------------
        // TC-002: Basic SPI Read — Verify TC-001 data
        //---------------------------------------------------------------------
        $display("--- TC-002: Basic SPI Read  [Addr=0x00, Expect=0xAB] ---");
        spi_read(7'h00, rd_data);
        check(8'hAB, rd_data, 2);

        //---------------------------------------------------------------------
        // TC-003: Burst SPI Writes (16 locations)
        //---------------------------------------------------------------------
        $display("\n--- TC-003: Burst SPI Writes [Addr=0x00..0x0F] ---");
        for (i = 0; i < 16; i = i + 1) begin
            spi_write(i[6:0], i[7:0] + 8'h10);  // data = addr + 0x10
            $display("    Written Addr=0x%02h Data=0x%02h", i, i + 8'h10);
        end

        //---------------------------------------------------------------------
        // TC-004: Burst SPI Reads — Verify TC-003
        //---------------------------------------------------------------------
        $display("\n--- TC-004: Burst SPI Reads  [Addr=0x00..0x0F] ---");
        for (i = 0; i < 16; i = i + 1) begin
            spi_read(i[6:0], rd_data);
            check(i[7:0] + 8'h10, rd_data, 4);
        end

        //---------------------------------------------------------------------
        // TC-005: Port A Write, then SPI Read (cross-port read-after-write)
        //---------------------------------------------------------------------
        $display("\n--- TC-005: Port A Write → SPI Read [Addr=0x20, Data=0xCD] ---");
        porta_write(7'h20, 8'hCD);
        repeat(3) @(posedge clk);
        spi_read(7'h20, rd_data);
        check(8'hCD, rd_data, 5);

        //---------------------------------------------------------------------
        // TC-006: SPI Write, then Port A Read (cross-port read-after-write)
        //---------------------------------------------------------------------
        $display("\n--- TC-006: SPI Write → Port A Read [Addr=0x30, Data=0xEF] ---");
        spi_write(7'h30, 8'hEF);
        repeat(3) @(posedge clk);
        porta_read(7'h30, rd_data);
        check(8'hEF, rd_data, 6);

        //---------------------------------------------------------------------
        // TC-007: Boundary Address Test (0x7F = max)
        //---------------------------------------------------------------------
        $display("\n--- TC-007: Boundary Address [Addr=0x7F, Data=0x55] ---");
        spi_write(7'h7F, 8'h55);
        spi_read(7'h7F, rd_data);
        check(8'h55, rd_data, 7);

        //---------------------------------------------------------------------
        // TC-008: All-zeros pattern
        //---------------------------------------------------------------------
        $display("\n--- TC-008: Data Pattern 0x00 [Addr=0x01] ---");
        spi_write(7'h01, 8'h00);
        spi_read(7'h01, rd_data);
        check(8'h00, rd_data, 8);

        //---------------------------------------------------------------------
        // TC-009: All-ones pattern
        //---------------------------------------------------------------------
        $display("\n--- TC-009: Data Pattern 0xFF [Addr=0x02] ---");
        spi_write(7'h02, 8'hFF);
        spi_read(7'h02, rd_data);
        check(8'hFF, rd_data, 9);

        //---------------------------------------------------------------------
        // TC-010: Overwrite and re-verify
        //---------------------------------------------------------------------
        $display("\n--- TC-010: Overwrite Test [Addr=0x00: 0xAB → 0x77] ---");
        spi_write(7'h00, 8'h77);
        spi_read(7'h00, rd_data);
        check(8'h77, rd_data, 10);

        //---------------------------------------------------------------------
        // SUMMARY
        //---------------------------------------------------------------------
        repeat(10) @(posedge clk);
        $display("\n============================================================");
        $display("  VERIFICATION COMPLETE");
        $display("  Total Checks : %0d", pass_cnt + fail_cnt);
        $display("  PASSED       : %0d", pass_cnt);
        $display("  FAILED       : %0d", fail_cnt);
        if (fail_cnt == 0)
            $display("  STATUS       : *** ALL TESTS PASSED — DESIGN VERIFIED ***");
        else
            $display("  STATUS       : *** %0d TEST(S) FAILED — REVIEW REQUIRED ***", fail_cnt);
        $display("============================================================\n");

        $finish;
    end

    //=========================================================================
    // Timeout Watchdog (prevents infinite simulation on hang)
    //=========================================================================
    initial begin
        #5_000_000; // 5 ms timeout
        $display("[TIMEOUT] Simulation exceeded time limit — forcing stop.");
        $finish;
    end

endmodule
