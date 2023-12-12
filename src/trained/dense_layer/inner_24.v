`include "consts_trained.vh"

module inner_24 (
    input wire clk,
    input wire rst_n,
    input wire run,
    input wire [24*`N_LEN - 1:0] d1,//16bitの数字が24個
    input wire [24*`N_LEN - 1:0] d2,
    output reg signed [`N_LEN - 1:0] q
  );

  reg signed [2*`N_LEN - 1:0] mul [0:23];
  reg [`N_LEN - 1:0] add1 [0:7];
  reg [`N_LEN - 1:0] add2 [0:2];

  integer i;

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      for (i = 0; i < 24; i = i + 1) begin//mul[0]~mul[23]の24個
          mul[i] <= 0;
      end
    end
    else if (run) begin
      for (i = 0; i < 24; i = i + 1) begin
          mul[i] <= $signed(d1[i*`N_LEN +: `N_LEN]) * $signed(d2[i*`N_LEN +: `N_LEN]);
      end
    end
  end

  always @(posedge clk, negedge rst_n) begin//データは24個、3個ずつ計算するから8個分用意(0~7)
    if (!rst_n) begin
      for (i = 0; i < 8; i = i + 1) begin
          add1[i] <= 0;
      end
    end
    else if (run) begin
      for (i = 0; i < 8; i = i + 1) begin
          add1[i] <= mul[i*3][`F_LEN +: `N_LEN] + mul[i*3+1][`F_LEN +: `N_LEN] + mul[i*3+2][`F_LEN +: `N_LEN];
      end
    end
  end

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      for (i = 0; i < 3; i = i + 1) begin//mul[0]~mul[23]の24個
          add2[i] <= 0;
      end
    end
    else if (run) begin
      add2[0] <= add1[0] + add1[1] + add1[2];
      add2[1] <= add1[3] + add1[4] + add1[5];
      add2[2] <= add1[6] + add1[7];
    end
  end

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      q <= 0;
    end
    else if (run) begin
      q <= add2[0] + add2[1] + add2[2];
    end
  end
  
endmodule