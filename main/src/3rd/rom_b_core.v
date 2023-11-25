`include "num_data.v"

module rom_b_core#(
    parameter filenum = 0
    )(
    input wire clk, 
    input wire rst_n, 
    input wire [15:0] addr, 
    output reg [`BIT_LENGTH-1:0] output_bias
);


(* ram_style = "block" *)
reg [`BIT_LENGTH-1:0] mem [0:24*3-1];


//要求されたアドレスに入っているデータを読み出してレジスタqに渡している。
always @(posedge clk) begin
    output_bias <= mem[addr];
end


initial begin
    $readmemb($sformatf("/home/hirahara/lsi_data/full_test/rom/mix_layer_b_1_%02d.txt", filenum), mem, 0, 23);
end

initial begin
    $readmemb($sformatf("/home/hirahara/lsi_data/full_test/rom/mix_layer_b_2_%02d.txt", filenum), mem, 24, 47);
end

initial begin
    $readmemb($sformatf("/home/hirahara/lsi_data/full_test/rom/mix_layer_b_3_%02d.txt", filenum), mem, 48, 71);
end

endmodule