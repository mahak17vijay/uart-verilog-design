// uart_rx.v
// Simple UART Receiver: 8-N-1 format
// Samples the middle of each bit period after detecting the falling edge of start bit

module uart_rx #(
    parameter CLKS_PER_BIT = 87
)(
    input        clk,
    input        rst_n,
    input        rx_serial,     // serial input line
    output reg [7:0] rx_data,   // received byte
    output reg   rx_done        // pulses high for 1 clk when a byte is ready
);

    localparam IDLE  = 3'd0,
               START = 3'd1,
               DATA  = 3'd2,
               STOP  = 3'd3;

    reg [2:0]  state;
    reg [15:0] clk_count;
    reg [2:0]  bit_index;
    reg [7:0]  rx_shift;

    // 2-flop synchronizer to bring the async rx_serial line into our clock domain
    // (protects against metastability -- a basic CDC technique)
    reg rx_sync_0, rx_sync_1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_sync_0 <= 1'b1;
            rx_sync_1 <= 1'b1;
        end else begin
            rx_sync_0 <= rx_serial;
            rx_sync_1 <= rx_sync_0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            clk_count <= 0;
            bit_index <= 0;
            rx_shift  <= 8'd0;
            rx_data   <= 8'd0;
            rx_done   <= 1'b0;
        end else begin
            rx_done <= 1'b0;

            case (state)
                IDLE: begin
                    clk_count <= 0;
                    bit_index <= 0;
                    if (rx_sync_1 == 1'b0) begin   // falling edge = start bit detected
                        state <= START;
                    end
                end

                START: begin
                    // sample at the middle of the start bit to confirm it's valid
                    if (clk_count == (CLKS_PER_BIT - 1) / 2) begin
                        if (rx_sync_1 == 1'b0) begin
                            clk_count <= 0;
                            state     <= DATA;
                        end else begin
                            state <= IDLE;  // false start (glitch)
                        end
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end

                DATA: begin
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count            <= 0;
                        rx_shift[bit_index]  <= rx_sync_1;
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            bit_index <= 0;
                            state     <= STOP;
                        end
                    end
                end

                STOP: begin
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        rx_data   <= rx_shift;
                        rx_done   <= 1'b1;
                        state     <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
