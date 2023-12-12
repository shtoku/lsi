`include "consts_trained.vh"

module state_machine_tb ();

  reg  clk;
  reg  rst_n;
  reg  run;
  reg  set;
  reg  [`STATE_LEN-1:0] d;
  wire [`STATE_LEN-1:0] q;

  state_machine state_machine_inst (.*);

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    $dumpvars;
    rst_n=0; run=0; set=0; d=`IDLE; #10
    rst_n=1; run=1; #10
    set=1; #10
    run=0; #10
    run=1; #10
    set=0; #10
    #50
    run=0; #10
    run=1; #50
    $finish;
  end


endmodule