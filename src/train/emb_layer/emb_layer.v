`include "consts_train.vh"

//
// zero_grad needs 800 clk.
//

module emb_layer #(
    parameter integer ADDR_WIDTH = 10   // log2(`CHAR_NUM*`EMB_DIM/DATA_N) < 10
  ) (
    input  wire clk,
    input  wire rst_n,
    input  wire update,
    input  wire zero_grad,
    input  wire run_forward,
    input  wire run_backward,
    input  wire load_backward,
    input  wire [`N*`CHAR_LEN-1:0] d_forward,
    input  wire [`N*`EMB_DIM*`N_LEN-1:0] d_backward,
    output wire valid_update,
    output wire valid_zero_grad,
    output wire valid_forward,
    output wire valid_backward,
    output wire [`N*`EMB_DIM*`N_LEN_W-1:0] q_forward
  );


  // ----------------------------------------
  // reg input buffer
  reg [`N*`CHAR_LEN-1:0] d_forward_buf, d_forward_buf_delay;

  // reg zero_grad
  reg [ADDR_WIDTH-1:0] zero_grad_addr;

  // wire emb_forward
  wire [ADDR_WIDTH-1:0] emb_forward_raddr;
  wire [`DATA_N*`N_LEN_W-1:0] emb_forward_rdata;

  // wire emb_backward
  wire [ADDR_WIDTH-1:0] emb_backward_waddr, emb_backward_raddr;
  wire [`DATA_N*`N_LEN_W-1:0] emb_backward_wdata, emb_backward_rdata;

  // wire emb_optim
  wire [ADDR_WIDTH-1:0] emb_optim_waddr, emb_optim_raddr;
  wire [`DATA_N*`N_LEN_W-1:0] emb_optim_wdata_w, emb_optim_wdata_v;
  wire [`DATA_N*`N_LEN_W-1:0] emb_optim_rdata_w, emb_optim_rdata_v, emb_optim_rdata_grad;

  // wire emb_ram_w
  wire emb_ram_w_load;
  wire [ADDR_WIDTH-1:0] emb_ram_w_waddr, emb_ram_w_raddr;
  wire [`DATA_N*`N_LEN_W-1:0] emb_ram_w_wdata, emb_ram_w_rdata;

  // wire emb_ram_v
  wire emb_ram_v_load;
  wire [ADDR_WIDTH-1:0] emb_ram_v_waddr, emb_ram_v_raddr;
  wire [`DATA_N*`N_LEN_W-1:0] emb_ram_v_wdata, emb_ram_v_rdata;

  // wire emb_ram_grad
  wire emb_ram_grad_load;
  wire [ADDR_WIDTH-1:0] emb_ram_grad_waddr, emb_ram_grad_raddr;
  wire [`DATA_N*`N_LEN_W-1:0] emb_ram_grad_wdata, emb_ram_grad_rdata;


  // ----------------------------------------
  // assign valid_zero_grad
  assign valid_zero_grad = (zero_grad & zero_grad_addr == `CHAR_NUM*`EMB_DIM/`DATA_N);

  // assign emb_forward
  assign emb_forward_rdata = emb_ram_w_rdata;

  // assign emb_backward
  assign emb_backward_rdata = emb_ram_grad_rdata;

  // assign emb_optim
  assign emb_optim_rdata_w    = emb_ram_w_rdata;
  assign emb_optim_rdata_v    = emb_ram_v_rdata;
  assign emb_optim_rdata_grad = emb_ram_grad_rdata;

  // assign emb_ram_w
  assign emb_ram_w_load  = update;
  assign emb_ram_w_waddr = emb_optim_waddr;
  assign emb_ram_w_wdata = emb_optim_wdata_w;
  assign emb_ram_w_raddr = (run_forward) ? emb_forward_raddr :
                           (update)      ? emb_optim_raddr   : {ADDR_WIDTH{1'bX}};

  // assign emb_ram_v
  assign emb_ram_v_load  = update;
  assign emb_ram_v_waddr = emb_optim_waddr;
  assign emb_ram_v_wdata = emb_optim_rdata_v;
  assign emb_ram_v_raddr = emb_optim_raddr;

  // assign emb_ram_grad
  assign emb_ram_grad_load  = (zero_grad | run_backward);
  assign emb_ram_grad_waddr = (zero_grad)    ? zero_grad_addr     :
                              (run_backward) ? emb_backward_waddr : {ADDR_WIDTH{1'bX}};
  assign emb_ram_grad_wdata = (zero_grad)    ? {`DATA_N*`N_LEN_W{1'b0}} :
                              (run_backward) ? emb_backward_wdata       : {`DATA_N*`N_LEN_W{1'bX}};
  assign emb_ram_grad_raddr = (run_backward) ? emb_backward_raddr :
                              (update)       ? emb_optim_raddr    : {ADDR_WIDTH{1'bX}};



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
  // emb_forward
  emb_forward #(
    .ADDR_WIDTH(ADDR_WIDTH)
  ) emb_forward_inst (
    .clk(clk),
    .rst_n(rst_n),
    .run(run_forward),
    .d(d_forward),
    .valid(valid_forward),
    .q(q_forward),
    .raddr(emb_forward_raddr),
    .rdata(emb_forward_rdata)
  );

  // emb_backward
  emb_backward #(
    .ADDR_WIDTH(ADDR_WIDTH)
  ) emb_backward_inst (
    .clk(clk),
    .rst_n(rst_n),
    .run(run_backward),
    .d_forward(d_forward_buf_delay),
    .d_backward(d_backward),
    .valid(valid_backward),
    .waddr(emb_backward_waddr),
    .wdata(emb_backward_wdata),
    .raddr(emb_backward_raddr),
    .rdata(emb_backward_rdata)
  );


  // emb_optim
  emb_optim #(
    .ADDR_WIDTH(ADDR_WIDTH)
  ) emb_optim_inst (
    .clk(clk),
    .rst_n(rst_n),
    .run(update),
    .valid(valid_update),
    .waddr(emb_optim_waddr),
    .wdata_w(emb_optim_wdata_w),
    .wdata_v(emb_optim_wdata_v),
    .raddr(emb_optim_raddr),
    .rdata_w(emb_optim_rdata_w),
    .rdata_v(emb_optim_rdata_v),
    .rdata_grad(emb_optim_rdata_grad)
  );

  // emb_ram_w
  ram #(
    .FILENAME("../../data/parameter/train/binary108/emb_layer_W_emb.txt"),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(`DATA_N*`N_LEN_W),
    .DATA_DEPTH(`CHAR_NUM*`EMB_DIM/`DATA_N)
  ) emb_ram_w (
    .clk(clk),
    .load(emb_ram_w_load),
    .waddr(emb_ram_w_waddr),
    .wdata(emb_ram_w_wdata),
    .raddr(emb_ram_w_raddr),
    .rdata(emb_ram_w_rdata)
  );

  // emb_ram_v
  ram #(
    .FILENAME("../../data/parameter/train/binary108/zeros_like_W_emb.txt"),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(`DATA_N*`N_LEN_W),
    .DATA_DEPTH(`CHAR_NUM*`EMB_DIM/`DATA_N)
  ) emb_ram_v (
    .clk(clk),
    .load(emb_ram_v_load),
    .waddr(emb_ram_v_waddr),
    .wdata(emb_ram_v_wdata),
    .raddr(emb_ram_v_raddr),
    .rdata(emb_ram_v_rdata)
  );


  // emb_ram_grad
  ram #(
    .FILENAME("../../data/parameter/train/binary108/zeros_like_W_emb.txt"),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(`DATA_N*`N_LEN_W),
    .DATA_DEPTH(`CHAR_NUM*`EMB_DIM/`DATA_N)
  ) emb_ram_grad (
    .clk(clk),
    .load(emb_ram_grad_load),
    .waddr(emb_ram_grad_waddr),
    .wdata(emb_ram_grad_wdata),
    .raddr(emb_ram_grad_raddr),
    .rdata(emb_ram_grad_rdata)
  );

  
endmodule