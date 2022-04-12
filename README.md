<!-- Title -->
# Bitcoin Miner Implemented on an FPGA

<!-- Overview -->
## Overview
This project implements the necessary computational and transmission elements onto a FPGA to enable the Bitcoin mining algorithm. The Bitcoin mining algorithm is written in Verilog and sythesized using Vivado 2021. The aggregation of Bitcoin network data is accomplished through API requests using a Python application. 

<!-- Data Path -->
## Data Path
The data path of the project is given below:
1. Data from the Bitcoin Network is aggregated onto a Website.
2. Data from the Website is accessed via API requests via a Python application.
3. The Python application sends the relevant data to the FPGA via a UART connection.
4. The FPGA recieves the data, and implements the Bitcoin mining algorithm.
5. When the FPGA completes the Bitcoin mining algorithm, relevant data is returned to the Python application via the UART connection.
6. The Python application recieves the data from the FPGA and uploads the relevant data to the Bitcoin network. 

<!-- Contents -->
# Contents
<!-- Verilog Files  -->
## Verilog Files 
This project is composed of several Verilog modules which instantiate the communication between the FPGA and computer and Bitcoin mining algorithim.
* Top.v
  * Top level file that instantiates the transmission and receiver protocols for the UART connection
* UART_RX.v
  * UART receiver protocol
* UART_TX.v
  * UART transmitter protocol
* Merkle_Root_Hash.v
  * Merkle root hash generator
* SHA_256.v
  * Secure Hash 256 instantiation
* Bitcoin_Wrapper.v
  * Bitcoin mining protocol
<!-- Constraint File -->
## Constraint Files 
* constraint.xdc
  * Constraint file for setting up UART I/O connections and system clock I/O
<!-- IP Files -->
## IP Files 
* clk_wiz_0.xci
  * Clocking wizard Vivado IP that instantiates the application's clock from the system's differential clock
