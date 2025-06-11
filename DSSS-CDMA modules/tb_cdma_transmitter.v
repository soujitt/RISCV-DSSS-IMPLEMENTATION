`timescale 1ns/1ps

module tb_cdma_transmitter();

    // Parameters
    parameter CLK_PERIOD = 10;  // 100 MHz clock
    parameter USER_CODE_1 = 6'b101011; // User 1 code
    parameter USER_CODE_2 = 6'b110101; // User 2 code
    
    // Signals
    reg clk;
    reg rst;
    reg [1:0] data_in;       // [0] for user1, [1] for user2
    wire signed [7:0] bpsk_out_1, bpsk_out_2;
    wire [5:0] pn_and_user_1 = dut1.pn_seq & USER_CODE_1;
    wire [5:0] pn_and_user_2 = dut2.pn_seq & USER_CODE_2;
    wire pn_xor_user_1 = ^pn_and_user_1;
    wire pn_xor_user_2 = ^pn_and_user_2;
    reg signed [7:0] expected_bpsk_1=0, expected_bpsk_2=0;
    integer error_count = 0;

    // Instantiate DUTs for both users
    cdma_transmitter dut1 (
        .clk(clk),
        .rst(rst),
        .data_in(data_in[0]),
        .user_code_1(USER_CODE_1),
        .user_code_2(USER_CODE_2),
        .user_select(1'b0),     // Explicit 1-bit 0 for user 1
        .bpsk_out(bpsk_out_1)
    );
    
    cdma_transmitter dut2 (
        .clk(clk),
        .rst(rst),
        .data_in(data_in[1]),
        .user_code_1(USER_CODE_1),
        .user_code_2(USER_CODE_2),
        .user_select(1'b1),     // Explicit 1-bit 1 for user 2
        .bpsk_out(bpsk_out_2)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test sequence
    initial begin
        // Initialize
        rst = 1;
        data_in = 2'b00;
        #100;
        
        // Test Case 1: Reset Verification
        $display("\n=== Test Case 1: Reset Verification ===");
        if (dut1.pn_seq !== 6'b101010 || dut2.pn_seq !== 6'b101010) begin
            $error("Reset failed - PN seq not initialized properly");
            error_count = error_count + 1;
        end else begin
            $display("Reset verification passed for both users");
        end
        
        // Verify PN sequences are synchronized
        if (dut1.pn_seq !== dut2.pn_seq) begin
            $error("PN sequences not synchronized between users!");
            error_count = error_count + 1;
        end
        
        rst = 0;
        #10;
        
        // Test Case 2: User 1 transmission
        $display("\n=== Test Case 2: User 1 transmission ===");
        data_in[0] = 1;
        repeat(64) begin  // Changed to 64 cycles for full LFSR period
            @(posedge clk);
            expected_bpsk_1 = (data_in[0] ^ pn_xor_user_1) ? 8'sd100 : -8'sd100;
            if (bpsk_out_1 !== expected_bpsk_1) begin
                $error("User1 Mismatch at time %t: Expected %d, Got %d", 
                      $time, expected_bpsk_1, bpsk_out_1);
                error_count = error_count + 1;
            end
        end
        
        // Test Case 3: User 2 transmission
        $display("\n=== Test Case 3: User 2 transmission ===");
        data_in[1] = 1;
        repeat(64) begin  // Changed to 64 cycles for full LFSR period
            @(posedge clk);
            expected_bpsk_2 = (data_in[1] ^ pn_xor_user_2) ? 8'sd100 : -8'sd100;
            if (bpsk_out_2 !== expected_bpsk_2) begin
                $error("User2 Mismatch at time %t: Expected %d, Got %d", 
                      $time, expected_bpsk_2, bpsk_out_2);
                error_count = error_count + 1;
            end
        end
        
        // Test Case 4: Both users simultaneously
        $display("\n=== Test Case 4: Both users simultaneously ===");
        data_in = 2'b11;
        repeat(64) begin  // Changed to 64 cycles for full LFSR period
            @(posedge clk);
            expected_bpsk_1 = (data_in[0] ^ pn_xor_user_1) ? 8'sd100 : -8'sd100;
            expected_bpsk_2 = (data_in[1] ^ pn_xor_user_2) ? 8'sd100 : -8'sd100;
            
            if (bpsk_out_1 !== expected_bpsk_1) begin
                $error("User1 Mismatch at time %t: Expected %d, Got %d", 
                      $time, expected_bpsk_1, bpsk_out_1);
                error_count = error_count + 1;
            end
            
            if (bpsk_out_2 !== expected_bpsk_2) begin
                $error("User2 Mismatch at time %t: Expected %d, Got %d", 
                      $time, expected_bpsk_2, bpsk_out_2);
                error_count = error_count + 1;
            end
        end
        
        // Test summary
        $display("\n=== Test Summary ===");
        if (error_count == 0) begin
            $display("All tests completed successfully");
        end else begin
            $display("Completed with %0d errors", error_count);
        end
        $finish;
    end
    
    // Monitor
    initial begin
        $monitor("Time=%t | U1: data=%b, out=%d | U2: data=%b, out=%d",
                 $time, data_in[0], bpsk_out_1, data_in[1], bpsk_out_2);
    end

    // VCD dump
    initial begin
        $dumpfile("cdma_transmitter_multi.vcd");
        $dumpvars(0, tb_cdma_transmitter);
    end

endmodule
