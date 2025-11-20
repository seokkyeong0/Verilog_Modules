`timescale 1ns / 1ps

`include "./rtl/uart/uart_rx.sv"
`include "./rtl/uart/uart_tx.sv"
`include "./rtl/uart/baud_generator.sv"
`include "./rtl/uart/fifo.sv"

module uart #(parameter BAUD = 9600)(
    input  logic clk,
    input  logic reset,
    input  logic rx_in,
    output logic tx_out 
    );

    // baud tick signal
    logic w_baud;

    // fifo rx side
    logic [7:0] rx_data;
    logic rx_done;
    logic rx_busy;
    logic rx_full;
    logic rx_empty;

    // fifo tx side
    logic [7:0] tx_data;
    logic tx_done;
    logic tx_busy;
    logic tx_full;
    logic tx_empty;

    // uart tx side
    logic [7:0] lb_data;
    logic lb_done;
    logic lb_busy;

    baud_generator #(.BAUD(BAUD)) U_BG(
        .clk    (clk),
        .rst    (reset),
        .baud   (w_baud)
    );

    uart_rx U_UART_RX(
        .clk      (clk),
        .rst      (reset),
        .baud     (w_baud),
        .rx_in    (rx_in),
        .rx_data  (rx_data),
        .rx_done  (rx_done),
        .rx_busy  (rx_busy)
    );

    fifo #(.DEPTH(8)) U_FIFO_RX(
        .clk      (clk),
        .rst      (reset),
        .push     (rx_done),
        .pop      (~rx_empty),
        .wdata    (rx_data),
        .rdata    (tx_data),
        .full     (rx_full),
        .empty    (rx_empty)
    );

    fifo #(.DEPTH(8)) U_FIFO_TX(
        .clk      (clk),
        .rst      (reset),
        .push     (~rx_empty),
        .pop      (~tx_empty),
        .wdata    (tx_data),
        .rdata    (lb_data),
        .full     (tx_full),
        .empty    (tx_empty)
    );

    uart_tx U_UART_TX(
        .clk      (clk),
        .rst      (reset),
        .baud     (w_baud),
        .tx_start (~tx_empty & ~lb_busy),
        .tx_data  (lb_data),
        .tx_out   (tx_out),
        .tx_done  (lb_done),
        .tx_busy  (lb_busy)
    );
endmodule