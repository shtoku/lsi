`include "consts.vh"

module emb_layer_tb ();

  reg  clk;
  reg  rst_n;
  reg  run;
  reg  [`N*`CHAR_LEN-1:0] d;//10*8
  wire valid;
  wire [`N*`EMB_DIM*`N_LEN-1:0] q;//10*24*16

  emb_layer emb_layer_inst (.*);//なにこれ

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    $dumpvars;
    rst_n=0; run=0; d={8'd0, 8'd1, 8'd2, 8'd3, 8'd4, 8'd5, 8'd6, 8'd7, 8'd198, 8'd199}; #10
    rst_n=1; #10
    run=1; #10
    #300
    // run=0; #10
    // d=199; #10
    // run=1; #10
    // #300
    $display("%b\n", q);
    $finish;
  end

endmodule