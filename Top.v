`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/17/2022 07:15:39 AM
// Design Name: 
// Module Name: Top
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

module Top(
    sys_clk_p,  // Input: Positive Differential System Clock
    sys_clk_n,  // Input: Negative Differential System Clock
    RX_In,      // Input: UART Receiver
    TX_Out      // Output: UART Transmitter
);

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////
// System Clock                              //
///////////////////////////////////////////////

// Clocking Inputs
input sys_clk_p;    // System Positive Clock
input sys_clk_n;    // System Negative Clock

// Clocking Wires
wire clk;           // Implemented Clock 

// Clocking Instantiation
clk_wiz_0 inst(
    // Clock out ports  
    .clk_out1(clk),
    // Clock in ports
    .clk_in1_p(sys_clk_p),
    .clk_in1_n(sys_clk_n)
);
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////
// UART Receiver                             //
///////////////////////////////////////////////

// Receiver Instantiation Wires/Regs
input RX_In;        // RX Input
wire [7:0] RX_Out;  // Byte of data received
wire RX_Valid;      // Byte of data received is valid to use

// Receiver Instantiation   
UART_RX Receiver_inst(
    .clk(clk),              // Input: Clock
    .RX_In(RX_In),          // Input: Serial Bus Input
    .RX_Valid(RX_Valid),    // Output: Data Valid Signal for Reception
    .RX_Out(RX_Out)         // Output: Data Register for Byte Received
);

// Receiver FSM Registers
reg [10:0] Byte_Counter;       // Counts the number of bytes received for the block header
reg [639:0] RX_data;           // Block Header Data
reg Block_Header_Valid;        // Block Header Data Valid

// Training Sequence
parameter [31:0] Training_Sequence = 32'b01100001011000100110001101100100; // 'abcd' UTF-8 
parameter TS_BYTE_SIZE = 4;    // Training sequence byte size
reg [3:0] RX_State;            // State for Training Sequence FSM 
reg [6:0] TS_Index;            // Training sequence index

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////
// UART Transmitter                          //
///////////////////////////////////////////////

// Transmitter Instantiation Wires/Regs
reg TX_Enable;          // TX Enable signal
reg [7:0] TX_In_Reg;    // Byte of data to be sent
wire [7:0] TX_In;       // Byte of data to be sent
wire TX_Valid;          // TX has finished transmitting byte
output wire TX_Out;     // TX output

// Transmitter Instantiation   
UART_TX Transmitter_inst(
    .clk(clk),              // Input: Clock
    .TX_In(TX_In),          // Input: Data Register for Byte Transmission
    .TX_Enable(TX_Enable),  // Input: Transmission Enable Signal
    .TX_Out(TX_Out),        // Output: Serial Bus Output
    .TX_Valid(TX_Valid)     // Output: Data Valid Signal for Transmission
);

// Transmitter Assignments
assign TX_In = TX_In_Reg;   // Cannot instantiate input with a reg

// Transmission FSM Registers:
reg [255:0] TX_Data;        // Full Data register for TX data
reg [6:0] TX_Index;         // Index for sending data
wire Transmit_Enable;       // Enable Transmission
reg TX_State;               // TX State
//reg [31:0] Golden_Nonce;  // Validation Nonce
wire [255:0] Golden_Hash;   // Validation Hash

// Tranmission Parameters 
parameter BYTES_TO_SEND     = 32;   // Amount of bytes to send over TX
parameter BYTES_TO_RECEIVE  = 80;   // Amount of bytes to send over TX

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////
// Miner Module                              //
///////////////////////////////////////////////

Bitcoin_Wrapper Miner_inst(
    .clk(clk),                                  // Input: Clock
    .Block_Header(RX_data),                     // Input: Block Header Data
    .Block_Header_Valid(Block_Header_Valid),    // Input: Block Header Data Valid
    //.Golden_Nonce(Golden_Nonce),              // Output: Validation Nonce
    .Golden_Hash(Golden_Hash),                  // Output: Validation Hash
    .Hash_Valid(Transmit_Enable)                // Output: Data Valid for Hash/Nonce
);  

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////
// Transmission Protocol                     //
///////////////////////////////////////////////

always @ (posedge clk)
begin
case (TX_State)
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    1'b0: // Wait for transmit enable signal
        begin
        TX_Enable <= 0;     // Disable UART_TX module
        // If Transmission is enabled, change to state 1 and reset the TX_Index
        if (Transmit_Enable)
            begin
            TX_Data <= Golden_Hash;
            TX_Index <= BYTES_TO_SEND - 1; 
            TX_State <= 1;
            end
        // If transmission is not enabled, loop
        else 
            begin
            TX_State <= 0;
            end
        end 
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    1'b1: // Send (BYTES_TO_SEND) amount of bytes using the UART_TX module 
        begin
        TX_Enable <= 1;                                 // Enable TX Module   
        TX_In_Reg <= TX_Data[((TX_Index)*8) +: 8];      // Load Byte of Transmit_Data in reference to TX_Index      
        // After a byte has been sent:
        if (TX_Valid == 1)
            begin                           
            // If all bytes have been sent:  
            if (TX_Index == 0)
                begin
                TX_State <= 0;
                end
            // If more bytes need to be sent:
            else
                begin
                TX_Index <= TX_Index - 1; 
                TX_State <= 1;
                end
            end
        // While a byte is being sent:
        else
            begin
            TX_State <= 1;
            end
        end 
    default: TX_State <= 0;
endcase
end

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////
// Receiver Protocol                         //
///////////////////////////////////////////////

always @ (posedge clk)
begin
// If the data from the receiver is valid
if (RX_Valid == 1)
    begin        
    case(RX_State)
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Check for Training Sequence Recognition             
    4'd0: 
        begin
        Block_Header_Valid <= 0;
        Byte_Counter <= BYTES_TO_RECEIVE-1;
         // If the received data matched the training sequence
        if (RX_Out == Training_Sequence[((TS_Index)*8) +: 8])
            begin
            // If the several bytes of received data match the full training sequence, save received data
            if (TS_Index == 0)
                begin                
                RX_State <= 1;
                RX_data <= 0;
                end
            // If the training sequence has not been fully matched, decrease the index
            else
                begin
                TS_Index <= TS_Index - 1;
                RX_State <= 0;
                end        
            end
        // If the received data does no match the training sequenece, reset the training sequence index counter
        else
            begin
            TS_Index <= TS_BYTE_SIZE-1;
            RX_State <= 0;
            end
        end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Save received data 
    4'd1: 
        begin  
        TS_Index <= TS_BYTE_SIZE-1;
        RX_data[((Byte_Counter)*8) +: 8] <= RX_Out;            
        if (Byte_Counter == 0)
            begin
            Byte_Counter <= BYTES_TO_RECEIVE-1;
            Block_Header_Valid <= 1;
            RX_State <= 0;
            end
        else
            begin             
            Byte_Counter <= Byte_Counter - 1;
            Block_Header_Valid <= 0;
            RX_State <= 1;
            end
        end 
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    default: RX_State <= 0;
    endcase
    end
else 
    begin
    Block_Header_Valid <= 0;
    end
end

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

endmodule
