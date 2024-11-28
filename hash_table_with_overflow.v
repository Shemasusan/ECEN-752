`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/21/2024 01:24:14 PM
// Design Name: 
// Module Name: hash_table_with_overflow
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


module hash_table_with_overflow #(parameter WIDTH = 32, TABLE_SIZE = 1024, VALUE_SIZE = 32) (
    input clk,
    input reset,
    input [1:0] operation, // 00: Lookup, 01: Insert, 10: Delete
    input [WIDTH-1:0] key,
    input [VALUE_SIZE-1:0] value_in,
    output reg [VALUE_SIZE-1:0] value_out,
    output reg hit, // Indicates if the key was found
    output reg success // Indicates operation success
);
    // On-chip hash table
    reg [WIDTH-1:0] keys [0:TABLE_SIZE-1];
    reg [VALUE_SIZE-1:0] values [0:TABLE_SIZE-1];
    reg valid [0:TABLE_SIZE-1];
    reg overflow [0:TABLE_SIZE-1]; // Overflow bit for each bin

    // External memory interface
    wire ext_hit, ext_success;
    wire [VALUE_SIZE-1:0] ext_value_out;
    external_memory #(.WIDTH(WIDTH), .VALUE_SIZE(VALUE_SIZE)) ext_mem (
        .clk(clk),
        .reset(reset),
        .operation(operation),
        .key(key),
        .value_in(value_in),
        .value_out(ext_value_out),
        .hit(ext_hit),
        .success(ext_success)
    );

    // Hash function
    wire [$clog2(TABLE_SIZE)-1:0] hash_index;
    hash_function #(.WIDTH(WIDTH), .TABLE_SIZE(TABLE_SIZE)) hf (
        .key(key),
        .hash_index(hash_index)
    );

    integer i;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < TABLE_SIZE; i = i + 1) begin
                valid[i] <= 0;
                overflow[i] <= 0;
            end
            success <= 0;
            hit <= 0;
        end else begin
            case (operation)
                2'b00: begin // Lookup
                    if (valid[hash_index] && keys[hash_index] == key) begin
                        value_out <= values[hash_index];
                        hit <= 1;
                    end else if (overflow[hash_index]) begin
                        hit <= ext_hit;
                        value_out <= ext_value_out;
                    end else begin
                        hit <= 0;
                    end
                end
                2'b01: begin // Insert
                    if (!valid[hash_index]) begin
                        keys[hash_index] <= key;
                        values[hash_index] <= value_in;
                        valid[hash_index] <= 1;
                        success <= 1;
                    end else if (!overflow[hash_index]) begin
                        overflow[hash_index] <= 1;
                        success <= ext_success;
                    end else begin
                        success <= ext_success;
                    end
                end
                2'b10: begin // Delete
                    if (valid[hash_index] && keys[hash_index] == key) begin
                        valid[hash_index] <= 0;
                        success <= 1;
                    end else if (overflow[hash_index]) begin
                        success <= ext_success;
                        if (!ext_success) overflow[hash_index] <= 0;
                    end else begin
                        success <= 0;
                    end
                end
                default: success <= 0;
            endcase
        end
    end
endmodule
