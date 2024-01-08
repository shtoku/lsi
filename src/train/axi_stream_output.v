`include "consts_train.vh"

module axi_stream_output (
    input  wire ACLK,
    input  wire ARESETN,

    // AXI Stream interface
    output wire [`CHAR_LEN-1:0] M_AXIS_TDATA,
    output wire M_AXIS_TLAST,
    output wire M_AXIS_TVALID,
    input  wire M_AXIS_TREADY,
    // AXI Stream interface end

    input  wire run,
    input  wire [`N*`CHAR_LEN-1:0] d,
    input  wire [`STATE_LEN-1:0] state,
    output wire valid
  );


  // ----------------------------------------
  genvar i;

  // wire fifo
  wire [`CHAR_LEN:0] fifo_data_w, fifo_data_r;
  wire fifo_we,    fifo_re;
  wire fifo_empty, fifo_full;

  // reg/wire write fifo controller
  reg  [3:0] count1;
  reg  [9:0] count2;
  wire [`CHAR_LEN-1:0] d_buf [0:`N-1];


  // ----------------------------------------
  // assign AXI Stream
  assign M_AXIS_TDATA  = fifo_data_r[`CHAR_LEN-1:0];
  assign M_AXIS_TLAST  = fifo_data_r[`CHAR_LEN];
  assign M_AXIS_TVALID = ~fifo_empty;

  // assign valid
  assign valid = (count1 == `N);

  // assign fifo_out
  assign fifo_data_w = {(count2 == `BATCH_SIZE*`N - 1), d_buf[count1]};
  assign fifo_we     = run & ~fifo_full & (count1 != `N);
  assign fifo_re     = M_AXIS_TVALID & M_AXIS_TREADY;

  // convert shape (N, CHAR_LEN) <- (N*CHAR_LEN, )
  generate
    for (i = 0; i < `N; i = i + 1) begin
      assign d_buf[i] = d[i*`CHAR_LEN +: `CHAR_LEN];
    end
  endgenerate


  // ----------------------------------------
  // write fifo controller
  always @(posedge ACLK, negedge ARESETN) begin
    if (~ARESETN) begin
      count1 <= 4'b0;
    end else if (fifo_we) begin
      count1 <= count1 + 1;
    end else if (run) begin
      count1 <= count1;
    end else begin
      count1 <= 4'b0;
    end
  end

  // 
  always @(posedge ACLK, negedge ARESETN) begin
    if (~ARESETN) begin
      count2 <= 4'b0;
    end else if (fifo_we) begin
      count2 <= count2 + 1;
    end else if (state == `M_FIN) begin
      count2 <= 4'b0;
    end else begin
      count2 <= count2;
    end
  end


  // ----------------------------------------
  // fifo instance
  fifo #(
    .WIDTH(1+`CHAR_LEN),
    .SIZE(1024),
    .LOG_SIZE(10)
  ) fifo_inst (
    .clk(ACLK),
    .rst_n(ARESETN),
    .data_w(fifo_data_w),
    .data_r(fifo_data_r),
    .we(fifo_we),
    .re(fifo_re),
    .empty(fifo_empty),
    .full(fifo_full)
  );
  
endmodule