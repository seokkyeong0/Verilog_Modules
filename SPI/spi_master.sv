`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/10 11:16:18
// Design Name: 
// Module Name: spi_master
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


module spi_master (
    // Global Signals
    input  logic       clk,
    input  logic       reset,
    // Internal Signals
    input  logic       CPOL,
    input  logic       CPHA,
    input  logic       start,
    input  logic [7:0] tx_data,
    output logic [7:0] rx_data,
    output logic       tx_ready,
    output logic       done,
    // External Signals
    output logic       SCLK,
    output logic       MOSI,
    input  logic       MISO
);

    // Define States
    typedef enum {
        IDLE,
        CP0,
        CP1,
        CP_DELAY
    } spi_state_m;
    spi_state_m state, state_next;

    // Registers
    logic p_clk, sclk_reg, sclk_next;
    logic done_reg, done_next;
    logic tx_ready_reg, tx_ready_next;
    logic [7:0] tx_data_reg, tx_data_next;
    logic [7:0] rx_data_reg, rx_data_next;
    logic [$clog2(50)-1:0] sclk_cnt_reg, sclk_cnt_next;
    logic [$clog2(8)-1:0] bit_cnt_reg, bit_cnt_next;

    // Outputs
    assign rx_data  = rx_data_reg;
    assign tx_ready = tx_ready_reg;
    assign done     = done_reg;
    assign MOSI     = tx_data_reg[7];
    assign SCLK     = sclk_reg;

    // Assign SCLK
    assign p_clk = ((state_next == CP0) && (CPHA == 1)) || 
                   ((state_next == CP1) && (CPHA == 0));
    assign sclk_next = CPOL ? ~p_clk : p_clk;
    assign SCLK = sclk_reg;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state        <= IDLE;
            sclk_reg     <= 1'b0;
            done_reg     <= 1'b0;
            tx_ready_reg <= 1'b1;
            tx_data_reg  <= 8'h00;
            rx_data_reg  <= 8'h00;
            sclk_cnt_reg <= 0;
            bit_cnt_reg  <= 0;
        end else begin
            state        <= state_next;
            sclk_reg     <= sclk_next;
            done_reg     <= done_next;
            tx_ready_reg <= tx_ready_next;
            tx_data_reg  <= tx_data_next;
            rx_data_reg  <= rx_data_next;
            sclk_cnt_reg <= sclk_cnt_next;
            bit_cnt_reg  <= bit_cnt_next;
        end
    end

    always_comb begin
        state_next    = state;
        done_next     = done_reg;
        tx_ready_next = tx_ready_reg;
        tx_data_next  = tx_data_reg;
        rx_data_next  = rx_data_reg;
        sclk_cnt_next = sclk_cnt_reg;
        bit_cnt_next  = bit_cnt_reg;
        case (state)
            IDLE: begin
                done_next     = 1'b0;
                tx_ready_next = 1'b1;
                sclk_cnt_next = 0;
                bit_cnt_next  = 0;
                if (start) begin
                    state_next = CPHA ? CP_DELAY : CP0;
                    tx_data_next = tx_data;
                end
            end
            CP0: begin
                if (sclk_cnt_reg == 50 - 1) begin
                    state_next = CP1;
                    sclk_cnt_next = 0;
                    rx_data_next = {rx_data_reg[6:0], MISO};
                end else begin
                    sclk_cnt_next = sclk_cnt_reg + 1;
                end
            end
            CP1: begin
                if (sclk_cnt_reg == 50 - 1) begin
                    sclk_cnt_next = 0;
                    if (bit_cnt_reg == 8 - 1) begin
                        state_next   = CPHA ? IDLE : CP_DELAY;
                        done_next    = CPHA ? 1'b1 : 1'b0;
                        bit_cnt_next = 0;
                    end else begin
                        state_next = CP0;
                        bit_cnt_next = bit_cnt_reg + 1;
                        tx_data_next = {tx_data_reg[6:0], 1'b0};
                    end
                end else begin
                    sclk_cnt_next = sclk_cnt_reg + 1;
                end
            end
            CP_DELAY: begin
                if (sclk_cnt_reg == 50 - 1) begin
                    sclk_cnt_next = 0;
                    state_next = CPHA ? CP0 : IDLE;
                    done_next  = CPHA ? 1'b0 : 1'b1;
                end else begin
                    sclk_cnt_next = sclk_cnt_reg + 1;
                end
            end
        endcase
    end
endmodule
