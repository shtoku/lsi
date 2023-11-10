module rom_tb ();

  parameter awidth = 11;
  parameter dwidth = 18;
  parameter words  = 1440;

  reg  clk;
  reg  [awidth - 1:0] addr [0:1];
  wire [dwidth - 1:0] q [0:1];
  
  generate
    genvar i;
    for (i = 0; i < 2; i = i + 1) begin
      rom #(
        .filenum(i)
      ) rom_inst (
        .clk(clk),
        .addr(addr[i]),
        .q(q[i])
      );
    end
    
  endgenerate

  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    $dumpvars;
    addr[0]=0; addr[1]=0; #10
    addr[0]=1; addr[1]=1; #10
    addr[0]=2; addr[1]=6; #10
    addr[0]=3; addr[1]=9; #10
    #10
    $finish;
  end
  
endmodule