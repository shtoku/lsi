`include "consts_train.vh"

module emb_backward #(
    parameter integer ADDR_WIDTH = 10   // log2(`CHAR_NUM*`EMB_DIM/DATA_N) < 10
  ) (
    input  wire clk,
    input  wire rst_n,
    input  wire run,
    input  wire [`N*`CHAR_LEN-1:0] d_forward,
    input  wire [`N*`EMB_DIM*`N_LEN-1:0] d_backward,
    output wire valid,
    output reg  [ADDR_WIDTH-1:0] waddr,
    output wire [`DATA_N*`N_LEN_W-1:0] wdata,
    output reg  [ADDR_WIDTH-1:0] raddr,
    input  wire [`DATA_N*`N_LEN_W-1:0] rdata
  );


  // ----------------------------------------
  genvar i;

  // wire input buffer
  wire [`CHAR_LEN-1:0] d_forward_buf  [0:`N-1];
  wire [`DATA_N*`N_LEN-1:0] d_backward_buf [0:`N*`EMB_DIM/`DATA_N-1];

  // reg/wire rdata/wdata buffer
  wire [`N_LEN_W-1:0] rdata_buf [0:`DATA_N-1];
  reg  [`N_LEN_W-1:0] wdata_buf [0:`DATA_N-1];

  // reg raddr controller
  reg  count0;
  reg  [1:0] count1;
  reg  [4:0] count2;

  // reg waddr controller
  reg  [ADDR_WIDTH-1:0] raddr_delay;

  // reg for valid
  reg  [7:0] count3, count3_delay1, count3_delay2, count3_delay3;


  // ----------------------------------------
  generate
    // convert shape (`N, `CHAR_LEN) <- (`N*`CHAR_LEN,)
    for (i = 0; i < `N; i = i + 1) begin
      assign d_forward_buf[i] = d_forward[i*`CHAR_LEN +: `CHAR_LEN];
    end
    // convert shape (`N*`EMB_DIM/`DATA_N, `DATA_N*`N_LEN) <- (`N*`EMB_DIM*`N_LEN,)
    for (i = 0; i < `N*`EMB_DIM/`DATA_N; i = i + 1) begin
      assign d_backward_buf[i] = d_backward[i*`DATA_N*`N_LEN +: `DATA_N*`N_LEN];
    end
    // covert shape (`DATA_N, `N_LEN_W) <-> (`DATA_N*`N_LEN_W,)
    for (i = 0; i < `DATA_N; i = i + 1) begin
      assign rdata_buf[i] = rdata[i*`N_LEN_W +: `N_LEN_W];
      assign wdata[i*`N_LEN_W +: `N_LEN_W] = wdata_buf[i];
    end
  endgenerate

  // assign valid
  assign valid = run & (count3_delay3 == `N*`EMB_DIM/`DATA_N - 1);


  // ----------------------------------------
  // main counter
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      count0 <= 0;
      count1 <= 0;
      count2 <= 0;
      raddr <= 0;
    end else if (run) begin
      count0 <= ~count0;
      if (count0 & ~(count1 == (`EMB_DIM/`DATA_N) - 1 & count2 == `N)) begin
        if (count1 == (`EMB_DIM/`DATA_N) - 1) begin
          count1 <= 0;
          count2 <= count2 + 1;
          raddr <= (`EMB_DIM/`DATA_N) * d_forward_buf[count2 + 1];
        end else begin
          count1 <= count1 + 1;
          raddr <= raddr + 1;
        end
      end
    end else begin
      count0 <= 0;
      count1 <= 0;
      count2 <= 0;
      raddr <= (`EMB_DIM/`DATA_N) * d_forward_buf[0];
    end
  end

  // waddr controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      raddr_delay <= 0;
      waddr <= 0;
    end else if (run) begin
      raddr_delay <= raddr;
      waddr <= raddr_delay;
    end else begin
      raddr_delay <= (`EMB_DIM/`DATA_N) * d_forward_buf[0];
      waddr <= (`EMB_DIM/`DATA_N) * d_forward_buf[0];
    end
  end 

  // count3 controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      count3 <= 0;
    end else if (count0 & count3 != `N*`EMB_DIM/`DATA_N - 1) begin
      count3 <= count3 + 1;
    end else if (run) begin
      count3 <= count3;
    end else begin
      count3 <= 0;
    end
  end

  // count3 delay
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      count3_delay1 <= 0;
      count3_delay2 <= 0;
      count3_delay3 <= 0;
    end else begin
      count3_delay1 <= count3;
      count3_delay2 <= count3_delay1;
      count3_delay3 <= count3_delay2;
    end
  end

  // wdata controller
  generate
    for (i = 0; i < `DATA_N; i = i + 1) begin
      always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
          wdata_buf[i] <= 0;
        end else if (run & ~valid) begin
          wdata_buf[i] <= rdata_buf[i] + d_backward_buf[count3_delay1][i*`N_LEN +: `N_LEN_W];
        end
      end
    end
  endgenerate

  
endmodule