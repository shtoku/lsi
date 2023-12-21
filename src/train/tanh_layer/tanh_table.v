`include "consts_train.vh"

module tanh_table #(
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

  // reg/wire tanh_rom
  reg  [ADDR_WIDTH-1:0] raddr;
  wire [`N_LEN_W-1:0]   rdata;


  // ----------------------------------------


  // ----------------------------------------
  // raddr controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      raddr <= 0;
    end else begin
      raddr <= d[(`F_LEN-D_F_LEN) +: ADDR_WIDTH] + 2**(ADDR_WIDTH-1);
    end
  end

  // d_delay
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      d_delay1 <= 0;
      d_delay2 <= 0;
    end else begin
      d_delay1 <= d;
      d_delay2 <= d_delay2;
    end
  end

  // output controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      q <= 0;
    end else begin
      if ($signed(d_delay2) < -2**(ADDR_WIDTH-1) * 2**(`F_LEN-D_F_LEN))             // d < 11111000_0000000000000000 = -8
        q <= {{`I_LEN_W{1'b1}}, {`F_LEN_W{1'b0}}};                                  // q =       11_0000000000000000 = -1.0
      else if ($signed(d_delay2) > (2**(ADDR_WIDTH-1) - 1) * 2**(`F_LEN-D_F_LEN))   // d > 00000111_1111110000000000 = 7.984375 ~= 8
        q <= {{`I_LEN_W{1'b1}}, {`F_LEN_W{1'b0}}};                                  // q =       01_0000000000000000 = 1.0
      else                                                                          // -8 < d < 7.984375 ~= 8
        q <= rdata;
    end
  end


  // ----------------------------------------
  // tanh_rom
  rom #(
    .FILENAME("../../data/parameter/train/binary18/tanh_table.txt"),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(`N_LEN_W),
    .DATA_DEPTH(2**ADDR_WIDTH)
  ) tanh_rom (
    .clk(clk),
    .raddr(raddr),
    .rdata(rdata)
  );


endmodule