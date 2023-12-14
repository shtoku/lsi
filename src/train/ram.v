module ram #(
    parameter FILENAME = "../data/parameter/train/binary108/emb_layer_W_emb.txt",
    parameter ADDR_WIDTH = 10,
    parameter DATA_WIDTH = 108,
    parameter DATA_DEPTH = 800
  ) (
    input  wire clk,
    input  wire load,
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire [DATA_WIDTH-1:0] d,
    output reg  [DATA_WIDTH-1:0] q
  );

  (* ram_style = "block" *)
  reg [DATA_WIDTH-1:0] mem [0:DATA_DEPTH-1];

  always @(posedge clk) begin
    q <= mem[addr];
    if (load)
      mem[addr] <= d;
  end

  initial begin
    $readmemb(FILENAME, mem);
  end
  
endmodule