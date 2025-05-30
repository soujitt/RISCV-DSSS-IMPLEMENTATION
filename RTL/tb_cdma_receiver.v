`timescale 1ns/1ps

module tb_cdma_receiver;

    parameter CLK_PERIOD = 10;
    parameter USER_CODE_1 = 6'b101011; // User 1 code
    parameter USER_CODE_2 = 6'b110101; // User 2 code
    parameter NUM_BITS = 4;
    parameter CHIP_DURATION = 64; // Full LFSR period

    // Signals
    reg clk, rst;
    reg [1:0] data_in;       // [0] for user1, [1] for user2
    wire signed [7:0] bpsk_out_1, bpsk_out_2;
    wire signed [7:0] combined_out = bpsk_out_1 + bpsk_out_2;
    wire data_out_1, data_valid_1;
    wire data_out_2, data_valid_2;

    // Explicit 1-bit user select signals
    wire user_select_1 = 1'b0; // Always user 1
    wire user_select_2 = 1'b1; // Always user 2

    // Instantiate transmitters with explicit 1-bit selects
    cdma_transmitter tx1 (
        .clk(clk),
        .rst(rst),
        .data_in(data_in[0]),
        .user_code_1(USER_CODE_1),
        .user_code_2(USER_CODE_2),
        .user_select(user_select_1),
        .bpsk_out(bpsk_out_1)
    );
    
    cdma_transmitter tx2 (
        .clk(clk),
        .rst(rst),
        .data_in(data_in[1]),
        .user_code_1(USER_CODE_1),
        .user_code_2(USER_CODE_2),
        .user_select(user_select_2),
        .bpsk_out(bpsk_out_2)
    );

    // Instantiate receivers with explicit 1-bit selects
    cdma_receiver rx1 (
        .clk(clk),
        .rst(rst),
        .bpsk_in(combined_out),
        .user_code_1(USER_CODE_1),
        .user_code_2(USER_CODE_2),
        .user_select(user_select_1),
        .data_out(data_out_1),
        .data_valid(data_valid_1)
    );
    
    cdma_receiver rx2 (
        .clk(clk),
        .rst(rst),
        .bpsk_in(combined_out),
        .user_code_1(USER_CODE_1),
        .user_code_2(USER_CODE_2),
        .user_select(user_select_2),
        .data_out(data_out_2),
        .data_valid(data_valid_2)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // Test data
    reg [NUM_BITS-1:0] test_data_1 = 4'b1010;
    reg [NUM_BITS-1:0] test_data_2 = 4'b1100;
    integer bit_count = 0;

    // Stimulus
    initial begin
        // Initialize
        rst = 1;
        data_in = 2'b00;
        #100;
        rst = 0;

        $display("\nTesting %0d-bit transmission for both users", NUM_BITS);
        
        // Send test data for both users
        for (bit_count = 0; bit_count < NUM_BITS; bit_count = bit_count + 1) begin
            // Reset between bits to ensure synchronization
            rst = 1;
            #20;
            rst = 0;
            #20;
            
            data_in[0] = test_data_1[bit_count];
            data_in[1] = test_data_2[bit_count];
            
            // Wait exactly one full correlation period
            repeat(CHIP_DURATION) @(posedge clk);
            
            // Verify received data
            if (data_out_1 !== test_data_1[bit_count]) begin
                $error("User1 Bit %0d mismatch! Expected %b, Got %b", 
                      bit_count, test_data_1[bit_count], data_out_1);
            end else begin
                $display("User1 Bit %0d passed: Data out = %b", bit_count, data_out_1);
            end
            
            if (data_out_2 !== test_data_2[bit_count]) begin
                $error("User2 Bit %0d mismatch! Expected %b, Got %b", 
                      bit_count, test_data_2[bit_count], data_out_2);
            end else begin
                $display("User2 Bit %0d passed: Data out = %b", bit_count, data_out_2);
            end
            
            // Small delay between bits
            #10;
        end

        $display("\nAll receiver tests completed");
        $finish;
    end

    // Monitor
    initial begin
        $monitor("Time=%t | TX: U1=%b, U2=%b | RX: U1=%b(v=%b), U2=%b(v=%b)",
                 $time, data_in[0], data_in[1], 
                 data_out_1, data_valid_1, data_out_2, data_valid_2);
    end

    // VCD dump
    initial begin
        $dumpfile("cdma_receiver_multi.vcd");
        $dumpvars(0, tb_cdma_receiver);
    end

endmodule