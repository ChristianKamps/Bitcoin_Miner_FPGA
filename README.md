<!-- Title -->
# Bitcoin Miner Implemented on an FPGA

<!-- Overview -->
## Overview
This project implements the necessary computational and transmission elements onto a FPGA to enable the Bitcoin mining algorithm. The Bitcoin mining algorithm is written in Verilog and sythesized using Vivado 2021. The aggregation of Bitcoin network data is accomplished through API requests using a Python application. 

**This project is unfinished.**
**A detailed low-level report is in progress.**

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
## Contents
This project is composed of two files:
* Technical_Report.pdf 
  * A detailed analysis and description of the designed system in MATLAB
* Digital_Communications_Simulation_Christian_Kamps.m
  * The MATLAB file containing the design digital communciation system
