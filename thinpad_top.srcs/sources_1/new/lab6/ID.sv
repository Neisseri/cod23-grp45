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

        output logic [5:0] alu_op,
        output logic [2:0] alu_mux_a,
        output logic [2:0] alu_mux_b,

        output logic mem_en,
        output logic we,
        output logic [3:0] sel,
        output logic signed_ext, // load instr: if signed extension

        output logic rf_wen,
        output logic [3:0] wb_if_mem,

        output logic id_exception_o,

        output logic csr_we_o,
        output logic [11:0] csr_adr_o,
        output logic [3:0] csr_op_o,

        output logic exception_occured_o,
        output logic [31:0] exception_cause_o
    );

    logic [2:0] funct3;
    logic [6:0] opcode;
    logic [6:0] funct7;
    logic [11:0] funct12;

    always_comb begin
        opcode = instr[6:0];
        funct3 = instr[14:12];
        funct7 = instr[31:25];
        funct12 = instr[31:20];
    end
    
    typedef enum logic [7:0]{
        // RV32I Base Instruction Set
        OP_LUI,
        OP_AUIPC,
        OP_JAL,
        OP_JALR,
        OP_BEQ,
        OP_BNE,
        OP_BLT, // branch less than
        OP_BGE, // TODO: test
        OP_BLTU, // TODO: test
        OP_BGEU, // TODO: test
        OP_LB,
        OP_LH, // TODO: test
        OP_LW,
        OP_LBU, // TODO: test
        OP_LHU, // TODO: test
        OP_SB,
        OP_SH, // TODO: test
        OP_SW,
        OP_ADDI,
        OP_SLTI, // TODO： test
        OP_SLTIU, // TODO: test
        OP_XORI, // TODO: test
        OP_ORI,
        OP_ANDI,
        OP_SLLI,
        OP_SRLI,
        OP_SRAI, // TODO: test
        OP_ADD,
        OP_SUB, // TODO: test
        OP_SLL, // TODO: test
        OP_SLT, // TODO: test
        OP_SLTU,
        OP_XOR,
        OP_SRL, // TODO: test
        OP_SRA, // TODO: test
        OP_OR,
        OP_AND,
        // no FENCE
        OP_ECALL,
        OP_EBREAK,
        
        // Zicsr csr instructions
        OP_CSRRW,
        OP_CSRRS,
        OP_CSRRC,
        OP_CSRRWI, // TODO:--------------------------------------------------------↑
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
    assign op_type_out = op_type;

    logic [9:0] funct;
    assign funct = {funct7, funct3};

    always_comb begin
        csr_adr_o = 0;
        op_type = OP_UNKNOWN;
        case (opcode)
            7'b0110011: begin // R-type
                case (funct)
                    10'b0000000_000: op_type = OP_ADD;
                    10'b0100000_000: op_type = OP_SUB;
                    10'b0000000_111: op_type = OP_AND;
                    10'b0000000_110: op_type = OP_OR;
                    10'b0000000_100: op_type = OP_XOR;
                    10'b0000000_101: op_type = OP_SRL;
                    10'b0100000_101: op_type = OP_SRA;
                    10'b0000101_110: op_type = OP_MINU;
                    10'b0100000_111: op_type = OP_ANDN;
                    10'b0000000_001: op_type = OP_SLL;
                    10'b0000000_010: op_type = OP_SLT;
                    10'b0000000_011: op_type = OP_SLTU;
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
                    3'b010: op_type = OP_SLTI;
                    3'b011: op_type = OP_SLTIU;
                    3'b100: op_type = OP_XORI;
                    3'b111: op_type = OP_ANDI;
                    3'b110: op_type = OP_ORI;
                    3'b001: begin
                        if(funct7 == 7'b0110000)begin
                            op_type = OP_CTZ;
                        end else begin
                            op_type = OP_SLLI;
                        end
                    end
                    3'b101: begin
                        if (funct7 == 7'b0000000) begin
                            op_type = OP_SRLI;
                        end else if (funct7 == 7'b0100000) begin
                            op_type = OP_SRAI;
                        end
                    end
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
                    3'b001: op_type = OP_LH;
                    3'b100: op_type = OP_LBU;
                    3'b101: op_type = OP_LHU;
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
                    3'b001: op_type = OP_SH;
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
                    3'b100: op_type = OP_BLT;
                    3'b101: op_type = OP_BGE;
                    3'b110: op_type = OP_BLTU;
                    3'b111: op_type = OP_BGEU;
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
            7'b1110011: begin // SYSTEM(CSR)
                case(funct3)
                    3'b011: begin // CSRRC
                        op_type = OP_CSRRC;
                    end
                    3'b010: begin // CSRRS
                        op_type = OP_CSRRS;
                    end
                    3'b001: begin // CSRRW
                        op_type = OP_CSRRW;
                    end
                    3'b000: begin // PRIV
                        case(funct12)
                            12'b000000000001: begin // EBREAK
                                op_type = OP_EBREAK;
                            end
                            12'b000000000000: begin // ECALL
                                op_type = OP_ECALL;
                            end
                            12'b001100000010: begin // MRET
                                op_type = OP_MRET;
                            end
                            default: op_type = OP_UNKNOWN;
                        endcase
                    end
                    default: op_type = OP_UNKNOWN;
                endcase
                rd = instr[11:7];
                rs1 = instr[19:15];
                rs2 = 0;
                csr_adr_o = instr[31:20];
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
            OP_BEQ, OP_BNE, OP_BLT, OP_BGE, OP_BLTU, OP_BGEU: begin // B-type
                imm = {{19{sign_bit}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            end
            OP_LB, OP_ADDI, OP_ANDI, OP_JALR, OP_LW, OP_ORI, OP_SLLI, OP_SRLI, OP_SRAI, OP_LH, OP_LBU, OP_LHU, OP_SLTI, OP_SLTIU, OP_XORI: begin  // I-type
                imm = {{20{sign_bit}}, instr[31:20]};
            end
            OP_SB, OP_SW, OP_SH: begin // S-type
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
        csr_we_o = 0;
        csr_op_o = 0;
        id_exception_o = 0;
        exception_occured_o = 0;
        exception_cause_o = 0;
        signed_ext = 0;
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
                signed_ext = 1;
                rf_wen = 1;
                wb_if_mem = 1;
            end
            OP_LW: begin
                alu_op = `ALU_ADD;
                alu_mux_a = `ALU_MUX_DATA;
                alu_mux_b = `ALU_MUX_IMM_B;
                mem_en = 1;
                we = 0;
                sel = 4'b1111;
                signed_ext = 1;
                rf_wen = 1;
                wb_if_mem = 1;
            end
            OP_LH: begin
                alu_op = `ALU_ADD;
                alu_mux_a = `ALU_MUX_DATA;
                alu_mux_b = `ALU_MUX_IMM_B;
                mem_en = 1;
                we = 0;
                sel = 4'b0011;
                signed_ext = 1;
                rf_wen = 1;
                wb_if_mem = 1;
            end
            OP_LBU: begin
                alu_op = `ALU_ADD;
                alu_mux_a = `ALU_MUX_DATA;
                alu_mux_b = `ALU_MUX_IMM_B; 
                mem_en = 1;
                we = 0;
                sel = 4'b0001;
                signed_ext = 0;
                rf_wen = 1;
                wb_if_mem = 1;
            end
            OP_LHU: begin
                alu_op = `ALU_ADD;
                alu_mux_a = `ALU_MUX_DATA;
                alu_mux_b = `ALU_MUX_IMM_B; 
                mem_en = 1;
                we = 0;
                sel = 4'b0011;
                signed_ext = 0;
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
            OP_SH: begin
                alu_op = `ALU_ADD;
                alu_mux_a = `ALU_MUX_DATA;
                alu_mux_b = `ALU_MUX_IMM_B;
                mem_en = 1;
                we = 1;
                sel = 4'b0011;
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
            OP_SLTI: begin
                alu_op = `ALU_SLT;
                alu_mux_a = `ALU_MUX_DATA;
                alu_mux_b = `ALU_MUX_IMM_B;
                mem_en = 0;
                we = 0;
                sel = 4'b0000;
                rf_wen = 1;
                wb_if_mem = 0;
            end
            OP_SLTIU: begin
                alu_op = `ALU_SLTU;
                alu_mux_a = `ALU_MUX_DATA;
                alu_mux_b = `ALU_MUX_IMM_B; 
                mem_en = 0;
                we = 0;
                sel = 4'b0000;
                rf_wen = 1;
                wb_if_mem = 0;
            end
            OP_XORI: begin
                alu_op = `ALU_XOR;
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
            OP_SUB: begin
                alu_op = `ALU_SUB;
                alu_mux_a = `ALU_MUX_DATA;
                alu_mux_b = `ALU_MUX_DATA; 
                mem_en = 0;
                we = 0;
                sel = 4'b0000;
                rf_wen = 1;
                wb_if_mem = 0;
            end
            OP_SLL: begin
                alu_op = `ALU_LOGIC_LEFT;
                alu_mux_a = `ALU_MUX_DATA;
                alu_mux_b = `ALU_MUX_DATA; 
                mem_en = 0;
                we = 0;
                sel = 4'b0000;
                rf_wen = 1;
                wb_if_mem = 0;
            end
            OP_SLT: begin
                alu_op = `ALU_SLT;
                alu_mux_a = `ALU_MUX_DATA;
                alu_mux_b = `ALU_MUX_DATA; 
                mem_en = 0;
                we = 0;
                sel = 4'b0000;
                rf_wen = 1;
                wb_if_mem =0;
            end
            OP_SLTU: begin
                alu_op = `ALU_SLTU;
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
            OP_BNE, OP_BLT, OP_BGE, OP_BLTU, OP_BGEU: begin
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
            OP_SRAI: begin
                alu_op = `ALU_ALG_RIGHT;
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
            OP_SRL: begin
                alu_op = `ALU_LOGIC_RIGHT;
                alu_mux_a = `ALU_MUX_DATA;
                alu_mux_b = `ALU_MUX_DATA; 
                mem_en = 0;
                we = 0;
                sel = 4'b0000;
                rf_wen = 1;
                wb_if_mem = 0;
            end
            OP_SRA: begin
                alu_op = `ALU_ALG_RIGHT;
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
            OP_CSRRC: begin
                alu_op = `ALU_ADD;
                alu_mux_a = `ALU_MUX_DATA;
                alu_mux_b = `ALU_MUX_IMM_B;
                mem_en = 0;
                we = 0;
                sel = 4'b0000;
                rf_wen = 1;
                wb_if_mem = 2;
                csr_we_o = 1;
                csr_op_o = `CSR_CSRRC;
            end
            OP_CSRRW: begin
                alu_op = `ALU_ADD;
                alu_mux_a = `ALU_MUX_DATA;
                alu_mux_b = `ALU_MUX_IMM_B;
                mem_en = 0;
                we = 0;
                sel = 4'b0000;
                rf_wen = 1;
                wb_if_mem = 2;
                csr_we_o = 1;
                csr_op_o = `CSR_CSRRW;
            end
            OP_CSRRS: begin
                alu_op = `ALU_ADD;
                alu_mux_a = `ALU_MUX_DATA;
                alu_mux_b = `ALU_MUX_IMM_B;
                mem_en = 0;
                we = 0;
                sel = 4'b0000;
                rf_wen = 1;
                wb_if_mem = 2;
                csr_we_o = 1;
                csr_op_o = `CSR_CSRRS;
            end
            OP_ECALL: begin
                alu_op = `ALU_ADD;
                alu_mux_a = `ALU_MUX_DATA;
                alu_mux_b = `ALU_MUX_IMM_B;
                mem_en = 0;
                we = 0;
                sel = 4'b0000;
                rf_wen = 0;
                wb_if_mem = 0;
                id_exception_o = 1;
                csr_op_o = `ENV_ECALL;
            end
            OP_EBREAK: begin
                alu_op = `ALU_ADD;
                alu_mux_a = `ALU_MUX_DATA;
                alu_mux_b = `ALU_MUX_IMM_B;
                mem_en = 0;
                we = 0;
                sel = 4'b0000;
                rf_wen = 0;
                wb_if_mem = 0;
                id_exception_o = 1;
                csr_op_o = `ENV_EBREAK;
            end
            OP_MRET: begin
                alu_op = `ALU_ADD;
                alu_mux_a = `ALU_MUX_DATA;
                alu_mux_b = `ALU_MUX_ZERO;
                mem_en = 0;
                we = 0;
                sel = 4'b0000;
                rf_wen = 0;
                wb_if_mem = 0;
                id_exception_o = 1;
                csr_op_o = `ENV_MRET;
            end
            OP_NOP: begin
                alu_op = `ALU_ADD;
                alu_mux_a = `ALU_MUX_DATA;
                alu_mux_b = `ALU_MUX_IMM_B;
                mem_en = 0;
                we = 0;
                sel = 4'b0000;
                rf_wen = 1;
                wb_if_mem = 0;
            end
            OP_UNKNOWN: begin
                alu_op = `ALU_ADD;
                alu_mux_a = `ALU_MUX_DATA;
                alu_mux_b = `ALU_MUX_IMM_B;
                mem_en = 0;
                we = 0;
                sel = 4'b0000;
                rf_wen = 1;
                wb_if_mem = 0;
                exception_occured_o = 1;
                exception_cause_o = 2;
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
                exception_occured_o = 1;
                exception_cause_o = 2;
            end
        endcase
    end

endmodule
