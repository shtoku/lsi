`include "consts_train.vh"

module mix_layer (
    input  wire clk,
    input  wire rst_n,
    input  wire update,
    input  wire zero_grad,
    input  wire run_forward,
    input  wire run_backward,
    input  wire load_backward,
    input  wire [`STATE_LEN-1:0] state_forward,
    input  wire [`STATE_LEN-1:0] state_backward,
    input  wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] d_forward,
    input  wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] d_backward,
    output wire valid_update,
    output wire valid_zero_grad,
    output wire valid_forward,
    output wire valid_backward,
    output wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] q_forward,
    output wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] q_backward
  );


  // ----------------------------------------
  genvar i, j;

  // wire input/output buffer
  wire [`HID_DIM*`N_LEN-1:0] d_forward_buf  [0:`HID_DIM-1];
  wire [`HID_DIM*`N_LEN-1:0] d_backward_buf [0:`HID_DIM-1];
  wire [`HID_DIM*`N_LEN-1:0] q_forward_buf  [0:`HID_DIM-1];
  wire [`HID_DIM*`N_LEN-1:0] q_backward_buf [0:`HID_DIM-1];

  // wire valid buffer
  wire [`HID_DIM-1:0] valid_update_buf;
  wire [`HID_DIM-1:0] valid_zero_grad_buf;
  wire [`HID_DIM-1:0] valid_forward_buf;
  wire [`HID_DIM-1:0] valid_backward_buf;


  // ----------------------------------------
  // convert shape (`HID_DIM*`HID_DIM*`N_LEN,) <-> (`HID_DIM, `HID_DIM*`N_LEN)
  generate
    for (i = 0; i < `HID_DIM; i = i + 1) begin
      assign d_backward_buf[i] = d_backward[i*`HID_DIM*`N_LEN +: `HID_DIM*`N_LEN];
      assign q_forward[i*`HID_DIM*`N_LEN +: `HID_DIM*`N_LEN]  = q_forward_buf[i];

      // transpose
      for (j = 0; j < `HID_DIM; j = j + 1) begin
        assign d_forward_buf[j][i*`N_LEN +: `N_LEN] = d_forward[(i*`HID_DIM+j)*`N_LEN +: `N_LEN];
        assign q_backward[(i*`HID_DIM+j)*`N_LEN +: `N_LEN] = q_backward_buf[j][i*`N_LEN +: `N_LEN];
      end
    end
  endgenerate

  // assign valid
  assign valid_update    = &valid_update_buf;
  assign valid_zero_grad = &valid_zero_grad_buf;
  assign valid_forward   = &valid_forward_buf;
  assign valid_backward  = &valid_backward_buf;


  // ----------------------------------------
  // mix_block × `HID_DIM
  generate
    for (i = 0; i < `HID_DIM; i = i + 1) begin : mix_block
      mix_block #(
        .FILENUM(i)
      ) mix_block_inst (
        .clk(clk),
        .rst_n(rst_n),
        .update(update),
        .zero_grad(zero_grad),
        .run_forward(run_forward),
        .run_backward(run_backward),
        .load_backward(load_backward),
        .state_forward(state_forward),
        .state_backward(state_backward),
        .d_forward(d_forward_buf[i]),
        .d_backward(d_backward_buf[i]),
        .valid_update(valid_update_buf[i]),
        .valid_zero_grad(valid_zero_grad_buf[i]),
        .valid_forward(valid_forward_buf[i]),
        .valid_backward(valid_backward_buf[i]),
        .q_forward(q_forward_buf[i]),
        .q_backward(q_backward_buf[i])
      );
    end
  endgenerate
  
endmodule