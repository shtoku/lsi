`include "consts_trained.vh"

module axi_stream_input_tb ();
  reg  ACLK;
  reg  ARESETN;

  // AXI Stream interface
  reg  [`CHAR_LEN-1:0] S_AXIS_TDATA;
  reg  S_AXIS_TLAST;
  reg  S_AXIS_TVALID;
  wire S_AXIS_TREADY;
  // AXI Stream interface end

  reg  run;
  wire valid;
  wire [`N*`CHAR_LEN-1:0] q;

  axi_stream_input axi_stream_input_inst (.*);

  integer i;

  initial ACLK = 0;
  always #5 ACLK = ~ ACLK;

  initial begin
    $dumpvars;
    ARESETN=0; S_AXIS_TDATA=0; S_AXIS_TLAST=0; S_AXIS_TVALID=0; run=0; #10
    ARESETN=1; #10

    for (i = 0; i < `N-1; i = i + 1) begin
      S_AXIS_TDATA=`CHAR_LEN'h01; S_AXIS_TVALID=1; #10;
    end
    S_AXIS_TDATA=`CHAR_LEN'hff; S_AXIS_TLAST=1; #10
    S_AXIS_TLAST=0; S_AXIS_TVALID=0; #10
    #10
    run=1; #10
    wait(valid == 1); #5
    run=0; #10
    #30

    for (i = 0; i < `N-1; i = i + 1) begin
      S_AXIS_TDATA=`CHAR_LEN'h10; S_AXIS_TVALID=1; #10;
    end
    S_AXIS_TDATA=`CHAR_LEN'hee; S_AXIS_TLAST=1; #10
    S_AXIS_TLAST=0; S_AXIS_TVALID=0; #10
    #10
    run=1; #10
    wait(valid == 1); #5
    run=0; #10
    #30
    $finish;
  end
  

endmodule