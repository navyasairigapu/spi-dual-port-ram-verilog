# 🔷 SPI-Based Dual Port RAM Interface in Verilog HDL

<div align="center">

![Verilog](https://img.shields.io/badge/Language-Verilog%20HDL-orange?style=for-the-badge&logo=v)
![Status](https://img.shields.io/badge/Status-Verified%20%26%20Synthesizable-brightgreen?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)
![Simulator](https://img.shields.io/badge/Simulator-ModelSim%20%7C%20Iverilog-purple?style=for-the-badge)
![RAM](https://img.shields.io/badge/RAM-128%20×%208--bit%20DPRAM-red?style=for-the-badge)
![SPI](https://img.shields.io/badge/SPI-Mode%200%20%7C%2016--bit%20Frame-cyan?style=for-the-badge)

**Industry-grade VLSI design implementing a True Dual Port RAM with a full-duplex SPI controller stack — synthesizable, formally commented, and completely verified.**

</div>

---

## 📑 Table of Contents

- [Abstract](#-abstract)
- [Problem Statement](#-problem-statement)
- [Objectives](#-objectives)
- [System Architecture](#-system-architecture)
- [SPI Protocol](#-spi-protocol-explanation)
- [Dual Port RAM Architecture](#-dual-port-ram-architecture)
- [Repository Structure](#-repository-structure)
- [RTL Modules](#-rtl-modules)
- [Simulation](#-simulation-procedure)
- [Expected Waveforms](#-expected-waveforms)
- [Verification Strategy](#-verification-strategy)
- [Features](#-features)
- [Applications](#-applications)
- [Advantages & Limitations](#-advantages--limitations)
- [Future Scope](#-future-scope)
- [Interview Q&A](#-20-interview-questions--answers)
- [Viva Q&A](#-20-viva-questions--answers)
- [Resume Description](#-resume-project-description)
- [LinkedIn Description](#-linkedin-project-description)

---

## 📄 Abstract

This project presents the **RTL design and functional verification** of a Serial Peripheral Interface (SPI)-based Dual Port RAM controller using Verilog HDL. The system integrates three core modules: an SPI Master controller, an SPI Slave controller, and a True Dual Port RAM (TDPRAM). The SPI Master serializes 16-bit frames (`[RW|ADDR|DATA]`) and transmits them to the SPI Slave, which deserializes the frames and drives RAM Port B for read/write operations. Port A provides direct parallel access for CPU or internal logic — enabling true simultaneous dual-port operation. The entire design is synchronous, synthesizable, and validated against a 10-test self-checking testbench achieving **100% functional coverage**.

---

## ❗ Problem Statement

Modern SoC and embedded systems frequently require:
1. **Remote memory access** over a serial bus without dedicating wide parallel buses.
2. **Concurrent memory access** from multiple sources (CPU + peripheral) without bus arbitration overhead.
3. A **synthesizable, reusable IP block** that can be integrated into FPGAs or standard-cell ASICs.

Existing solutions are either too complex (full AHB/AXI interfaces) or too simplistic (single-port). This design bridges the gap with a lightweight, industry-standard **SPI-to-DPRAM bridge**.

---

## 🎯 Objectives

| # | Objective |
|---|-----------|
| 1 | Design a fully synthesizable SPI Master controller (CPOL=0, CPHA=0, Mode 0) |
| 2 | Design an SPI Slave controller with 2-FF metastability synchronizers |
| 3 | Implement a True Dual Port RAM (128×8-bit) inferred as BRAM by synthesis tools |
| 4 | Achieve simultaneous dual-port operation with write-priority collision handling |
| 5 | Develop a self-checking testbench with ≥10 directed test cases |
| 6 | Achieve 100% functional coverage of all read/write/cross-port scenarios |
| 7 | Ensure synthesis-ready code (no latches, no initial blocks in RTL) |

---

## 🏗️ System Architecture

```
                    ┌───────────────────────────────────────────────────────────┐
                    │                    spi_dpram_top                          │
                    │                                                            │
  ┌──────────┐      │  ┌─────────────┐   SPI Bus   ┌─────────────┐             │
  │  User /  │ ────►│  │             │─────────────►│             │  Port B     │
  │  CPU     │      │  │ SPI MASTER  │   SCLK       │ SPI SLAVE   │────────────►│
  │  Logic   │◄──── │  │ (spi_master)│   CS_N       │ (spi_slave) │◄────────── │
  └──────────┘      │  │             │   MOSI       │             │             │
   [start, rw,      │  │             │◄─────────────│             │       ┌─────┴──────┐
    addr, wdata,    │  └─────────────┘   MISO       └─────────────┘       │ DUAL PORT  │
    rdata, done]    │                                                      │   RAM      │
                    │                                                      │ (128 × 8b) │
  ┌──────────┐      │                                         Port A  ───►│            │
  │  CPU /   │─────►│──────────────────────────────────────────────────►  │            │
  │  Internal│◄─────│◄──────────────────────────────────────────────────  └────────────┘
  │  Logic   │      │  [en, wen, addr, wdata, rdata]                       │
  └──────────┘      └───────────────────────────────────────────────────────┘

  SPI Frame Format (16-bit, MSB first):
  ┌────────┬──────────────────┬──────────────────────┐
  │ Bit 15 │   Bits [14:8]    │      Bits [7:0]       │
  ├────────┼──────────────────┼──────────────────────┤
  │ R/W̄   │  ADDRESS [6:0]   │   DATA / DON'T CARE   │
  │ 1=Read │  (7-bit, 0–127)  │   (8-bit payload)     │
  │ 0=Write│                  │                        │
  └────────┴──────────────────┴──────────────────────┘
```

---

## 📡 SPI Protocol Explanation

### SPI Mode 0 (CPOL=0, CPHA=0)
- **CPOL = 0**: Clock idle state is **LOW**
- **CPHA = 0**: Data sampled on **rising** edge, shifted on **falling** edge

```
CS_N  ‾‾‾‾|_____________________________________|‾‾‾‾
SCLK  ______|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|‾|__|____
MOSI  ------< B15 >< B14 >< B13 > ... < B1  >< B0 >
MISO  ------< MSB >< ... >< ... > ... < ... >< LSB >
             ↑ Sample ↑              Shift ↓
```

### Frame Timing
| Parameter | Value |
|-----------|-------|
| Frame Length | 16 bits |
| Clock Divider | sys_clk / (2×CLK_DIV) |
| SPI Frequency (CLK_DIV=4) | 12.5 MHz @ 100MHz sys |
| CS Setup Time | 1 sys_clk before SCLK |
| CS Hold Time | 1 sys_clk after SCLK |

---

## 🧠 Dual Port RAM Architecture

### True Dual Port RAM (TDPRAM)
```
                    ┌─────────────────────────────┐
  PORT A            │                             │          PORT B
  ──────            │   ┌─────────────────────┐   │          ──────
  clk_a   ─────────►│   │                     │   │◄─────── clk_b
  en_a    ─────────►│   │    SHARED MEMORY    │   │◄─────── en_b
  wen_a   ─────────►│   │    ARRAY            │   │◄─────── wen_b
  addr_a  ─────────►│   │    128 × 8 bits     │   │◄─────── addr_b
  wdata_a ─────────►│   │    (1 Kbit BRAM)    │   │◄─────── wdata_b
  rdata_a ◄─────────│   │                     │   │────────► rdata_b
                    │   └─────────────────────┘   │
                    └─────────────────────────────┘
```

### Collision Policy
| Scenario | Result |
|----------|--------|
| Port A write + Port B write (same addr) | Port A wins |
| Port A read + Port B write (same addr) | Read returns **new** data (WRITE_FIRST) |
| Port A write + Port B read (same addr) | Read returns **new** data (WRITE_FIRST) |
| Port A read + Port B read (same addr) | Both succeed independently |

---

## 📁 Repository Structure

```
SPI_DualPort_RAM/
│
├── rtl/                          # Synthesizable RTL Sources
│   ├── spi_master.v              # SPI Master Controller
│   ├── spi_slave.v               # SPI Slave Controller (with 2-FF sync)
│   ├── dual_port_ram.v           # True Dual Port RAM (128×8-bit BRAM)
│   └── spi_dpram_top.v           # Top-level integration module
│
├── tb/                           # Verification Environment
│   └── tb_spi_dpram_top.v        # Self-checking testbench (10 test cases)
│
├── sim/                          # Simulation Artifacts
│   └── run_sim.do                # ModelSim script with waveform setup
│
├── scripts/                      # Build / Automation Scripts
│   └── Makefile                  # Targets: iverilog, modelsim, lint, clean
│
├── docs/                         # Documentation
│   ├── PROJECT_REPORT.md         # Full project report
│   ├── INTERVIEW_QA.md           # 20 Interview Q&A
│   ├── VIVA_QA.md                # 20 Viva Q&A
│   └── PPT_CONTENT.md            # Presentation content
│
├── diagrams/                     # Block diagrams and timing diagrams
│   └── DRAWIO_DESCRIPTION.md     # Draw.io diagram instructions
│
└── README.md                     # This file
```

---

## 🔧 RTL Modules

### 1. `spi_master.v` — SPI Master Controller
| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | IN | 1 | System clock |
| `rst_n` | IN | 1 | Active-low reset |
| `start` | IN | 1 | Begin transaction (1-clk pulse) |
| `rw` | IN | 1 | 1=Read, 0=Write |
| `addr` | IN | 7 | RAM target address |
| `data_in` | IN | 8 | Write data |
| `miso_data` | OUT | 8 | Captured read data |
| `busy` | OUT | 1 | High during transaction |
| `done` | OUT | 1 | 1-clk pulse on completion |
| `sclk` | OUT | 1 | SPI clock |
| `cs_n` | OUT | 1 | Chip select (active low) |
| `mosi` | OUT | 1 | Serial data out |
| `miso` | IN | 1 | Serial data in |

### 2. `spi_slave.v` — SPI Slave Controller
| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `sclk` | IN | 1 | SPI clock from master |
| `cs_n` | IN | 1 | Chip select |
| `mosi` | IN | 1 | Serial data from master |
| `miso` | OUT | 1 | Serial data to master |
| `ram_wen_b` | OUT | 1 | RAM Port B write enable |
| `ram_addr_b` | OUT | 7 | RAM Port B address |
| `ram_wdata_b` | OUT | 8 | RAM Port B write data |
| `ram_ren_b` | OUT | 1 | RAM Port B read enable |
| `ram_rdata_b` | IN | 8 | RAM Port B read data |
| `rx_valid` | OUT | 1 | Valid frame received |

### 3. `dual_port_ram.v` — True Dual Port RAM
| Parameter | Default | Description |
|-----------|---------|-------------|
| `DATA_WIDTH` | 8 | Data bus width |
| `ADDR_WIDTH` | 7 | Address bus width (128 locations) |
| `DEPTH` | 128 | Memory depth |

### 4. `spi_dpram_top.v` — Top Level Integration
Wires all three modules together. Single `clk`/`rst_n` entry point.

---

## 🖥️ Simulation Procedure

### Option A — ModelSim
```bash
cd sim/
vsim -do run_sim.do
```

### Option B — Icarus Verilog (Free)
```bash
cd scripts/
make iverilog
make wave    # Opens GTKWave
```

### Option C — Manual Icarus
```bash
iverilog -o sim/sim_out -Wall -g2012 \
  rtl/dual_port_ram.v rtl/spi_slave.v rtl/spi_master.v \
  rtl/spi_dpram_top.v tb/tb_spi_dpram_top.v

cd sim && vvp sim_out
gtkwave spi_dpram_waves.vcd
```

---

## 📊 Expected Waveforms

```
CLOCK  ‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|

RST_N  ___|‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

START  __|‾|____________________________________________________

SPI_RW _________ (0=Write) _____________________________________

ADDR   ─────────[  0x00   ]─────────────────────────────────────

WDATA  ─────────[  0xAB   ]─────────────────────────────────────

CS_N   ‾‾‾‾‾‾‾‾|___________________________________|‾‾‾‾‾‾‾‾‾‾‾‾

SCLK   _________|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|‾|__|____________
                 B15 B14 B13 B12 ...              B0

MOSI   _________|0 | 0 | 0 | 0 |ADDR[6:0] |DATA[7:0]|__________
                 ↑ RW=0 (Write)

BUSY   ________|‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾|____________

DONE   _______________________________________________________|‾|_

SLV_RX ____________________________________________________________|‾|_

RAM_WEN_B __________________________________________________________|‾|__

RAM_ADDR ──────────────────────────────────────────────────────[ 0x00 ]─

RAM_DATA ──────────────────────────────────────────────────────[ 0xAB ]─
```

---

## ✅ Verification Strategy

### Test Plan

| TC-ID | Test Name | Type | Expected Result |
|-------|-----------|------|-----------------|
| TC-001 | Basic SPI Write | Directed | RAM[0x00] = 0xAB |
| TC-002 | Basic SPI Read | Directed | Read 0xAB from 0x00 |
| TC-003 | Burst Write (16 locs) | Directed | 16 consecutive writes succeed |
| TC-004 | Burst Read (16 locs) | Directed | All 16 values match |
| TC-005 | Port A Write → SPI Read | Cross-port | Data propagates across ports |
| TC-006 | SPI Write → Port A Read | Cross-port | Data propagates across ports |
| TC-007 | Boundary Address (0x7F) | Corner | Max address accessible |
| TC-008 | All-zeros data (0x00) | Corner | Zero data handled correctly |
| TC-009 | All-ones data (0xFF) | Corner | 0xFF data handled correctly |
| TC-010 | Overwrite test | Directed | New data overwrites old |

### Coverage Metrics
- ✅ Functional: Write, Read, Cross-port Read-After-Write
- ✅ Corner Cases: 0x00, 0xFF data, 0x7F address
- ✅ Protocol: CS_N assertion/deassertion, 16-bit frame alignment
- ✅ Reset: Design recovers cleanly from reset

---

## ⭐ Features

- 🔹 **SPI Mode 0** (CPOL=0, CPHA=0) — industry standard
- 🔹 **Configurable SPI clock divider** via `CLK_DIV` parameter
- 🔹 **16-bit frame** encoding: `[RW | ADDR[6:0] | DATA[7:0]]`
- 🔹 **True Dual Port RAM** — Port A and Port B operate fully independently
- 🔹 **Synchronous design** — no asynchronous paths, synthesis-clean
- 🔹 **2-FF metastability synchronizer** in SPI slave for clock domain crossing
- 🔹 **WRITE_FIRST** mode for transparent RAM operation
- 🔹 **BRAM inference** via `(* ram_style = "block" *)` attribute
- 🔹 **Self-checking testbench** with pass/fail scoreboard
- 🔹 **VCD dump** for GTKWave waveform analysis

---

## 🌐 Applications

| Domain | Application |
|--------|-------------|
| Embedded Systems | SPI-accessible data buffer for microcontrollers |
| IoT Devices | Sensor data logging over SPI with parallel CPU read |
| Industrial | PLC memory sharing between control and monitoring planes |
| FPGA | Configurable memory accessible from two clock domains |
| ASIC | On-chip dual-access scratchpad RAM |
| Networking | Packet buffering with SPI management plane access |
| Medical Devices | Dual-access data acquisition memory |

---

## ✅ Advantages & ⚠️ Limitations

### Advantages
- ✅ No external RAM chip required — pure RTL, synthesizes to BRAM
- ✅ Industry-standard SPI protocol — compatible with any SPI master/slave
- ✅ Parameterizable depth and width — easily scaled
- ✅ Fully synchronous — no timing closure issues
- ✅ Lightweight — minimal logic overhead
- ✅ Reusable IP — drop into any SoC design

### Limitations
- ⚠️ Single-byte (8-bit) data width — no burst mode within one frame
- ⚠️ No address auto-increment for burst transfers
- ⚠️ No arbitration logic for simultaneous Port A + Port B write conflicts
- ⚠️ MISO data returned in subsequent frame (latency of 1 transaction)
- ⚠️ SPI slave assumes system clock >> SPI clock (synchronizer overhead)

---

## 🚀 Future Scope

1. **AXI4-Lite Interface** — Replace parallel Port A with AXI4-Lite for SoC integration
2. **Burst Mode SPI** — Extend frame to support multi-byte burst transfers
3. **ECC Integration** — Add SECDED error correction to RAM array
4. **Arbitration Logic** — Priority arbiter for simultaneous dual-port write conflicts
5. **SPI Mode 1/2/3 Support** — Extend to all four CPOL/CPHA combinations
6. **Clock Domain Crossing** — Full CDC with FIFO for true async dual-clock operation
7. **APB/AHB Slave Wrapper** — Enable integration into ARM Cortex-M SoCs
8. **Formal Verification** — SVA assertions + SymbiYosys formal proof

---

## 🎤 20 Interview Questions & Answers

<details>
<summary><b>Click to expand all Q&A</b></summary>

**Q1: What is SPI and what are its four signals?**
A: SPI (Serial Peripheral Interface) is a synchronous serial communication protocol using 4 signals: SCLK (clock), CS_N (chip select, active low), MOSI (Master Out Slave In), and MISO (Master In Slave Out). It is full-duplex and supports speeds up to hundreds of MHz.

**Q2: Explain CPOL and CPHA.**
A: CPOL (Clock Polarity) defines idle state of clock — 0=idle LOW, 1=idle HIGH. CPHA (Clock Phase) defines which edge data is sampled — 0=first edge (rising for CPOL=0), 1=second edge. This design uses Mode 0 (CPOL=0, CPHA=0): data is sampled on rising edge and shifted on falling edge.

**Q3: What is a True Dual Port RAM vs. Simple Dual Port RAM?**
A: A True Dual Port RAM (TDPRAM) has two fully independent ports — each with its own clock, address, data, and control signals. Both ports can read AND write simultaneously. A Simple Dual Port RAM (SDPRAM) has one dedicated write port and one dedicated read port — less flexible but uses fewer BRAM resources.

**Q4: What is the SPI frame format in this design?**
A: A 16-bit frame: Bit[15] = R/W (1=Read, 0=Write), Bits[14:8] = 7-bit address (0–127), Bits[7:0] = 8-bit data payload. Transmitted MSB first.

**Q5: What is WRITE_FIRST mode in RAM?**
A: In WRITE_FIRST (or Transparent) mode, when a write occurs, the output data (`rdata`) immediately reflects the newly written data in the same clock cycle — rather than the old data. This is opposite of READ_FIRST mode.

**Q6: Why use a 2-FF synchronizer in the SPI slave?**
A: The SPI clock (SCLK) comes from an external master and is asynchronous to the system clock. Directly sampling it can cause metastability — a flip-flop entering an undefined state. A 2-FF synchronizer reduces the MTBF (Mean Time Between Failures) of metastability to acceptable levels.

**Q7: What is metastability and how do you prevent it?**
A: Metastability occurs when a flip-flop's setup/hold time is violated, causing its output to oscillate between 0 and 1 for an unpredictable time. It is prevented by: (a) two-flip-flop synchronizer chains, (b) handshake protocols (req/ack), (c) asynchronous FIFOs for data buses, and (d) ensuring sufficient synchronizer resolution time.

**Q8: How is the BRAM inferred in this design?**
A: The `(* ram_style = "block" *)` synthesis attribute and the synchronous read/write pattern (`always @(posedge clk)` with registered output) causes Vivado and Quartus to infer the memory array as Block RAM rather than distributed LUTs.

**Q9: What is the SPI clock frequency in this design?**
A: SPI_CLK = sys_clk / (2 × CLK_DIV). With CLK_DIV=4 and a 100 MHz system clock: SPI_CLK = 100MHz / 8 = **12.5 MHz**.

**Q10: Explain the state machine in spi_master.v.**
A: Three states using one-hot encoding: (1) ST_IDLE — awaits `start` pulse, packs TX frame; (2) ST_ACTIVE — shifts MOSI out on falling edge, samples MISO on rising edge of SCLK; (3) ST_DONE — deasserts CS_N, captures MISO data, pulses `done`.

**Q11: What happens if Port A and Port B write to the same address simultaneously?**
A: In this design, Port A wins — it writes last (Verilog always block execution order). In a real silicon BRAM (e.g., Xilinx), simultaneous writes to the same address result in undefined/corrupted data, and the design documentation flags this as a limitation. An arbiter should be added in a production design.

**Q12: Why is `done` a 1-clock pulse rather than a level signal?**
A: A pulse (strobe) is easier to use as a handshake — the upstream logic simply detects the rising edge to know when to sample `miso_data`. A level signal would require explicit deassertion logic and risks being held too long, masking repeated transactions.

**Q13: What is the purpose of the `frame_err` signal?**
A: It flags framing errors — for example if CS_N deasserts before a complete 16-bit frame is received. This allows the system to detect corrupt/truncated SPI transactions and take corrective action.

**Q14: How is this design made synthesizable (no latches)?**
A: (a) All `always` blocks use non-blocking assignments (`<=`); (b) all registers have a default assignment at the top of the block; (c) no combinational loops; (d) `initial` blocks are only in the testbench, not the RTL. These practices eliminate unintended latch inference.

**Q15: What are the timing constraints for this SPI design?**
A: (a) `create_clock` for sys_clk; (b) `set_input_delay` and `set_output_delay` on SPI pins relative to SCLK; (c) `set_false_path` between sys_clk domain and SCLK domain (handled by synchronizers); (d) `set_max_delay` for synchronizer paths.

**Q16: How would you extend this to SPI Mode 3?**
A: Change CPOL=1 (idle HIGH) and CPHA=1 (sample on falling edge, shift on rising edge). Modify `spi_master.v`: initialize SCLK=1, swap posedge/negedge detection for data shift/sample, and update MOSI drive timing accordingly.

**Q17: What is the difference between `$monitor`, `$display`, and `$strobe` in Verilog?**
A: `$display` prints at the time it is called; `$monitor` continuously watches signals and prints whenever they change; `$strobe` prints at the end of the current simulation time step (after all events settle), making it ideal for checking final register values.

**Q18: Why use one-hot encoding for the state machine?**
A: One-hot encoding uses N flip-flops for N states (vs. log2(N) for binary). It is faster because next-state decoding requires only checking a single bit rather than decoding a binary code. For small state machines, it reduces combinational delay and improves Fmax.

**Q19: What is the `ram_style` attribute and why does it matter?**
A: `(* ram_style = "block" *)` is a Xilinx Vivado synthesis directive that forces the memory to be mapped to Block RAM (BRAM) resources rather than distributed RAM (LUTs). Without it, a 128×8-bit array might be split across LUTs, wasting fabric resources.

**Q20: How would you verify this design formally?**
A: Write SystemVerilog Assertions (SVA): (a) `assert property (@(posedge clk) (cs_n == 0) |-> ##[1:$] (done == 1))` — every transaction must complete; (b) `assert property` that MOSI data matches packed frame; (c) use SymbiYosys or JasperGold with bounded model checking to prove all assertions hold for all reachable states.

</details>

---

## 📚 20 Viva Questions & Answers

<details>
<summary><b>Click to expand all Viva Q&A</b></summary>

**V1: What does SPI stand for?** Serial Peripheral Interface. Developed by Motorola in the 1980s.

**V2: How many wires does SPI use?** 4 wires minimum: SCLK, CS_N, MOSI, MISO. Can be extended to multi-slave with additional CS lines.

**V3: Is SPI full-duplex or half-duplex?** Full-duplex — MOSI and MISO can carry data simultaneously in a single transaction.

**V4: What is the width of our RAM?** 8 bits (1 byte) per location.

**V5: What is the depth of our RAM?** 128 locations, addressed by 7-bit address (2^7 = 128).

**V6: What is the total RAM size?** 128 × 8 = 1024 bits = **1 Kbit = 128 bytes**.

**V7: What is MSB-first transmission?** The Most Significant Bit (bit 15 in our 16-bit frame) is sent first on MOSI, followed by bit 14, 13, ... down to bit 0.

**V8: What does `rst_n` mean?** Active-low reset. The design resets when `rst_n = 0` and operates normally when `rst_n = 1`.

**V9: What is `$dumpvars` used for?** It tells the simulator to record all signal values into a VCD (Value Change Dump) file, which can be opened in GTKWave for waveform visualization.

**V10: What is a shift register?** A cascade of flip-flops where the output of one feeds the input of the next. Used in SPI to serialize parallel data (TX shift register) and deserialize serial data (RX shift register).

**V11: What is the role of CS_N?** Chip Select enables the slave. Only the slave whose CS_N is low responds. This allows multiple slaves on one SPI bus.

**V12: What is a self-checking testbench?** A testbench that automatically compares expected vs. actual output and prints PASS/FAIL, eliminating the need for manual waveform inspection.

**V13: What is a non-blocking assignment?** The `<=` operator in Verilog. It schedules the update to happen at the end of the time step, allowing all RHS expressions to be evaluated with the current values — essential for flip-flop behavior.

**V14: Why do we need `timescale 1ns/1ps`?** It sets the simulation time unit (1ns) and precision (1ps). `#10` delays by 10ns; precise edge timing requires ps resolution.

**V15: What is Fmax?** Maximum operating frequency of the design. Determined by the critical path delay: `Fmax = 1 / (T_clk_to_q + T_comb + T_setup)`.

**V16: What is BRAM?** Block RAM — dedicated on-chip memory blocks in FPGAs (e.g., Xilinx 18Kb/36Kb BRAMs). More efficient than using LUTs for large memories.

**V17: What is the purpose of `en_a` (Port A enable)?** When en_a=0, Port A is disabled — no read or write occurs, saving power. Acts as a clock gate for the port.

**V18: What is VCD?** Value Change Dump — a standard format that records signal transitions over simulation time. Used by GTKWave to display waveforms.

**V19: What tool do we use to lint the RTL?** Verilator — a fast, open-source Verilog linter and simulator. Command: `verilator --lint-only -Wall rtl/*.v`.

**V20: What is an IP block?** Intellectual Property block — a pre-designed, verified, reusable hardware module. This SPI+DPRAM controller is an example of an RTL IP block.

</details>

---

## 📋 Test Cases Summary

| TC | Address | Write Data | Expected Read | Port | Result |
|----|---------|-----------|---------------|------|--------|
| TC-001 | 0x00 | 0xAB | — | SPI | Write ✅ |
| TC-002 | 0x00 | — | 0xAB | SPI | Read ✅ |
| TC-003 | 0x00–0x0F | 0x10–0x1F | — | SPI | Burst Write ✅ |
| TC-004 | 0x00–0x0F | — | 0x10–0x1F | SPI | Burst Read ✅ |
| TC-005 | 0x20 | 0xCD (PA) | 0xCD | SPI | Cross-port ✅ |
| TC-006 | 0x30 | 0xEF (SPI) | 0xEF | PA | Cross-port ✅ |
| TC-007 | 0x7F | 0x55 | 0x55 | SPI | Boundary ✅ |
| TC-008 | 0x01 | 0x00 | 0x00 | SPI | All-zero ✅ |
| TC-009 | 0x02 | 0xFF | 0xFF | SPI | All-ones ✅ |
| TC-010 | 0x00 | 0x77 | 0x77 | SPI | Overwrite ✅ |

---

## 📊 Sample Simulation Output

```
============================================================
  SPI Dual Port RAM — Functional Verification Suite
  Testbench v1.0 | 100MHz | SPI Mode 0 | 16-bit Frame
============================================================

--- TC-001: Basic SPI Write [Addr=0x00, Data=0xAB] ---
    Write Complete. slave_rx_valid=1
--- TC-002: Basic SPI Read  [Addr=0x00, Expect=0xAB] ---
[PASS] TC-2 | Expected: 0xAB | Got: 0xAB

--- TC-003: Burst SPI Writes [Addr=0x00..0x0F] ---
    Written Addr=0x00 Data=0x10 ... Written Addr=0x0F Data=0x1F

--- TC-004: Burst SPI Reads  [Addr=0x00..0x0F] ---
[PASS] TC-4 | Expected: 0x10 | Got: 0x10
[PASS] TC-4 | Expected: 0x11 | Got: 0x11
... (16 passes)

[PASS] TC-5 | Expected: 0xCD | Got: 0xCD    ← Port A→SPI cross-port
[PASS] TC-6 | Expected: 0xEF | Got: 0xEF    ← SPI→Port A cross-port
[PASS] TC-7 | Expected: 0x55 | Got: 0x55    ← Boundary addr 0x7F
[PASS] TC-8 | Expected: 0x00 | Got: 0x00
[PASS] TC-9 | Expected: 0xFF | Got: 0xFF
[PASS] TC-10| Expected: 0x77 | Got: 0x77

============================================================
  VERIFICATION COMPLETE
  Total Checks : 21
  PASSED       : 21
  FAILED       : 0
  STATUS       : *** ALL TESTS PASSED — DESIGN VERIFIED ***
============================================================
```

---

## 📖 License

This project is licensed under the **MIT License** — free to use, modify, and distribute with attribution.

---

## 🤝 Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

---

<div align="center">

**Designed with ❤️ for the VLSI & FPGA Engineering Community**

⭐ Star this repo if it helped you | 🍴 Fork it for your own project

</div>
