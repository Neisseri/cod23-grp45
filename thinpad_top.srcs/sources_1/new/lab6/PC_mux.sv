`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/11/19 09:41:15
// Design Name: 
// Module Name: PC_mux
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


module PC_mux#(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
        input wire branch,
        input wire [ADDR_WIDTH-1:0] branch_addr,
        input wire [ADDR_WIDTH-1:0] cur_pc,
        output logic [ADDR_WIDTH-1:0] next_pc
    );

    always_comb begin
            if(branch)begin
                next_pc = branch_addr;
            end else begin
                next_pc = cur_pc + 4; //TODO: 分支预测逻辑
            end
    end

endmodule
