`include "consts_train.vh"

module softmax_layer_tb ();

  reg  clk;
  reg  rst_n;
  reg  run;
  reg  load_d_num;
  reg  [`N*`CHAR_NUM*`N_LEN-1:0] d;
  reg  [`N*`CHAR_LEN-1:0] d_num;
  reg  [`N*`N_LEN-1:0] d_max;
  wire valid;
  wire [`N*`CHAR_NUM*`N_LEN_W-1:0] q;

  softmax_layer softmax_layer_inst (.*);

  // correct
  reg  [`N_LEN-1:0] d_mem [0:`BATCH_SIZE*`N*`CHAR_NUM-1];
  reg  [`N_LEN_W-1:0] q_mem [0:`BATCH_SIZE*`N*`CHAR_NUM-1];
  wire [`N*`CHAR_NUM*`N_LEN-1:0] d_buf [0:`BATCH_SIZE-1];
  wire [`N*`CHAR_NUM*`N_LEN_W-1:0] q_ans [0:`BATCH_SIZE-1];

  reg  [`CHAR_LEN-1:0] d_num_mem [0:`BATCH_SIZE*`N-1];
  reg  [`N_LEN-1:0] d_max_mem [0:`BATCH_SIZE*`N-1];
  wire [`N*`CHAR_LEN-1:0] d_num_buf [0:`BATCH_SIZE-1];
  wire [`N*`N_LEN-1:0] d_max_buf [0:`BATCH_SIZE-1];
  
  wire [`BATCH_SIZE-1:0] correct;


  // assign
  genvar i, j;
  generate
    for (i = 0; i < `BATCH_SIZE; i = i + 1) begin
      for (j = 0; j < `N*`CHAR_NUM; j = j + 1) begin
        assign d_buf[i][j*`N_LEN +: `N_LEN] = d_mem[i*`N*`CHAR_NUM + j];
        assign q_ans[i][j*`N_LEN_W +: `N_LEN_W] = q_mem[i*`N*`CHAR_NUM + j];
      end
      for (j = 0; j < `N; j = j + 1) begin
        assign d_num_buf[i][j*`CHAR_LEN +: `CHAR_LEN] = d_num_mem[i*`N + j];
        assign d_max_buf[i][j*`N_LEN +: `N_LEN] = d_max_mem[i*`N + j];
      end
      assign correct[i] = (q == q_ans[i]);
    end
  endgenerate


  initial clk = 0;
  always #5 clk =~clk;

  initial begin
    $readmemb("../../data/tb/train/softmax_layer/softmax_layer_in.txt",  d_mem);
    $readmemb("../../data/tb/train/softmax_layer/softmax_layer_num.txt", d_num_mem);
    $readmemb("../../data/tb/train/softmax_layer/softmax_layer_max.txt", d_max_mem);
    $readmemb("../../data/tb/train/softmax_layer/softmax_layer_out.txt", q_mem);
  end

  initial begin
    $dumpvars;
    rst_n=0;
    run=0; load_d_num=0; d=0; d_num=0; d_max=0; 
    #10;
    rst_n=1; #10;
    #20;

    // S1
    // zero_grad=1; #10;
    /* d=d_buf[0]; */ d_num=d_num_buf[0]; #10;
    // wait (valid); #5;
    #10;
    // zero_grad=0; #10;
    #100;

    // S2
    load_d_num=1; #10;
    load_d_num=0; #10;
    /* d=d_buf[1]; */ d_num=d_num_buf[1]; #10;
    // run=1;  #10;
    #100;
    d=d_buf[0]; d_max=d_max_buf[0]; #10;
    run=1; #10;
    wait (valid); #5;
    run=0; #10;
    #100;

    // S3
    load_d_num=1; #10;
    load_d_num=0; #10;
    d=d_buf[1]; d_max=d_max_buf[1]; #10;
    run=1; #10;
    wait (valid); #5;
    #10;
    run=0; #10;
    #100;
  
    // UPDATE
    // update=1; #10;
    // wait (valid_update); #5;
    // update=0; #10;
    #100;

    // S1
    // zero_grad=1; #10;
    // d=d_buf[2]; #10;
    // run=1; #10;
    // wait (valid); #5;
    // #10;
    // run=0; #10;
    // zero_grad=0; #10;
    #100;

    $finish;
  end



endmodule