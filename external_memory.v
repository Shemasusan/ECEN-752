`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Shema Thomas
// 
// Design Name: External Memory
// Module Name: external_memory
// Description: Synthesizable external memory module with key-value operations.
// 
//////////////////////////////////////////////////////////////////////////////////

module external_memory 
#(
    parameter WIDTH = 32,         // Key width
    parameter VALUE_SIZE = 32,    // Value width
    parameter EXT_MEM_SIZE = 2048 // Memory size
)
(
    input clk, 
    input reset,
    input start,                // Start operation signal
    input [1:0] operation,      // 00: Lookup, 01: Insert, 10: Delete
    input [WIDTH-1:0] key,
    input [VALUE_SIZE-1:0] value_in,
    output reg [VALUE_SIZE-1:0] value_out,
    output reg hit,             // Indicates if the key was found
    output reg success          // Indicates operation success
);

    // Internal memory arrays (block RAM)
    reg [WIDTH-1:0] ext_keys [0:EXT_MEM_SIZE-1];
    reg [VALUE_SIZE-1:0] ext_values [0:EXT_MEM_SIZE-1];
    reg valid [0:EXT_MEM_SIZE-1];

    // Control signals
    reg [$clog2(EXT_MEM_SIZE):0] search_index; // Log2 size for indexing
    reg [WIDTH-1:0] found_index;              // Store found index
    reg searching;                            // Search in progress flag
    reg found;                                // Key found flag

    // Reset and initialization
    integer i;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Clear valid bits and reset control signals
            for (i = 0; i < EXT_MEM_SIZE; i = i + 1) begin
                valid[i] <= 0;
            end
            search_index <= 0;
            hit <= 0;
            success <= 0;
            searching <= 0;
            found <= 0;
        end
    end

    // Sequential operation logic
    always @(posedge clk) begin
        if (!reset) begin
            case (operation)
                2'b00: begin // Lookup
                    if (start && !searching) begin
                        // Initialize search
                        search_index <= 0;
                        hit <= 0;
                        value_out <= 0;
                        found <= 0;
                        searching <= 1;
                    end else if (searching) begin
                        // Perform search over clock cycles
                        if (search_index < EXT_MEM_SIZE) begin
                            if (valid[search_index] && ext_keys[search_index] == key) begin
                                value_out <= ext_values[search_index];
                                hit <= 1;
                                found <= 1;
                                searching <= 0; // End search
                            end
                            search_index <= search_index + 1;
                        end else begin
                            // End search if not found
                            searching <= 0;
                        end
                    end
                end

                2'b01: begin // Insert
                    if (start && !searching) begin
                        // Initialize search for empty slot
                        search_index <= 0;
                        success <= 0;
                        searching <= 1;
                    end else if (searching) begin
                        if (search_index < EXT_MEM_SIZE) begin
                            if (!valid[search_index]) begin
                                ext_keys[search_index] <= key;
                                ext_values[search_index] <= value_in;
                                valid[search_index] <= 1;
                                success <= 1;
                                searching <= 0; // End insertion
                            end
                            search_index <= search_index + 1;
                        end else begin
                            // End search if no empty slots available
                            searching <= 0;
                        end
                    end
                end

                2'b10: begin // Delete
                    if (start && !searching) begin
                        // Initialize search for key to delete
                        search_index <= 0;
                        success <= 0;
                        searching <= 1;
                    end else if (searching) begin
                        if (search_index < EXT_MEM_SIZE) begin
                            if (valid[search_index] && ext_keys[search_index] == key) begin
                                valid[search_index] <= 0; // Invalidate the entry
                                success <= 1;
                                searching <= 0; // End deletion
                            end
                            search_index <= search_index + 1;
                        end else begin
                            // End search if key not found
                            searching <= 0;
                        end
                    end
                end

                default: begin
                    success <= 0; // Invalid operation
                end
            endcase
        end
    end
endmodule
