`include "consts.vh"

module emb_rom #(
    parameter filename = "../data/parameter/hard/binary/emb_layer_W_emb.txt",
    parameter integer dwidth = `N_LEN,//consts needs `,16
    parameter integer awidth = 13,
    parameter integer words = `EMB_DIM*`CHAR_NUM//24*200=4800
  ) (
    input wire clk,
    input wire [awidth-1:0] addr,//4800<2^13
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