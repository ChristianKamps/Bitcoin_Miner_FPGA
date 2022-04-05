`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/03/2022 08:14:24 AM
// Design Name: 
// Module Name: UART_RX
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

module UART_RX(
    clk,        // Input: Clock
    RX_In,      // Input: Serial Bus Input
    RX_Valid,   // Output: Data Valid Signal for Reception
    RX_Out      // Output: Data Register for Byte Received
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
parameter MIDDLE_clk_PER_BIT= 2604;         // Middle of Bitlength = CLKS_PER_BIT/2

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////
// I/O                                       //
///////////////////////////////////////////////

// Inputs
input clk;      // Clock signal
input RX_In;    // Serial input 

// Outputs
output reg [7:0] RX_Out;    // Rx Output
output reg RX_Valid;        // RX has received the entire data frame

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////
// Registers                                 //
///////////////////////////////////////////////

// Index/Counter Registers
reg [31:0] clk_count;   // Counter for clock cycles within a single bit transmission
reg [3:0] RX_out_index; // Index of current bit transmitted

// State Registers
reg [1:0] state;        // Current State
reg [1:0] next_state;   // Next State

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////
// FSM                                       //
///////////////////////////////////////////////

always @ (posedge clk)
begin
    case (state)
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Check for active-low start bit
        IDLE:             
            begin
            RX_Valid <= 0;            
            clk_count <= 0;
            RX_out_index <= 3'd0;
            RX_Out <= 0;
            if (RX_In == 0) 
                begin                
                state <= START_BIT; 
                end
            else
                begin
                state <= IDLE;
                end
            end 
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Verify the start bit was not noise    
        START_BIT:             
            begin
            RX_Valid <= 0;
            RX_out_index <= 3'd0;            
            RX_Out <= 0;
            // If the receiver is reading the middle of the start bit
            if (clk_count == MIDDLE_clk_PER_BIT-1)
                begin
                clk_count <= 0;
                // If the middle bit of the stop bit is 0, change state to DATA_BIT
                if (RX_In == 1'b0) 
                    begin
                    state <= DATA_BIT;
                    end
                // If the middle bit of the stop bit is 1, change state to IDLE
                else               
                    begin
                    state <= IDLE;
                    end
                end
            // Increment the clock counter and remain in the current state
            else 
                begin
                clk_count <= clk_count + 1;
                state <= START_BIT; 
                end
            end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Index through the Byte to save the incoming data
        DATA_BIT: 
            begin
            RX_Valid <= 0;
            // If the receiver is reading the middle of the data bit
            if (clk_count == clkS_PER_BIT-1)
                begin
                clk_count <= 0;                     // Reset the clock counter
                RX_Out[RX_out_index] <= RX_In;      // Shift the RX input into the RX output register at the index value
                // If the receiver has read 8 data bits
                if (RX_out_index == 4'd7)
                    begin
                    RX_out_index <= 4'd0;   // Reset the index
                    state <= STOP_BIT;      // Change state to STOP_BIT
                    end
                // If the receiver has not read 8 data bits
                else
                    begin
                    RX_out_index <= RX_out_index + 1;   // Increment the index value 
                    state <= DATA_BIT;                  // Remain in the current state
                    end
                end
            // If the receiver is not reading the middle of the data bit
            else
                begin
                clk_count <= clk_count + 1; // Increment the clock counter
                state <= DATA_BIT;          // Reamin in current state
                end
            end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Wait until the end of the stop bit to return to IDLE
        STOP_BIT:             
            begin            
            RX_out_index <= 0;
            // If the clock counter has passed 1.5 bit lengths
            // The last data bit is read halfway through its bitlength, so we wait 1.5 clocks until the end of the stop bit
            if (clk_count == (clkS_PER_BIT+MIDDLE_clk_PER_BIT-1)) 
                begin
                RX_Valid <= 1'b1;   // Acknowledge to let the system know the RX output now that all data bits the RX_Out register
                clk_count <= 0;     // Reset clock counter
                state <= IDLE;      // Change state to IDLE
                end              
            // If the clock counter has not passed 1.5 bit lengths
            else
                begin
                RX_Valid <= 1'b0;
                clk_count <= clk_count + 1; // Increment the clock counter
                state <= STOP_BIT;          // Remain in the current state
                end
            end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        default: state <= IDLE; // Default state is IDLE
    endcase
end

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

endmodule
