`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/29/2022 10:28:29 PM
// Design Name: 
// Module Name: Merkle_Root_Hash
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

module Merkle_Root_Hash (
    TX_ID_input,        // Input    : Cocatenated 256-bit TX_ID Hashes from UART module
    total_TX_ID,        // Input    : Number of TX_ID Hashes 
    TX_ID_valid,        // Input    : Data valid signal for TX_ID Hashes
    clk,                // Input    : Clock
    merkle_root,        // Output   : Merkle Root Hash
    merkle_root_valid   // Output   : Data valid signal for Merkle Root Hash
);

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////
// I/O                                       //
///////////////////////////////////////////////

// Inputs
input [1023:0] TX_ID_input;     // TX_ID Hash input from UART module
input [7:0] total_TX_ID;        // Total number of TX_ID Hashes sent to FPGA
input TX_ID_valid;              // Data valid signal for TX_ID Hashes
input clk;                      // Clock

// Outputs
output reg [255:0] merkle_root;     // Merkle Root Hash
output reg merkle_root_valid;       // Data valid signal for output

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////
// Registers                                 //
///////////////////////////////////////////////

reg [7:0] hash_counter;         // Current amount of hashes for a specefic level in the merkle tree
reg parity;                     // Odd or even amount of Hashes for current merkle state
reg [1023:0] TX_ID_reg;         // Holds the TX_ID Hashes from UART
reg [1023:0] TX_ID_reg_temp;    // Holds the TX_ID Hashes from UART
reg [2:0] hash_state;           // FSM state 
reg [7:0] total_TX_ID_reg;      // Total number of TX_ID Hashes sent to FPGA 

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

// Hashing Parameter Definitions   
parameter INITIAL_HASHES  = 256'h6a09e667bb67ae853c6ef372a54ff53a510e527f9b05688c1f83d9ab5be0cd19;
parameter FIRST_HASH_MSG  = 512'h80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200;
parameter SECOND_HASH_MSG = 256'h8000000000000000000000000000000000000000000000000000000000000100;

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
if (TX_ID_valid == 1)
    begin
    // Reset FSM State:
    hash_state                  <= 0;
    // SHA256 Inputs:
    ready_to_hash               <= 0;                           // Disable the Hasher
    input_message               <= 512'b0;                      // Clear the input message
    initial_hashes              <= 256'b0;                      // Clear the initial hashes
    // Transaction Register/Indexing Setup:
    total_TX_ID_reg             <= {1'b0, total_TX_ID[7:1]};    // Save the new total amount of hashes per merkle row   
    hash_counter                <= {1'b0, total_TX_ID[7:1]};    // Integer division by 2 to determine hashes required per merkle row    
    TX_ID_reg                   <= TX_ID_input;                 // Save input TX_ID Hashes
    parity                      <= total_TX_ID[1];              // Save the parity of the hashing counter 
    TX_ID_reg_temp[4863:0]      <= 0;     
    // Outputs:
    merkle_root_valid           <= 0;                           // Data valid signal for output
    end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// FSM:
else 
    begin
    case(hash_state)
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // State 0 - Load Concatenated Transactions 
        3'd0:
            begin              
            // If this is the last hash of the row, and there is only one hash left, concatenate it with itself         
            if ((parity == 1) & (hash_counter == 0))
                begin
                input_message   <= {TX_ID_reg[255:0],TX_ID_reg[255:0]};       // Concatenate the last hash with itself
                end
            else
                begin
                input_message   <= TX_ID_reg[((hash_counter-1)*512) +: 512];    // Concatenate two 256-bit TX_ID Hashes [((TX_ID_Index)*512+512-1):((TX_ID_Index)*512)]          
                end
            initial_hashes      <= INITIAL_HASHES;                              // Send the default initial hashes to the hasher   
            ready_to_hash       <= 1;                                           // Send hashing enable signal
            hash_state          <= 3'd1;                                        // Go to next state      
            merkle_root_valid   <= 0;                                           // Disable data valid signal for output  
            end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // State 1 - First Hash Done - Load Second Hash
        3'd1:
            begin            
            merkle_root_valid   <= 0;               // Disable data valid signal for output
            // When First Hash Done:
            if (Hashing_Done)
                begin
                input_message   <= FIRST_HASH_MSG;  // 1 - 0 padding - 0x200 = 512
                initial_hashes  <= digest;          // Use the output of the hasher as the initial hashes  
                ready_to_hash   <= 1;               // Send hashing enable signal
                hash_state      <= 3'd2;            // Go to next state        
                end
            // While First Hash Calculating:
            else
                begin
                ready_to_hash   <= 0; 
                input_message   <= 512'b0;
                initial_hashes  <= 256'b0;
                hash_state      <= 3'd1;
                end
            end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // State 2 - Second Hash Done - Load Third Hash
        3'd2:
            begin            
            merkle_root_valid   <= 0;               // Disable data valid signal for output
            // When Second Hash Done:
            if (Hashing_Done)
                begin
                input_message   <= {digest, SECOND_HASH_MSG};   // Load digest + padded message
                initial_hashes  <= INITIAL_HASHES;              // Initial hashes  
                ready_to_hash   <= 1;                           // Send hashing enable signal
                hash_state      <= 3'd3;                        // Go to next state        
                end
            // While Second Hash Calculating:
            else
                begin
                ready_to_hash   <= 0; 
                input_message   <= 512'b0;
                initial_hashes  <= 256'b0;
                hash_state      <= 3'd2;
                end
            end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // State 3 - Third Hash Done - Save Hash
        3'd3:
            begin            
            // When Third Hash Done:
            if (Hashing_Done)
                begin
                // If we have completed all hashes for a row in the merkle tree
                if (hash_counter == 1)
                    begin                        
                    // If we have completed every hash
                    if (total_TX_ID_reg == 1)
                        begin
                        merkle_root         <= digest;  // Save the output hash
                        merkle_root_valid   <= 1;       // Enable the merkle root valid signal
                        hash_state          <= 3'd4;    // Go to a dead state to wait for next enable
                        end
                    // If we have more rows to hash
                    else
                        begin  
                        merkle_root_valid       <= 0;                               // Disable the merkle root valid signal
                        total_TX_ID_reg         <= {1'b0, total_TX_ID_reg[7:1]};    // Save the new total amount of hashes per merkle row   
                        hash_counter            <= {1'b0, total_TX_ID_reg[7:1]};    // Integer division by 2 to determine hashes required per merkle row                            
                        TX_ID_reg_temp          <= 0;                         
                        TX_ID_reg[((total_TX_ID_reg-1)*256) +: 256] <= TX_ID_reg_temp[((total_TX_ID_reg-1)*256) +: 256];
                        TX_ID_reg[255:0]        <= digest; 
                        row_count               <= row_count -1;                        
                        parity                  <= total_TX_ID_reg[1];              // Save the parity of the hashing counter for the next row   
                        hash_state              <= 3'd0;                            // Move to the first hashing state    
                        end
                    end
                // If we have more hashes in the row to complete
                else
                    begin
                    TX_ID_reg_temp[((hash_counter-1)*256) +: 256]      <= digest;  // Save the digest
                    merkle_root_valid   <= 0;                   // Disable the merkle root valid signal
                    hash_counter        <= hash_counter - 1;    // Decrease the hash counter to change the indexing in the first hash roun
                    hash_state          <= 3'd0;                // Go to the first hash round
                    end
                end
            // While Third Hash Calculating:
            else
                begin
                merkle_root_valid   <= 0;                   
                ready_to_hash       <= 0; 
                input_message       <= 512'b0;
                initial_hashes      <= 256'b0;
                hash_state          <= 3'd3;
                end
            end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        // State 4 - Dead/Default State - Wait for Reset
        3'd4:
            begin            
            merkle_root_valid   <= 0;               
            ready_to_hash       <= 0; 
            input_message       <= 512'b0;
            initial_hashes      <= 256'b0;
            hash_state          <= 3'd4;
            end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        default: hash_state = 3'd4; // Default State
    endcase
    end
end

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

endmodule
