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

    OP_TYPE_T op_type;
    assign op_type = OP_TYPE_T'(op_type_in);

    assign new_pc = imm + pc;

    always_comb begin
        case (op_type)
            OP_BEQ: comp_result = (data_a == data_b);
            OP_BNE: comp_result = (data_a != data_b);
            OP_JAL, OP_JALR: comp_result = 1;
            default: comp_result = 0;
        endcase
    end
endmodule
