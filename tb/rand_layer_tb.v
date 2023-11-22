`include "consts.vh"

module rand_layer_tb ();

  reg  clk;
  reg  rst_n;
  reg  run;
  wire valid;
  wire [`HID_DIM*`N_LEN-1:0] q;

  rand_layer rand_layer_inst (.*);

  genvar i;
  reg  [`N_LEN-1:0] q_mem [0:`HID_DIM-1];
  wire [`HID_DIM*`N_LEN-1:0] q_ans;
  wire correct;

  assign correct = (q == q_ans);

  generate
    for (i = 0; i < `HID_DIM; i = i + 1) begin
      assign q_ans[i*`N_LEN +: `N_LEN] = q_mem[i];
    end
  endgenerate

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    $readmemb("../data/tb/rand_layer_out_tb.txt", q_mem);
  end

  initial begin
    $dumpvars;
    rst_n=0; run=0; #10
    rst_n=1; run=1; #10
    #300
    // run=0; #10
    // #50
    // run=1; #10
    // #300
    $finish;
  end

endmodule  