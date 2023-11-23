`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/10/08 20:53:08
// Design Name: 
// Module Name: counter
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

`default_nettype none

module counter(
    input wire clk,
    input wire reset,
    input wire trigger,
    output wire [3:0] count
    );

reg[3:0] count_reg;
    
always_ff @(posedge clk, posedge reset) begin
    if(reset)begin
        count_reg <= 0;
    end else begin
        if(trigger && count < 15) begin
            count_reg <= count_reg + 1;
        end
    end
end

 // Òì²½ÊµÏÖ
//always_ff @(posedge trigger, posedge reset) begin
//    if(reset)begin
//        count_reg <= 0;
//    end else begin
//        if(count < 15)begin
//            count_reg <= count_reg + 1;
//        end
//    end
//end

assign count = count_reg;
    
endmodule
