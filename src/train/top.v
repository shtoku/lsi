`include "consts_train.vh"

module top # (
    // Width of S_AXI data bus
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    // Width of S_AXI address bus
    parameter integer C_S_AXI_ADDR_WIDTH = 4
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
    input  wire M_AXIS_TREADY,
    // AXI Stream interface (output) end

    // debug port
    input  wire [`N*`EMB_DIM*`N_LEN-1:0] d_backward_debug
  );


  // ----------------------------------------
  // wire load_backward, update, zero_grad
  wire load_backward;
  wire update, zero_grad;
  wire valid_update, valid_zero_grad;

  // wire AXI LITE Controller
  wire clk;
  wire rst_n;
  wire axi_lite_run;
  wire axi_lite_set;
  wire axi_lite_next;
  wire [2:0] axi_lite_finish;
  wire [`MODE_LEN-1:0] axi_lite_mode;

  // wire state_main
  wire state_main_run;
  wire [`MODE_LEN-1:0] state_main_mode;
  wire [`STATE_LEN-1:0] state_main_q;

  // wire state_forward
  wire state_forward_run;
  wire state_forward_set;
  wire [`STATE_LEN-1:0] state_forward_d;
  wire [`STATE_LEN-1:0] state_forward_q;

  // wire state_backward
  wire state_backward_run;
  wire [`STATE_LEN-1:0] state_backward_q;

  // wire AXI Stream Controller (input)
  wire axis_in_run;
  wire axis_in_valid;
  wire [`N*`CHAR_LEN-1:0] axis_in_q;

  // wire emb_layer
  wire emb_run_forward, emb_run_backward;
  wire [`N*`CHAR_LEN-1:0] emb_d_forward;
  wire [`N*`EMB_DIM*`N_LEN-1:0] emb_d_backward;
  wire emb_valid_forward, emb_valid_backward;
  wire [`N*`EMB_DIM*`N_LEN_W-1:0] emb_q_forward;


  

  // wire AXI Stream Controller (output)
  wire axis_out_run;
  wire [`N*`CHAR_LEN-1:0] axis_out_d;
  wire axis_out_valid;


  // ----------------------------------------
  // assign load_backward, update, zero_grad
  assign load_backward = state_main_run;
  assign update        = (state_main_q == `M_UPDATE);
  assign zero_grad     = (state_main_q == `M_S1);

  // assign AXI LITE Controller
  assign axi_lite_finish = {(state_backward_q == `B_FIN), (state_forward_q  == `F_FIN), (state_main_q == `M_FIN)};

  // assign state_main
  assign state_main_run = (state_main_q == `M_IDLE)   ? axi_lite_run :
                          (state_main_q == `M_S1)     ? (state_forward_q  == `F_FIN) & (&valid_zero_grad):
                          (state_main_q == `M_S2)     ? (state_forward_q  == `F_FIN) & (state_backward_q == `B_FIN) :
                          (state_main_q == `M_S3)     ? (state_backward_q == `B_FIN) :
                          (state_main_q == `M_UPDATE) ? (&valid_update) :
                          (state_main_q == `M_FIN)    ? axi_lite_next : 1'b0;
  assign state_main_mode = axi_lite_mode;

  // assign state_forward
  assign state_forward_run = (state_forward_q == `F_IDLE)  ? (state_main_q == `M_S1 | state_main_q == `M_S2) :
                             (state_forward_q == `F_RECV)  ? axis_in_valid :
                             (state_forward_q == `F_EMB)   ? emb_valid_forward :
                             (state_forward_q == `F_MIX1)  ? 1'b1 :
                             (state_forward_q == `F_TANH1) ? 1'b1 :
                             (state_forward_q == `F_MIX2)  ? 1'b1 :
                             (state_forward_q == `F_TANH2) ? 1'b1 :
                             (state_forward_q == `F_MIX3)  ? 1'b1 :
                             (state_forward_q == `F_TANH3) ? 1'b1 :
                             (state_forward_q == `F_DENS)  ? 1'b1 :
                             (state_forward_q == `F_COMP)  ? 1'b1 :
                             (state_forward_q == `F_SEND)  ? axis_out_valid :
                             (state_forward_q == `F_FIN)  ? state_main_run : 1'b0;
  assign state_forward_set = axi_lite_set;
  assign state_forward_d   = (axi_lite_mode == `TRAIN )   ? `F_IDLE :
                             (axi_lite_mode == `FORWARD)  ? `F_IDLE :
                             (axi_lite_mode == `GEN_SIMI) ? `F_IDLE :
                             (axi_lite_mode == `GEN_NEW ) ? `F_MIX3 : `F_IDLE;
  
  // assign state_backward
  assign state_backward_run = (state_backward_q == `B_IDLE)  ? (state_main_q == `M_S2 | state_main_q == `M_S3) :
                              (state_backward_q == `B_SMAX)  ? 1'b1 :
                              (state_backward_q == `B_DENS)  ? 1'b1 :
                              (state_backward_q == `B_TANH3) ? 1'b1 :
                              (state_backward_q == `B_MIX3)  ? 1'b1 :
                              (state_backward_q == `B_TANH2) ? 1'b1 :
                              (state_backward_q == `B_MIX2)  ? 1'b1 :
                              (state_backward_q == `B_TANH1) ? 1'b1 :
                              (state_backward_q == `B_MIX1)  ? 1'b1 :
                              (state_backward_q == `B_EMB)   ? emb_valid_backward :
                              (state_backward_q == `B_FIN)   ? state_main_run : 1'b0;

  // assign AXI Stream Controller (input)
  assign axis_in_run = (state_forward_q == `F_RECV);

  // assign emb_layer
  assign emb_run_forward  = (state_forward_q  == `F_EMB);
  assign emb_run_backward = (state_backward_q == `B_EMB);
  assign emb_d_forward    = axis_in_q;
  assign emb_d_backward   = d_backward_debug;


  

  // assign AXI Stream Controller (output)
  assign axis_out_run = (state_forward_q == `F_SEND);
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
    .next(axi_lite_next),
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

  // state_main
  state_main state_main_inst (
    .clk(clk),
    .rst_n(rst_n),
    .run(state_main_run),
    .mode(state_main_mode),
    .q(state_main_q)
  );

  // state_forward
  state_forward state_forward_inst (
    .clk(clk),
    .rst_n(rst_n),
    .run(state_forward_run),
    .set(state_forward_set),
    .d(state_forward_d),
    .q(state_forward_q)
  );

  // state_backward
  state_backward state_backward_inst (
    .clk(clk),
    .rst_n(rst_n),
    .run(state_backward_run),
    .q(state_backward_q)
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

  // emb_layer
  emb_layer emb_layer_inst (
    .clk(clk),
    .rst_n(rst_n),
    .update(update),
    .zero_grad(zero_grad),
    .run_forward(emb_run_forward),
    .run_backward(emb_run_backward),
    .load_backward(load_backward),
    .d_forward(emb_d_forward),
    .d_backward(emb_d_backward),
    .valid_update(valid_update),
    .valid_zero_grad(valid_zero_grad),
    .valid_forward(emb_valid_forward),
    .valid_backward(emb_valid_backward),
    .q_forward(emb_q_forward)
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