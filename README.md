# VHDL HARDWARE UART

This repository contains a VHDL hardware UART that can be synthetized to communicate with an FPGA.

I personally developed this UART as an excercise and also included simple simulation test benches written in VHDL/Verilog and Modelsim/Questasim scripts to run such tests.

In this first version, crude TX and RX blocks has been developed without a parent entity or a register interface, those blocks are the bare minimum implementation and the baud rade should be hardwired by providing a clock frequency which is 8 times the wanted baud rate. I/O will also respect this clock frequency so interfacing blocks are needed to use those blocks with other circuits at higher frequency.

The folders are subdivided as follows:

|Folder | Content |
| --- | --- |
|src | VHDL source files |
|tb  | VHDL/Verilog test benches |
|sim | Simulation scripts (should be work directory) |

### RX BLOCK

The RX block datapath can be seen on the diagram below, it consists of a sample register, a majority voting block and two counters. Red arrows indicate I/O signals, the interface is quite simple: when a new data frame has been received, the STROBE signal is set high for a single clock cycle and the received data is valid on the DATA line for at least one clock cycle (in reality is valid until the first data bit of the next frame is sampled).

![RX block data path](diagrams/rx_datapath.svg)

Oversampling is hardwired to be 8x (and so as said above the clock should be 8 times the baud rate) and the data bit value is the result of a 3-samples majority voting at the signal center, the samples are shifted on the sampling register until the start condition is met (the sequence 110xxZZZ is read, where ZZZ means that the majority voting result of those three bits must be 0, see image below).

![Start condition and majority voting](diagrams/rx_start.svg)

The RX block flow chart is shown on the image below.

![RX block flow chart](diagrams/rx_flowchart.svg)

From the flow chart is immediate to extract the control unit state machine, the only difficult part is to consider that the actions are COMMANDED by each state and so will be executed at the next clock edge.

![RX block state machine](diagrams/rx_machine.svg)

All this is implemented on a single block src/rx_block.vhd

The test bench is tb/tb_rx_block.v while the simulation script is in sim/sim_rx_block.do

### TX BLOCK

The TX block has a similar implementation to the RX block, for simplicity it also has to be fed with the same clock cycle (transmission "oversampling" is 8x). The image below shows the datapath (I/O in red).

The interface is again quite simple: a NEW_DATA input should be set high to signal that new data is ready to be sent on the DATA input, the TX block responds with a pulse of one clock cycle on the STROBE output when it has loaded the data which from that moment can be changed. 

![TX block data path](diagrams/tx_datapath.svg)

The TX block flow chart is shown on the image below.

![TX block flow chart](diagrams/tx_flowchart.svg)

Again, it's immediate to extrapolate the state machine from the flow chart.

![TX block state machine](diagrams/tx_machine.svg)

The test bench is tb/tb_tx_block.v while the simulation script is in sim/sim_tx_block.do