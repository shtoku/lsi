`include "consts_train.vh"

module forward_mix_input (
    input  wire clk,
    input  wire rst_n,
    input  wire [`STATE_LEN-1:0] state,
    input  wire [`MODE_LEN-1:0] mode,
    input  wire [`N*`EMB_DIM*`N_LEN_W-1:0] d_emb,
    input  wire [`HID_DIM*`HID_DIM*`N_LEN_W-1:0] d_tanh,
    // input  wire [`HID_DIM*`N_LEN_W-1:0] d_rand,
    // input  wire valid_rand,
    output reg  valid,
    output wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] q
  );
  

  // ----------------------------------------
  genvar i, j;

  // wire output buffer
  wire [`HID_DIM*`HID_DIM*`N_LEN_W-1:0] q_buf;

  // wire valid controller
  wire load;

  // wire hidden vector
  wire [`N_LEN_W-1:0] hid_vec [0:`HID_DIM-1];

  // wire mix_layer input
  wire [`HID_DIM*`HID_DIM*`N_LEN_W-1:0] mix1_in;
  wire [`HID_DIM*`HID_DIM*`N_LEN_W-1:0] mix2_in;
  wire [`HID_DIM*`HID_DIM*`N_LEN_W-1:0] mix3_in;


  // ----------------------------------------
  // convert shape (`HID_DIM*`HID_DIM*`N_LEN,) <- (`HID_DIM*`HID_DIM*`N_LEN_W,)
  generate
    for (i = 0; i < `HID_DIM; i = i + 1) begin
      for (j = 0; j < `HID_DIM; j = j + 1) begin
        assign q[(i*`HID_DIM+j)*`N_LEN +: `N_LEN] = {{(`I_LEN-`I_LEN_W){q_buf[(i*`HID_DIM+j+1)*`N_LEN_W-1]}}, q_buf[(i*`HID_DIM+j)*`N_LEN_W +: `N_LEN_W]};
      end      
    end
  endgenerate

  // assign load
  assign load = (state == `F_MIX1) | (state == `F_MIX2) | ((state == `F_MIX3) /* & valid_rand */);
  
  // assign hid_vec
  generate
    for (i = 0; i < `HID_DIM; i = i + 1) begin
      assign hid_vec[i] = (mode == `TRAIN   ) ? d_tanh[i*`HID_DIM*`N_LEN_W +: `N_LEN_W] :
                          (mode == `FORWARD ) ? d_tanh[i*`HID_DIM*`N_LEN_W +: `N_LEN_W] :
                          // (mode == `GEN_SIMI) ? d_tanh[i*`HID_DIM*`N_LEN_W +: `N_LEN_W] + {d_rand[(i+1)*`N_LEN_W-1], d_rand[(i+1)*`N_LEN_W-1 : i*`N_LEN_W+1]} :
                          // (mode == `GEN_NEW ) ? d_rand[i*`N_LEN_W +: `N_LEN_W] :
                          d_tanh[i*`HID_DIM*`N_LEN_W +: `N_LEN_W];
    end
  endgenerate

  // assign mix1_in
  assign mix1_in = {{((`HID_DIM-`N)*`HID_DIM){`N_LEN_W'b0}}, d_emb};

  // assign mix2_in
  assign mix2_in = d_tanh;

  // assign mix3_in
  generate
    for (i = 0; i < `HID_DIM; i = i + 1) begin
      for (j = 0; j < `HID_DIM; j = j + 1) begin
        assign mix3_in[(i*`HID_DIM+j)*`N_LEN_W +: `N_LEN_W] = hid_vec[i];
      end
    end
  endgenerate

  // assign output
  assign q_buf = (state == `F_MIX1) ? mix1_in : 
                 (state == `F_MIX2) ? mix2_in : 
                 (state == `F_MIX3) ? mix3_in : mix1_in;
  

  // ----------------------------------------
  // valid controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      valid <= 1'b0;
    end else if (load) begin
      valid <= 1'b1;
    end else begin
      valid <= 1'b0;
    end
  end

endmodule