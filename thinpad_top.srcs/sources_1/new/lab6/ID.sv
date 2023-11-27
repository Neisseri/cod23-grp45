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
        output logic [2:0] alu_mux_a,
        output logic [2:0] alu_mux_b,

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

        OP_AND,
        OP_AUIPC,
        OP_BNE,
        OP_JAL,
        OP_JALR,
        OP_LW,
        OP_OR,
        OP_ORI,
        OP_SLLI,
        OP_SRLI,
        OP_XOR,

        OP_CTZ,
        OP_ANDN,
        OP_MINU,

        OP_NOP,
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
                    10'b0000000_111: op_type = OP_AND;
                    10'b0000000_110: op_type = OP_OR;
                    10'b0000000_100: op_type = OP_XOR;
                    10'b0000101_110: op_type = OP_MINU;
                    10'b0100000_111: op_type = OP_ANDN;
                    default: op_type = OP_UNKNOWN;
                endcase
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = instr[24:20];
            end 
            7'b0010011: begin // I-type-Compute
                case (funct3)
                    3'b000: begin
                        if(instr == `NOP_INSTR)begin
                            op_type = OP_NOP;
                        end else begin
                            op_type = OP_ADDI;
                        end
                    end
                    3'b111: op_type = OP_ANDI;
                    3'b110: op_type = OP_ORI;
                    3'b001: op_type = OP_SLLI;
                    3'b101: op_type = OP_SRLI;
                    3'b001: op_type = OP_CTZ;
                    default: op_type = OP_UNKNOWN;
                endcase
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = 0;
            end
            7'b0000011: begin // I-type-Load
                case (funct3)
                    3'b000: op_type = OP_LB; 
                    3'b010: op_type = OP_LW;
                    default: op_type = OP_UNKNOWN;
                endcase
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = 0;
            end
            7'b1100111: begin // JALR
                case (funct3)
                    3'b000: op_type = OP_JALR; 
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
                    3'b001: op_type = OP_BNE;
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
            7'b0010111: begin // AUIPC
                op_type = OP_AUIPC;
                rd = instr[11:7];
                rs1 = 0;
                rs2 = 0;
            end
            7'b1101111: begin // JAL
                op_type = OP_JAL;
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
            OP_LUI, OP_AUIPC: begin // U-type
                imm = {instr[31:12], 12'b0};
            end
            OP_BEQ, OP_BNE: begin // B-type
                imm = {{19{sign_bit}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            end
            OP_LB, OP_ADDI, OP_ANDI, OP_JALR, OP_LW, OP_ORI, OP_SLLI, OP_SRLI: begin  // I-type
                imm = {{20{sign_bit}}, instr[31:20]};
            end
            OP_SB, OP_SW: begin // S-type
                imm = {{20{sign_bit}}, instr[31:25], instr[11:7]};
            end
            OP_JAL: begin // J-type
                imm = {{11{sign_bit}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
            end
            default: begin  // unknown or no need of imm
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
            OP_AND: begin
                alu_op = `ALU_AND;
                alu_mux_a = `ALU_MUX_DATA;
                alu_mux_b = `ALU_MUX_DATA;
                mem_en = 0;
                we = 0;
                sel = 4'b0000;
                rf_wen = 1;
                wb_if_mem = 0;
            end
            OP_AUIPC: begin
                alu_op = `ALU_ADD;
                alu_mux_a = `ALU_MUX_PC_A;
                alu_mux_b = `ALU_MUX_IMM_B;
                mem_en = 0;
                we = 0;
                sel = 4'b0000;
                rf_wen = 1;
                wb_if_mem = 0;
            end
            OP_BNE: begin
                alu_op = `ALU_ADD;
                alu_mux_a = `ALU_MUX_PC_A;
                alu_mux_b = `ALU_MUX_IMM_B;
                mem_en = 0;
                we = 0;
                sel = 4'b0000;
                rf_wen = 0;
                wb_if_mem = 0;
            end
            OP_JAL: begin
                alu_op = `ALU_ADD;
                alu_mux_a = `ALU_MUX_PC_A;
                alu_mux_b = `ALU_MUX_FOUR_B;
                mem_en = 0;
                we = 0;
                sel = 4'b0000;
                rf_wen = 1;
                wb_if_mem = 0;
            end
            OP_JALR: begin
                alu_op = `ALU_ADD;
                alu_mux_a = `ALU_MUX_PC_A;
                alu_mux_b = `ALU_MUX_FOUR_B;
                mem_en = 0;
                we = 0;
                sel = 4'b0000;
                rf_wen = 1;
                wb_if_mem = 0;
            end
            OP_LW: begin
                alu_op = `ALU_ADD;
                alu_mux_a = `ALU_MUX_DATA;
                alu_mux_b = `ALU_MUX_IMM_B;
                mem_en = 1;
                we = 0;
                sel = 4'b1111;
                rf_wen = 1;
                wb_if_mem = 1;
            end
            OP_OR: begin
                alu_op = `ALU_OR;
                alu_mux_a = `ALU_MUX_DATA;
                alu_mux_b = `ALU_MUX_DATA;
                mem_en = 0;
                we = 0;
                sel = 4'b0000;
                rf_wen = 1;
                wb_if_mem = 0;
            end
            OP_ORI: begin
                alu_op = `ALU_OR;
                alu_mux_a = `ALU_MUX_DATA;
                alu_mux_b = `ALU_MUX_IMM_B;
                mem_en = 0;
                we = 0;
                sel = 4'b0000;
                rf_wen = 1;
                wb_if_mem = 0;
            end
            OP_SLLI: begin
                alu_op = `ALU_LOGIC_LEFT;
                alu_mux_a = `ALU_MUX_DATA;
                alu_mux_b = `ALU_MUX_IMM_B;
                mem_en = 0;
                we = 0;
                sel = 4'b0000;
                rf_wen = 1;
                wb_if_mem = 0;
            end
            OP_SRLI: begin
                alu_op = `ALU_LOGIC_RIGHT;
                alu_mux_a = `ALU_MUX_DATA;
                alu_mux_b = `ALU_MUX_IMM_B;
                mem_en = 0;
                we = 0;
                sel = 4'b0000;
                rf_wen = 1;
                wb_if_mem = 0;
            end
            OP_XOR: begin
                alu_op = `ALU_XOR;
                alu_mux_a = `ALU_MUX_DATA;
                alu_mux_b = `ALU_MUX_DATA;
                mem_en = 0;
                we = 0;
                sel = 4'b0000;
                rf_wen = 1;
                wb_if_mem = 0;
            end
            OP_CTZ: begin
                alu_op = `ALU_CTZ;
                alu_mux_a = `ALU_MUX_DATA;
                alu_mux_b = `ALU_MUX_DATA;
                mem_en = 0;
                we = 0;
                sel = 4'b0000;
                rf_wen = 1;
                wb_if_mem = 0;
            end
            OP_ANDN: begin
                alu_op = `ALU_ANDN;
                alu_mux_a = `ALU_MUX_DATA;
                alu_mux_b = `ALU_MUX_DATA;
                mem_en = 0;
                we = 0;
                sel = 4'b0000;
                rf_wen = 1;
                wb_if_mem = 0;
            end
            OP_MINU: begin
                alu_op = `ALU_MINU;
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
