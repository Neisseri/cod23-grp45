`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/11/19 09:30:01
// Design Name: 
// Module Name: Data_memory
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


module Data_memory #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input wire clk,
    input wire rst,

    // wishbone master
    output logic wb_cyc_o,
    output logic wb_stb_o,
    input wire wb_ack_i,
    output logic [ADDR_WIDTH-1:0] wb_adr_o,
    output logic [DATA_WIDTH-1:0] wb_dat_o,
    input wire [DATA_WIDTH-1:0] wb_dat_i,
    output logic [DATA_WIDTH/8-1:0] wb_sel_o,
    output logic wb_we_o,

    output logic master_ready_o,
    input wire mem_en,
    input wire write_en,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire [DATA_WIDTH/8-1:0] sel,
    output reg [DATA_WIDTH-1:0] data_out,

    input wire pipeline_stall,
    output logic idle_stall
    );

    typedef enum logic [3:0] {
    STATE_IDLE,
    STATE_WRITE_SRAM_ACTION,
    STATE_READ_SRAM_ACTION,
    STATE_DONE
} state_t;

    state_t state;
    
    assign wb_dat_o = data_in;
    assign wb_adr_o = addr;
    assign wb_sel_o = sel;
    assign wb_cyc_o = (state == STATE_READ_SRAM_ACTION) || (state == STATE_WRITE_SRAM_ACTION);
    assign wb_stb_o = (state == STATE_READ_SRAM_ACTION) || (state == STATE_WRITE_SRAM_ACTION);
    assign master_ready_o = !wb_stb_o;
    assign wb_we_o = write_en;

    assign idle_stall = 0;

    always_ff @(posedge clk) begin
        if(rst)begin
            data_out <= 0;
            state <= STATE_IDLE;
        end else begin
            if(mem_en)begin
                case (state)
                    STATE_IDLE: begin
                        if(write_en)begin
                            state <= STATE_WRITE_SRAM_ACTION;
                        end else begin
                            state <= STATE_READ_SRAM_ACTION;
                        end
                    end
                    STATE_WRITE_SRAM_ACTION: begin
                        if(wb_ack_i) begin
                            data_out <= wb_dat_i;
                            state <= STATE_DONE;
                        end
                    end
                    STATE_READ_SRAM_ACTION: begin
                        if(wb_ack_i) begin
                            data_out <= wb_dat_i;
                            state <= STATE_DONE;
                        end
                    end
                    STATE_DONE: begin
                        if(!pipeline_stall)begin
                            state <= STATE_IDLE;
                        end
                    end
                endcase
            end
        end
    end
endmodule

module Instruction_memory #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input wire clk,
    input wire rst,

    // wishbone master
    output logic wb_cyc_o,
    output logic wb_stb_o,
    input wire wb_ack_i,
    output logic [ADDR_WIDTH-1:0] wb_adr_o,
    output logic [DATA_WIDTH-1:0] wb_dat_o,
    input wire [DATA_WIDTH-1:0] wb_dat_i,
    output logic [DATA_WIDTH/8-1:0] wb_sel_o,
    output logic wb_we_o,

    output logic master_ready_o,
    input wire mem_en,
    input wire write_en,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire [DATA_WIDTH/8-1:0] sel,
    output reg [DATA_WIDTH-1:0] data_out,

    input wire pipeline_stall,
    output logic idle_stall
    );

    typedef enum logic [3:0] {
    STATE_IDLE,
    STATE_WRITE_SRAM_ACTION,
    STATE_READ_SRAM_ACTION,
    STATE_DONE
} state_t;

    state_t state;
    
    assign wb_dat_o = data_in;
    assign wb_adr_o = addr;
    assign wb_sel_o = sel;
    assign wb_cyc_o = (state == STATE_READ_SRAM_ACTION) || (state == STATE_WRITE_SRAM_ACTION);
    assign wb_stb_o = (state == STATE_READ_SRAM_ACTION) || (state == STATE_WRITE_SRAM_ACTION);
    assign master_ready_o = !wb_stb_o;
    assign wb_we_o = write_en;

    assign idle_stall = 0;

    always_ff @(posedge clk) begin
        if(rst)begin
            data_out <= 0;
            state <= STATE_DONE;
        end else begin
            if(mem_en)begin
                case (state)
                    STATE_IDLE: begin
                        if(write_en)begin
                            state <= STATE_WRITE_SRAM_ACTION;
                        end else begin
                            state <= STATE_READ_SRAM_ACTION;
                        end
                    end
                    STATE_WRITE_SRAM_ACTION: begin
                        if(wb_ack_i) begin
                            data_out <= wb_dat_i;
                            state <= STATE_DONE;
                        end
                    end
                    STATE_READ_SRAM_ACTION: begin
                        if(wb_ack_i) begin
                            data_out <= wb_dat_i;
                            state <= STATE_DONE;
                        end
                    end
                    STATE_DONE: begin
                        if(!pipeline_stall)begin
                            if(write_en)begin
                                state <= STATE_WRITE_SRAM_ACTION;
                            end else begin
                                state <= STATE_READ_SRAM_ACTION;
                            end
                        end
                    end
                endcase
            end
        end
    end
endmodule

