`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/06 23:01:35
// Design Name: 
// Module Name: edge_detector
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


module edge_detector(
    input  clk      ,
    input  sig_in   ,
    output edge_out 
    );

    // signal register
    reg sig_reg;

    // dualedge detect
    assign edge_out = sig_in ^ sig_reg;

    // posedge detect
    //assign edge_out = sig_in & ~sig_reg;

    // negedge detect
    //assign edge_out = ~sig_in & sig_reg;

    // store prev clk value
    always @(posedge clk) begin
        sig_reg <= sig_in;
    end
endmodule
