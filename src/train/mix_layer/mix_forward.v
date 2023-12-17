`include "consts_train.vh"

module mix_forward #(
    parameter integer ADDR_WIDTH = 9    // log2(3*`HID_DIM*`HID_DIM/`DATA_N) < 9
  ) (
    input  wire clk, 
    input  wire rst_n, 
    input  wire run,
    input  wire [`STATE_LEN-1:0] state,
    input  wire [`HID_DIM*`N_LEN-1:0] d,
    output wire valid,
    output wire [`HID_DIM*`N_LEN-1:0] q,
    output reg  [ADDR_WIDTH-1:0] raddr_w,
    output reg  [ADDR_WIDTH-1:0] raddr_b,
    input  wire [`DATA_N*`N_LEN_W-1:0] rdata_w,
    input  wire [`N_LEN_W-1:0] rdata_b
  );


  // ----------------------------------------
  // wire mix_forward_logic
  reg  [`DATA_N*`N_LEN-1:0] mix_forward_logic_d;

  // reg counter
  reg  [1:0] count1;
  reg  [7:0] count2, count3;


  // ----------------------------------------
  // function select_d 
  function [`DATA_N*`N_LEN-1:0] select_d;
    input [`HID_DIM*`N_LEN-1:0] data;
    input [1:0] select;
    case (select)
      0: select_d = data[0*`DATA_N*`N_LEN +: `DATA_N*`N_LEN];
      1: select_d = data[1*`DATA_N*`N_LEN +: `DATA_N*`N_LEN];
      2: select_d = data[2*`DATA_N*`N_LEN +: `DATA_N*`N_LEN];
      3: select_d = data[3*`DATA_N*`N_LEN +: `DATA_N*`N_LEN];
    endcase
  endfunction

  // fucntion raddr_w_bias
  function [ADDR_WIDTH-1:0] raddr_w_bias;
    input [`STATE_LEN-1:0] select;
    case (select)
      `F_MIX1 : raddr_w_bias = 0*(`HID_DIM*`HID_DIM/`DATA_N);
      `F_MIX2 : raddr_w_bias = 1*(`HID_DIM*`HID_DIM/`DATA_N);
      `F_MIX3 : raddr_w_bias = 2*(`HID_DIM*`HID_DIM/`DATA_N);
      default : raddr_w_bias = {`STATE_LEN{1'bX}};
    endcase
  endfunction

  // function raddr_b_bias
  function [ADDR_WIDTH-1:0] raddr_b_bias;
    input [`STATE_LEN-1:0] select;
    case (select)
      `F_MIX1 : raddr_b_bias = 0*`HID_DIM;
      `F_MIX2 : raddr_b_bias = 1*`HID_DIM;
      `F_MIX3 : raddr_b_bias = 2*`HID_DIM;
      default : raddr_b_bias = {`STATE_LEN{1'bX}};
    endcase
  endfunction


  // ----------------------------------------
  // data_in_src (mix_forward_logic_d controller)
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      count1 <= 0;
      mix_forward_logic_d <= 0;
    end else if(run) begin
      count1 <= count1 + 1;
      mix_forward_logic_d <= select_d(d, count1);
    end else begin
      count1 <= 0;
      mix_forward_logic_d <= 0;
    end
  end

  // raddr_w controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      raddr_w <= 0;
    end else if(run) begin
      raddr_w <= raddr_w + 1;
    end else begin
      raddr_w <= raddr_w_bias(state);
    end
  end

  // raddr_b controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      count2 <= 0;
      count3 <= 0;
      raddr_b <= 0;
    end else if (run) begin
        count2 <= count2 + 1;
      if (count2 == count3 + 8) begin
        count3 <= count3 + 4;
        raddr_b <= raddr_b + 1;
      end
    end else begin
      count2 <= 0;
      count3 <= 0;
      raddr_b <= raddr_b_bias(state);
    end
  end


  // ----------------------------------------
  // mix_forward_logic
  mix_forward_logic mix_forward_logic_inst (
    .clk(clk),
    .rst_n(rst_n),
    .run(run),
    .valid(valid),
    .d(mix_forward_logic_d),
    .rdata_w(rdata_w),
    .rdata_b(rdata_b),
    .q(q)
  );


endmodule