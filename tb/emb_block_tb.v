`include "consts.vh"

module emb_block_tb ();

  reg  clk;
  reg  rst_n;
  reg  run;
  reg  [`CHAR_LEN-1:0] d;//8
  wire valid;
  wire [`EMB_DIM*`N_LEN-1:0] q;//24*16

  emb_block emb_block_inst (.*);//なにこれ

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    $dumpvars;
    rst_n=0; run=0; d=0; #10
    rst_n=1; #10
    run=1; #10
    #300
    run=0; #10
    d=1; #10
    run=1; #10
    #300
    $finish;
  end

endmodule