`timescale 1ns / 1ps
`include "../header/csr.sv"

module CSR_reg #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input wire clk,
    input wire rst,
    input wire  [11:0]  csr_adr_i,
    input wire  [11:0]  csr_wadr_i,
    input wire  [DATA_WIDTH-1:0] csr_wdat_i,
    input wire  csr_we_i,
    output  reg [DATA_WIDTH-1:0] csr_o,

    input wire [DATA_WIDTH-1:0] csr_sepc_i,
    input wire csr_sepc_we_i,
    input wire [DATA_WIDTH-1:0] csr_scause_i,
    input wire csr_scause_we_i,
    input wire [DATA_WIDTH-1:0] csr_stval_i,
    input wire csr_stval_we_i,
    input wire [DATA_WIDTH-1:0] csr_mstatus_i,
    input wire csr_mstatus_we_i,
    input wire [DATA_WIDTH-1:0] csr_mtvec_i,
    input wire csr_mtvec_we_i,
    input wire [DATA_WIDTH-1:0] csr_mepc_i,
    input wire csr_mepc_we_i,
    input wire [DATA_WIDTH-1:0] csr_mcause_i,
    input wire csr_mcause_we_i,
    input wire [DATA_WIDTH-1:0] csr_mtval_i,
    input wire csr_mtval_we_i,
    input wire [DATA_WIDTH-1:0] csr_mip_i,
    input wire csr_mip_we_i,
    input wire [DATA_WIDTH-1:0] csr_mie_i,
    input wire csr_mie_we_i,

    output reg [DATA_WIDTH-1:0] csr_satp_o,
    output reg [DATA_WIDTH-1:0] csr_stvec_o,
    output reg [DATA_WIDTH-1:0] csr_stval_o,
    output reg [DATA_WIDTH-1:0] csr_sip_o,
    output reg [DATA_WIDTH-1:0] csr_sie_o,
    output reg [DATA_WIDTH-1:0] csr_sepc_o,
    output reg [DATA_WIDTH-1:0] csr_mstatus_o,
    output reg [DATA_WIDTH-1:0] csr_mtvec_o,
    output reg [DATA_WIDTH-1:0] csr_mtval_o,
    output reg [DATA_WIDTH-1:0] csr_mepc_o,
    output reg [DATA_WIDTH-1:0] csr_mcause_o,
    output reg [DATA_WIDTH-1:0] csr_mip_o,
    output reg [DATA_WIDTH-1:0] csr_mie_o,
    output reg [DATA_WIDTH-1:0] csr_medeleg_o,
    output reg [DATA_WIDTH-1:0] csr_mideleg_o,

    input wire [DATA_WIDTH-1:0] mtime_h_i,
    input wire [DATA_WIDTH-1:0] mtime_l_i,

    input wire [1:0] priv_level_i,
    input wire priv_level_we_i,
    output reg [1:0] priv_level_o
    );
    
    reg [DATA_WIDTH-1:0] satp;
    reg [DATA_WIDTH-1:0] sstatus; // TODO
    reg [DATA_WIDTH-1:0] sepc; // TODO
    reg [DATA_WIDTH-1:0] scause; // TODO
    reg [DATA_WIDTH-1:0] stval; // TODO
    reg [DATA_WIDTH-1:0] stvec; // TODO
    reg [DATA_WIDTH-1:0] sscratch; // TODO
    reg [DATA_WIDTH-1:0] sie; // TODO
    reg [DATA_WIDTH-1:0] sip; // TODO
    
    reg [DATA_WIDTH-1:0] mstatus; // TODO
    reg [DATA_WIDTH-1:0] mtvec;
    reg [DATA_WIDTH-1:0] mscratch;
    reg [DATA_WIDTH-1:0] mepc;
    reg [DATA_WIDTH-1:0] mcause;
    reg [DATA_WIDTH-1:0] mie; // TODO
    reg [DATA_WIDTH-1:0] mip; // TODO
    reg [DATA_WIDTH-1:0] mhartid; // TODO
    reg [DATA_WIDTH-1:0] mideleg; // TODO
    reg [DATA_WIDTH-1:0] medeleg; // TODO
    reg [DATA_WIDTH-1:0] mtval; // TODO

    reg [1:0] priv_level;
    
    always_comb begin
        case(csr_adr_i)
            12'h100: csr_o = sstatus;
            12'h104: csr_o = sie;
            12'h105: csr_o = stvec;
            12'h140: csr_o = sscratch;
            12'h141: csr_o = sepc;
            12'h142: csr_o = scause;
            12'h143: csr_o = stval;
            12'h144: csr_o = sip;
            12'h180: csr_o = satp;

            12'h300: csr_o = mstatus;
            12'h302: csr_o = medeleg;
            12'h303: csr_o = mideleg;
            12'h304: csr_o = mie;
            12'h305: csr_o = mtvec;
            12'h340: csr_o = mscratch;
            12'h341: csr_o = mepc;
            12'h342: csr_o = mcause;
            12'h343: csr_o = mtval;
            12'h344: csr_o = mip;

            12'hc01: csr_o = mtime_l_i;
            12'hc81: csr_o = mtime_h_i;

            12'hf14: csr_o = mhartid;
            default: csr_o = 0;
        endcase

        csr_satp_o = satp;
        csr_stvec_o = stvec;
        csr_stval_o = stval;
        csr_sip_o = sip;
        csr_sie_o = sie;
        csr_sepc_o = sepc;
        csr_mstatus_o = mstatus;
        csr_mtvec_o = mtvec;
        csr_mtval_o = mtval;
        csr_mepc_o = mepc;
        csr_mcause_o = mcause;
        csr_mip_o = mip;
        csr_mie_o = mie;
        csr_medeleg_o = medeleg;
        csr_mideleg_o = mideleg;

        priv_level_o = priv_level;
    end

    
    always_ff @(posedge clk) begin
        if(rst) begin
            priv_level <= `PRIV_M_LEVEL;
            satp <= 0;
            sstatus <= 0;
            sepc <= 0;
            scause <= 0;
            stval <= 0;
            stvec <= 0;
            sscratch <= 0;
            sie <= 0;
            sip <= 0;

            mstatus <= 0;
            mtvec <= 0;
            mscratch <= 0;
            mepc <= 0;
            mcause <= 0;
            mie <= 0;
            mip <= 0;
            mhartid <= 0;
            mideleg <= 0;
            medeleg <= 0;
            mtval <= 0;
        end else begin
            if (csr_we_i) begin
                case(csr_wadr_i)
                    12'h100: sstatus <= csr_wdat_i;
                    12'h104: sie <= csr_wdat_i;
                    12'h105: stvec <= csr_wdat_i;
                    12'h140: sscratch <= csr_wdat_i;
                    12'h141: sepc <= csr_wdat_i;
                    12'h142: scause <= csr_wdat_i;
                    12'h143: stval <= csr_wdat_i;
                    12'h144: sip <= csr_wdat_i;
                    12'h180: satp <= csr_wdat_i;

                    12'h300: mstatus <= csr_wdat_i;
                    12'h302: medeleg <= csr_wdat_i;
                    12'h303: mideleg <= csr_wdat_i;
                    12'h304: mie <= csr_wdat_i;
                    12'h305: mtvec <= csr_wdat_i;
                    12'h340: mscratch <= csr_wdat_i;
                    12'h341: mepc <= csr_wdat_i;
                    12'h342: mcause <= csr_wdat_i;
                    12'h343: mtval <= csr_wdat_i;
                    12'h344: mip <= csr_wdat_i;
                    12'hf14: mhartid <= csr_wdat_i;
                endcase
            end else begin
                if (csr_sepc_we_i) begin
                    sepc <= csr_sepc_i;
                end
                if (csr_scause_we_i) begin
                    scause <= csr_scause_i;
                end
                if (csr_stval_we_i) begin
                    stval <= csr_stval_i;
                end
                if (csr_mstatus_we_i) begin
                    mstatus <= csr_mstatus_i;
                end
                if (csr_mtvec_we_i) begin
                    mtvec <= csr_mtvec_i;
                end
                if (csr_mepc_we_i) begin
                    mepc <= csr_mepc_i;
                end
                if (csr_mcause_we_i) begin
                    mcause <= csr_mcause_i;
                end
                if (csr_mtval_we_i) begin
                    mtval <= csr_mtval_i;
                end
                if (csr_mip_we_i) begin
                    mip <= csr_mip_i;
                end
                if (csr_mie_we_i) begin
                    mie <= csr_mie_i;
                end
                if (priv_level_we_i) begin
                    priv_level <= priv_level_i;
                end
            end
        end
    end
    
endmodule
