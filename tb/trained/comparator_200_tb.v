`include "consts_trained.vh"

module comparator_200_tb ();

  reg  clk;
  reg  rst_n;
  reg  run;
  reg  [200*`N_LEN-1:0] d;
  wire valid;
  wire [`CHAR_LEN-1:0] q;

  comparator_200 comp_200_inst (.*);

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    $dumpvars;
    rst_n=0; run=0; d={{99{`N_LEN'h8000}}, `N_LEN'h8001, {100{`N_LEN'h8000}}}; #10
    rst_n=1; #10
    run=1; #10
    #100
    $finish;
  end
  

endmodule