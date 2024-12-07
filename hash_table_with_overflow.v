`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Shema Thomas
// 
// Design Name: Hash Table with Overflow
// Module Name: hash_table_with_overflow
// Description: Synthesizable hash table with overflow handling using external memory.
// 
//////////////////////////////////////////////////////////////////////////////////

module hash_table_with_overflow 
#(
    parameter WIDTH = 32,        // Key width
    parameter TABLE_SIZE = 1024, // Hash table size
    parameter VALUE_SIZE = 32    // Value width
)
(
    input clk,
    input reset,
    input [1:0] operation,                 // 00: Lookup, 01: Insert, 10: Delete
    input [WIDTH-1:0] key,                 // Key for the operation
    input [VALUE_SIZE-1:0] value_in,       // Value for insertion
    output reg [VALUE_SIZE-1:0] value_out, // Output value for lookup
    output reg hit,                        // Hit flag for lookup
    output reg success                     // Success flag for operations
);

    // On-chip hash table storage
    reg [WIDTH-1:0] keys [0:TABLE_SIZE-1];       // Key storage
    reg [VALUE_SIZE-1:0] values [0:TABLE_SIZE-1];// Value storage
    reg valid [0:TABLE_SIZE-1];                  // Valid bit to indicate presence
    reg overflow [0:TABLE_SIZE-1];               // Overflow bit to indicate external memory use

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

    // Sequential logic for hash table operations
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset all entries in the hash table
            for (i = 0; i < TABLE_SIZE; i = i + 1) begin
                valid[i] <= 0;
                overflow[i] <= 0;
            end
            success <= 0;
            hit <= 0;
        end else begin
            case (operation)
                2'b00: begin // Lookup
                    hit <= 0; // Default to no hit
                    value_out <= 0; // Default to zero
                    if (valid[hash_index] && keys[hash_index] == key) begin
                        value_out <= values[hash_index];
                        hit <= 1;
                    end else if (overflow[hash_index]) begin
                        hit <= ext_hit;
                        value_out <= ext_value_out;
                    end
                end
                2'b01: begin // Insert
                    success <= 0; // Default to failure
                    if (!valid[hash_index]) begin
                        // Insert into the on-chip hash table
                        keys[hash_index] <= key;
                        values[hash_index] <= value_in;
                        valid[hash_index] <= 1;
                        success <= 1;
                    end else if (!overflow[hash_index]) begin
                        // Overflow occurs, use external memory
                        overflow[hash_index] <= 1;
                        success <= ext_success;
                    end else begin
                        // If already in overflow, delegate to external memory
                        success <= ext_success;
                    end
                end
                2'b10: begin // Delete
                    success <= 0; // Default to failure
                    if (valid[hash_index] && keys[hash_index] == key) begin
                        valid[hash_index] <= 0; // Mark entry as invalid
                        success <= 1;
                    end else if (overflow[hash_index]) begin
                        success <= ext_success;
                        if (!ext_success) begin
                            overflow[hash_index] <= 0; // Clear overflow bit if delete fails in external memory
                        end
                    end
                end
                default: success <= 0; // Default case for unsupported operations
            endcase
        end
    end
endmodule
