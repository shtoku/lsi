`include "consts.vh"

module rom_b_core#(
    parameter filenum = 0
  ) (
    input wire clk, 
    input wire rst_n, 
    input wire [`N_LEN-1:0] addr, 
    output reg [`N_LEN-1:0] output_bias
  );


  (* ram_style = "block" *)
  reg [`N_LEN-1:0] mem [0:3*`HID_DIM-1];


  //要求されたアドレスに入っているデータを読み出してレジスタqに渡している。
  always @(posedge clk) begin
    output_bias <= mem[addr];
  end


  initial begin
    $readmemb($sformatf("../data/parameter/trained/hard/binary16/mix_layer_b_1/mix_layer_b_1_%02d.txt", filenum), mem, 0*`HID_DIM, 1*`HID_DIM-1);
    $readmemb($sformatf("../data/parameter/trained/hard/binary16/mix_layer_b_2/mix_layer_b_2_%02d.txt", filenum), mem, 1*`HID_DIM, 2*`HID_DIM-1);
    $readmemb($sformatf("../data/parameter/trained/hard/binary16/mix_layer_b_3/mix_layer_b_3_%02d.txt", filenum), mem, 2*`HID_DIM, 3*`HID_DIM-1);
  end

endmodule