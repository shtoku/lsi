`include "consts_train.vh"

module mix_block #(
    parameter integer FILENUM = 0,
    parameter integer ADDR_WIDTH = 9    // log2(3*`HID_DIM*`HID_DIM/`DATA_N) < 9
  ) (
    input  wire clk,
    input  wire rst_n,
    input  wire update,
    input  wire zero_grad,
    input  wire run_forward,
    input  wire run_backward,
    input  wire load_backward,
    input  wire [`STATE_LEN-1:0] state_forward,
    input  wire [`STATE_LEN-1:0] state_backward,
    input  wire [`HID_DIM*`N_LEN-1:0] d_forward,
    input  wire [`HID_DIM*`N_LEN-1:0] d_backward,
    output wire valid_update,
    output wire valid_zero_grad,
    output wire valid_forward,
    output wire valid_backward,
    output wire [`HID_DIM*`N_LEN-1:0] q_forward,
    output wire [`HID_DIM*`N_LEN-1:0] q_backward
  );


  // ----------------------------------------
  // reg input buffer
  wire [`HID_DIM*`N_LEN-1:0] d_forward_buf_delay;
  reg  [`HID_DIM*`N_LEN-1:0] d_forward_mix1, d_forward_mix2, d_forward_mix3;
  reg  [`HID_DIM*`N_LEN-1:0] d_forward_mix1_delay, d_forward_mix2_delay, d_forward_mix3_delay;

  // reg zero_grad
  reg  [ADDR_WIDTH-1:0] zero_grad_addr;

  // wire mix_forward
  wire [ADDR_WIDTH-1:0]       mix_forward_raddr_w, mix_forward_raddr_b;
  wire [`DATA_N*`N_LEN_W-1:0] mix_forward_rdata_w;
  wire [`N_LEN_W-1:0]         mix_forward_rdata_b;

  // wire mix_backward
  wire [`HID_DIM*`N_LEN-1:0]  mix_backward_d_forward;
  wire [ADDR_WIDTH-1:0]       mix_backward_waddr_grad_w, mix_backward_waddr_grad_b;
  wire [`DATA_N*`N_LEN_W-1:0] mix_backward_wdata_grad_w;
  wire [`N_LEN_W-1:0]         mix_backward_wdata_grad_b;
  wire [ADDR_WIDTH-1:0]       mix_backward_raddr_w, mix_backward_raddr_grad_w, mix_backward_raddr_grad_b;
  wire [`DATA_N*`N_LEN_W-1:0] mix_backward_rdata_w, mix_backward_rdata_grad_w;
  wire [`N_LEN_W-1:0]         mix_backward_rdata_grad_b;

  // wire mix_optim_w
  wire mix_optim_w_valid;
  wire [ADDR_WIDTH-1:0] mix_optim_w_waddr, mix_optim_w_raddr;
  wire [`DATA_N*`N_LEN_W-1:0] mix_optim_w_wdata_w, mix_optim_w_wdata_v;
  wire [`DATA_N*`N_LEN_W-1:0] mix_optim_w_rdata_w, mix_optim_w_rdata_v, mix_optim_w_rdata_grad;

  // wire mix_optim_b
  wire mix_optim_b_valid;
  wire [ADDR_WIDTH-1:0] mix_optim_b_waddr, mix_optim_b_raddr;
  wire [`N_LEN_W-1:0] mix_optim_b_wdata_b, mix_optim_b_wdata_v;
  wire [`N_LEN_W-1:0] mix_optim_b_rdata_b, mix_optim_b_rdata_v, mix_optim_b_rdata_grad;

  // wire mix_ram_wt
  wire mix_ram_wt_load;
  wire [ADDR_WIDTH-1:0]       mix_ram_wt_waddr, mix_ram_wt_raddr;
  wire [`DATA_N*`N_LEN_W-1:0] mix_ram_wt_wdata, mix_ram_wt_rdata;

  // wire mix_ram_w
  wire mix_ram_w_load;
  wire [ADDR_WIDTH-1:0]       mix_ram_w_waddr, mix_ram_w_raddr;
  wire [`DATA_N*`N_LEN_W-1:0] mix_ram_w_wdata, mix_ram_w_rdata;
  
  // wire mix_ram_b
  wire mix_ram_b_load;
  wire [ADDR_WIDTH-1:0] mix_ram_b_waddr, mix_ram_b_raddr;
  wire [`N_LEN_W-1:0]   mix_ram_b_wdata, mix_ram_b_rdata;

  // wire mix_ram_v_w
  wire mix_ram_v_w_load;
  wire [ADDR_WIDTH-1:0]       mix_ram_v_w_waddr, mix_ram_v_w_raddr;
  wire [`DATA_N*`N_LEN_W-1:0] mix_ram_v_w_wdata, mix_ram_v_w_rdata;

  // wire mix_ram_v_b
  wire mix_ram_v_b_load;
  wire [ADDR_WIDTH-1:0] mix_ram_v_b_waddr, mix_ram_v_b_raddr;
  wire [`N_LEN_W-1:0]   mix_ram_v_b_wdata, mix_ram_v_b_rdata;

  // wire mix_ram_grad_w
  wire mix_ram_grad_w_load;
  wire [ADDR_WIDTH-1:0]       mix_ram_grad_w_waddr, mix_ram_grad_w_raddr;
  wire [`DATA_N*`N_LEN_W-1:0] mix_ram_grad_w_wdata, mix_ram_grad_w_rdata;

  // wire mix_ram_grad_b
  wire mix_ram_grad_b_load;
  wire [ADDR_WIDTH-1:0] mix_ram_grad_b_waddr, mix_ram_grad_b_raddr;
  wire [`N_LEN_W-1:0]   mix_ram_grad_b_wdata, mix_ram_grad_b_rdata;


  // ----------------------------------------
  // assign valid_zero_grad
  assign valid_zero_grad = (zero_grad_addr == 3*`HID_DIM*`HID_DIM/`DATA_N);

  // assign mix_forward
  assign mix_forward_rdata_w = mix_ram_wt_rdata;
  assign mix_forward_rdata_b = mix_ram_b_rdata;

  // assign mix_backward
  assign mix_backward_d_forward  = (state_backward == `B_MIX1) ? d_forward_mix1_delay :
                                   (state_backward == `B_MIX2) ? d_forward_mix2_delay :
                                   (state_backward == `B_MIX3) ? d_forward_mix3_delay : {(`HID_DIM*`N_LEN){1'bX}};
  assign mix_backward_rdata_w    = mix_ram_w_rdata;
  assign mix_backward_rdata_grad_w = mix_ram_grad_w_rdata;
  assign mix_backward_rdata_grad_b = mix_ram_grad_b_rdata;

  // assign mix_optim_w
  assign mix_optim_w_rdata_w    = mix_ram_w_rdata;
  assign mix_optim_w_rdata_v    = mix_ram_v_w_rdata;
  assign mix_optim_w_rdata_grad = mix_ram_grad_w_rdata;

  // assign mix_optim_b
  assign mix_optim_b_rdata_b    = mix_ram_b_rdata;
  assign mix_optim_b_rdata_v    = mix_ram_v_b_rdata;
  assign mix_optim_b_rdata_grad = mix_ram_grad_b_rdata;

  // assign mix_ram_wt
  assign mix_ram_wt_load  = 0;
  assign mix_ram_wt_waddr = 0;
  assign mix_ram_wt_wdata = 0;
  assign mix_ram_wt_raddr = mix_forward_raddr_w;

  // assign mix_ram_w
  assign mix_ram_w_load  = update;
  assign mix_ram_w_waddr = mix_optim_w_waddr;
  assign mix_ram_w_wdata = mix_optim_w_wdata_w;
  assign mix_ram_w_raddr = (run_backward) ? mix_backward_raddr_w :
                           (update)       ? mix_optim_w_raddr    : {ADDR_WIDTH{1'bX}};

  // assign mix_ram_b
  assign mix_ram_b_load  = update;
  assign mix_ram_b_waddr = mix_optim_b_waddr;
  assign mix_ram_b_wdata = mix_optim_b_wdata_b;
  assign mix_ram_b_raddr = (run_forward) ? mix_forward_raddr_b :
                           (update)      ? mix_optim_b_raddr   : {ADDR_WIDTH{1'bX}};

  // assign mix_ram_v_w
  assign mix_ram_v_w_load  = update;
  assign mix_ram_v_w_waddr = mix_optim_w_waddr;
  assign mix_ram_v_w_wdata = mix_optim_w_wdata_v;
  assign mix_ram_v_w_raddr = mix_optim_w_raddr;

  // assign mix_ram_v_b
  assign mix_ram_v_b_load  = update;
  assign mix_ram_v_b_waddr = mix_optim_b_waddr;
  assign mix_ram_v_b_wdata = mix_optim_b_wdata_v;
  assign mix_ram_v_b_raddr = mix_optim_b_raddr;

  // assign mix_ram_grad_w
  assign mix_ram_grad_w_load  = (zero_grad | run_backward);
  assign mix_ram_grad_w_waddr = (zero_grad)    ? zero_grad_addr            :
                                (run_backward) ? mix_backward_waddr_grad_w : {ADDR_WIDTH{1'bX}};
  assign mix_ram_grad_w_wdata = (zero_grad)    ? {`DATA_N*`N_LEN_W{1'b0}}  :
                                (run_backward) ? mix_backward_wdata_grad_w : {`DATA_N*`N_LEN_W{1'bX}};
  assign mix_ram_grad_w_raddr = (run_backward) ? mix_backward_raddr_grad_w :
                                (update)       ? mix_optim_w_raddr         : {ADDR_WIDTH{1'bX}};

  // assign mix_ram_grad_b
  assign mix_ram_grad_b_load  = (zero_grad | run_backward);
  assign mix_ram_grad_b_waddr = (zero_grad)    ? zero_grad_addr[ADDR_WIDTH-1:2] :
                                (run_backward) ? mix_backward_waddr_grad_b      : {ADDR_WIDTH{1'bX}};
  assign mix_ram_grad_b_wdata = (zero_grad)    ? {`N_LEN_W{1'b0}}  :
                                (run_backward) ? mix_backward_wdata_grad_b : {`N_LEN_W{1'bX}};
  assign mix_ram_grad_b_raddr = (run_backward) ? mix_backward_raddr_grad_b :
                                (update)       ? mix_optim_b_raddr         : {ADDR_WIDTH{1'bX}};


  // ----------------------------------------
  // input buffer controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      d_forward_mix1 <= 0;
      d_forward_mix2 <= 0;
      d_forward_mix3 <= 0;
      d_forward_mix1_delay <= 0;
      d_forward_mix2_delay <= 0;
      d_forward_mix3_delay <= 0;
    end else begin
      if (run_forward)
        case (state_forward)
          `F_MIX1 : d_forward_mix1 <= d_forward;
          `F_MIX2 : d_forward_mix2 <= d_forward;
          `F_MIX3 : d_forward_mix3 <= d_forward;
        endcase
      if (load_backward) begin
        d_forward_mix1_delay <= d_forward_mix1;
        d_forward_mix2_delay <= d_forward_mix2;
        d_forward_mix3_delay <= d_forward_mix3;
      end
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
  // mix_forward
  mix_forward #(
    .ADDR_WIDTH(ADDR_WIDTH)
  ) mix_forward_inst (
    .clk(clk),
    .rst_n(rst_n),
    .run(run_forward),
    .state(state_forward),
    .d(d_forward),
    .valid(valid_forward),
    .q(q_forward),
    .raddr_w(mix_forward_raddr_w),
    .raddr_b(mix_forward_raddr_b),
    .rdata_w(mix_forward_rdata_w),
    .rdata_b(mix_forward_rdata_b)
  );

  // mix_backward
  mix_backward #(
    .ADDR_WIDTH(ADDR_WIDTH)
  ) mix_backward_inst (
    .clk(clk),
    .rst_n(rst_n),
    .run(run_backward),
    .state(state_backward),
    .d_forward(mix_backward_d_forward),
    .d_backward(d_backward),
    .valid(valid_backward),
    .q(q_backward),
    .waddr_grad_w(mix_backward_waddr_grad_w),
    .waddr_grad_b(mix_backward_waddr_grad_b),
    .wdata_grad_w(mix_backward_wdata_grad_w),
    .wdata_grad_b(mix_backward_wdata_grad_b),
    .raddr_w(mix_backward_raddr_w),
    .raddr_grad_w(mix_backward_raddr_grad_w),
    .raddr_grad_b(mix_backward_raddr_grad_b),
    .rdata_w(mix_backward_rdata_w),
    .rdata_grad_w(mix_backward_rdata_grad_w),
    .rdata_grad_b(mix_backward_rdata_grad_b)
  );

  // mix_optim_w
  mix_optim_w #(
    .ADDR_WIDTH(ADDR_WIDTH)
  ) mix_optim_w_inst (
    .clk(clk),
    .rst_n(rst_n),
    .run(update),
    .state(state_backward),
    .valid(mix_optim_w_valid),
    .waddr(mix_optim_w_waddr),
    .wdata_w(mix_optim_w_wdata_w),
    .wdata_v(mix_optim_w_wdata_v),
    .raddr(mix_optim_w_raddr),
    .rdata_w(mix_optim_w_rdata_w),
    .rdata_v(mix_optim_w_rdata_v),
    .rdata_grad(mix_optim_w_rdata_grad)
  );

  // mix_optim_b
  mix_optim_b #(
    .ADDR_WIDTH(ADDR_WIDTH)
  ) mix_optim_b_inst (
    .clk(clk),
    .rst_n(rst_n),
    .run(update),
    .state(state_backward),
    .valid(mix_optim_b_valid),
    .waddr(mix_optim_b_waddr),
    .wdata_b(mix_optim_b_wdata_b),
    .wdata_v(mix_optim_b_wdata_v),
    .raddr(mix_optim_b_raddr),
    .rdata_b(mix_optim_b_rdata_b),
    .rdata_v(mix_optim_b_rdata_v),
    .rdata_grad(mix_optim_b_rdata_grad)
  );

  // mix_ram_wt
  mix_ram_wt #(
    .FILENUM(FILENUM),
    .ADDR_WIDTH(ADDR_WIDTH)
  ) mix_ram_wt_inst (
    .clk(clk),
    .load(mix_ram_wt_load),
    .waddr(mix_ram_wt_waddr),
    .wdata(mix_ram_wt_wdata),
    .raddr(mix_ram_wt_raddr),
    .rdata(mix_ram_wt_rdata)
  );

  // mix_ram_w
  mix_ram_w #(
    .FILENUM(FILENUM),
    .ADDR_WIDTH(ADDR_WIDTH)
  ) mix_ram_w_inst (
    .clk(clk),
    .load(mix_ram_w_load),
    .waddr(mix_ram_w_waddr),
    .wdata(mix_ram_w_wdata),
    .raddr(mix_ram_w_raddr),
    .rdata(mix_ram_w_rdata)
  );

  // mix_ram_b
  mix_ram_b #(
    .FILENUM(FILENUM),
    .ADDR_WIDTH(ADDR_WIDTH)
  ) mix_ram_b_inst (
    .clk(clk),
    .load(mix_ram_b_load),
    .waddr(mix_ram_b_waddr),
    .wdata(mix_ram_b_wdata),
    .raddr(mix_ram_b_raddr),
    .rdata(mix_ram_b_rdata)
  );

  // mix_ram_v_w
  ram #(
    .FILENAME("../../data/parameter/train/binary108/zeros_like_W_mix.txt"),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(`DATA_N*`N_LEN_W),
    .DATA_DEPTH(3*`HID_DIM*`HID_DIM/`DATA_N)
  ) mix_ram_v_w (
    .clk(clk),
    .load(mix_ram_v_w_load),
    .waddr(mix_ram_v_w_waddr),
    .wdata(mix_ram_v_w_wdata),
    .raddr(mix_ram_v_w_raddr),
    .rdata(mix_ram_v_w_rdata)
  );

  // mix_ram_v_b
  ram #(
    .FILENAME("../../data/parameter/train/binary18/zeros_like_b_mix.txt"),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(`N_LEN_W),
    .DATA_DEPTH(3*`HID_DIM)
  ) mix_ram_v_b (
    .clk(clk),
    .load(mix_ram_v_b_load),
    .waddr(mix_ram_v_b_waddr),
    .wdata(mix_ram_v_b_wdata),
    .raddr(mix_ram_v_b_raddr),
    .rdata(mix_ram_v_b_rdata)
  );
  
  // mix_ram_grad_w
  ram #(
    .FILENAME("../../data/parameter/train/binary108/zeros_like_W_mix.txt"),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(`DATA_N*`N_LEN_W),
    .DATA_DEPTH(3*`HID_DIM*`HID_DIM/`DATA_N)
  ) mix_ram_grad_w (
    .clk(clk),
    .load(mix_ram_grad_w_load),
    .waddr(mix_ram_grad_w_waddr),
    .wdata(mix_ram_grad_w_wdata),
    .raddr(mix_ram_grad_w_raddr),
    .rdata(mix_ram_grad_w_rdata)
  );
  
  // mix_ram_grad_b
  ram #(
    .FILENAME("../../data/parameter/train/binary18/zeros_like_b_mix.txt"),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(`N_LEN_W),
    .DATA_DEPTH(3*`HID_DIM)
  ) mix_ram_grad_b (
    .clk(clk),
    .load(mix_ram_grad_b_load),
    .waddr(mix_ram_grad_b_waddr),
    .wdata(mix_ram_grad_b_wdata),
    .raddr(mix_ram_grad_b_raddr),
    .rdata(mix_ram_grad_b_rdata)
  );

  // mix_w_transpose



endmodule