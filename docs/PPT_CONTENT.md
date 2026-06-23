# PPT Presentation Content
## SPI-Based Dual Port RAM Interface in Verilog HDL

---

### SLIDE 1 — TITLE SLIDE
**Title**: SPI-Based Dual Port RAM Interface in Verilog HDL  
**Subtitle**: RTL Design, Simulation & Functional Verification  
**Presenter**: [Your Name]  
**Institution/Organization**: [Name]  
**Date**: 2025  
**Visual**: Circuit board background, SPI waveform overlay

---

### SLIDE 2 — AGENDA
1. Project Abstract
2. Problem Statement
3. SPI Protocol Overview
4. System Architecture
5. RTL Module Details
6. Simulation & Waveforms
7. Verification Results
8. Applications & Future Scope
9. Conclusion

---

### SLIDE 3 — ABSTRACT
**Title**: What Did We Build?

> A fully synthesizable SPI Master/Slave controller stack integrated with a 128×8-bit True Dual Port RAM in Verilog HDL — verified with a self-checking testbench achieving 100% functional coverage.

**Key Numbers:**
- 📦 3 RTL Modules  |  ~300 lines of RTL
- 🔬 10 Test Cases   |  21 Pass/Fail checks
- ⚡ 12.5 MHz SPI   |  100 MHz system clock
- 💾 128 bytes RAM  |  1 Kbit BRAM

---

### SLIDE 4 — PROBLEM STATEMENT
**Title**: The Challenge

❌ **Without this design**: CPU needs wide parallel bus to access memory AND no serial port access possible simultaneously.

✅ **With this design**: 
- External SPI device reads/writes RAM over 4 wires
- CPU accesses same RAM via parallel Port A simultaneously
- No arbitration overhead, no bus contention

**Use Case Diagram**: [External SPI Master] ←SPI→ [FPGA] ←Parallel→ [CPU]

---

### SLIDE 5 — SPI PROTOCOL
**Title**: Serial Peripheral Interface (SPI) — Mode 0

**Diagram**: CS_N/SCLK/MOSI/MISO waveform for 16-bit frame

**Frame Format** (16 bits, MSB first):
```
[ RW(1) | ADDRESS[6:0] | DATA[7:0] ]
  Bit15    Bits 14-8      Bits 7-0
```

| Feature | Value |
|---------|-------|
| Mode | CPOL=0, CPHA=0 |
| Full-duplex | ✅ |
| Speed | Up to 12.5 MHz |
| Frame | 16 bits |

---

### SLIDE 6 — SYSTEM ARCHITECTURE
**Title**: Top-Level Block Diagram

[Show ASCII art from README or Draw.io screenshot]

**Three-Module Architecture:**
- **SPI Master**: Serializes user commands, drives SPI bus
- **SPI Slave**: Deserializes frames, controls RAM Port B
- **Dual Port RAM**: 128×8-bit BRAM with two independent ports

---

### SLIDE 7 — SPI MASTER FSM
**Title**: spi_master.v — State Machine

**State Diagram:**
```
       start=1
IDLE ──────────► ACTIVE ──────────► DONE
  ◄────────────────────────────────────
       (bit_cnt==16 & sclk_fall)   (auto)
```

**Key Operations:**
- IDLE: Pack frame {rw, addr, data_in}
- ACTIVE: Shift MOSI out (↓ edge), Sample MISO (↑ edge)
- DONE: Deassert CS_N, capture miso_data, pulse done

---

### SLIDE 8 — SPI SLAVE
**Title**: spi_slave.v — Synchronizer + Decoder

**2-FF Synchronizer** (prevents metastability):
```
SCLK_external → FF1 → FF2 → Edge Detect → Logic
```

**Frame Decode:**
- Bit[15]=0 → WRITE → drive ram_wen_b, addr_b, wdata_b
- Bit[15]=1 → READ → drive ram_ren_b, preload tx_shift

---

### SLIDE 9 — DUAL PORT RAM
**Title**: dual_port_ram.v — True DPRAM Architecture

**Diagram**: Two-port memory with independent clocks, addr, data, control

**Specifications:**
| Feature | Value |
|---------|-------|
| Organization | 128 × 8-bit |
| Total Size | 1 Kbit |
| Mode | WRITE_FIRST |
| Inference | BRAM (block) |
| Collision | Port A priority |

---

### SLIDE 10 — SIMULATION WAVEFORMS
**Title**: ModelSim Simulation Results

[Screenshot of ModelSim waveform window]

**Annotated Waveform Showing:**
1. Reset release
2. spi_start pulse
3. CS_N assertion
4. SCLK toggling (16 cycles)
5. MOSI serialized data
6. done pulse
7. RAM write enable
8. RAM address/data

---

### SLIDE 11 — VERIFICATION RESULTS
**Title**: 100% Tests Passed — Design Verified

| Test Case | Description | Result |
|-----------|-------------|--------|
| TC-001 | Basic Write | ✅ PASS |
| TC-002 | Basic Read | ✅ PASS |
| TC-003/004 | Burst W/R | ✅ PASS (16×) |
| TC-005/006 | Cross-port | ✅ PASS |
| TC-007 | Boundary addr | ✅ PASS |
| TC-008/009 | 0x00/0xFF | ✅ PASS |
| TC-010 | Overwrite | ✅ PASS |

**Summary: 21/21 Checks — ZERO Failures**

---

### SLIDE 12 — APPLICATIONS
**Title**: Real-World Use Cases

🏭 **Industrial**: PLC shared memory  
📡 **IoT**: Sensor data buffer  
🏥 **Medical**: Dual-access acquisition  
🌐 **Networking**: Packet buffer  
💻 **Embedded**: MCU + SPI peripheral  
🔬 **FPGA**: Multi-clock-domain BRAM  

---

### SLIDE 13 — FUTURE SCOPE
**Title**: Roadmap to Production

1. 🔄 AXI4-Lite Port A — SoC integration
2. 📦 SPI Burst Mode — multi-byte transfers
3. 🛡️ ECC — SECDED fault tolerance
4. 🔐 Formal Verification — SVA + SymbiYosys
5. 🔗 Multi-slave SPI — CS decoder for 8 devices
6. ⚡ CDC FIFO — true async dual-clock

---

### SLIDE 14 — CONCLUSION
**Title**: Key Takeaways

✅ Successfully designed a complete SPI-to-DPRAM interface  
✅ 3-module RTL hierarchy, fully synthesizable  
✅ 100% functional verification (21/21 checks)  
✅ Ready for Xilinx/Intel FPGA deployment  
✅ Industry-grade documentation and simulation flow  

**GitHub Repository**: [Link]

---

### SLIDE 15 — THANK YOU / Q&A
**Title**: Thank You

Questions & Answers

[Contact Information]  
[GitHub Link]  
[LinkedIn]
