`include "consts.vh"

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
    output wire valid
  );


  // ----------------------------------------
  genvar i;

  // wire fifo
  wire [`CHAR_LEN:0] fifo_data_w, fifo_data_r;
  wire fifo_we,    fifo_re;
  wire fifo_empty, fifo_full;

  // reg/wire write fifo controller
  reg  [3:0] count;
  wire [`CHAR_LEN-1:0] d_buf [0:`N-1];


  // ----------------------------------------
  // assign AXI Stream
  assign M_AXIS_TDATA  = fifo_data_r[`CHAR_LEN-1:0];
  assign M_AXIS_TLAST  = fifo_data_r[`CHAR_LEN];
  assign M_AXIS_TVALID = ~fifo_empty;

  // assign valid
  assign valid = (count == `N);

  // assign fifo_out
  assign fifo_data_w = {(count == `N - 1), d_buf[count]};
  assign fifo_we     = run & ~fifo_full & (count != `N);
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
      count <= 4'b0;
    end else if (fifo_we) begin
      count <= count + 1;
    end else if (run) begin
      count <= count;
    end else begin
      count <= 4'b0;
    end
  end


  // ----------------------------------------
  // fifo instance
  fifo #(
    .WIDTH(1+`CHAR_LEN),
    .SIZE(32),
    .LOG_SIZE(5)
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