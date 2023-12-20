`include "consts_train.vh"

module dense_backward_q_block #(
    parameter integer DENSE_DATA_N = 8     // 1 time read, read 8 data.
  ) (
    input  wire clk,
    input  wire rst_n,
    input  wire run,
    input  wire [`CHAR_NUM*`N_LEN_W-1:0] d,
    output wire valid,
    output wire [`HID_DIM*`N_LEN-1:0] q,
    input  wire [DENSE_DATA_N*`N_LEN-1:0] rdata
  );


  // ----------------------------------------
  genvar i;
  integer j;

  // wire input/output buffer
  wire [DENSE_DATA_N*`N_LEN_W-1:0] d_buf [0:`CHAR_NUM/DENSE_DATA_N-1];
  reg  [`N_LEN-1:0] q_buf [0:`HID_DIM-1];

  // reg counter
  reg  [4:0] count1, count1_delay1, count1_delay2, count1_delay3;
  reg  [4:0] count2, count2_delay1, count2_delay2, count2_delay3;

  // reg d_buf_index, q_buf_index
  reg  [4:0] d_buf_index;
  reg  [4:0] q_buf_index, q_buf_index_delay;

  // inner index/buffer
  reg  [4:0] inner_buf_index, inner_buf_index_delay;
  reg  [`N_LEN-1:0] inner_buf [0:`CHAR_NUM/DENSE_DATA_N-1];

  // inner_q add
  reg  [`N_LEN-1:0] inner_add1 [0:6];    // `CHAR_NUM/DENSE_DATA_N / 3 - 1 = 7
  reg  [`N_LEN-1:0] inner_add2 [0:1];    // 7 / 3 = 2
  reg  [`N_LEN-1:0] inner_add3;
  reg  [`N_LEN-1:0] inner_add4;

  // wire dense_inner_8
  wire [DENSE_DATA_N*`N_LEN-1:0]   inner_d1;
  wire [DENSE_DATA_N*`N_LEN_W-1:0] inner_d2;
  wire [`N_LEN-1:0] inner_q;

  
  // ----------------------------------------
  // assign valid
  assign valid = run & (q_buf_index_delay == `HID_DIM - 1) & (inner_buf_index_delay == `CHAR_NUM/DENSE_DATA_N - 1);

  generate
    // convert shape (`CHAR_NUM/DENSE_DATA_N, DENSE_DATA_N*`N_LEN_W) <- (`CHAR_NUM*`N_LEN_W,)
    for (i = 0; i < `CHAR_NUM/DENSE_DATA_N; i = i + 1) begin
      assign d_buf[i] = d[i*DENSE_DATA_N*`N_LEN_W +: DENSE_DATA_N*`N_LEN_W];
    end
    // convert shape (`HID_DIM*`N_LEN) <- (`CHAR_NUM, `N_LEN)
    for (i = 0; i < `HID_DIM; i = i + 1) begin
      assign q[i*`N_LEN +: `N_LEN] = q_buf[i];
    end
  endgenerate

  // assign dense_inner_8
  assign inner_d1 = rdata;
  assign inner_d2 = d_buf[d_buf_index];

  
  // ----------------------------------------
  // main counter
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      count1 <= 0;
      count2 <= 0;
    end else if (run) begin
      if ((count1 != `CHAR_NUM/DENSE_DATA_N - 1) | (count2 != `HID_DIM - 1)) begin
        if (count1 == `CHAR_NUM/DENSE_DATA_N - 1) begin
          count1 <= 0;
          count2 <= count2 + 1;
        end else begin
          count1 <= count1 + 1;
          count2 <= count2;
        end
      end
    end else begin
      count1 <= 0;
      count2 <= 0;
    end
  end

  // d_buf_index controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      d_buf_index <= 0;
    end else begin
      d_buf_index <= count1;
    end
  end

  // inner_buf_index controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      count1_delay1 <= 0;
      count1_delay2 <= 0;
      count1_delay3 <= 0;
      inner_buf_index <= 0;
      inner_buf_index_delay <= 0;
    end else begin
      count1_delay1 <= count1;
      count1_delay2 <= count1_delay1;
      count1_delay3 <= count1_delay2;
      inner_buf_index <= count1_delay3;
      inner_buf_index_delay <= inner_buf_index;
    end
  end

  // inner_buf controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      for (j = 0; j < `CHAR_NUM/DENSE_DATA_N; j = j + 1) begin
        inner_buf[j] <= 0;
      end
    end else begin
      inner_buf[inner_buf_index] <= inner_q;
    end
  end

  // q_buf_index controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      count2_delay1 <= 0;
      count2_delay2 <= 0;
      count2_delay3 <= 0;
      q_buf_index <= 0;
      q_buf_index_delay <= 0;
    end else begin
      count2_delay1 <= count2;
      count2_delay2 <= count2_delay1;
      count2_delay3 <= count2_delay2;
      q_buf_index <= count2_delay3;
      q_buf_index_delay <= q_buf_index;
    end
  end

  // inner_add1
  generate
    for (i = 0; i < 7; i = i + 1) begin
      always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
          inner_add1[i] <= 0;
        end else begin
          inner_add1[i] <= inner_buf[3*i] + inner_buf[3*i+1] + inner_buf[3*i+2];
        end
      end
    end
  endgenerate

  // inner_add2, 3, 4
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      inner_add2[0] <= 0;
      inner_add2[1] <= 0;
      inner_add3    <= 0;
      inner_add4    <= 0;
    end else begin
      inner_add2[0] <= inner_add1[0] + inner_add1[1] + inner_add1[2];
      inner_add2[1] <= inner_add1[3] + inner_add1[4] + inner_add1[5];
      inner_add3    <= inner_add2[0] + inner_add2[1] + inner_add1[6];
      inner_add4    <= inner_add3    + inner_buf[21] + inner_buf[22];
    end
  end

  // q_buf controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      for (j = 0; j < `CHAR_NUM; j = j + 1) begin
        q_buf[j] <= 0;
      end
    end else if (run) begin
      q_buf[q_buf_index] <= inner_add4 + inner_buf[23] + inner_q;
    end
  end


  // ----------------------------------------
  // dense_inner_8
  dense_inner_8 #(
    .DATA_WIDTH1(`N_LEN),
    .DATA_WIDTH2(`N_LEN_W)
  ) dense_inner_8_inst (
    .clk(clk),
    .rst_n(rst_n),
    .d1(inner_d1),
    .d2(inner_d2),
    .q(inner_q)
  );

endmodule