`timescale 1ns / 1ps
`include "header/page_table_code.svh"
`include "header/csr.svh"

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
    input wire mstatus_sum,
    input wire pc_stall,

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
    input wire ack,

    // report exception
    output logic exception_occured_o,
    output logic [DATA_WIDTH-1:0] exception_cause_o,
    output logic [DATA_WIDTH-1:0] exception_val_o
);

    satp_t satp;
    // always_comb begin
    //     if(satp_update_i)begin
    //         satp = update_satp_i;
    //     end else begin
    //         satp = new_satp_reg_i;
    //     end
    // end
    assign satp = new_satp_reg_i;

    logic [1:0] wishbone_owner;
    logic [1:0] tlb_wishbone_owner;
    logic tlb_en;
    logic permit_cache;
    logic access_user_page_table;
    assign access_user_page_table = (satp.mode != 1'b0) && (priv_level_i != `PRIV_M_LEVEL);//(priv_level_i == `PRIV_U_LEVEL) || ((priv_level_i == `PRIV_S_LEVEL && mstatus_sum));
    always_comb begin
        // judge wishbone_owner
        if(access_user_page_table && !mem_exception_i && mmu_mem_en)begin
            wishbone_owner = tlb_wishbone_owner;
            tlb_en = 1;
            permit_cache = 0;
        end else begin
            tlb_en = 0;
            if(mmu_addr <= 32'h807f_ffff && mmu_addr >= 32'h8000_0000)begin // SRAM
                permit_cache = 1;
                wishbone_owner = `CACHE_OWN;
            end else begin
                permit_cache = 0;
                wishbone_owner = `MMU_OWN;
            end
        end
    end

    // include TLB, Translation, Cache, arbeiter
    logic tlb_ready;
    logic [DATA_WIDTH-1:0] query_data_o;
    logic [ADDR_WIDTH-1:0] tlb_query_addr;
    logic translation_en;
    logic translation_ready;
    logic translation_error;
    logic [ADDR_WIDTH-1:0] translation_result;
    logic [ADDR_WIDTH-1:0] phy_addr;
    logic tlb_cache_mem_en;
    logic tlb_cache_write_en;
    logic [DATA_WIDTH-1:0] tlb_cache_mem_data_o;
    logic [DATA_WIDTH/8-1:0] tlb_cache_mem_sel_o;
    logic tlb_cache_ready;
    logic [DATA_WIDTH-1:0] tlb_cache_result;

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
        .cache_mem_en(tlb_cache_mem_en),
        .cache_write_en(tlb_cache_write_en),
        .cache_mem_data_o(tlb_cache_mem_data_o),
        .cache_mem_sel_o(tlb_cache_mem_sel_o),
        .cache_ready(tlb_cache_ready),
        .cache_error(1'b0),
        .cache_result(tlb_cache_result)
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
    logic trans_running;
    logic instruction_page_fault;
    logic load_page_fault;
    logic store_page_fault;
    
    logic cache_cyc;
    logic cache_stb;
    logic [ADDR_WIDTH-1:0] cache_adr;
    logic [DATA_WIDTH/8-1:0] cache_sel;
    logic cache_we;
    logic cache_ack;
    logic [DATA_WIDTH-1:0] cache_dat_i;
    
    assign translation_error = instruction_page_fault | load_page_fault | store_page_fault;
    assign trans_req = ((wishbone_owner == `TRANSLATE_OWN) && trans_running) || ((wishbone_owner == `CACHE_OWN) && cache_stb);
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
        .trans_running(trans_running),
        .satp_i(satp),
        .bubble(1'b0),
        .stall(pc_stall),
        .instruction_page_fault(instruction_page_fault),
        .load_page_fault(load_page_fault),
        .store_page_fault(store_page_fault)
    );

    logic valid_phy_addr;
    assign valid_phy_addr = (mmu_addr >= 32'h8000_0000 && mmu_addr <= 32'h807f_ffff) || (mmu_addr >= 32'h1000_0000 && mmu_addr <= 32'h1000_ffff) || (mmu_addr >= 32'h0200_0000 && mmu_addr <= 32'h0200_ffff);
    logic invalid_phy_addr_fault;
    assign invalid_phy_addr_fault = !access_user_page_table && mmu_mem_en && !valid_phy_addr;

    logic [30:0] exception_code;
    always_comb begin
        if(instruction_page_fault)begin
            exception_code = 12;
        end else if(load_page_fault)begin
            exception_code = 13;
        end else if(store_page_fault) begin
            exception_code = 15;
        end else if(invalid_phy_addr_fault) begin
            if(mmu_write_en)begin
                exception_code = 15;
            end else begin
                exception_code = 13;
            end
        end else begin
            exception_code = 0;
        end
        exception_occured_o = instruction_page_fault | load_page_fault | store_page_fault | invalid_phy_addr_fault;
        exception_cause_o = {1'b0, exception_code};
        exception_val_o = mmu_addr;
    end

    logic s_cache_ready;
    logic s_cache_mem_en;
    logic [ADDR_WIDTH-1:0] s_cache_addr;
    logic [DATA_WIDTH/8-1:0] s_cache_sel;
    logic [DATA_WIDTH-1:0] s_cache_dat_out;
    always_comb begin
        if(permit_cache)begin // MMU controlls cache
            s_cache_mem_en = mmu_mem_en;
            s_cache_addr = mmu_addr;
            s_cache_sel = mmu_sel;

            tlb_cache_ready = 1'b0;
            tlb_cache_result = 0;
        end else begin // TLB controlls cache
            s_cache_mem_en = tlb_cache_mem_en;
            s_cache_addr = phy_addr;
            s_cache_sel = tlb_cache_mem_sel_o;

            tlb_cache_ready = s_cache_ready;
            tlb_cache_result = s_cache_dat_out;
        end
    end
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

        .master_ready_o(s_cache_ready),
        .mem_en(s_cache_mem_en),
        .addr(s_cache_addr),
        .sel(s_cache_sel),
        .data_out(s_cache_dat_out)
    );

    // always_ff @(posedge clk) begin
    //     if(rst)begin
    //         mmu_own_work <= 0;
    //     end else begin
    //         if(wishbone_owner == `MMU_OWN)begin
    //             if(master_ready_o)begin
    //                 mmu_own_work <= 0;
    //             end else begin
    //                 mmu_own_work <= 1;
    //             end
    //         end else begin
    //             mmu_own_work <= 0;
    //         end
    //     end
    // end

    logic mmu_own_work;
    assign mmu_own_work = (wishbone_owner == `MMU_OWN) && !master_ready_o;

    // arbeiter
    always_comb begin
        case (wishbone_owner)
            `MMU_OWN: begin
                if(invalid_phy_addr_fault)begin
                    mem_en = 0;
                end else begin
                    mem_en = mmu_mem_en;
                end
                write_en = mmu_write_en;
                addr = mmu_addr;
                data_in = mmu_data_in;
                sel = mmu_sel;

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

                trans_ack = 0;
                trans_dat_i = 0;
                cache_ack = master_ready_o;
                cache_dat_i = data_out;
            end
            `TLB_OWN: begin // TLB doesn't send direct message to wishbone
                mem_en = cache_stb;
                write_en = 0; // read only
                addr = cache_adr;
                data_in = 0;
                sel = cache_sel;

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

                trans_ack = 0;
                trans_dat_i = 0;
                cache_ack = 0;
                cache_dat_i = 0;
            end
        endcase
    end

    always_comb begin
        if(tlb_en)begin
            mmu_ready_o = tlb_ready;
            mmu_data_out = query_data_o;
        end else begin
            if(permit_cache)begin
                mmu_ready_o = s_cache_ready || !s_cache_mem_en;
                mmu_data_out = s_cache_dat_out;
            end else begin
                mmu_ready_o = !mem_en || master_ready_o;
                mmu_data_out = data_out;
            end
        end
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
    input wire mstatus_sum,
    input wire exe_mem_stall,
    input wire exe_mem_bubble,

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
    input wire ack,

    // report exception
    output logic exception_occured_o,
    output logic [DATA_WIDTH-1:0] exception_cause_o,
    output logic [DATA_WIDTH-1:0] exception_val_o
);

    satp_t satp;
    assign satp = satp_i;

    logic trans_running;
    logic [1:0] wishbone_owner;
    logic [1:0] tlb_wishbone_owner;
    logic tlb_en;
    logic access_user_page_table;
    assign access_user_page_table = (satp.mode != 1'b0) && (priv_level_i != `PRIV_M_LEVEL);//(priv_level_i == `PRIV_U_LEVEL) || ((priv_level_i == `PRIV_S_LEVEL && mstatus_sum));
    always_comb begin
        // judge wishbone_owner, no cache
        if(access_user_page_table && mmu_mem_en)begin
            wishbone_owner = tlb_wishbone_owner;
            tlb_en = 1;
        end else begin
            wishbone_owner = `MMU_OWN;
            tlb_en = 0;
        end
    end
    assign trans_req = (wishbone_owner == `TRANSLATE_OWN) && trans_running;

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
        .trans_running(trans_running),
        .satp_i(satp),
        .bubble(exe_mem_bubble),
        .stall(exe_mem_stall),
        .instruction_page_fault(instruction_page_fault),
        .load_page_fault(load_page_fault),
        .store_page_fault(store_page_fault)
    );

    logic valid_phy_addr;
    assign valid_phy_addr = (mmu_addr >= 32'h8000_0000 && mmu_addr <= 32'h807f_ffff) || (mmu_addr >= 32'h1000_0000 && mmu_addr <= 32'h1000_ffff) || (mmu_addr >= 32'h0200_0000 && mmu_addr <= 32'h0200_ffff);
    logic invalid_phy_addr_fault;
    assign invalid_phy_addr_fault = !access_user_page_table && mmu_mem_en && !valid_phy_addr;

    logic [30:0] exception_code;
    always_comb begin
        if(instruction_page_fault)begin
            exception_code = 12;
        end else if(load_page_fault)begin
            exception_code = 13;
        end else if(store_page_fault) begin
            exception_code = 15;
        end else if(invalid_phy_addr_fault) begin
            if(mmu_write_en)begin
                exception_code = 15;
            end else begin
                exception_code = 13;
            end
        end else begin
            exception_code = 0;
        end
        exception_occured_o = instruction_page_fault | load_page_fault | store_page_fault | invalid_phy_addr_fault;
        exception_cause_o = {1'b0, exception_code};
        exception_val_o = mmu_addr;
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
        cache_cyc = cache_mem_en && !cache_ack;
        cache_stb = cache_mem_en && !cache_ack;
        cache_adr = phy_addr;
        cache_sel = cache_mem_sel_o;
        cache_we = cache_write_en;
        cache_dat_o = cache_mem_data_o;
        cache_ready = cache_ack;
        cache_result = cache_dat_i;
    end

    reg mmu_own_work;
    // assign mmu_own_work = (wishbone_owner == `MMU_OWN) && !master_ready_o;
    always_ff @(posedge clk) begin
        if(rst)begin
            mmu_own_work <= 0;
        end else begin
            if(wishbone_owner == `MMU_OWN && mmu_mem_en)begin
                if(master_ready_o)begin
                    mmu_own_work <= 0;
                end else begin
                    mmu_own_work <= 1;
                end
            end else begin
                mmu_own_work <= 0;
            end
        end
    end

    // arbeiter
    always_comb begin
        case (wishbone_owner)
            `MMU_OWN: begin
                if(invalid_phy_addr_fault)begin
                    mem_en = 0;
                end else begin
                    mem_en = mmu_own_work;
                end
                write_en = mmu_write_en;
                addr = mmu_addr;
                data_in = mmu_data_in;
                sel = mmu_sel;

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

                trans_ack = master_ready_o;
                trans_dat_i = data_out;
                cache_ack = 0;
                cache_dat_i = 0;
            end
            `CACHE_OWN: begin
                mem_en = cache_stb;
                write_en = cache_we;
                addr = cache_adr;
                data_in = cache_dat_o;
                sel = cache_sel;

                trans_ack = 0;
                trans_dat_i = 0;
                cache_ack = master_ready_o;
                cache_dat_i = data_out;
            end
            `TLB_OWN: begin // TLB doesn't send direct message to wishbone
                mem_en = cache_stb;
                write_en = cache_we;
                addr = cache_adr;
                data_in = cache_dat_o;
                sel = cache_sel;

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

                trans_ack = 0;
                trans_dat_i = 0;
                cache_ack = 0;
                cache_dat_i = 0;
            end
        endcase
    end

    always_comb begin
        if(tlb_en)begin
            mmu_ready_o = tlb_ready;
            mmu_data_out = query_data_o;
        end else begin
            mmu_ready_o = !mem_en || master_ready_o;
            mmu_data_out = data_out;
        end
    end
    
endmodule