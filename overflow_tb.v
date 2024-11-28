`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/21/2024 01:27:02 PM
// Design Name: 
// Module Name: overflow_tb
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


module tb_hash_table_with_overflow();
    // Parameters
    parameter WIDTH = 32;
    parameter TABLE_SIZE = 16;
    parameter VALUE_SIZE = 32;

    // Inputs
    reg clk, reset;
    reg [1:0] operation;
    reg [WIDTH-1:0] key, value_in;

    // Outputs
    wire [VALUE_SIZE-1:0] value_out;
    wire hit, success;
    integer i;
    // Instantiate the module
    hash_table_with_overflow #(.WIDTH(WIDTH), .TABLE_SIZE(TABLE_SIZE), .VALUE_SIZE(VALUE_SIZE)) uut (
        .clk(clk),
        .reset(reset),
        .operation(operation),
        .key(key),
        .value_in(value_in),
        .value_out(value_out),
        .hit(hit),
        .success(success)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 10 ns clock period

    // Test sequence
    initial begin
        // Testbench Initialization
        $display("Starting Testbench...");
        reset = 1; #10; reset = 0; // Apply reset

        // Insert operations
        $display("Testing Insertions...");
        test_insert(32'h0001, 32'hAAAA); // Insert key=1, value=0xAAAA
        test_insert(32'h0002, 32'hBBBB); // Insert key=2, value=0xBBBB
        test_insert(32'h0003, 32'hCCCC); // Insert key=3, value=0xCCCC
        test_insert(32'h0004, 32'hDDDD); // Insert key=4, value=0xDDDD

        // Fill up on-chip memory and test overflow handling
        
        for (i = 0; i < TABLE_SIZE; i=i+1) begin
            test_insert(i, i * 16); // Insert into all on-chip bins
        end
        test_insert(32'h1000, 32'h1234); // Overflow into external memory

        // Lookup operations
        $display("Testing Lookups...");
        test_lookup(32'h0001); // Lookup key=1
        test_lookup(32'h0002); // Lookup key=2
        test_lookup(32'h1000); // Lookup key from external memory

        // Delete operations
        $display("Testing Deletions...");
        test_delete(32'h0001); // Delete key=1
        test_lookup(32'h0001); // Verify deletion
        test_delete(32'h1000); // Delete key from external memory
        test_lookup(32'h1000); // Verify deletion from external memory

        // Lookup non-existent key
        $display("Testing Non-existent Key Lookup...");
        test_lookup(32'h9999); // Non-existent key

        $display("Testbench Completed!");
        $stop;
    end

    // Task for Insert Operation
    task test_insert(input [WIDTH-1:0] test_key, input [VALUE_SIZE-1:0] test_value);
        begin
            operation = 2'b01; key = test_key; value_in = test_value;
            @(posedge clk); #1;
            if (success) $display("Insert: Key=0x%0h, Value=0x%0h -> Success", test_key, test_value);
            else $display("Insert: Key=0x%0h, Value=0x%0h -> Failed", test_key, test_value);
        end
    endtask

    // Task for Lookup Operation
    task test_lookup(input [WIDTH-1:0] test_key);
        begin
            operation = 2'b00; key = test_key;
            @(posedge clk); #1;
            if (hit) $display("Lookup: Key=0x%0h -> Value=0x%0h (Found)", test_key, value_out);
            else $display("Lookup: Key=0x%0h -> Not Found", test_key);
        end
    endtask

    // Task for Delete Operation
    task test_delete(input [WIDTH-1:0] test_key);
        begin
            operation = 2'b10; key = test_key;
            @(posedge clk); #1;
            if (success) $display("Delete: Key=0x%0h -> Success", test_key);
            else $display("Delete: Key=0x%0h -> Failed", test_key);
        end
    endtask
endmodule
