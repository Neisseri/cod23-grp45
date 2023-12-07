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
    input wire exe_is_load,

    // add signals
    input wire mem_is_load,
    input wire id_exe_rf_wen,
    input wire wb_rf_we,
    input wire [4:0] mem_wb_rd,
    input wire wb_is_load,
    input wire [DATA_WIDTH-1:0] wb_dat, // hazard 3

    input wire use_mem_dat_a, // mark mem hazard a
    input wire use_mem_dat_b, // mark mem hazard b
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
    output logic pass_use_mem_dat_a, // mem hazard a
    output logic pass_use_mem_dat_b, // mem hazard b

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

    // hazard 2
    // inst1: IF ID EXE-MEM WB
    // inst2:       IF -ID  EXE MEM WB

    // hazard 3
    // inst1: IF ID EXE MEM-WB
    // inst2:           IF -ID EXE MEM WB

    // hazard 4 (mem hazard) = hazard 1 && exe_is_load
    // ints1: IF ID EXE-MEM WB
    // inst2:    IF-ID  EXE MEM WB

    // hazard 5 (mem hazard) = hazard 2 && mem_is_load
    // inst1: IF ID EXE-MEM WB
    // inst2:       IF -ID  EXE MEM WB

    // hazard 6 (mem hazard) = hazard 3 && WB_is_load
    // inst1: IF ID EXE MEM-WB
    // inst2:           IF -ID EXE MEM WB

    // hazard 1
    always_comb begin
        if (exe_mem_rd == id_exe_rs1 && exe_mem_rd != 0 && exe_mem_rf_wen) begin // rs1
            hazard1_a = 1;
        end else begin
            hazard1_a = 0;
        end
        if (exe_mem_rd == id_exe_rs2 && exe_mem_rd != 0 && exe_mem_rf_wen) begin // rs2
            hazard1_b = 1;
        end else begin
            hazard1_b = 0;
        end
    end

    // hazard 2
    always_comb begin
        if (mem_wb_rd == id_exe_rs1 && mem_wb_rd != 0 && wb_rf_we) begin // rs1
            hazard2_a = 1;
        end else begin
            hazard2_a = 0;
        end
        if (mem_wb_rd == id_exe_rs2 && mem_wb_rd != 0 && wb_rf_we) begin // rs2
            hazard2_b = 1;
        end else begin
            hazard2_b = 0;
        end
    end

    // hazard 3
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
        if (hazard1_a && exe_is_load) begin // rs1
            hazard4_a = 1;
        end else begin
            hazard4_a = 0;
        end
        if (hazard1_b && exe_is_load) begin // rs2
            hazard4_b = 1;
        end else begin
            hazard4_b = 0;
        end
        // hazard 5
        if (hazard2_a && mem_is_load) begin // rs1
            hazard5_a = 1;
        end else begin
            hazard5_a = 0;
        end
        if (hazard2_b && mem_is_load) begin // rs2
            hazard5_b = 1;
        end else begin
            hazard5_b = 0;
        end
        // hazard 6
        if (hazard3_a && wb_is_load) begin // rs1
            hazard6_a = 1;
        end else begin
            hazard6_a = 0;
        end
        if (hazard3_b && wb_is_load) begin // rs2
            hazard6_b = 1;
        end else begin
            hazard6_b = 0;
        end
    end

    // alu control signals
    // TODO: 目前只考虑了非 mem hazard 的部分，mam hazerd 采用暂停解决，测试发现 forward 传输数据错误（如下）
    always_comb begin
        // rs1
        if (use_mem_dat_a) begin // hazard 4 5 6
            // TODO: hazard 4 5 6 different
            alu_mux_a = id_exe_alu_mux_a;
            alu_a_forward = 0;
        end else if (hazard1_a) begin // hazard 1
            alu_mux_a = `ALU_MUX_FORWARD;
            alu_a_forward = exe_mem_dat;
        end else if (hazard2_a) begin // hazard 2
            alu_mux_a = `ALU_MUX_FORWARD;
            alu_a_forward = mem_wb_dat;
        end else if (hazard3_a) begin // hazard 3
            // alu_mux_a = `ALU_MUX_FORWARD;
            // alu_a_forward = wb_dat;
            alu_mux_a = id_exe_alu_mux_a;
            alu_a_forward = 0;
        end else begin // no hazard
            alu_mux_a = id_exe_alu_mux_a;
            alu_a_forward = 0;
        end
        // rs2
        if (use_mem_dat_b) begin // hazard 4 5 6
            // TODO: hazard 3 and 4 different
            alu_mux_b = id_exe_alu_mux_b;
            alu_b_forward = 0;
        end else if (hazard1_b) begin // hazard 1
            alu_mux_b = `ALU_MUX_FORWARD;
            alu_b_forward = exe_mem_dat;
        end else if (hazard2_b) begin // hazard 2
            alu_mux_b = `ALU_MUX_FORWARD;
            alu_b_forward = mem_wb_dat;
        end else if (hazard3_b) begin // hazard 3
            // alu_mux_b = `ALU_MUX_FORWARD;
            // alu_b_forward = wb_dat;
            alu_mux_b = id_exe_alu_mux_b;
            alu_b_forward = 0;
        end else begin // no hazard
            alu_mux_b = id_exe_alu_mux_b;
            alu_b_forward = 0;
        end
        // alu_mux_a = id_exe_alu_mux_a;
        // alu_a_forward = 0;
        // alu_mux_b = id_exe_alu_mux_b;
        // alu_b_forward = 0;
    end

    // mem hazard signal
    always_comb begin
        // rs1
        if (hazard4_a || hazard5_a || hazard6_a) begin // hazard 4 5 6
            pass_use_mem_dat_a = 1;
        end else begin
            pass_use_mem_dat_a = 0;
        end
        // rs2
        if (hazard4_b || hazard5_b || hazard6_b) begin // hazard 4 5 6
            pass_use_mem_dat_b = 1;
        end else begin
            pass_use_mem_dat_b = 0;
        end
    end

    // test
    always_comb begin
        if (
            // id_exe_rf_wen && (if_id_rs1 == id_exe_rd || if_id_rs2 == id_exe_rd) && id_exe_rd != 0 || // ID -> EXE
            // exe_mem_rf_wen && (if_id_rs1 == exe_mem_rd || if_id_rs2 == exe_mem_rd) && exe_mem_rd != 0 || // EXE -> MEM
            // wb_rf_we && (if_id_rs1 == mem_wb_rd || if_id_rs2 == mem_wb_rd) && mem_wb_rd != 0 // MEM -> WB
            //hazard1_a || hazard1_b || hazard2_a || hazard2_b || hazard3_a || hazard3_b ||
            hazard3_a || hazard3_b ||
            hazard4_a || hazard4_b || hazard5_a || hazard5_b || hazard6_a || hazard6_b 
        ) begin
            exe_stall_req = 1;
        end else begin
            exe_stall_req = 0;
        end
    end

    // TODO: branch hazard
    always_comb begin
        // -------------------------------------
        // alu_mux_a = id_exe_alu_mux_a;
        // alu_a_forward = 0;
        // alu_mux_b = id_exe_alu_mux_b;
        // alu_b_forward = 0;
        // pass_use_mem_dat_a = 0;
        // pass_use_mem_dat_b = 0;
        // --------------------------------------
        branch_rs1 = 0;
        branch_rs2 = 0;
    end

endmodule

// module Forward_Unit #(
//     parameter ADDR_WIDTH = 32,
//     parameter DATA_WIDTH = 32
// )(
//     // EXE hazard
//     input wire [4:0] id_exe_rs1,
//     input wire [4:0] id_exe_rs2,
//     input wire [4:0] exe_mem_rd,
//     input wire exe_mem_rf_wen,

//     input wire [DATA_WIDTH-1:0] exe_mem_dat,

//     // MEM hazard
//     input wire [4:0] if_id_rs1,
//     input wire [4:0] if_id_rs2,
//     input wire [4:0] id_exe_rd,
//     input wire exe_is_load,

//     input wire use_mem_dat_a,
//     input wire use_mem_dat_b,
//     input wire [DATA_WIDTH-1:0] mem_wb_dat,

//     input wire [2:0] id_exe_alu_mux_a,
//     input wire [2:0] id_exe_alu_mux_b,

//     output logic [2:0] alu_mux_a,
//     output logic [2:0] alu_mux_b,
//     output logic [DATA_WIDTH-1:0] alu_a_forward,
//     output logic [DATA_WIDTH-1:0] alu_b_forward,

//     //output logic exe_stall_req,
//     output logic pass_use_mem_dat_a,
//     output logic pass_use_mem_dat_b,

//     output logic branch_rs1,
//     output logic branch_rs2
//     );

//     always_comb begin
//         alu_mux_a = id_exe_alu_mux_a;
//         alu_a_forward = 0;
//         alu_mux_b = id_exe_alu_mux_b;
//         alu_b_forward = 0;

//         pass_use_mem_dat_a = 0;
//         pass_use_mem_dat_b = 0;
//         branch_rs1 = 0;
//         branch_rs2 = 0;
//     end

//     // logic branch_hazard_a;
//     // logic branch_hazard_b;
//     // assign branch_hazard_a = id_exe_rd != 0 && id_exe_rd == if_id_rs1;
//     // assign branch_hazard_b = id_exe_rd != 0 && id_exe_rd == if_id_rs2;

//     // always_comb begin
//     //     if(branch_hazard_a)begin
//     //         branch_rs1 = 1;
//     //     end else begin
//     //         branch_rs1 = 0;
//     //     end

//     //     if(branch_hazard_b)begin
//     //         branch_rs2 = 1;
//     //     end else begin
//     //         branch_rs2 = 0;
//     //     end
//     // end

//     // always_comb begin
//     //     if(use_mem_dat_a)begin
//     //         alu_mux_a = `ALU_MUX_FORWARD;
//     //         alu_a_forward = mem_wb_dat;
//     //     end else begin
//     //         if(exe_mem_rd == id_exe_rs1 && exe_mem_rd != 0 && exe_mem_rf_wen)begin
//     //             alu_mux_a = `ALU_MUX_FORWARD;
//     //             alu_a_forward = exe_mem_dat;
//     //         end else begin
//     //             alu_mux_a = id_exe_alu_mux_a;
//     //             alu_a_forward = 0;
//     //         end
//     //     end

//     //     if(use_mem_dat_b)begin
//     //         alu_mux_b = `ALU_MUX_FORWARD;
//     //         alu_b_forward = mem_wb_dat;
//     //     end else begin
//     //         if(exe_mem_rd == id_exe_rs2 && exe_mem_rd != 0 && exe_mem_rf_wen)begin
//     //             alu_mux_b = `ALU_MUX_FORWARD;
//     //             alu_b_forward = exe_mem_dat;
//     //         end else begin
//     //             alu_mux_b = id_exe_alu_mux_b;
//     //             alu_b_forward = 0;
//     //         end
//     //     end
//     // end

//     // logic mem_hazard_a;
//     // logic mem_hazard_b;
//     // assign mem_hazard_a = exe_is_load && id_exe_rd != 0 && id_exe_rd == if_id_rs1;
//     // assign mem_hazard_b = exe_is_load && id_exe_rd != 0 && id_exe_rd == if_id_rs2;
//     // //assign mem_hazard_a = id_exe_rd != 0 && id_exe_rd == if_id_rs1;
//     // //assign mem_hazard_b = id_exe_rd != 0 && id_exe_rd == if_id_rs2;

//     // always_comb begin
//     //     if(mem_hazard_a || mem_hazard_b)begin
//     //         exe_stall_req = 1;
//     //     end else begin
//     //         exe_stall_req = 0;
//     //     end

//     //     if(mem_hazard_a)begin
//     //         pass_use_mem_dat_a = 1;
//     //     end else begin
//     //         pass_use_mem_dat_a = 0;
//     //     end

//     //     if(mem_hazard_b)begin
//     //         pass_use_mem_dat_b = 1;
//     //     end else begin
//     //         pass_use_mem_dat_b = 0;
//     //     end
//     // end
// endmodule
