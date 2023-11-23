module lab5_master #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (
    input wire clk_i,
    input wire rst_i,

    // TODO: 添加需要的控制信号，例如按键开关？
    input wire [31:0] sw_addr,

    // wishbone master
    output reg wb_cyc_o,
    output reg wb_stb_o,
    input wire wb_ack_i,
    output reg [ADDR_WIDTH-1:0] wb_adr_o,
    output reg [DATA_WIDTH-1:0] wb_dat_o,
    input wire [DATA_WIDTH-1:0] wb_dat_i,
    output reg [DATA_WIDTH/8-1:0] wb_sel_o,
    output reg wb_we_o
);

  // TODO: 实现实验 5 的内存+串口 Master
  typedef enum logic [3:0] {
    STATE_IDLE = 0,
    STATE_READ_WAIT_ACTION = 1,
    STATE_READ_WAIT_CHECK = 2,
    STATE_READ_DATA_ACTION = 3,
    STATE_READ_DATA_DONE = 4,
    STATE_WRITE_SRAM_ACTION = 5,
    STATE_WRITE_SRAM_DONE = 6,
    STATE_WRITE_WAIT_ACTION = 7,
    STATE_WRITE_WAIT_CHECK = 8,
    STATE_WRITE_DATA_ACTION = 9,
    STATE_WRITE_DATA_DONE = 10
} state_t;

    state_t state;
    
    reg [31:0] sw_addr_reg;
    
    reg can_do;
    reg [DATA_WIDTH-1:0] wb_dat_reg;
    reg [3:0] times;
    
    always_ff @ (posedge clk_i) begin
        if (rst_i) begin
            wb_cyc_o <= 0;
            wb_stb_o <= 0;
            wb_we_o <= 0;
            wb_adr_o <= 0;
            wb_dat_o <= 0;
            wb_sel_o <= 0;
            can_do <= 0;
            wb_dat_reg <= 0;
            times <= 0;
            sw_addr_reg <= (sw_addr >> 2) << 2;
            state <= STATE_IDLE;
        end else begin
            case (state)
                STATE_IDLE: begin
                    if (times < 10) begin
                        wb_cyc_o <= 1;
                        wb_stb_o <= 1;
                        wb_we_o <= 0;
                        wb_adr_o <= 'h10000005;
                        wb_sel_o <= 'b1111;
                        can_do <= 0;
                        state <= STATE_READ_WAIT_ACTION;
                    end
                end
                STATE_READ_WAIT_ACTION: begin
                    if (wb_ack_i)begin
                        if (wb_dat_i[0] == 1)begin
                            can_do <= 1;
                        end
                        wb_cyc_o <= 0;
                        wb_stb_o <= 0;
                        state <= STATE_READ_WAIT_CHECK;
                    end
                end
                STATE_READ_WAIT_CHECK: begin
                    wb_cyc_o <= 1;
                    wb_stb_o <= 1;
                    wb_we_o <= 0;
                    if (can_do) begin
                        wb_adr_o <= 'h10000000;
                        wb_sel_o <= 'b1111;
                        state <= STATE_READ_DATA_ACTION;
                    end else begin
                        wb_adr_o <= 'h10000005;
                        wb_sel_o <= 'b1111;
                        state <= STATE_READ_WAIT_ACTION;
                    end
                end
                STATE_READ_DATA_ACTION: begin
                    if (wb_ack_i) begin
                        wb_dat_reg <= wb_dat_i;
                        wb_cyc_o <= 0;
                        wb_stb_o <= 0;
                        can_do <= 0;
                        state <= STATE_READ_DATA_DONE;
                    end
                end
                STATE_READ_DATA_DONE: begin
                    wb_cyc_o <= 1;
                    wb_stb_o <= 1;
                    wb_we_o <= 1;
                    wb_adr_o <= sw_addr_reg;
                    wb_dat_o <= wb_dat_reg;
                    wb_sel_o <= (4'b0001 << (sw_addr_reg & 2'b11));
                    state <= STATE_WRITE_SRAM_ACTION;
                end
                STATE_WRITE_SRAM_ACTION: begin
                    if (wb_ack_i) begin
                        wb_cyc_o <= 0;
                        wb_stb_o <= 0;
                        wb_we_o <= 0;
                        sw_addr_reg <= sw_addr_reg + 4;
                        state <= STATE_WRITE_SRAM_DONE;
                    end
                end
                STATE_WRITE_SRAM_DONE: begin
                    wb_cyc_o <= 1;
                    wb_stb_o <= 1;
                    wb_we_o <= 0;
                    wb_adr_o <= 'h10000005;
                    wb_sel_o <= 'b1111;
                    state <=  STATE_WRITE_WAIT_ACTION;
                end
                STATE_WRITE_WAIT_ACTION: begin
                    if (wb_ack_i) begin
                        if (wb_dat_i[5] == 1)begin
                            can_do <= 1;
                        end
                        wb_cyc_o <= 0;
                        wb_stb_o <= 0;
                        state <= STATE_WRITE_WAIT_CHECK;
                    end
                end
                STATE_WRITE_WAIT_CHECK: begin
                    wb_cyc_o <= 1;
                    wb_stb_o <= 1;
                    if (can_do) begin
                        wb_we_o <= 1;
                        wb_adr_o <= 'h10000000;
                        wb_sel_o <= 'b0001;
                        state <= STATE_WRITE_DATA_ACTION;
                    end else begin
                        wb_we_o <= 0;
                        wb_adr_o <= 'h10000005;
                        wb_sel_o <= 'b1111;
                        state <= STATE_WRITE_WAIT_ACTION;
                    end
                end
                STATE_WRITE_DATA_ACTION: begin
                    if (wb_ack_i) begin
                        wb_cyc_o <= 0;
                        wb_stb_o <= 0;
                        wb_we_o <= 0;
                        can_do <= 0;
                        state <= STATE_WRITE_DATA_DONE;
                    end
                end
                STATE_WRITE_DATA_DONE: begin
                    times <= times + 1;
                    state <=  STATE_IDLE;
                end
            endcase
        end
    end

endmodule
