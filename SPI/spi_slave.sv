`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/10 13:30:28
// Design Name: 
// Module Name: spi_slave
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module spi_slave (
    // Global Signals
    input  logic       clk,
    input  logic       reset,
    // Internal Signals
    output logic [7:0] rx_data,
    output logic       done,
    input  logic       start,
    input  logic [7:0] tx_data,
    output logic       ready,
    // External Signals
    input  logic       SCLK,
    input  logic       MOSI,
    output logic       MISO,
    input  logic       CS
);

    // Synchronizer = DFF + Edge Detector
    logic sclk_sync0, sclk_sync1;
    logic sclk_pos, sclk_neg;

    assign sclk_pos = sclk_sync0 & ~sclk_sync1;
    assign sclk_neg = ~sclk_sync0 & sclk_sync1;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            sclk_sync0 <= 1'b0;
            sclk_sync1 <= 1'b0;
        end else begin
            sclk_sync0 <= SCLK;
            sclk_sync1 <= sclk_sync0;
        end
    end

    // Slave Receive(SI) FSM
    typedef enum {
        IDLE_SI,
        PHASE_SI
    } spi_state_si;
    spi_state_si state, state_next;

    logic [7:0] rx_data_reg, rx_data_next;
    logic done_reg, done_next;
    logic [2:0] bit_cnt_reg, bit_cnt_next;

    assign rx_data = rx_data_reg;
    assign done = done_reg;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state       <= IDLE_SI;
            rx_data_reg <= 8'h00;
            done_reg    <= 1'b0;
            bit_cnt_reg <= 3'b000;
        end else begin
            state <= state_next;
            rx_data_reg <= rx_data_next;
            done_reg    <= done_next;
            bit_cnt_reg <= bit_cnt_next;
        end
    end

    always_comb begin
        state_next   = state;
        rx_data_next = rx_data_reg;
        done_next    = done_reg;
        bit_cnt_next = bit_cnt_reg;
        case (state)
            IDLE_SI: begin
                done_next = 1'b0;
                if (!CS) begin
                    state_next = PHASE_SI;
                end
            end
            PHASE_SI: begin
                if (!CS) begin
                    if (sclk_pos) begin
                        rx_data_next = {rx_data_reg[6:0], MOSI};
                        if (bit_cnt_reg == 8 - 1) begin
                            state_next = IDLE_SI;
                            done_next = 1'b1;
                            bit_cnt_next = 0;
                        end else begin
                            bit_cnt_next = bit_cnt_reg + 1;
                        end
                    end
                end else begin
                    state_next = IDLE_SI;
                end
            end
        endcase
    end

    // Slave Transmit(SO) FSM
    typedef enum {
        IDLE_SO,
        PHASE_SO
    } spi_state_so;
    spi_state_so state_so, state_next_so;

    logic [7:0] tx_data_reg, tx_data_next;
    logic ready_reg, ready_next;
    logic [2:0] bit_cnt_reg_so, bit_cnt_next_so;

    assign MISO = CS ? 1'bz : tx_data_reg[7];
    assign ready = ready_reg;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state_so       <= IDLE_SO;
            tx_data_reg    <= 8'h00;
            ready_reg      <= 1'b0;
            bit_cnt_reg_so <= 3'b000;
        end else begin
            state_so       <= state_next_so;
            tx_data_reg    <= tx_data_next;
            ready_reg      <= ready_next;
            bit_cnt_reg_so <= bit_cnt_next_so;
        end
    end

    always_comb begin
        state_next_so   = state_so;
        tx_data_next    = tx_data_reg;
        ready_next      = ready_reg;
        bit_cnt_next_so = bit_cnt_reg_so;
        case (state_so)
            IDLE_SO: begin
                ready_next   = 1'b0;
                if (!CS) begin
                    ready_next = 1'b1;
                    if (start) begin
                        state_next_so   = PHASE_SO;
                        tx_data_next    = tx_data;
                        bit_cnt_next_so = 0;
                    end
                end
            end
            PHASE_SO: begin
                if (!CS) begin
                    if (sclk_neg) begin
                        tx_data_next = {tx_data_reg[6:0], 1'b0};
                        if (bit_cnt_reg_so == 8 - 1) begin
                            state_next_so   = IDLE_SO;
                            bit_cnt_next_so = 0;
                            ready_next      = 1'b0;
                        end else begin
                            bit_cnt_next_so = bit_cnt_reg_so + 1;
                        end
                    end
                end else begin
                    state_next_so = IDLE_SO;
                end
            end
        endcase
    end
endmodule
