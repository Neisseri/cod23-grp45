`timescale 1ns / 1ps
`include "../header/page_table_code.sv"

module Translation #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (
    input wire clk,
    input wire rst,

    input wire if_fetch_instruction,
    input wire if_user_mode,

    // CPU to Translation
    input wire [ADDR_WIDTH-1:0] query_addr,
    input wire [DATA_WIDTH-1:0] query_data_i,
    input wire query_mem_en,
    input wire query_write_en,
    input wire [DATA_WIDTH/8-1:0] query_sel,

    // Translation to CPU
    output logic translation_ready,
    output logic [DATA_WIDTH-1:0] query_data_o,

    // Memory to Translation
    input wire mem_ready,
    input wire [DATA_WIDTH-1:0] mem_data_i,

    // Translation to Memory
    output reg [ADDR_WIDTH-1:0] phy_addr,
    output reg mem_en,
    output reg write_en,
    output logic [DATA_WIDTH-1:0] mem_data_o,
    output logic [DATA_WIDTH/8-1:0] mem_sel_o,

    // CSR to Translation
    input wire satp_t satp_i,

    // Translation to CSR
    output reg instruction_page_fault,
    output reg load_page_fault,
    output reg store_page_fault
);

typedef enum logic { 
    STATE_IDLE,
    STATE_FETCH_TABLE,
    STATE_FETCH_TABLE_DONE,
    STATE_FIND_PAGE,
    STATE_FIND_LEAF,
    STATE_READ_DATA,
    STATE_DONE
} state_t;

    state_t state;

    always_comb begin
        mem_data_o = query_data_i;
        mem_sel_o = query_sel;
        query_data_o = mem_data_i;
        translation_ready = (state == STATE_IDLE) || (state == STATE_DONE);
    end

    page_entry_t cur_page;

    logic [ADDR_WIDTH-1:0] page_base;
    assign page_base = {satp_i.ppn[`PPN1_LENGTH+`PPN0_LENGTH-3:0], {`PAGE_OFFSET{0}}}; // 第一层页表基址

    virtual_address_t vir_addr;
    assign vir_addr = query_addr;
    
    always_ff @(posedge clk) begin
        if(rst)begin
            mem_en <= 0;
            write_en <= 0;
            instruction_page_fault <= 0;
            load_page_fault <= 0;
            store_page_fault <= 0;
            phy_addr <= 0;
            cur_page <= 0;
            state <= STATE_IDLE;
        end else begin
            case (state)
                STATE_IDLE: begin
                    instruction_page_fault <= 0;
                    load_page_fault <= 0;
                    store_page_fault <= 0;
                    if(query_mem_en)begin
                        phy_addr <= page_base + (vir_addr.VPN1 << `PAGE_OFFSET);
                        mem_en <= 1;
                        write_en <= 0;
                        cur_page <= 0;
                        state <= STATE_FETCH_TABLE;
                    end
                end
                STATE_FETCH_TABLE: begin
                    if(mem_ready)begin
                        mem_en <= 0;
                        write_en <= 0;
                        cur_page <= mem_data_i;
                        state <= STATE_FETCH_TABLE_DONE;
                    end
                end
                STATE_FETCH_TABLE_DONE: begin
                    if(cur_page.V == 0 || (cur_page.R == 0 && cur_page.W == 1))begin
                        phy_addr <= 0;
                        if(if_fetch_instruction) instruction_page_fault <= 1;
                        else load_page_fault <= 1;
                        state <= STATE_DONE;
                    end else begin
                        if(cur_page.X == 0 && cur_page.R == 0)begin
                            mem_en <= 1;
                            write_en <= 0;
                            phy_addr <= {cur_page.PPN1[`PPN1_LENGTH-3:0], cur_page.PPN0[`PPN0_LENGTH-1:0], {`PAGE_OFFSET{0}}} + (vir_addr.VPN0 << `PAGE_OFFSET);
                            state <= STATE_FIND_PAGE;
                        end else begin
                            mem_en <= 0;
                            write_en <= 0;
                            phy_addr <= 0;
                            state <= STATE_FIND_LEAF;
                        end
                    end
                end
                STATE_FIND_PAGE: begin
                    if(mem_ready)begin
                        mem_en <= 0;
                        write_en <= 0;
                        cur_page <= mem_data_i;
                        state <= STATE_FIND_LEAF;
                    end
                end
                STATE_FIND_LEAF: begin
                    if(cur_page.V == 0 || (cur_page.R == 0 && cur_page.W == 1))begin
                        phy_addr <= 0;
                        if(if_fetch_instruction) instruction_page_fault <= 1;
                        else load_page_fault <= 1;
                        state <= STATE_DONE;
                    end else begin
                        if(cur_page.X == 0 && cur_page.R == 0)begin
                            phy_addr <= 0;
                            if(if_fetch_instruction) instruction_page_fault <= 1;
                            else load_page_fault <= 1;
                            state <= STATE_DONE;
                        end else begin
                            if(cur_page.U && !if_user_mode)begin
                                phy_addr <= 0;
                                if(if_fetch_instruction) instruction_page_fault <= 1;
                                else load_page_fault <= 1;
                                state <= STATE_DONE;
                            end else if(!cur_page.X && if_fetch_instruction)begin
                                phy_addr <= 0;
                                instruction_page_fault <= 1;
                                state <= STATE_DONE;
                            end else if(!cur_page.W && query_write_en)begin
                                phy_addr <= 0;
                                store_page_fault <= 1;
                                state <= STATE_DONE;
                            end else if(!cur_page.R && !if_fetch_instruction)begin
                                phy_addr <= 0;
                                load_page_fault <= 1;
                                state <= STATE_DONE;
                            end else begin
                                phy_addr <= {cur_page.PPN1[`PPN1_LENGTH-3:0], cur_page.PPN0[`PPN0_LENGTH-1:0], vir_addr.offset};
                                mem_en <= query_mem_en;
                                write_en <= query_write_en;
                                state <= STATE_READ_DATA;
                            end
                        end
                    end
                end
                STATE_READ_DATA: begin
                    if(mem_ready)begin
                        mem_en <= 0;
                        write_en <= 0;
                        state <= STATE_DONE;
                    end
                end
                STATE_DONE: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

endmodule