# IEEE-754 Compliant Floating-Point Unit (FPU) ALU

A 32-bit single-precision IEEE-754 compliant Floating-Point Unit (FPU) Arithmetic Logic Unit (ALU) implemented in Verilog HDL. The design features registered input/output stages for pipelined operation and was simulated using Cadence NCVerilog and synthesized with Cadence Genus using the **SAED 90nm PDK** standard cell library (`saed90nm_typ`).

---

## Technical Overview

The FPU ALU processes 32-bit IEEE-754 single-precision floating-point numbers consisting of 1 sign bit, 8 exponent bits, and 23 mantissa/fraction bits.

### Supported Operations

Operation selection is controlled via an 8-bit `opcode`:

| Opcode (`8'b`) | Operation | Description |
| :--- | :--- | :--- |
| `1111_1111` | **FP Addition** | Floating-point addition with full rounding and exception detection |
| `1111_1101` | **FP Equal** | Logical equality check ($A = B$) |
| `1111_1100` | **FP Unequal** | Logical inequality check ($A \neq B$) |
| `1111_1011` | **FP Greater Than** | Magnitude comparison ($A > B$) |
| `Default` | **Idle / NOP** | Output zeroed |

### Status Flags (`flag[6:0]`)

The top-level ALU outputs a 7-bit status vector indicating arithmetic/IEEE-754 conditions:

- **`flag[6]`**: NaN Flag
- **`flag[5]`**: Infinity Flag
- **`flag[4]`**: Zero Flag
- **`flag[3]`**: Subnormal Flag
- **`flag[2]`**: Sticky Bit Flag
- **`flag[1]`**: Overflow Flag
- **`flag[0]`**: Underflow Flag

---

## Synthesis & Hardware Performance Summary

The design was synthesized using **Cadence Genus Synthesis Solution 20.11-s111_1** targeted to the **SAED 90nm** standard cell library (`saed90nm_typ`).

### Clock & Timing Constraints

- **Target Clock (`clk`) Period:** 20.0 ns (50 MHz operating frequency)
- **Clock Uncertainty / Skew:** 200 ps (0.2 ns)
- **Time Units:** 1.0 ns

### Area & Gate Count Metrics

- **Total Cell Count:** 1,300 instances
- **Total Cell Area:** $15,504.998 \, \mu \text{m}^2$
- **Top Module Breakdown:**
  - Registered ALU Wrapper (`fpu_alu`): 1,300 cells ($15,504.998 \, \mu \text{m}^2$)
  - Combinational Core (`fpu_alu_top`): 1,188 cells ($11,919.053 \, \mu \text{m}^2$)

### Cell Area Utilization Breakdown

| Type | Instance Count | Total Area ($\mu\text{m}^2$) | Area Percentage |
| :--- | :--- | :--- | :--- |
| **Logic (Combinational)** | 1,054 | 11,177.165 | 72.1% |
| **Sequential (DFFARX1)** | 111 | 3,580.416 | 23.1% |
| **Inverters (INVX0, INVX2)** | 135 | 747.418 | 4.8% |
| **Total** | **1,300** | **15,504.998** | **100.0%** |

---

## File Structure

```text
.
├── fpu_alu.v          # Verilog HDL source file containing top-level wrapper, core logic, and sub-modules
├── fpu_alu_tb.v       # Testbench for verifying addition, equality, inequality, and comparison logic
├── constraints.sdc    # SDC constraint file used for synthesis
└── README.md          # Project documentation
```

---

## Architecture Diagram

```text
               +-------------------------------------------------------+
               |                       fpu_alu                         |
               |                                                       |
               |  +------------+     +---------------+     +---------+ |
a [31:0]   --->|->|            |---->| a_out  [31:0] |---->|         | |
b [31:0]   --->|->|   ip_reg   |---->| b_out  [31:0] |---->| fpu_alu | |
opcode [7:0]->|->| (Input Reg)|---->| opcode [7:0]  |---->|   top   | |---> y_in  ---> +---------+
clk, reset ---->|->|            |     +---------------+     | (Core)  | |---> flag_in ---> | op_reg  |---> y [31:0]
               |  +------------+                           +---------+ |                  | (Output |---> flag [6:0]
               |                                                       |                  |  Reg)   |
               +-------------------------------------------------------+                  +---------+
```

---

## Simulation & Verification

The project includes a comprehensive Verilog testbench (`fpu_alu_tb.v`) designed for NCVerilog. It validates:
1. Single-precision addition ($5.0 + 5.0$, $5.25 + 0.75$, $500.25 + 499.75$).
2. Floating-point comparison operations (`==`, `!=`, `>`).
3. Corner cases including $+ \infty$, $-\infty$, zero values, and signed comparisons.

### Running Simulation (NCVerilog / Cadence xrun)

```bash
ncverilog fpu_alu.v fpu_alu_tb.v +access+r
```

---

## Synthesis Commands (Cadence Genus)

To synthesize the design using Genus and the SAED 90nm library:

```tcl
# Read Technology Library
set_attribute library saed90nm_typ.lib

# Read HDL Source
read_hdl fpu_alu.v

# Elaborate Top Module
elaborate fpu_alu

# Apply Constraints
read_sdc constraints.sdc

# Synthesize
syn_generic
syn_map
syn_opt

# Generate Reports
report_area > area_report.txt
report_gates > gates_report.txt
```
