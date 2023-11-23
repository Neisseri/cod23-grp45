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


module alu_mux_a #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (
        input wire [2:0] code,
        input wire [DATA_WIDTH-1:0] data,
        input wire [ADDR_WIDTH-1:0] pc,
        input wire [DATA_WIDTH-1:0] forward_data,
        output logic [DATA_WIDTH-1:0] result
    );

    always_comb begin
        case (code)
            0: result = data;
            1: result = pc;
            2: result = 0;
            3: result = forward_data;
            default: result = data;
        endcase
    end
endmodule
