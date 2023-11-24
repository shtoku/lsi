`include "consts.vh"

module dense_layer (
    input  wire clk,
    input  wire rst_n,
    input  wire run,//ここらへんは決まってる
    input  wire [`N*`HID_DIM*`N_LEN-1:0] d,
    output wire valid,
    output wire [`N*`CHAR_NUM*`N_LEN-1:0] q//10*200*16,縦10個、横24*16
  ); 


  genvar i, j;
  integer m, n;

  wire [`HID_DIM*`N_LEN-1:0] d1_buf [0:`N-1];//inputにあたる。
  wire [`HID_DIM*`N_LEN-1:0] d2_buf [0:`N-1];//W_outにあたる。
  wire [`N_LEN-1:0] q_inner_buf [0:`N-1];//16が10個

  reg  [`N_LEN-1:0] q_buf [0:`N-1][0:`CHAR_NUM-1];

  reg [2:0] count;

  // reg/wire inner_24
  wire run_block;
  wire [`CHAR_LEN-1:0] d_block;
  reg  [`CHAR_LEN-1:0] d_block_delay;
  wire valid_block;
  wire [`HID_DIM*`N_LEN-1:0] q_block;

  // assign dense_block
  assign run_block = run & ~valid_block & ~valid;
  assign d_block = (valid_block) ? d_block_delay + 1 : d_block_delay;
  
  // assign output
  assign valid = (count == 0) & (d_block_delay == `CHAR_NUM);

//q_bufを横並びにする
  generate
    for (i = 0; i < `N; i = i + 1) begin
      for (j = 0; j < `CHAR_NUM; j = j + 1) begin
        assign q[(i*`CHAR_NUM+j)*`N_LEN +: `N_LEN] = q_buf[i][j];
      end
    end
  endgenerate

//input.txtから[10,24]->[10*24,]
  generate
    for (i = 0; i < `N; i = i + 1) begin//10*24
      assign d1_buf[i] = d[i*`HID_DIM*`N_LEN +: `HID_DIM*`N_LEN];
    end
  endgenerate


  // d_block
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      d_block_delay <= 0;
    end else if (valid_block) begin
      d_block_delay <= d_block_delay + 1;
    end
  end

  // count
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      count <= 0;
    end else if (valid_block) begin
      count <= 1;
    end else if (count != 0 & count != 4) begin
      count <= count + 1;
    end else begin
      count <= 0;
    end
  end

  // q_buf
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      for (m = 0; m < `N; m = m + 1) begin
        for (n = 0; n < `CHAR_NUM; n = n + 1) begin
          q_buf[m][n] <= 0;
        end
      end
    end else if (count == 4) begin
      for (n = 0 ; n < `N; n = n + 1) begin
        q_buf[n][d_block-1] <= q_inner_buf[n];
      end
    end
  end

//inner24のインスタンス化
  generate
    for (genvar i = 0; i < `N; i=i+1) begin
      inner_24 inner_24_inst (
        .clk(clk),
        .rst_n(rst_n),
        .run(run),
        .d1(d1_buf[i]),
        .d2(q_block),
        .q(q_inner_buf[i])
      );
    end
  endgenerate

//dense_blockのインスタンス化
  dense_block dense_block_inst (
    .clk(clk),
    .rst_n(rst_n),
    .run(run_block),
    .d(d_block),
    .valid(valid_block),
    .q(q_block)
  );
  
endmodule