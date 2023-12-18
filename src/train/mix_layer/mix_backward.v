`include "consts_train.vh"

module mix_backward #(
    parameter integer ADDR_WIDTH = 9    // log2(3*`HID_DIM*`HID_DIM/`DATA_N) < 9
  ) (
    input  wire clk,
    input  wire rst_n,
    input  wire run,
    input  wire [`STATE_LEN-1:0] state,
    input  wire [`HID_DIM*`N_LEN-1:0] d_forward,
    input  wire [`HID_DIM*`N_LEN-1:0] d_backward,
    output wire valid,
    output wire [`HID_DIM*`N_LEN-1:0] q,
    output reg  [ADDR_WIDTH-1:0] waddr_grad,
    output wire [`DATA_N*`N_LEN_W-1:0] wdata_grad,
    output reg  [ADDR_WIDTH-1:0] raddr_w,
    output reg  [ADDR_WIDTH-1:0] raddr_grad,
    input  wire [`DATA_N*`N_LEN_W-1:0] rdata_w,
    input  wire [`DATA_N*`N_LEN_W-1:0] rdata_grad
  );


  // ----------------------------------------
  // reg/wire mix_dot
  reg  [`DATA_N*`N_LEN-1:0] mix_dot_d;
  wire mix_dot_valid;

  // reg counter
  reg  [1:0] count1;


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

  // fucntion raddr_bias
  function [ADDR_WIDTH-1:0] raddr_bias;
    input [`STATE_LEN-1:0] select;
    case (select)
      `B_MIX1 : raddr_bias = 0*(`HID_DIM*`HID_DIM/`DATA_N);
      `B_MIX2 : raddr_bias = 1*(`HID_DIM*`HID_DIM/`DATA_N);
      `B_MIX3 : raddr_bias = 2*(`HID_DIM*`HID_DIM/`DATA_N);
      default : raddr_bias = {`STATE_LEN{1'bX}};
    endcase
  endfunction


  // ----------------------------------------
  // data_in_src (mix_dot_d controller)
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      count1 <= 0;
      mix_dot_d <= 0;
    end else if (run) begin
      count1 <= count1 + 1;
      mix_dot_d <= select_d(d_backward, count1);
    end else begin
      count1 <= 0;
      mix_dot_d <= 0;
    end
  end

  // raddr_w controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      raddr_w <= 0;
    end else if (run) begin
      raddr_w <= raddr_w + 1;
    end else begin
      raddr_w <= raddr_bias(state);
    end
  end


  // ----------------------------------------
  // mix_dot (calculate q)
  mix_dot mix_dot_inst (
    .clk(clk),
    .rst_n(rst_n),
    .run(run),
    .valid(mix_dot_valid),
    .d(mix_dot_d),
    .rdata_w(rdata_w),
    .rdata_b({`N_LEN_W{1'b0}}),
    .q(q)
  ); 


endmodule