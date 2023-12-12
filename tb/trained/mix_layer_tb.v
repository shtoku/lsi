`include "consts_trained.vh"

module mix_layer_tb ();

  reg  clk;
  reg  rst_n;
  reg  run;
  reg  [`STATE_LEN-1:0] state;
  wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] d;
  wire valid;
  wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] q;

  mix_layer mix_layer_inst (.*);


  genvar i;

  reg [`N_LEN-1:0] d_mem [0:`HID_DIM*`HID_DIM-1];
  reg [`N_LEN-1:0] q_mem [0:`HID_DIM*`HID_DIM-1];
  wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] q_ans;
  wire correct;

  assign correct = (q == q_ans);

  generate
    for (i = 0; i < `HID_DIM*`HID_DIM; i = i + 1) begin
      assign     d[i*`N_LEN +: `N_LEN] = d_mem[i];
      assign q_ans[i*`N_LEN +: `N_LEN] = q_mem[i];
    end
  endgenerate

  initial begin
    $readmemb("../../data/tb/trained/mix_layer3_in_tb.txt",  d_mem);
    $readmemb("../../data/tb/trained/mix_layer3_out_tb.txt", q_mem);
  end


  initial clk = 0;
  always #5 clk = ~clk;

  //本体
  initial begin
    $dumpvars;
    rst_n=0; run=0; state=`IDLE; #10
    rst_n=1; #10
    state=`MIX3; #10
    run=1; #10
    #1030
    $finish;
  end

endmodule