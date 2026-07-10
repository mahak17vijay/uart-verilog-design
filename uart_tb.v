// uart_tb.v
// Self-checking testbench: connects TX -> RX in loopback,
// sends several known bytes, and checks each one is received correctly.

`timescale 1ns/1ps

module uart_tb;

    parameter CLKS_PER_BIT = 87;
    parameter CLK_PERIOD   = 20; // 50 MHz clock -> 20ns period

    reg        clk;
    reg        rst_n;
    reg        tx_start;
    reg  [7:0] tx_data;
    wire       tx_serial;
    wire       tx_busy;
    wire       tx_done;

    wire [7:0] rx_data;
    wire       rx_done;

    integer errors;
    integer i;

    // byte set to test
    reg [7:0] test_bytes [0:4];

    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) DUT_TX (
        .clk(clk), .rst_n(rst_n),
        .tx_start(tx_start), .tx_data(tx_data),
        .tx_serial(tx_serial), .tx_busy(tx_busy), .tx_done(tx_done)
    );

    // loopback: RX listens directly to TX's serial line
    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) DUT_RX (
        .clk(clk), .rst_n(rst_n),
        .rx_serial(tx_serial),
        .rx_data(rx_data), .rx_done(rx_done)
    );

    // clock generation
    always #(CLK_PERIOD/2) clk = ~clk;

    task send_byte(input [7:0] data);
        begin
            @(posedge clk);
            tx_data  = data;
            tx_start = 1'b1;
            @(posedge clk);
            tx_start = 1'b0;
        end
    endtask

    initial begin
        $dumpfile("uart_tb.vcd");
        $dumpvars(0, uart_tb);

        clk      = 0;
        rst_n    = 0;
        tx_start = 0;
        tx_data  = 8'd0;
        errors   = 0;

        test_bytes[0] = 8'h55; // 01010101
        test_bytes[1] = 8'hA3;
        test_bytes[2] = 8'h00;
        test_bytes[3] = 8'hFF;
        test_bytes[4] = 8'h3C;

        // release reset
        #(CLK_PERIOD*5);
        rst_n = 1;
        #(CLK_PERIOD*5);

        for (i = 0; i < 5; i = i + 1) begin
            send_byte(test_bytes[i]);

            // wait for RX to signal it has a byte
            @(posedge rx_done);
            #1; // small delta to let rx_data settle

            if (rx_data !== test_bytes[i]) begin
                $display("FAIL: sent 0x%0h, received 0x%0h", test_bytes[i], rx_data);
                errors = errors + 1;
            end else begin
                $display("PASS: byte 0x%0h received correctly", test_bytes[i]);
            end

            // wait for tx to be free before sending the next byte
            @(posedge tx_done);
            #(CLKS_PER_BIT*CLK_PERIOD);
        end

        if (errors == 0)
            $display("ALL TESTS PASSED (%0d bytes)", 5);
        else
            $display("TESTS FAILED: %0d error(s)", errors);

        #(CLK_PERIOD*10);
        $finish;
    end

endmodule
