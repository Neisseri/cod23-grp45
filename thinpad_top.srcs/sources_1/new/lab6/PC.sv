`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/11/19 09:26:54
// Design Name: 
// Module Name: IF_IM_reg
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

module PC#(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input wire clk,
    input wire rst,
    input wire [ADDR_WIDTH-1:0] next_pc,
    output reg [ADDR_WIDTH-1:0] addr
    );

    always_ff @(posedge  clk) begin
        if(rst)begin
            addr <= 32'h7fff_fffc;
        end else begin
            addr <= next_pc;
        end
    end

endmodule
