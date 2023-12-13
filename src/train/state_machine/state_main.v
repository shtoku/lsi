`include "consts_train.vh"

module state_main (
    input  wire clk,
    input  wire rst_n,
    input  wire run,
    input  wire [`MODE_LEN-1:0] mode,
    output reg  [`STATE_LEN-1:0] q
  );

  always @(posedge clk, negedge rst_n) begin
    if (~rst_n)
      q <= `M_IDLE;
    else if (run) begin
      if (mode == `TRAIN) begin
        case (q)
          `M_IDLE  : q <= `M_S1;
          `M_S1    : q <= `M_S2;
          `M_S2    : q <= `M_S3;
          `M_S3    : q <= `M_UPDATE;
          `M_UPDATE: q <= `M_FIN;
          `M_FIN   : q <= `M_IDLE;
          default  : q <= `STATE_LEN'bX;
        endcase
      end else begin
        case (q)
          `M_IDLE  : q <= `M_S1;
          `M_S1    : q <= `M_FIN;
          `M_FIN   : q <= `M_FIN;
          default  : q <= `STATE_LEN'bX; 
        endcase
      end
    end
  end
  
endmodule