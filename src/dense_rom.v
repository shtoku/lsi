`include "consts.vh"

module dense_rom #(
    parameter filename = "../data/parameter/hard/binary96/dense_layer_W_out.txt",
    parameter integer dwidth = `DATA_N*`N_LEN,//6*16,6個一緒に計算するため
    parameter integer awidth = 10,//800 < 2^10 
    parameter integer words = `HID_DIM/`DATA_N*`CHAR_NUM//24 / 6 * 200=800
  ) (
    input wire clk,
    input wire [awidth-1:0] addr,//800 < 2^10
    output reg [dwidth-1:0] q
  );

  (* ram_style = "block" *)
  reg [dwidth-1:0] mem [0:words-1];

  always @(posedge clk) begin
    q <= mem[addr];
  end

  initial begin
    $readmemb(filename, mem);
  end
  
endmodule