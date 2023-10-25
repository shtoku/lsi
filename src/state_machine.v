`include "consts.vh"

module state_machine (
    input  wire clk,
    input  wire rst_n,
    input  wire run,
    input  wire set,
    input  wire [`STATE_LEN-1:0] d,
    output reg  [`STATE_LEN-1:0] q
  );
  
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n)
      q <= `IDLE;
    else if (set)
      q <= d;
    else if (run) begin
      case (q)
        `IDLE  : q <= `RECV;
        `RECV  : q <= `EMB;
        `EMB   : q <= `MIX1;
        `MIX1  : q <= `MIX2;
        `MIX2  : q <= `MIX3;
        `MIX3  : q <= `DENS;
        `DENS  : q <= `COMP;
        `COMP  : q <= `SEND;
        `SEND  : q <= `IDLE;
        default: q <= `STATE_LEN'bX;
      endcase
    end
  end


endmodule