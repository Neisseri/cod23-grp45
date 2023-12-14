module flash_controller #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter BUFFER_CLK = 3,
    parameter INNER_CLK = 1,
    parameter POST_RST_CLK = 4
) (
    input wire clk,
    input wire rst,

    // wishbone slave
    input wire wb_cyc_i,
    input wire wb_stb_i,
    input wire wb_we_i,
    input wire [ADDR_WIDTH-1:0] wb_addr_i,
    input wire [DATA_WIDTH-1:0] wb_data_i,
    input wire [DATA_WIDTH/8-1:0] wb_sel_i,

    output reg wb_ack_o,
    output wire [DATA_WIDTH-1:0] wb_data_o,

    // flash
    output wire [22:0] flash_addr_o,
    inout  wire [15:0] flash_data_io,
    output wire rp_n_o,
    output wire vpen_o,
    output wire ce_n_o,
    output wire oe_n_o,
    output wire we_n_o,
    output wire byte_n_o
);
    logic pre_page_valid;
    logic [19:0] pre_page;
    logic [DATA_WIDTH-1:0] data;
    logic [2:0] counter;
    logic [22:0] addr;

    assign byte_n_o = 1;
    assign vpen_o = 0;
    assign we_n_o = 1;
    assign oe_n_o = 0;
    assign ce_n_o = 0;
    assign rp_n_o = ~rst;

    assign flash_addr_o = addr;
    assign wb_data_o = data;

    typedef enum logic [3:0] {
        POST_RST,
        IDLE,
        PAGE_BUFFER_WAIT,
        INNER_WAIT_LO,
        INNER_WAIT_HI,
        ACK
    } state_e;

    state_e state;

    always_comb begin 
        wb_ack_o = 0;
        addr[1] = 0;
        case (state)
            INNER_WAIT_LO:
                addr[1] = 0;
            INNER_WAIT_HI:
                addr[1] = 1;
            ACK: 
                wb_ack_o = 1;
        endcase
    end

    always_ff @ (posedge clk) begin 
        if (rst) begin
            state <= POST_RST;
            pre_page_valid <= 0;
            counter <= 1;
        end else begin
            case (state)
                POST_RST: begin
                    if (counter == POST_RST_CLK) begin
                        state <= IDLE;
                    end else begin
                        counter <= counter + 1;
                    end
                end

                IDLE: begin
                    if (wb_stb_i && wb_cyc_i) begin
                        if (!(wb_sel_i[3] | wb_sel_i[2] | wb_sel_i[1] | wb_sel_i[0])) begin
                            state <= ACK;
                        end else begin
                            addr[22:2] <= wb_addr_i[22:2];
                            if (pre_page_valid && (pre_page == wb_addr_i[22:3])) begin
                                counter <= 1;
                                if (wb_sel_i[1] | wb_sel_i[0]) begin
                                    state <= INNER_WAIT_LO;
                                end else if (wb_sel_i[2] | wb_sel_i[3]) begin
                                    state <= INNER_WAIT_HI;
                                end
                            end else begin
                                counter <= 1;
                                state <= PAGE_BUFFER_WAIT;
                            end
                        end
                    end
                end

                PAGE_BUFFER_WAIT: begin
                    if (counter >= 3) begin
                        pre_page_valid <= 1;
                        pre_page <= addr[22:3];
                        counter <= 1;
                        if (wb_sel_i[1] | wb_sel_i[0]) begin
                            state <= INNER_WAIT_LO;
                        end else if (wb_sel_i[2] | wb_sel_i[3]) begin
                            state <= INNER_WAIT_HI;
                        end
                    end else begin
                        counter <= counter + 1;
                    end
                end

                INNER_WAIT_LO: begin
                    if (counter == INNER_CLK) begin
                        counter <= 1;
                        data[15:0] <= flash_data_io;
                        if (wb_sel_i[2] | wb_sel_i[3]) begin
                            state <= INNER_WAIT_HI;
                        end else begin
                            state <= ACK;
                        end
                    end else begin
                        counter <= counter + 1;
                    end
                end

                INNER_WAIT_HI: begin
                    if (counter == INNER_CLK) begin
                        counter <= 1;
                        data[31:16] <= flash_data_io;
                        state <= ACK;
                    end else begin
                        counter <= counter + 1;
                    end
                end

                ACK: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule