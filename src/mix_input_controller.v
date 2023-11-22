`include "consts.vh"

module mix_input_controller (
    input  wire clk,
    input  wire rst_n,
    input  wire [`STATE_LEN-1:0] state,
    input  wire [`N*`EMB_DIM*`N_LEN-1:0] d_emb,
    input  wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] d_mix,
    input  wire valid_emb,
    input  wire valid_mix,
    output reg  valid,
    output wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] q
  );


  // ----------------------------------------
  genvar i, j;

  // wire valid controller
  wire load;

  // d_emb, d_mix buffer
  reg  [`N*`EMB_DIM*`N_LEN-1:0] d_emb_buf;
  reg  [`HID_DIM*`HID_DIM*`N_LEN-1:0] d_mix_buf;

  // wire hidden vector
  wire [`N_LEN-1:0] hid_vec [0:`HID_DIM-1];

  // wire mix_layer input
  wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] mix1_in;
  wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] mix2_in;
  wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] mix3_in;


  // ----------------------------------------
  // assign load
  assign load = ((state == `MIX1) | (state == `MIX2) | (state == `MIX3)) & ~valid_mix;

  // assign hid_vec
  generate
    for (i = 0; i < `HID_DIM; i = i + 1) begin
      assign hid_vec[i] = d_mix_buf[i*`HID_DIM*`N_LEN +: `N_LEN];
    end
  endgenerate

  // assign mix1_in
  assign mix1_in = {{((`HID_DIM-`N)*`HID_DIM){`N_LEN'b0}}, d_emb_buf};

  // assign mix2_in
  assign mix2_in = d_mix_buf;

  // assign mix3_in
  generate
    for (i = 0; i < `HID_DIM; i = i + 1) begin
      for (j = 0; j < `HID_DIM; j = j + 1) begin
        assign mix3_in[(`HID_DIM*i+j)*`N_LEN +: `N_LEN] = hid_vec[i];
      end
    end
  endgenerate

  // assign output
  assign q = (state == `MIX1) ? mix1_in : 
             (state == `MIX2) ? mix2_in : 
             (state == `MIX3) ? mix3_in : d_mix_buf;


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

  // d_emb register
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      d_emb_buf <= {(`N*`EMB_DIM*`N_LEN){1'b0}};
    end else if (valid_emb) begin
      d_emb_buf <= d_emb;
    end
  end

  // d_mix register
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      d_mix_buf <= {(`HID_DIM*`HID_DIM*`N_LEN){1'b0}};
    end else if (valid_mix) begin
      d_mix_buf <= d_mix;
    end
  end

endmodule