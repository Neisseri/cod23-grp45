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


module EXE_MEM_reg #(
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
    input wire [DATA_WIDTH-1:0] rs1_dat_i,
    input wire [DATA_WIDTH-1:0] rs2_dat_i,
    input wire [DATA_WIDTH-1:0] imm_dat_i,
    input wire mem_en_i,
    input wire rf_wen_i,
    input wire [3:0] sel_i,
    input wire signed_ext_i,
    input wire we_i,
    input wire [3:0] wb_if_mem_i,
    input wire csr_we_i,
    input wire [11:0] csr_adr_i,
    input wire [3:0] csr_op_i,
    input wire [3:0] env_op_i,

    output reg [4:0] rd_o,
    output reg [DATA_WIDTH-1:0] rs1_dat_o,
    output reg [DATA_WIDTH-1:0] rs2_dat_o,
    output reg [DATA_WIDTH-1:0] imm_dat_o,
    output reg mem_en_o,
    output reg rf_wen_o,
    output reg [3:0] sel_o,
    output reg signed_ext_o,
    output reg we_o,
    output reg [3:0] wb_if_mem_o,
    output reg csr_we_o,
    output reg [11:0] csr_adr_o,
    output reg [3:0] csr_op_o,
    output reg [3:0] env_op_o,

    // EXE
    input wire [DATA_WIDTH-1:0] wdata_i,
    output reg [DATA_WIDTH-1:0] wdata_o,

    // Forward Unit
    input wire use_mem_dat_a_i,
    input wire use_mem_dat_b_i,
    output reg use_mem_dat_a_o,
    output reg use_mem_dat_b_o,
    
    // exception
    input wire exception_occured_i,
    input wire [DATA_WIDTH-1:0] exception_cause_i,
    input wire [DATA_WIDTH-1:0] exception_val_i,
    output reg exception_occured_o,
    output reg [DATA_WIDTH-1:0] exception_cause_o,
    output reg [DATA_WIDTH-1:0] exception_val_o
    );

    always_ff @(posedge clk)begin
        if(rst)begin
            instr_o <= `NOP_INSTR;
            pc_o <= 0;
            rd_o <= 0;
            rs1_dat_o <= 0;
            rs2_dat_o <= 0;
            imm_dat_o <= 0;
            mem_en_o <= 0;
            we_o <= 0;
            sel_o <= 4'b0000;
            signed_ext_o <= 0;
            rf_wen_o <= 0;
            wdata_o <= 0;
            wb_if_mem_o <= 0;
            csr_we_o <= 0;
            csr_adr_o <= 0;
            csr_op_o <= 0;
            env_op_o <= 0;
            use_mem_dat_a_o <= 0;
            use_mem_dat_b_o <= 0;
            exception_occured_o <= 0;
            exception_cause_o <= 0;
            exception_val_o <= 0;
        end else begin
            if(!stall)begin
                if(bubble)begin
                    instr_o <= `NOP_INSTR;
                    pc_o <= 0;
                    rd_o <= 0;
                    rs1_dat_o <= 0;
                    rs2_dat_o <= 0;
                    imm_dat_o <= 0;
                    mem_en_o <= 0;
                    we_o <= 0;
                    sel_o <= 4'b0000;
                    signed_ext_o <= 0;
                    rf_wen_o <= 0;
                    wdata_o <= 0;
                    wb_if_mem_o <= 0;
                    csr_we_o <= 0;
                    csr_adr_o <= 0;
                    csr_op_o <= 0;
                    env_op_o <= 0;
                    use_mem_dat_a_o <= 0;
                    use_mem_dat_b_o <= 0;
                    exception_occured_o <= 0;
                    exception_cause_o <= 0;
                    exception_val_o <= 0;
                end else begin
                    instr_o <= instr_i;
                    pc_o <= pc_i;
                    rd_o <= rd_i;
                    rs1_dat_o <= rs1_dat_i;
                    rs2_dat_o <= rs2_dat_i;
                    imm_dat_o <= imm_dat_i;
                    mem_en_o <= mem_en_i;
                    we_o <= we_i;
                    sel_o <= sel_i;
                    signed_ext_o <= signed_ext_i;
                    rf_wen_o <= rf_wen_i;
                    wdata_o <= wdata_i;
                    wb_if_mem_o <= wb_if_mem_i;
                    csr_we_o <= csr_we_i;
                    csr_adr_o <= csr_adr_i;
                    csr_op_o <= csr_op_i;
                    env_op_o <= env_op_i;
                    use_mem_dat_a_o <= use_mem_dat_a_i;
                    use_mem_dat_b_o <= use_mem_dat_b_i;
                    exception_occured_o <= exception_occured_i;
                    exception_cause_o <= exception_cause_i;
                    exception_val_o <= exception_val_i;
                end
            end
        end
    end
endmodule
