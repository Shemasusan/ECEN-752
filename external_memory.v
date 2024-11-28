`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/21/2024 01:26:10 PM
// Design Name: 
// Module Name: external_memory
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


module external_memory #(parameter WIDTH = 32, VALUE_SIZE = 32, EXT_MEM_SIZE = 2048) (
    input clk, 
    input reset,
    input [1:0] operation, // 00: Lookup, 01: Insert, 10: Delete
    input [WIDTH-1:0] key,
    input [VALUE_SIZE-1:0] value_in,
    output reg [VALUE_SIZE-1:0] value_out,
    output reg hit, // Indicates if the key was found
    output reg success // Indicates operation success
);
    // Simulated external memory (key-value pairs)
    reg [WIDTH-1:0] ext_keys [0:EXT_MEM_SIZE-1];
    reg [VALUE_SIZE-1:0] ext_values [0:EXT_MEM_SIZE-1];
    reg valid [0:EXT_MEM_SIZE-1];

    integer i;
    reg done; // Added flag to stop further iterations

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < EXT_MEM_SIZE; i = i + 1) begin
                valid[i] <= 0;
            end
            hit <= 0;
            success <= 0;
        end else begin
            case (operation)
                2'b00: begin // Lookup
                    hit <= 0;
                    value_out <= 0; // Reset value_out to avoid stale values
                    done <= 0;
                    for (i = 0; i < EXT_MEM_SIZE; i = i + 1) begin
                        if (!done && valid[i] && ext_keys[i] == key) begin
                            value_out <= ext_values[i];
                            hit <= 1;
                            done <= 1; // Stop further iterations
                        end
                    end
                end
                2'b01: begin // Insert
                    success <= 0;
                    done <= 0;
                    for (i = 0; i < EXT_MEM_SIZE; i = i + 1) begin
                        if (!done && !valid[i]) begin
                            ext_keys[i] <= key;
                            ext_values[i] <= value_in;
                            valid[i] <= 1;
                            success <= 1;
                            done <= 1; // Stop further iterations
                        end
                    end
                end
                2'b10: begin // Delete
                    success <= 0;
                    done <= 0;
                    for (i = 0; i < EXT_MEM_SIZE; i = i + 1) begin
                        if (!done && valid[i] && ext_keys[i] == key) begin
                            valid[i] <= 0;
                            success <= 1;
                            done <= 1; // Stop further iterations
                        end
                    end
                end
                default: success <= 0;
            endcase
        end
    end
endmodule


