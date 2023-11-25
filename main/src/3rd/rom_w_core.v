`include "num_data.v"

module rom_w_core #(
    parameter filenum = 0
    )(
    input wire clk, 
    input wire rst_n, 
    input wire [15:0] addr, 
    output reg [`BIT_LENGTH*`DATA_N-1:0] output_weight
);


(* ram_style = "block" *)
reg [`BIT_LENGTH*`DATA_N-1:0] mem [0:`DATA_ALL*3-1];


//要求されたアドレスに入っているデータを読み出してレジスタqに渡している。
always @(posedge clk) begin
    output_weight <= mem[addr];
end


//memというレジスタに重みを格納している
initial begin
    $readmemb($sformatf("/home/hirahara/lsi_data/full_test/rom/mix_layer_W_1_%02d.txt", filenum), mem, 0, 95);
end

initial begin
    $readmemb($sformatf("/home/hirahara/lsi_data/full_test/rom/mix_layer_W_2_%02d.txt", filenum), mem, 96, 191);
end

initial begin
    $readmemb($sformatf("/home/hirahara/lsi_data/full_test/rom/mix_layer_W_3_%02d.txt", filenum), mem, 192, 287);
end

endmodule