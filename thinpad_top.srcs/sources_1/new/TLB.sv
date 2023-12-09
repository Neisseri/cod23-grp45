`timescale 1ns / 1ps
`include "header/page_table_code.sv"

module TLB #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter TLB_LENGTH = 32
) (
    input wire clk,
    input wire rst,

    // CPU controll
    input wire tlb_en,
    input wire flush_tlb,
    input wire satp_t satp_i,

    output logic [1:0] wishbone_owner,
    
    // CPU request
    input wire [ADDR_WIDTH-1:0] query_addr,
    input wire [DATA_WIDTH-1:0] query_data_i,
    input wire query_mem_en,
    input wire query_write_en,
    input wire [DATA_WIDTH/8-1:0] query_sel,

    // CPU respond
    output logic tlb_ready,
    output reg [DATA_WIDTH-1:0] query_data_o,

    // TLB to Translation
    output logic [ADDR_WIDTH-1:0] tlb_query_addr,
    output logic translation_en,
    output logic to_trans_query_write_en,

    // Translation to TLB
    input wire translation_ready,
    input wire translation_error,
    input wire [ADDR_WIDTH-1:0] translation_result,

    // TLB to Cache
    output logic [ADDR_WIDTH-1:0] phy_addr,
    output logic cache_mem_en,
    output logic cache_write_en,
    output logic [DATA_WIDTH-1:0] cache_mem_data_o,
    output logic [DATA_WIDTH/8-1:0] cache_mem_sel_o,

    // Cache to TLB
    input wire cache_ready,
    input wire cache_error,
    input wire [DATA_WIDTH-1:0] cache_result
);

    tlb_entry_t tlb_table [0:TLB_LENGTH-1];

    typedef enum logic [3:0] { 
        STATE_IDLE,
        STATE_TRANSLATE,
        STATE_READ_DATA,
        STATE_DONE
    } state_t;

    state_t state;

    tlb_req_t tlb_req;
    assign tlb_req = query_addr;

    page_entry_t translation_page;
    assign translation_page = translation_result;

    always_comb begin
        tlb_query_addr = query_addr;
        to_trans_query_write_en = query_write_en;
        cache_write_en = query_write_en;
        cache_mem_data_o = query_data_i;
        cache_mem_sel_o = query_sel;
    end

    logic tlb_hit;
    tlb_entry_t tlb_visit_entry;
    always_comb begin
        tlb_visit_entry = tlb_table[tlb_req.TLBT];
        tlb_hit = tlb_en && !flush_tlb && tlb_visit_entry.TLBI == tlb_req.TLBI && tlb_visit_entry.valid;
        if(tlb_hit)begin
            phy_addr = {tlb_visit_entry.page.PPN1[`PPN1_LENGTH-3:0], tlb_visit_entry.page.PPN0, tlb_req.offset};
        end else begin
            phy_addr = {translation_page.PPN1[`PPN1_LENGTH-3:0], translation_page.PPN0[`PPN0_LENGTH-1:0], tlb_req.offset};
        end
    end

    always_comb begin
        case (state)
            STATE_IDLE: begin
                if(tlb_hit)begin
                    wishbone_owner = `CACHE_OWN;
                end else begin
                    wishbone_owner = `TRANSLATE_OWN;
                end
            end
            STATE_TRANSLATE: wishbone_owner = `TRANSLATE_OWN;
            STATE_READ_DATA: wishbone_owner = `CACHE_OWN;
            STATE_DONE: wishbone_owner = `TLB_OWN;
        endcase
    end

    assign tlb_ready = (state == STATE_IDLE && !tlb_en) || (state == STATE_DONE);

    always_comb begin
        if((state == STATE_IDLE && tlb_en && !tlb_hit) || (state == STATE_TRANSLATE))begin
            translation_en = 1;
        end else begin
            translation_en = 0;
        end

        if((state == STATE_IDLE && tlb_en && tlb_hit) || (state == STATE_TRANSLATE && translation_ready && !translation_error) || (state == STATE_READ_DATA))begin
            cache_mem_en = 1;
        end else begin
            cache_mem_en = 0;
        end
    end

    always_ff @(posedge clk) begin
        if(rst)begin
            for(integer i = 0;i < TLB_LENGTH;i = i + 1)begin
                tlb_table[i] <= 0;
            end
            state <= STATE_IDLE;
        end else begin
            case (state)
                STATE_IDLE: begin
                    if(flush_tlb)begin
                        for(integer i = 0;i < TLB_LENGTH;i = i + 1)begin
                            tlb_table[i] <= 0;
                        end
                    end
                    if(tlb_en)begin
                        if(tlb_hit)begin
                            state <= STATE_READ_DATA;
                        end else begin
                            state <= STATE_TRANSLATE;
                        end
                    end
                end
                STATE_TRANSLATE: begin
                    if(translation_ready)begin
                        if(!translation_error)begin
                            tlb_table[tlb_req.TLBT] <= {tlb_req.TLBI, satp_i.asid, translation_page, 1'b1};
                            state <= STATE_READ_DATA;
                        end else begin
                            state <= STATE_DONE;
                        end
                    end
                end
                STATE_READ_DATA: begin
                    if(cache_ready)begin
                        if(!cache_error)begin
                            query_data_o <= cache_result;
                            state <= STATE_DONE;
                        end else begin
                            state <= STATE_DONE;
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