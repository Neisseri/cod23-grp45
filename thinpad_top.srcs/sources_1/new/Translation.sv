`timescale 1ns / 1ps
`include "header/page_table_code.svh"

module Translation #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (
    input wire clk,
    input wire rst,

    input wire if_fetch_instruction,
    input wire if_user_mode,

    // TLB to Translation
    input wire [ADDR_WIDTH-1:0] query_addr,
    input wire translation_en,
    input wire query_write_en,

    // Translation to TLB
    output logic translation_ready,
    output reg [ADDR_WIDTH-1:0] query_addr_o,

    // Wishbone to Translation
    input wire wb_ack_i,
    input wire [DATA_WIDTH-1:0] wb_dat_i,

    // Translation to Memory
    output logic wb_cyc_o,
    output logic wb_stb_o,
    output reg [ADDR_WIDTH-1:0] wb_adr_o,
    output logic [DATA_WIDTH-1:0] wb_dat_o,
    output logic [DATA_WIDTH/8-1:0] wb_sel_o,
    output logic wb_we_o,
    output logic trans_running,

    // CSR to Translation
    input wire satp_t satp_i,
    input wire bubble,
    input wire stall,

    // Translation to CSR
    output reg instruction_page_fault,
    output reg load_page_fault,
    output reg store_page_fault
);

typedef enum logic [2:0] { 
    STATE_IDLE,
    STATE_FETCH_TABLE,
    STATE_FETCH_TABLE_DONE,
    STATE_FIND_PAGE,
    STATE_FIND_LEAF,
    STATE_DONE
} state_t;

    state_t state;

    always_comb begin
        wb_dat_o = 0; // not write
        wb_we_o = 0;
        wb_sel_o = 4'b1111;
        wb_cyc_o = (state == STATE_FETCH_TABLE) || (state == STATE_FIND_PAGE);
        wb_stb_o = (state == STATE_FETCH_TABLE) || (state == STATE_FIND_PAGE);
        translation_ready = (state == STATE_IDLE && !translation_en) || (state == STATE_DONE);
        trans_running = (state != STATE_IDLE);
    end

    page_entry_t cur_page;
    assign cur_page = wb_dat_i;

    logic [ADDR_WIDTH-1:0] page_base;
    assign page_base = {satp_i.ppn[`PPN1_LENGTH+`PPN0_LENGTH-3:0], {`PAGE_OFFSET{1'b0}}}; // 第一层页表基�??

    virtual_address_t vir_addr;
    assign vir_addr = query_addr;

    logic [ADDR_WIDTH-1:0] first_table_addr;
    assign first_table_addr = {satp_i.ppn[`PPN1_LENGTH+`PPN0_LENGTH-3:0], vir_addr.VPN1[`VPN1_LENGTH-1:0], 2'b00};

    logic [ADDR_WIDTH-1:0] second_table_addr;
    assign second_table_addr = {cur_page.PPN1[`PPN1_LENGTH-3:0], cur_page.PPN0[`PPN0_LENGTH-1:0], vir_addr.VPN0[`VPN0_LENGTH-1:0], 2'b00};
    
    logic [ADDR_WIDTH-1:0] final_phy_addr;
    assign final_phy_addr = {cur_page.PPN1[`PPN1_LENGTH-3:0], cur_page.PPN0[`PPN0_LENGTH-1:0], vir_addr.offset};
    logic valid_phy_addr;
    assign valid_phy_addr = (final_phy_addr >= 32'h8000_0000 && final_phy_addr <= 32'h807f_ffff) || (final_phy_addr >= 32'h1000_0000 && final_phy_addr <= 32'h1000_ffff) || (final_phy_addr >= 32'h0200_0000 && final_phy_addr <= 32'h0200_ffff);
    always_ff @(posedge clk) begin
        if(rst)begin
            instruction_page_fault <= 0;
            load_page_fault <= 0;
            store_page_fault <= 0;
            query_addr_o <= 0;
            wb_adr_o <= 0;
            state <= STATE_IDLE;
        end else begin
            case (state)
                STATE_IDLE: begin
                    instruction_page_fault <= 0;
                    load_page_fault <= 0;
                    store_page_fault <= 0;
                    if(translation_en)begin
                        wb_adr_o <= first_table_addr;
                        state <= STATE_FETCH_TABLE;
                    end
                end
                STATE_FETCH_TABLE: begin
                    if(wb_ack_i)begin
                        state <= STATE_FETCH_TABLE_DONE;
                    end
                end
                STATE_FETCH_TABLE_DONE: begin
                    if(cur_page.V == 0 || (cur_page.R == 0 && cur_page.W == 1))begin
                        query_addr_o <= 0;
                        if(if_fetch_instruction) instruction_page_fault <= 1;
                        else if (query_write_en) store_page_fault <= 1;
                        else load_page_fault <= 1;
                        state <= STATE_DONE;
                    end else begin
                        if(cur_page.X == 0 && cur_page.R == 0)begin
                            wb_adr_o <= second_table_addr;
                            state <= STATE_FIND_PAGE;
                        end else begin
                            wb_adr_o <= 0;
                            state <= STATE_FIND_LEAF;
                        end
                    end
                end
                STATE_FIND_PAGE: begin
                    if(wb_ack_i)begin
                        state <= STATE_FIND_LEAF;
                    end
                end
                STATE_FIND_LEAF: begin
                    if(cur_page.V == 0 || (cur_page.R == 0 && cur_page.W == 1))begin
                        query_addr_o <= 0;
                        if(if_fetch_instruction) instruction_page_fault <= 1;
                        else if (query_write_en) store_page_fault <= 1;
                        else load_page_fault <= 1;
                        state <= STATE_DONE;
                    end else begin
                        if(cur_page.X == 0 && cur_page.R == 0)begin
                            query_addr_o <= 0;
                            if(if_fetch_instruction) instruction_page_fault <= 1;
                            else if (query_write_en) store_page_fault <= 1;
                            else load_page_fault <= 1;
                            state <= STATE_DONE;
                        end else begin
                            // if(cur_page.U && !if_user_mode)begin
                            //     query_addr_o <= 0;
                            //     if(if_fetch_instruction) instruction_page_fault <= 1;
                            //     else if (query_write_en) store_page_fault <= 1;
                            //     else load_page_fault <= 1;
                            //     state <= STATE_DONE;
                            if(!cur_page.X && if_fetch_instruction)begin
                                query_addr_o <= 0;
                                instruction_page_fault <= 1;
                                state <= STATE_DONE;
                            end else if(!cur_page.W && query_write_en)begin
                                query_addr_o <= 0;
                                store_page_fault <= 1;
                                state <= STATE_DONE;
                            end else if(!cur_page.R && !if_fetch_instruction)begin
                                query_addr_o <= 0;
                                load_page_fault <= 1;
                                state <= STATE_DONE;
                            end else if(!valid_phy_addr) begin
                                if(query_write_en)begin
                                    query_addr_o <= 0;
                                    store_page_fault <= 1;
                                    state <= STATE_DONE;
                                end else begin
                                    query_addr_o <= 0;
                                    load_page_fault <= 1;
                                    state <= STATE_DONE;
                                end
                            end else begin
                                query_addr_o <= cur_page;
                                state <= STATE_DONE;
                            end
                        end
                    end
                end
                STATE_DONE: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

endmodule