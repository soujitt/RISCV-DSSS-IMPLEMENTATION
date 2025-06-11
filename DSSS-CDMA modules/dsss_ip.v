module dsss_ip (
    // System signals
    input clk,
    input rst,
    
    // DSSS signals
    output signed [7:0] bpsk_out,
    input signed [7:0] bpsk_in,
    
    // Register interface
    input [31:0] waddr,
    input [31:0] wdata,
    input [3:0] wstrb,
    input wen,
    output reg [31:0] rdata,
    input [31:0] raddr,
    input ren
);

// Register map (Corsair style)
localparam DSSS_TX_CTRL    = 0;  // Control register
localparam DSSS_TX_DATA    = 4;  // Data to transmit
localparam DSSS_TX_CODE1   = 8;  // User code 1
localparam DSSS_TX_CODE2   = 12; // User code 2
localparam DSSS_RX_CTRL    = 16; // Receiver control
localparam DSSS_RX_DATA    = 20; // Received data
localparam DSSS_RX_STATUS  = 24; // Status register

// Internal registers
reg [5:0] user_code_1;
reg [5:0] user_code_2;
reg tx_enable;
reg rx_enable;
reg [1:0] user_select;
wire tx_data_valid;
wire rx_data_valid;
wire tx_data_out;
wire rx_data_out;

// Instantiate transmitter
cdma_transmitter dsss_tx (
    .clk(clk),
    .rst(rst),
    .data_in(tx_data_out),
    .user_code_1(user_code_1),
    .user_code_2(user_code_2),
    .user_select(user_select[0]),
    .bpsk_out(bpsk_out)
);

// Instantiate receiver
cdma_receiver dsss_rx (
    .clk(clk),
    .rst(rst),
    .bpsk_in(bpsk_in),
    .user_code_1(user_code_1),
    .user_code_2(user_code_2),
    .user_select(user_select[1]),
    .data_out(rx_data_out),
    .data_valid(rx_data_valid)
);

// Register write logic
always @(posedge clk) begin
    if (rst) begin
        user_code_1 <= 6'b101011;
        user_code_2 <= 6'b110101;
        tx_enable <= 0;
        rx_enable <= 0;
        user_select <= 0;
    end else if (wen) begin
        case (waddr[7:0])
            DSSS_TX_CTRL: begin
                if (wstrb[0]) tx_enable <= wdata[0];
                if (wstrb[1]) user_select[0] <= wdata[8];
            end
            DSSS_TX_CODE1: if (|wstrb) user_code_1 <= wdata[5:0];
            DSSS_TX_CODE2: if (|wstrb) user_code_2 <= wdata[5:0];
            DSSS_RX_CTRL: begin
                if (wstrb[0]) rx_enable <= wdata[0];
                if (wstrb[1]) user_select[1] <= wdata[8];
            end
        endcase
    end
end

// Register read logic
always @(*) begin
    rdata = 32'h0;
    if (ren) begin
        case (raddr[7:0])
            DSSS_TX_CTRL:    rdata = {23'b0, user_select[0], 7'b0, tx_enable};
            DSSS_TX_DATA:    rdata = {31'b0, tx_data_out};
            DSSS_TX_CODE1:   rdata = {26'b0, user_code_1};
            DSSS_TX_CODE2:   rdata = {26'b0, user_code_2};
            DSSS_RX_CTRL:    rdata = {23'b0, user_select[1], 7'b0, rx_enable};
            DSSS_RX_DATA:   rdata = {31'b0, rx_data_out};
            DSSS_RX_STATUS:  rdata = {31'b0, rx_data_valid};
            default:        rdata = 32'h0;
        endcase
    end
end

endmodule