`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/27/2024 09:46:30 AM
// Design Name: 
// Module Name: tb_hash_ssd
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

module tb_hash_table_with_ssd();
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

    // SSD Interface
    wire ssd_write, ssd_delete;
    wire [DATA_SIZE-1:0] ssd_data_out;
    wire [VALUE_SIZE-1:0] ssd_addr_out;
    wire [VALUE_SIZE-1:0] ssd_addr_in;
    wire ssd_ready, ssd_done;

    // Instantiate the hash table
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
        .success(success),
        .ssd_write(ssd_write),
        .ssd_delete(ssd_delete),
        .ssd_data_out(ssd_data_out),
        .ssd_addr_out(ssd_addr_out),
        .ssd_addr_in(ssd_addr_in),
        .ssd_ready(ssd_ready),
        .ssd_done(ssd_done)
    );

    // Instantiate the simulated SSD module
    ssd_sim #(.VALUE_SIZE(VALUE_SIZE), .DATA_SIZE(DATA_SIZE)) ssd (
        .clk(clk),
        .reset(reset),
        .write(ssd_write),
        .delete(ssd_delete),
        .data_in(ssd_data_out),
        .addr_in(ssd_addr_out),
        .addr_out(ssd_addr_in),
        .ready(ssd_ready),
        .done(ssd_done)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 10 ns clock period

    // Test sequence
    initial begin
        $display("Starting Testbench...");

        // Reset the system
        reset = 1; #10; reset = 0;

        // Insert photos into SSD via hash table
        $display("\nTesting Insertions...");
        for (integer i = 0; i < TABLE_SIZE; i=i+1) begin
            test_insert(i, i * 16); // Insert keys 0 to TABLE_SIZE-1 with dummy photo data
        end

        // Lookup operations
        $display("\nTesting Lookups...");
        for (integer i = 0; i < TABLE_SIZE; i=i+1) begin
            test_lookup(i); // Lookup each key
        end
        test_lookup(TABLE_SIZE + 1); // Lookup a non-existent key

        // Delete operations
        $display("\nTesting Deletions...");
        for (integer i = 0; i < TABLE_SIZE; i=i+1) begin
            test_delete(i); // Delete each key
        end

        // Verify all keys are deleted
        $display("\nTesting Lookups After Deletion...");
        for (integer i = 0; i < TABLE_SIZE; i=i+1) begin
            test_lookup(i); // Should not find any key
        end

        $display("Testbench Completed!");
        $stop;
    end

    // Task for Insert Operation
    task test_insert(input [WIDTH-1:0] test_key, input [DATA_SIZE-1:0] test_data);
        begin
            operation = 2'b01; key = test_key; photo_data = test_data;
            @(posedge clk); #1;
            if (success) begin
                wait (ssd_done); // Wait for SSD write to complete
                $display("Insert: Key=0x%0h, SSD Addr=0x%0h -> Success", test_key, ssd_addr_in);
            end else begin
                $display("Insert: Key=0x%0h, Data=0x%0h -> Failed (SSD Busy or Collision)", test_key, test_data);
            end
        end
    endtask

    // Task for Lookup Operation
    task test_lookup(input [WIDTH-1:0] test_key);
        begin
            operation = 2'b00; key = test_key;
            @(posedge clk); #1;
            if (hit) $display("Lookup: Key=0x%0h -> SSD Addr=0x%0h (Found)", test_key, value_out);
            else $display("Lookup: Key=0x%0h -> Not Found", test_key);
        end
    endtask

    // Task for Delete Operation
    task test_delete(input [WIDTH-1:0] test_key);
        begin
            operation = 2'b10; key = test_key;
            @(posedge clk); #1;
            if (success) begin
                wait (ssd_done); // Wait for SSD delete to complete
                $display("Delete: Key=0x%0h -> Success", test_key);
            end else begin
                $display("Delete: Key=0x%0h -> Failed (Key Not Found or SSD Busy)", test_key);
            end
        end
    endtask
endmodule
