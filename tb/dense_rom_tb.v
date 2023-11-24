`include "../include/consts.vh"

module dense_rom_tb ();

  reg clk;
  reg [13 - 1:0] addr;
  wire [16 - 1:0] q;

  dense_rom #("../data/parameter/hard/binary16/dense_layer_W_out.txt") dense_rom_inst (clk, addr, q);
  //rom #(filename=$sformatf("../data/data18/weight18_%0d.txt", 0)) rom0 (clk, addr, q);

  initial clk = 0;
  always #50 clk = ~clk;

  initial begin
    $dumpvars;
    // temp = 0;
    // $display("a");
    // $sformat(temp, "%s%d", "ab", 1);
    // $display("%s", $sformatf("%d", 1));
    #51
    addr = 0; #100
    addr = 1; #100
    addr = 4799; #100
    #100
    $finish;
  end

endmodule