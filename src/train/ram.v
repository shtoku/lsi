module ram #(
    parameter FILENAME = "../../data/parameter/train/binary108/zeros_like_W_emb.txt",
    parameter ADDR_WIDTH = 10,
    parameter DATA_WIDTH = 108,
    parameter DATA_DEPTH = 800
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
    $readmemb(FILENAME, mem);
  end
  
endmodule