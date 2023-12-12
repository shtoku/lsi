module xorshift_tb ();

  parameter integer WIDTH = 32;
  parameter integer SEED  = 32'd5671;

  reg  clk;
  reg  rst_n;
  reg  run;
  wire [WIDTH-1:0] q;
  
  xorshift xorshift_inst (.*);

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    $dumpvars;
    rst_n=0; run=0; #10
    rst_n=1; run=1; #10
    #100
    $finish;
  end

endmodule