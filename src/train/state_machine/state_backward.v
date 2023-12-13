`include "consts_train.vh"

module state_backward (
    input  wire clk,
    input  wire rst_n,
    input  wire run,
    output reg  [`STATE_LEN-1:0] q
  );

  always @(posedge clk, negedge rst_n) begin
    if (~rst_n)
      q <= `B_IDLE;
    else if (run) begin
      case (q)
        `B_IDLE  : q <= `B_SMAX;
        `B_SMAX  : q <= `B_DENS;
        `B_DENS  : q <= `B_TANH3;
        `B_TANH3 : q <= `B_MIX3;
        `B_MIX3  : q <= `B_TANH2;
        `B_TANH2 : q <= `B_MIX2;
        `B_MIX2  : q <= `B_TANH1;
        `B_TANH1 : q <= `B_MIX1;
        `B_MIX1  : q <= `B_EMB;
        `B_EMB   : q <= `B_FIN;
        `B_FIN   : q <= `B_IDLE;
        default  : q <= `STATE_LEN'bX;
      endcase
    end
  end

endmodule