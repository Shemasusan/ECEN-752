`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/27/2024 11:46:38 AM
// Design Name: 
// Module Name: tb_hash_table
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Testbench for the hash_table module
// 
// Dependencies: hash_table.v
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//////////////////////////////////////////////////////////////////////////////////

module tb_hash_table;

    // Parameters
    parameter WIDTH = 32;
    parameter TABLE_SIZE = 16;
    parameter VALUE_SIZE = 32;
    
    // Testbench signals
    reg clk;
    reg reset;
    reg [1:0] operation;  // 00: Lookup, 01: Insert, 10: Delete
    reg [WIDTH-1:0] key;
    reg [VALUE_SIZE-1:0] value_in;
    wire [VALUE_SIZE-1:0] value_out;
    wire hit;
    wire success;

    // Instantiate DUT (Device Under Test)
    hash_table #(
        .WIDTH(WIDTH), 
        .TABLE_SIZE(TABLE_SIZE), 
        .VALUE_SIZE(VALUE_SIZE)
    ) dut (
        .clk(clk),
        .reset(reset),
        .operation(operation),
        .key(key),
        .value_in(value_in),
        .value_out(value_out),
        .hit(hit),
        .success(success)
    );

    // Clock Generation
    initial clk = 0;
    always #5 clk = ~clk; // Generate a 10ns clock period

    // Test Sequence
    initial begin
        // Initialization
        reset = 1;
        operation = 2'b00;
        key = 0;
        value_in = 0;

        #20;  // Wait 20ns for reset
        reset = 0; // Deassert reset
        
        // Test Case 1: Insert a key-value pair
        $display("\nStarting Test Case 1: Insert Operation");
        @(posedge clk);
        operation = 2'b01; // Insert operation
        key = 32'h01;      // Key = 1
        value_in = 32'hDEADBEEF; // Value = 0xDEADBEEF
        @(posedge clk);
        #1;
        if (success) 
            $display("Insert Success: Key=0x%0h, Value=0x%0h", key, value_in);
        else 
            $display("Insert Failed: Key=0x%0h", key);

        // Test Case 2: Lookup the inserted key
        $display("\nStarting Test Case 2: Lookup Operation");
        @(posedge clk);
        operation = 2'b00; // Lookup operation
        key = 32'h01;      // Lookup Key = 1
        @(posedge clk);
        #1;
        if (hit) 
            $display("Lookup Success: Key=0x%0h, Value=0x%0h", key, value_out);
        else 
            $display("Lookup Failed: Key=0x%0h", key);

        // Test Case 3: Delete the inserted key
        $display("\nStarting Test Case 3: Delete Operation");
        @(posedge clk);
        operation = 2'b10; // Delete operation
        key = 32'h01;      // Delete Key = 1
        @(posedge clk);
        #1;
        if (success) 
            $display("Delete Success: Key=0x%0h", key);
        else 
            $display("Delete Failed: Key=0x%0h", key);

        // Test Case 4: Verify deletion by looking up the deleted key
        $display("\nStarting Test Case 4: Lookup After Deletion");
        @(posedge clk);
        operation = 2'b00; // Lookup operation
        key = 32'h01;      // Lookup Key = 1
        @(posedge clk);
        #1;
        if (hit) 
            $display("Unexpected Lookup Success: Key=0x%0h, Value=0x%0h", key, value_out);
        else 
            $display("Correct Lookup Failure: Key=0x%0h not found", key);

        $display("\nTestbench completed successfully!");
        $stop; // End simulation
    end
endmodule
