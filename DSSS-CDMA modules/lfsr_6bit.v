`timescale 1ns/1ps

module lfsr_6bit (
    output reg [5:0] out,
    input clk,
    input rst
);

    wire feedback;
    assign feedback = ~(out[5] ^ out[0]); // Polynomial: x^6 + x^5 + 1

    always @(posedge clk or posedge rst) begin
        if (rst)
            out <= 6'b000001; // Non-zero seed
        else
            out <= {out[4:0], feedback};
    end

endmodule