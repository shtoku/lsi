`include "consts_train.vh"

module emb_layer_tb ();

  reg  clk;
  reg  rst_n;
  reg  update;
  reg  zero_grad;
  reg  run_forward;
  reg  run_backward;
  reg  load_backward;
  reg  [`N*`CHAR_LEN-1:0] d_forward;
  reg  [`N*`EMB_DIM*`N_LEN-1:0] d_backward;
  wire valid_update;
  wire valid_zero_grad;
  wire valid_forward;
  wire valid_backward;
  wire [`N*`EMB_DIM*`N_LEN_W-1:0] q_forward;

  emb_layer emb_layer_inst (.*);

  // correct
  reg  [`CHAR_LEN-1:0] d_forward_mem [0:(`BATCH_SIZE+1)*`N-1];
  reg  [`N_LEN_W-1:0]  q_forward_mem [0:(`BATCH_SIZE+1)*`N*`EMB_DIM-1];
  wire [`N*`CHAR_LEN-1:0] d_forward_buf [0:`BATCH_SIZE];
  wire [`N*`EMB_DIM*`N_LEN_W-1:0] q_forward_ans[0:`BATCH_SIZE];
  wire [`BATCH_SIZE:0] correct_forward;

  reg  [`N_LEN-1:0] d_backward_mem [0:`BATCH_SIZE*`N*`EMB_DIM-1];
  wire [`N*`EMB_DIM*`N_LEN-1:0] d_backward_buf [0:`BATCH_SIZE-1];


  // assign
  genvar i, j;
  generate
    for (i = 0; i < `BATCH_SIZE + 1; i = i + 1) begin
      for (j = 0; j < `N; j = j + 1) begin
        assign d_forward_buf[i][j*`CHAR_LEN +: `CHAR_LEN] = d_forward_mem[i*`N + j];
      end
      for (j = 0; j < `N*`EMB_DIM; j = j + 1) begin
        assign q_forward_ans[i][j*`N_LEN_W +: `N_LEN_W] = q_forward_mem[i*`N*`EMB_DIM + j];
      end
      assign correct_forward[i] = (q_forward == q_forward_ans[i]);
    end

    
    for (i = 0; i < `BATCH_SIZE; i = i + 1) begin
      for (j = 0; j < `N*`EMB_DIM; j = j + 1) begin
        assign d_backward_buf[i][j*`N_LEN +: `N_LEN] = d_backward_mem[i*`N*`EMB_DIM + j];
      end
    end
  endgenerate


  initial clk = 0;
  always #5 clk =~clk;

  initial begin
    $readmemb("../../data/tb/train/emb_layer/emb_layer_forward_in.txt",  d_forward_mem);
    $readmemb("../../data/tb/train/emb_layer/emb_layer_forward_out.txt", q_forward_mem);
    $readmemb("../../data/tb/train/emb_layer/emb_layer_backward_in.txt", d_backward_mem);
  end

  initial begin
    $dumpvars;
    rst_n=0; update=0; zero_grad=0;
    run_forward=0; run_backward=0; load_backward=0; d_forward=0; d_backward=0;
    #10;
    rst_n=1; #10;
    #20;

    // S1
    zero_grad=1; #10;
    d_forward=d_forward_buf[0]; #10;
    run_forward=1; #10;
    wait (valid_forward & valid_zero_grad); #5;
    #10;
    run_forward=0; #10;
    zero_grad=0; #10;
    #100;

    // S2
    load_backward=1; #10;
    load_backward=0; #10;
    d_forward=d_forward_buf[1]; #10;
    run_forward=1;  #10;
    #100;
    d_backward=d_backward_buf[0]; #10;
    run_backward=1; #10;
    wait (valid_forward & valid_backward); #5;
    #10;
    run_forward=0; run_backward=0; #10;
    #100;

    // S3
    load_backward=1; #10;
    load_backward=0; #10;
    d_backward=d_backward_buf[1]; #10;
    run_backward=1; #10;
    wait (valid_backward); #5;
    #10;
    run_backward=0; #10;
    #100;

    // UPDATE
    update=1; #10;
    wait (valid_update); #5;
    update=0; #10;
    #100;

    // S1
    zero_grad=1; #10;
    d_forward=d_forward_buf[2]; #10;
    run_forward=1; #10;
    wait (valid_forward & valid_zero_grad); #5;
    #10;
    run_forward=0; #10;
    zero_grad=0; #10;
    #100;

    

    $finish;
  end

endmodule  