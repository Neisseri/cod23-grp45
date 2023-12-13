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


module MEM_WB_reg#(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input wire clk,
    input wire rst,
    input wire stall,
    input wire bubble,

    // IF
    input wire [DATA_WIDTH-1:0] instr_i,

    // ID
    input wire [4:0] rd_i,
    input wire rf_wen_i,
    input wire [3:0] wb_if_mem_i,

    output reg [4:0] rd_o,
    output reg rf_wen_o,
    output reg [3:0] wb_if_mem_o,

    // EXE
    input wire [DATA_WIDTH-1:0] wdata_i,
    output reg [DATA_WIDTH-1:0] wdata_o,
    
    //MEM
    input wire [DATA_WIDTH-1:0] mem_data_i,
    output reg [DATA_WIDTH-1:0] mem_data_o,
    input wire [DATA_WIDTH-1:0] mem_csr_dat_i,
    output reg [DATA_WIDTH-1:0] mem_csr_dat_o,
    input wire mem_exception_i,
    output reg wb_exception_o
    );

    always_ff @(posedge clk)begin
        if(rst)begin
            rf_wen_o <= 0;
            rd_o <= 0;
            wdata_o <= 0;
            wb_if_mem_o <= 0;
            mem_data_o <= 0;
            mem_csr_dat_o <= 0;
            wb_exception_o <= 0;
        end else begin
            if(!stall)begin
                if(bubble)begin
                    rf_wen_o <= 0;
                    rd_o <= 0;
                    wdata_o <= 0;
                    wb_if_mem_o <= 0;
                    mem_data_o <= 0;
                    mem_csr_dat_o <= 0;
                    wb_exception_o <= 0;
                end else begin
                    rf_wen_o <= rf_wen_i;
                    rd_o <= rd_i;
                    wdata_o <= wdata_i;
                    wb_if_mem_o <= wb_if_mem_i;
                    mem_data_o <= mem_data_i;
                    mem_csr_dat_o <= mem_csr_dat_i;
                    wb_exception_o <= mem_exception_i;
                end
            end
        end
    end
endmodule
