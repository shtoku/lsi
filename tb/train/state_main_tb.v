`include "consts_train.vh"

module state_main_tb ();

  // top
  reg  clk;
  reg  rst_n;
  reg  run;
  reg  set;
  reg  next_batch;
  reg  [`MODE_LEN-1:0] mode;

  // state_main
  wire state_main_run;
  wire [`MODE_LEN-1:0] state_main_mode;
  wire [`STATE_LEN-1:0] state_main_q;

  // state_forward
  wire state_forward_run;
  wire state_forward_set;
  wire [`STATE_LEN-1:0] state_forward_d;
  wire [`STATE_LEN-1:0] state_forward_q;

  // state_backward
  wire state_backward_run;
  wire [`STATE_LEN-1:0] state_backward_q;


  assign state_main_run = (state_main_q == `M_IDLE)   ? run :
                          (state_main_q == `M_S1)     ? (state_forward_q  == `F_FIN) :
                          (state_main_q == `M_S2)     ? (state_forward_q  == `F_FIN) & (state_backward_q == `B_FIN) :
                          (state_main_q == `M_S3)     ? (state_backward_q == `B_FIN) :
                          (state_main_q == `M_UPDATE) ? 1'b1 :
                          (state_main_q == `M_FIN)    ? next_batch : 1'b0;
  assign state_main_mode = mode;
  
  assign state_forward_run = (state_forward_q == `F_IDLE) ? (state_main_q == `M_S1 | state_main_q == `M_S2) :
                             (state_forward_q == `F_FIN)  ? state_main_run : 1'b1;
  assign state_forward_set = set;
  assign state_forward_d = `F_IDLE;
  
  assign state_backward_run = (state_backward_q == `B_IDLE) ? (state_main_q == `M_S2 | state_main_q == `M_S3) :
                              (state_backward_q == `B_FIN)  ? state_main_run : 1'b1;


  state_main state_main_inst (
    .clk(clk),
    .rst_n(rst_n),
    .run(state_main_run),
    .mode(state_main_mode),
    .q(state_main_q)
  );

  state_forward state_forward_inst (
    .clk(clk),
    .rst_n(rst_n),
    .run(state_forward_run),
    .set(state_forward_set),
    .d(state_forward_d),
    .q(state_forward_q)
  );

  state_backward state_backward_inst (
    .clk(clk),
    .rst_n(rst_n),
    .run(state_backward_run),
    .q(state_backward_q)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    $dumpvars;
    rst_n=0; run=0; set=0; next_batch=1; mode=`TRAIN; #10;
    rst_n=1; run=0; set=1; #10;
    rst_n=1; run=1; set=0; #10;    
    #1000;
    $finish;
  end

endmodule