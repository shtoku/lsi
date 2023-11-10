module fifo_tb ();
  parameter WIDTH    = 8;
  parameter SIZE     = 32;
  parameter LOG_SIZE = 5;

  reg  clk;
  reg  rst_n;
  reg  [WIDTH-1:0] data_w;
  wire [WIDTH-1:0] data_r;
  reg  we;
  reg  re;
  wire empty;
  wire full;

  fifo fifo_inst (.*);

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    $dumpvars;
    rst_n=0; data_w=8'h10; we=0; re=0; #10
    rst_n=1; we=1; #10
    data_w = 8'h32; #10
    we=0; #10
    re=1; #10
    #10
    $finish;
  end
  

endmodule