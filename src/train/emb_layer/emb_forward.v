`include "consts_train.vh"

module emb_forward #(
    parameter integer ADDR_WIDTH = 10   // log2(`CHAR_NUM*`EMB_DIM/DATA_N) < 10
  ) (
    input  wire clk,
    input  wire rst_n,
    input  wire run,
    input  wire [`N*`CHAR_LEN-1:0] d,
    output wire valid,
    output wire [`N*`EMB_DIM*`N_LEN_W-1:0] q,
    output reg  [ADDR_WIDTH-1:0] ram_addr,
    input  wire [`DATA_N*`N_LEN_W-1:0] ram_data
  );

  // ----------------------------------------
  genvar i;
  integer j;

  // reg/wire
  wire [`CHAR_LEN-1:0] d_buf [0:`N-1];
  reg  [`DATA_N*`N_LEN_W-1:0] q_buf [0:`N*`EMB_DIM/`DATA_N-1];
  reg  [1:0] count1;
  reg  [4:0] count2;
  reg  [7:0] count3;


  // ----------------------------------------
  generate
    for (i = 0; i < `N; i = i + 1) begin
      // convert shape (`N, `CHAR_LEN) <- (`N*`CHAR_LEN, )
      assign d_buf[i] = d[i*`CHAR_LEN +: `CHAR_LEN];
    end
    for (i = 0; i < `N*`EMB_DIM/`DATA_N; i = i + 1) begin
      // convert shape (`N*`EMB_DIM*`N_LEN_W, ) <- (`N*`EMB_DIM/`DATA_N, `DATA_N*`N_LEN_W)
      assign q[i*`DATA_N*`N_LEN_W +: `DATA_N*`N_LEN_W] = q_buf[i];
    end
  endgenerate

  assign valid = (count3 == `N*`EMB_DIM/`DATA_N + 1);


  // ----------------------------------------
  // ram_addr controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      count1 <= 0;
      count2 <= 0;
      ram_addr <= 0;
    end else if (run & ~(count1 == (`EMB_DIM/`DATA_N) - 1 & count2 == `N)) begin
      if (count1 == (`EMB_DIM/`DATA_N) - 1) begin
        count1 <= 0;
        count2 <= count2 + 1;
        ram_addr <= (`EMB_DIM/`DATA_N) * d_buf[count2];
      end else begin
        count1 <= count1 + 1;
        ram_addr <= ram_addr + 1;
      end
    end else begin
      count1 <= 0;
      count2 <= 1;
      ram_addr <= (`EMB_DIM/`DATA_N) * d_buf[0];
    end
  end

  // output controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      count3 <= 0;
      for (j = 0; j < `N*`EMB_DIM/`DATA_N; j = j + 1) begin
        q_buf[j] <= 0;
      end
    end else if (run & ~valid) begin
      count3 <= count3 + 1;
      if (count3 != 0) begin
        q_buf[count3-1] <= ram_data;
      end
    end else if (run) begin
      count3 <= count3;
    end else begin
      count3 <= 0;
      for (j = 0; j < `N*`EMB_DIM/`DATA_N; j = j + 1) begin
        q_buf[j] <= 0;
      end
    end
  end

  
endmodule