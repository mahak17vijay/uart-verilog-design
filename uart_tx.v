// uart_tx.v
// Simple UART Transmitter: 8-N-1 format (8 data bits, no parity, 1 stop bit)
// Parameterized clock divider for baud rate generation

module uart_tx #(
    parameter CLKS_PER_BIT = 87   // e.g. 50MHz clk / 115200 baud ~= 434 (use small value for sim)
)(
    input        clk,
    input        rst_n,
    input        tx_start,      // pulse high for 1 clk to begin transmission
    input  [7:0] tx_data,       // byte to send
    output reg   tx_serial,     // serial output line
    output reg   tx_busy,       // high while transmitting
    output reg   tx_done        // pulses high for 1 clk when byte finished
);

    localparam IDLE  = 3'd0,
               START = 3'd1,
               DATA  = 3'd2,
               STOP  = 3'd3;

    reg [2:0]  state;
    reg [15:0] clk_count;
    reg [2:0]  bit_index;
    reg [7:0]  tx_data_latched;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state           <= IDLE;
            clk_count       <= 0;
            bit_index       <= 0;
            tx_serial       <= 1'b1;   // idle line is high
            tx_busy         <= 1'b0;
            tx_done         <= 1'b0;
            tx_data_latched <= 8'd0;
        end else begin
            tx_done <= 1'b0;

            case (state)
                IDLE: begin
                    tx_serial <= 1'b1;
                    clk_count <= 0;
                    bit_index <= 0;
                    if (tx_start) begin
                        tx_busy         <= 1'b1;
                        tx_data_latched <= tx_data;
                        state           <= START;
                    end
                end

                START: begin
                    tx_serial <= 1'b0;  // start bit
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        state     <= DATA;
                    end
                end

                DATA: begin
                    tx_serial <= tx_data_latched[bit_index];
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            bit_index <= 0;
                            state     <= STOP;
                        end
                    end
                end

                STOP: begin
                    tx_serial <= 1'b1;  // stop bit
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        tx_busy   <= 1'b0;
                        tx_done   <= 1'b1;
                        state     <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
