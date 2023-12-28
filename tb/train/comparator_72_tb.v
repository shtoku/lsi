`include "consts_train.vh"

module comparator_72_tb ();

  reg  clk;
  reg  rst_n;
  reg  run;
  reg  [72*`N_LEN-1:0] d;
  wire valid;
  wire [`CHAR_LEN-1:0] num;
  wire [`N_LEN-1:0] q;

  comparator_72 comp_72_inst (.*);

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    $dumpvars;
    rst_n=0; run=0; d={{35{`N_LEN'h800000}}, `N_LEN'h000001, {36{`N_LEN'h800000}}}; #10
    rst_n=1; #10
    run=1; #10
    #100
    $finish;
  end
  

endmodule