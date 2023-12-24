`include "consts_train.vh"

module dense_backward_grad #(
    parameter integer ADDR_WIDTH   = 10,   // log2(`HID_DIM*`CHAR_NUM/DATA_N) < 10
    parameter integer DENSE_DATA_N = 8     // 1 time read, read 8 data.
  ) (
    input  wire clk,
    input  wire rst_n,
    input  wire run,
    input  wire [`N*`HID_DIM*`N_LEN_W-1:0] d_forward,
    input  wire [`N*`CHAR_NUM*`N_LEN_W-1:0] d_backward,
    output wire valid,
    output wire [ADDR_WIDTH-1:0] waddr,
    output wire [DENSE_DATA_N*`N_LEN-1:0] wdata,
    output wire [ADDR_WIDTH-1:0] raddr,
    input  wire [DENSE_DATA_N*`N_LEN-1:0] rdata
  );


  // ----------------------------------------
  genvar i, j;
  integer k;

  // wire input buffer
  wire [`N*`N_LEN_W-1:0] d_forward_buf_t [0:`HID_DIM-1];
  wire [`N*`N_LEN_W-1:0] d_backward_buf_t [0:`CHAR_NUM-1];
  wire [`N*`N_LEN_W-1:0] d_backward_buf_t_split [0:`CHAR_NUM/DENSE_DATA_N-1][0:DENSE_DATA_N-1];

  // reg/wire wdata/rdata buffer
  reg  [`N_LEN-1:0] wdata_buf [0:DENSE_DATA_N-1];
  wire [`N_LEN-1:0] rdata_buf [0:DENSE_DATA_N-1];

  // reg counter
  reg  [4:0] count1;
  reg  [4:0] count2;
  reg  [ADDR_WIDTH-1:0] count3, count3_delay [0:5];

  // rdata delay
  reg  [DENSE_DATA_N*`N_LEN-1:0] rdata_delay1, rdata_delay2, rdata_delay3;

  // wire dense_inner_10
  wire [`N_LEN-1:0] inner_q [0:DENSE_DATA_N-1];

  
  // ----------------------------------------
  // assign valid
  assign valid = run & (count3_delay[5] == `HID_DIM*`CHAR_NUM/DENSE_DATA_N - 1);

  // assign addr
  assign waddr = count3_delay[4];
  assign raddr = count3;

  generate
    for (i = 0; i < `N; i = i + 1) begin
      // transpose d_forward
      for (j = 0; j < `HID_DIM; j = j + 1) begin
        assign d_forward_buf_t[j][i*`N_LEN_W +: `N_LEN_W] = d_forward[(i*`HID_DIM+j)*`N_LEN_W +: `N_LEN_W];
      end
      // transpose d_backward
      for (j = 0; j < `CHAR_NUM; j = j + 1) begin
        assign d_backward_buf_t[j][i*`N_LEN_W +: `N_LEN_W] = d_backward[(i*`CHAR_NUM+j)*`N_LEN_W +: `N_LEN_W];
      end
    end

    // split d_backward_buf_t per DENSE_DATA_N
    for (i = 0; i < `CHAR_NUM/DENSE_DATA_N; i = i + 1) begin
      for (j = 0; j < DENSE_DATA_N; j = j + 1) begin
        assign d_backward_buf_t_split[i][j] = d_backward_buf_t[i*DENSE_DATA_N + j];
      end
    end

    // convert shape (DENSE_DATA_N, `N_LEN) <-> (DENSE_DATA_N*`N_LEN)
    for (i = 0; i < DENSE_DATA_N; i = i + 1) begin
      assign wdata[i*`N_LEN +: `N_LEN] = wdata_buf[i];
      assign rdata_buf[i] = rdata_delay3[i*`N_LEN +: `N_LEN];
    end
  endgenerate


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

  // addr count controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      count3 <= 0;
    end else if (run) begin
      if (count3 != `HID_DIM*`CHAR_NUM/DENSE_DATA_N - 1) begin
        count3 <= count3 + 1;
      end 
    end else begin
      count3 <= 0;
    end
  end

  // addr controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      for (k = 0; k < 6; k = k + 1) begin
        count3_delay[k] <= 0;
      end
    end else begin
      count3_delay[0] <= count3;
      for (k = 0; k < 5; k = k + 1) begin
        count3_delay[k+1] <= count3_delay[k];
      end
    end
  end

  // rdata delay
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      rdata_delay1 <= 0;
      rdata_delay2 <= 0;
      rdata_delay3 <= 0;
    end else begin
      rdata_delay1 <= rdata;
      rdata_delay2 <= rdata_delay1;
      rdata_delay3 <= rdata_delay2;
    end
  end


  // wdata_buf controller
  generate
    for (i = 0; i < DENSE_DATA_N; i = i + 1) begin
      always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
          wdata_buf[i] <= 0;
        end else if (run & ~valid) begin
          wdata_buf[i] <= rdata_buf[i] + inner_q[i];
        end
      end
    end
  endgenerate
  

  // ----------------------------------------
  // dense_inner_10
  generate
    for (i = 0; i < DENSE_DATA_N; i = i + 1) begin : inner_10
      dense_inner_10 #(
        .DATA_WIDTH1(`N_LEN_W),
        .DATA_WIDTH2(`N_LEN_W),
        .OUT_WIDTH(`N_LEN)
      ) dense_inner_10_inst (
        .clk(clk),
        .rst_n(rst_n),
        .d1(d_forward_buf_t[count2]),
        .d2(d_backward_buf_t_split[count1][i]),
        .q(inner_q[i])
      );
    end
  endgenerate
  
endmodule