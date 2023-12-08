`timescale 1ns / 1ps
`include "header/page_table_code.sv"
`include "header/csr.sv"

module IF_MMU #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (
    input wire clk,
    input wire rst,

    input wire [DATA_WIDTH-1:0] update_satp_i,
    input wire [DATA_WIDTH-1:0] new_satp_reg_i,
    input wire satp_update_i,
    input wire flush_tlb,
    input wire mem_exception_i,

    input wire if_fetch_instruction, //identify IF or MEM
    input wire [1:0] priv_level_i, // identify user mode

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
    output logic trans_req,

    // Data memory to MMU
    input wire master_ready_o,
    input wire [DATA_WIDTH-1:0] data_out,

    // report exception
    output logic exception_occured_o,
    output logic [DATA_WIDTH-1:0] exception_cause_o
);

    logic [1:0] wishbone_owner;
    logic [1:0] tlb_wishbone_owner;
    logic tlb_en;
    always_comb begin
        // judge wishbone_owner
        if(mmu_addr <= 32'h807f_ffff && mmu_addr >= 32'h8000_0000)begin // SRAM
            if(priv_level_i != `PRIV_M_LEVEL && !mem_exception_i)begin
                wishbone_owner = tlb_wishbone_owner;
                tlb_en = 1;
            end else begin
                wishbone_owner = `MMU_OWN;
                tlb_en = 0;
            end
        end else begin
            wishbone_owner = `MMU_OWN;
            tlb_en = 0;
        end
    end
    assign trans_req = (wishbone_owner == `TRANSLATE_OWN);

    // include TLB, Translation, Cache, arbeiter
    logic tlb_ready;
    logic [DATA_WIDTH-1:0] query_data_o;
    logic [ADDR_WIDTH-1:0] tlb_query_addr;
    logic translation_en;
    logic translation_ready;
    logic translation_error;
    logic [ADDR_WIDTH-1:0] translation_result;
    logic [ADDR_WIDTH-1:0] phy_addr;
    logic cache_mem_en;
    logic cache_write_en;
    logic [DATA_WIDTH-1:0] cache_mem_data_o;
    logic [DATA_WIDTH/8-1:0] cache_mem_sel_o;
    logic cache_ready;
    logic [DATA_WIDTH-1:0] cache_result;

    satp_t satp;
    always_comb begin
        if(satp_update_i)begin
            satp = update_satp_i;
        end else begin
            satp = new_satp_reg_i;
        end
    end

    logic to_trans_query_write_en;

    TLB tlb_u(
        .clk(clk),
        .rst(rst),
        
        .tlb_en(tlb_en),
        .flush_tlb(flush_tlb),
        .satp_i(satp),
        .wishbone_owner(tlb_wishbone_owner),

        .query_addr(mmu_addr),
        .query_data_i(mmu_data_in),
        .query_mem_en(mmu_mem_en),
        .query_write_en(mmu_write_en),
        .query_sel(mmu_sel),

        .tlb_ready(tlb_ready),
        .query_data_o(query_data_o),

        .tlb_query_addr(tlb_query_addr),
        .translation_en(translation_en),
        .to_trans_query_write_en(to_trans_query_write_en),

        .translation_ready(translation_ready),
        .translation_error(translation_error),
        .translation_result(translation_result),
        
        .phy_addr(phy_addr),
        .cache_mem_en(cache_mem_en),
        .cache_write_en(cache_write_en),
        .cache_mem_data_o(cache_mem_data_o),
        .cache_mem_sel_o(cache_mem_sel_o),
        .cache_ready(cache_ready),
        .cache_error(1'b0),
        .cache_result(cache_result)
    );

    logic if_user_mode;
    assign if_user_mode = (priv_level_i == `PRIV_U_LEVEL);
    logic trans_ack;
    logic [DATA_WIDTH-1:0] trans_dat_i;
    logic trans_cyc;
    logic trans_stb;
    logic [ADDR_WIDTH-1:0] trans_adr_o;
    logic [DATA_WIDTH-1:0] trans_dat_o;
    logic [DATA_WIDTH/8-1:0] trans_sel_o;
    logic trans_we_o;
    logic instruction_page_fault;
    logic load_page_fault;
    logic store_page_fault;
    assign translation_error = instruction_page_fault | load_page_fault | store_page_fault;
    Translation translation_u(
        .clk(clk),
        .rst(rst),
        .if_fetch_instruction(if_fetch_instruction),
        .if_user_mode(if_user_mode),
        .query_addr(tlb_query_addr),
        .translation_en(translation_en),
        .query_write_en(to_trans_query_write_en),
        .translation_ready(translation_ready),
        .query_addr_o(translation_result),
        .wb_ack_i(trans_ack),
        .wb_dat_i(trans_dat_i),
        .wb_cyc_o(trans_cyc),
        .wb_stb_o(trans_stb),
        .wb_adr_o(trans_adr_o),
        .wb_dat_o(trans_dat_o),
        .wb_sel_o(trans_sel_o),
        .wb_we_o(trans_we_o),
        .satp_i(satp),
        .instruction_page_fault(instruction_page_fault),
        .load_page_fault(load_page_fault),
        .store_page_fault(store_page_fault)
    );

    logic [30:0] exception_code;
    always_comb begin
        if(instruction_page_fault)begin
            exception_code = 12;
        end else if(load_page_fault)begin
            exception_code = 13;
        end else if(store_page_fault) begin
            exception_code = 15;
        end else begin
            exception_code = 0;
        end
        exception_occured_o = instruction_page_fault | load_page_fault | store_page_fault;
        exception_cause_o = {1'b0, exception_code};
    end

    logic cache_cyc;
    logic cache_stb;
    logic [ADDR_WIDTH-1:0] cache_adr;
    logic [DATA_WIDTH/8-1:0] cache_sel;
    logic cache_we;
    logic cache_ack;
    logic [DATA_WIDTH-1:0] cache_dat_i;
    instruction_cache instr_cache(
        .clk(clk),
        .rst(rst),
        
        .wb_cyc_o(cache_cyc),
        .wb_stb_o(cache_stb),
        .wb_adr_o(cache_adr),
        .wb_sel_o(cache_sel),
        .wb_we_o(cache_we),
        .wb_ack_i(cache_ack),
        .wb_dat_i(cache_dat_i),

        .master_ready_o(cache_ready),
        .mem_en(cache_mem_en),
        .addr(phy_addr),
        .sel(cache_mem_sel_o),
        .data_out(cache_result)
    );

    // arbeiter
    always_comb begin
        case (wishbone_owner)
            `MMU_OWN: begin
                mem_en = mmu_mem_en;
                write_en = mmu_write_en;
                addr = mmu_addr;
                data_in = mmu_data_in;
                sel = mmu_sel;

                mmu_ready_o = master_ready_o;
                mmu_data_out = data_out;
                trans_ack = 0;
                trans_dat_i = 0;
                cache_ack = 0;
                cache_dat_i = 0;
            end
            `TRANSLATE_OWN: begin
                mem_en = trans_stb;
                write_en = trans_we_o;
                addr = trans_adr_o;
                data_in = trans_dat_o;
                sel = trans_sel_o;

                mmu_ready_o = 0;
                mmu_data_out = 0;
                trans_ack = master_ready_o;
                trans_dat_i = data_out;
                cache_ack = 0;
                cache_dat_i = 0;
            end
            `CACHE_OWN: begin
                mem_en = cache_stb;
                write_en = 0; // read only
                addr = cache_adr;
                data_in = 0;
                sel = cache_sel;

                mmu_ready_o = 0;
                mmu_data_out = 0;
                trans_ack = 0;
                trans_dat_i = 0;
                cache_ack = master_ready_o;
                cache_dat_i = data_out;
            end
            default: begin
                mem_en = mmu_mem_en;
                write_en = mmu_write_en;
                addr = mmu_addr;
                data_in = mmu_data_in;
                sel = mmu_sel;

                mmu_ready_o = master_ready_o;
                mmu_data_out = data_out;
                trans_ack = 0;
                trans_dat_i = 0;
                cache_ack = 0;
                cache_dat_i = 0;
            end
        endcase
    end
    
endmodule

module MEM_MMU #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (
    input wire clk,
    input wire rst,

    input wire [DATA_WIDTH-1:0] satp_i,
    input wire flush_tlb,

    input wire if_fetch_instruction, //identify IF or MEM
    input wire [1:0] priv_level_i, // identify user mode

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
    output logic trans_req,

    // Data memory to MMU
    input wire master_ready_o,
    input wire [DATA_WIDTH-1:0] data_out,

    // report exception
    output logic exception_occured_o,
    output logic [DATA_WIDTH-1:0] exception_cause_o
);

    logic [1:0] wishbone_owner;
    logic [1:0] tlb_wishbone_owner;
    logic tlb_en;
    always_comb begin
        // judge wishbone_owner
        if(mmu_addr <= 32'h807f_ffff && mmu_addr >= 32'h8000_0000)begin // SRAM
            if(priv_level_i != `PRIV_M_LEVEL)begin
                wishbone_owner = tlb_wishbone_owner;
                tlb_en = 1;
            end else begin
                wishbone_owner = `MMU_OWN;
                tlb_en = 0;
            end
        end else begin
            wishbone_owner = `MMU_OWN;
            tlb_en = 0;
        end
    end
    assign trans_req = (wishbone_owner == `TRANSLATE_OWN);

    // include TLB, Translation, arbeiter
    logic tlb_ready;
    logic [DATA_WIDTH-1:0] query_data_o;
    logic [ADDR_WIDTH-1:0] tlb_query_addr;
    logic translation_en;
    logic translation_ready;
    logic translation_error;
    logic [ADDR_WIDTH-1:0] translation_result;
    logic [ADDR_WIDTH-1:0] phy_addr;
    logic cache_mem_en;
    logic cache_write_en;
    logic [DATA_WIDTH-1:0] cache_mem_data_o;
    logic [DATA_WIDTH/8-1:0] cache_mem_sel_o;
    logic cache_ready;
    logic [DATA_WIDTH-1:0] cache_result;

    satp_t satp;
    assign satp = satp_i;

    logic to_trans_query_write_en;
    TLB tlb_u(
        .clk(clk),
        .rst(rst),
        
        .tlb_en(tlb_en),
        .flush_tlb(flush_tlb),
        .satp_i(satp),
        .wishbone_owner(tlb_wishbone_owner),

        .query_addr(mmu_addr),
        .query_data_i(mmu_data_in),
        .query_mem_en(mmu_mem_en),
        .query_write_en(mmu_write_en),
        .query_sel(mmu_sel),

        .tlb_ready(tlb_ready),
        .query_data_o(query_data_o),

        .tlb_query_addr(tlb_query_addr),
        .translation_en(translation_en),
        .to_trans_query_write_en(to_trans_query_write_en),

        .translation_ready(translation_ready),
        .translation_error(translation_error),
        .translation_result(translation_result),
        
        .phy_addr(phy_addr),
        .cache_mem_en(cache_mem_en),
        .cache_write_en(cache_write_en),
        .cache_mem_data_o(cache_mem_data_o),
        .cache_mem_sel_o(cache_mem_sel_o),
        .cache_ready(cache_ready),
        .cache_error(1'b0),
        .cache_result(cache_result)
    );

    logic if_user_mode;
    assign if_user_mode = (priv_level_i == `PRIV_U_LEVEL);
    logic trans_ack;
    logic [DATA_WIDTH-1:0] trans_dat_i;
    logic trans_cyc;
    logic trans_stb;
    logic [ADDR_WIDTH-1:0] trans_adr_o;
    logic [DATA_WIDTH-1:0] trans_dat_o;
    logic [DATA_WIDTH/8-1:0] trans_sel_o;
    logic trans_we_o;
    logic instruction_page_fault;
    logic load_page_fault;
    logic store_page_fault;
    assign translation_error = instruction_page_fault | load_page_fault | store_page_fault;
    Translation translation_u(
        .clk(clk),
        .rst(rst),
        .if_fetch_instruction(if_fetch_instruction),
        .if_user_mode(if_user_mode),
        .query_addr(tlb_query_addr),
        .translation_en(translation_en),
        .query_write_en(to_trans_query_write_en),
        .translation_ready(translation_ready),
        .query_addr_o(translation_result),
        .wb_ack_i(trans_ack),
        .wb_dat_i(trans_dat_i),
        .wb_cyc_o(trans_cyc),
        .wb_stb_o(trans_stb),
        .wb_adr_o(trans_adr_o),
        .wb_dat_o(trans_dat_o),
        .wb_sel_o(trans_sel_o),
        .wb_we_o(trans_we_o),
        .satp_i(satp),
        .instruction_page_fault(instruction_page_fault),
        .load_page_fault(load_page_fault),
        .store_page_fault(store_page_fault)
    );

    logic [30:0] exception_code;
    always_comb begin
        if(instruction_page_fault)begin
            exception_code = 12;
        end else if(load_page_fault)begin
            exception_code = 13;
        end else if(store_page_fault) begin
            exception_code = 15;
        end else begin
            exception_code = 0;
        end
        exception_occured_o = instruction_page_fault | load_page_fault | store_page_fault;
        exception_cause_o = {1'b0, exception_code};
    end

    // no cache, connect directly
    logic cache_cyc;
    logic cache_stb;
    logic [ADDR_WIDTH-1:0] cache_adr;
    logic [DATA_WIDTH/8-1:0] cache_sel;
    logic cache_we;
    logic [ADDR_WIDTH-1:0] cache_dat_o;
    logic cache_ack;
    logic [DATA_WIDTH-1:0] cache_dat_i;
    always_comb begin
        cache_cyc = cache_mem_en;
        cache_stb = cache_mem_en;
        cache_adr = phy_addr;
        cache_sel = cache_mem_sel_o;
        cache_we = cache_write_en;
        cache_dat_o = cache_mem_data_o;
        cache_ready = cache_ack;
        cache_result = cache_dat_i;
    end

    // arbeiter
    always_comb begin
        case (wishbone_owner)
            `MMU_OWN: begin
                mem_en = mmu_mem_en;
                write_en = mmu_write_en;
                addr = mmu_addr;
                data_in = mmu_data_in;
                sel = mmu_sel;

                mmu_ready_o = master_ready_o;
                mmu_data_out = data_out;
                trans_ack = 0;
                trans_dat_i = 0;
                cache_ack = 0;
                cache_dat_i = 0;
            end
            `TRANSLATE_OWN: begin
                mem_en = trans_stb;
                write_en = trans_we_o;
                addr = trans_adr_o;
                data_in = trans_dat_o;
                sel = trans_sel_o;

                mmu_ready_o = 0;
                mmu_data_out = 0;
                trans_ack = master_ready_o;
                trans_dat_i = data_out;
                cache_ack = 0;
                cache_dat_i = 0;
            end
            `CACHE_OWN: begin
                mem_en = cache_stb;
                write_en = cache_we; // read only
                addr = cache_adr;
                data_in = cache_dat_o;
                sel = cache_sel;

                mmu_ready_o = 0;
                mmu_data_out = 0;
                trans_ack = 0;
                trans_dat_i = 0;
                cache_ack = master_ready_o;
                cache_dat_i = data_out;
            end
            default: begin
                mem_en = mmu_mem_en;
                write_en = mmu_write_en;
                addr = mmu_addr;
                data_in = mmu_data_in;
                sel = mmu_sel;

                mmu_ready_o = master_ready_o;
                mmu_data_out = data_out;
                trans_ack = 0;
                trans_dat_i = 0;
                cache_ack = 0;
                cache_dat_i = 0;
            end
        endcase
    end
    
endmodule