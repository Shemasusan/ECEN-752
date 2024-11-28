`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/21/2024 12:14:05 PM
// Design Name: 
// Module Name: hash_function
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
//////////////////////////////////////////////////////////////////////////////////


module hash_function #(parameter WIDTH = 32, TABLE_SIZE = 1024) (
    input [WIDTH-1:0] key,
    output [$clog2(TABLE_SIZE)-1:0] hash_index
);
    assign hash_index = key % TABLE_SIZE; // Simple modulo operation
endmodule

