`include "consts_trained.vh"

module comparator_2 (
    input  wire clk,
    input  wire rst_n,
    input  wire run,
    input  wire [`CHAR_LEN-1:0] num1,
    input  wire [`CHAR_LEN-1:0] num2,
    input  wire signed [`N_LEN-1:0] d1,
    input  wire signed [`N_LEN-1:0] d2,
    output reg  [`CHAR_LEN-1:0] num,
    output reg  [`N_LEN-1:0] q
  );

  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      num <= `CHAR_LEN'b0;
      q   <= `N_LEN'b0;
    end else if (run) begin  
      if (d2 > d1) begin
        num <= num2;
        q <= d2;
      end else begin
        num <= num1;
        q <= d1;
      end
    end
  end
  
endmodule