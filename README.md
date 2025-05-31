
FPGA IMPLEMENTATION OF DSSS-CDMA TRANSMITTER AND RECEIVER

DESCRIPTION
-----------
This project implements a basic Direct Sequence Spread Spectrum (DSSS) system 
based on Code Division Multiple Access (CDMA) principles using Verilog HDL. 
It is targeted for simulation and FPGA implementation. The design demonstrates 
how a digital bitstream can be spread using a pseudo-random code and then 
successfully despread at the receiver to recover the original message.

DSSS is a key technique used in wireless communication systems, such as CDMA 
cellular networks, to increase resistance to interference and allow multiple 
users to share the same frequency band.

This implementation focuses on a **single-user system** using a **6-bit LFSR**
for spreading and despreading. The transmitter and receiver modules are verified 
using testbenches provided in this repository.

--------------------------------------------------------------------------------
FILES INCLUDED
--------------------------------------------------------------------------------

1. cdma_transmitter.v      - Transmitter module that performs spreading.
2. cdma_receiver.v         - Receiver module that performs despreading.
3. lfsr_6bit.v             - 6-bit Linear Feedback Shift Register used to generate 
                             the pseudo-random spreading sequence.
4. tb_cdma_transmitter.v   - Testbench for the transmitter.
5. tb_cdma_receiver.v      - Testbench for the receiver.

--------------------------------------------------------------------------------
PROJECT STRUCTURE AND WORKING
--------------------------------------------------------------------------------

[1] LFSR Module:
    - Implements a 6-bit shift register with feedback taps.
    - Generates a pseudo-random binary sequence (PN code).
    - The same LFSR sequence is used at both transmitter and receiver.

[2] CDMA Transmitter:
    - Takes input data bits (1-bit at a time).
    - Multiplies (XORs) the input bit with the LFSR output to spread the signal.
    - Output is a wider bit sequence representing the spread signal.

[3] CDMA Receiver:
    - Accepts the spread data stream as input.
    - Uses the same LFSR sequence to despread the signal.
    - Recovers the original input data by correlating with the spreading code.

[4] Testbenches:
    - Provide input stimulus for both transmitter and receiver.
    - Display output in waveform or simulation logs.
    - Validate correctness of the design.

--------------------------------------------------------------------------------
HOW TO RUN SIMULATION
--------------------------------------------------------------------------------

You can use any Verilog simulator (Icarus Verilog, ModelSim, Vivado, etc.)

Example using Icarus Verilog:
> iverilog -o tb_tx tb_cdma_transmitter.v cdma_transmitter.v lfsr_6bit.v
> vvp tb_tx

> iverilog -o tb_rx tb_cdma_receiver.v cdma_receiver.v lfsr_6bit.v
> vvp tb_rx

Use GTKWave or Vivado for waveform analysis.

--------------------------------------------------------------------------------
FPGA IMPLEMENTATION NOTES
--------------------------------------------------------------------------------

- The design is fully synthesizable.
- You can implement the design using Xilinx Vivado or Intel Quartus.
- To test on hardware, you will need to connect I/O pins for data input/output.
- The LFSR can be seeded via a reset value to ensure synchronization.

--------------------------------------------------------------------------------
FUTURE IMPROVEMENTS
--------------------------------------------------------------------------------

- Extend to multi-user CDMA using orthogonal codes.
- Add synchronization support (e.g., start-of-frame detection).
- Support higher-order modulation schemes (BPSK, QPSK).
- Measure Bit Error Rate (BER) under noisy conditions.
- Integrate with RISC-V CPU for software-driven communication control.

--------------------------------------------------------------------------------
CREDITS
--------------------------------------------------------------------------------

Developed by: Soujit Chel
Undergraduate Student, Dept. of Electronics & Communication Engineering
Project Title: FPGA Implementation of DSSS-CDMA Communication System

This project is part of an academic initiative to explore secure and robust 
communication systems using hardware design methodologies.

--------------------------------------------------------------------------------
LICENSE
--------------------------------------------------------------------------------

This project is open-sourced under the MIT License. You are free to modify,
distribute, and use it in your own research or development work.
