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

    input wire [DATA_WIDTH-1:0] csr_mstatus_i,
    input wire csr_mstatus_we_i,
    input wire [DATA_WIDTH-1:0] csr_mtvec_i,
    input wire csr_mtvec_we_i,
    input wire [DATA_WIDTH-1:0] csr_mepc_i,
    input wire csr_mepc_we_i,
    input wire [DATA_WIDTH-1:0] csr_mcause_i,
    input wire csr_mcause_we_i,
    input wire [DATA_WIDTH-1:0] csr_mip_i,
    input wire csr_mip_we_i,
    input wire [DATA_WIDTH-1:0] csr_mie_i,
    input wire csr_mie_we_i,

    output reg [DATA_WIDTH-1:0] csr_satp_o,

    output reg [DATA_WIDTH-1:0] csr_mstatus_o,
    output reg [DATA_WIDTH-1:0] csr_mtvec_o,
    output reg [DATA_WIDTH-1:0] csr_mepc_o,
    output reg [DATA_WIDTH-1:0] csr_mcause_o,
    output reg [DATA_WIDTH-1:0] csr_mip_o,
    output reg [DATA_WIDTH-1:0] csr_mie_o,

    input wire [1:0] priv_level_i,
    input wire priv_level_we_i,
    output reg [1:0] priv_level_o
    );

    reg [DATA_WIDTH-1:0] satp;
    
    reg [DATA_WIDTH-1:0] mstatus;
    reg [DATA_WIDTH-1:0] mtvec;
    reg [DATA_WIDTH-1:0] mscratch;
    reg [DATA_WIDTH-1:0] mepc;
    reg [DATA_WIDTH-1:0] mcause;
    reg [DATA_WIDTH-1:0] mie;
    reg [DATA_WIDTH-1:0] mip;
    reg [1:0] priv_level;
    
    always_comb begin
        case(csr_adr_i)
             // TODO: correct reset value
            12'h180: csr_o = satp;

            12'h300: csr_o = mstatus;
            12'h304: csr_o = mie;
            12'h305: csr_o = mtvec;
            12'h340: csr_o = mscratch;
            12'h341: csr_o = mepc;
            12'h342: csr_o = mcause;
            12'h344: csr_o = mip;
        endcase

        csr_satp_o = satp;

        csr_mstatus_o = mstatus;
        csr_mtvec_o = mtvec;
        csr_mepc_o = mepc;
        csr_mcause_o = mcause;
        csr_mip_o = mip;
        csr_mie_o = mie;
        priv_level_o = priv_level;
    end

    
    always_ff @(posedge clk) begin
        if(rst) begin
            priv_level <= `PRIV_M_LEVEL;
            satp <= 0;

            mstatus <= 0;
            mtvec <= 0;
            mscratch <= 0;
            mepc <= 0;
            mcause <= 0;
            mie <= 0;
            mip <= 0;
        end else begin
            if (csr_we_i) begin
                case(csr_wadr_i)
                    12'h180: satp <= csr_wdat_i;

                    12'h300: mstatus <= csr_wdat_i;
                    12'h304: mie <= csr_wdat_i;
                    12'h305: mtvec <= csr_wdat_i;
                    12'h340: mscratch <= csr_wdat_i;
                    12'h341: mepc <= csr_wdat_i;
                    12'h342: mcause <= csr_wdat_i;
                    12'h344: mip <= csr_wdat_i;
                endcase
            end else begin
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
