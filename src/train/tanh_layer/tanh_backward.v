`include "consts_train.vh"

module tanh_backward (
    input  wire clk,
    input  wire rst_n,
    input  wire run,
    input  wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] d,
    input  wire [`HID_DIM*`HID_DIM*`N_LEN_W-1:0] q_forward,
    output wire valid,
    output wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] q_backward
  );


  // ----------------------------------------
  genvar i;

  // wire input/output buffer
  wire [`HID_DIM*`N_LEN-1:0] d_buf [0:`HID_DIM-1];
  wire [`HID_DIM*`N_LEN_W-1:0] q_forward_buf  [0:`HID_DIM-1];
  wire [`HID_DIM*`N_LEN-1:0] q_backward_buf [0:`HID_DIM-1];
  wire [`HID_DIM-1:0] valid_buf;


  // ----------------------------------------
  // convert shape (`HID_DIM, `HID_DIM*`N_LEN) <-> (`HID_DIM*`HID_DIM*`N_LEN,)
  generate
    for (i = 0; i < `HID_DIM; i = i + 1) begin
      assign d_buf[i] = d[i*`HID_DIM*`N_LEN +: `HID_DIM*`N_LEN];
      assign q_forward_buf[i] = q_forward[i*`HID_DIM*`N_LEN_W +: `HID_DIM*`N_LEN_W];
      assign q_backward[i*`HID_DIM*`N_LEN +: `HID_DIM*`N_LEN] = q_backward_buf[i];
    end
  endgenerate

  // assign valid
  assign valid = &valid_buf;


  // ----------------------------------------
  // tanh_backward_block
  generate
    for (i = 0; i < `HID_DIM; i = i + 1) begin : tanh_backward_block
      tanh_backward_block tanh_backward_block_inst (
        .clk(clk),
        .rst_n(rst_n),
        .run(run),
        .d(d_buf[i]),
        .q_forward(q_forward_buf[i]),
        .valid(valid_buf[i]),
        .q_backward(q_backward_buf[i])
      );
    end
  endgenerate

endmodule