`timescale 1ns / 1ps

module uart_tx(
    input  logic       clk      ,
    input  logic       rst      ,
    input  logic       baud     ,
    input  logic       tx_start ,
    input  logic [7:0] tx_data  ,
    output logic       tx_out   ,
    output logic       tx_done  ,
    output logic       tx_busy  
    );

    // state parameter
    localparam [1:0] IDLE = 0, START = 1, DATA = 2, STOP = 3;

    // state register
    logic [1:0] state_reg, state_next;

    // data register
    logic [7:0] db_reg, db_next;

    // output register
    logic tx_reg, tx_next;
    logic td_reg, td_next;
    logic tb_reg, tb_next;

    // count register
    logic [3:0] tc_reg, tc_next;
    logic [2:0] bc_reg, bc_next;

    // assign output
    assign tx_out  = tx_reg;
    assign tx_done = td_reg;
    assign tx_busy = tb_reg;

    // sequential logic
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            state_reg <= IDLE;
            db_reg <= 8'h00;
            tx_reg <= 1'b1;
            td_reg <= 1'b0;
            tb_reg <= 1'b0;
            tc_reg <= 0;
            bc_reg <= 0;
        end else begin
            state_reg <= state_next;
            db_reg <= db_next;
            tx_reg <= tx_next;
            td_reg <= td_next;
            tb_reg <= tb_next;
            tc_reg <= tc_next;
            bc_reg <= bc_next;
        end
    end

    // combinational logic
    always_comb begin
        state_next = state_reg;
        db_next = db_reg;
        tx_next = tx_reg;
        td_next = td_reg;
        tb_next = tb_reg;
        tc_next = tc_reg;
        bc_next = bc_reg;

        case (state_reg)
            IDLE: begin
                db_next = 8'h00;
                tx_next = 1'b1;
                td_next = 1'b0;
                tb_next = 1'b0;
                tc_next = 0;
                bc_next = 0;
                if (tx_start) begin
                    db_next = tx_data;
                    state_next = START;
                end
            end 
            START: begin
                tx_next = 1'b0;
                tb_next = 1'b1;
                if (baud) begin
                    if (tc_reg == 15) begin
                        state_next = DATA;
                        tc_next = 0;
                    end begin
                        tc_next = tc_reg + 1;
                    end
                end
            end 
            DATA: begin
                tx_next = db_reg[0];
                if (baud) begin
                    if (tc_reg == 15) begin
                        if (bc_reg == 7) begin
                            state_next = STOP;
                            tc_next = 0;
                            bc_next = 0;
                        end else begin
                            db_next = db_reg >> 1;
                            bc_next = bc_reg + 1;
                            tc_next = 0;
                        end
                    end begin
                        tc_next = tc_reg + 1;
                    end
                end
            end 
            STOP: begin
                tx_next = 1'b1;
                if (baud) begin
                    if (tc_reg == 15) begin
                        state_next = IDLE;
                        tx_next = 1'b1;
                        td_next = 1'b1;
                        tb_next = 1'b0;
                        tc_next = 0;
                    end begin
                        tc_next = tc_reg + 1;
                    end
                end
            end 
        endcase
    end

endmodule
