`include "consts_trained.vh"

module rom_w_core #(
    parameter filenum = 0
  ) (
    input  wire clk, 
    input  wire rst_n, 
    input  wire [`N_LEN-1:0] addr, 
    output reg  [`DATA_N*`N_LEN-1:0] output_weight
  );


(* ram_style = "block" *)
reg [`DATA_N*`N_LEN-1:0] mem [0:3*(`HID_DIM*`HID_DIM/`DATA_N)-1];


//要求されたアドレスに入っているデータを読み出してレジスタqに渡している。
always @(posedge clk) begin
  output_weight <= mem[addr];
end


//memというレジスタに重みを格納している
initial begin
  $readmemb($sformatf("../../data/parameter/trained/hard/binary96/mix_layer_W_1/mix_layer_W_1_%02d.txt", filenum), mem, 0*(`HID_DIM*`HID_DIM/`DATA_N), 1*(`HID_DIM*`HID_DIM/`DATA_N)-1);
  $readmemb($sformatf("../../data/parameter/trained/hard/binary96/mix_layer_W_2/mix_layer_W_2_%02d.txt", filenum), mem, 1*(`HID_DIM*`HID_DIM/`DATA_N), 2*(`HID_DIM*`HID_DIM/`DATA_N)-1);
  $readmemb($sformatf("../../data/parameter/trained/hard/binary96/mix_layer_W_3/mix_layer_W_3_%02d.txt", filenum), mem, 2*(`HID_DIM*`HID_DIM/`DATA_N), 3*(`HID_DIM*`HID_DIM/`DATA_N)-1);
end

endmodule