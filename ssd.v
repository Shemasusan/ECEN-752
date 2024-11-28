`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/27/2024 09:42:45 AM
// Design Name: 
// Module Name: ssd (hash table)
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


module hash_table #(
    parameter WIDTH = 32,       // Key width
    parameter TABLE_SIZE = 1024, // Number of entries in the hash table
    parameter VALUE_SIZE = 32,  // Value size (address to SSD)
    parameter DATA_SIZE = 512   // Data size for SSD
) (
    input clk,
    input reset,
    input [1:0] operation, // 00: Lookup, 01: Insert, 10: Delete
    input [WIDTH-1:0] key,
    input [DATA_SIZE-1:0] photo_data, // Data to write to SSD
    output reg [VALUE_SIZE-1:0] value_out, // Address read from SSD
    output reg hit,                       // Indicates if the key was found
    output reg success,                   // Indicates operation success
    output reg ssd_write,                 // Signal to write to SSD
    output reg ssd_delete,                // Signal to delete from SSD
    output reg [DATA_SIZE-1:0] ssd_data_out, // Data to write to SSD
    output reg [VALUE_SIZE-1:0] ssd_addr_out, // SSD address for write/delete
    input [DATA_SIZE-1:0] ssd_data_in,    // Data read from SSD
    input [VALUE_SIZE-1:0] ssd_addr_in,   // SSD address assigned for write
    input ssd_ready,                      // SSD ready signal
    input ssd_done                        // SSD operation done signal
);

    // Internal memory for key-value pairs
    reg [WIDTH-1:0] keys [0:TABLE_SIZE-1];
    reg [VALUE_SIZE-1:0] values [0:TABLE_SIZE-1];
    reg valid [0:TABLE_SIZE-1]; // Valid bit for each entry
    
    // Hash function output
    wire [$clog2(TABLE_SIZE)-1:0] hash_index;
    hash_function #(.WIDTH(WIDTH), .TABLE_SIZE(TABLE_SIZE)) hf (
        .key(key),
        .hash_index(hash_index)
    );

    // Internal state machine for SSD coordination
    typedef enum reg [1:0] {IDLE, WAIT_SSD} state_t;
    state_t state;

    // Temporary registers
    reg [1:0] operation_reg;
    reg [DATA_SIZE-1:0] photo_data_reg;
    reg [WIDTH-1:0] key_reg;

    integer i;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset all memory and state
            for (i = 0; i < TABLE_SIZE; i = i + 1) begin
                valid[i] <= 0;
            end
            success <= 0;
            hit <= 0;
            ssd_write <= 0;
            ssd_delete <= 0;
            ssd_data_out <= 0;
            ssd_addr_out <= 0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    // Default outputs
                    ssd_write <= 0;
                    ssd_delete <= 0;
                    success <= 0;
                    hit <= 0;

                    case (operation)
                        2'b00: begin // Lookup
                            if (valid[hash_index] && keys[hash_index] == key) begin
                                value_out <= values[hash_index];
                                ssd_addr_out <= values[hash_index];
                                if (ssd_ready) begin
                                    ssd_write <= 0;
                                    ssd_delete <= 0;
                                    hit <= 1;
                                    success <= 1;
                                end
                            end else begin
                                hit <= 0;
                            end
                        end

                        2'b01: begin // Insert
                            if (!valid[hash_index]) begin
                                // Valid bit not set; can insert
                                keys[hash_index] <= key;
                                ssd_data_out <= photo_data;
                                if (ssd_ready) begin
                                    ssd_write <= 1; // Start SSD write
                                    state <= WAIT_SSD;
                                    operation_reg <= 2'b01;
                                end
                            end else begin
                                success <= 0; // Key collision
                            end
                        end

                        2'b10: begin // Delete
                            if (valid[hash_index] && keys[hash_index] == key) begin
                                if (ssd_ready) begin
                                    valid[hash_index] <= 0; // Mark invalid
                                    ssd_delete <= 1;
                                    ssd_addr_out <= values[hash_index];
                                    state <= WAIT_SSD;
                                    operation_reg <= 2'b10;
                                end
                            end else begin
                                success <= 0; // Key not found
                            end
                        end

                        default: success <= 0;
                    endcase
                end

                WAIT_SSD: begin
                    if (ssd_done) begin
                        ssd_write <= 0;
                        ssd_delete <= 0;
                        if (operation_reg == 2'b01) begin // Insert
                            values[hash_index] <= ssd_addr_in; // Store SSD address
                            valid[hash_index] <= 1; // Mark as valid
                            success <= 1;
                        end else if (operation_reg == 2'b10) begin // Delete
                            success <= 1;
                        end
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule

