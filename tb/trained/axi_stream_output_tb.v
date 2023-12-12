`include "consts_trained.vh"

module axi_stream_output_tb ();
  reg  ACLK;
  reg  ARESETN;

  // AXI Stream interface
  wire [`CHAR_LEN-1:0] M_AXIS_TDATA;
  wire M_AXIS_TLAST;
  wire M_AXIS_TVALID;
  reg  M_AXIS_TREADY;
  // AXI Stream interface end

  reg  run;
  reg  [`N*`CHAR_LEN-1:0] d;
  wire valid;

  axi_stream_output axi_stream_output_inst (.*);

  integer i;

  initial ACLK = 0;
  always #5 ACLK = ~ ACLK;

  initial begin
    $dumpvars;
    ARESETN=0; M_AXIS_TREADY=0; run=0; d={`CHAR_LEN'hff, {(`N-1){`CHAR_LEN'h01}}}; #10
    ARESETN=1; #10
    run=1; #10
    wait(valid == 1); #5
    run=0; #10
    #10
    M_AXIS_TREADY=1; #10
    wait(M_AXIS_TLAST == 1); #5
    #30
    $finish;
  end
  

endmodule