`include "../header/csr.sv"

module mtime_controller #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (
    // clk and reset
    input wire clk_i,
    input wire rst_i,

    // wishbone slave interface
    input wire wb_cyc_i,
    input wire wb_stb_i,
    output reg wb_ack_o,
    input wire [ADDR_WIDTH-1:0] wb_adr_i,
    input wire [DATA_WIDTH-1:0] wb_dat_i,
    output reg [DATA_WIDTH-1:0] wb_dat_o,
    input wire [DATA_WIDTH/8-1:0] wb_sel_i,
    input wire wb_we_i,

    output reg [DATA_WIDTH-1:0] mtime_h_o,
    output reg [DATA_WIDTH-1:0] mtime_l_o,

    output reg time_interrupt_o
);

    reg [DATA_WIDTH-1:0] mtime_h;
    reg [DATA_WIDTH-1:0] mtime_l;
    reg [DATA_WIDTH-1:0] mtimecmp_h;
    reg [DATA_WIDTH-1:0] mtimecmp_l;

  always_comb begin
    mtime_h_o = mtime_h;
    mtime_l_o = mtime_l;
  end

  /*-- wishbone fsm --*/
  always_ff @(posedge clk_i) begin
    if (rst_i)
      wb_ack_o <= 0;
    else
      // every request get ACK-ed immediately
      if (wb_ack_o) begin
        wb_ack_o <= 0;
      end else begin
        wb_ack_o <= wb_stb_i;
      end
  end

  logic [DATA_WIDTH-1:0] time_interval;

  always_comb begin
    time_interrupt_o = ({mtime_h, mtime_l} >= {mtimecmp_h, mtimecmp_l});
  end

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
        time_interval <= 0;
        {mtime_h, mtime_l} <= 0;
    end else begin
      if(wb_stb_i && wb_we_i) begin
        case (wb_adr_i[31:0])
          32'h200BFF8: begin // mtime_l
            if (wb_sel_i[0]) mtime_l[7:0] <= wb_dat_i[7:0];
            if (wb_sel_i[1]) mtime_l[15:8] <= wb_dat_i[15:8];
            if (wb_sel_i[2]) mtime_l[23:16] <= wb_dat_i[23:16];
            if (wb_sel_i[3]) mtime_l[31:24] <= wb_dat_i[31:24];
          end

          32'h200BFFc: begin // mtime_h
            if (wb_sel_i[0]) mtime_h[7:0] <= wb_dat_i[7:0];
            if (wb_sel_i[1]) mtime_h[15:8] <= wb_dat_i[15:8];
            if (wb_sel_i[2]) mtime_h[23:16] <= wb_dat_i[23:16];
            if (wb_sel_i[3]) mtime_h[31:24] <= wb_dat_i[31:24];
          end

          32'h2004000: begin // mtimecmp_l
            if (wb_sel_i[0]) mtimecmp_l[7:0] <= wb_dat_i[7:0];
            if (wb_sel_i[1]) mtimecmp_l[15:8] <= wb_dat_i[15:8];
            if (wb_sel_i[2]) mtimecmp_l[23:16] <= wb_dat_i[23:16];
            if (wb_sel_i[3]) mtimecmp_l[31:24] <= wb_dat_i[31:24];
          end

          32'h2004004: begin // mtimecmp_h
            if (wb_sel_i[0]) mtimecmp_h[7:0] <= wb_dat_i[7:0];
            if (wb_sel_i[1]) mtimecmp_h[15:8] <= wb_dat_i[15:8];
            if (wb_sel_i[2]) mtimecmp_h[23:16] <= wb_dat_i[23:16];
            if (wb_sel_i[3]) mtimecmp_h[31:24] <= wb_dat_i[31:24];
          end
          default: ;  // do nothing
        endcase
      end else if(wb_stb_i && !wb_we_i) begin
        case (wb_adr_i[31:0])
          32'h200BFF8: begin // mtime_l
            if (wb_sel_i[0]) wb_dat_o[7:0] <= mtime_l[7:0];
            if (wb_sel_i[1]) wb_dat_o[15:8] <= mtime_l[15:8];
            if (wb_sel_i[2]) wb_dat_o[23:16] <= mtime_l[23:16];
            if (wb_sel_i[3]) wb_dat_o[31:24] <= mtime_l[31:24];
          end

          32'h200BFFc: begin // mtime_h
            if (wb_sel_i[0]) wb_dat_o[7:0] <= mtime_h[7:0];
            if (wb_sel_i[1]) wb_dat_o[15:8] <= mtime_h[15:8];
            if (wb_sel_i[2]) wb_dat_o[23:16] <= mtime_h[23:16];
            if (wb_sel_i[3]) wb_dat_o[31:24] <= mtime_h[31:24];
          end

          32'h2004000: begin // mtimecmp_l
            if (wb_sel_i[0]) wb_dat_o[7:0] <= mtimecmp_l[7:0];
            if (wb_sel_i[1]) wb_dat_o[15:8] <= mtimecmp_l[15:8];
            if (wb_sel_i[2]) wb_dat_o[23:16] <= mtimecmp_l[23:16];
            if (wb_sel_i[3]) wb_dat_o[31:24] <= mtimecmp_l[31:24];
          end

          32'h2004004: begin // mtimecmp_h
            if (wb_sel_i[0]) wb_dat_o[7:0] <= mtimecmp_h[7:0];
            if (wb_sel_i[1]) wb_dat_o[15:8] <= mtimecmp_h[15:8];
            if (wb_sel_i[2]) wb_dat_o[23:16] <= mtimecmp_h[23:16];
            if (wb_sel_i[3]) wb_dat_o[31:24] <= mtimecmp_h[31:24];
          end
          default: ;  // do nothing
        endcase
          if (time_interval < `MTIME_INTERVAL) begin
              time_interval <= time_interval + 1;
          end else begin
              time_interval <= 0;
              {mtime_h, mtime_l} <= {mtime_h, mtime_l} + 1;
          end
      end else begin
          if (time_interval < `MTIME_INTERVAL) begin
              time_interval <= time_interval + 1;
          end else begin
              time_interval <= 0;
              {mtime_h, mtime_l} <= {mtime_h, mtime_l} + 1;
          end
      end
    end
  end

endmodule
