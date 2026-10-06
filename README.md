# RISC-V Software-Scheduled Pipeline (CprE 381, Project Part 2)

A five-stage pipelined RV32I processor in VHDL with no hazard hardware: the assembly program is reordered and padded with NOPs so hazards never occur.

| | |
|---|---|
| Period | November – December 2025 |
| Team | 2 — Jongwoo Kim, Veda Vegiraju (Project Group F_04) |
| My role | Pipeline registers, top-level integration, scheduled test programs |
| Stack | VHDL, RISC-V assembly, QuestaSim, Quartus (timing), RARS, course toolflow |

## Overview

- **Problem:** the single-cycle processor needs a 41.40 ns clock because one instruction passes through every block in a single cycle. Splitting the datapath into stages shortens the clock, but instructions now overlap and can read stale values or follow the wrong branch.
- **Approach in this stage:** add the four pipeline registers (IF/ID, ID/EX, EX/MEM, MEM/WB) and leave hazard handling to the programmer.

## My role

The commits in this repository are mine. I added the four pipeline registers, rewired `RISCV_Processor.vhd` around them, and rescheduled the test programs so they run correctly without the maximum number of NOPs. The report was written with my teammate.

## What I learned

**Technical**
- Listing which datapath values and control signals each stage needs, and carrying only those forward.
- Identifying data and control dependencies by hand, which made clear exactly what forwarding and stalling hardware would have to detect.
- Finding the critical path in a Quartus timing report.

**Teamwork**
- Using short-lived branches and pull requests to merge processor changes.

## Resources used

- Patterson and Hennessy, *Computer Organization and Design: RISC-V Edition*
- Course toolflow (`3810_tf.sh`, `cpre3810-toolflow.pdf`) and lecture material
- QuestaSim, Quartus, RARS

## Results

- Maximum frequency 59.53 MHz (16.80 ns), about 2.5 times the single-cycle clock rate.
- Critical path: ID/EX register → ALU control → ALU adder and compare → next-PC logic → PC register.
- Mergesort: 3,948 instructions in 4,411 cycles (CPI 1.12), 74,105 ns in total.

## Limitations and next steps

- The faster clock does not pay off on Mergesort. Scheduling grows the program from 1,695 to 3,948 executed instructions, so total time (74,105 ns) is slightly worse than single-cycle (70,214 ns).
- Correctness depends on the programmer; an unscheduled program gives wrong results.
- Next step: detect and resolve hazards in hardware, done in [Project-Part-1](https://github.com/devjwk/Project-Part-1).

## The three processors

This repository is one of three from the same term project.

| Stage | Repository | Max clock period | Max frequency |
|---|---|---|---|
| Single-cycle | [Project-Part-1-RISC-V-Single-cycle-Processor](https://github.com/devjwk/Project-Part-1-RISC-V-Single-cycle-Processor) | 41.40 ns | about 24.2 MHz |
| Software-scheduled pipeline | [Project-Part-2](https://github.com/devjwk/Project-Part-2) | 16.80 ns | 59.53 MHz |
| Hardware-scheduled pipeline | [Project-Part-1](https://github.com/devjwk/Project-Part-1) | 25.43 ns | 39.33 MHz |
