`timescale 1ns / 1ps
`include "../header/opcode.sv"

module instruction_cache #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter CACHE_SIZE = 128,  // 256 instructions
    parameter CACHE_LINE_SIZE = 32, // 32 bytes per line
    parameter CACHE_ASSOCIATIVITY = 8,  // CACHE_ASSOCIATIVITY ways
    parameter CACHE_GROUP_SIZE = CACHE_SIZE / CACHE_ASSOCIATIVITY // 128 / 8 = 16
)(
    input wire clk,
    input wire rst,

    // wishbone master: read only
    output logic wb_cyc_o,
    output logic wb_stb_o,
    output logic [ADDR_WIDTH-1:0] wb_adr_o,
    output logic [DATA_WIDTH/8-1:0] wb_sel_o,
    output logic wb_we_o,
    input wire wb_ack_i,
    input wire [DATA_WIDTH-1:0] wb_dat_i,
    
    // data ready
    output logic master_ready_o,

    // call cache signals
    input wire mem_en,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH/8-1:0] sel,
    output reg [DATA_WIDTH-1:0] data_out
);
    // instruction cache
    reg [DATA_WIDTH-1:0] cache [CACHE_GROUP_SIZE-1:0][CACHE_ASSOCIATIVITY-1:0];
    // CACHE_SIZE/CACHE_ASSOCIATIVITY groups (1024 / 4 = 256)
    // CACHE_ASSOCIATIVITY rows in each group (4)
    reg [ADDR_WIDTH-1:0] cache_tag [CACHE_GROUP_SIZE-1:0][CACHE_ASSOCIATIVITY-1:0];
    // tag for each cache row: index of memory block
    reg [$clog2(CACHE_ASSOCIATIVITY)-1:0] cache_group_num [CACHE_GROUP_SIZE-1:0];
    // number of valid rows in group

    reg [$clog2(CACHE_GROUP_SIZE)-1:0] group_index;
    
    typedef enum logic [3:0] {
        STATE_READ_SRAM_ACTION,
        STATE_DONE
    } state_t;

    state_t state;
    
    assign wb_adr_o = addr;
    assign wb_sel_o = sel;
    assign wb_cyc_o = (state == STATE_READ_SRAM_ACTION);
    assign wb_stb_o = (state == STATE_READ_SRAM_ACTION);
    assign master_ready_o = !wb_stb_o;
    assign wb_we_o = 1'b0;

    // cache hit sign
    reg cache_hit;
    reg [$clog2(CACHE_ASSOCIATIVITY)-1:0] selected_way; // which way is selected 

    always_comb begin
        // check if the cache hit
        cache_hit = 0;
        selected_way = 0;
        group_index = ((addr - 32'h8000_0000) / 4 / CACHE_ASSOCIATIVITY) % CACHE_GROUP_SIZE;
        if (mem_en) begin
            for (int i = 0; i < CACHE_ASSOCIATIVITY; i++) begin
                if (cache_tag[group_index][i] == addr) begin
                    cache_hit = 1;
                    selected_way = i;
                end
            end
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < CACHE_GROUP_SIZE; i = i + 1) begin
                for (int j = 0; j < CACHE_ASSOCIATIVITY; j = j + 1) begin
                    cache[i][j] = 0;
                end
            end
            for (int i = 0; i < CACHE_GROUP_SIZE; i = i + 1) begin
                for (int j = 0; j < CACHE_ASSOCIATIVITY; j = j + 1) begin
                    cache_tag[i][j] = 0;
                end
            end
            for (int i = 0; i < CACHE_GROUP_SIZE; i = i + 1) begin
                for (int j = 0; j < $clog2(CACHE_ASSOCIATIVITY); j = j + 1) begin
                    cache_group_num[i][j] = 0;
                end
            end
            data_out <= `NOP_INSTR;
            state <= STATE_DONE;
        end else begin
            if (mem_en) begin
                case (state)

                    STATE_READ_SRAM_ACTION: begin
                        if (!cache_hit) begin
                            // cache miss
                            if (wb_ack_i) begin
                                // update cache
                                cache_group_num[group_index] <= cache_group_num[group_index] + 1;
                                if (cache_group_num[group_index] == CACHE_ASSOCIATIVITY + 1) begin
                                    cache_group_num[group_index] <= 1;
                                end
                                cache[group_index][cache_group_num[group_index] - 1] <= wb_dat_i;
                                cache_tag[group_index][cache_group_num[group_index] - 1] <= addr;
                                // pass data
                                data_out <= wb_dat_i;
                                state <= STATE_DONE;
                            end
                        end else begin
                            // cache hit
                            data_out <= cache[group_index][selected_way];
                            state <= STATE_DONE;
                        end
                    end

                    STATE_DONE: begin
                        state <= STATE_READ_SRAM_ACTION;
                    end

                endcase
            end
        end
    end

endmodule