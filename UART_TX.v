`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/07/2022 05:34:44 PM
// Design Name: 
// Module Name: UART_TX
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////
// Module                                    //
///////////////////////////////////////////////

module UART_TX(
    clk,        // Input: Clock
    TX_In,      // Input: Data Register for Byte Transmission
    TX_Enable,  // Input: Transmission Enable Signal
    TX_Out,     // Output: Serial Bus Output
    TX_Valid    // Output: Data Valid Signal for Transmission
);

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////
// State Parameter Definitions               //
///////////////////////////////////////////////

parameter IDLE      = 0;   // Idle state between transactions
parameter START_BIT = 1;   // Start bit
parameter DATA_BIT  = 2;   // Transmission data
parameter STOP_BIT  = 3;   // Stop bit

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////
// Clocking Parameter Definitions            //
///////////////////////////////////////////////

parameter SYS_clk_FREQUENCY = 50000000;     // System Clock Frequency
parameter BAUD_RATE         = 9600;         // UART Baud Rate
parameter clkS_PER_BIT      = 5208;         // Clock Cycles per Bit-Length  = (System Clock Frequency)/(UART Baud Rate)

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////
// I/O                                       //
///////////////////////////////////////////////

// Inputs
input clk;              // Clock signal
input [7:0] TX_In;      // Input data
input TX_Enable;        // Input enable

// Outputs
output reg TX_Out;      // Serial Tx Output
output reg TX_Valid;     // Transmisstion Completion Signal (Active-high)

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////
// Registers                                 //
///////////////////////////////////////////////

// Index/Counter Registers
reg [31:0] clk_count;       // Counter for clock cycles within a single bit transmission
reg [3:0] TX_data_index;    // Index of current bit transmitted

// State Registers
reg [7:0] TX_Data;          // Data register for TX data
reg [1:0] state;            // Current State of FSM

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////
// FSM                                       //
///////////////////////////////////////////////

always @ (posedge clk)
begin
    case (state)
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        IDLE: 
            begin
            TX_Out <= 1'b1;         // Default high transmission bus
            TX_Valid <= 1'b0;       // Data-valid signal is low
            clk_count <= 3'd0;      // Clock count is 0
            TX_data_index <= 3'd0;  // Transmission index is 0
            // Check for transmission enable
            if (TX_Enable == 1'b1) 
                begin                
                state <= START_BIT; 
                TX_Data <= TX_In;   // Load input data into temporary register
                end
            else
                begin
                state <= IDLE;
                TX_Data <= 8'd0;
                end
            end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        START_BIT: 
            // Send the start bit
            begin
            TX_Out <= 1'b0;
            // If the start bit has been sent for one bit length
            if (clk_count == clkS_PER_BIT-1)
                begin
                clk_count <= 0;
                state <= DATA_BIT;
                end
            // If the start bit has not been sent for one bit length
            else
                begin
                clk_count <= clk_count + 1;
                state <= START_BIT;
                end
            end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        DATA_BIT: 
            // Send 8 data bits
            begin
            TX_Out <= TX_Data[TX_data_index];
            // If a bit has been transmitted for one bit length
            if (clk_count == clkS_PER_BIT-1)
                begin
                clk_count <= 0;
                // If all 8 bits have been sent
                if (TX_data_index == 4'd7)
                    begin
                    TX_data_index <= 4'd0;
                    state <= STOP_BIT;                    
                    TX_Valid <= 1'b1;        // Active-high signal is high
                    end
                // If less than 8 bits have been sent
                else
                    begin                        
                    TX_data_index <= TX_data_index + 1;
                    state <= DATA_BIT;
                    end
                end
            else
                begin
                clk_count <= clk_count + 1;
                state <= DATA_BIT;
                end
            end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        STOP_BIT: 
            // Send stop bit            
            begin
            TX_Valid <= 1'b0;       // Data-valid signal is low
            TX_Out <= 1'b1;         // Default high bus
            TX_data_index <= 3'd0;  // Transmission index is 0
            // If the stop bit has been sent for one bit length
            if (clk_count == clkS_PER_BIT-1)
                begin
                clk_count <= 0;
                state <= IDLE;                
                end
            // If the start bit has not been sent for one bit length
            else
                begin
                clk_count <= clk_count + 1;
                state <= STOP_BIT;
                end
            end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        default: state <= IDLE; 
    endcase
end

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

endmodule
