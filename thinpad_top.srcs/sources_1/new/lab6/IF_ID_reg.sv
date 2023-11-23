`timescale 1ns / 1ps
`include "../header/opcode.sv"
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


module IF_ID_reg #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input wire clk,
    input wire rst,
    input wire stall,
    input wire bubble,

    // IF
    input wire [DATA_WIDTH-1:0] instr_i,
    output reg [DATA_WIDTH-1:0] instr_o,
    input wire [ADDR_WIDTH-1:0] pc_i,
    output reg [ADDR_WIDTH-1:0] pc_o
    );

    always_ff @(posedge clk)begin
        if(rst)begin
            instr_o <= `NOP_INSTR;
            pc_o <= 0;
        end else begin
            if(!stall)begin
                if(bubble)begin
                    instr_o <= `NOP_INSTR;
                    pc_o <= 0;
                end else begin
                    instr_o <= instr_i;
                    pc_o <= pc_i;
                end
            end
        end
    end
endmodule
