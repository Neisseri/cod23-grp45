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


module Branch_comp #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
        input wire [7:0] op_type_in,
        input wire [DATA_WIDTH-1:0] data_a,
        input wire [DATA_WIDTH-1:0] data_b,
        input wire [DATA_WIDTH-1:0] imm,
        input wire [ADDR_WIDTH-1:0] pc,
        output logic comp_result,
        output logic [DATA_WIDTH-1:0] new_pc
    );
    
    typedef enum logic [7:0]{
        // RV32I Base Instruction Set
        OP_LUI,
        OP_AUIPC,
        OP_JAL,
        OP_JALR,
        OP_BEQ,
        OP_BNE,
        OP_BLT, // TODO
        OP_BGE, // TODO
        OP_BLTU, // TODO
        OP_BGEU, // TODO
        OP_LB,
        OP_LH, // TODO
        OP_LW,
        OP_LBU, // TODO
        OP_LHU, // TODO
        OP_SB,
        OP_SH, // TODO
        OP_SW,
        OP_ADDI,
        OP_SLTI, // TODO
        OP_SLTIU, // TODO
        OP_XORI, // TODO
        OP_ORI,
        OP_ANDI,
        OP_SLLI,
        OP_SRLI,
        OP_SRAI, // TODO
        OP_ADD,
        OP_SUB, // TODO
        OP_SLL, // TODO
        OP_SLT, // TODO
        OP_SLTU,
        OP_XOR,
        OP_SRL, // TODO
        OP_SRA, // TODO
        OP_OR,
        OP_AND,
        // no FENCE
        OP_ECALL,
        OP_EBREAK,
        
        // Zicsr csr instructions
        OP_CSRRW,
        OP_CSRRS,
        OP_CSRRC,
        OP_CSRRWI, // TODO
        OP_CSRRSI, // TODO
        OP_CSRRCI, // TODO

        //Zicntr instructions
        OP_RDTIME, // TODO
        OP_RDTIMEH, // TODO

        // priv instructions
        OP_MRET,
        OP_SRET, // TODO

        // our group's additional instructions
        OP_CTZ,
        OP_ANDN,
        OP_MINU,

        OP_NOP, // NOP
        OP_UNKNOWN // instruction not supported(exception)
    } OP_TYPE_T;

    OP_TYPE_T op_type;
    assign op_type = OP_TYPE_T'(op_type_in);

    //assign new_pc = imm + pc;
    always_comb begin
        case (op_type)
            OP_JALR: new_pc = (imm + data_a) & -1;
            default: new_pc = imm + pc;
        endcase
    end

    always_comb begin
        case (op_type)
            OP_BEQ: comp_result = (data_a == data_b);
            OP_BNE: comp_result = (data_a != data_b);
            OP_JAL, OP_JALR: comp_result = 1;
            default: comp_result = 0;
        endcase
    end
endmodule
