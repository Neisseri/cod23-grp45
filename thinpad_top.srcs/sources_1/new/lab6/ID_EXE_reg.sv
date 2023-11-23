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


module ID_EXE_reg #(
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
    output reg [ADDR_WIDTH-1:0] pc_o,

    // ID
    input wire [4:0] rd_i,
    input wire [4:0] rs1_i,
    input wire [4:0] rs2_i,
    input wire [DATA_WIDTH-1:0] rs1_dat_i,
    input wire [DATA_WIDTH-1:0] rs2_dat_i,
    input wire [DATA_WIDTH-1:0] imm_i,
    input wire [3:0] alu_op_i,
    input wire [1:0] alu_mux_a_i,
    input wire [1:0] alu_mux_b_i,
    input wire mem_en_i,
    input wire rf_wen_i,
    input wire [3:0] sel_i,
    input wire we_i,
    input wire wb_if_mem_i,

    output reg [4:0] rd_o,
    output reg [4:0] rs1_o,
    output reg [4:0] rs2_o,
    output reg [DATA_WIDTH-1:0] rs1_dat_o,
    output reg [DATA_WIDTH-1:0] rs2_dat_o,
    output reg [DATA_WIDTH-1:0] imm_o,
    output reg [3:0] alu_op_o,
    output reg [1:0] alu_mux_a_o,
    output reg [1:0] alu_mux_b_o,
    output reg mem_en_o,
    output reg rf_wen_o,
    output reg [3:0] sel_o,
    output reg we_o,
    output reg wb_if_mem_o
    );

    always_ff @(posedge clk)begin
        if(rst)begin
            instr_o <= `NOP_INSTR;
            pc_o <= 0;
            rd_o <= 0;
            rs1_o <= 0;
            rs2_o <= 0;
            rs1_dat_o <= 0;
            rs2_dat_o <= 0;
            imm_o <= 0;
            alu_op_o <= `ALU_ADD;
            alu_mux_a_o <= `ALU_MUX_DATA;
            alu_mux_b_o <= `ALU_MUX_DATA;
            mem_en_o <= 0;
            we_o <= 0;
            sel_o <= 4'b0000;
            rf_wen_o <= 0;
            wb_if_mem_o <= 0;
        end else begin
            if(!stall)begin
                if(bubble)begin
                    instr_o <= `NOP_INSTR;
                    pc_o <= 0;
                    rd_o <= 0;
                    rs1_o <= 0;
                    rs2_o <= 0;
                    rs1_dat_o <= 0;
                    rs2_dat_o <= 0;
                    imm_o <= 0;
                    alu_op_o <= `ALU_ADD;
                    alu_mux_a_o <= `ALU_MUX_DATA;
                    alu_mux_b_o <= `ALU_MUX_DATA;
                    mem_en_o <= 0;
                    we_o <= 0;
                    sel_o <= 4'b0000;
                    rf_wen_o <= 0;
                    wb_if_mem_o <= 0;
                end else begin
                    instr_o <= instr_i;
                    pc_o <= pc_i;
                    rd_o <= rd_i;
                    rs1_o <= rs1_i;
                    rs2_o <= rs2_i;
                    rs1_dat_o <= rs1_dat_i;
                    rs2_dat_o <= rs2_dat_i;
                    imm_o <= imm_i;
                    alu_op_o <= alu_op_i;
                    alu_mux_a_o <= alu_mux_a_i;
                    alu_mux_b_o <= alu_mux_b_i;
                    mem_en_o <= mem_en_i;
                    we_o <= we_i;
                    sel_o <= sel_i;
                    rf_wen_o <= rf_wen_i;
                    wb_if_mem_o <= wb_if_mem_i;
                end
            end
        end
    end
endmodule
