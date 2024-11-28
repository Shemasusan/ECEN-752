`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/27/2024 12:03:44 PM
// Design Name: 
// Module Name: tb_ssd
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


module tb_ssd_sim;
    parameter VALUE_SIZE = 32;
    parameter DATA_SIZE = 512;
    parameter SSD_CAPACITY = 32;

    reg clk, reset;
    reg write, delete, read;
    reg [DATA_SIZE-1:0] data_in;
    reg [VALUE_SIZE-1:0] addr_in;
    wire [VALUE_SIZE-1:0] addr_out;
    wire [DATA_SIZE-1:0] data_out;
    wire ready, done;

    // Instantiate the ssd_sim module
    ssd_sim #(
        .VALUE_SIZE(VALUE_SIZE), 
        .DATA_SIZE(DATA_SIZE), 
        .SSD_CAPACITY(SSD_CAPACITY)
    ) ssd (
        .clk(clk),
        .reset(reset),
        .write(write),
        .delete(delete),
        .read(read),
        .data_in(data_in),
        .addr_in(addr_in),
        .addr_out(addr_out),
        .data_out(data_out),
        .ready(ready),
        .done(done)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 10 ns clock period

    // Test sequence
    initial begin
        // Initialize
        reset = 1; write = 0; delete = 0; read = 0; data_in = 0; addr_in = 0;// ready = 1; done = 0;
        #10 reset = 0;

        // Test 1: Write to SSD
        $display("\nTesting Write Operations...");
        write = 1; data_in = 512'hA0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0; // Arbitrary data
        addr_in = 32'h0;
        //ready = 1; // SSD is ready to accept the operation
        @(posedge clk); #1;
        write = 0;
        //done = 1; // Indicate operation completion
        wait(done); // Wait for operation to complete
        $display("Write: Data written to SSD at Addr=0x%0h", addr_out);
        #10;

        // Test 2: Read from SSD (valid address)
$display("\nTesting Read from Valid Address...");
read = 1; addr_in = 32'h0; // Read the address we just wrote
//ready = 1; // SSD is ready to accept the operation
@(posedge clk); #1;
read = 0; // Deactivate the read signal
wait(done); // Wait for the operation to complete
$display("Read: Data read from SSD at Addr=0x%0h, Data=0x%0h", addr_in, data_out);
#10;

// Test 3: Read from SSD (invalid address)
$display("\nTesting Invalid Read Operation...");
read = 1; addr_in = 32'h1; // Invalid read (address not written to)
//ready = 1; // SSD is ready to accept the operation
@(posedge clk); #1;
read = 0; // Deactivate the read signal
wait(done); // Wait for the operation to complete
$display("Invalid Read: Data read from SSD at Addr=0x%0h, Data=0x%0h", addr_in, data_out);
#10;

// Test 4: Delete operation
$display("\nTesting Delete Operations...");
delete = 1; addr_in = 32'h0; // Delete the address we just wrote
//ready = 1; // SSD is ready to accept the operation
@(posedge clk); #1;
delete = 0;
wait(done); // Wait for the operation to complete
$display("Delete: Data deleted from SSD at Addr=0x%0h", addr_in);
#10;

// Test 5: Read from SSD after deletion (invalid read)
$display("\nTesting Read After Deletion...");
read = 1; addr_in = 32'h0; // Read the deleted address
//ready = 1; // SSD is ready to accept the operation
@(posedge clk); #1;
read = 0; // Deactivate the read signal
wait(done); // Wait for the operation to complete
$display("Read After Deletion: Data read from SSD at Addr=0x%0h, Data=0x%0h", addr_in, data_out);
#10;

        // Test 6: Write After SSD is Full
        $display("\nTesting Write When SSD is Full...");
        for (integer i = 0; i < SSD_CAPACITY; i = i + 1) begin
            write = 1; data_in = {8{i}}; addr_in = i; // Writing arbitrary data
            @(posedge clk); #1;
            write = 0;
            //done = 1;
            wait(done);
            $display("Write: Data written to SSD at Addr=0x%0h", addr_in);
        end
        // Try writing beyond the SSD's capacity
        write = 1; data_in = 512'hF0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0;
        addr_in = 32'h1024; // Attempt to write beyond SSD capacity
        @(posedge clk); #1;
        write = 0;
        //done = 1;
        wait(done);
        $display("Write Beyond Capacity: Attempt to write at Addr=0x%0h", addr_in);
        #10;

        // Test 7: Boundary Test (First Address)
        $display("\nTesting Boundary Write and Read (First Address)...");
        write = 1; data_in = 512'hF1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1;
        addr_in = 32'h0; // Write to address 0x0
        //ready = 1; // SSD is ready
        @(posedge clk); #1;
        write = 0;
        //done = 1;
        wait(done); // Wait for operation to complete
        $display("Boundary Test: Data written to SSD at Addr=0x%0h", addr_out);
        #10;

        // Test 8: Boundary Test (Last Address)
        $display("\nTesting Boundary Write and Read (Last Address)...");
        write = 1; data_in = 512'hA1A1A1A1A1A1A1A1A1A1A1A1A1A1A1A1;
        addr_in = 32'h1F; // Write to the last address 0x1F
        //ready = 1; // SSD is ready
        @(posedge clk); #1;
        write = 0;
        //done = 1;
        wait(done); // Wait for operation to complete
        $display("Boundary Test: Data written to SSD at Addr=0x%0h", addr_out);
        #10;

        // Test 9: Read from Full SSD
        $display("\nTesting Read from Full SSD...");
        for (integer i = 0; i < SSD_CAPACITY; i = i + 1) begin
            read = 1; addr_in = i; // Read each address
            //ready = 1; // SSD is ready
            @(posedge clk); #1;
            read = 0;
            //done = 1;
            wait(done);
            $display("Read: Data read from SSD at Addr=0x%0h, Data=0x%0h", addr_in, data_out);
        end
        #10;

        // Finish test
        $display("\nTest Complete!");
        $stop;
    end
endmodule



