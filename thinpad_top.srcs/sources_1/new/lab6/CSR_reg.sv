`timescale 1ns / 1ps

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
    output  reg [DATA_WIDTH-1:0] csr_o
    );
    
    reg [DATA_WIDTH-1:0] mstatus;
    reg [DATA_WIDTH-1:0] mtvec;
    reg [DATA_WIDTH-1:0] mscratch;
    reg [DATA_WIDTH-1:0] mepc;
    reg [DATA_WIDTH-1:0] mcause;
    reg [DATA_WIDTH-1:0] mie;
    reg [DATA_WIDTH-1:0] mip;
    
    always_comb begin
        case(csr_adr_i)
            12'h300: csr_o = mstatus;
            12'h304: csr_o = mie;
            12'h305: csr_o = mtvec;
            12'h340: csr_o = mscratch;
            12'h341: csr_o = mepc;
            12'h342: csr_o = mcause;
            12'h344: csr_o = mip;
        endcase
    end

    
    always_ff @(posedge clk) begin
        if(rst) begin
            // TODO: reset
        end else begin
            if (csr_we_i) begin
                case(csr_wadr_i)
                    12'h300: mstatus <= csr_wdat_i;
                    12'h304: mie <= csr_wdat_i;
                    12'h305: mtvec <= csr_wdat_i;
                    12'h340: mscratch <= csr_wdat_i;
                    12'h341: mepc <= csr_wdat_i;
                    12'h342: mcause <= csr_wdat_i;
                    12'h344: mip <= csr_wdat_i;
                endcase
            end
        end
    end
    
endmodule
