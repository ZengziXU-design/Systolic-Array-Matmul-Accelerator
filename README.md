# Systolic-Array-Matmul-Accelerator

This repository contains the **baseline-1** RTL design of a **4×4 systolic-array-based matrix multiplication accelerator** written in Verilog/SystemVerilog, together with a lightweight RTL testbench suite.

The design demonstrates the core idea of systolic dataflow: matrix **A** streams horizontally, matrix **B** streams vertically, and skewed inputs are used to align multiply-accumulate operations in time. Each processing element (PE) contributes to one output entry through temporal accumulation and local data forwarding.

## Baseline-1 Design

This repository corresponds to the **baseline-1** version of our accelerator.

Main features:
- 4×4 matrix multiplication accelerator
- systolic-array datapath
- skewed input scheduling for A and B
- signed 8-bit input elements
- local multiply-accumulate processing in each PE
- reusable tiled compute structure for future scaling to larger matrix multiplication

## Repository Structure

### `rtl/`

Contains the RTL implementation.

- **`Proj_44_Xcel.v`**  
  Top-level module of the accelerator. It connects the control path and datapath and exposes the request/response accelerator interface.

- **`xcel-msgs.v`**  
  Defines the accelerator request and response message formats, including packed struct typedefs and message type macros.

- **`XcelCtrl.v`**  
  Control logic of the accelerator. It handles request decoding, scheduling, enable generation, and response timing.

- **`XcelDpath.v`**  
  Datapath of the accelerator. It stores matrix inputs, generates skewed systolic inputs, connects the PE array, and prepares read responses.

- **`XcelPE.v`**  
  Processing element module. Each PE forwards input operands and performs multiply-accumulate operations.

### `tb/`

Contains RTL simulation testbenches.

- **`tb_common.vh`**  
  Shared helper tasks for reset, request generation, matrix loading, golden-model matrix multiplication, and result checking.

- **`tb_basic.v`**  
  Deterministic functional test using fixed positive-valued matrices.

- **`tb_signed.v`**  
  Functional test using signed matrix values to verify correct signed 8-bit handling and accumulation.

- **`tb_random.v`**  
  Randomized regression test for multiple matrix pairs.

## RTL Simulation

For the **public RTL version**, simulation is provided using **Icarus Verilog (`iverilog`)**, since this does not involve confidential implementation collateral.

In the actual project flow, RTL simulation was performed using **Synopsys VCS**. However, for open-source release and reproducibility, this repository uses **Icarus Verilog** for the public testbench flow.

### Run basic test

```bash
iverilog -g2012 -I ./tb -I ./rtl -o simv_basic ./tb/tb_basic.v ./rtl/Proj_44_Xcel.v
vvp simv_basic
