`include "consts_train.vh"

module tanh_layer (
    input  wire clk,
    input  wire rst_n,
    input  wire run_forward,
    input  wire run_backward,
    input  wire load_backward,
    input  wire [`STATE_LEN-1:0] state_forward,
    input  wire [`STATE_LEN-1:0] state_backward,
    input  wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] d_forward,
    input  wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] d_backward,
    output wire valid_forward,
    output wire valid_backward,
    output wire [`HID_DIM*`HID_DIM*`N_LEN_W-1:0] q_forward,
    output wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] q_backward
  );

  
  // ----------------------------------------


  // ----------------------------------------


  // ----------------------------------------
  // tanh_forward
  tanh_forward tanh_forward_inst (
    .clk(clk),
    .rst_n(rst_n),
    .run(run_forward),
    .d(d_forward),
    .valid(valid_forward),
    .q(q_forward)
  );

  // tanh_backward
  
endmodule