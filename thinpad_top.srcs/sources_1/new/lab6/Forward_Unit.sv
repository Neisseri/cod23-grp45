`timescale 1ns / 1ps
`include "../header/opcode.sv"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/11/20 15:30:18
// Design Name: 
// Module Name: Forward_Unit
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

module Forward_Unit #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    // set register addrin ID, get register data in ID_EXE_reg

    input wire [4:0] id_exe_rs1,
    input wire [4:0] id_exe_rs2,
    input wire [4:0] exe_mem_rd,
    input wire exe_mem_rf_wen,

    input wire [DATA_WIDTH-1:0] exe_mem_dat, // hazard 1

    input wire [4:0] if_id_rs1,
    input wire [4:0] if_id_rs2,
    input wire [4:0] id_exe_rd,
    input wire id_exe_is_load,

    // add signals
    input wire exe_mem_is_load,
    input wire id_exe_rf_wen,
    input wire wb_rf_we,
    input wire [4:0] mem_wb_rd,
    input wire mem_wb_is_load,
    input wire [DATA_WIDTH-1:0] wb_dat,
    input wire [DATA_WIDTH-1:0] id_exe_dat,
    input wire [DATA_WIDTH-1:0] mem_dat,
    input wire [DATA_WIDTH-1:0] mem_wb_mem_dat,

    // hazard 3
    output logic rs1_forward_o,
    output logic rs2_forward_o,
    output logic [DATA_WIDTH-1:0] rs1_forward_dat_o,
    output logic [DATA_WIDTH-1:0] rs2_forward_dat_o,

    input wire [DATA_WIDTH-1:0] mem_wb_dat, // hazard 2

    input wire [2:0] id_exe_alu_mux_a,
    input wire [2:0] id_exe_alu_mux_b,

    // output --------------------------------------------------------------------

    output logic [2:0] alu_mux_a,
    output logic [2:0] alu_mux_b,
    output logic [DATA_WIDTH-1:0] alu_a_forward,
    output logic [DATA_WIDTH-1:0] alu_b_forward,

    // mem hazard: need stall
    output logic exe_stall_req,

    // branch hazard
    output logic branch_rs1,
    output logic branch_rs2
);
    logic hazard1_a;
    logic hazard1_b;
    logic hazard2_a;
    logic hazard2_b;
    logic hazard3_a;
    logic hazard3_b;
    logic hazard4_a;
    logic hazard4_b;
    logic hazard5_a;
    logic hazard5_b;
    logic hazard6_a;
    logic hazard6_b;

    // hazard 1
    // ints1: IF ID-EXE MEM WB
    // inst2:    IF-ID  EXE MEM WB
    always_comb begin
        if (id_exe_rd == if_id_rs1 && id_exe_rd != 0 && id_exe_rf_wen) begin // rs1
            hazard1_a = 1;
        end else begin
            hazard1_a = 0;
        end
        if (id_exe_rd == if_id_rs2 && id_exe_rd != 0 && id_exe_rf_wen) begin // rs2
            hazard1_b = 1;
        end else begin
            hazard1_b = 0;
        end
    end

    // hazard 2
    // inst1: IF ID EXE-MEM WB
    // inst2:       IF -ID  EXE MEM WB
    always_comb begin
        if (exe_mem_rd == if_id_rs1 && exe_mem_rd != 0 && exe_mem_rf_wen) begin // rs1
            hazard2_a = 1;
        end else begin
            hazard2_a = 0;
        end
        if (exe_mem_rd == if_id_rs2 && exe_mem_rd != 0 && exe_mem_rf_wen) begin // rs2
            hazard2_b = 1;
        end else begin
            hazard2_b = 0;
        end
    end

    // hazard 3
    // inst1: IF ID EXE MEM-WB
    // inst2:           IF -ID EXE MEM WB
    always_comb begin
        if (mem_wb_rd == if_id_rs1 && mem_wb_rd != 0 && wb_rf_we) begin // rs1
            hazard3_a = 1;
        end else begin
            hazard3_a = 0;
        end
        if (mem_wb_rd == if_id_rs2 && mem_wb_rd != 0 && wb_rf_we) begin // rs2
            hazard3_b = 1;
        end else begin
            hazard3_b = 0;
        end
    end

    // hazard 4 5 6
    always_comb begin
        // hazard 4
        // ints1: IF ID-EXE MEM WB
        // inst2:    IF-ID  EXE MEM WB
        if (hazard1_a && id_exe_is_load) begin // rs1
            hazard4_a = 1;
        end else begin
            hazard4_a = 0;
        end
        if (hazard1_b && id_exe_is_load) begin // rs2
            hazard4_b = 1;
        end else begin
            hazard4_b = 0;
        end
        // hazard 5
        // inst1: IF ID EXE-MEM WB
        // inst2:       IF -ID  EXE MEM WB
        if (hazard2_a && exe_mem_is_load) begin // rs1
            hazard5_a = 1;
        end else begin
            hazard5_a = 0;
        end
        if (hazard2_b && exe_mem_is_load) begin // rs2
            hazard5_b = 1;
        end else begin
            hazard5_b = 0;
        end
        // hazard 6
        // inst1: IF ID EXE MEM-WB
        // inst2:           IF -ID EXE MEM WB
        if (hazard3_a && mem_wb_is_load) begin // rs1
            hazard6_a = 1;
        end else begin
            hazard6_a = 0;
        end
        if (hazard3_b && mem_wb_is_load) begin // rs2
            hazard6_b = 1;
        end else begin
            hazard6_b = 0;
        end
    end

    // alu control signals
    always_comb begin
        // rs1
        rs1_forward_o = 0;
        rs1_forward_dat_o = 0;
        alu_mux_a = id_exe_alu_mux_a;
        alu_a_forward = 0;
        if (hazard4_a) begin // hazard 4
            rs1_forward_o = 0;
            rs1_forward_dat_o = 0;
        end else if (hazard1_a) begin // hazard 1
            rs1_forward_o = 1;
            rs1_forward_dat_o = id_exe_dat;
        end else if (hazard5_a) begin // hazard 5
            rs1_forward_o = 1;
            rs1_forward_dat_o = mem_dat;
        end else if (hazard2_a) begin // hazard 2
            rs1_forward_o = 1;
            rs1_forward_dat_o = exe_mem_dat;
        end else if (hazard6_a) begin // hazard 6
            rs1_forward_o = 1;
            rs1_forward_dat_o = mem_wb_mem_dat;
        end else if (hazard3_a) begin // hazard 3
            rs1_forward_o = 1;
            rs1_forward_dat_o = mem_wb_dat;
        end
        // rs2
        rs2_forward_o = 0;
        rs2_forward_dat_o = 0;
        alu_mux_b = id_exe_alu_mux_b;
        alu_b_forward = 0;
        if (hazard4_b) begin // hazard 4
            rs2_forward_o = 0;
            rs2_forward_dat_o = 0;
        end else if (hazard1_b) begin // hazard 1
            rs2_forward_o = 1;
            rs2_forward_dat_o = id_exe_dat;
        end else if (hazard5_b) begin // hazard 5
            rs2_forward_o = 1;
            rs2_forward_dat_o = mem_dat;
        end else if (hazard2_b) begin // hazard 2
            rs2_forward_o = 1;
            rs2_forward_dat_o = exe_mem_dat;
        end else if (hazard6_b) begin // hazard 6
            rs2_forward_o = 1;
            rs2_forward_dat_o = mem_wb_mem_dat;
        end else if (hazard3_b) begin // hazard 3
            rs2_forward_o = 1;
            rs2_forward_dat_o = mem_wb_dat;
        end
    end

    always_comb begin
        if (hazard4_a || hazard4_b) begin
            exe_stall_req = 1;
        end else begin
            exe_stall_req = 0;
        end
    end

    // TODO: branch hazard
    always_comb begin
        branch_rs1 = 0;
        branch_rs2 = 0;
    end

endmodule