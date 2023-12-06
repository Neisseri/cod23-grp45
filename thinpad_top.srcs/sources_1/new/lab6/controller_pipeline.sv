`timescale 1ns / 1ps
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


module controller_pipeline(
    input wire if_stall_req,
    input wire mem_stall_req,
    input wire id_flush_req,
    input wire mem_flush_req,
    input wire exe_stall_req,

    output logic pc_stall,
    output logic if_id_stall,
    output logic if_id_bubble,
    output logic id_exe_stall,
    output logic id_exe_bubble,
    output logic exe_mem_stall,
    output logic exe_mem_bubble,
    output logic mem_wb_stall,
    output logic mem_wb_bubble,

    output logic pipeline_stall,
    input wire im_idle_stall,
    input wire dm_idle_stall
    );

    //logic pipeline_stall;
    assign pipeline_stall = if_stall_req || mem_stall_req;

    logic idle_stall;
    assign idle_stall = im_idle_stall;

    always_comb begin
        if(idle_stall)begin
            pc_stall = 1;
            if_id_stall = 0;
            if_id_bubble = 0;
            id_exe_stall = 0;
            id_exe_bubble = 0;
            exe_mem_stall = 0;
            exe_mem_bubble = 0;
            mem_wb_stall = 0;
            mem_wb_bubble = 0;
        end
        else begin
        if (pipeline_stall) begin
            pc_stall = 1;
            if_id_stall = 1;
            if_id_bubble = 0;
            id_exe_stall = 1;
            id_exe_bubble = 0;
            exe_mem_stall = 1;
            exe_mem_bubble = 0;
            mem_wb_stall = 1;
            mem_wb_bubble = 0;
        end else begin
            if (exe_stall_req) begin
                    pc_stall = 1;
                    if_id_stall = 1;
                    if_id_bubble = 0;
                    id_exe_stall = 0;
                    id_exe_bubble = 1;
                    exe_mem_stall = 0;
                    exe_mem_bubble = 0;
                    mem_wb_stall = 0;
                    mem_wb_bubble = 0;
            end else begin
                if (mem_flush_req) begin
                    pc_stall = 0;
                    if_id_stall = 0;
                    if_id_bubble = 1;
                    id_exe_stall = 0;
                    id_exe_bubble = 1;
                    exe_mem_stall = 0;
                    exe_mem_bubble = 1;
                    mem_wb_stall = 0;
                    mem_wb_bubble = 0;
                end else if (id_flush_req) begin
                    pc_stall = 0;
                    if_id_stall = 0;
                    if_id_bubble = 1;
                    id_exe_stall = 0;
                    id_exe_bubble = 0;
                    exe_mem_stall = 0;
                    exe_mem_bubble = 0;
                    mem_wb_stall = 0;
                    mem_wb_bubble = 0;
                end else begin
                    pc_stall = 0;
                    if_id_stall = 0;
                    if_id_bubble = 0;
                    id_exe_stall = 0;
                    id_exe_bubble = 0;
                    exe_mem_stall = 0;
                    exe_mem_bubble = 0;
                    mem_wb_stall = 0;
                    mem_wb_bubble = 0;
                end
            end
        end
        end
    end
endmodule
