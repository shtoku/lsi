`include "consts_train.vh"

module mix_optim_w #(
    parameter integer ADDR_WIDTH = 9    // log2(3*`HID_DIM*`HID_DIM/`DATA_N) < 9
  ) (
    input  wire clk,
    input  wire rst_n,
    input  wire run,
    input  wire [`STATE_LEN-1:0] state,
    output wire valid,
    output reg  [ADDR_WIDTH-1:0] waddr,
    output wire [`DATA_N*`N_LEN_W-1:0] wdata_w,
    output wire [`DATA_N*`N_LEN_W-1:0] wdata_v,
    output reg  [ADDR_WIDTH-1:0] raddr,
    input  wire [`DATA_N*`N_LEN_W-1:0] rdata_w,
    input  wire [`DATA_N*`N_LEN_W-1:0] rdata_v,
    input  wire [`DATA_N*`N_LEN_W-1:0] rdata_grad
  );


  // ----------------------------------------
  genvar i;

  // reg/wire rdata/wdata buffer
  wire [`N_LEN_W-1:0] rdata_w_buf [0:`DATA_N-1];
  reg  [`N_LEN_W-1:0] rdata_w_buf_delay [0:`DATA_N-1];
  wire [`N_LEN_W-1:0] rdata_v_buf [0:`DATA_N-1];
  wire [`N_LEN_W-1:0] rdata_grad_buf [0:`DATA_N-1];
  reg  [`N_LEN_W-1:0] wdata_w_buf [0:`DATA_N-1];
  reg  [`N_LEN_W-1:0] wdata_v_buf [0:`DATA_N-1];

  // reg multiply momentum, lr buffer
  reg  [`N_LEN_W-1:0] mul_mtm_buf [0:`DATA_N-1];
  reg  [`N_LEN_W-1:0] mul_lr_buf  [0:`DATA_N-1];

  // reg raddr controller
  reg  [6:0] count1, count1_delay1, count1_delay2, count1_delay3, count1_delay4;

  // reg waddr controller
  reg  [ADDR_WIDTH-1:0] raddr_delay1, raddr_delay2;


  // ----------------------------------------
  generate
    // covert shape (`DATA_N, `N_LEN_W) <-> (`DATA_N*`N_LEN_W,)
    for (i = 0; i < `DATA_N; i = i + 1) begin
      assign rdata_w_buf[i]    = rdata_w[i*`N_LEN_W +: `N_LEN_W];
      assign rdata_v_buf[i]    = rdata_v[i*`N_LEN_W +: `N_LEN_W];
      assign rdata_grad_buf[i] = rdata_grad[i*`N_LEN_W +: `N_LEN_W];
      assign wdata_w[i*`N_LEN_W +: `N_LEN_W] = wdata_w_buf[i];
      assign wdata_v[i*`N_LEN_W +: `N_LEN_W] = wdata_v_buf[i];
    end
  endgenerate

  // assign valid
  assign valid = run & (count1_delay4 == `HID_DIM*`HID_DIM/`DATA_N - 1);


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

  // fucntion fixed multiply 
  function [`N_LEN_W-1:0] fixed_mul;
    input signed [`N_LEN_W-1:0] num1, num2;
    reg [2*`N_LEN_W-1:0] mul;
    begin
      mul = num1 * num2;
      fixed_mul = mul[`F_LEN_W +: `N_LEN_W]; 
    end
  endfunction


  // ----------------------------------------
  // raddr controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      count1 <= 0;
      raddr <= 0;
    end else if (run) begin
      if (count1 != `HID_DIM*`HID_DIM/`DATA_N - 1) begin
        count1 <= count1 + 1;
        raddr <= raddr + 1;
      end
    end else begin
      count1 <= 0;
      raddr <= raddr_w_bias(state);
    end
  end

  // count1 delay
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      count1_delay1 <= 0;
      count1_delay2 <= 0;
      count1_delay3 <= 0;
      count1_delay4 <= 0;
    end else begin
      count1_delay1 <= count1;
      count1_delay2 <= count1_delay1;
      count1_delay3 <= count1_delay2;
      count1_delay4 <= count1_delay3;
    end
  end

  // rdata_w delay
  generate
    for (i = 0; i < `DATA_N; i = i + 1) begin
      always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
          rdata_w_buf_delay[i] <= 0;
        end else begin
          rdata_w_buf_delay[i] <= rdata_w_buf[i];
        end
      end
    end
  endgenerate

  // calculate momentum*rdata_v and lr*rdata_v
  generate
    for (i = 0; i < `DATA_N; i = i + 1) begin
      always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
          mul_mtm_buf[i] <= 0;
          mul_lr_buf[i] <= 0;
        end else begin
          mul_mtm_buf[i] <= fixed_mul(`MOMENTUM, rdata_v_buf[i]);
          mul_lr_buf[i] <= fixed_mul(`LR, rdata_grad_buf[i]);
        end
      end
    end
  endgenerate

  // calculate rdata_w + momentum*rdata_v - lr*rdata_v
  generate
    for (i = 0; i < `DATA_N; i = i + 1) begin
      always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
          wdata_w_buf[i] <= 0;
          wdata_v_buf[i] <= 0;
        end else begin
          wdata_w_buf[i] <= rdata_w_buf_delay[i] + mul_mtm_buf[i] - mul_lr_buf[i];
          wdata_v_buf[i] <= mul_mtm_buf[i] - mul_lr_buf[i];
        end
      end
    end
  endgenerate

  // waddr controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      raddr_delay1 <= 0;
      raddr_delay2 <= 0;
      waddr <= 0;
    end else begin
      raddr_delay1 <= raddr;
      raddr_delay2 <= raddr_delay1;
      waddr <= raddr_delay2;
    end 
  end

endmodule