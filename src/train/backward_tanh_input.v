`include "consts_train.vh"

module backward_tanh_input (
    input  wire clk,
    input  wire rst_n,
    input  wire run,
    input  wire [`STATE_LEN-1:0] state,
    input  wire [`N*`HID_DIM*`N_LEN-1:0] d_dense,
    input  wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] d_mix,
    output reg  valid,
    output wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] q
  );


  // ----------------------------------------
  genvar i, j;

  // wire valid controller
  wire load;

  // wire input buffer
  wire [`N_LEN-1:0] d_mix_buf [0:`HID_DIM-1][0:`HID_DIM-1];

  // reg add input
  reg [4:0] count1;
  reg [`N_LEN-1:0] hid_vec [0:`HID_DIM-1];

  // wire tanh_layer input
  wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] tanh3_in;
  wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] tanh2_in;
  wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] tanh1_in;


  // ----------------------------------------
  // convert shape (`HID_DIM*`HID_DIM*`N_LEN,) <- (`HID_DIM, `HID_DIM, `N_LEN)
  generate
    for (i = 0; i < `HID_DIM; i = i + 1) begin
      for (j = 0; j < `HID_DIM; j = j + 1) begin
        assign d_mix_buf[i][j] = d_mix[(i*`HID_DIM+j)*`N_LEN +: `N_LEN];
      end
    end
  endgenerate

  // assign load
  assign load = (state == `B_TANH3) | ((state == `B_TANH2) & (count1 == `HID_DIM - 2)) | (state == `B_TANH1);

  // assign tanh3_in
  assign tanh3_in = {{((`HID_DIM-`N)*`HID_DIM){`N_LEN'b0}}, d_dense};

  // assign tanh2_in
  generate
    for (i = 0; i < `HID_DIM; i = i + 1) begin
      assign tanh2_in[i*`HID_DIM*`N_LEN +: `HID_DIM*`N_LEN] = {{(`HID_DIM-1){`N_LEN'b0}}, hid_vec[i]};
    end
  endgenerate


  // assign tanh1_in
  assign tanh1_in = d_mix;

  // assign output
  assign q = (state == `B_TANH3) ? tanh3_in :
             (state == `B_TANH2) ? tanh2_in : 
             (state == `B_TANH1) ? tanh1_in : tanh3_in; 

                 
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

  // counter
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      count1 <= 0;
    end else if (run) begin
      if (count1 != `HID_DIM - 2) begin
        count1 <= count1 + 2;
      end
    end else begin
      count1 <= 0;
    end
  end


  // add d_mix_buf[i]
  generate
    for (i = 0; i < `HID_DIM; i = i + 1) begin
      always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
          hid_vec[i] <= 0;
        end else begin
          if (count1 == 0) begin
            hid_vec[i] <= d_mix_buf[i][0] + d_mix_buf[i][1];
          end else if (count1 != `HID_DIM - 2) begin
            hid_vec[i] <= hid_vec[i] + d_mix_buf[i][count1] + d_mix_buf[i][count1+1];
          end
        end
      end
    end
  endgenerate


endmodule