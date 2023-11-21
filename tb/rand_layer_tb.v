`include "consts.vh"

module rand_layer_tb ();

  reg  clk;
  reg  rst_n;
  reg  run;
  wire valid;
  wire [`HID_DIM*`N_LEN-1:0] q;

  rand_layer rand_layer_inst (.*);

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    $dumpvars;
    rst_n=0; run=0; #10
    rst_n=1; run=1; #10
    #300
    run=0; #10
    #50
    run=1; #10
    #300
    $finish;
  end

endmodule  