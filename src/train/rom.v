module rom #(
    parameter FILENAME = "../../data/parameter/train/binary18/tanh_table.txt",
    parameter ADDR_WIDTH = 10,
    parameter DATA_WIDTH = 18,
    parameter DATA_DEPTH = 1024
  ) (
    input  wire clk,
    input  wire [ADDR_WIDTH-1:0] raddr,
    output reg  [DATA_WIDTH-1:0] rdata
  );

  (* ram_style = "block" *)
  reg [DATA_WIDTH-1:0] mem [0:DATA_DEPTH-1];

  always @(posedge clk) begin
    rdata <= mem[raddr];
  end

  initial begin
    $readmemb(FILENAME, mem);
  end
  
endmodule