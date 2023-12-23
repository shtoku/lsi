`include "consts_train.vh"

module backward_tanh_input_tb ();

  reg  clk;
  reg  rst_n;
  reg  run;
  reg  [`STATE_LEN-1:0] state;
  wire [`N*`HID_DIM*`N_LEN-1:0] d_dense;
  wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] d_mix;
  wire valid;
  wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] q;

  backward_tanh_input backward_tanh_input_inst (.*);

  genvar i;
  reg  [`N_LEN-1:0] d_dense_mem [0:`BATCH_SIZE*`N*`HID_DIM-1];
  reg  [`N_LEN-1:0] d_mix_mem [0:`BATCH_SIZE*`HID_DIM*`HID_DIM-1];
  reg  [`N_LEN-1:0] q_mem [0:`BATCH_SIZE*`HID_DIM*`HID_DIM-1];
  wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] q_ans;
  wire correct;

  assign correct = (q == q_ans);

  generate
    for (i = 0; i < `N*`HID_DIM; i = i + 1) begin
      assign d_dense[i*`N_LEN +: `N_LEN] = d_dense_mem[i];
    end
    for (i = 0; i < `HID_DIM*`HID_DIM; i = i + 1) begin
      assign d_mix[i*`N_LEN +: `N_LEN] = d_mix_mem[i];
    end
    for (i = 0; i < `HID_DIM*`HID_DIM; i = i + 1) begin
      assign q_ans[i*`N_LEN +: `N_LEN] = q_mem[i];
    end
  endgenerate

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    // 
    //     test case     |          d_dense_mem         |          d_mix_mem          |         q_mem
    // ------------------+------------------------------+-----------------------------+--------------------------
    // tanh3_layer input | dense_layer_backward_out.txt |                             | tanh_layer3_backward_in.txt
    // tanh2_layer input |                              | mix_layer3_backward_out.txt | tanh_layer2_backward_in.txt
    // tanh1_layer input |                              | mix_layer2_backward_out.txt | tanh_layer1_backward_in.txt
    //
    $readmemb("../../data/tb/train/dense_layer/dense_layer_backward_out.txt", d_dense_mem);
    $readmemb("../../data/tb/train/mix_layer/mix_layer2_backward_out.txt",    d_mix_mem);
    $readmemb("../../data/tb/train/tanh_layer/tanh_layer1_backward_in.txt",   q_mem);
  end

  initial begin
    $dumpvars;
    rst_n=0; run=0; state=`B_IDLE;
    #10;
    
    rst_n=1; run=1; state=`B_DENS; #10;
    run=0; #10;
    #30;
    run=1; state=`B_TANH3; #10;
    run=0; #10;
    #30;
    run=1; state=`B_TANH2; #150;
    run=0; #10;
    #30;
    run=1; state=`B_TANH1; #10;
    run=0; #10;
    #30;
    #30;
    $finish;
  end


endmodule