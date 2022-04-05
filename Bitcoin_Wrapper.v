`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// University: Carleton University
// Author: Christian Kamps
// 
// Create Date: 01/27/2022 04:18:33 PM
// Design Name: 
// Module Name: Bitcoin_Wrapper
// Project Name: Bitcoin Miner on a FPGA
// Target Devices: Virtex-7 VC707
// Tool Versions: Vivado 2021.1
// Description: Top file for SHA-256 implementation
// 
// Dependencies: N/A
// 
// Revision: 1
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

/*
Pseudo-code:
1. Wait for a valid block header data pulse
2. When a valid block header data pulse is detected:
    2.1 Reset the nonce value to 0
    2.2 Set the hashing state to the initial state
    2.3 Take 640 bit block header and format it into two 512 message blocks according to SHA256 standards
3. First hashing state:
    3.1 Load into the SHA256 module:
        - First message block as the input message
        - Default initial hashing values as the initial hashing value
    3.2 Enable the SHA256 module
    3.3 Enter the second hashing state
4. Second hashing state:
    4.1 When the SHA256 module has completed the first round of hashing:
        4.1.1 Load into the SHA256 module:
              - Second message block as the input message + nonce value
              - Output hash of the first message block as the initial hash values
        4.1.2 Enable the SHA256  module
        4.1.3 Enter the third hashing state
5. Third hashing state:
    5.1 When the SHA256 module has completed the second round of hashing:
        5.1.1 Load into the SHA256 module:
              - Output hash of the second round of hashing as the input message
              - Default initial hashing values as the initial hashing value
        5.1.2 Enable the SHA256  module
        5.1.3 Enter the fourth hashing state
6. Fourth hashing state:
    6.1 When the SHA256 module has completed the third round of hashing:
        6.1.1 If the output hash is less than the target value
              - Stop hashing until a new valid block header pulse is detected            - 
        6.1.2 If the output hash is greater than the target value:
              - Increase the nonce
              - Enter the second hashing state
*/

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////
// Module                                    //
///////////////////////////////////////////////

module Bitcoin_Wrapper(
    clk,                    // Input: Clock
    Block_Header,           // Input: Block Header Data
    Block_Header_Valid,     // Input: Block Header Data Valid
    //Golden_Nonce,         // Output: Validation Nonce
    Golden_Hash,            // Output: Validation Hash     
    Hash_Valid              // Output: Data Valid for Hash/Nonce
);

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////
// I/O                                       //
///////////////////////////////////////////////

// Inputs
input clk;                      // Clock Signal
input [639:0] Block_Header;     // 640-bit Block Header from Communication Module
input Block_Header_Valid;       // Data valid signal for Block Header from Communication Module

// Outputs
//output reg [31:0] Golden_Nonce;   // Validation Nonce 
output reg [255:0] Golden_Hash;     // Validation Hash     
output reg Hash_Valid;              // Data Valid for Hash/Nonce

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////
// Registers                                 //
///////////////////////////////////////////////

// Temporary Registers
reg [639:0] Block_Header_reg; 
reg [255:0] First_Block_Digest;

// FSM Registers:
reg [2:0] Hashing_State;   
reg [31:0] nonce;        
reg Hashing_Loop;

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////
// SHA-256                                   //
///////////////////////////////////////////////

// SHA-256 Module Registers
reg ready_to_hash;              // Enable Signal
reg [511:0] input_message;      // Input Message
reg [255:0] initial_hashes;     // Input Initialization Hash

// SHA-256 Module Wires
wire [255:0] digest;            // Output Hash aka Digest
wire Hashing_Done;              // Data Valid Signal

// SHA256 Module Instatiation
SHA_256_Top SHA_256_inst(
    .ready_to_hash(ready_to_hash),  // Input    : A *1 clock pulse* to enable the SHA256 Module
    .clk(clk),                      // Input    : Hashing Clock (May be a seperate clock than the communication clock)
    .input_message(input_message),  // Input    : 512-bit Input message to hash - Must be formatted correctly using the Padding module
    .initial_hashes(initial_hashes),// Input    : 256-bit Initial Hash values
    .digest(digest),                // Output   : Output Hash from the SHA256 module
    .Hashing_Done(Hashing_Done)     // Output   : Data valid signal for the digest (Output Hash) - *1 clock pulse* signal
);

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////
// FSM                                       //
///////////////////////////////////////////////

always@(posedge clk)
begin
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// FSM Reset/Initialize Condition:
// If the Block Header data is valid, reset the FSM to the initial state
if (Block_Header_Valid == 1)
    begin
    nonce <= 0;                         // Reset the nonce value to 0
    Hashing_State = 3'd1;               // Move to the first hashing state
    Block_Header_reg <= Block_Header;   // Load the block header input data into a working variable register
    Hashing_Loop <= 0;
    // SHA256 Inputs:
    ready_to_hash <= 0;
    input_message <= 512'b0;
    initial_hashes <= 256'b0;
    end
// Otherwise, loop through the FSM
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
else 
    begin
    case(Hashing_State)
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Default State
        // No hashing in this state
        // Dead state that requires a reset (Block_Header_Valid) pulse to start a new hashing process
        3'd0:
            begin
            Hash_Valid      <= 0;            
            ready_to_hash   <= 0; 
            input_message   <= 512'b0;
            initial_hashes  <= 256'b0;
            end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Hashing State 1
        // Sends the first Message Block, initial hash values, and the hashing enable signal
        3'd1:
            begin
            Hash_Valid      <= 0; 
            ready_to_hash   <= 1; 
            input_message   <= Block_Header_reg[639:128];
            initial_hashes  <= 256'h6a09e667bb67ae853c6ef372a54ff53a510e527f9b05688c1f83d9ab5be0cd19;
            Hashing_State   <= 3'd2;
            end 
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Hashing State 2
        // Disables the hashing enable and waits for the done signal
        // When Done signal is enabled, load the next message block into the input and load the output of the first message block into the initial hash values
        3'd2:
            begin    
            Hash_Valid <= 0;         
            // We can send the Hashing_Done signal a clock earlier because we read it a clock later
            if (Hashing_Done|Hashing_Loop)
                begin
                ready_to_hash <= 1; 
                input_message <= {Block_Header_reg[127:0]+nonce,384'h800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000280};
                if (Hashing_Loop)
                    begin
                    Hashing_Loop    <= 0;
                    initial_hashes  <= First_Block_Digest;
                    Hashing_State   <= 3'd2;
                    end
                else
                    begin
                    initial_hashes      <= digest;
                    First_Block_Digest  <= digest;
                    Hashing_State       <= 3'd3;
                    end
                end
            else
                begin
                ready_to_hash   <= 0; 
                input_message   <= 512'b0;
                initial_hashes  <= 256'b0;
                Hashing_State   <= 3'd2;
                end
            end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Hashing State 3 
        // Disables the hashing enable and waits for the done signal
        // When Done signal is enabled, load the output hash into the input and load the default hash values into the initial hash values
        3'd3:
            begin
            Hash_Valid <= 0; 
            if (Hashing_Done == 1)
                begin
                ready_to_hash   <= 1; 
                input_message   <= {digest, 256'h8000000000000000000000000000000000000000000000000000000000000100};
                initial_hashes  <= 256'h6a09e667bb67ae853c6ef372a54ff53a510e527f9b05688c1f83d9ab5be0cd19;
                Hashing_State   <= 3'd4;
                end
            else
                begin
                ready_to_hash   <= 0; 
                input_message   <= 512'b0;
                initial_hashes  <= 256'b0;
                Hashing_State   <= 3'd3;
                end
            end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // Hashing State 4:
        // Disables the hashing enable and waits for the done signal 
        // When Done signal is enabled, check if the output hash is lower than the target 
        // If the output hash is lower than the target, the system has found the nonce that generates a valid block, and we stop hashing
        // If the output hash is greater than the target, the system restarts the hashing process with an incremented nonce value
        3'd4:
            begin
            if (Hashing_Done == 1)
                begin
                // If the digest is lower than the target, return to the default state for next block header
                if ((digest[17:0] == 0) & ({digest[19:18],digest[21:20],digest[23:22]} < 24'h0a3773))
                    begin
                    Hash_Valid      <= 1;                     
                    Golden_Hash     <= digest; 
                    Hashing_State   <= 3'd0;
                    //Golden_Nonce <= nonce;
                    end
                else
                    begin
                    Hash_Valid      <= 0; 
                    ready_to_hash   <= 0; 
                    nonce           <= nonce + 1; // This only tracks the current nonce value
                    Hashing_Loop    <= 1;
                    Hashing_State   <= 3'd2;
                    end
                end
            else
                begin
                Hash_Valid      <= 0; 
                ready_to_hash   <= 0; 
                input_message   <= 512'b0;
                initial_hashes  <= 256'b0;
                Hashing_State   <= 3'd4;
                end  
            end 
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        default: Hashing_State = 3'd0; // Default State
    endcase
    end
end

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

endmodule
