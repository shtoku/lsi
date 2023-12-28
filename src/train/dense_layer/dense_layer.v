`include "consts_train.vh"

module dense_layer #(
    parameter integer ADDR_WIDTH   = 10,   // log2(`HID_DIM*`CHAR_NUM/DATA_N) < 10
    parameter integer DENSE_DATA_N = 6     // 1 time read, read 6 data.
  ) (
    input  wire clk,
    input  wire rst_n,
    input  wire update,
    input  wire zero_grad,
    input  wire run_forward,
    input  wire run_backward,
    input  wire load_backward,
    input  wire [`N*`HID_DIM*`N_LEN_W-1:0] d_forward,
    input  wire [`N*`CHAR_NUM*`N_LEN_W-1:0] d_backward,
    output wire valid_update,
    output wire valid_zero_grad,
    output wire valid_forward,
    output wire valid_backward,
    output wire [`N*`CHAR_NUM*`N_LEN-1:0] q_forward,
    output wire [`N*`HID_DIM*`N_LEN-1:0] q_backward
  );


  // ----------------------------------------
  // reg input buffer
  reg [`N*`HID_DIM*`N_LEN_W-1:0] d_forward_buf, d_forward_buf_delay;

  // reg zero_grad
  reg [ADDR_WIDTH-1:0] zero_grad_addr;

  // wire dense_forward
  wire [ADDR_WIDTH-1:0]          dense_forward_raddr;
  wire [DENSE_DATA_N*`N_LEN-1:0] dense_forward_rdata;

  // wire dense_backward
  wire [ADDR_WIDTH-1:0]          dense_backward_waddr;
  wire [DENSE_DATA_N*`N_LEN-1:0] dense_backward_wdata;
  wire [ADDR_WIDTH-1:0]          dense_backward_raddr_w, dense_backward_raddr_grad;
  wire [DENSE_DATA_N*`N_LEN-1:0] dense_backward_rdata_w, dense_backward_rdata_grad;

  // wire dense_optim
  wire dense_optim_valid;
  wire [ADDR_WIDTH-1:0] dense_optim_waddr, dense_optim_raddr;
  wire [DENSE_DATA_N*`N_LEN-1:0] dense_optim_wdata_w, dense_optim_wdata_v;
  wire [DENSE_DATA_N*`N_LEN-1:0] dense_optim_rdata_w, dense_optim_rdata_v, dense_optim_rdata_grad;

  // wire dense_ram_wt
  wire dense_ram_wt_load;
  wire [ADDR_WIDTH-1:0]          dense_ram_wt_waddr, dense_ram_wt_raddr;
  wire [DENSE_DATA_N*`N_LEN-1:0] dense_ram_wt_wdata, dense_ram_wt_rdata;

  // wire dense_ram_w
  wire dense_ram_w_load;
  wire [ADDR_WIDTH-1:0]          dense_ram_w_waddr, dense_ram_w_raddr;
  wire [DENSE_DATA_N*`N_LEN-1:0] dense_ram_w_wdata, dense_ram_w_rdata;

  // wire dense_ram_v
  wire dense_ram_v_load;
  wire [ADDR_WIDTH-1:0]          dense_ram_v_waddr, dense_ram_v_raddr;
  wire [DENSE_DATA_N*`N_LEN-1:0] dense_ram_v_wdata, dense_ram_v_rdata;

  // wire dense_ram_grad
  wire dense_ram_grad_load;
  wire [ADDR_WIDTH-1:0]          dense_ram_grad_waddr, dense_ram_grad_raddr;
  wire [DENSE_DATA_N*`N_LEN-1:0] dense_ram_grad_wdata, dense_ram_grad_rdata;

  // wire dense_transpose
  wire dense_transpose_run;
  wire dense_transpose_valid;
  wire [ADDR_WIDTH-1:0]          dense_transpose_waddr, dense_transpose_raddr;
  wire [DENSE_DATA_N*`N_LEN-1:0] dense_transpose_wdata, dense_transpose_rdata;


  // ----------------------------------------
  // assign valid_update
  assign valid_update = (update & dense_transpose_valid);

  // assign valid_zero_grad
  assign valid_zero_grad = (zero_grad & zero_grad_addr == `HID_DIM*`CHAR_NUM/DENSE_DATA_N);

  // assign dense_forward
  assign dense_forward_rdata = dense_ram_wt_rdata;

  // assign dense_backward
  assign dense_backward_rdata_w    = dense_ram_w_rdata;
  assign dense_backward_rdata_grad = dense_ram_grad_rdata;

  // assign dense_optim
  assign dense_optim_rdata_w    = dense_ram_w_rdata;
  assign dense_optim_rdata_v    = dense_ram_v_rdata;
  assign dense_optim_rdata_grad = dense_ram_grad_rdata;

  // assign dense_ram_wt
  assign dense_ram_wt_load  = dense_transpose_run;
  assign dense_ram_wt_waddr = dense_transpose_waddr;
  assign dense_ram_wt_wdata = dense_transpose_wdata;
  assign dense_ram_wt_raddr = dense_forward_raddr;

  // assign dense_ram_w
  assign dense_ram_w_load  = (update & ~dense_optim_valid);
  assign dense_ram_w_waddr = dense_optim_waddr;
  assign dense_ram_w_wdata = dense_optim_wdata_w;
  assign dense_ram_w_raddr = (run_backward)        ? dense_backward_raddr_w :
                             (dense_transpose_run) ? dense_transpose_raddr  :
                             (update)              ? dense_optim_raddr      : {ADDR_WIDTH{1'b0}};

  // assign dense_ram_v
  assign dense_ram_v_load  = (update & ~dense_optim_valid);
  assign dense_ram_v_waddr = dense_optim_waddr;
  assign dense_ram_v_wdata = dense_optim_wdata_v;
  assign dense_ram_v_raddr = dense_optim_raddr;

  // assign dense_ram_grad
  assign dense_ram_grad_load  = (zero_grad | run_backward);
  assign dense_ram_grad_waddr = (zero_grad)    ? zero_grad_addr       :
                                (run_backward) ? dense_backward_waddr : {ADDR_WIDTH{1'bX}};
  assign dense_ram_grad_wdata = (zero_grad)    ? {DENSE_DATA_N*`N_LEN{1'b0}} :
                                (run_backward) ? dense_backward_wdata        : {DENSE_DATA_N*`N_LEN{1'bX}};
  assign dense_ram_grad_raddr = (run_backward) ? dense_backward_raddr_grad  :
                                (update)       ? dense_optim_raddr          : {ADDR_WIDTH{1'bX}};

  // assign dense_transpose
  assign dense_transpose_run   = update & dense_optim_valid;
  assign dense_transpose_rdata = dense_ram_w_rdata;


  // ----------------------------------------
  // input buffer controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      d_forward_buf <= 0;
      d_forward_buf_delay <= 0;
    end else begin
      if (run_forward)
        d_forward_buf <= d_forward;
      if (load_backward)
        d_forward_buf_delay <= d_forward_buf;
    end
  end

  // zero_grad_addr controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      zero_grad_addr <= 0;
    end else if (zero_grad) begin
      if (~valid_zero_grad)
        zero_grad_addr <= zero_grad_addr + 1;
      else
        zero_grad_addr <= zero_grad_addr; 
    end else begin
      zero_grad_addr <= 0;
    end
  end


  // ----------------------------------------
  // dense_forward
  dense_forward #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DENSE_DATA_N(DENSE_DATA_N)
  ) dense_forward_inst (
    .clk(clk), 
    .rst_n(rst_n), 
    .run(run_forward),
    .d(d_forward),
    .valid(valid_forward),
    .q(q_forward),
    .raddr(dense_forward_raddr),
    .rdata(dense_forward_rdata)
  );

  // dense_backward
  dense_backward #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DENSE_DATA_N(DENSE_DATA_N)
  ) dense_backward_inst (
    .clk(clk),
    .rst_n(rst_n),
    .run(run_backward),
    .d_forward(d_forward_buf_delay),
    .d_backward(d_backward),
    .valid(valid_backward),
    .q(q_backward),
    .waddr(dense_backward_waddr),
    .wdata(dense_backward_wdata),
    .raddr_w(dense_backward_raddr_w),
    .raddr_grad(dense_backward_raddr_grad),
    .rdata_w(dense_backward_rdata_w),
    .rdata_grad(dense_backward_rdata_grad)
  );

  // dense_optim
  dense_optim #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DENSE_DATA_N(DENSE_DATA_N)
  ) dense_optim_inst (
    .clk(clk),
    .rst_n(rst_n),
    .run(update),
    .valid(dense_optim_valid),
    .waddr(dense_optim_waddr),
    .wdata_w(dense_optim_wdata_w),
    .wdata_v(dense_optim_wdata_v),
    .raddr(dense_optim_raddr),
    .rdata_w(dense_optim_rdata_w),
    .rdata_v(dense_optim_rdata_v),
    .rdata_grad(dense_optim_rdata_grad)
  );

  // dense_ram_wt
  ram #(
    .FILENAME("../../data/parameter/train/binary108/dense_layer_W_out_T.txt"),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DENSE_DATA_N*`N_LEN),
    .DATA_DEPTH(`HID_DIM*`CHAR_NUM/DENSE_DATA_N)
  ) dense_ram_wt (
    .clk(clk),
    .load(dense_ram_wt_load),
    .waddr(dense_ram_wt_waddr),
    .wdata(dense_ram_wt_wdata),
    .raddr(dense_ram_wt_raddr),
    .rdata(dense_ram_wt_rdata)
  );

  // dense_ram_w
  ram #(
    .FILENAME("../../data/parameter/train/binary108/dense_layer_W_out.txt"),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DENSE_DATA_N*`N_LEN),
    .DATA_DEPTH(`HID_DIM*`CHAR_NUM/DENSE_DATA_N)
  ) dense_ram_w (
    .clk(clk),
    .load(dense_ram_w_load),
    .waddr(dense_ram_w_waddr),
    .wdata(dense_ram_w_wdata),
    .raddr(dense_ram_w_raddr),
    .rdata(dense_ram_w_rdata)
  );

  // dense_ram_v
  ram #(
    .FILENAME("../../data/parameter/train/binary108/zeros_like_W_out.txt"),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DENSE_DATA_N*`N_LEN),
    .DATA_DEPTH(`HID_DIM*`CHAR_NUM/DENSE_DATA_N)
  ) dense_ram_v (
    .clk(clk),
    .load(dense_ram_v_load),
    .waddr(dense_ram_v_waddr),
    .wdata(dense_ram_v_wdata),
    .raddr(dense_ram_v_raddr),
    .rdata(dense_ram_v_rdata)
  );

  // dense_ram_grad
  ram #(
    .FILENAME("../../data/parameter/train/binary108/zeros_like_W_out.txt"),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DENSE_DATA_N*`N_LEN),
    .DATA_DEPTH(`HID_DIM*`CHAR_NUM/DENSE_DATA_N)
  ) dense_ram_grad (
    .clk(clk),
    .load(dense_ram_grad_load),
    .waddr(dense_ram_grad_waddr),
    .wdata(dense_ram_grad_wdata),
    .raddr(dense_ram_grad_raddr),
    .rdata(dense_ram_grad_rdata)
  );

  // dense_transpose
  dense_transpose #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DENSE_DATA_N(DENSE_DATA_N)
  ) dense_transpose_inst (
    .clk(clk),
    .rst_n(rst_n),
    .run(dense_transpose_run),
    .valid(dense_transpose_valid),
    .waddr(dense_transpose_waddr),
    .wdata(dense_transpose_wdata),
    .raddr(dense_transpose_raddr),
    .rdata(dense_transpose_rdata)
  );

endmodule