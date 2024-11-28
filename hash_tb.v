`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/27/2024 11:46:38 AM
// Design Name: 
// Module Name: hash_tb
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


module tb_hash_table;
    parameter WIDTH = 32;
    parameter TABLE_SIZE = 16;
    parameter VALUE_SIZE = 32;
    parameter DATA_SIZE = 512;

    reg clk, reset;
    reg [1:0] operation;
    reg [WIDTH-1:0] key;
    reg [DATA_SIZE-1:0] photo_data;
    wire [VALUE_SIZE-1:0] value_out;
    wire hit, success;

    // Instantiate the hash_table module (without SSD interactions)
    hash_table #(
        .WIDTH(WIDTH), 
        .TABLE_SIZE(TABLE_SIZE), 
        .VALUE_SIZE(VALUE_SIZE), 
        .DATA_SIZE(DATA_SIZE)
    ) dut (
        .clk(clk),
        .reset(reset),
        .operation(operation),
        .key(key),
        .photo_data(photo_data),
        .value_out(value_out),
        .hit(hit),
        .success(success)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 10 ns clock period

    // Test sequence
    initial begin
        // Initialize
        reset = 1; key = 0; photo_data = 0; operation = 2'b00; // Lookup operation
        #10 reset = 0;

        // Test Insertions
        $display("\nTesting Insertions...");
        operation = 2'b01; key = 32'h0; photo_data = 512'hA0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0; // Insert a key-value pair
        @(posedge clk); #1;
        wait(success);
        $display("Insert: Key=0x%0h, Data=0x%0h -> Success", key, photo_data);

        // Test Lookups
        $display("\nTesting Lookups...");
        operation = 2'b00; // Lookup operation
        key = 32'h0; // Lookup the inserted key
        @(posedge clk); #1;
        if (hit) begin
            $display("Lookup: Key=0x%0h -> Value=0x%0h (Found)", key, value_out);
        end else begin
            $display("Lookup: Key=0x%0h -> Not Found", key);
        end

        // Test Deletions
        $display("\nTesting Deletions...");
        operation = 2'b10; // Delete operation
        key = 32'h0; // Delete the inserted key
        @(posedge clk); #1;
        wait(success);
        $display("Delete: Key=0x%0h -> Success", key);

        // Verify deletion by lookup
        $display("\nTesting Lookups After Deletion...");
        operation = 2'b00; // Lookup operation
        key = 32'h0; // Lookup the deleted key
        @(posedge clk); #1;
        if (hit) begin
            $display("Lookup: Key=0x%0h -> Value=0x%0h (Found)", key, value_out);
        end else begin
            $display("Lookup: Key=0x%0h -> Not Found", key);
        end

        $display("Test Complete!");
        $stop;
    end
endmodule




