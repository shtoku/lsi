`include "consts_train.vh"

module state_main (
    input  wire clk,
    input  wire rst_n,
    input  wire run,
    input  wire [`MODE_LEN-1:0] mode,
    output reg  [`STATE_LEN-1:0] q
  );

  reg  [7:0] count;

  always @(posedge clk, negedge rst_n) begin
    if (~rst_n)
      q <= `M_IDLE;
    else if (run) begin
      if (mode == `TRAIN) begin
        case (q)
          `M_IDLE  : q <= `M_FF;
          `M_FF    : q <= `M_FB;
          `M_FB    : q <= (count != `BATCH_SIZE) ? `M_FB : `M_LB;
          `M_LB    : q <= `M_UPDATE;
          `M_UPDATE: q <= `M_FIN;
          `M_FIN   : q <= `M_IDLE;
          default  : q <= `STATE_LEN'bX;
        endcase
      end else begin
        case (q)
          `M_IDLE  : q <= `M_FF;
          `M_FF    : q <= (count != `BATCH_SIZE) ? `M_FF : `M_FIN;
          `M_FIN   : q <= `M_IDLE;
          default  : q <= `STATE_LEN'bX; 
        endcase
      end
    end
  end

  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      count <= 0;
    end else if (run) begin
      if (q == `M_FIN)
        count <= 0;
      else
        count <= count + 1;
    end
  end
  
endmodule