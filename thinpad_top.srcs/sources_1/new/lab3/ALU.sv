`timescale 1ns / 1ps
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
    input wire [3:0] alu_op,
    output reg [DATA_WIDTH-1:0] alu_y
);

    always_comb begin
        if(alu_op == 1)begin
            alu_y = alu_a + alu_b;
        end else if(alu_op == 2)begin
            alu_y = alu_a - alu_b;
        end else if(alu_op == 3)begin
            alu_y = alu_a & alu_b;
        end else if(alu_op == 4)begin
            alu_y = alu_a | alu_b;
        end else if(alu_op == 5)begin
            alu_y = alu_a ^ alu_b;
        end else if(alu_op == 6)begin
            alu_y = ~alu_a;
        end else if(alu_op == 7)begin
            alu_y = alu_a << (alu_b & (DATA_WIDTH-1));
        end else if(alu_op == 8)begin
            alu_y = alu_a >> (alu_b & (DATA_WIDTH-1));
        end else if(alu_op == 9)begin
            alu_y = $signed(alu_a) >>> (alu_b & (DATA_WIDTH-1));
        end else if(alu_op == 10)begin
            alu_y = {DATA_WIDTH{1'b1}} & (alu_a << (alu_b & (DATA_WIDTH-1))) | (alu_a >> (DATA_WIDTH - (alu_b & (DATA_WIDTH-1))));
        end else begin
            alu_y = 0;
        end
    end

endmodule
