`include "consts_train.vh"

module forward_mix_input_tb ();

  reg  clk;
  reg  rst_n;
  reg  [`STATE_LEN-1:0] state;
  reg  [`MODE_LEN-1:0] mode;
  wire [`N*`EMB_DIM*`N_LEN_W-1:0] d_emb;
  wire [`HID_DIM*`HID_DIM*`N_LEN_W-1:0] d_tanh;
  // reg  [`HID_DIM*`N_LEN-1:0] d_rand;
  // reg  valid_rand;
  wire valid;
  wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] q;

  forward_mix_input forward_mix_input_inst (.*);

  genvar i;
  reg  [`N_LEN_W-1:0] d_emb_mem [0:(2*`BATCH_SIZE)*`N*`EMB_DIM-1];
  reg  [`N_LEN_W-1:0] d_tanh_mem [0:(`BATCH_SIZE+1)*`HID_DIM*`HID_DIM-1];
  reg  [`N_LEN-1:0] q_mem [0:(`BATCH_SIZE+1)*`HID_DIM*`HID_DIM-1];
  wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] q_ans;
  wire correct;

  assign correct = (q == q_ans);

  generate
    for (i = 0; i < `N*`EMB_DIM; i = i + 1) begin
      assign d_emb[i*`N_LEN_W +: `N_LEN_W] = d_emb_mem[i];
    end
    for (i = 0; i < `HID_DIM*`HID_DIM; i = i + 1) begin
      assign d_tanh[i*`N_LEN_W +: `N_LEN_W] = d_tanh_mem[i];
    end
    for (i = 0; i < `HID_DIM*`HID_DIM; i = i + 1) begin
      assign q_ans[i*`N_LEN +: `N_LEN] = q_mem[i];
    end
  endgenerate

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    // 
    //    test case     |         d_emb_mem         |          d_tanh_mem         |         q_mem
    // -----------------+---------------------------+-----------------------------+--------------------------
    // mix1_layer input | emb_layer_forward_out.txt |                             | mix_layer1_forward_in.txt
    // mix2_layer input |                           | tanh_layer1_forward_out.txt | mix_layer2_forward_in.txt
    // mix3_layer input |                           | tanh_layer2_forward_out.txt | mix_layer3_forward_in.txt
    //
    $readmemb("../../data/tb/train/emb_layer/emb_layer_forward_out.txt",    d_emb_mem);
    $readmemb("../../data/tb/train/tanh_layer/tanh_layer2_forward_out.txt", d_tanh_mem);
    $readmemb("../../data/tb/train/mix_layer/mix_layer3_forward_in.txt",    q_mem);
  end

  initial begin
    $dumpvars;
    rst_n=0; state=`F_IDLE; mode=`TRAIN;
    // valid_rand=1;
    // d_rand={`HID_DIM{`N_LEN'hfffc}};
    #10;
    
    rst_n=1; state=`F_EMB; #10;
    #30;
    state=`F_MIX1; #10;
    #30;
    state=`F_MIX2; #10;
    #30;
    state=`F_MIX3; #10;
    #30;
    #30;
    $finish;
  end


endmodule