`include "consts_train.vh"

module dense_layer #(
    parameter integer ADDR_WIDTH   = 10,   // log2(`HID_DIM*`CHAR_NUM/DATA_N) < 10
    parameter integer DENSE_DATA_N = 8     // 1 time read, read 8 data.
  ) (
    input  wire clk,
    input  wire rst_n,
    input  wire update,
    input  wire zero_grad,
    input  wire run_forward,
    input  wire run_backward,
    input  wire load_backward,
    input  wire [`N*`HID_DIM*`N_LEN-1:0] d_forward,
    input  wire [`N*`CHAR_NUM*`N_LEN_W-1:0] d_backward,
    output wire valid_update,
    output wire valid_zero_grad,
    output wire valid_forward,
    output wire valid_backward,
    output wire [`N*`CHAR_NUM*`N_LEN-1:0] q_forward,
    output wire [`N*`HID_DIM*`N_LEN-1:0] q_backward
  );


  // ----------------------------------------
  // wire dense_forward
  wire [ADDR_WIDTH-1:0]          dense_forward_raddr;
  wire [DENSE_DATA_N*`N_LEN-1:0] dense_forward_rdata;

  // wire dense_backward

  // wire dense_optim

  // wire dense_ram_wt
  wire dense_ram_wt_load;
  wire [ADDR_WIDTH-1:0]          dense_ram_wt_waddr, dense_ram_wt_raddr;
  wire [DENSE_DATA_N*`N_LEN-1:0] dense_ram_wt_wdata, dense_ram_wt_rdata;

  // wire dense_ram_w

  // wire dense_ram_v

  // wire dense_ram_grad

  // wire dense_transpose


  // ----------------------------------------
  // assign dense_forward
  assign dense_forward_rdata = dense_ram_wt_rdata;

  // assign dense_backward

  // assign dense_optim

  // assign dense_ram_wt
  assign dense_ram_wt_load  = 0;
  assign dense_ram_wt_waddr = 0;
  assign dense_ram_wt_wdata = 0;
  assign dense_ram_wt_raddr = dense_forward_raddr;

  // assign dense_ram_w

  // assign dense_ram_v

  // assign dense_ram_grad

  // assign dense_transpose


  // ----------------------------------------


  // ----------------------------------------
  // dense_forward
  dense_forward #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DENSE_DATA_N(DENSE_DATA_N)
  ) dense_forward_inst (
    .clk(clk), 
    .rst_n(rst_n), 
    .run(run_forward),
    .d(d_forward),
    .valid(valid_forward),
    .q(q_forward),
    .raddr(dense_forward_raddr),
    .rdata(dense_forward_rdata)
  );

  // dense_backward

  // dense_optim

  // dense_ram_wt
  ram #(
    .FILENAME("../../data/parameter/train/binary192/dense_layer_W_out_T.txt"),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DENSE_DATA_N*`N_LEN),
    .DATA_DEPTH(`HID_DIM*`CHAR_NUM/DENSE_DATA_N)
  ) dense_ram_wt (
    .clk(clk),
    .load(dense_ram_wt_load),
    .waddr(dense_ram_wt_waddr),
    .wdata(dense_ram_wt_wdata),
    .raddr(dense_ram_wt_raddr),
    .rdata(dense_ram_wt_rdata)
  );

  // dense_ram_w

  // dense_ram_v

  // dense_ram_grad

  // dense_transpose

endmodule