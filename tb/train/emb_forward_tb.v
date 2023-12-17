`include "consts_train.vh"

module emb_forward_tb ();
  parameter integer ADDR_WIDTH = 10;

  reg  clk;
  reg  rst_n;
  reg  run;

  // emb_forward
  wire [`N*`CHAR_LEN-1:0] emb_forward_d;
  wire emb_forward_valid;
  wire [`N*`EMB_DIM*`N_LEN_W-1:0] emb_forward_q;
  wire [ADDR_WIDTH-1:0] emb_forward_addr;
  wire [`DATA_N*`N_LEN_W-1:0] emb_forward_rdata;

  // emb_ram_W_emb
  wire emb_ram_w_load;
  wire [ADDR_WIDTH-1:0] emb_ram_w_addr;
  wire [`DATA_N*`N_LEN_W-1:0] emb_ram_w_d;
  wire [`DATA_N*`N_LEN_W-1:0] emb_ram_w_q;

  // mem
  reg  [`CHAR_LEN-1:0] d_mem [0:`N-1];
  reg  [`N_LEN_W-1:0]  q_mem [0:`N*`EMB_DIM-1];
  wire [`N*`EMB_DIM*`N_LEN_W-1:0] q_ans;
  wire correct;


  // assign
  genvar i;
  generate
    for (i = 0; i < `N; i = i + 1) begin
      assign emb_forward_d[i*`CHAR_LEN +: `CHAR_LEN] = d_mem[i];
    end
    for (i = 0; i < `N*`EMB_DIM; i = i + 1) begin
      assign q_ans[i*`N_LEN_W +: `N_LEN_W] = q_mem[i];
    end
  endgenerate
  assign emb_forward_rdata = emb_ram_w_q;
  assign emb_ram_w_addr = emb_forward_addr;

  assign correct = (emb_forward_q == q_ans);


  // instance
  emb_forward emb_forward_inst (
    .clk(clk),
    .rst_n(rst_n),
    .run(run),
    .d(emb_forward_d),
    .valid(emb_forward_valid),
    .q(emb_forward_q),
    .addr(emb_forward_addr),
    .rdata(emb_forward_rdata)
  );

  ram #(
    .FILENAME("../../data/parameter/train/binary108/emb_layer_W_emb.txt"),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(`DATA_N*`N_LEN_W),
    .DATA_DEPTH(`CHAR_NUM*`EMB_DIM/`DATA_N)
  ) emb_ram_w (
    .clk(clk),
    .load(emb_ram_w_load),
    .addr(emb_ram_w_addr),
    .d(emb_ram_w_d),
    .q(emb_ram_w_q)
  );

  initial clk = 0;
  always #5 clk =~clk;

  initial begin
    $readmemb("../../data/tb/train/emb_layer/emb_layer_forward_in.txt",  d_mem);
    $readmemb("../../data/tb/train/emb_layer/emb_layer_forward_out.txt", q_mem);
  end

  initial begin
    $dumpvars;
    rst_n=0; run=0; #10;
    rst_n=1; #30;
    run=1; #10;
    #500;
    run=0; #10;
    run=1; #10;
    #50;
    $finish;
  end
  
endmodule