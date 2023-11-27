module xorshift #(
    parameter integer WIDTH = 32,
    parameter integer SEED  = 32'd5671
  ) (
    input  wire clk,
    input  wire rst_n,
    input  wire run,
    output reg  [WIDTH-1:0] q
  );

  reg  [WIDTH-1:0] a;
  wire [WIDTH-1:0] b, c, d;
  
  assign b = (a ^ a << 13);
  assign c = (b ^ b >> 17);
  assign d = (c ^ c << 5 );

  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      a <= SEED;
      q <= {WIDTH{1'b0}};
    end else if (run) begin
      a <= d;
      q <= d;
    end
  end

endmodule