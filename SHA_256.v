`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// University: Carleton University
// Author: Christian Kamps
// 
// Create Date: 10/21/2021 11:21:22 PM
// Design Name: 
// Module Name: SHA_256_Top
// Project Name: Bitcoin Miner on a FPGA
// Target Devices: Virtex-7 VC707
// Tool Versions: Vivado 2021.1
// Description: SHA-256 implementation
// 
// Dependencies: N/A
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Define 32 bit WORDs based on 'x'
`define IDX(x) (((x)+1)*(32)-1):((x)*(32))

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////
// Module                                    //
///////////////////////////////////////////////

module SHA_256_Top (
    ready_to_hash,      // Input    : A *1 clock pulse* to enable the SHA256 Module
    clk,                // Input    : Hashing Clock (May be a seperate clock than the communication clock)
    input_message,      // Input    : 512-bit Input message to hash - Must be formatted correctly using the Padding module
    initial_hashes,     // Input    : 256-bit Initial Hash values
    digest,             // Output   : Output Hash from the SHA256 module
    Hashing_Done        // Output   : Data valid signal for the digest (Output Hash) - *1 clock pulse* signal
);

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////
// I/O                                       //
///////////////////////////////////////////////

// Inputs
input ready_to_hash;            // Enable Signal
input clk;                      // System Clock   
input [511:0] input_message;    // Input message 
input [255:0] initial_hashes;   // Initial Hash Values (8 hashes of 32-bit size)

// Outputs
output reg [255:0] digest;      // Output Hash termed Digest
output reg Hashing_Done;        // Done Signal 

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////
// Registers                                 //
///////////////////////////////////////////////

reg [31:0] a, b, c, d, e, f, g, h;          // Working variable registers
reg [31:0] h1, h2, h3, h4, h5, h6, h7, h8;  // Hash registers
reg [511:0] W;                              // Message Schedule
reg [7:0] t;                                // Hash State
reg [31:0] k;                               // Current Fractional Prime

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////
// Functions                                 //
///////////////////////////////////////////////

// Choice Function
function [31:0] ch_f;
    input [31:0] x,y,z;
    ch_f = (x & y) ^ (~x & z);
endfunction

// Majority Function
function [31:0] maj_f;
    input [31:0] x,y,z;
    maj_f = (x & y) ^ (x & z) ^ (y & z);
endfunction

// Sigma0 Function
function [31:0] sigma0_f;
    input [31:0] x;
    sigma0_f = {x[6:0],x[31:7]} ^ {x[17:0],x[31:18]} ^ (x >> 3);
endfunction

// Sigma1 Function
function [31:0] sigma1_f;
    input [31:0] x;
    sigma1_f = {x[16:0],x[31:17]} ^ {x[18:0],x[31:19]} ^ (x >> 10);
endfunction

// Uppercase Simga0 (Sum sign) Function
function [31:0] sum0_f;
    input [31:0] x;
    sum0_f = {x[1:0],x[31:2]} ^ {x[12:0],x[31:13]} ^ {x[21:0],x[31:22]};
endfunction

// Uppercase Simga1 (Sum sign) Function
function [31:0] sum1_f;
    input [31:0] x;
    sum1_f = {x[5:0],x[31:6]} ^ {x[10:0],x[31:11]} ^ {x[24:0],x[31:25]};
endfunction

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////
// Parameters                                //
///////////////////////////////////////////////

// Initial Hash Values (8 hashes of 32-bit size)
parameter [255:0] default_initial_hashes = {32'h5be0cd19, 32'h1f83d9ab, 32'h9b05688c, 32'h510e527f, 32'ha54ff53a, 32'h3c6ef372, 32'hbb67ae85, 32'h6a09e667};

// Irrational Constants (64 irrational constant 32-bit IDXs)
parameter [2047:0] ks =     {32'hc67178f2, 32'hbef9a3f7, 32'ha4506ceb, 32'h90befffa, 32'h8cc70208, 32'h84c87814, 32'h78a5636f, 32'h748f82ee, 
                             32'h682e6ff3, 32'h5b9cca4f, 32'h4ed8aa4a, 32'h391c0cb3, 32'h34b0bcb5, 32'h2748774c, 32'h1e376c08, 32'h19a4c116, 
                             32'h106aa070, 32'hf40e3585, 32'hd6990624, 32'hd192e819, 32'hc76c51a3, 32'hc24b8b70, 32'ha81a664b, 32'ha2bfe8a1, 
                             32'h92722c85, 32'h81c2c92e, 32'h766a0abb, 32'h650a7354, 32'h53380d13, 32'h4d2c6dfc, 32'h2e1b2138, 32'h27b70a85, 
                             32'h14292967, 32'h06ca6351, 32'hd5a79147, 32'hc6e00bf3, 32'hbf597fc7, 32'hb00327c8, 32'ha831c66d, 32'h983e5152, 
                             32'h76f988da, 32'h5cb0a9dc, 32'h4a7484aa, 32'h2de92c6f, 32'h240ca1cc, 32'h0fc19dc6, 32'hefbe4786, 32'he49b69c1,
                             32'hc19bf174, 32'h9bdc06a7, 32'h80deb1fe, 32'h72be5d74, 32'h550c7dc3, 32'h243185be, 32'h12835b01, 32'hd807aa98,
                             32'hab1c5ed5, 32'h923f82a4, 32'h59f111f1, 32'h3956c25b, 32'he9b5dba5, 32'hb5c0fbcf, 32'h71374491, 32'h428a2f98};

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////
// Wires                                     //
///////////////////////////////////////////////
        
wire [31:0] ch, maj, sigma0, sigma1, sum0, sum1, t1, t2, next_W;

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////
// Assignments                               //
///////////////////////////////////////////////

assign ch       = ch_f(e,f,g);
assign maj      = maj_f(a,b,c);
assign sigma0   = sigma0_f( W[`IDX(14)] );
assign sigma1   = sigma1_f( W[`IDX(1)] );
assign sum0     = sum0_f(a);
assign sum1     = sum1_f(e);
assign t1       = h + sum1 + ch + k + W[`IDX(15)];
assign t2       = sum0 + maj;
assign next_W   = sigma1 + W[`IDX(6)] + sigma0 + W[`IDX(15)];

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////
// FSM                                       //
///////////////////////////////////////////////

always @(posedge clk) 
    begin
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Reset/Enable Condition for Initialization
    if(ready_to_hash) 
        begin
        // Set initial k value
        k <= ks[`IDX(0)];
        // Put messgae block IDXs into the initial message schedule
        W[511:0] <=  input_message[511:0];
        // Input initial hash values into hash registers
        h1 <= initial_hashes[`IDX(7)];
        h2 <= initial_hashes[`IDX(6)];
        h3 <= initial_hashes[`IDX(5)];
        h4 <= initial_hashes[`IDX(4)];
        h5 <= initial_hashes[`IDX(3)];
        h6 <= initial_hashes[`IDX(2)];
        h7 <= initial_hashes[`IDX(1)];
        h8 <= initial_hashes[`IDX(0)];
        // Input hash values into working variables a-h to begin process
        a <= initial_hashes[`IDX(7)];
        b <= initial_hashes[`IDX(6)];
        c <= initial_hashes[`IDX(5)];
        d <= initial_hashes[`IDX(4)];
        e <= initial_hashes[`IDX(3)];
        f <= initial_hashes[`IDX(2)];
        g <= initial_hashes[`IDX(1)];
        h <= initial_hashes[`IDX(0)];
        t <= 1'b0;
        Hashing_Done <= 0;
        end 
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Begin SHA-256 Hash Computation
    else if (t < 7'd64) // For 0 < t < 63
        begin
        // Set k value
        k <= ks[((t+1)*32)+:32]; // x = (t+1)*32 , k <= ks[32+x:x], w[x +: y] == w[(x+y-1) : x ], indexed part select
        // Add in new message schedule
        W <= {W[479:0],next_W}; // Next W takes up most significant 32-bit IDX in W, Other 32-bit IDXs are shifted right (up)
        // Set new working variables
        a <= t1+t2;
        b <= a;
        c <= b;
        d <= c;
        e <= d+t1;
        f <= e;
        g <= f;			
        h <= g;					
        t <= t+1;
        Hashing_Done <= 0;
        end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Output State
    // When hasing is done add the final working variable to the intial hashes to get the digest
    else if (t == 7'd64) 
        begin
        digest[`IDX(7)] <= a + h1;
        digest[`IDX(6)] <= b + h2;
        digest[`IDX(5)] <= c + h3;
        digest[`IDX(4)] <= d + h4;
        digest[`IDX(3)] <= e + h5;
        digest[`IDX(2)] <= f + h6;
        digest[`IDX(1)] <= g + h7;
        digest[`IDX(0)] <= h + h8;
        Hashing_Done <= 1;
        t <= t+1;
        end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    else
        begin
        Hashing_Done <= 0;
        end
    end

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


endmodule
