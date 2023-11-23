
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

    // ALU_mux
    `define ALU_MUX_DATA 0
    `define ALU_MUX_PC_A 1
    `define ALU_MUX_IMM_B 1
    `define ALU_MUX_ZERO 2
    `define ALU_MUX_FORWARD 3
    `define ALU_MUX_FOUR_B 4 // for compute PC+4