`timescale 1ns / 1ps
`include "../header/opcode.svh"

module instruction_cache #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
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
    
    typedef enum logic [3:0] {
        STATE_READ_SRAM_ACTION,
        STATE_DONE
    } state_t;

    state_t state;
    
    logic [ADDR_WIDTH-1:0] pre_addr = 0;
    logic [DATA_WIDTH-1:0] pre_data = 0;
    logic cache_hit;

    assign cache_hit = (pre_addr == addr) && (pre_addr != 0);
    
    assign wb_adr_o = addr;
    assign wb_sel_o = sel;
    assign wb_cyc_o = (state == STATE_READ_SRAM_ACTION) && mem_en && !cache_hit;
    assign wb_stb_o = (state == STATE_READ_SRAM_ACTION) && mem_en && !cache_hit;
    assign wb_we_o = 1'b0;

    always_ff @(posedge clk) begin
        if (rst) begin
            data_out <= `NOP_INSTR;
            state <= STATE_READ_SRAM_ACTION;
            master_ready_o <= 1'b0;
            pre_addr <= 0;
            pre_data <= 0;
        end else begin
            if (mem_en) begin
                case (state)

                    STATE_READ_SRAM_ACTION: begin
                        if (!cache_hit) begin // cache miss
                            if (wb_ack_i) begin
                                data_out <= wb_dat_i;
                                master_ready_o <= 1'b1;
                                state <= STATE_DONE;
                            end
                        end else begin // cache hit
                            data_out <= pre_data;
                            master_ready_o <= 1'b1;
                        end
                    end

                    STATE_DONE: begin
                        pre_addr <= addr;
                        pre_data <= data_out;
                        master_ready_o <= 1'b0;
                        state <= STATE_READ_SRAM_ACTION;
                    end

                    default: begin
                        data_out <= `NOP_INSTR;
                        master_ready_o <= 1'b0;
                        state <= STATE_READ_SRAM_ACTION;
                    end

                endcase
            end
        end
    end

endmodule