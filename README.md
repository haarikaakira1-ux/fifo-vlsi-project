# Synchronous & Asynchronous FIFO with SRAM Controller
## RTL to GDS using Open Source Tools

## Project Overview
Parameterized Sync & Async FIFO design implemented in Verilog,
taken through complete RTL-to-GDS flow using open source EDA tools.

## Tools Used
| Tool | Version | Purpose |
|------|---------|---------|
| Icarus Verilog | 12.0 | RTL Simulation |
| Verilator | 5.032 | Lint Checking |
| Yosys | 0.52 | Synthesis |
| OpenLane | 2.x | RTL to GDS Flow |
| Skywater PDK | 130nm | Technology Library |

## Design Specifications
| Parameter | Value |
|-----------|-------|
| FIFO Depth | 16 |
| Data Width | 8 bits |
| Technology | Skywater 130nm |
| Target Frequency | 50 MHz |

## Synthesis Results (Yosys)
| Metric | Value |
|--------|-------|
| Total Cells | 507 |
| Flip-Flops | 149 |
| Total Wires | 871 |
| AND gates | 194 |
| OR gates | 130 |

## Testbench Results
### Sync FIFO — 6/6 Tests Passing
- Fill FIFO completely
- Write to full (overflow protection)
- Drain FIFO completely
- Read from empty (underflow protection)
- Simultaneous read+write
- Almost-full flag verification

### Async FIFO — 5/5 Tests Passing
- Fill FIFO (dual clock)
- Overflow protection
- Drain FIFO
- Simultaneous RW different clocks
- Burst write then read

## Repository Structure
## How to Run Simulation
```bash
# Sync FIFO
iverilog -o sim/fifo_sim rtl/sync_fifo.v tb/tb_sync_fifo.v
vvp sim/fifo_sim

# Async FIFO
iverilog -o sim/async_fifo_sim rtl/async_fifo.v tb/tb_async_fifo.v
vvp sim/async_fifo_sim
```
