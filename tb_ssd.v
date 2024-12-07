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
        reset = 1; write = 0; delete = 0; read = 0; data_in = 0; addr_in = 0;
        #10 reset = 0;

        // Test 1: Write to SSD
        $display("\nTesting Write Operations...");
        
        // Write Operation Test 1
        write = 1;
        data_in = 512'hA0A0A0A0A0A0A0A0A0A0A0A0A0A0A0A0; // Arbitrary data to write
        addr_in = 32'h0;  // Writing at address 0x0
        @(posedge clk); #1;
        write = 0;
        wait(done); // Wait for the operation to complete
        $display("Write Test 1: Data written to SSD at Addr=0x%0h", addr_out);
        #10;

        // Write Operation Test 2
        write = 1;
        data_in = 512'hB0B0B0B0B0B0B0B0B0B0B0B0B0B0B0B0; // Another arbitrary data pattern
        addr_in = 32'h4;  // Writing at address 0x4
        @(posedge clk); #1;
        write = 0;
        wait(done); // Wait for the operation to complete
        $display("Write Test 2: Data written to SSD at Addr=0x%0h", addr_out);
        #10;

        // Write Operation Test 3 (Beyond Capacity)
        $display("\nTesting Write Beyond SSD Capacity...");
        write = 1;
        data_in = 512'hC0C0C0C0C0C0C0C0C0C0C0C0C0C0C0C0; // Data to write
        addr_in = 32'h100;  // Attempt to write beyond the SSD capacity
        @(posedge clk); #1;
        write = 0;
        wait(done); // Wait for the operation to complete
        $display("Write Beyond Capacity: Attempted write at Addr=0x%0h", addr_in);
        #10;

        // Finish write test
        $display("\nWrite Operations Complete!");
        $stop;
    end
endmodule
