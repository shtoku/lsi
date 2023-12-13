`include "consts_train.vh"

module state_forward (
    input  wire clk,
    input  wire rst_n,
    input  wire run,
    input  wire set,
    input  wire [`STATE_LEN-1:0] d,
    output reg  [`STATE_LEN-1:0] q
  );
  
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n)
      q <= `F_IDLE;
    else if (set)
      q <= d;
    else if (run) begin
      case (q)
        `F_IDLE  : q <= `F_RECV;
        `F_RECV  : q <= `F_EMB;
        `F_EMB   : q <= `F_MIX1;
        `F_MIX1  : q <= `F_TANH1;
        `F_TANH1 : q <= `F_MIX2;
        `F_MIX2  : q <= `F_TANH2;
        `F_TANH2 : q <= `F_MIX3;
        `F_MIX3  : q <= `F_TANH3;
        `F_TANH3 : q <= `F_DENS;
        `F_DENS  : q <= `F_COMP;
        `F_COMP  : q <= `F_SEND;
        `F_SEND  : q <= `F_FIN;
        `F_FIN   : q <= `F_IDLE;
        default  : q <= `STATE_LEN'bX;
      endcase
    end
  end


endmodule