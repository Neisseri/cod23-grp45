`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/11/19 14:18:49
// Design Name: 
// Module Name: alu_mux_a
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


module wb_mux #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (
        input wire if_mem,
        input wire [DATA_WIDTH-1:0] alu_data,
        input wire [DATA_WIDTH-1:0] mem_data,
        output logic [DATA_WIDTH-1:0] result
    );

    always_comb begin
        case (if_mem)
            0: result = alu_data;
            1: result = mem_data;
            default: result = alu_data;
        endcase
    end
endmodule
