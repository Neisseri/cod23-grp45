`timescale 1ns / 1ps
`include "../header/opcode.sv"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/10/14 17:19:03
// Design Name: 
// Module Name: controller
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


module ALU #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input wire [DATA_WIDTH-1:0] alu_a,
    input wire [DATA_WIDTH-1:0] alu_b,
    input wire [5:0] alu_op,
    output logic [DATA_WIDTH-1:0] alu_y,

    output logic exception_occured_o,
    output logic [DATA_WIDTH-1:0] exception_cause_o
);

    always_comb begin // change here when alu exception occurs
        exception_occured_o = 0;
        exception_cause_o = 0;
    end

    always_comb begin
        if (alu_op == `ALU_ADD) begin
            alu_y = alu_a + alu_b;
        end else if (alu_op == `ALU_SUB) begin
            alu_y = alu_a - alu_b;
        end else if (alu_op == `ALU_AND) begin
            alu_y = alu_a & alu_b;
        end else if (alu_op == `ALU_OR) begin
            alu_y = alu_a | alu_b;
        end else if (alu_op == `ALU_XOR) begin
            alu_y = alu_a ^ alu_b;
        end else if (alu_op == `ALU_NOT) begin
            alu_y = ~alu_a;
        end else if (alu_op == `ALU_LOGIC_LEFT) begin
            alu_y = alu_a << (alu_b & (DATA_WIDTH-1));
        end else if (alu_op == `ALU_LOGIC_RIGHT) begin
            alu_y = alu_a >> (alu_b & (DATA_WIDTH-1));
        end else if (alu_op == `ALU_ALG_RIGHT) begin
            alu_y = $signed(alu_a) >>> (alu_b & (DATA_WIDTH-1));
        end else if (alu_op == `ALU_CIRCLE_LEFT) begin
            alu_y = {DATA_WIDTH{1'b1}} & (alu_a << (alu_b & (DATA_WIDTH-1))) | (alu_a >> (DATA_WIDTH - (alu_b & (DATA_WIDTH-1))));
        end else if (alu_op == `ALU_CTZ) begin
            casez (alu_a)
                32'b???????????????????????????????1: alu_y = 32'h0;
                32'b??????????????????????????????10: alu_y = 32'h1;
                32'b?????????????????????????????100: alu_y = 32'h2;
                32'b????????????????????????????1000: alu_y = 32'h3;
                32'b???????????????????????????10000: alu_y = 32'h4;
                32'b??????????????????????????100000: alu_y = 32'h5;
                32'b?????????????????????????1000000: alu_y = 32'h6;
                32'b????????????????????????10000000: alu_y = 32'h7;
                32'b???????????????????????100000000: alu_y = 32'h8;
                32'b??????????????????????1000000000: alu_y = 32'h9;
                32'b?????????????????????10000000000: alu_y = 32'ha;
                32'b????????????????????100000000000: alu_y = 32'hb;
                32'b???????????????????1000000000000: alu_y = 32'hc;
                32'b??????????????????10000000000000: alu_y = 32'hd;
                32'b?????????????????100000000000000: alu_y = 32'he;
                32'b????????????????1000000000000000: alu_y = 32'hf;
                32'b???????????????10000000000000000: alu_y = 32'h10;
                32'b??????????????100000000000000000: alu_y = 32'h11;
                32'b?????????????1000000000000000000: alu_y = 32'h12;
                32'b????????????10000000000000000000: alu_y = 32'h13;
                32'b???????????100000000000000000000: alu_y = 32'h14;
                32'b??????????1000000000000000000000: alu_y = 32'h15;
                32'b?????????10000000000000000000000: alu_y = 32'h16;
                32'b????????100000000000000000000000: alu_y = 32'h17;
                32'b???????1000000000000000000000000: alu_y = 32'h18;
                32'b??????10000000000000000000000000: alu_y = 32'h19;
                32'b?????100000000000000000000000000: alu_y = 32'h1a;
                32'b????1000000000000000000000000000: alu_y = 32'h1b;
                32'b???10000000000000000000000000000: alu_y = 32'h1c;
                32'b??100000000000000000000000000000: alu_y = 32'h1d;
                32'b?1000000000000000000000000000000: alu_y = 32'h1e;
                32'b10000000000000000000000000000000: alu_y = 32'h1f;
                32'b00000000000000000000000000000000: alu_y = 32'h20;
                default: alu_y = 32'h20;
            endcase
        end else if (alu_op == `ALU_ANDN) begin
            alu_y = alu_a & (~alu_b);
        end else if (alu_op == `ALU_MINU) begin
            if (alu_a < alu_b) begin
                alu_y = alu_a;
            end else begin
                alu_y = alu_b;
            end
        end else if (alu_op == `ALU_SLTU) begin
            if (alu_a < alu_b) begin
                alu_y = 1;
            end else begin
                alu_y = 0;
            end
        end else if (alu_op == `ALU_SLT) begin
            if ($signed(alu_a) < $signed(alu_b)) begin
                alu_y = 1;
            end else begin
                alu_y = 0;
            end
        end else begin
            alu_y = 0;
        end
    end

endmodule
