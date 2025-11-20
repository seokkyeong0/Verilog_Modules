`timescale 1ns / 1ps

module baud_generator #(parameter BAUD = 9600)(
    input  logic clk,
    input  logic rst,
    output logic baud
    );

    // local parameter DIV
    localparam DIV = 100_000_000 / (BAUD * 16);

    // count register
    logic [$clog2(DIV)-1:0] b_cnt_reg;
    logic b_tick_reg;

    // assign output
    assign baud = b_tick_reg;

    // sequential logic
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            b_cnt_reg  <= 0;
            b_tick_reg <= 1'b0;
        end else begin
            if (b_cnt_reg == DIV - 1) begin
                b_cnt_reg  <= 0;
                b_tick_reg <= 1'b1;
            end else begin
                b_cnt_reg  <= b_cnt_reg + 1;
                b_tick_reg <= 1'b0;
            end
        end
    end
endmodule
