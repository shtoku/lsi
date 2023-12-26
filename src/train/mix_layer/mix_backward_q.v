`include "consts_train.vh"

module mix_backward_q #(
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
    input  wire [`DATA_N*`N_LEN_W-1:0] rdata_w
  );


  // ----------------------------------------
  genvar i;

  // wire input buffer
  wire [`DATA_N*`N_LEN-1:0] d_buf [0:`HID_DIM/`DATA_N-1];

  // reg/wire mix_dot
  reg  [`DATA_N*`N_LEN-1:0] mix_dot_d;

  // reg counter
  reg  count1;


  // ----------------------------------------
  // convert shape (`HID_DIM/`DATA_N, `DATA_N*`N_LEN) <- (`HID_DIM*`N_LEN)
  generate
    for (i = 0; i < `HID_DIM/`DATA_N; i = i + 1) begin
      assign d_buf[i]  = d[i*`DATA_N*`N_LEN +: `DATA_N*`N_LEN];
    end
  endgenerate


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


  // ----------------------------------------
  // data_in_src (mix_dot_d controller)
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      count1 <= 0;
      mix_dot_d <= 0;
    end else if (run) begin
      count1 <= count1 + 1;
      mix_dot_d <= d_buf[count1];
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
      raddr_w <= raddr_w_bias(state);
    end
  end


  // ----------------------------------------
  // mix_dot (calculate q)
  mix_dot mix_dot_inst (
    .clk(clk),
    .rst_n(rst_n),
    .run(run),
    .valid(valid),
    .d(mix_dot_d),
    .rdata_w(rdata_w),
    .rdata_b({`N_LEN_W{1'b0}}),
    .q(q)
  ); 

endmodule