`timescale 1ns / 1ps
`include "../header/page_table_code.sv"

module MMU #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (
    input wire clk,
    input wire rst,

    // CPU to MMU
    input wire mmu_mem_en,
    input wire mmu_write_en,
    input wire [ADDR_WIDTH-1:0] mmu_addr,
    input wire [DATA_WIDTH-1:0] mmu_data_in,
    input wire [DATA_WIDTH/8-1:0] mmu_sel,

    // MMU to CPU
    output logic mmu_ready_o,
    output logic [DATA_WIDTH-1:0] mmu_data_out,

    // MMU to Data memory
    output logic mem_en,
    output logic write_en,
    output logic [ADDR_WIDTH-1:0] addr,
    output logic [DATA_WIDTH-1:0] data_in,
    output logic [DATA_WIDTH/8-1:0] sel,

    // Data memory to MMU
    input wire master_ready_o,
    input wire [DATA_WIDTH-1:0] data_out,
);

    // include TLB, Translation, Cache, arbeiter
    logic [1:0] tlb_wishbone_owner;
    TLB tlb_u(

    );

    Translation translation_u(

    );

    // Cache

    // arbeiter
    assign mmu_ready_o = master_ready_o;
    assign mmu_data_out = data_out;

    logic [1:0] wishbone_owner;
    always_comb begin
        // judge wishbone_owner
        if(mmu_addr <= 32'h807f_ffff && mmu_addr >= 32'h8000_0000)begin // SRAM
            wishbone_owner = tlb_wishbone_owner;
        end else begin
            wishbone_owner = `MMU_OWN;
        end

        case (wishbone_owner)
            `MMU_OWN: begin
                mem_en = mmu_mem_en;
                write_en = mmu_write_en;
                addr = mmu_addr;
                data_in = mmu_data_in;
                sel = mmu_sel;
            end
            `TRANSLATE_OWN: begin
                
            end
            `CACHE_OWN: begin
                
            end
            default: begin
                mem_en = mmu_mem_en;
                write_en = mmu_write_en;
                addr = mmu_addr;
                data_in = mmu_data_in;
                sel = mmu_sel;
            end
        endcase
    end
    
endmodule
