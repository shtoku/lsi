module rom #(
    parameter filenum = 0,
    parameter awidth = 11,
    parameter dwidth = 18,
    parameter words  = 1440
  ) (
    input wire clk,
    input wire [awidth - 1:0] addr,
    output reg [dwidth - 1:0] q
  );

  (* ram_style = "block" *)
  reg [dwidth - 1:0] mem [0:words - 1];

  always @(posedge clk) begin
    q <= mem[addr];
  end

  initial begin
    $readmemb($sformatf("weight18_%02d.txt", filenum), mem);
  end
  
endmodule