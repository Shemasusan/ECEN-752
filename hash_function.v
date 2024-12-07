`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Shema Thomas
// 
// Design Name: Hash Function
// Module Name: hash_function
// Description: Synthesizable hash function using a modulo operation.
// 
//////////////////////////////////////////////////////////////////////////////////

module hash_function 
#(
    parameter WIDTH = 32,         // Key width
    parameter TABLE_SIZE = 1024   // Hash table size
)
(
    input [WIDTH-1:0] key,                      // Input key
    output reg [$clog2(TABLE_SIZE)-1:0] hash_index // Hash index output
);
    always @(*) begin
        // Compute the hash index using modulo operation
        hash_index = key % TABLE_SIZE;
    end
endmodule
