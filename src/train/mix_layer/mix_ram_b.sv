`include "consts_train.vh"

module mix_ram_b #(
    parameter integer FILENUM = 0,
    parameter integer ADDR_WIDTH = 9,   // log2(3*`HID_DIM*`HID_DIM/`DATA_N) < 9
    parameter DATA_WIDTH = `N_LEN_W,
    parameter DATA_DEPTH = 3*`HID_DIM
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
    $readmemb($sformatf("../../data/parameter/train/binary18/mix_layer_b_1/mix_layer_b_1_%02d.txt", FILENUM), mem, 0*`HID_DIM, 1*`HID_DIM-1);
    $readmemb($sformatf("../../data/parameter/train/binary18/mix_layer_b_2/mix_layer_b_2_%02d.txt", FILENUM), mem, 1*`HID_DIM, 2*`HID_DIM-1);
    $readmemb($sformatf("../../data/parameter/train/binary18/mix_layer_b_3/mix_layer_b_3_%02d.txt", FILENUM), mem, 2*`HID_DIM, 3*`HID_DIM-1);
  end

endmodule