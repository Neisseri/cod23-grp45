`timescale 1ns/1ps
`include "../header/opcode.sv"
`include "../header/csr.sv"

module CSR_controller #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input wire clk,
    input wire rst,
    input wire stall,
    input wire bubble,

    input wire [DATA_WIDTH-1:0] rs1_dat_i,
    input wire [11:0] csr_adr_i,
    input wire csr_we_i,
    input wire [3:0] csr_op_i,

    output reg [DATA_WIDTH-1:0] csr_o,

    input wire [DATA_WIDTH-1:0] csr_i,
    output reg [11:0] csr_adr_o,
    output reg [DATA_WIDTH-1:0] csr_wdat_o,
    output reg csr_we_o,

    input wire [DATA_WIDTH-1:0] csr_mstatus_i,
    input wire [DATA_WIDTH-1:0] csr_mtvec_i,
    input wire [DATA_WIDTH-1:0] csr_mepc_i,
    input wire [DATA_WIDTH-1:0] csr_mcause_i,
    input wire [DATA_WIDTH-1:0] csr_mip_i,
    input wire [DATA_WIDTH-1:0] csr_mie_i,

    output logic [DATA_WIDTH-1:0] csr_mstatus_o,
    output logic csr_mstatus_we_o,
    output logic [DATA_WIDTH-1:0] csr_mtvec_o,
    output logic csr_mtvec_we_o,
    output logic [DATA_WIDTH-1:0] csr_mepc_o,
    output logic csr_mepc_we_o,
    output logic [DATA_WIDTH-1:0] csr_mcause_o,
    output logic csr_mcause_we_o,
    output logic [DATA_WIDTH-1:0] csr_mip_o,
    output logic csr_mip_we_o,
    output logic [DATA_WIDTH-1:0] csr_mie_o,
    output logic csr_mie_we_o,

    input wire [ADDR_WIDTH-1:0] mem_pc_i,
    output reg [ADDR_WIDTH-1:0] pc_next_exception_o,
    output reg mem_exception_o,
    output reg [1:0] priv_level_o,
    output reg priv_level_we_o,
    input wire [1:0] priv_level_i,

    input wire time_interrupt_i,

    input wire exception_occured_i,
    input wire [DATA_WIDTH-1:0] exception_cause_i,
    input wire [ADDR_WIDTH-1:0] exception_pc_i
    );

    reg exception_idle; // set 1 for idle after handling a exception

    always_comb begin
        csr_adr_o = 0;
        csr_wdat_o = 0;
        csr_we_o = 0;
        csr_o = 0;
        csr_mip_o = 0;
        csr_mip_we_o = 0;
        if (!exception_idle && !stall) begin
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

    always_ff @(posedge clk) begin
        if(rst) begin
            csr_mstatus_we_o <= 0;
            csr_mepc_we_o <= 0;
            csr_mcause_we_o <= 0;
            csr_mtvec_we_o <= 0;
            csr_mie_we_o <= 0;
            priv_level_we_o <= 0;
            mem_exception_o <= 0;
            exception_idle <= 0;
        end else begin
            if (!stall) begin
                if (bubble || exception_idle) begin
                    csr_mstatus_we_o <= 0;
                    priv_level_we_o <= 0;
                    csr_mepc_we_o <= 0;
                    csr_mcause_we_o <= 0;
                    csr_mtvec_we_o <= 0;
                    csr_mie_we_o <= 0;
                    mem_exception_o <= 0;
                    exception_idle <= 0;
                end else begin
                    csr_mtvec_we_o <= 0;
                    csr_mie_we_o <= 0;
                    if (exception_occured_i) begin
                        csr_mcause_o <= exception_cause_i;
                        csr_mcause_we_o <= 1;
                        csr_mepc_o <= exception_pc_i;
                        csr_mepc_we_o <= 1;
                        csr_mstatus_o <= {
                            csr_mstatus_i[31:13],
                            `PRIV_U_LEVEL,
                            csr_mstatus_i[10:8],
                            csr_mstatus_i[3], // mpie <= mie
                            csr_mstatus_i[6:4],
                            1'b0, // mie <= 0
                            csr_mstatus_i[2:0]
                        };
                        csr_mstatus_we_o <= 1;
                        pc_next_exception_o <= csr_mtvec_i;
                        mem_exception_o <= 1;
                        exception_idle <= 1;
                        priv_level_o <= `PRIV_M_LEVEL;
                        priv_level_we_o <= 1;
                    end else if (csr_mip_i[7] && csr_mie_i[7] && (priv_level_i == `PRIV_U_LEVEL || (priv_level_i == `PRIV_M_LEVEL && csr_mstatus_i[3]))) begin // time_interrupt
                        csr_mcause_o <= {1'b1, `USER_TIMER_INTERRUPT};
                        csr_mcause_we_o <= 1;
                        csr_mepc_o <= mem_pc_i;
                        csr_mepc_we_o <= 1;
                        csr_mstatus_o <= {
                            csr_mstatus_i[31:13],
                            `PRIV_U_LEVEL,
                            csr_mstatus_i[10:8],
                            csr_mstatus_i[3], // mpie <= mie
                            csr_mstatus_i[6:4],
                            1'b0, // mie <= 0
                            csr_mstatus_i[2:0]
                        };
                        csr_mstatus_we_o <= 1;
                        pc_next_exception_o <= csr_mtvec_i;
                        mem_exception_o <= 1;
                        exception_idle <= 1;
                        priv_level_o <= `PRIV_M_LEVEL;
                        priv_level_we_o <= 1;
                    end else begin
                        case(csr_op_i)
                            `ENV_MRET: begin
                                csr_mstatus_o <= {
                                    csr_mstatus_i[31:13],
                                    `PRIV_M_LEVEL,
                                    csr_mstatus_i[10:8],
                                    1'b1, // mpie <= 1
                                    csr_mstatus_i[6:4],
                                    csr_mstatus_i[7], // mie <= mpie
                                    csr_mstatus_i[2:0]
                                };
                                csr_mstatus_we_o <= 1;
                                pc_next_exception_o <= csr_mepc_i;
                                mem_exception_o <= 1;
                                exception_idle <= 1;
                                priv_level_o <= csr_mstatus_i[12:11];
                                priv_level_we_o <= 1;
                            end
                            `ENV_ECALL: begin
                                csr_mcause_o <= {1'b0, `ENVIRONMENT_CALL_FROM_U};
                                csr_mcause_we_o <= 1;
                                csr_mepc_o <= mem_pc_i;
                                csr_mepc_we_o <= 1;
                                csr_mstatus_o <= {
                                    csr_mstatus_i[31:13],
                                    `PRIV_U_LEVEL,
                                    csr_mstatus_i[10:8],
                                    csr_mstatus_i[3], // mpie <= mie
                                    csr_mstatus_i[6:4],
                                    1'b0, // mie <= 0
                                    csr_mstatus_i[2:0]
                                };
                                csr_mstatus_we_o <= 1;
                                pc_next_exception_o <= csr_mtvec_i;
                                mem_exception_o <= 1;
                                exception_idle <= 1;
                                priv_level_o <= `PRIV_M_LEVEL;
                                priv_level_we_o <= 1;
                            end
                            `ENV_EBREAK: begin 
                                csr_mcause_o <= {1'b0, `BREAKPOINT_EXCEPTION};
                                csr_mcause_we_o <= 1;
                                csr_mepc_o <= mem_pc_i;
                                csr_mepc_we_o <= 1;
                                csr_mstatus_o <= {
                                    csr_mstatus_i[31:13],
                                    `PRIV_U_LEVEL,
                                    csr_mstatus_i[10:8],
                                    csr_mstatus_i[3], // mpie <= mie
                                    csr_mstatus_i[6:4],
                                    1'b0, // mie <= 0
                                    csr_mstatus_i[2:0]
                                };
                                csr_mstatus_we_o <= 1;
                                pc_next_exception_o <= csr_mtvec_i;
                                mem_exception_o <= 1;
                                exception_idle <= 1;
                                priv_level_o <= `PRIV_M_LEVEL;
                                priv_level_we_o <= 1;
                            end
                            default: begin
                                csr_mstatus_we_o <= 0;
                                priv_level_we_o <= 0;
                                csr_mepc_we_o <= 0;
                                csr_mcause_we_o <= 0;
                                mem_exception_o <= 0;
                                exception_idle <= 0;
                            end
                        endcase
                    end
                end
            end
        end
    end

endmodule