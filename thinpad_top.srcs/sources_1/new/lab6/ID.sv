`timescale 1ns / 1ps
`include "../header/opcode.sv"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/11/19 10:08:09
// Design Name: 
// Module Name: ID
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


module ID(
        input wire [31:0] instr,
        output logic [4:0] rd,
        output logic [4:0] rs1,
        output logic [4:0] rs2,
        output logic [31:0] imm,
        output logic [7:0] op_type_out, // for branch comp

        output logic [3:0] alu_op,
        output logic [1:0] alu_mux_a,
        output logic [1:0] alu_mux_b,

        output logic mem_en,
        output logic we,
        output logic [3:0] sel,

        output logic rf_wen,
        output logic wb_if_mem
    );

    logic [2:0] funct3;
    logic [6:0] opcode;
    logic [6:0] funct7;

    always_comb begin
        opcode = instr[6:0];
        funct3 = instr[14:12];
        funct7 = instr[31:25];
    end
    
    typedef enum logic [7:0]{
        OP_LUI,
        OP_BEQ,
        OP_LB,
        OP_SB,
        OP_SW,
        OP_ADDI,
        OP_ANDI,
        OP_ADD,
        OP_UNKNOWN
    } OP_TYPE_T;

    OP_TYPE_T op_type;
    assign op_type_out = op_type;

    logic [9:0] funct;
    assign funct = {funct7, funct3};

    always_comb begin
        case (opcode)
            7'b0110011: begin // R-type
                case (funct)
                    10'b0000000_000: op_type = OP_ADD;
                    default: op_type = OP_UNKNOWN;
                endcase
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
            end 
            7'b0010011: begin // I-type
                case (funct3)
                    3'b000: op_type = OP_ADDI; 
                    3'b111: op_type = OP_ANDI;
                    default: op_type = OP_UNKNOWN;
                endcase
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = 0;
            end
            7'b0000011: begin // I-type
                case (funct3)
                    3'b000: op_type = OP_LB; 
                    default: op_type = OP_UNKNOWN;
                endcase
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = 0;
            end
            7'b0100011: begin // S-type
                case (funct3)
                    3'b000: op_type = OP_SB;
                    3'b010: op_type = OP_SW;
                    default: op_type = OP_UNKNOWN;
                endcase
                rd = 0;
                rs1 = instr[19:15];
                rs2 = instr[24:20];
            end
            7'b1100011: begin // B-type
                case (funct3)
                    3'b000: op_type = OP_BEQ; 
                    default: op_type = OP_UNKNOWN;
                endcase
                rd = 0;
                rs1 = instr[19:15];
                rs2 = instr[24:20];
            end
            7'b0110111: begin // U-type
                op_type = OP_LUI;
                rd = instr[11:7];
                rs1 = 0;
                rs2 = 0;
            end
            default: begin
                op_type = OP_UNKNOWN;
                rd = 0;
                rs1 = 0;
                rs2 = 0;
            end
        endcase
    end

    logic sign_bit;
    assign sign_bit = instr[31];

    // imm-gen
    always_comb begin
        case (op_type)
            OP_LUI: begin
                imm = {instr[31:12], 12'b0};
            end
            OP_BEQ: begin
                imm = {{19{sign_bit}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            end
            OP_LB, OP_ADDI, OP_ANDI: begin
                imm = {{20{sign_bit}}, instr[31:20]};
            end
            OP_SB, OP_SW: begin
                imm = {{20{sign_bit}}, instr[31:25], instr[11:7]};
            end
            default: begin
                imm = 0;
            end
        endcase
    end

    //signal-gen
    always_comb begin
        case (op_type)
            OP_LUI: begin
                alu_op = `ALU_ADD;
                alu_mux_a = `ALU_MUX_ZERO;
                alu_mux_b = `ALU_MUX_IMM_B;
                mem_en = 0;
                we = 0;
                sel = 4'b0000;
                rf_wen = 1;
                wb_if_mem = 0;
            end
            OP_BEQ: begin
                alu_op = `ALU_ADD;
                alu_mux_a = `ALU_MUX_PC_A;
                alu_mux_b = `ALU_MUX_IMM_B;
                mem_en = 0;
                we = 0;
                sel = 4'b0000;
                rf_wen = 0;
                wb_if_mem = 0;
            end
            OP_LB: begin
                alu_op = `ALU_ADD;
                alu_mux_a = `ALU_MUX_DATA;
                alu_mux_b = `ALU_MUX_IMM_B;
                mem_en = 1;
                we = 0;
                sel = 4'b0001;
                rf_wen = 1;
                wb_if_mem = 1;
            end
            OP_SB: begin
                alu_op = `ALU_ADD;
                alu_mux_a = `ALU_MUX_DATA;
                alu_mux_b = `ALU_MUX_IMM_B;
                mem_en = 1;
                we = 1;
                sel = 4'b0001;
                rf_wen = 0;
                wb_if_mem = 0;
            end
            OP_SW: begin
                alu_op = `ALU_ADD;
                alu_mux_a = `ALU_MUX_DATA;
                alu_mux_b = `ALU_MUX_IMM_B;
                mem_en = 1;
                we = 1;
                sel = 4'b1111;
                rf_wen = 0;
                wb_if_mem = 0;
            end
            OP_ADDI: begin
                alu_op = `ALU_ADD;
                alu_mux_a = `ALU_MUX_DATA;
                alu_mux_b = `ALU_MUX_IMM_B;
                mem_en = 0;
                we = 0;
                sel = 4'b0000;
                rf_wen = 1;
                wb_if_mem = 0;
            end
            OP_ANDI: begin
                alu_op = `ALU_AND;
                alu_mux_a = `ALU_MUX_DATA;
                alu_mux_b = `ALU_MUX_IMM_B;
                mem_en = 0;
                we = 0;
                sel = 4'b0000;
                rf_wen = 1;
                wb_if_mem = 0;
            end
            OP_ADD: begin
                alu_op = `ALU_ADD;
                alu_mux_a = `ALU_MUX_DATA;
                alu_mux_b = `ALU_MUX_DATA;
                mem_en = 0;
                we = 0;
                sel = 4'b0000;
                rf_wen = 1;
                wb_if_mem = 0;
            end
            default: begin // NOP: addi zero, zero, 0
                alu_op = `ALU_ADD;
                alu_mux_a = `ALU_MUX_DATA;
                alu_mux_b = `ALU_MUX_IMM_B;
                mem_en = 0;
                we = 0;
                sel = 4'b0000;
                rf_wen = 1;
                wb_if_mem = 0;
            end
        endcase
    end

endmodule
