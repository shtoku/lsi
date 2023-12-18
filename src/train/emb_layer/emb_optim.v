`include "consts_train.vh"

module emb_optim #(
    parameter integer ADDR_WIDTH = 10   // log2(`CHAR_NUM*`EMB_DIM/DATA_N) < 10
  ) (
    input  wire clk,
    input  wire rst_n,
    input  wire run,
    output wire valid,
    output reg  [ADDR_WIDTH-1:0] waddr,
    output wire [`DATA_N*`N_LEN_W-1:0] wdata_w,
    output wire [`DATA_N*`N_LEN_W-1:0] wdata_v,
    output reg  [ADDR_WIDTH-1:0] raddr,
    input  wire [`DATA_N*`N_LEN_W-1:0] rdata_w,
    input  wire [`DATA_N*`N_LEN_W-1:0] rdata_v,
    input  wire [`DATA_N*`N_LEN_W-1:0] rdata_grad
  );


  // ----------------------------------------
  genvar i;

  // reg/wire rdata/wdata buffer
  wire [`N_LEN_W-1:0] rdata_w_buf [0:`DATA_N-1];
  reg  [`N_LEN_W-1:0] rdata_w_buf_delay [0:`DATA_N-1];
  wire [`N_LEN_W-1:0] rdata_v_buf [0:`DATA_N-1];
  wire [`N_LEN_W-1:0] rdata_grad_buf [0:`DATA_N-1];
  reg  [`N_LEN_W-1:0] wdata_w_buf [0:`DATA_N-1];
  reg  [`N_LEN_W-1:0] wdata_v_buf [0:`DATA_N-1];

  // reg multiply momentum, lr buffer
  reg  [`N_LEN_W-1:0] mul_mtm_buf [0:`DATA_N-1];
  reg  [`N_LEN_W-1:0] mul_lr_buf  [0:`DATA_N-1];

  // reg waddr controller
  reg  [ADDR_WIDTH-1:0] raddr_delay1, raddr_delay2, raddr_delay3;


  // ----------------------------------------
  generate
    // covert shape (`DATA_N, `N_LEN_W) <-> (`DATA_N*`N_LEN_W,)
    for (i = 0; i < `DATA_N; i = i + 1) begin
      assign rdata_w_buf[i]    = rdata_w[i*`N_LEN_W +: `N_LEN_W];
      assign rdata_v_buf[i]    = rdata_v[i*`N_LEN_W +: `N_LEN_W];
      assign rdata_grad_buf[i] = rdata_grad[i*`N_LEN_W +: `N_LEN_W];
      assign wdata_w[i*`N_LEN_W +: `N_LEN_W] = wdata_w_buf[i];
      assign wdata_v[i*`N_LEN_W +: `N_LEN_W] = wdata_v_buf[i];
    end
  endgenerate

  // assign valid
  assign valid = run & (raddr_delay3 == `CHAR_NUM*`EMB_DIM/`DATA_N - 1);


  // fucntion fixed multiply 
  function [`N_LEN_W-1:0] fixed_mul;
    input signed [`N_LEN_W-1:0] num1, num2;
    reg [2*`N_LEN_W-1:0] mul;
    begin
      mul = num1 * num2;
      fixed_mul = mul[`F_LEN_W +: `N_LEN_W]; 
    end
  endfunction


  // ----------------------------------------
  // raddr controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      raddr <= 0;
    end else if (run & (raddr != (`CHAR_NUM*`EMB_DIM/`DATA_N) - 1)) begin
      raddr <= raddr + 1;
    end else if (run) begin
      raddr <= raddr;
    end else begin
      raddr <= 0;
    end
  end

  // rdata_w delay
  generate
    for (i = 0; i < `DATA_N; i = i + 1) begin
      always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
          rdata_w_buf_delay[i] <= 0;
        end else begin
          rdata_w_buf_delay[i] <= rdata_w_buf[i];
        end
      end
    end
  endgenerate

  // calculate momentum*rdata_v and lr*rdata_v
  generate
    for (i = 0; i < `DATA_N; i = i + 1) begin
      always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
          mul_mtm_buf[i] <= 0;
          mul_lr_buf[i] <= 0;
        end else begin
          mul_mtm_buf[i] <= fixed_mul(`MOMENTUM, rdata_v_buf[i]);
          mul_lr_buf[i] <= fixed_mul(`LR, rdata_grad_buf[i]);
        end
      end
    end
  endgenerate

  // calculate rdata_w + momentum*rdata_v - lr*rdata_v
  generate
    for (i = 0; i < `DATA_N; i = i + 1) begin
      always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
          wdata_w_buf[i] <= 0;
          wdata_v_buf[i] <= 0;
        end else begin
          wdata_w_buf[i] <= rdata_w_buf_delay[i] + mul_mtm_buf[i] - mul_lr_buf[i];
          wdata_v_buf[i] <= mul_mtm_buf[i] - mul_lr_buf[i];
        end
      end
    end
  endgenerate

  // waddr controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      raddr_delay1 <= 0;
      raddr_delay2 <= 0;
      waddr <= 0;
      raddr_delay3 <= 0;
    end else begin
      raddr_delay1 <= raddr;
      raddr_delay2 <= raddr_delay1;
      waddr <= raddr_delay2;
      raddr_delay3 <= waddr;
    end 
  end

endmodule