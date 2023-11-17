`include "consts.vh"

module emb_layer_tb ();

  reg  clk;
  reg  rst_n;
  reg  run;
  wire [`N*`CHAR_LEN-1:0] d;//10*8
  wire valid;
  wire [`N*`EMB_DIM*`N_LEN-1:0] q;

  emb_layer emb_layer_inst (.*);

  genvar i;
  reg  [`CHAR_LEN-1:0] d_mem [0:`N-1];//8bitの数字が10行
  reg  [`N_LEN-1:0] q_mem [0:`N*`EMB_DIM-1];//16bitの数字が24*10行
  wire [`N*`EMB_DIM*`N_LEN-1:0] q_ans;
  wire correct;

  assign correct = (q == q_ans);

  generate
    for (i = 0; i < `N; i = i + 1) begin
      assign d[i*`CHAR_LEN +: `CHAR_LEN] = d_mem[i];
    end
    for (i = 0; i < `N*`EMB_DIM; i = i + 1) begin
      assign q_ans[i*`N_LEN +: `N_LEN] = q_mem[i];
    end
  endgenerate

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    $readmemb("../data/tb/emb_layer_in_tb.txt", d_mem);
    $readmemb("../data/tb/emb_layer_out_tb.txt", q_mem);
  end

  initial begin
    $dumpvars;
    rst_n=0; run=0; #10
    rst_n=1; #10
    run=1; #10
    #300
    $finish;
  end

endmodule  