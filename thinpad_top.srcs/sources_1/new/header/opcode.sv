
    `define NOP_INSTR 32'h00000013

    // ALU
    `define ALU_ADD 1
    `define ALU_SUB 2
    `define ALU_AND 3
    `define ALU_OR 4
    `define ALU_XOR 5
    `define ALU_NOT 6
    `define ALU_LOGIC_LEFT 7
    `define ALU_LOGIC_RIGHT 8
    `define ALU_ALG_RIGHT 9
    `define ALU_CIRCLE_LEFT 10
    `define ALU_CTZ 11
    `define ALU_ANDN 12
    `define ALU_MINU 13
    `define ALU_SLTU 14

    // ALU_mux
    `define ALU_MUX_DATA 0
    `define ALU_MUX_PC_A 1
    `define ALU_MUX_IMM_B 1
    `define ALU_MUX_ZERO 2
    `define ALU_MUX_FORWARD 3
    `define ALU_MUX_FOUR_B 4 // for compute PC+4

    // CSR
    `define CSR_CSRRC 1
    `define CSR_CSRRS 2
    `define CSR_CSRRW 3
    `define CSR_CSRRCI 4
    `define CSR_CSRRSI 5
    `define CSR_CSRRWI 6
    // ENV
    `define ENV_ECALL 7
    `define ENV_EBREAK 8
    `define ENV_MRET 9
    `define ENV_SRET 10