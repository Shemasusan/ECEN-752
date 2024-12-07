`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/27/2024 09:45:24 AM
// Design Name: 
// Module Name: ssd_sim
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// Synthesisable version of SSD simulation module
// Dependencies: 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ssd_sim #(parameter VALUE_SIZE = 32, DATA_SIZE = 512, SSD_CAPACITY = 32) (
    input clk,
    input reset,
    input write, // Signal to write to SSD
    input delete, // Signal to delete from SSD
    input read, // Signal to read from SSD
    input [DATA_SIZE-1:0] data_in, // Data to write
    input [VALUE_SIZE-1:0] addr_in, // Address for delete or read
    output reg [VALUE_SIZE-1:0] addr_out, // Address assigned for written data
    output reg [DATA_SIZE-1:0] data_out, // Data read from the SSD
    output reg ready, // SSD ready signal
    output reg done // Indicates write/delete/read operation completion
);
    reg [DATA_SIZE-1:0] ssd_mem [0:SSD_CAPACITY-1]; // Simulated SSD memory
    reg valid [0:SSD_CAPACITY-1]; // Valid bit for each address
    integer i;
    reg [VALUE_SIZE-1:0] next_free_addr; // Track the next available address
    reg writing, deleting, reading; // Flags to indicate write, delete, and read states

    // Sequential block triggered by clock or reset
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset SSD state
            for (i = 0; i < SSD_CAPACITY; i = i + 1) begin
                valid[i] <= 0;
            end
            ready <= 1; // SSD is ready to accept operations
            done <= 0; // No operation in progress
            writing <= 0; // No operation in progress
            deleting <= 0; // No operation in progress
            reading <= 0; // No operation in progress
            next_free_addr <= 0; // Start scanning from address 0
            data_out <= 0; // Clear data output
        end else begin
            // Default to not done
            done <= 0;

            // Write Operation
            if (write && ready && !writing) begin
                // Start write operation
                if (next_free_addr < SSD_CAPACITY) begin
                    writing <= 1; // Indicate we are writing
                    ready <= 0; // SSD is busy
                    ssd_mem[next_free_addr] <= data_in; // Write data to SSD
                    valid[next_free_addr] <= 1; // Mark address as valid
                    addr_out <= next_free_addr; // Assign address to addr_out
                    next_free_addr <= next_free_addr + 1; // Move to the next address
                    done <= 1; // Write operation complete
                    writing <= 0; // End write operation
                end else begin
                    // SSD is full, reject the write request
                    done <= 0; // Indicate operation could not be completed
                end
                ready <= 1; // SSD is ready again
            end

            // Delete Operation
            if (delete && ready && !deleting) begin
                deleting <= 1; // Start delete operation
                ready <= 0; // SSD is busy
                if (valid[addr_in]) begin
                    valid[addr_in] <= 0; // Mark address as invalid
                    ssd_mem[addr_in] <= {DATA_SIZE{1'b0}}; // Clear data (optional)
                    done <= 1; // Indicate delete operation is complete
                end else begin
                    done <= 1; // Indicate operation handled (though no action taken)
                end
                deleting <= 0; // End delete operation
                ready <= 1; // SSD is ready again
            end

            // Read Operation
            if (read && ready && !reading) begin
                reading <= 1; // Start read operation
                ready <= 0; // SSD is busy
                if (valid[addr_in]) begin
                    data_out <= ssd_mem[addr_in]; // Read the data from SSD
                    done <= 1; // Indicate read operation is complete
                end else begin
                    data_out <= {DATA_SIZE{1'bx}}; // Return invalid data for invalid address
                    done <= 1; // Still set done to indicate the operation is complete
                end
                reading <= 0; // End read operation
                ready <= 1; // SSD is ready again
            end
        end
    end
endmodule
