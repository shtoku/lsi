`include "consts_train.vh"

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

  // debug port
  // reg  [`N*`CHAR_NUM*`N_LEN_W-1:0] d_backward_debug;

  top top_inst (.*);


  genvar i, j;
  integer l, m, n;
  parameter integer BATCH_NUM = 4;

  // send data mem
  reg  [`CHAR_LEN-1:0] d_forward_mem [0:BATCH_NUM*`BATCH_SIZE*`N-1];

  // receive data buffer
  reg  [`CHAR_LEN-1:0] q_forward_buf [0:`N-1];

  // debug mem
  // reg  [`N_LEN_W-1:0] d_backward_mem [0:BATCH_NUM*`BATCH_SIZE*`N*`CHAR_NUM-1];
  // reg  [`N*`CHAR_NUM*`N_LEN_W-1:0] d_backward_buf [0:BATCH_NUM*`BATCH_SIZE-1];

  reg  [`N_LEN-1:0] q_forward_mem [0:BATCH_NUM*`BATCH_SIZE*`N-1];
  wire [`N*`N_LEN-1:0] q_forward_ans [0:BATCH_NUM*`BATCH_SIZE-1];

  // reg  [`N_LEN-1:0] q_backward_mem [0:BATCH_NUM*`BATCH_SIZE*`HID_DIM*`HID_DIM-1];
  // wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] q_backward_ans [0:BATCH_NUM*`BATCH_SIZE-1];

  wire [BATCH_NUM*`BATCH_SIZE-1:0] correct_forward;
  // wire [BATCH_NUM*`BATCH_SIZE-1:0] correct_backward;

  // extract answer
  // wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] q_forward_ans_tmp;
  // wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] q_backward_ans_tmp;
  // assign q_forward_ans_tmp = q_forward_ans[4];
  // assign q_backward_ans_tmp = q_backward_ans[2];


  generate
    for (i = 0; i < BATCH_NUM*`BATCH_SIZE; i = i + 1) begin
      for (j = 0; j < `N; j = j + 1) begin
        assign q_forward_ans[i][j*`N_LEN +: `N_LEN] = q_forward_mem[i*`N + j];
      end
      assign correct_forward[i] = (q_forward_ans[i] == top_inst.comp_q);

      // for (j = 0; j < `N*`CHAR_NUM; j = j + 1) begin
      //   assign d_backward_buf[i][j*`N_LEN_W +: `N_LEN_W] = d_backward_mem[i*`N*`CHAR_NUM + j];
      // end
      // for (j = 0; j < `HID_DIM*`HID_DIM; j = j + 1) begin
      //   assign q_backward_ans[i][j*`N_LEN +: `N_LEN] = q_backward_mem[i*`HID_DIM*`HID_DIM + j];
      // end
      // assign correct_backward[i] = (q_backward_ans[i] == top_inst.mix_q_backward);
    end
  endgenerate


  // assign d_backward_debug = (top_inst.state_main == `M_S2) ? d_backward_buf[0] :
  //                           (top_inst.state_main == `M_S3) ? d_backward_buf[1] : d_backward_buf[0];


  initial begin
    $readmemb("../../data/tb/train/emb_layer/emb_layer_forward_in.txt", d_forward_mem);
    // $readmemb("../../data/tb/train/softmax_layer/softmax_layer_out.txt", d_backward_mem);
    $readmemb("../../data/tb/train/comp_layer/comp_layer_out.txt", q_forward_mem);
    // $readmemb("../../data/tb/train/mix_layer/mix_layer1_backward_out.txt", q_backward_mem);
  end


  initial ACLK = 0;
  always #5 ACLK = ~ACLK;

  initial begin
    $dumpvars;
    ARESETN=0;
    // AXI LITE Controller
    S_AXI_AWADDR=4'b0000; S_AXI_AWPROT=3'b000; S_AXI_AWVALID=0;
    S_AXI_WDATA=32'b0; S_AXI_WSTRB=4'b1111; S_AXI_WVALID=0;
    S_AXI_BREADY=1;
    S_AXI_ARADDR=4'b0000; S_AXI_ARPROT=3'b000; S_AXI_ARVALID=0;
    S_AXI_RREADY=0;
    // AXI Stream Controller (input/output)
    S_AXIS_TDATA=`CHAR_LEN'h00; S_AXIS_TLAST=0; S_AXIS_TVALID=0;
    M_AXIS_TREADY=0;
    #10;

    ARESETN=1; #10;

    // run TRAIN
    // write data to slv_reg1. mode=mode.
    write_slv(4'b0100, `TRAIN);
    #10;

    // write data to slv_reg0. next=0, set=1, run=0, rst_n=1.
    write_slv(4'b0000, 4'b0101);
    #20;

    send_data(0);
    #10;

    // write data to slv_reg0. next=0, set=0, run=1, rst_n=1.
    write_slv(4'b0000, 4'b0011);
    #10;

    // repeat l times.
    for (l = 1; l < BATCH_NUM - 1; l = l + 1) begin
      send_data(l);
      #10;

      wait_finish();
      #10;

      // write data to slv_reg0. next=1, set=0, run=0, rst_n=1.
      write_slv(4'b0000, 4'b1001);
      #10;

      // write data to slv_reg0. next=0, set=0, run=1, rst_n=1.
      write_slv(4'b0000, 4'b0011);
      #10;

      recieve_data();
      #10;
    end

    wait_finish();
    #10;

    recieve_data();
    #10;

    // check update
    send_data(l);
    #10;
    // write data to slv_reg0. next=1, set=0, run=0, rst_n=1.
    write_slv(4'b0000, 4'b1001);
    #10;
    run_mode(`FORWARD);
    #10;
    recieve_data();
    #30;

    // write data to slv_reg0. next=1, set=0, run=0, rst_n=1.
    write_slv(4'b0000, 4'b1001);
    #30;

    $finish;
  end

  task send_data;
    input integer m;
    begin
      // send data to AXI Stream Controller (input)
      for (n = 0; n < `BATCH_SIZE*`N-1; n = n + 1) begin
        S_AXIS_TDATA=d_forward_mem[m*`BATCH_SIZE*`N + n]; S_AXIS_TVALID=1; #10;
      end
      S_AXIS_TDATA=d_forward_mem[m*`BATCH_SIZE*`N + n]; S_AXIS_TLAST=1; #10;
      S_AXIS_TLAST=0; S_AXIS_TVALID=0;
    end
  endtask

  task write_slv;
    input [C_S_AXI_ADDR_WIDTH-1:0] addr;
    input [C_S_AXI_DATA_WIDTH-1:0] data;
    begin
      S_AXI_AWADDR=addr; S_AXI_AWVALID=1;
      S_AXI_WDATA=data; S_AXI_WVALID=1;
      #20;
      S_AXI_AWVALID=0;
      S_AXI_WVALID=0;
    end
  endtask

  task wait_finish;
    begin
      // read data from slv_reg2 and wait until finish==1.
      S_AXI_ARADDR=4'b1000; S_AXI_ARVALID=1;
      S_AXI_RREADY=1;
      #20;
      wait(S_AXI_RDATA[0] == 1) #5;
      S_AXI_ARVALID=0;
      S_AXI_RREADY=0;
    end
  endtask

  task run_mode;
    input [`MODE_LEN-1:0] mode;
    begin
      // write data to slv_reg1. mode=mode.
      write_slv(4'b0100, mode);
      #10;

      // write data to slv_reg0. next=0, set=1, run=0, rst_n=1.
      write_slv(4'b0000, 4'b0101);
      #20;

      // write data to slv_reg0. next=0, set=0, run=1, rst_n=1.
      write_slv(4'b0000, 4'b0011);
      #10;

      wait_finish();
      #10;
    end
  endtask

  task recieve_data;
    begin
      // recieve data from AXI Stream Controller (output)
      M_AXIS_TREADY=1;
      for (n = 0; M_AXIS_TLAST != 1; n = n + 1) begin
        q_forward_buf[n] = M_AXIS_TDATA; #10;
      end
      q_forward_buf[n] = M_AXIS_TDATA; #10;
      M_AXIS_TREADY=0;
    end
  endtask

endmodule