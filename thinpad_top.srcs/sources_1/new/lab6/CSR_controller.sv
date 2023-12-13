`timescale 1ns/1ps
`include "../header/opcode.svh"
`include "../header/csr.svh"

module CSR_controller #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input wire clk,
    input wire rst,
    input wire stall,
    input wire bubble,

    input wire [DATA_WIDTH-1:0] rs1_dat_i,
    input wire [DATA_WIDTH-1:0] imm_dat_i,
    input wire [11:0] csr_adr_i,
    input wire csr_we_i,
    input wire [3:0] csr_op_i,

    output reg [DATA_WIDTH-1:0] csr_o,

    input wire [DATA_WIDTH-1:0] csr_i,
    output reg [11:0] csr_adr_o,
    output reg [DATA_WIDTH-1:0] csr_wdat_o,
    output reg csr_we_o,

    input wire [DATA_WIDTH-1:0] csr_sepc_i,
    input wire [DATA_WIDTH-1:0] csr_stvec_i,
    input wire [DATA_WIDTH-1:0] csr_stval_i,
    input wire [DATA_WIDTH-1:0] csr_sip_i,
    input wire [DATA_WIDTH-1:0] csr_sie_i,
    input wire [DATA_WIDTH-1:0] csr_mstatus_i,
    input wire [DATA_WIDTH-1:0] csr_mtvec_i,
    input wire [DATA_WIDTH-1:0] csr_mtval_i,
    input wire [DATA_WIDTH-1:0] csr_mepc_i,
    input wire [DATA_WIDTH-1:0] csr_mcause_i,
    input wire [DATA_WIDTH-1:0] csr_mip_i,
    input wire [DATA_WIDTH-1:0] csr_mie_i,
    input wire [DATA_WIDTH-1:0] csr_medeleg_i,
    input wire [DATA_WIDTH-1:0] csr_mideleg_i,

    output reg [DATA_WIDTH-1:0] csr_sepc_o,
    output reg csr_sepc_we_o,
    output reg [DATA_WIDTH-1:0] csr_scause_o,
    output reg csr_scause_we_o,
    output reg [DATA_WIDTH-1:0] csr_stval_o,
    output reg csr_stval_we_o,
    output reg [DATA_WIDTH-1:0] csr_mstatus_o,
    output reg csr_mstatus_we_o,
    output reg [DATA_WIDTH-1:0] csr_mtvec_o,
    output reg csr_mtvec_we_o,
    output reg [DATA_WIDTH-1:0] csr_mepc_o,
    output reg csr_mepc_we_o,
    output reg [DATA_WIDTH-1:0] csr_mcause_o,
    output reg csr_mcause_we_o,
    output reg [DATA_WIDTH-1:0] csr_mtval_o,
    output reg csr_mtval_we_o,
    output reg [DATA_WIDTH-1:0] csr_mip_o,
    output reg csr_mip_we_o,
    output reg [DATA_WIDTH-1:0] csr_mie_o,
    output reg csr_mie_we_o,

    input wire [DATA_WIDTH-1:0] id_exe_pc_i,
    input wire [DATA_WIDTH-1:0] if_id_pc_i,
    input wire [DATA_WIDTH-1:0] if_pc_i,
    input wire [ADDR_WIDTH-1:0] mem_pc_i,
    output reg [ADDR_WIDTH-1:0] pc_next_exception_o,
    output reg mem_exception_o,
    output reg [1:0] priv_level_o,
    output reg priv_level_we_o,
    input wire [1:0] priv_level_i,

    input wire time_interrupt_i,

    input wire exception_occured_i,
    input wire [DATA_WIDTH-1:0] exception_cause_i,
    input wire [DATA_WIDTH-1:0] exception_val_i,
    input wire [ADDR_WIDTH-1:0] exception_pc_i,

    output wire csr_stall_req
    );

    logic [DATA_WIDTH-2:0] exc_cause;
    assign exc_cause = exception_cause_i[DATA_WIDTH-2:0];
    logic mission_to_s;
    assign mission_to_s = (priv_level_i == `PRIV_U_LEVEL || priv_level_i == `PRIV_S_LEVEL) && csr_medeleg_i[exc_cause];
    logic s_time_interrupt;
    assign s_time_interrupt = csr_sip_i[5] && csr_sie_i[5] && (priv_level_i == `PRIV_U_LEVEL || (priv_level_i == `PRIV_S_LEVEL && csr_mstatus_i[1]));
    logic m_time_interrupt;
    assign m_time_interrupt = csr_mip_i[7] && csr_mie_i[7] && (priv_level_i == `PRIV_U_LEVEL || priv_level_i == `PRIV_S_LEVEL || (priv_level_i == `PRIV_M_LEVEL && csr_mstatus_i[3]));
    logic system_call;
    assign system_call = (csr_op_i == `ENV_MRET) || (csr_op_i == `ENV_ECALL) || (csr_op_i == `ENV_EBREAK) || (csr_op_i == `ENV_SRET);
    logic exception_occur_real;
    assign exception_occur_real = exception_occured_i || s_time_interrupt || m_time_interrupt || system_call;

    assign csr_stall_req = exception_occur_real && !mem_exception_o;

    logic [DATA_WIDTH-1:0] next_pc;
    always_comb begin
        if (id_exe_pc_i != 0) begin
            next_pc = id_exe_pc_i;
        end else if (if_id_pc_i != 0) begin
            next_pc = if_id_pc_i;
        end else begin
            next_pc = if_pc_i;
        end
    end

    always_comb begin
        csr_adr_o = 0;
        csr_wdat_o = 0;
        csr_we_o = 0;
        csr_o = 0;
        csr_mip_o = 0;
        csr_mip_we_o = 0;
        if (!exception_idle) begin
            case(csr_op_i)
                `CSR_CSRRW: begin
                    csr_adr_o = csr_adr_i;
                    csr_wdat_o = rs1_dat_i;
                    csr_we_o = csr_we_i;
                    csr_o = csr_i;
                end
                `CSR_CSRRS: begin
                    csr_adr_o = csr_adr_i;
                    csr_wdat_o = csr_i | rs1_dat_i;
                    csr_we_o = csr_we_i;
                    csr_o = csr_i;
                end
                `CSR_CSRRC: begin
                    csr_adr_o = csr_adr_i;
                    csr_wdat_o = csr_i & ~rs1_dat_i;
                    csr_we_o = csr_we_i;
                    csr_o = csr_i;
                end
                `CSR_CSRRWI: begin
                    csr_adr_o = csr_adr_i;
                    csr_wdat_o = imm_dat_i;
                    csr_we_o = csr_we_i;
                    csr_o = csr_i;
                end
                `CSR_CSRRSI: begin
                    csr_adr_o = csr_adr_i;
                    csr_wdat_o = csr_i | imm_dat_i;
                    csr_we_o = csr_we_i;
                    csr_o = csr_i;
                end
                `CSR_CSRRCI: begin
                    csr_adr_o = csr_adr_i;
                    csr_wdat_o = csr_i & ~imm_dat_i;
                    csr_we_o = csr_we_i;
                    csr_o = csr_i;
                end
                default: begin
                    csr_adr_o = 0;
                    csr_wdat_o = 0;
                    csr_we_o = 0;
                    csr_o = 0;
                end
            endcase
            if (time_interrupt_i) begin
                csr_mip_o = {csr_mip_i[31:8], 1'b1, csr_mip_i[6:0]};
                csr_mip_we_o = 1;
            end else begin
                csr_mip_o = {csr_mip_i[31:8], 1'b0, csr_mip_i[6:0]};
                csr_mip_we_o = 1;
            end
        end
    end

    reg exception_idle; // set 1 for idle after handling a exception

    always_ff @(posedge clk) begin
        if(rst)begin
            mem_exception_o <= 0;
            exception_idle <= 0;
        end else begin
            if(exception_occur_real) begin
                mem_exception_o <= 1;
                exception_idle <= 1;
            end else begin
                if(exception_idle)begin
                    exception_idle <= 0;
                end else begin
                    mem_exception_o <= 0;
                end
            end
        end
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            csr_sepc_we_o <= 0;
            csr_scause_we_o <= 0;
            csr_stval_we_o <= 0;
            csr_mstatus_we_o <= 0;
            csr_mepc_we_o <= 0;
            csr_mcause_we_o <= 0;
            csr_mtval_we_o <= 0;
            csr_mtvec_we_o <= 0;
            csr_mie_we_o <= 0;
            priv_level_we_o <= 0;
        end else begin
            if (1) begin
                if (bubble) begin
                    csr_sepc_we_o <= 0;
                    csr_scause_we_o <= 0;
                    csr_stval_we_o <= 0;
                    csr_mstatus_we_o <= 0;
                    csr_mepc_we_o <= 0;
                    csr_mcause_we_o <= 0;
                    csr_mtval_we_o <= 0;
                    csr_mtvec_we_o <= 0;
                    csr_mie_we_o <= 0;
                    priv_level_we_o <= 0;
                end else begin
                    csr_mtvec_we_o <= 0;
                    csr_mie_we_o <= 0;
                    if (exception_occured_i) begin // exception
                        if (mission_to_s) begin // to S-level
                            csr_scause_o <= exception_cause_i;
                            csr_scause_we_o <= 1;
                            csr_stval_o <= exception_val_i;
                            csr_stval_we_o <= 1;
                            csr_sepc_o <= exception_pc_i;
                            csr_sepc_we_o <= 1;
                            csr_mstatus_o <= {
                                csr_mstatus_i[31:9],
                                priv_level_i[0], // spp <= priv_level
                                csr_mstatus_i[7:6],
                                csr_mstatus_i[1], // spie <= sie
                                csr_mstatus_i[4:2],
                                1'b0, // sie <= 0
                                csr_mstatus_i[0]
                            };
                            csr_mstatus_we_o <= 1;
                            pc_next_exception_o <= csr_stvec_i;
                            priv_level_o <= `PRIV_S_LEVEL;
                            priv_level_we_o <= 1;
                        end else begin // to M-level
                            csr_mcause_o <= exception_cause_i;
                            csr_mcause_we_o <= 1;
                            csr_mtval_o <= exception_val_i;
                            csr_mtval_we_o <= 1;
                            csr_mepc_o <= exception_pc_i;
                            csr_mepc_we_o <= 1;
                            csr_mstatus_o <= {
                                csr_mstatus_i[31:13],
                                priv_level_i, // mpp <= priv_level
                                csr_mstatus_i[10:8],
                                csr_mstatus_i[3], // mpie <= mie
                                csr_mstatus_i[6:4],
                                1'b0, // mie <= 0
                                csr_mstatus_i[2:0]
                            };
                            csr_mstatus_we_o <= 1;
                            pc_next_exception_o <= csr_mtvec_i;
                            priv_level_o <= `PRIV_M_LEVEL;
                            priv_level_we_o <= 1;
                        end
                    end else if (s_time_interrupt) begin
                        csr_scause_o <= {1'b1, `SUPERVISOR_TIMER_INTERRUPT};
                        csr_scause_we_o <= 1;
                        csr_stval_o <= csr_stval_i;
                        csr_stval_we_o <= 1;
                        csr_sepc_o <= next_pc;
                        csr_sepc_we_o <= 1;
                        csr_mstatus_o <= {
                            csr_mstatus_i[31:9],
                            priv_level_i[0], // spp <= priv_level
                            csr_mstatus_i[7:6],
                            csr_mstatus_i[1], // spie <= sie
                            csr_mstatus_i[4:2],
                            1'b0, // sie <= 0
                            csr_mstatus_i[0]
                        };
                        csr_mstatus_we_o <= 1;
                        pc_next_exception_o <= csr_stvec_i;
                        priv_level_o <= `PRIV_S_LEVEL;
                        priv_level_we_o <= 1;
                    end else if (m_time_interrupt) begin // m time_interrupt
                        csr_mcause_o <= {1'b1, `MACHINE_TIMER_INTERRUPT};
                        csr_mcause_we_o <= 1;
                        csr_mtval_o <= csr_mtval_i;
                        csr_mtval_we_o <= 1;
                        csr_mepc_o <= next_pc;
                        csr_mepc_we_o <= 1;
                        csr_mstatus_o <= {
                            csr_mstatus_i[31:13],
                            priv_level_i, // mpp <= priv_level
                            csr_mstatus_i[10:8],
                            csr_mstatus_i[3], // mpie <= mie
                            csr_mstatus_i[6:4],
                            1'b0, // mie <= 0
                            csr_mstatus_i[2:0]
                        };
                        csr_mstatus_we_o <= 1;
                        pc_next_exception_o <= csr_mtvec_i;
                        priv_level_o <= `PRIV_M_LEVEL;
                        priv_level_we_o <= 1;
                    end else begin
                        case(csr_op_i)
                            `ENV_MRET: begin
                                csr_mstatus_o <= {
                                    csr_mstatus_i[31:13],
                                    `PRIV_U_LEVEL,
                                    csr_mstatus_i[10:8],
                                    1'b1, // mpie <= 1
                                    csr_mstatus_i[6:4],
                                    csr_mstatus_i[7], // mie <= mpie
                                    csr_mstatus_i[2:0]
                                };
                                csr_mstatus_we_o <= 1;
                                pc_next_exception_o <= csr_mepc_i;
                                priv_level_o <= csr_mstatus_i[12:11];
                                priv_level_we_o <= 1;
                            end
                            `ENV_ECALL: begin
                                logic [DATA_WIDTH-2:0] ecall_cause;
                                if (priv_level_i == `PRIV_U_LEVEL)begin
                                    ecall_cause = `ENVIRONMENT_CALL_FROM_U;
                                end else if (priv_level_i == `PRIV_S_LEVEL) begin
                                    ecall_cause = `ENVIRONMENT_CALL_FROM_S;
                                end else begin
                                    ecall_cause = `ENVIRONMENT_CALL_FROM_M;
                                end
                                if ((priv_level_i == `PRIV_U_LEVEL || priv_level_i == `PRIV_S_LEVEL) && csr_medeleg_i[ecall_cause]) begin // to S-level
                                    csr_scause_o <= {1'b0, ecall_cause};
                                    csr_scause_we_o <= 1;
                                    csr_stval_o <= csr_stval_i;
                                    csr_stval_we_o <= 1;
                                    csr_sepc_o <= mem_pc_i;
                                    csr_sepc_we_o <= 1;
                                    csr_mstatus_o <= {
                                        csr_mstatus_i[31:9],
                                        priv_level_i[0], // spp <= priv_level
                                        csr_mstatus_i[7:6],
                                        csr_mstatus_i[1], // spie <= sie
                                        csr_mstatus_i[4:2],
                                        1'b0, // sie <= 0
                                        csr_mstatus_i[0]
                                    };
                                    csr_mstatus_we_o <= 1;
                                    pc_next_exception_o <= csr_stvec_i;
                                    priv_level_o <= `PRIV_S_LEVEL;
                                    priv_level_we_o <= 1;
                                end else begin // to M-level
                                    csr_mcause_o <= {1'b0, ecall_cause};
                                    csr_mcause_we_o <= 1;
                                    csr_mtval_o <= csr_mtval_i;
                                    csr_mtval_we_o <= 1;
                                    csr_mepc_o <= mem_pc_i;
                                    csr_mepc_we_o <= 1;
                                    csr_mstatus_o <= {
                                        csr_mstatus_i[31:13],
                                        priv_level_i, // mpp <= priv_level
                                        csr_mstatus_i[10:8],
                                        csr_mstatus_i[3], // mpie <= mie
                                        csr_mstatus_i[6:4],
                                        1'b0, // mie <= 0
                                        csr_mstatus_i[2:0]
                                    };
                                    csr_mstatus_we_o <= 1;
                                    pc_next_exception_o <= csr_mtvec_i;
                                    priv_level_o <= `PRIV_M_LEVEL;
                                    priv_level_we_o <= 1;
                                end
                            end
                            `ENV_EBREAK: begin
                                if ((priv_level_i == `PRIV_U_LEVEL || priv_level_i == `PRIV_S_LEVEL) && csr_medeleg_i[`BREAKPOINT_EXCEPTION]) begin // to S-level
                                    csr_scause_o <= {1'b0, `BREAKPOINT_EXCEPTION};
                                    csr_scause_we_o <= 1;
                                    csr_stval_o <= mem_pc_i;
                                    csr_stval_we_o <= 1;
                                    csr_sepc_o <= mem_pc_i;
                                    csr_sepc_we_o <= 1;
                                    csr_mstatus_o <= {
                                        csr_mstatus_i[31:9],
                                        priv_level_i[0], // spp <= priv_level
                                        csr_mstatus_i[7:6],
                                        csr_mstatus_i[1], // spie <= sie
                                        csr_mstatus_i[4:2],
                                        1'b0, // sie <= 0
                                        csr_mstatus_i[0]
                                    };
                                    csr_mstatus_we_o <= 1;
                                    pc_next_exception_o <= csr_stvec_i;
                                    priv_level_o <= `PRIV_S_LEVEL;
                                    priv_level_we_o <= 1;
                                end else begin // to M-level
                                    csr_mcause_o <= {1'b0, `BREAKPOINT_EXCEPTION};
                                    csr_mcause_we_o <= 1;
                                    csr_mtval_o <= mem_pc_i;
                                    csr_mtval_we_o <= 1;
                                    csr_mepc_o <= mem_pc_i;
                                    csr_mepc_we_o <= 1;
                                    csr_mstatus_o <= {
                                        csr_mstatus_i[31:13],
                                        priv_level_i, // mpp <= priv_level
                                        csr_mstatus_i[10:8],
                                        csr_mstatus_i[3], // mpie <= mie
                                        csr_mstatus_i[6:4],
                                        1'b0, // mie <= 0
                                        csr_mstatus_i[2:0]
                                    };
                                    csr_mstatus_we_o <= 1;
                                    pc_next_exception_o <= csr_mtvec_i;
                                    priv_level_o <= `PRIV_M_LEVEL;
                                    priv_level_we_o <= 1;
                                end
                            end
                            `ENV_SRET: begin
                                csr_mstatus_o <= {
                                    csr_mstatus_i[31:9],
                                    1'b0, // u-level
                                    csr_mstatus_i[7:6],
                                    1'b1, // spie <= 1
                                    csr_mstatus_i[4:2],
                                    csr_mstatus_i[5], // sie <= spie
                                    csr_mstatus_i[0]
                                };
                                csr_mstatus_we_o <= 1;
                                pc_next_exception_o <= csr_sepc_i;
                                priv_level_o <= {1'b0, csr_mstatus_i[8]};
                                priv_level_we_o <= 1;
                            end
                            default: begin
                                csr_sepc_we_o <= 0;
                                csr_scause_we_o <= 0;
                                csr_stval_we_o <= 0;
                                csr_mstatus_we_o <= 0;
                                csr_mepc_we_o <= 0;
                                csr_mcause_we_o <= 0;
                                csr_mtval_we_o <= 0;
                                csr_mtvec_we_o <= 0;
                                csr_mie_we_o <= 0;
                                priv_level_we_o <= 0;
                            end
                        endcase
                    end
                end
            end
        end
    end

endmodule