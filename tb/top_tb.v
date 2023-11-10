`include "consts.vh"

module top_tb ();
  // Width of S_AXI data bus
  parameter integer C_S_AXI_DATA_WIDTH	= 32;
  // Width of S_AXI address bus
  parameter integer C_S_AXI_ADDR_WIDTH	= 4;

  // output for led
  wire [3:0] led_out;

  // CLK and RESET
  reg  ACLK;
  reg  ARESETN;

  // AXI LITE interface
  reg  [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR;
  reg  [2 : 0] S_AXI_AWPROT;
  reg   S_AXI_AWVALID;
  wire  S_AXI_AWREADY;
  reg  [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA;
  reg  [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB;
  reg   S_AXI_WVALID;
  wire  S_AXI_WREADY;
  wire [1 : 0] S_AXI_BRESP;
  wire  S_AXI_BVALID;
  reg   S_AXI_BREADY;
  reg  [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR;
  reg  [2 : 0] S_AXI_ARPROT;
  reg   S_AXI_ARVALID;
  wire  S_AXI_ARREADY;
  wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA;
  wire [1 : 0] S_AXI_RRESP;
  wire  S_AXI_RVALID;
  reg   S_AXI_RREADY;
  // AXI LITE interface end

  // AXI Stream interface (input)
  reg  [`CHAR_LEN-1:0] S_AXIS_TDATA;
  reg  S_AXIS_TLAST;
  reg  S_AXIS_TVALID;
  wire S_AXIS_TREADY;
  // AXI Stream interface (input) end

  // AXI Stream interface (output)
  wire [`CHAR_LEN-1:0] M_AXIS_TDATA;
  wire M_AXIS_TLAST;
  wire M_AXIS_TVALID;
  reg  M_AXIS_TREADY;
  // AXI Stream interface (output) end

  top top_inst (.*);

  integer i;

  initial ACLK = 0;
  always #5 ACLK = ~ACLK;

  initial begin
    $dumpvars;
    ARESETN=0;
    // AXI LITE Controller
    S_AXI_AWADDR=4'b0000; S_AXI_AWPROT=3'b000; S_AXI_AWVALID=0;
    S_AXI_WDATA=32'b0; S_AXI_WSTRB=4'b1111; S_AXI_WVALID=0;
    S_AXI_BREADY=0;
    S_AXI_ARADDR=4'b0000; S_AXI_ARPROT=3'b000; S_AXI_ARVALID=0;
    S_AXI_RREADY=0;
    // AXI Stream Controller (input/output)
    S_AXIS_TDATA=`CHAR_LEN'h00; S_AXIS_TLAST=0; S_AXIS_TVALID=0;
    M_AXIS_TREADY=0;
    #10

    ARESETN=1; #10

    // send data to AXI Stream Controller (input)
    for (i = 0; i < `N-1; i = i + 1) begin
      S_AXIS_TDATA=`CHAR_LEN'h01; S_AXIS_TVALID=1; #10;
    end
    S_AXIS_TDATA=`CHAR_LEN'hff; S_AXIS_TLAST=1; #10
    S_AXIS_TLAST=0; S_AXIS_TVALID=0; #10
    #10

    // write data to slv_reg0. rst_n=1, run=1.
    S_AXI_AWADDR=4'b0000; S_AXI_AWVALID=1;
    S_AXI_WDATA=32'h00000003; S_AXI_WVALID=1;
    #20
    S_AXI_AWVALID=0;
    S_AXI_WVALID=0;
    #10

    // read data from slv_reg2 and wait until finish==1.
    S_AXI_ARADDR=4'b1000; S_AXI_ARVALID=1;
    S_AXI_RREADY=1;
    wait(S_AXI_RDATA[0] == 1) #5
    S_AXI_ARVALID=0;
    S_AXI_RREADY=0;
    #10

    // recieve data from AXI Stream Controller (output)
    M_AXIS_TREADY=1; #10
    wait(M_AXIS_TLAST == 1); #5
    #30   

    $finish;
  end

endmodule