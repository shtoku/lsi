`include "consts_train.vh"

module mix_optim_b #(
    parameter integer ADDR_WIDTH = 9    // log2(3*`HID_DIM*`HID_DIM/`DATA_N) < 9
  ) (
    input  wire clk,
    input  wire rst_n,
    input  wire run,
    input  wire [`STATE_LEN-1:0] state,
    output wire valid,
    output reg  [ADDR_WIDTH-1:0] waddr,
    output reg  [`N_LEN_W-1:0] wdata_b,
    output reg  [`N_LEN_W-1:0] wdata_v,
    output reg  [ADDR_WIDTH-1:0] raddr,
    input  wire [`N_LEN_W-1:0] rdata_b,
    input  wire [`N_LEN_W-1:0] rdata_v,
    input  wire [`N_LEN_W-1:0] rdata_grad
  );


  // ----------------------------------------
  genvar i;

  // reg rdata buffer
  reg  [`N_LEN_W-1:0] rdata_b_delay;

  // reg multiply momentum, lr buffer
  reg  [`N_LEN_W-1:0] mul_mtm_buf;
  reg  [`N_LEN_W-1:0] mul_lr_buf;

  // reg raddr controller
  reg  [6:0] count1, count1_delay1, count1_delay2, count1_delay3, count1_delay4;

  // reg waddr controller
  reg  [ADDR_WIDTH-1:0] raddr_delay1, raddr_delay2;


  // ----------------------------------------
  // assign valid
  assign valid = run & (count1_delay4 == `HID_DIM - 1);


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
      if (count1 != `HID_DIM - 1) begin
        count1 <= count1 + 1;
        raddr <= raddr + 1;
      end
    end else begin
      count1 <= 0;
      raddr <= raddr_b_bias(state);
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

  // rdata_b delay
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      rdata_b_delay <= 0;
    end else begin
      rdata_b_delay <= rdata_b;
    end
  end    

  // calculate momentum*rdata_v and lr*rdata_v
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      mul_mtm_buf <= 0;
      mul_lr_buf <= 0;
    end else begin
      mul_mtm_buf <= fixed_mul(`MOMENTUM, rdata_v);
      mul_lr_buf <= fixed_mul(`LR, rdata_grad);
    end
  end

  // calculate rdata_b + momentum*rdata_v - lr*rdata_v
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      wdata_b <= 0;
      wdata_v <= 0;
    end else begin
      wdata_b <= rdata_b_delay + mul_mtm_buf - mul_lr_buf;
      wdata_v <= mul_mtm_buf - mul_lr_buf;
    end
  end

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