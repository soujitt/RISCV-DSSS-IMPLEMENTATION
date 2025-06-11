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
    // Parameters
    parameter INIT_THRESHOLD = 32'sd500;      // Initial threshold
    parameter ADAPTATION_RATE = 5;            // How quickly threshold adapts (higher = slower)
    parameter MIN_THRESHOLD = 32'sd100;       // Minimum allowed threshold
    parameter MAX_THRESHOLD = 32'sd2000;      // Maximum allowed threshold
    
    // Signals
    wire [5:0] pn_seq;
    wire [5:0] active_user_code;
    wire [5:0] spread_code;
    wire despread_bit;
    reg signed [31:0] accum;
    reg [5:0] chip_count;
    reg signed [31:0] dynamic_threshold;      // Dynamic threshold register
    reg signed [31:0] signal_power;           // Estimated signal power
    reg signed [7:0] gain_factor = 8'sd64; // Initial gain (1.0 in Q7 format)
    reg signed [15:0] rssi;                // Received signal strength indicator
    
    // Instantiate LFSR
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

    // Signal power estimation (moving average)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            signal_power <= 0;
        end else begin
            // Low-pass filter to estimate signal power
            signal_power <= (signal_power * (ADAPTATION_RATE-1) + 
                           (despreaded_signal * despreaded_signal)) / ADAPTATION_RATE;
        end
    end

    // Dynamic threshold calculation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dynamic_threshold <= INIT_THRESHOLD;
        end else begin
            // Set threshold proportional to sqrt(signal power)
            // with min/max bounds
            if (signal_power > 0) begin
                dynamic_threshold <= $sqrt(signal_power) * 8; // Scaling factor
                
                // Apply bounds
                if (dynamic_threshold < MIN_THRESHOLD)
                    dynamic_threshold <= MIN_THRESHOLD;
                if (dynamic_threshold > MAX_THRESHOLD)
                    dynamic_threshold <= MAX_THRESHOLD;
            end
        end
    end

    // Correlation and data recovery with dynamic threshold
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
                if (accum > dynamic_threshold) begin
                    data_out <= 1'b1;
                    data_valid <= 1;
                end else if (accum < -dynamic_threshold) begin
                    data_out <= 1'b0;
                    data_valid <= 1;
                end else begin
                    data_valid <= 0; // Signal too weak
                end
                
                chip_count <= 0;
                accum <= 0;
            end
        end
    end

// Automatic Gain Control (AGC)
always @(posedge clk or posedge rst) begin
    if (rst) begin
        gain_factor <= 8'sd64; // Reset to unity gain
        rssi <= 0;
    end else begin
        // Update RSSI estimate (moving average of absolute signal)
        rssi <= (rssi * 15 + (bpsk_in > 0 ? bpsk_in : -bpsk_in)) / 16;
        
        // Adjust gain to target RSSI of 50 (example value)
        if (rssi > 60 && gain_factor > 8'sd16) begin
            gain_factor <= gain_factor - 1; // Reduce gain
        end else if (rssi < 40 && gain_factor < 8'sd127) begin
            gain_factor <= gain_factor + 1; // Increase gain
        end
    end
end
    // Accumulator saturation logic
    always @(posedge clk) begin
        if (accum >  32'sd5000) accum <=  32'sd5000;
        if (accum < -32'sd5000) accum <= -32'sd5000;
    end

endmodule
