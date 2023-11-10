`include "consts.vh"

module comp_layer_tb ();

  reg  clk;
  reg  rst_n;
  reg  run;
  wire [`N*`CHAR_NUM*`N_LEN-1:0] d;
  wire valid;
  wire [`N*`CHAR_LEN-1:0] q;

  comp_layer comp_layer_inst (.*);

  genvar i;
  reg  [`N_LEN-1:0] d_mem [0:`N*`CHAR_NUM-1];
  reg  [`CHAR_LEN-1:0] q_mem [0:`N-1];
  wire [`N*`CHAR_LEN-1:0] q_ans;
  wire correct;

  assign correct = (q == q_ans);

  generate
    for (i = 0; i < `N*`CHAR_NUM; i = i + 1) begin
      assign d[i*`N_LEN +: `N_LEN] = d_mem[i];
    end
    for (i = 0; i < `N; i = i + 1) begin
      assign q_ans[i*`CHAR_LEN +: `CHAR_LEN] = q_mem[i];
    end
  endgenerate

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    $readmemb("../data/tb/comp_layer_in_tb.txt", d_mem);
    $readmemb("../data/tb/comp_layer_out_tb.txt", q_mem);
  end

  initial begin
    $dumpvars;
    rst_n=0; run=0; #10
    rst_n=1; #10
    run=1; #10
    #100
    $finish;
  end

endmodule  