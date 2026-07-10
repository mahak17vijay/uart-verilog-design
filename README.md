# UART Transceiver in Verilog

A UART (Universal Asynchronous Receiver/Transmitter) design implemented in Verilog, with a self-checking testbench verifying TX-RX loopback communication.

## Overview

This project implements the standard 8-N-1 UART frame format (1 start bit, 8 data bits, no parity, 1 stop bit) as two independent FSM-based modules:

- **`uart_tx.v`** — Parallel-to-serial transmitter. Takes an 8-bit input byte and serializes it onto a single output line, framed with start/stop bits. Baud rate is configurable via the `CLKS_PER_BIT` parameter (a clock-divider value).
- **`uart_rx.v`** — Serial-to-parallel receiver. Detects an incoming start bit, samples each data bit at the midpoint of its bit period for reliability, and reconstructs the original byte. Includes a **2-flop synchronizer** on the input line to safely handle the asynchronous serial signal crossing into the receiver's clock domain.
- **`uart_tb.v`** — Testbench. Connects TX's serial output directly to RX's serial input (loopback), transmits 5 test bytes (including edge cases `0x00` and `0xFF`), and automatically checks each received byte against what was sent.

## Design highlights

- FSM-based control (`IDLE → START → DATA → STOP`) for both TX and RX
- Parameterized baud rate via `CLKS_PER_BIT`
- Mid-bit sampling on RX for robust bit detection
- 2-flip-flop synchronizer for clock domain crossing (CDC) on the async input
- Self-checking testbench (no manual waveform inspection needed to verify correctness)

## Running the simulation

Using [Icarus Verilog](http://iverilog.icarus.com/):

```bash
iverilog -o sim uart_tx.v uart_rx.v uart_tb.v
vvp sim
```

Expected output:
