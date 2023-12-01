`include "consts.vh"

module mix_input_controller_tb ();

  reg  clk;
  reg  rst_n;
  reg  [`STATE_LEN-1:0] state;
  reg  [`MODE_LEN-1:0] mode;
  wire [`N*`EMB_DIM*`N_LEN-1:0] d_emb;
  wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] d_mix;
  reg  [`HID_DIM*`N_LEN-1:0] d_rand;
  reg  valid_emb;
  reg  valid_mix;
  reg  valid_rand;
  wire valid;
  wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] q;

  mix_input_controller mix_in_controller_inst (.*);

  genvar i;
  reg  [`N_LEN-1:0] d_emb_mem [0:`N*`EMB_DIM-1];
  reg  [`N_LEN-1:0] d_mix_mem [0:`HID_DIM*`HID_DIM-1];
  reg  [`N_LEN-1:0] q_mem [0:`HID_DIM*`HID_DIM-1];
  wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] q_ans;
  wire correct;

  assign correct = (q == q_ans);

  generate
    for (i = 0; i < `N*`EMB_DIM; i = i + 1) begin
      assign d_emb[i*`N_LEN +: `N_LEN] = d_emb_mem[i];
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
    //    test case     |       d_emb_mem      |       d_mix_mem       |       q_mem
    // -----------------+----------------------+-----------------------+---------------------
    // mix1_layer input | emb_layer_out_tb.txt |                       | mix_layer1_in_tb.txt
    // mix2_layer input |                      | mix_layer1_out_tb.txt | mix_layer2_in_tb.txt
    // mix3_layer input |                      | mix_layer2_out_tb.txt | mix_layer3_in_tb.txt
    //
    $readmemb("../data/tb/emb_layer_out_tb.txt",  d_emb_mem);
    $readmemb("../data/tb/mix_layer2_out_tb.txt", d_mix_mem);
    $readmemb("../data/tb/mix_layer3_in_tb.txt",  q_mem);
  end

  initial begin
    $dumpvars;
    rst_n=0; state=`IDLE; mode=`GEN_SIMI;
    valid_emb=0; valid_mix=0; valid_rand=1;
    d_rand={`HID_DIM{`N_LEN'hfffc}}; #6
    
    rst_n=1; state=`EMB; #10
    #30
    valid_emb=1; #10
    state=`MIX1; valid_emb=0; #10
    #30
    valid_mix=1; #10
    state=`MIX2; valid_mix=0; #10
    #30
    valid_mix=1; #10
    state=`MIX3; valid_mix=0; #10
    #30
    valid_mix=1; #10
    state=`DENS; valid_mix=0; #10
    #30
    $finish;
  end


endmodule