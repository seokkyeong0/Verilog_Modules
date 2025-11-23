`timescale 1ns / 1ps

module sync_fifo #(parameter DEPTH = 8, DATA_WIDTH = 8)(
    input  logic       clk,
    input  logic       reset,
    input  logic       push,
    input  logic       pop,
    input  logic [7:0] data_in,
    output logic [7:0] data_out,
    output logic       full,
    output logic       empty
);

    logic [$clog2(DEPTH)-1:0] w_ptr, r_ptr;
    logic [DATA_WIDTH-1:0] queue[0:DEPTH-1];

    // FIFO Reset
    always_ff @(posedge clk) begin
        if (!reset) begin
            w_ptr    <= 0;
            r_ptr    <= 0;
            data_out <= 0;
        end
    end

    // FIFO Push
    always_ff @(posedge clk) begin
        if (push && !full) begin
            queue[w_ptr] <= data_in;
            w_ptr        <= w_ptr + 1;
        end
    end

    // FIFO Pop
    always_ff @(posedge clk) begin
        if (pop && !empty) begin
            data_out <= queue[r_ptr];
            r_ptr    <= r_ptr + 1;
        end
    end

    // Full & Empty Conditions
    assign full  = ((w_ptr + 1'b1) == r_ptr);
    assign empty = (w_ptr == r_ptr);

endmodule
