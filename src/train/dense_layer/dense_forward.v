`include "consts_train.vh"

module dense_forward #(
    parameter integer ADDR_WIDTH   = 10,   // log2(`HID_DIM*`CHAR_NUM/DATA_N) < 10
    parameter integer DENSE_DATA_N = 8     // 1 time read, read 8 data.
  ) (
    input  wire clk, 
    input  wire rst_n, 
    input  wire run,
    input  wire [`N*`HID_DIM*`N_LEN-1:0] d,
    output wire valid,
    output wire [`N*`CHAR_NUM*`N_LEN-1:0] q,
    output reg  [ADDR_WIDTH-1:0] raddr,
    input  wire [DENSE_DATA_N*`N_LEN-1:0] rdata
  );


  // ----------------------------------------
  genvar i;

  // wire input/output buffer
  wire [`N-1:0] valid_buf;
  wire [`HID_DIM*`N_LEN-1:0]  d_buf [0:`N-1];
  wire [`CHAR_NUM*`N_LEN-1:0] q_buf [0:`N-1];

  
  // ----------------------------------------
  // assign valid
  assign valid = &valid_buf;

  generate
    for (i = 0; i < `N; i = i + 1) begin
      // convert shape (`N, `HID_DIM) <- (`N*`HID_DIM,)
      assign d_buf[i] = d[i*`HID_DIM*`N_LEN +: `HID_DIM*`N_LEN];
      
      // convert shape (`N, `CHAR_NUM) <- (`N*`CHAR_NUM,)
      assign q[i*`CHAR_NUM*`N_LEN +: `CHAR_NUM*`N_LEN] = q_buf[i];
    end
  endgenerate

  
  // ----------------------------------------
  // raddr controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      raddr <= 0;
    end else if (run) begin
      if (raddr != `HID_DIM*`CHAR_NUM/DENSE_DATA_N - 1) begin
        raddr <= raddr + 1;
      end 
    end else begin
      raddr <= 0;
    end
  end


  // ----------------------------------------
  // dense_forward_block
  generate
    for (i = 0; i < `N; i = i + 1) begin : dense_forward_block
      dense_forward_block #(
        .DENSE_DATA_N(DENSE_DATA_N)
      ) dense_forward_block_inst (
        .clk(clk),
        .rst_n(rst_n),
        .run(run),
        .d(d_buf[i]),
        .valid(valid_buf[i]),
        .q(q_buf[i]),
        .rdata(rdata)
      );
    end
  endgenerate


  


endmodule