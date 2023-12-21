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
  // reg input buffer
  wire [`HID_DIM*`HID_DIM*`N_LEN_W-1:0] q_forward_buf_delay;
  reg  [`HID_DIM*`HID_DIM*`N_LEN_W-1:0] q_forward_tanh1, q_forward_tanh2, q_forward_tanh3;
  reg  [`HID_DIM*`HID_DIM*`N_LEN_W-1:0] q_forward_tanh1_delay, q_forward_tanh2_delay, q_forward_tanh3_delay;
  
  // wire tanh_backward
  wire [`HID_DIM*`HID_DIM*`N_LEN_W-1:0]  tanh_backward_q_forward;


  // ----------------------------------------
  // assign tanh_backward
  assign tanh_backward_q_forward    = (state_backward == `B_TANH1) ? q_forward_tanh1_delay :
                                      (state_backward == `B_TANH2) ? q_forward_tanh2_delay :
                                      (state_backward == `B_TANH3) ? q_forward_tanh3_delay : {(`HID_DIM*`HID_DIM*`N_LEN_W){1'bX}};


  // ----------------------------------------
  // input buffer controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      q_forward_tanh1 <= 0;
      q_forward_tanh2 <= 0;
      q_forward_tanh3 <= 0;
      q_forward_tanh1_delay <= 0;
      q_forward_tanh2_delay <= 0;
      q_forward_tanh3_delay <= 0;
    end else begin
      if (valid_forward)
        case (state_forward)
          `F_TANH1 : q_forward_tanh1 <= q_forward;
          `F_TANH2 : q_forward_tanh2 <= q_forward;
          `F_TANH3 : q_forward_tanh3 <= q_forward;
        endcase
      if (load_backward) begin
        q_forward_tanh1_delay <= q_forward_tanh1;
        q_forward_tanh2_delay <= q_forward_tanh2;
        q_forward_tanh3_delay <= q_forward_tanh3;
      end
    end
  end


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
  tanh_backward tanh_backward (
    .clk(clk),
    .rst_n(rst_n),
    .run(run_backward),
    .d(d_backward),
    .q_forward(tanh_backward_q_forward),
    .valid(valid_backward),
    .q_backward(q_backward)
  );
  
endmodule