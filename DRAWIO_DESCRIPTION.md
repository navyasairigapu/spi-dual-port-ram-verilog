# Draw.io Block Diagram Instructions
## SPI-Based Dual Port RAM Interface

Follow these step-by-step instructions to recreate the block diagram in draw.io (app.diagrams.net).

---

## DIAGRAM 1: System Architecture (Top-Level)

### Canvas Setup
- Page size: A4 Landscape
- Grid: ON (10px)
- Background: #1a1a2e (dark blue) or white

### Step-by-Step Element Placement

#### 1. Top Enclosing Rectangle (SoC Boundary)
- Shape: Rectangle
- Label: `spi_dpram_top`
- Size: 900 × 500
- Style: `rounded=1; fillColor=#dae8fc; strokeColor=#6c8ebf; fontSize=14; fontStyle=1;`
- Position: Center of canvas

#### 2. SPI Master Block
- Shape: Rectangle
- Label: `SPI MASTER\nspi_master.v`
- Size: 160 × 120
- Style: `rounded=1; fillColor=#fff2cc; strokeColor=#d6b656; fontSize=12; fontStyle=1;`
- Position: Left side inside the SoC block
- Add sub-label: `FSM: IDLE→ACTIVE→DONE`

#### 3. SPI Slave Block
- Shape: Rectangle
- Label: `SPI SLAVE\nspi_slave.v`
- Size: 160 × 120
- Style: `rounded=1; fillColor=#d5e8d4; strokeColor=#82b366; fontSize=12; fontStyle=1;`
- Position: Center of SoC block

#### 4. Dual Port RAM Block
- Shape: Rectangle with vertical divider
- Label: `DUAL PORT RAM\ndual_port_ram.v\n128 × 8-bit`
- Size: 200 × 200
- Style: `rounded=0; fillColor=#f8cecc; strokeColor=#b85450; fontSize=12; fontStyle=1;`
- Position: Right side inside SoC block
- Add two vertical sections labeled `PORT A` and `PORT B`

#### 5. External CPU/User Logic Block
- Shape: Rectangle
- Label: `CPU / User Logic`
- Size: 130 × 80
- Style: `rounded=1; fillColor=#e1d5e7; strokeColor=#9673a6;`
- Position: Left outside the SoC boundary

#### 6. External SPI Master (Optional scenario)
- Shape: Cloud or Rectangle
- Label: `External\nSPI Master`
- Size: 130 × 80
- Style: `rounded=1; fillColor=#fff2cc; strokeColor=#d6b656;`
- Position: Far left, outside SoC

---

### Connections

| From | To | Label | Style |
|------|----|-------|-------|
| External SPI Master | SPI Master | `start/rw/addr/wdata` | Arrow, blue |
| SPI Master | SPI Slave | `SCLK, CS_N, MOSI` | Arrow, orange, bold |
| SPI Slave | SPI Master | `MISO` | Arrow, green, dashed |
| SPI Slave | DPRAM Port B | `wen_b, addr_b, wdata_b` | Arrow, red |
| DPRAM Port B | SPI Slave | `rdata_b` | Arrow, green, dashed |
| CPU/User Logic | DPRAM Port A | `en_a, wen_a, addr_a, wdata_a` | Arrow, purple |
| DPRAM Port A | CPU/User Logic | `rdata_a` | Arrow, green, dashed |
| SPI Master | External | `spi_rdata, done, busy` | Arrow, blue, dashed |

---

## DIAGRAM 2: SPI Frame Format

### Elements
1. **Title**: "SPI Frame Format — 16 bits, MSB First"
2. Create a horizontal row of 16 boxes (each 40×40)
3. Label boxes: B15, B14, B13, B12, B11, B10, B9, B8, B7, B6, B5, B4, B3, B2, B1, B0
4. Color B15 **RED** (RW bit) with label "R/W̄"
5. Color B14–B8 **BLUE** with label "ADDRESS [6:0]"
6. Color B7–B0 **GREEN** with label "DATA [7:0]"
7. Add bracket labels below each group

---

## DIAGRAM 3: SPI Waveform Timing Diagram

### Elements
1. Title: "SPI Mode 0 Timing (CPOL=0, CPHA=0)"
2. Create 5 horizontal signal rows:
   - Row 1: CS_N (high→low→high trapezoid)
   - Row 2: SCLK (16 clock pulses)
   - Row 3: MOSI (16 serial bits)
   - Row 4: MISO (16 serial bits, offset)
   - Row 5: Labels: "Sample↑ / Shift↓"
3. Use zigzag/bus notation for MOSI/MISO data

---

## DIAGRAM 4: FSM State Diagram

### States (Circles)
1. **IDLE** — Circle, yellow fill
2. **ACTIVE** — Circle, green fill  
3. **DONE** — Circle, red fill

### Transitions (Arrows)
- IDLE → ACTIVE: Label `start=1 / pack_frame`
- ACTIVE → DONE: Label `bit_cnt==16 & sclk_fall`
- DONE → IDLE: Label `auto / assert_done`
- IDLE → IDLE: Self-loop `start=0 / —`

---

## DIAGRAM 5: Dual Port RAM Architecture

### Elements
1. Large center rectangle: "Shared Memory Array [127:0][7:0]"
2. Left side arrows (PORT A): clk_a, en_a, wen_a, addr_a[6:0], wdata_a[7:0] → into RAM; rdata_a[7:0] ← out of RAM
3. Right side arrows (PORT B): clk_b, en_b, wen_b, addr_b[6:0], wdata_b[7:0] → into RAM; rdata_b[7:0] ← out of RAM
4. Add collision note at bottom: "Collision Policy: Port A Write Priority | WRITE_FIRST mode"

---

## Export Settings
- Format: PNG (300 DPI) for reports
- Format: SVG for web/GitHub
- Format: PDF for slides
