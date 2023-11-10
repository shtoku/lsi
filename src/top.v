`include "consts.vh"

module top # (
		// Width of S_AXI data bus
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		// Width of S_AXI address bus
		parameter integer C_S_AXI_ADDR_WIDTH	= 4
	) (
    // output for led
    output wire [3:0] led_out,

    // CLK and RESET
    input  wire ACLK,
    input  wire ARESETN,

    // AXI LITE interface
    input  wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		input  wire [2 : 0] S_AXI_AWPROT,
		input  wire  S_AXI_AWVALID,
		output wire  S_AXI_AWREADY,
		input  wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		input  wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		input  wire  S_AXI_WVALID,
		output wire  S_AXI_WREADY,
		output wire [1 : 0] S_AXI_BRESP,
		output wire  S_AXI_BVALID,
		input  wire  S_AXI_BREADY,
		input  wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		input  wire [2 : 0] S_AXI_ARPROT,
		input  wire  S_AXI_ARVALID,
		output wire  S_AXI_ARREADY,
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		output wire [1 : 0] S_AXI_RRESP,
		output wire  S_AXI_RVALID,
		input  wire  S_AXI_RREADY,
    // AXI LITE interface end

    // AXI Stream interface (input)
    input  wire [`CHAR_LEN-1:0] S_AXIS_TDATA,
    input  wire S_AXIS_TLAST,
    input  wire S_AXIS_TVALID,
    output wire S_AXIS_TREADY,
    // AXI Stream interface (input) end

    // AXI Stream interface (output)
    output wire [`CHAR_LEN-1:0] M_AXIS_TDATA,
    output wire M_AXIS_TLAST,
    output wire M_AXIS_TVALID,
    input  wire M_AXIS_TREADY
    // AXI Stream interface (output) end
  );


  // ----------------------------------------
  // wire AXI LITE Controller
  wire clk;
  wire rst_n;
  wire axi_lite_run;
  wire axi_lite_set;
  wire axi_lite_finish;
  wire [1:0] axi_lite_mode;

  // wire state machine
  wire state_run;
  wire state_set;
  wire [`STATE_LEN-1:0] state_d;
  wire [`STATE_LEN-1:0] state_q;

  // wire AXI Stream Controller (input)
  wire axis_in_run;
  wire axis_in_valid;
  wire [`N*`CHAR_LEN-1:0] axis_in_q;

  // wire AXI Stream Controller (output)
  wire axis_out_run;
  wire [`N*`CHAR_LEN-1:0] axis_out_d;
  wire axis_out_valid;


  // ----------------------------------------
  // assign AXI LITE Controller
  assign axi_lite_finish = (state_q == `FIN);

  // assign state machine
  assign state_run = (state_q == `IDLE) ? axi_lite_run   :
                     (state_q == `RECV) ? axis_in_valid  :
                     (state_q == `EMB ) ? 1'b1           :
                     (state_q == `MIX1) ? 1'b1           :
                     (state_q == `MIX2) ? 1'b1           :
                     (state_q == `MIX3) ? 1'b1           :
                     (state_q == `DENS) ? 1'b1           :
                     (state_q == `COMP) ? 1'b1           :
                     (state_q == `SEND) ? axis_out_valid :
                     (state_q == `FIN ) ? 1'b0           : 1'b0;
  assign state_set = axi_lite_set;
  assign state_d   = `IDLE;

  // assign AXI Stream Controller (input)
  assign axis_in_run = (state_q == `RECV);



  // assign AXI Stream Controller (output)
  assign axis_out_run = (state_q == `SEND);
  assign axis_out_d   = axis_in_q;

  
  // ----------------------------------------
  // AXI LITE Controller
  axi_lite_controller #(
    .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
  ) axi_lite_controller_inst (
		.clk(clk),
		.rst_n(rst_n),
		.run(axi_lite_run),
		.set(axi_lite_set),
    .finish(axi_lite_finish),
		.mode(axi_lite_mode),
		.led_out(led_out),
    .S_AXI_ACLK(ACLK),
    .S_AXI_ARESETN(ARESETN),
    .S_AXI_AWADDR(S_AXI_AWADDR),
		.S_AXI_AWPROT(S_AXI_AWPROT),
		.S_AXI_AWVALID(S_AXI_AWVALID),
		.S_AXI_AWREADY(S_AXI_AWREADY),
		.S_AXI_WDATA(S_AXI_WDATA),
		.S_AXI_WSTRB(S_AXI_WSTRB),
		.S_AXI_WVALID(S_AXI_WVALID),
		.S_AXI_WREADY(S_AXI_WREADY),
		.S_AXI_BRESP(S_AXI_BRESP),
		.S_AXI_BVALID(S_AXI_BVALID),
		.S_AXI_BREADY(S_AXI_BREADY),
		.S_AXI_ARADDR(S_AXI_ARADDR),
		.S_AXI_ARPROT(S_AXI_ARPROT),
		.S_AXI_ARVALID(S_AXI_ARVALID),
		.S_AXI_ARREADY(S_AXI_ARREADY),
		.S_AXI_RDATA(S_AXI_RDATA),
		.S_AXI_RRESP(S_AXI_RRESP),
		.S_AXI_RVALID(S_AXI_RVALID),
		.S_AXI_RREADY(S_AXI_RREADY)
  );

  // state machine
  state_machine state_machine_inst (
    .clk(clk),
    .rst_n(rst_n),
    .run(state_run),
    .set(state_set),
    .d(state_d),
    .q(state_q)
  );

  // AXI Stream Controller (input)
  axi_stream_input axi_stream_input_int (
    .ACLK(ACLK),
    .ARESETN(ARESETN),
    .S_AXIS_TDATA(S_AXIS_TDATA),
    .S_AXIS_TLAST(S_AXIS_TLAST),
    .S_AXIS_TVALID(S_AXIS_TVALID),
    .S_AXIS_TREADY(S_AXIS_TREADY),
    .run(axis_in_run),
    .valid(axis_in_valid),
    .q(axis_in_q)
  );



  // AXI Stream Controller (output)
  axi_stream_output axi_stream_output_inst (
    .ACLK(ACLK),
    .ARESETN(ARESETN),
    .M_AXIS_TDATA(M_AXIS_TDATA),
    .M_AXIS_TLAST(M_AXIS_TLAST),
    .M_AXIS_TVALID(M_AXIS_TVALID),
    .M_AXIS_TREADY(M_AXIS_TREADY),
    .run(axis_out_run),
    .d(axis_out_d),
    .valid(axis_out_valid)
  );



endmodule