`include "consts_train.vh"

module mix_backward #(
    parameter integer ADDR_WIDTH = 9    // log2(3*`HID_DIM*`HID_DIM/`DATA_N) < 9
  ) (
    input  wire clk,
    input  wire rst_n,
    input  wire run,
    input  wire [`STATE_LEN-1:0] state,
    input  wire [`HID_DIM*`N_LEN-1:0] d_forward,
    input  wire [`HID_DIM*`N_LEN-1:0] d_backward,
    output wire valid,
    output wire [`HID_DIM*`N_LEN-1:0] q,
    output wire [ADDR_WIDTH-1:0] waddr_grad_w,
    output wire [ADDR_WIDTH-1:0] waddr_grad_b,
    output wire [`DATA_N*`N_LEN_W-1:0] wdata_grad_w,
    output wire [`N_LEN_W-1:0]         wdata_grad_b,
    output wire [ADDR_WIDTH-1:0] raddr_w,
    output wire [ADDR_WIDTH-1:0] raddr_grad_w,
    output wire [ADDR_WIDTH-1:0] raddr_grad_b,
    input  wire [`DATA_N*`N_LEN_W-1:0] rdata_w,
    input  wire [`DATA_N*`N_LEN_W-1:0] rdata_grad_w,
    input  wire [`N_LEN_W-1:0]         rdata_grad_b
  );

  wire valid_backward_q;
  wire valid_backward_grad;

  assign valid = (valid_backward_q & valid_backward_grad);


  // mix_backward_q
  mix_backward_q #(
    .ADDR_WIDTH(ADDR_WIDTH)
  ) mix_backward_q_inst (
    .clk(clk),
    .rst_n(rst_n),
    .run(run),
    .state(state),
    .d(d_backward),
    .valid(valid_backward_q),
    .q(q),
    .raddr_w(raddr_w),
    .rdata_w(rdata_w)
  );

  // mix_backward_grad
  mix_backward_grad #(
    .ADDR_WIDTH(ADDR_WIDTH)
  ) mix_backward_grad_inst (
    .clk(clk),
    .rst_n(rst_n),
    .run(run),
    .state(state),
    .d_forward(d_forward),
    .d_backward(d_backward),
    .valid(valid_backward_grad),
    .waddr_grad_w(waddr_grad_w),
    .waddr_grad_b(waddr_grad_b),
    .wdata_grad_w(wdata_grad_w),
    .wdata_grad_b(wdata_grad_b),
    .raddr_grad_w(raddr_grad_w),
    .raddr_grad_b(raddr_grad_b),
    .rdata_grad_w(rdata_grad_w),
    .rdata_grad_b(rdata_grad_b)
  );
  


endmodule