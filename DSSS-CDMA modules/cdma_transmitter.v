`timescale 1ns/1ps

module cdma_transmitter (
    input clk,
    input rst,
    input data_in,
    input [5:0] user_code_1,  // User 1 code
    input [5:0] user_code_2,  // User 2 code
    input user_select,        // 0 for user 1, 1 for user 2
    output signed [7:0] bpsk_out
);

    wire [5:0] pn_seq;
    wire spread_signal;
    wire [5:0] active_user_code;
    
    // Instantiate LFSR
    lfsr_6bit lfsr (
        .out(pn_seq),
        .clk(clk),
        .rst(rst)
    );
    
    // Select active user code
    assign active_user_code = user_select ? user_code_2 : user_code_1;
    
    // Spreading process
    wire [5:0] spread_bits = pn_seq & active_user_code;
    assign spread_signal = data_in ^ (^spread_bits);
    
    // BPSK modulation
    assign bpsk_out = spread_signal ? 8'sd100 : -8'sd100;

endmodule
