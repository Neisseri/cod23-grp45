`timescale 1ns/1ps
`include "../header/opcode.sv"

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
    output reg [DATA_WIDTH-1:0] csr_adr_o,
    output reg [DATA_WIDTH-1:0] csr_wdat_o,
    output reg csr_we_o
    );

    always_comb begin
        case(csr_op_i)
            `CSR_CSRRW: begin
                csr_adr_o = csr_adr_i;
                csr_wdat_o = rs1_dat_i;
                csr_we_o = csr_we_i;
            end
            `CSR_CSRRS: begin
                csr_adr_o = csr_adr_i;
                csr_wdat_o = csr_i | rs1_dat_i;
                csr_we_o = csr_we_i;
            end
            `CSR_CSRRC: begin
                csr_adr_o = csr_adr_i;
                csr_wdat_o = csr_i & ~rs1_dat_i;
                csr_we_o = csr_we_i;
            end
            default: begin
                csr_adr_o = 0;
                csr_wdat_o = 0;
                csr_we_o = 0;
            end
        endcase
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            csr_o <= 0;
        end else begin
            if (!stall) begin
                if (bubble) begin
                    csr_o <= 0;
                end else begin
                    csr_o <= csr_i;
                end
            end
        end
    end

endmodule