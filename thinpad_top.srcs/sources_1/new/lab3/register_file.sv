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


module register_file #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input wire clk,
    input wire reset,
    input wire  [4:0]  rf_raddr_a,
    output  reg [DATA_WIDTH-1:0] rf_rdata_a,
    input wire  [4:0]  rf_raddr_b,
    output  reg [DATA_WIDTH-1:0] rf_rdata_b,
    input wire  [4:0]  rf_waddr,
    input wire  [DATA_WIDTH-1:0] rf_wdata,
    input wire  rf_we
    );
    
    reg [DATA_WIDTH-1:0] regs [0:31];
    
    always_comb begin
        if (rf_raddr_a == rf_waddr && rf_waddr != 0 && rf_we) begin
            rf_rdata_a = rf_wdata;
        end else begin
            rf_rdata_a = regs[rf_raddr_a];
        end
        
        if (rf_raddr_b == rf_waddr && rf_waddr != 0 && rf_we) begin
            rf_rdata_b = rf_wdata;
        end else begin
            rf_rdata_b = regs[rf_raddr_b];
        end
    end

//    always_comb begin
//        rf_rdata_a = regs[rf_raddr_a];
//        rf_rdata_b = regs[rf_raddr_b];
//    end
    
    always_ff @(posedge clk) begin
        if(reset) begin
            for(integer i = 0;i < 32;i = i + 1)begin
                regs[i] <= 0;
            end
        end else begin
            if(rf_waddr != 0 && rf_we) begin
                regs[rf_waddr] <= rf_wdata;
            end
        end
    end
    
endmodule
