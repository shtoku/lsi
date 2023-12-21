`include "consts_train.vh"

module comp_layer_tb ();

  reg  clk;
  reg  rst_n;
  reg  run;
  reg  [`N*`CHAR_NUM*`N_LEN-1:0] d;
  wire valid;
  wire [`N*`CHAR_LEN-1:0] num;
  wire [`N*`N_LEN-1:0] q;

  comp_layer comp_layer_inst (.*);

  // correct
  reg  [`N_LEN-1:0] d_mem [0:(`BATCH_SIZE+1)*`N*`CHAR_NUM-1];
  reg  [`CHAR_LEN-1:0] num_mem [0:(`BATCH_SIZE+1)*`N-1];
  reg  [`N_LEN-1:0] q_mem [0:(`BATCH_SIZE+1)*`N-1];
  wire [`N*`CHAR_NUM*`N_LEN-1:0] d_buf [0:`BATCH_SIZE];
  wire [`N*`CHAR_LEN-1:0] num_ans [0:`BATCH_SIZE];
  wire [`N*`N_LEN-1:0] q_ans [0:`BATCH_SIZE];
  wire [`BATCH_SIZE:0] correct_num, correct_q;


  // assign
  genvar i, j;
  generate
    for (i = 0; i < `BATCH_SIZE + 1; i = i + 1) begin
      for (j = 0; j < `N*`CHAR_NUM; j = j + 1) begin
        assign d_buf[i][j*`N_LEN +: `N_LEN] = d_mem[i*`N*`CHAR_NUM + j];
      end
      for (j = 0; j < `N; j = j + 1) begin
        assign num_ans[i][j*`CHAR_LEN +: `CHAR_LEN] = num_mem[i*`N + j];
        assign q_ans[i][j*`N_LEN +: `N_LEN] = q_mem[i*`N + j];
      end
      assign correct_num[i] = (num == num_ans[i]);
      assign correct_q[i] = (q == q_ans[i]);
    end
  endgenerate


  initial clk = 0;
  always #5 clk =~clk;

  initial begin
    $readmemb("../../data/tb/train/comp_layer/comp_layer_in.txt",  d_mem);
    $readmemb("../../data/tb/train/comp_layer/comp_layer_num.txt", num_mem);
    $readmemb("../../data/tb/train/comp_layer/comp_layer_out.txt", q_mem);
  end

  initial begin
    $dumpvars;
    rst_n=0;
    run=0; d=0;
    #10;
    rst_n=1; #10;
    #20;

    // S1
    // zero_grad=1; #10;
    d=d_buf[0]; #10;
    run=1; #10;
    wait (valid); #5;
    #10;
    run=0; #10;
    // zero_grad=0; #10;
    #100;

    // S2
    // load_backward=1; #10;
    // load_backward=0; #10;
    d=d_buf[1]; #10;
    run=1;  #10;
    #100;
    // d_backward=d_backward_buf[0]; #10;
    // run_backward=1; #10;
    wait (valid); #5;
    #10;
    run=0; #10;
    #100;

    // S3
    // load_backward=1; #10;
    // load_backward=0; #10;
    // d_backward=d_backward_buf[1]; #10;
    // run_backward=1; #10;
    // wait (valid_backward); #5;
    #10;
    // run_backward=0; #10;
    #100;
  
    // UPDATE
    // update=1; #10;
    // wait (valid_update); #5;
    // update=0; #10;
    #100;

    // S1
    // zero_grad=1; #10;
    d=d_buf[2]; #10;
    run=1; #10;
    wait (valid); #5;
    #10;
    run=0; #10;
    // zero_grad=0; #10;
    #100;

    $finish;
  end



endmodule