`include "consts_train.vh"

module dense_backward #(
    parameter integer ADDR_WIDTH   = 10,   // log2(`HID_DIM*`CHAR_NUM/DATA_N) < 10
    parameter integer DENSE_DATA_N = 8     // 1 time read, read 8 data.
  ) (
    input  wire clk,
    input  wire rst_n,
    input  wire run,
    input  wire [`N*`HID_DIM*`N_LEN_W-1:0] d_forward,
    input  wire [`N*`CHAR_NUM*`N_LEN_W-1:0] d_backward,
    output wire valid,
    output wire [`N*`HID_DIM*`N_LEN-1:0] q,
    output wire [ADDR_WIDTH-1:0] waddr,
    output wire [DENSE_DATA_N*`N_LEN-1:0] wdata,
    output wire [ADDR_WIDTH-1:0] raddr_w,
    output wire [ADDR_WIDTH-1:0] raddr_grad,
    input  wire [DENSE_DATA_N*`N_LEN-1:0] rdata_w,
    input  wire [DENSE_DATA_N*`N_LEN-1:0] rdata_grad
  );

  wire valid_backward_q;
  wire valid_backward_grad;

  assign valid = (valid_backward_q & valid_backward_grad);


  // dense_backward_q
  dense_backward_q #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DENSE_DATA_N(DENSE_DATA_N)
  ) dense_backward_q_inst (
    .clk(clk),
    .rst_n(rst_n),
    .run(run),
    .d(d_backward),
    .valid(valid_backward_q),
    .q(q),
    .raddr(raddr_w),
    .rdata(rdata_w)
  );

  // dense_backward_grad
  dense_backward_grad #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DENSE_DATA_N(DENSE_DATA_N)
  ) dense_backward_grad_inst (
    .clk(clk),
    .rst_n(rst_n),
    .run(run),
    .d_forward(d_forward),
    .d_backward(d_backward),
    .valid(valid_backward_grad),
    .waddr(waddr),
    .wdata(wdata),
    .raddr(raddr_grad),
    .rdata(rdata_grad)
  );

endmodule