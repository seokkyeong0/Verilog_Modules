`timescale 1ns / 1ps

module uart_rx(
    input  logic       clk      ,
    input  logic       rst      ,
    input  logic       baud     ,
    input  logic       rx_in    ,
    output logic [7:0] rx_data  ,
    output logic       rx_done  ,
    output logic       rx_busy  
    );

    // state parameter
    localparam [1:0] IDLE = 0, START = 1, DATA = 2, STOP = 3;

    // state register
    logic [1:0] state_reg, state_next;

    // output register
    logic [7:0] rx_reg, rx_next;
    logic rd_reg, rd_next;
    logic rb_reg, rb_next;

    // count register
    logic [3:0] tc_reg, tc_next;
    logic [2:0] bc_reg, bc_next;

    // assign output
    assign rx_data = rx_reg;
    assign rx_done = rd_reg;
    assign rx_busy = rb_reg;

    // sequential logic
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            state_reg <= IDLE;
            rx_reg <= 8'h00;
            rd_reg <= 1'b0;
            rb_reg <= 1'b0;
            tc_reg <= 0;
            bc_reg <= 0;
        end else begin
            state_reg <= state_next;
            rx_reg <= rx_next;
            rd_reg <= rd_next;
            rb_reg <= rb_next;
            tc_reg <= tc_next;
            bc_reg <= bc_next;
        end
    end

    // combinational logic
    always_comb begin
        state_next = state_reg;
        rx_next = rx_reg;
        rd_next = rd_reg;
        rb_next = rb_reg;
        tc_next = tc_reg;
        bc_next = bc_reg;
        case (state_reg)
            IDLE: begin
                rd_next = 1'b0;
                rb_next = 1'b0;
                tc_next = 0;
                bc_next = 0;
                if (!rx_in) begin
                    state_next = START;
                    rb_next = 1'b1;
                end
            end 
            START: begin
                if (baud) begin
                    if (tc_reg == 7) begin
                        state_next = DATA;
                        tc_next = 0;
                    end else begin
                        tc_next = tc_reg + 1;
                    end
                end
            end 
            DATA: begin
                if (baud) begin
                    if (tc_reg == 15) begin
                        rx_next = {rx_in, rx_reg[7:1]};
                        tc_next = 0;
                        if (bc_reg == 7) begin
                            state_next = STOP;
                            tc_next = 0;
                            bc_next = 0;
                        end else begin
                            bc_next = bc_reg + 1;
                        end
                    end else begin
                        tc_next = tc_reg + 1;
                    end
                end
            end 
            STOP: begin
                if (baud) begin
                    if (tc_reg == 15) begin
                        state_next = IDLE;
                        rd_next = 1'b1;
                        rb_next = 1'b0;
                        tc_next = 0;
                    end else begin
                        tc_next = tc_reg + 1;
                    end
                end
            end 
        endcase
    end
endmodule
