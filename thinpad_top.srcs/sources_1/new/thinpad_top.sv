`default_nettype none

module thinpad_top #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (
    input wire clk_50M,     // 50MHz ʱ������
    input wire clk_11M0592, // 11.0592MHz ʱ�����루���ã��ɲ��ã�

    input wire push_btn,  // BTN5 ��ť���أ���������·������ʱΪ 1
    input wire reset_btn, // BTN6 ��λ��ť����������·������ʱΪ 1

    input  wire [ 3:0] touch_btn,  // BTN1~BTN4����ť���أ�����ʱΪ 1
    input  wire [31:0] dip_sw,     // 32 λ���뿪�أ�������ON��ʱΪ 1
    output wire [15:0] leds,       // 16 λ LED������? 1 ����
    output wire [ 7:0] dpy0,       // ����ܵ�λ�źţ�����С���㣬��� 1 ����
    output wire [ 7:0] dpy1,       // ����ܸ�λ�źţ�����С���㣬��� 1 ����

    // CPLD ���ڿ������ź�
    output wire uart_rdn,        // �������źţ�����Ч
    output wire uart_wrn,        // д�����źţ�����Ч
    input  wire uart_dataready,  // ��������׼����
    input  wire uart_tbre,       // �������ݱ�־
    input  wire uart_tsre,       // ���ݷ�����ϱ��?

    // BaseRAM �ź�
    inout wire [31:0] base_ram_data,  // BaseRAM ���ݣ��� 8 λ�� CPLD ���ڿ���������
    output wire [19:0] base_ram_addr,  // BaseRAM ��ַ
    output wire [3:0] base_ram_be_n,  // BaseRAM �ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣���? 0
    output wire base_ram_ce_n,  // BaseRAM Ƭѡ������Ч
    output wire base_ram_oe_n,  // BaseRAM ��ʹ�ܣ�����Ч
    output wire base_ram_we_n,  // BaseRAM дʹ�ܣ�����Ч

    // ExtRAM �ź�
    inout wire [31:0] ext_ram_data,  // ExtRAM ����
    output wire [19:0] ext_ram_addr,  // ExtRAM ��ַ
    output wire [3:0] ext_ram_be_n,  // ExtRAM �ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣���? 0
    output wire ext_ram_ce_n,  // ExtRAM Ƭѡ������Ч
    output wire ext_ram_oe_n,  // ExtRAM ��ʹ�ܣ�����Ч
    output wire ext_ram_we_n,  // ExtRAM дʹ�ܣ�����Ч

    // ֱ�������ź�
    output wire txd,  // ֱ�����ڷ��Ͷ�
    input  wire rxd,  // ֱ�����ڽ��ն�

    // Flash �洢���źţ��ο� JS28F640 оƬ�ֲ�
    output wire [22:0] flash_a,  // Flash ��ַ��a0 ���� 8bit ģʽ��Ч��16bit ģʽ������
    inout wire [15:0] flash_d,  // Flash ����
    output wire flash_rp_n,  // Flash ��λ�źţ�����Ч
    output wire flash_vpen,  // Flash д�����źţ��͵�ƽʱ���ܲ�������д
    output wire flash_ce_n,  // Flash Ƭѡ�źţ�����Ч
    output wire flash_oe_n,  // Flash ��ʹ���źţ�����Ч
    output wire flash_we_n,  // Flash дʹ���źţ�����Ч
    output wire flash_byte_n, // Flash 8bit ģʽѡ�񣬵���Ч����ʹ�� flash �� 16 λģʽʱ����Ϊ 1

    // USB �������źţ��ο� SL811 оƬ�ֲ�
    output wire sl811_a0,
    // inout  wire [7:0] sl811_d,     // USB �������������������??? dm9k_sd[7:0] ����
    output wire sl811_wr_n,
    output wire sl811_rd_n,
    output wire sl811_cs_n,
    output wire sl811_rst_n,
    output wire sl811_dack_n,
    input  wire sl811_intrq,
    input  wire sl811_drq_n,

    // ����������źţ��ο�??? DM9000A оƬ�ֲ�
    output wire dm9k_cmd,
    inout wire [15:0] dm9k_sd,
    output wire dm9k_iow_n,
    output wire dm9k_ior_n,
    output wire dm9k_cs_n,
    output wire dm9k_pwrst_n,
    input wire dm9k_int,

    // ͼ������ź�???
    output wire [2:0] video_red,    // ��ɫ���أ�3 λ
    output wire [2:0] video_green,  // ��ɫ���أ�3 λ
    output wire [1:0] video_blue,   // ��ɫ���أ�2 λ
    output wire       video_hsync,  // ��ͬ����ˮƽͬ�����ź�
    output wire       video_vsync,  // ��ͬ������ֱͬ�����ź�
    output wire       video_clk,    // ����ʱ�����???
    output wire       video_de      // ��������Ч�źţ���������������
);

  /* =========== Demo code begin =========== */

  // PLL ��Ƶʾ��
  logic locked, clk_10M, clk_20M;
  pll_example clock_gen (
      // Clock in ports
      .clk_in1(clk_50M),  // �ⲿʱ������
      // Clock out ports
      .clk_out1(clk_10M),  // ʱ�����??? 1��Ƶ���� IP ���ý���������
      .clk_out2(clk_20M),  // ʱ�����??? 2��Ƶ���� IP ���ý���������
      // Status and control signals
      .reset(reset_btn),  // PLL ��λ����
      .locked(locked)  // PLL ����ָʾ�����???"1"��ʾʱ���ȶ���
                       // �󼶵�·��λ�ź�Ӧ���������ɣ����£�
  );

  logic reset_of_clk10M;
  // �첽��λ��ͬ���ͷţ��� locked �ź�תΪ�󼶵�·�ĸ�λ reset_of_clk10M
  always_ff @(posedge clk_10M or negedge locked) begin
    if (~locked) reset_of_clk10M <= 1'b1;
    else reset_of_clk10M <= 1'b0;
  end

  logic reset_of_clk50M;
  always_ff @(posedge clk_50M or negedge locked) begin
    if (~locked) reset_of_clk50M <= 1'b1;
    else reset_of_clk50M <= 1'b0;
  end

  always_ff @(posedge clk_10M or posedge reset_of_clk10M) begin
    if (reset_of_clk10M) begin
      // Your Code
    end else begin
      // Your Code
    end
  end

  // ��ʹ���ڴ桢����ʱ��������ʹ���ź�
//  assign base_ram_ce_n = 1'b1;
//  assign base_ram_oe_n = 1'b1;
//  assign base_ram_we_n = 1'b1;

//  assign ext_ram_ce_n = 1'b1;
//  assign ext_ram_oe_n = 1'b1;
//  assign ext_ram_we_n = 1'b1;

  assign uart_rdn = 1'b1;
  assign uart_wrn = 1'b1;

  // ��������ӹ�ϵʾ��ͼ��dpy1 ͬ��
  // p=dpy0[0] // ---a---
  // c=dpy0[1] // |     |
  // d=dpy0[2] // f     b
  // e=dpy0[3] // |     |
  // b=dpy0[4] // ---g---
  // a=dpy0[5] // |     |
  // f=dpy0[6] // e     c
  // g=dpy0[7] // |     |
  //           // ---d---  p

   //7 ���������������ʾ����??? number �� 16 ������ʾ�����������???
//   logic [7:0] number;
//   SEG7_LUT segL (
//       .oSEG1(dpy0),
//       .iDIG (number[3:0])
//   );  // dpy0 �ǵ�λ�����???
//   SEG7_LUT segH (
//       .oSEG1(dpy1),
//       .iDIG (number[7:4])
//   );  // dpy1 �Ǹ�λ�����???

//   logic [15:0] led_bits;
//   assign leds = led_bits;

//   always_ff @(posedge push_btn or posedge reset_btn) begin
//     if (reset_btn) begin  // ��λ���£����� LED Ϊ��ʼֵ
//       led_bits <= 16'h1;
//     end else begin  // ÿ�ΰ��°�ť���أ�LED ѭ������
//       led_bits <= {led_bits[14:0], led_bits[15]};
//     end
//   end

  logic sys_clk;
  logic sys_rst;

  assign sys_clk = clk_50M;
  assign sys_rst = reset_of_clk50M;

  // ֱ�����ڽ��շ�����ʾ����ֱ�������յ��������ٷ��ͳ�ȥ
  // logic [7:0] ext_uart_rx;
  // logic [7:0] ext_uart_buffer, ext_uart_tx;
  // logic ext_uart_ready, ext_uart_clear, ext_uart_busy;
  // logic ext_uart_start, ext_uart_avai;

  // assign number = ext_uart_buffer;

  // ����ģ�飬9600 �޼���λ
  // async_receiver #(
  //     .ClkFrequency(50000000),
  //     .Baud(9600)
  // ) ext_uart_r (
  //     .clk           (clk_50M),         // �ⲿʱ���ź�
  //     .RxD           (rxd),             // �ⲿ�����ź�����
  //     .RxD_data_ready(ext_uart_ready),  // ���ݽ��յ���־
  //     .RxD_clear     (ext_uart_clear),  // ������ձ��?
  //     .RxD_data      (ext_uart_rx)      // ���յ���һ�ֽ�����
  // );

  // assign ext_uart_clear = ext_uart_ready; // �յ����ݵ�ͬʱ�������־����Ϊ������ȡ��??? ext_uart_buffer ��
  // always_ff @(posedge clk_50M) begin  // ���յ������� ext_uart_buffer
  //   if (ext_uart_ready) begin
  //     ext_uart_buffer <= ext_uart_rx;
  //     ext_uart_avai   <= 1;
  //   end else if (!ext_uart_busy && ext_uart_avai) begin
  //     ext_uart_avai <= 0;
  //   end
  // end
  // always_ff @(posedge clk_50M) begin  // �������� ext_uart_buffer ���ͳ�ȥ
  //   if (!ext_uart_busy && ext_uart_avai) begin
  //     ext_uart_tx <= ext_uart_buffer;
  //     ext_uart_start <= 1;
  //   end else begin
  //     ext_uart_start <= 0;
  //   end
  // end

  // ����ģ�飬9600 �޼���λ
  // async_transmitter #(
  //     .ClkFrequency(50000000),
  //     .Baud(9600)
  // ) ext_uart_t (
  //     .clk      (clk_50M),         // �ⲿʱ���ź�
  //     .TxD      (txd),             // �����ź����???
  //     .TxD_busy (ext_uart_busy),   // ������æ״ָ̬ʾ
  //     .TxD_start(ext_uart_start),  // ��ʼ�����ź�
  //     .TxD_data (ext_uart_tx)      // �����͵�����
  // );

  // ͼ�������ʾ���ֱ���??? 800x600@75Hz������ʱ��Ϊ 50MHz
  // logic [11:0] hdata;
  // assign video_red   = hdata < 266 ? 3'b111 : 0;  // ��ɫ����
  // assign video_green = hdata < 532 && hdata >= 266 ? 3'b111 : 0;  // ��ɫ����
  // assign video_blue  = hdata >= 532 ? 2'b11 : 0;  // ��ɫ����
  // assign video_clk   = clk_50M;
  // vga #(12, 800, 856, 976, 1040, 600, 637, 643, 666, 1, 1) vga800x600at75 (
  //     .clk        (clk_50M),
  //     .hdata      (hdata),        // ������
  //     .vdata      (),             // ������
  //     .hsync      (video_hsync),
  //     .vsync      (video_vsync),
  //     .data_enable(video_de)
  // );
  /* =========== Demo code end =========== */
  
  //Controller
  logic if_stall_req;
  logic mem_stall_req;
  logic id_flush_req;
  logic exe_stall_req;

  logic pc_stall;
  logic if_id_stall;
  logic if_id_bubble;
  logic id_exe_stall;
  logic id_exe_bubble;
  logic exe_mem_stall;
  logic exe_mem_bubble;
  logic mem_wb_stall;
  logic mem_wb_bubble;
  logic pipeline_stall;
  logic im_idle_stall;
  logic dm_idle_stall;
  controller_pipeline controller_pipeline_u(
    .if_stall_req(if_stall_req),
    .mem_stall_req(mem_stall_req),
    .id_flush_req(id_flush_req),
    .exe_stall_req(exe_stall_req),
    .pc_stall(pc_stall),
    .if_id_stall(if_id_stall),
    .if_id_bubble(if_id_bubble),
    .id_exe_stall(id_exe_stall),
    .id_exe_bubble(id_exe_bubble),
    .exe_mem_stall(exe_mem_stall),
    .exe_mem_bubble(exe_mem_bubble),
    .mem_wb_stall(mem_wb_stall),
    .mem_wb_bubble(mem_wb_bubble),
    .pipeline_stall(pipeline_stall),
    .im_idle_stall(im_idle_stall),
    .dm_idle_stall(dm_idle_stall)
  );
  
  //IF
  logic [ADDR_WIDTH-1:0] pc_next_pc;
  logic [ADDR_WIDTH-1:0] pc_addr;
  PC PC_u(
    .clk(sys_clk),
    .rst(sys_rst),
    .stall(pc_stall),
    .next_pc(pc_next_pc),
    .addr(pc_addr)
  );
  
  logic [ADDR_WIDTH-1:0] pc_branch_addr;
  logic [ADDR_WIDTH-1:0] if_id_pc;
  PC_mux PC_mux_u(
    .branch(id_flush_req),
    .branch_addr(pc_branch_addr),
    .cur_pc(pc_addr),
    .next_pc(pc_next_pc)
  );

  logic im_wb_cyc_o;
  logic im_wb_stb_o;
  logic im_wb_ack_i;
  logic [ADDR_WIDTH-1:0] im_wb_adr_o;
  logic [DATA_WIDTH-1:0] im_wb_dat_o;
  logic [DATA_WIDTH-1:0] im_wb_dat_i;
  logic [DATA_WIDTH/8-1:0] im_wb_sel_o;
  logic im_wb_we_o;
  logic im_master_ready_o;
  assign if_stall_req = ~im_master_ready_o;
  logic [DATA_WIDTH-1:0] im_data_out;
  Instruction_memory IM(
    .clk(sys_clk),
    .rst(sys_rst),
    .wb_cyc_o(im_wb_cyc_o),
    .wb_stb_o(im_wb_stb_o),
    .wb_ack_i(im_wb_ack_i),
    .wb_adr_o(im_wb_adr_o),
    .wb_dat_o(im_wb_dat_o),
    .wb_dat_i(im_wb_dat_i),
    .wb_sel_o(im_wb_sel_o),
    .wb_we_o(im_wb_we_o),
    .master_ready_o(im_master_ready_o),
    .mem_en(1'b1),
    .write_en(1'b0),
    .addr(pc_addr),
    .data_in(0),
    .sel(4'b1111),
    .data_out(im_data_out),
    .pipeline_stall(pipeline_stall),
    .idle_stall(im_idle_stall)
  );
  
  logic [DATA_WIDTH-1:0] if_id_instr;
  IF_ID_reg IF_ID(
    .clk(sys_clk),
    .rst(sys_rst),
    .stall(if_id_stall),
    .bubble(if_id_bubble),
    .instr_i(im_data_out),
    .instr_o(if_id_instr),
    .pc_i(pc_addr),
    .pc_o(if_id_pc)
  );
  
  //ID
  logic [4:0] id_rd;
  logic [4:0] id_rs1;
  logic [4:0] id_rs2;
  logic [31:0] id_imm;
  logic [7:0] id_op_type_out;
  logic [3:0] id_alu_op;
  logic [2:0] id_alu_mux_a;
  logic [2:0] id_alu_mux_b;
  logic id_mem_en;
  logic id_we;
  logic [3:0] id_sel;
  logic id_rf_wen;
  logic id_wb_if_mem;
  ID ID_u(
    .instr(if_id_instr),
    .rd(id_rd),
    .rs1(id_rs1),
    .rs2(id_rs2),
    .imm(id_imm),
    .op_type_out(id_op_type_out),
    .alu_op(id_alu_op),
    .alu_mux_a(id_alu_mux_a),
    .alu_mux_b(id_alu_mux_b),
    .mem_en(id_mem_en),
    .we(id_we),
    .sel(id_sel),
    .rf_wen(id_rf_wen),
    .wb_if_mem(id_wb_if_mem)
  );

  logic [DATA_WIDTH-1:0] rf_rdata_a;
  logic [DATA_WIDTH-1:0] rf_rdata_b;
  logic [DATA_WIDTH-1:0] wb_wdata;
  logic [4:0] wb_rd;
  logic wb_rf_we;
  register_file RF_u(
    .clk(sys_clk),
    .reset(sys_rst),
    .rf_raddr_a(id_rs1),
    .rf_rdata_a(rf_rdata_a),
    .rf_raddr_b(id_rs2),
    .rf_rdata_b(rf_rdata_b),
    .rf_waddr(wb_rd),
    .rf_wdata(wb_wdata),
    .rf_we(wb_rf_we)
  );
  
  logic branch_rs1_hazard;
  logic branch_rs2_hazard;
  logic [DATA_WIDTH-1:0] branch_rs1_dat;
  logic [DATA_WIDTH-1:0] branch_rs2_dat;
  logic [DATA_WIDTH-1:0] alu_y;
  always_comb begin
    if(branch_rs1_hazard)begin
      branch_rs1_dat = alu_y;
    end else begin
      branch_rs1_dat = rf_rdata_a;
    end

    if(branch_rs2_hazard)begin
      branch_rs2_dat = alu_y;
    end else begin
      branch_rs2_dat = rf_rdata_b;
    end
  end

  Branch_comp BC_u(
    .op_type_in(id_op_type_out),
    .data_a(branch_rs1_dat),
    .data_b(branch_rs2_dat),
    .imm(id_imm),
    .pc(if_id_pc),
    .comp_result(id_flush_req),
    .new_pc(pc_branch_addr)
  );
  
  logic [DATA_WIDTH-1:0] id_exe_instr;
  logic [ADDR_WIDTH-1:0] id_exe_pc;
  logic [4:0] id_exe_rd;
  logic [4:0] id_exe_rs1;
  logic [4:0] id_exe_rs2;
  logic [DATA_WIDTH-1:0] id_exe_rs1_dat;
  logic [DATA_WIDTH-1:0] id_exe_rs2_dat;
  logic [DATA_WIDTH-1:0] id_exe_imm;
  logic [3:0] id_exe_alu_op;
  logic [2:0] id_exe_alu_mux_a;
  logic [2:0] id_exe_alu_mux_b;
  logic id_exe_mem_en;
  logic id_exe_rf_wen;
  logic [3:0] id_exe_sel;
  logic id_exe_we;
  logic id_exe_wb_if_mem;
  ID_EXE_reg ID_EXE(
    .clk(sys_clk),
    .rst(sys_rst),
    .stall(id_exe_stall),
    .bubble(id_exe_bubble),
    .instr_i(if_id_instr),
    .instr_o(id_exe_instr),
    .pc_i(if_id_pc),
    .pc_o(id_exe_pc),
    .rd_i(id_rd),
    .rs1_i(id_rs1),
    .rs2_i(id_rs2),
    .rs1_dat_i(rf_rdata_a),
    .rs2_dat_i(rf_rdata_b),
    .imm_i(id_imm),
    .alu_op_i(id_alu_op),
    .alu_mux_a_i(id_alu_mux_a),
    .alu_mux_b_i(id_alu_mux_b),
    .mem_en_i(id_mem_en),
    .rf_wen_i(id_rf_wen),
    .sel_i(id_sel),
    .we_i(id_we),
    .wb_if_mem_i(id_wb_if_mem),

    .rd_o(id_exe_rd),
    .rs1_o(id_exe_rs1),
    .rs2_o(id_exe_rs2),
    .rs1_dat_o(id_exe_rs1_dat),
    .rs2_dat_o(id_exe_rs2_dat),
    .imm_o(id_exe_imm),
    .alu_op_o(id_exe_alu_op),
    .alu_mux_a_o(id_exe_alu_mux_a),
    .alu_mux_b_o(id_exe_alu_mux_b),
    .mem_en_o(id_exe_mem_en),
    .rf_wen_o(id_exe_rf_wen),
    .sel_o(id_exe_sel),
    .we_o(id_exe_we),
    .wb_if_mem_o(id_exe_wb_if_mem)
  );
  
  //EXE
  logic [2:0] alu_mux_a_code;
  logic [DATA_WIDTH-1:0] alu_mux_a_forward;
  logic [DATA_WIDTH-1:0] alu_a;
  alu_mux_a alu_mux_a_u(
    .code(alu_mux_a_code),
    .data(id_exe_rs1_dat),
    .pc(id_exe_pc),
    .forward_data(alu_mux_a_forward),
    .result(alu_a)
  );

  logic [2:0] alu_mux_b_code;
  logic [DATA_WIDTH-1:0] alu_mux_b_forward;
  logic [DATA_WIDTH-1:0] alu_b;
  alu_mux_b alu_mux_b_u(
    .code(alu_mux_b_code),
    .data(id_exe_rs2_dat),
    .imm(id_exe_imm),
    .forward_data(alu_mux_b_forward),
    .result(alu_b)
  );

  ALU alu_u(
    .alu_a(alu_a),
    .alu_b(alu_b),
    .alu_op(id_exe_alu_op),
    .alu_y(alu_y)
  );
  
  logic [DATA_WIDTH-1:0] exe_mem_instr;
  logic [4:0] exe_mem_rd;
  logic [DATA_WIDTH-1:0] exe_mem_rs2_dat;
  logic exe_mem_mem_en;
  logic exe_mem_rf_wen;
  logic [3:0] exe_mem_sel;
  logic exe_mem_we;
  logic [DATA_WIDTH-1:0] exe_mem_wdata;
  logic exe_mem_wb_if_mem;
  logic use_mem_dat_a_i;
  logic use_mem_dat_b_i;
  logic use_mem_dat_a_o;
  logic use_mem_dat_b_o;
  EXE_MEM_reg EXE_MEM(
    .clk(sys_clk),
    .rst(sys_rst),
    .stall(exe_mem_stall),
    .bubble(exe_mem_bubble),
    .instr_i(id_exe_instr),
    .instr_o(exe_mem_instr),
    .rd_i(id_exe_rd),
    .rs2_dat_i(id_exe_rs2_dat),
    .mem_en_i(id_exe_mem_en),
    .rf_wen_i(id_exe_rf_wen),
    .sel_i(id_exe_sel),
    .we_i(id_exe_we),
    .wb_if_mem_i(id_exe_wb_if_mem),

    .rd_o(exe_mem_rd),
    .rs2_dat_o(exe_mem_rs2_dat),
    .mem_en_o(exe_mem_mem_en),
    .rf_wen_o(exe_mem_rf_wen),
    .sel_o(exe_mem_sel),
    .we_o(exe_mem_we),
    .wdata_i(alu_y),
    .wdata_o(exe_mem_wdata),
    .wb_if_mem_o(exe_mem_wb_if_mem),

    .use_mem_dat_a_i(use_mem_dat_a_i),
    .use_mem_dat_b_i(use_mem_dat_b_i),
    .use_mem_dat_a_o(use_mem_dat_a_o),
    .use_mem_dat_b_o(use_mem_dat_b_o)
  );
  
  //MEM
  logic dm_wb_cyc_o;
  logic dm_wb_stb_o;
  logic dm_wb_ack_i;
  logic [ADDR_WIDTH-1:0] dm_wb_adr_o;
  logic [DATA_WIDTH-1:0] dm_wb_dat_o;
  logic [DATA_WIDTH-1:0] dm_wb_dat_i;
  logic [DATA_WIDTH/8-1:0] dm_wb_sel_o;
  logic dm_wb_we_o;
  logic dm_master_ready_o;
  assign mem_stall_req = ~dm_master_ready_o;
  logic [DATA_WIDTH-1:0] dm_data_out;
  Data_memory DM_u(
    .clk(sys_clk),
    .rst(sys_rst),
    .wb_cyc_o(dm_wb_cyc_o),
    .wb_stb_o(dm_wb_stb_o),
    .wb_ack_i(dm_wb_ack_i),
    .wb_adr_o(dm_wb_adr_o),
    .wb_dat_o(dm_wb_dat_o),
    .wb_dat_i(dm_wb_dat_i),
    .wb_sel_o(dm_wb_sel_o),
    .wb_we_o(dm_wb_we_o),
    .master_ready_o(dm_master_ready_o),
    .mem_en(exe_mem_mem_en),
    .write_en(exe_mem_we),
    .addr(exe_mem_wdata),
    .data_in(exe_mem_rs2_dat),
    .sel(exe_mem_sel),
    .data_out(dm_data_out),
    .pipeline_stall(pipeline_stall),
    .idle_stall(dm_idle_stall)
  );
  
  logic mem_wb_wb_if_mem;
  logic [DATA_WIDTH-1:0] mem_wb_wdata;
  logic [DATA_WIDTH-1:0] mem_wb_mem_data;
  MEM_WB_reg MEM_WB(
    .clk(sys_clk),
    .rst(sys_rst),
    .stall(mem_wb_stall),
    .bubble(mem_wb_bubble),
    .instr_i(exe_mem_instr),
    .rd_i(exe_mem_rd),
    .rf_wen_i(exe_mem_rf_wen),
    .wb_if_mem_i(exe_mem_wb_if_mem),
    .rd_o(wb_rd),
    .rf_wen_o(wb_rf_we),
    .wb_if_mem_o(mem_wb_wb_if_mem),
    .wdata_i(exe_mem_wdata),
    .wdata_o(mem_wb_wdata),
    .mem_data_i(dm_data_out),
    .mem_data_o(mem_wb_mem_data)
  );

  //WB
  wb_mux WB_MUX_u(
    .if_mem(mem_wb_wb_if_mem),
    .alu_data(mem_wb_wdata),
    .mem_data(mem_wb_mem_data),
    .result(wb_wdata)
  );

  //tmp
  // always_comb begin
  //   if(id_exe_rf_wen && (id_rs1 == id_exe_rd || id_rs2 == id_exe_rd) && id_exe_rd != 0
  //   || exe_mem_rf_wen && (id_rs1 == exe_mem_rd || id_rs2 == exe_mem_rd) && exe_mem_rd != 0
  //   || wb_rf_we && (id_rs1 == wb_rd || id_rs2 == wb_rd) && wb_rd != 0)begin
  //     exe_stall_req = 1;
  //   end else begin
  //     exe_stall_req = 0;
  //   end
  // end

  // Forward Unit
  logic exe_is_load;
  assign exe_is_load = id_exe_mem_en && id_exe_rf_wen;
  logic mem_is_load;
  assign mem_is_load = exe_mem_mem_en && exe_mem_rf_wen;
  logic wb_is_load;
  assign wb_is_load = mem_wb_wb_if_mem && wb_rf_we;

  Forward_Unit FU_u(
    .id_exe_rs1(id_exe_rs1),
    .id_exe_rs2(id_exe_rs2),
    .exe_mem_rd(exe_mem_rd),
    .exe_mem_rf_wen(exe_mem_rf_wen),
    .exe_mem_dat(exe_mem_wdata),
    .if_id_rs1(id_rs1),
    .if_id_rs2(id_rs2),
    .id_exe_rd(id_exe_rd),
    .exe_is_load(exe_is_load),

    // add signal
    .mem_is_load(mem_is_load),
    .id_exe_rf_wen(id_exe_rf_wen),
    .wb_rf_we(wb_rf_we),
    .mem_wb_rd(wb_rd),
    .wb_is_load(wb_is_load),
    .wb_dat(wb_wdata),

    .use_mem_dat_a(use_mem_dat_a_o),
    .use_mem_dat_b(use_mem_dat_b_o),
    .mem_wb_dat(mem_wb_wdata),
    .id_exe_alu_mux_a(id_exe_alu_mux_a),
    .id_exe_alu_mux_b(id_exe_alu_mux_b),
    .alu_mux_a(alu_mux_a_code),
    .alu_mux_b(alu_mux_b_code),
    .alu_a_forward(alu_mux_a_forward),
    .alu_b_forward(alu_mux_b_forward),
    .exe_stall_req(exe_stall_req),
    .pass_use_mem_dat_a(use_mem_dat_a_i),
    .pass_use_mem_dat_b(use_mem_dat_b_i),
    .branch_rs1(branch_rs1_hazard),
    .branch_rs2(branch_rs2_hazard)
  );
  
  // slaves
  logic [ADDR_WIDTH-1:0] wbs_adr_o;
  logic [DATA_WIDTH-1:0] wbs_dat_i;
  logic [DATA_WIDTH-1:0] wbs_dat_o;
  logic wbs_we_o;
  logic [DATA_WIDTH/8-1:0] wbs_sel_o;
  logic wbs_stb_o;
  logic wbs_ack_i;
  logic wbs_cyc_o;
  wb_arbiter_2 sram_arbiter(
    .clk(sys_clk),
    .rst(sys_rst),

    .wbm0_adr_i(im_wb_adr_o),
    .wbm0_dat_i(im_wb_dat_o),
    .wbm0_dat_o(im_wb_dat_i),
    .wbm0_we_i(im_wb_we_o),
    .wbm0_sel_i(im_wb_sel_o),
    .wbm0_stb_i(im_wb_stb_o),
    .wbm0_ack_o(im_wb_ack_i),
    .wbm0_cyc_i(im_wb_cyc_o),

    .wbm1_adr_i(dm_wb_adr_o),
    .wbm1_dat_i(dm_wb_dat_o),
    .wbm1_dat_o(dm_wb_dat_i),
    .wbm1_we_i(dm_wb_we_o),
    .wbm1_sel_i(dm_wb_sel_o),
    .wbm1_stb_i(dm_wb_stb_o),
    .wbm1_ack_o(dm_wb_ack_i),
    .wbm1_cyc_i(dm_wb_cyc_o),

    .wbs_adr_o(wbs_adr_o),
    .wbs_dat_i(wbs_dat_i),
    .wbs_dat_o(wbs_dat_o),
    .wbs_we_o(wbs_we_o),
    .wbs_sel_o(wbs_sel_o),
    .wbs_stb_o(wbs_stb_o),
    .wbs_ack_i(wbs_ack_i),
    .wbs_cyc_o(wbs_cyc_o)
  );

  // Wishbone MUX (Masters) => bus slaves
  logic wbs0_cyc_o;
  logic wbs0_stb_o;
  logic wbs0_ack_i;
  logic [31:0] wbs0_adr_o;
  logic [31:0] wbs0_dat_o;
  logic [31:0] wbs0_dat_i;
  logic [3:0] wbs0_sel_o;
  logic wbs0_we_o;

  logic wbs1_cyc_o;
  logic wbs1_stb_o;
  logic wbs1_ack_i;
  logic [31:0] wbs1_adr_o;
  logic [31:0] wbs1_dat_o;
  logic [31:0] wbs1_dat_i;
  logic [3:0] wbs1_sel_o;
  logic wbs1_we_o;

  logic wbs2_cyc_o;
  logic wbs2_stb_o;
  logic wbs2_ack_i;
  logic [31:0] wbs2_adr_o;
  logic [31:0] wbs2_dat_o;
  logic [31:0] wbs2_dat_i;
  logic [3:0] wbs2_sel_o;
  logic wbs2_we_o;

  wb_mux_3 wb_mux (
      .clk(sys_clk),
      .rst(sys_rst),

      // Master interface (to Lab5 master)
      .wbm_adr_i(wbs_adr_o),
      .wbm_dat_i(wbs_dat_o),
      .wbm_dat_o(wbs_dat_i),
      .wbm_we_i (wbs_we_o),
      .wbm_sel_i(wbs_sel_o),
      .wbm_stb_i(wbs_stb_o),
      .wbm_ack_o(wbs_ack_i),
      .wbm_err_o(),
      .wbm_rty_o(),
      .wbm_cyc_i(wbs_cyc_o),

      // Slave interface 0 (to BaseRAM controller)
      // Address range: 0x8000_0000 ~ 0x803F_FFFF
      .wbs0_addr    (32'h8000_0000),
      .wbs0_addr_msk(32'hFFC0_0000),

      .wbs0_adr_o(wbs0_adr_o),
      .wbs0_dat_i(wbs0_dat_i),
      .wbs0_dat_o(wbs0_dat_o),
      .wbs0_we_o (wbs0_we_o),
      .wbs0_sel_o(wbs0_sel_o),
      .wbs0_stb_o(wbs0_stb_o),
      .wbs0_ack_i(wbs0_ack_i),
      .wbs0_err_i('0),
      .wbs0_rty_i('0),
      .wbs0_cyc_o(wbs0_cyc_o),

      // Slave interface 1 (to ExtRAM controller)
      // Address range: 0x8040_0000 ~ 0x807F_FFFF
      .wbs1_addr    (32'h8040_0000),
      .wbs1_addr_msk(32'hFFC0_0000),

      .wbs1_adr_o(wbs1_adr_o),
      .wbs1_dat_i(wbs1_dat_i),
      .wbs1_dat_o(wbs1_dat_o),
      .wbs1_we_o (wbs1_we_o),
      .wbs1_sel_o(wbs1_sel_o),
      .wbs1_stb_o(wbs1_stb_o),
      .wbs1_ack_i(wbs1_ack_i),
      .wbs1_err_i('0),
      .wbs1_rty_i('0),
      .wbs1_cyc_o(wbs1_cyc_o),

      // Slave interface 2 (to UART controller)
      // Address range: 0x1000_0000 ~ 0x1000_FFFF
      .wbs2_addr    (32'h1000_0000),
      .wbs2_addr_msk(32'hFFFF_0000),

      .wbs2_adr_o(wbs2_adr_o),
      .wbs2_dat_i(wbs2_dat_i),
      .wbs2_dat_o(wbs2_dat_o),
      .wbs2_we_o (wbs2_we_o),
      .wbs2_sel_o(wbs2_sel_o),
      .wbs2_stb_o(wbs2_stb_o),
      .wbs2_ack_i(wbs2_ack_i),
      .wbs2_err_i('0),
      .wbs2_rty_i('0),
      .wbs2_cyc_o(wbs2_cyc_o)
  );

  /* =========== Lab5 MUX end =========== */

  /* =========== Lab5 Slaves begin =========== */
  sram_controller #(
      .SRAM_ADDR_WIDTH(20),
      .SRAM_DATA_WIDTH(32)
  ) sram_controller_base (
      .clk_i(sys_clk),
      .rst_i(sys_rst),

      // Wishbone slave (to MUX)
      .wb_cyc_i(wbs0_cyc_o),
      .wb_stb_i(wbs0_stb_o),
      .wb_ack_o(wbs0_ack_i),
      .wb_adr_i(wbs0_adr_o),
      .wb_dat_i(wbs0_dat_o),
      .wb_dat_o(wbs0_dat_i),
      .wb_sel_i(wbs0_sel_o),
      .wb_we_i (wbs0_we_o),

      // To SRAM chip
      .sram_addr(base_ram_addr),
      .sram_data(base_ram_data),
      .sram_ce_n(base_ram_ce_n),
      .sram_oe_n(base_ram_oe_n),
      .sram_we_n(base_ram_we_n),
      .sram_be_n(base_ram_be_n)
  );

  sram_controller #(
      .SRAM_ADDR_WIDTH(20),
      .SRAM_DATA_WIDTH(32)
  ) sram_controller_ext (
      .clk_i(sys_clk),
      .rst_i(sys_rst),

      // Wishbone slave (to MUX)
      .wb_cyc_i(wbs1_cyc_o),
      .wb_stb_i(wbs1_stb_o),
      .wb_ack_o(wbs1_ack_i),
      .wb_adr_i(wbs1_adr_o),
      .wb_dat_i(wbs1_dat_o),
      .wb_dat_o(wbs1_dat_i),
      .wb_sel_i(wbs1_sel_o),
      .wb_we_i (wbs1_we_o),

      // To SRAM chip
      .sram_addr(ext_ram_addr),
      .sram_data(ext_ram_data),
      .sram_ce_n(ext_ram_ce_n),
      .sram_oe_n(ext_ram_oe_n),
      .sram_we_n(ext_ram_we_n),
      .sram_be_n(ext_ram_be_n)
  );

  // 串口控制器模�???
  // NOTE: 如果修改系统时钟频率，也�???要修改此处的时钟频率参数
  uart_controller #(
      .CLK_FREQ(50_000_000),
      .BAUD    (115200)
  ) uart_controller (
      .clk_i(sys_clk),
      .rst_i(sys_rst),

      .wb_cyc_i(wbs2_cyc_o),
      .wb_stb_i(wbs2_stb_o),
      .wb_ack_o(wbs2_ack_i),
      .wb_adr_i(wbs2_adr_o),
      .wb_dat_i(wbs2_dat_o),
      .wb_dat_o(wbs2_dat_i),
      .wb_sel_i(wbs2_sel_o),
      .wb_we_i (wbs2_we_o),

      // to UART pins
      .uart_txd_o(txd),
      .uart_rxd_i(rxd)
  );

  /* =========== Lab5 Slaves end =========== */
  
  // ����debug��������
//  assign leds[0] = if_stall_req;
//  assign leds[1] = mem_stall_req;
//  assign leds[2] = id_flush_req;
//  assign leds[3] = exe_stall_req;
//  assign leds[4] = pc_stall;
//  assign leds[5] = if_id_stall;
//  assign leds[6] = if_id_bubble;
//  assign leds[7] = id_exe_stall;
//  assign leds[8] = id_exe_bubble;
//  assign leds[9] = exe_mem_stall;
//  assign leds[10] = exe_mem_bubble;
//  assign leds[11] = mem_wb_stall;
//  assign leds[12] = mem_wb_bubble;
//  assign leds[13] = pipeline_stall;
//  assign leds[14] = 0;
//  assign leds[15] = 0;
    assign leds = exe_mem_wdata[15:0];

endmodule
