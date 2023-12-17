`include "consts_train.vh"

module mix_ram_wt #(
    parameter integer FILENUM = 0,
    parameter integer ADDR_WIDTH = 9,   // log2(3*`HID_DIM*`HID_DIM/`DATA_N) < 9
    parameter DATA_WIDTH = `DATA_N*`N_LEN_W,
    parameter DATA_DEPTH = 3*`HID_DIM*`HID_DIM/`DATA_N
  ) (
    input  wire clk, 
    input  wire load,
    input  wire [ADDR_WIDTH-1:0] waddr,
    input  wire [DATA_WIDTH-1:0] wdata,
    input  wire [ADDR_WIDTH-1:0] raddr,
    output reg  [DATA_WIDTH-1:0] rdata
  );


  (* ram_style = "block" *)
  reg [DATA_WIDTH-1:0] mem [0:DATA_DEPTH-1];

  always @(posedge clk) begin
    rdata <= mem[raddr];
    if (load)
      mem[waddr] <= wdata;
  end

  initial begin
    $readmemb($sformatf("../../data/parameter/train/binary108/mix_layer_W_1/mix_layer_W_1_T_%02d.txt", FILENUM), mem, 0*(`HID_DIM*`HID_DIM/`DATA_N), 1*(`HID_DIM*`HID_DIM/`DATA_N)-1);
    $readmemb($sformatf("../../data/parameter/train/binary108/mix_layer_W_2/mix_layer_W_2_T_%02d.txt", FILENUM), mem, 1*(`HID_DIM*`HID_DIM/`DATA_N), 2*(`HID_DIM*`HID_DIM/`DATA_N)-1);
    $readmemb($sformatf("../../data/parameter/train/binary108/mix_layer_W_3/mix_layer_W_3_T_%02d.txt", FILENUM), mem, 2*(`HID_DIM*`HID_DIM/`DATA_N), 3*(`HID_DIM*`HID_DIM/`DATA_N)-1);
  end

endmodule