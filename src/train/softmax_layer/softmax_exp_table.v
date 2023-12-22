`include "consts_train.vh"

module softmax_exp_table #(
    parameter integer D_I_LEN    = 4,     // d integer bit width
    parameter integer D_F_LEN    = 6,     // d fractional bit width
    parameter integer ADDR_WIDTH = 10     // D_I_LEN + D_F_LEN
  ) (
    input  wire clk,
    input  wire rst_n,
    input  wire [`N_LEN-1:0] d,
    output reg  [`N_LEN_W-1:0] q
  );


  // ----------------------------------------
  // reg d_delay
  reg [`N_LEN-1:0] d_delay1, d_delay2;

  // reg/wire exp_rom
  reg  [ADDR_WIDTH-1:0] raddr;
  wire [`N_LEN_W-1:0]   rdata;


  // ----------------------------------------
  // raddr controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      raddr <= 0;
    end else begin
      raddr <= d[(`F_LEN-D_F_LEN) +: ADDR_WIDTH];
    end
  end

  // d_delay
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      d_delay1 <= 0;
      d_delay2 <= 0;
    end else begin
      d_delay1 <= d;
      d_delay2 <= d_delay1;
    end
  end

  // output controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      q <= 0;
    end else begin
      if ($signed(d_delay2) < -1 * 2**(ADDR_WIDTH+`F_LEN-D_F_LEN))      // d < 11110000_0000000000000000 = -16
        q <= {`N_LEN_W{1'b0}};                                          // q =       00_0000000000000000 = 0
      else if (d_delay2 == {`N_LEN{1'b0}})                              // d = 00000000_0000000000000000 = 0
        q <= {`I_LEN_W'h1, {`F_LEN_W{1'b0}}};                           // q =       01_0000000000000000 = 1.0
      else                                                              // -16 < d
        q <= rdata;
    end
  end


  // ----------------------------------------
  // softmax_exp_rom
  rom #(
    .FILENAME("../../data/parameter/train/binary18/exp_table.txt"),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(`N_LEN_W),
    .DATA_DEPTH(2**ADDR_WIDTH)
  ) softmax_exp_rom (
    .clk(clk),
    .raddr(raddr),
    .rdata(rdata)
  );


endmodule