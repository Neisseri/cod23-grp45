`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/10/08 21:35:40
// Design Name: 
// Module Name: trigger
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

module trigger(
    input wire clk,
    input wire reset,
    input wire button,
    output reg button_debounced
);
   logic last_button_reg;

  always_ff @ (posedge clk) begin
    if(reset)begin
        last_button_reg <= 0;
    end else begin
        last_button_reg <= button;
        if(last_button_reg == 0 && button == 1)begin
            button_debounced <= 1;
        end else begin
            button_debounced <= 0;
        end
    end
  end
   
endmodule
