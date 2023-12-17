`include "consts_train.vh"

module mix_block #(
    parameter integer FILENUM = 0,
    parameter integer ADDR_WIDTH = 9    // log2(3*`HID_DIM*`HID_DIM/`DATA_N) < 9
  ) (
    input  wire clk,
    input  wire rst_n,
    input  wire update,
    input  wire zero_grad,
    input  wire run_forward,
    input  wire run_backward,
    input  wire load_backward,
    input  wire [`STATE_LEN-1:0] state_forward,
    input  wire [`STATE_LEN-1:0] state_backward,
    input  wire [`HID_DIM*`N_LEN-1:0] d_forward,
    input  wire [`HID_DIM*`N_LEN-1:0] d_backward,
    output wire valid_update,
    output wire valid_zero_grad,
    output wire valid_forward,
    output wire valid_backward,
    output wire [`HID_DIM*`N_LEN-1:0] q_forward,
    output wire [`HID_DIM*`N_LEN-1:0] q_backward
  );


  // ----------------------------------------
  // wire mix_forward
  wire [ADDR_WIDTH-1:0] mix_forward_raddr_w, mix_forward_raddr_b;
  wire [`DATA_N*`N_LEN_W-1:0] mix_forward_rdata_w;
  wire [`N_LEN_W-1:0] mix_forward_rdata_b;


  // wire mix_ram_wt
  wire mix_ram_wt_load;
  wire [ADDR_WIDTH-1:0] mix_ram_wt_waddr, mix_ram_wt_raddr;
  wire [`DATA_N*`N_LEN_W-1:0] mix_ram_wt_wdata, mix_ram_wt_rdata;

  
  // wire mix_ram_b
  wire mix_ram_b_load;
  wire [ADDR_WIDTH-1:0] mix_ram_b_waddr, mix_ram_b_raddr;
  wire [`N_LEN_W-1:0] mix_ram_b_wdata, mix_ram_b_rdata;


  // ----------------------------------------
  // assign mix_forward
  assign mix_forward_rdata_w = mix_ram_wt_rdata;
  assign mix_forward_rdata_b = mix_ram_b_rdata;


  // assign mix_ram_wt
  assign mix_ram_wt_raddr = mix_forward_raddr_w;


  // assign mix_ram_b
  assign mix_ram_b_raddr = mix_forward_raddr_b;


  // ----------------------------------------


  // ----------------------------------------
  // mix_forward
  mix_forward #(
    .ADDR_WIDTH(ADDR_WIDTH)
  ) mix_forward_inst (
    .clk(clk),
    .rst_n(rst_n),
    .run(run_forward),
    .state(state_forward),
    .d(d_forward),
    .valid(valid_forward),
    .q(q_forward),
    .raddr_w(mix_forward_raddr_w),
    .raddr_b(mix_forward_raddr_b),
    .rdata_w(mix_forward_rdata_w),
    .rdata_b(mix_forward_rdata_b)
  );


  // mix_backward


  // mix_optim_w


  // mix_optim_b


  // mix_ram_wt
  mix_ram_wt #(
    .FILENUM(FILENUM),
    .ADDR_WIDTH(ADDR_WIDTH)
  ) mix_ram_wt_inst (
    .clk(clk),
    .load(mix_ram_wt_load),
    .waddr(mix_ram_wt_waddr),
    .wdata(mix_ram_wt_wdata),
    .raddr(mix_ram_wt_raddr),
    .rdata(mix_ram_wt_rdata)
  );

  // mix_ram_w


  // mix_ram_b
  mix_ram_b #(
    .FILENUM(FILENUM),
    .ADDR_WIDTH(ADDR_WIDTH)
  ) mix_ram_b_inst (
    .clk(clk),
    .load(mix_ram_b_load),
    .waddr(mix_ram_b_waddr),
    .wdata(mix_ram_b_wdata),
    .raddr(mix_ram_b_raddr),
    .rdata(mix_ram_b_rdata)
  );

  // mix_ram_v_w

  
  // mix_ram_v_b

  
  // mix_ram_grad_w

  
  // mix_ram_grad_b


  // mix_w_transpose



endmodule