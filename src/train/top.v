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
    input  wire M_AXIS_TREADY
    // AXI Stream interface (output) end
  );


  // ----------------------------------------
  // wire load_backward, update, zero_grad
  wire load_backward;
  wire update, zero_grad;
  wire [2:0] valid_update, valid_zero_grad;

  // wire AXI LITE Controller
  wire clk;
  wire rst_n;
  wire run;
  wire set;
  wire next;
  wire [2:0] finish;
  wire [`MODE_LEN-1:0] mode;

  // wire state_main
  wire state_main_run;
  wire [`STATE_LEN-1:0] state_main;

  // wire state_forward
  wire state_forward_run;
  wire [`STATE_LEN-1:0] state_forward_d;
  wire [`STATE_LEN-1:0] state_forward;

  // wire state_backward
  wire state_backward_run;
  wire [`STATE_LEN-1:0] state_backward;

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

  // wire forward_mix_input
  wire [`N*`EMB_DIM*`N_LEN_W-1:0] forward_mix_in_d_emb;
  wire [`HID_DIM*`HID_DIM*`N_LEN_W-1:0] forward_mix_in_d_tanh;
  wire forward_mix_in_valid;
  wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] forward_mix_in_q;

  // wire mix_layer
  wire mix_run_forward;
  reg  mix_run_backward;
  wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] mix_d_forward, mix_d_backward;
  wire mix_valid_forward, mix_valid_backward;
  wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] mix_q_forward, mix_q_backward;

  // wire tanh_layer
  wire tanh_run_forward, tanh_run_backward;
  wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] tanh_d_forward, tanh_d_backward;
  wire tanh_valid_forward, tanh_valid_backward;
  wire [`HID_DIM*`HID_DIM*`N_LEN_W-1:0] tanh_q_forward;
  wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] tanh_q_backward;

  // wire backward_tanh_input
  wire backward_tanh_in_run;
  wire [`N*`HID_DIM*`N_LEN-1:0] backward_tanh_in_d_dense;
  wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] backward_tanh_in_d_mix;
  wire backward_tanh_in_valid;
  wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] backward_tanh_in_q;

  // wire dense_layer
  wire dense_run_forward, dense_run_backward;
  wire [`N*`HID_DIM*`N_LEN_W-1:0] dense_d_forward;
  wire [`N*`CHAR_NUM*`N_LEN_W-1:0] dense_d_backward;
  wire dense_valid_forward, dense_valid_backward;
  wire [`N*`CHAR_NUM*`N_LEN-1:0] dense_q_forward;
  wire [`N*`HID_DIM*`N_LEN-1:0]  dense_q_backward;

  // wire comp_layer
  wire comp_run;
  wire [`N*`CHAR_NUM*`N_LEN-1:0] comp_d;
  wire comp_valid;
  wire [`N*`CHAR_LEN-1:0] comp_num;
  wire [`N*`N_LEN-1:0] comp_q;

  // wire softmax_layer
  wire smax_run;
  wire [`N*`CHAR_NUM*`N_LEN-1:0] smax_d;
  wire [`N*`CHAR_LEN-1:0] smax_d_num;
  wire [`N*`N_LEN-1:0] smax_d_max;
  wire smax_valid;
  wire [`N*`CHAR_NUM*`N_LEN_W-1:0] smax_q;  

  // wire AXI Stream Controller (output)
  wire axis_out_run;
  wire [`N*`CHAR_LEN-1:0] axis_out_d;
  wire axis_out_valid;


  // ----------------------------------------
  // assign load_backward, update, zero_grad
  assign load_backward = state_main_run;
  assign update        = (state_main == `M_UPDATE);
  assign zero_grad     = (state_main == `M_S1);

  // assign AXI LITE Controller
  assign finish = {(state_backward == `B_FIN), (state_forward  == `F_FIN), (state_main == `M_FIN)};

  // assign state_main
  assign state_main_run = (state_main == `M_IDLE)   ? run :
                          (state_main == `M_S1)     ? (state_forward  == `F_FIN) & (&valid_zero_grad):
                          (state_main == `M_S2)     ? (state_forward  == `F_FIN) & (state_backward == `B_FIN) :
                          (state_main == `M_S3)     ? (state_backward == `B_FIN) :
                          (state_main == `M_UPDATE) ? (&valid_update) :
                          (state_main == `M_FIN)    ? next : 1'b0;

  // assign state_forward
  assign state_forward_run = (state_forward == `F_IDLE)  ? (state_main == `M_S1 | state_main == `M_S2) :
                             (state_forward == `F_RECV)  ?       axis_in_valid :
                             (state_forward == `F_EMB)   ?   emb_valid_forward :
                             (state_forward == `F_MIX1)  ?   mix_valid_forward :
                             (state_forward == `F_TANH1) ?  tanh_valid_forward :
                             (state_forward == `F_MIX2)  ?   mix_valid_forward :
                             (state_forward == `F_TANH2) ?  tanh_valid_forward :
                             (state_forward == `F_MIX3)  ?   mix_valid_forward :
                             (state_forward == `F_TANH3) ?  tanh_valid_forward :
                             (state_forward == `F_DENS)  ? dense_valid_forward :
                             (state_forward == `F_COMP)  ?          comp_valid :
                             (state_forward == `F_SEND)  ?      axis_out_valid :
                             (state_forward == `F_FIN)   ?      state_main_run : 1'b0;
  assign state_forward_d   = (mode == `TRAIN )   ? `F_IDLE :
                             (mode == `FORWARD)  ? `F_IDLE :
                             (mode == `GEN_SIMI) ? `F_IDLE :
                             (mode == `GEN_NEW ) ? `F_MIX3 : `F_IDLE;
  
  // assign state_backward
  assign state_backward_run = (state_backward == `B_IDLE)  ? (state_main == `M_S2 | state_main == `M_S3) :
                              (state_backward == `B_SMAX)  ?           smax_valid :
                              (state_backward == `B_DENS)  ? dense_valid_backward :
                              (state_backward == `B_TANH3) ?  tanh_valid_backward :
                              (state_backward == `B_MIX3)  ?   mix_valid_backward :
                              (state_backward == `B_TANH2) ?  tanh_valid_backward :
                              (state_backward == `B_MIX2)  ?   mix_valid_backward :
                              (state_backward == `B_TANH1) ?  tanh_valid_backward :
                              (state_backward == `B_MIX1)  ?   mix_valid_backward :
                              (state_backward == `B_EMB)   ?   emb_valid_backward :
                              (state_backward == `B_FIN)   ?       state_main_run : 1'b0;

  // assign AXI Stream Controller (input)
  assign axis_in_run = (state_forward == `F_RECV);

  // assign emb_layer
  assign emb_run_forward  = (state_forward  == `F_EMB);
  assign emb_run_backward = (state_backward == `B_EMB);
  assign emb_d_forward    = axis_in_q;
  assign emb_d_backward   = mix_q_backward;

  // assign forward_mix_input
  assign forward_mix_in_d_emb = emb_q_forward;
  assign forward_mix_in_d_tanh = tanh_q_forward;

  // assign mix_layer
  assign mix_run_forward  = forward_mix_in_valid;
  assign mix_d_forward    = forward_mix_in_q;
  assign mix_d_backward   = tanh_q_backward;

  // assign tanh_layer
  assign tanh_run_forward  = (state_forward  == `F_TANH1) | (state_forward  == `F_TANH2) | (state_forward  == `F_TANH3);
  assign tanh_run_backward = backward_tanh_in_valid;
  assign tanh_d_forward    = mix_q_forward;
  assign tanh_d_backward   = backward_tanh_in_q;

  // assign backward_tanh_input
  assign backward_tanh_in_run     = (state_backward == `B_TANH1) | (state_backward == `B_TANH2) | (state_backward == `B_TANH3);
  assign backward_tanh_in_d_dense = dense_q_backward;
  assign backward_tanh_in_d_mix   = mix_q_backward;

  // assign dense_layer
  assign dense_run_forward  = (state_forward  == `F_DENS);
  assign dense_run_backward = (state_backward == `B_DENS);
  assign dense_d_forward    = tanh_q_forward[`N*`HID_DIM*`N_LEN_W-1:0];
  assign dense_d_backward   = smax_q;

  // assign comp_layer
  assign comp_run = (state_forward == `F_COMP);
  assign comp_d   = dense_q_forward;

  // assign softmax_lawe
  assign smax_run   = (state_backward == `B_SMAX);
  assign smax_d     = dense_q_forward;
  assign smax_d_num = axis_in_q;
  assign smax_d_max = comp_q;  

  // assign AXI Stream Controller (output)
  assign axis_out_run = (state_forward == `F_SEND);
  assign axis_out_d   = comp_num;


  // ----------------------------------------
  // mix_run_backward controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      mix_run_backward <= 0;
    end else begin
      mix_run_backward <= (state_backward == `B_MIX1) | (state_backward == `B_MIX2) | (state_backward == `B_MIX3);
    end
  end


  // ----------------------------------------
  // AXI LITE Controller
  axi_lite_controller #(
    .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
    .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
  ) axi_lite_controller_inst (
    .clk(clk),
    .rst_n(rst_n),
    .run(run),
    .set(set),
    .next(next),
    .finish(finish),
    .mode(mode),
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
    .mode(mode),
    .q(state_main)
  );

  // state_forward
  state_forward state_forward_inst (
    .clk(clk),
    .rst_n(rst_n),
    .run(state_forward_run),
    .set(set),
    .d(state_forward_d),
    .q(state_forward)
  );

  // state_backward
  state_backward state_backward_inst (
    .clk(clk),
    .rst_n(rst_n),
    .run(state_backward_run),
    .q(state_backward)
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
    .valid_update(valid_update[0]),
    .valid_zero_grad(valid_zero_grad[0]),
    .valid_forward(emb_valid_forward),
    .valid_backward(emb_valid_backward),
    .q_forward(emb_q_forward)
  );

  // forward_mix_input
  forward_mix_input forward_mix_input_inst (
    .clk(clk),
    .rst_n(rst_n),
    .state(state_forward),
    .mode(mode),
    .d_emb(forward_mix_in_d_emb),
    .d_tanh(forward_mix_in_d_tanh),
    .valid(forward_mix_in_valid),
    .q(forward_mix_in_q)
  );

  // mix_layer
  mix_layer mix_layer_inst (
    .clk(clk),
    .rst_n(rst_n),
    .update(update),
    .zero_grad(zero_grad),
    .run_forward(mix_run_forward),
    .run_backward(mix_run_backward),
    .load_backward(load_backward),
    .state_forward(state_forward),
    .state_backward(state_backward),
    .d_forward(mix_d_forward),
    .d_backward(mix_d_backward),
    .valid_update(valid_update[1]),
    .valid_zero_grad(valid_zero_grad[1]),
    .valid_forward(mix_valid_forward),
    .valid_backward(mix_valid_backward),
    .q_forward(mix_q_forward),
    .q_backward(mix_q_backward)
  );

  // tanh_layer
  tanh_layer tanh_layer_inst (
    .clk(clk),
    .rst_n(rst_n),
    .run_forward(tanh_run_forward),
    .run_backward(tanh_run_backward),
    .load_backward(load_backward),
    .state_forward(state_forward),
    .state_backward(state_backward),
    .d_forward(tanh_d_forward),
    .d_backward(tanh_d_backward),
    .valid_forward(tanh_valid_forward),
    .valid_backward(tanh_valid_backward),
    .q_forward(tanh_q_forward),
    .q_backward(tanh_q_backward)
  );

  // backward_tanh_input
  backward_tanh_input backward_tanh_input_inst (
    .clk(clk),
    .rst_n(rst_n),
    .run(backward_tanh_in_run),
    .state(state_backward),
    .d_dense(backward_tanh_in_d_dense),
    .d_mix(backward_tanh_in_d_mix),
    .valid(backward_tanh_in_valid),
    .q(backward_tanh_in_q)
  );

  // dense_layer
  dense_layer dense_layer_inst (
    .clk(clk),
    .rst_n(rst_n),
    .update(update),
    .zero_grad(zero_grad),
    .run_forward(dense_run_forward),
    .run_backward(dense_run_backward),
    .load_backward(load_backward),
    .d_forward(dense_d_forward),
    .d_backward(dense_d_backward),
    .valid_update(valid_update[2]),
    .valid_zero_grad(valid_zero_grad[2]),
    .valid_forward(dense_valid_forward),
    .valid_backward(dense_valid_backward),
    .q_forward(dense_q_forward),
    .q_backward(dense_q_backward)
  );

  // comp_layer
  comp_layer comp_layer_inst (
    .clk(clk),
    .rst_n(rst_n),
    .run(comp_run),
    .d(comp_d),
    .valid(comp_valid),
    .num(comp_num),
    .q(comp_q)
  );

  // softmax_layer
  softmax_layer softmax_layer_inst (
    .clk(clk),
    .rst_n(rst_n),
    .run(smax_run),
    .load_d_num(load_backward),
    .d(smax_d),
    .d_num(smax_d_num),
    .d_max(smax_d_max),
    .valid(smax_valid),
    .q(smax_q)
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