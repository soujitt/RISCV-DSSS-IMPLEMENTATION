`timescale 1ns/1ps

module cdma_receiver (
    input clk,
    input rst,
    input signed [7:0] bpsk_in,
    input [5:0] user_code_1,
    input [5:0] user_code_2,
    input user_select,
    output reg data_out,
    output reg data_valid
);

    wire [5:0] pn_seq;
    wire [5:0] active_user_code;
    wire [5:0] spread_code;
    wire despread_bit;
    reg signed [23:0] accum; // Increased from [19:0] to prevent overflow
    reg [5:0] chip_count;

    // Instantiate LFSR (must match transmitter)
    lfsr_6bit pn_gen (
        .clk(clk),
        .rst(rst),
        .out(pn_seq)
    );

    // Select active user code
    assign active_user_code = user_select ? user_code_2 : user_code_1;
    
    // Despreading process
    assign spread_code = pn_seq & active_user_code;
    assign despread_bit = ^spread_code;
    wire signed [7:0] despreaded_signal = despread_bit ? bpsk_in : -bpsk_in;

    // Correlation and data recovery
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            accum <= 0;
            chip_count <= 0;
            data_out <= 0;
            data_valid <= 0;
        end else begin
            accum <= accum + despreaded_signal;
            chip_count <= chip_count + 1;
            data_valid <= 0;

            if (chip_count == 6'd63) begin // Full 64-chip period
                data_out <= (accum > 0) ? 1'b1 : 1'b0;
                data_valid <= 1;
                chip_count <= 0;
                accum <= 0;
            end
        end
    end

endmodule