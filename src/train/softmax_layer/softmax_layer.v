`include "consts_train.vh"

module softmax_layer (
    input  wire clk,
    input  wire rst_n,
    input  wire run,
    input  wire load_d_num,
    input  wire [`N*`CHAR_NUM*`N_LEN-1:0] d,
    input  wire [`N*`CHAR_LEN-1:0] d_num,
    input  wire [`N*`N_LEN-1:0] d_max,
    output wire valid,
    output wire [`N*`CHAR_NUM*`N_LEN_W-1:0] q
  );


  // ----------------------------------------
  genvar i;

  // reg/wire input/output buffer
  wire [`CHAR_NUM*`N_LEN-1:0] d_buf [0:`N-1];
  reg  [`CHAR_LEN-1:0] d_num_buf [0:`N-1];
  wire [`N_LEN-1:0] d_max_buf [0:`N-1];
  wire [`CHAR_NUM*`N_LEN_W-1:0] q_buf [0:`N-1];
  wire [`N-1:0] valid_buf;


  // ----------------------------------------
  generate
    for (i = 0; i < `N; i = i + 1) begin
      // convert shape (`N, `CHAR_NUM*`N_LEN) <-> (`HID_DIM*`HID_DIM*`N_LEN,)
      assign d_buf[i] = d[i*`CHAR_NUM*`N_LEN +: `CHAR_NUM*`N_LEN];
      assign q[i*`CHAR_NUM*`N_LEN_W +: `CHAR_NUM*`N_LEN_W] = q_buf[i];
      
      // convert shape (`N, `N_LEN) <- (`N*`N_LEN,)
      assign d_max_buf[i] = d_max[i*`N_LEN +: `N_LEN];
    end
  endgenerate

  // assign valid
  assign valid = &valid_buf;


  // ----------------------------------------
  // input buffer controller
  // convert shape (`N, `CHAR_LEN) <- (`N*`CHAR_LEN,)
  generate
    for (i = 0; i < `N; i = i + 1) begin
      always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
          d_num_buf[i] <= 0;
        end else if (load_d_num) begin
          d_num_buf[i] <= d_num[i*`CHAR_LEN +: `CHAR_LEN];
        end
      end
    end
  endgenerate


  // ----------------------------------------
  // softmax_block
  generate
    for (i = 0; i < `N; i = i + 1) begin : softmax_block
      softmax_block softmax_block_inst (
        .clk(clk),
        .rst_n(rst_n),
        .run(run),
        .d(d_buf[i]),
        .d_num(d_num_buf[i]),
        .d_max(d_max_buf[i]),
        .valid(valid_buf[i]),
        .q(q_buf[i])
      );
    end
  endgenerate
  
endmodule