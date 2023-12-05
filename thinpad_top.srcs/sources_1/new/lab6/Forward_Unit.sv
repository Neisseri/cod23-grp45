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
    // EXE hazard
    // inst1: ID EXE -> MEM        rd
    //            |
    // inst2:     ID -> EXE MEM    rs1, rs2
    input wire [4:0] id_exe_rs1, // inst2: ID -> EXE rs1
    input wire [4:0] id_exe_rs2, // inst2: ID -> EXE rs2
    input wire [4:0] exe_mem_rd, // inst1: EXE -> MEM rd
    input wire exe_mem_rf_wen,   // inst1: write in rd

    input wire [DATA_WIDTH-1:0] exe_mem_dat, // inst1 rd, i.e. the real data of inst2 rs1/rs2

    // MEM hazard
    // inst1: ID EXE -> MEM             rd
    //                   |
    // inst3:     IF -> ID EXE MEM      rs1, rs2
    input wire [4:0] if_id_rs1, // inst3: IF -> ID rs1
    input wire [4:0] if_id_rs2, // inst3: IF -> ID rs2
    input wire [4:0] id_exe_rd, // inst1: ID -> EXE rd (exe_mem_rd == id_exe_rd)
    input wire exe_is_load,     // inst1: if MEM is after EXE stage

    input wire use_mem_dat_a, // inst3: '0' imm, '1' read from memory
    input wire use_mem_dat_b, // inst3: '0' imm, '1' read from memory
    input wire [DATA_WIDTH-1:0] mem_wb_dat, // inst1: MEM -> WB data

    input wire [2:0] id_exe_alu_mux_a, // inst3: ID -> EXE data type of alu input a 
    input wire [2:0] id_exe_alu_mux_b, // inst3: ID -> EXE data type of alu input b

    // output --------------------------------------------------------------------

    output logic [2:0] alu_mux_a, // inst2/3: alu_a data type
    output logic [2:0] alu_mux_b, // inst2/3: alu_b data type
    output logic [DATA_WIDTH-1:0] alu_a_forward, // inst2/3: alu_a forward data
    output logic [DATA_WIDTH-1:0] alu_b_forward, // inst2/3: alu_b forward data

    //output logic exe_stall_req,
    output logic pass_use_mem_dat_a, // pass `use_mem_dat_a` to next stage
    output logic pass_use_mem_dat_b, // pass `use_mem_dat_b` to next stage

    // branch hazard
    output logic branch_rs1,
    output logic branch_rs2
);

    logic exe_hazard_a;
    logic exe_hazard_a;
    logic mem_hazard_a;
    logic mem_hazard_b;

    // check EXE hazard
    always_comb begin
        if (exe_mem_rd == id_exe_rs1 && exe_mem_rd != 0 && exe_mem_rf_wen) begin // RAW
            exe_hazard_a = 1;
        end else begin
            exe_hazard_a = 0;
        end
        if (exe_mem_rd == id_exe_rs2 && exe_mem_rd != 0 && exe_mem_rf_wen) begin // RAW
            exe_hazard_b = 1;
        end else begin
            exe_hazard_b = 0;
        end
    end

    // check MEM hazard
    always_comb begin
        if (id_exe_rd == if_id_rs1 && exe_is_load && use_mem_dat_a) begin // RAW
            mem_hazard_a = 1;
        end else begin
            mem_hazard_a = 0;
        end
        if (id_exe_rd == if_id_rs2 && exe_is_load && use_mem_dat_b) begin // RAW
            mem_hazard_b = 1;
        end else begin
            mem_hazard_b = 0;
        end
    end

    // alu control signals
    always_comb begin
        // rs1
        if (exe_hazard_a) begin // exe hazard
            alu_mux_a = `ALU_MUX_FORWARD;
            alu_a_forward = exe_mem_dat;
        end else if (mem_hazard_a) begin // mem hazard
            alu_mux_a = `ALU_MUX_FORWARD;
            alu_a_forward = mem_wb_dat;
        end else begin // no hazard
            alu_mux_a = id_exe_alu_mux_a;
            alu_a_forward = 0;
        end
        // rs2
        if (exe_hazard_b) begin // exe hazard
            alu_mux_b = `ALU_MUX_FORWARD;
            alu_b_forward = exe_mem_dat;
        end else if (mem_hazard_b) begin // mem hazard
            alu_mux_b = `ALU_MUX_FORWARD;
            alu_b_forward = mem_wb_dat;
        end else begin // no hazard
            alu_mux_b = id_exe_alu_mux_b;
            alu_b_forward = 0;
        end
    end

    always_comb begin

        pass_use_mem_dat_a = 0;
        pass_use_mem_dat_b = 0;
        branch_rs1 = 0;
        branch_rs2 = 0;
    end

    // logic branch_hazard_a;
    // logic branch_hazard_b;
    // assign branch_hazard_a = id_exe_rd != 0 && id_exe_rd == if_id_rs1;
    // assign branch_hazard_b = id_exe_rd != 0 && id_exe_rd == if_id_rs2;

    // always_comb begin
    //     if(branch_hazard_a)begin
    //         branch_rs1 = 1;
    //     end else begin
    //         branch_rs1 = 0;
    //     end

    //     if(branch_hazard_b)begin
    //         branch_rs2 = 1;
    //     end else begin
    //         branch_rs2 = 0;
    //     end
    // end

    // logic mem_hazard_a;
    // logic mem_hazard_b;
    // assign mem_hazard_a = exe_is_load && id_exe_rd != 0 && id_exe_rd == if_id_rs1;
    // assign mem_hazard_b = exe_is_load && id_exe_rd != 0 && id_exe_rd == if_id_rs2;
    // //assign mem_hazard_a = id_exe_rd != 0 && id_exe_rd == if_id_rs1;
    // //assign mem_hazard_b = id_exe_rd != 0 && id_exe_rd == if_id_rs2;

    // always_comb begin
    //     if(mem_hazard_a || mem_hazard_b)begin
    //         exe_stall_req = 1;
    //     end else begin
    //         exe_stall_req = 0;
    //     end

    //     if(mem_hazard_a)begin
    //         pass_use_mem_dat_a = 1;
    //     end else begin
    //         pass_use_mem_dat_a = 0;
    //     end

    //     if(mem_hazard_b)begin
    //         pass_use_mem_dat_b = 1;
    //     end else begin
    //         pass_use_mem_dat_b = 0;
    //     end
    // end
endmodule
