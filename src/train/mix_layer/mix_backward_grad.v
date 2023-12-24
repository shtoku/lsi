`include "consts_train.vh"

module mix_backward_grad #(
    parameter integer ADDR_WIDTH = 9    // log2(3*`HID_DIM*`HID_DIM/`DATA_N) < 9
  ) (
    input  wire clk,
    input  wire rst_n,
    input  wire run,
    input  wire [`STATE_LEN-1:0] state,
    input  wire [`HID_DIM*`N_LEN-1:0] d_forward,
    input  wire [`HID_DIM*`N_LEN-1:0] d_backward,
    output wire valid,
    output reg  [ADDR_WIDTH-1:0] waddr_grad_w,
    output reg  [ADDR_WIDTH-1:0] waddr_grad_b,
    output wire [`DATA_N*`N_LEN_W-1:0] wdata_grad_w,
    output reg  [`N_LEN_W-1:0]         wdata_grad_b,
    output reg  [ADDR_WIDTH-1:0] raddr_grad_w,
    output reg  [ADDR_WIDTH-1:0] raddr_grad_b,
    input  wire [`DATA_N*`N_LEN_W-1:0] rdata_grad_w,
    input  wire [`N_LEN_W-1:0]         rdata_grad_b
  );


  // ----------------------------------------
  genvar i;

  // wire input buffer
  wire [`N_LEN-1:0] d_forward_buf   [0:`HID_DIM-1];
  wire [`N_LEN-1:0] d_backward_buf1 [0:`HID_DIM-1];
  wire [`DATA_N*`N_LEN-1:0] d_backward_buf2 [0:`HID_DIM/`DATA_N-1];

  // reg/wire rdata/wdata buffer
  wire [`N_LEN_W-1:0] rdata_grad_w_buf [0:`DATA_N-1];
  reg  [`N_LEN_W-1:0] wdata_grad_w_buf [0:`DATA_N-1];

  // reg waddr controller
  reg  [ADDR_WIDTH-1:0] raddr_grad_w_delay, raddr_grad_b_delay;

  // reg counter
  reg  [6:0] count1, count1_delay1, count1_delay2, count1_delay3;
  reg  [4:0] count2, count2_delay1, count2_delay2;
  reg  [1:0] count3;
  reg  [4:0] count4;

  // grad_w (d_forward.T, d_backward)
  reg  [`N_LEN-1:0] mul [0:`DATA_N-1];


  // ----------------------------------------
  generate
    // convert shape (`HID_DIM, `N_LEN) <- (`HID_DIM*`N_LEN)
    for (i = 0; i < `HID_DIM; i = i + 1) begin
      assign d_forward_buf[i]   = d_forward[i*`N_LEN +: `N_LEN];
      assign d_backward_buf1[i] = d_backward[i*`N_LEN +: `N_LEN];
    end
    // convert shape (`HID_DIM/`DATA_N, `DATA_N*`N_LEN) <- (`HID_DIM*`N_LEN)
    for (i = 0; i < `HID_DIM/`DATA_N; i = i + 1) begin
      assign d_backward_buf2[i]  = d_backward[i*`DATA_N*`N_LEN +: `DATA_N*`N_LEN];
    end
    // covert shape (`DATA_N, `N_LEN_W) <-> (`DATA_N*`N_LEN_W,)
    for (i = 0; i < `DATA_N; i = i + 1) begin
      assign rdata_grad_w_buf[i] = rdata_grad_w[i*`N_LEN_W +: `N_LEN_W];
      assign wdata_grad_w[i*`N_LEN_W +: `N_LEN_W] = wdata_grad_w_buf[i];
    end
  endgenerate

  // assign valid
  assign valid = run & (count1_delay3 == `HID_DIM*`HID_DIM/`DATA_N - 1);


  // ----------------------------------------
  // fucntion raddr_w_bias
  function [ADDR_WIDTH-1:0] raddr_w_bias;
    input [`STATE_LEN-1:0] select;
    case (select)
      `B_MIX1 : raddr_w_bias = 0*(`HID_DIM*`HID_DIM/`DATA_N);
      `B_MIX2 : raddr_w_bias = 1*(`HID_DIM*`HID_DIM/`DATA_N);
      `B_MIX3 : raddr_w_bias = 2*(`HID_DIM*`HID_DIM/`DATA_N);
      default : raddr_w_bias = {`STATE_LEN{1'bX}};
    endcase
  endfunction

  // function raddr_b_bias
  function [ADDR_WIDTH-1:0] raddr_b_bias;
    input [`STATE_LEN-1:0] select;
    case (select)
      `B_MIX1 : raddr_b_bias = 0*`HID_DIM;
      `B_MIX2 : raddr_b_bias = 1*`HID_DIM;
      `B_MIX3 : raddr_b_bias = 2*`HID_DIM;
      default : raddr_b_bias = {`STATE_LEN{1'bX}};
    endcase
  endfunction

  // fucntion fixed multiply 
  function [`N_LEN-1:0] fixed_mul;
    input signed [`N_LEN-1:0] num1, num2;
    reg [2*`N_LEN-1:0] mul;
    begin
      mul = num1 * num2;
      fixed_mul = mul[`F_LEN +: `N_LEN_W]; 
    end
  endfunction  


  // ----------------------------------------
  // raddr_grad_w controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      count1 <= 0;
      raddr_grad_w <= 0;
    end else if (run) begin
      if (count1 != `HID_DIM*`HID_DIM/`DATA_N - 1) begin
        count1 <= count1 + 1;
        raddr_grad_w <= raddr_grad_w + 1;
      end
    end else begin
      count1 <= 0;
      raddr_grad_w <= raddr_w_bias(state);
    end
  end

  // count1 delay
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      count1_delay1 <= 0;
      count1_delay2 <= 0;
      count1_delay3 <= 0;
    end else begin
      count1_delay1 <= count1;
      count1_delay2 <= count1_delay1;
      count1_delay3 <= count1_delay2;
    end
  end

  // raddr_grad_b controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      count2 <= 0;
      raddr_grad_b <= 0;
    end else if (run) begin
      if (count2 != `HID_DIM - 1) begin
        count2 <= count2 + 1;
        raddr_grad_b <= raddr_grad_b + 1;
      end
    end else begin
      count2 <= 0;
      raddr_grad_b <= raddr_b_bias(state);
    end
  end

  // count2 delay
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      count2_delay1 <= 0;
      count2_delay2 <= 0;
    end else begin
      count2_delay1 <= count2;
      count2_delay2 <= count2_delay1;
    end
  end

  // waddr_grad_w controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      raddr_grad_w_delay <= 0;
      waddr_grad_w <= 0;
    end else if (run) begin
      raddr_grad_w_delay <= raddr_grad_w;
      waddr_grad_w <= raddr_grad_w_delay;
    end else begin
      raddr_grad_w_delay <= raddr_w_bias(state);
      waddr_grad_w <= raddr_w_bias(state);
    end
  end

  // waddr_grad_b controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      raddr_grad_b_delay <= 0;
      waddr_grad_b <= 0;
    end else if (run) begin
      raddr_grad_b_delay <= raddr_grad_b;
      waddr_grad_b <= raddr_grad_b_delay;
    end else begin
      raddr_grad_b_delay <= raddr_b_bias(state);
      waddr_grad_b <= raddr_b_bias(state);
    end
  end 

  // d_forward, d_backward index
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      count3 <= 0;
      count4 <= 0;
    end else if (run) begin
      if ((count3 != `HID_DIM/`DATA_N - 1) | (count4 != `HID_DIM - 1)) begin
        count3 <= count3 + 1;
        if (count3 == `HID_DIM/`DATA_N - 1)
          count4 <= count4 + 1;
      end
    end else begin
      count3 <= 0;
      count4 <= 0;
    end
  end

  // calculate grad_w (d_forward.T, d_backward)
  generate
    for (i = 0; i < `DATA_N; i = i + 1) begin
      always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
          mul[i] <= 0;
        end else begin
          mul[i] <= fixed_mul(d_forward_buf[count4], d_backward_buf2[count3][i*`N_LEN +: `N_LEN]);
        end
      end
    end
  endgenerate

  // wdata_grad_w controller
  generate
    for (i = 0; i < `DATA_N; i = i + 1) begin
      always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
          wdata_grad_w_buf[i] <= 0;
        end else if (run & ~valid) begin
          wdata_grad_w_buf[i] <= rdata_grad_w_buf[i] + mul[i];
        end
      end
    end
  endgenerate

  // wdata_grad_b controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      wdata_grad_b <= 0;
    end else if (count2_delay2 != `HID_DIM - 1) begin
      wdata_grad_b <= rdata_grad_b + d_backward_buf1[count2_delay1];
    end
  end

endmodule