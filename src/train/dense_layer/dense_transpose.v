`include "consts_train.vh"

module dense_transpose #(
    parameter integer ADDR_WIDTH   = 10,   // log2(`HID_DIM*`CHAR_NUM/DATA_N) < 10
    parameter integer DENSE_DATA_N = 8     // 1 time read, read 8 data.
  ) (
    input  wire clk,
    input  wire rst_n,
    input  wire run,
    output wire valid,
    output reg  [ADDR_WIDTH-1:0] waddr,
    output wire [DENSE_DATA_N*`N_LEN-1:0] wdata,
    output reg  [ADDR_WIDTH-1:0] raddr,
    input  wire [DENSE_DATA_N*`N_LEN-1:0] rdata
  );


  // ----------------------------------------
  genvar i, j;
  integer k;

  // reg counter
  reg  [4:0] count1;
  reg  [4:0] count2;
  reg  [2:0] count3, count3_delay1, count3_delay2;
  reg  [2:0] count4, count4_delay [0:DENSE_DATA_N];
  reg  [1:0] count5;

  // reg/wire input/output buffer
  reg  [DENSE_DATA_N*`N_LEN-1:0] rdata_buf   [0:DENSE_DATA_N-1];
  wire [DENSE_DATA_N*`N_LEN-1:0] rdata_buf_t [0:DENSE_DATA_N-1];
  reg  [DENSE_DATA_N*`N_LEN-1:0] wdata_buf   [0:DENSE_DATA_N-1];

  // waddr controller
  reg  [ADDR_WIDTH-1:0] waddr_buf;
  reg  [ADDR_WIDTH-1:0] waddr_buf_delay [0:DENSE_DATA_N];
  reg  [ADDR_WIDTH-1:0] waddr_delay;

  // wdata index
  reg  [2:0] wdata_index;


  // ----------------------------------------
  generate
    for (i = 0; i < DENSE_DATA_N; i = i + 1) begin
      for (j = 0; j < DENSE_DATA_N; j = j + 1) begin
        assign rdata_buf_t[i][j*`N_LEN +: `N_LEN] = rdata_buf[j][i*`N_LEN +: `N_LEN];
      end
      assign wdata = wdata_buf[wdata_index];
    end
  endgenerate

  // assign valid
  assign valid = run & (waddr_delay == `HID_DIM*`CHAR_NUM/DENSE_DATA_N  - 1);


  // ----------------------------------------
  // raddr controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      count1 <= 0;
      count2 <= 0;
      raddr <= 0;
    end else if (run) begin
      if (raddr == `HID_DIM*`CHAR_NUM/DENSE_DATA_N  - 1) begin
        count1 <= count1;
        count2 <= count2;
        raddr <= raddr;
      end else if (count1 == `HID_DIM - 1) begin
        count1 <= 0;
        count2 <= count2 + 1;
        raddr  <= count2 + 1;
      end else begin
        count1 <= count1 + 1;
        count2 <= count2;
        raddr <= raddr + `CHAR_NUM/DENSE_DATA_N;
      end
    end else begin
      count1 <= 0;
      count2 <= 0;
      raddr <= 0;
    end
  end

  // restore rdata index controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      count3 <= 0;
      count3_delay1 <= 0;
      count3_delay2 <= 0;
    end else if (run) begin
      if (raddr != `HID_DIM*`CHAR_NUM/DENSE_DATA_N  - 1) begin
        if (count3 == DENSE_DATA_N - 1) begin
          count3 <= 0;
        end else begin
          count3 <= count3 + 1;
        end
      end
      count3_delay1 <= count3;
      count3_delay2 <= count3_delay1;
    end else begin
      count3 <= 0;
      count3_delay1 <= count3;
      count3_delay2 <= count3_delay1;
    end
  end

  // rdata controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      for (k = 0; k < DENSE_DATA_N; k = k + 1) begin
        rdata_buf[k] <= 0;
      end
    end else begin
      rdata_buf[count3_delay1] <= rdata;
    end
  end

  // waddr controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      count4 <= 0;
      count5 <= 0;
      waddr_buf <= 0;
    end else if (run) begin
      if (waddr_buf != `HID_DIM*`CHAR_NUM/DENSE_DATA_N  - 1) begin
        if ((count4 == DENSE_DATA_N - 1) & (count5 == `HID_DIM/DENSE_DATA_N - 1)) begin
          count4 <= 0;
          count5 <= 0;
          waddr_buf <= waddr_buf + 1;
        end else if (count4 == DENSE_DATA_N - 1) begin
          count4 <= 0;
          count5 <= count5 + 1;
          waddr_buf <= waddr_buf - (`HID_DIM - `HID_DIM/DENSE_DATA_N - 1);
        end else begin
          count4 <= count4 + 1;
          count5 <= count5;
          waddr_buf <= waddr_buf + `HID_DIM/DENSE_DATA_N;
        end
      end
    end else begin
      count4 <= 0;
      count5 <= 0;
      waddr_buf <= 0;
    end
  end

  // wdata_index controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      for (k = 0; k < DENSE_DATA_N + 1; k = k + 1) begin
        count4_delay[k] <= 0;
      end
      wdata_index <= 0;
    end else begin
      count4_delay[0] <= count4;
      for (k = 0; k < DENSE_DATA_N; k = k + 1) begin
        count4_delay[k+1] <= count4_delay[k];
      end
      wdata_index <= count4_delay[DENSE_DATA_N];
    end
  end

  // waddr_buf delay
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      for (k = 0; k < DENSE_DATA_N + 1; k = k + 1) begin
        waddr_buf_delay[k] <= 0;
      end
      waddr <= 0;
      waddr_delay <= 0;
    end else begin
      waddr_buf_delay[0] <= waddr_buf;
      for (k = 0; k < DENSE_DATA_N; k = k + 1) begin
        waddr_buf_delay[k+1] <= waddr_buf_delay[k];
      end
      waddr <= waddr_buf_delay[DENSE_DATA_N];
      waddr_delay <= waddr;
    end
  end

  // wdata_buf controller
  generate
    for (i = 0; i < DENSE_DATA_N; i = i + 1) begin
      always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            wdata_buf[i] <= 0;
        end else if (count4_delay[DENSE_DATA_N] == 0) begin
            wdata_buf[i] <= rdata_buf_t[i];
        end
      end
    end
  endgenerate
  
endmodule