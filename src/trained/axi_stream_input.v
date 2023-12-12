`include "consts_trained.vh"

module axi_stream_input (
    input  wire ACLK,
    input  wire ARESETN,

    // AXI Stream interface
    input  wire [`CHAR_LEN-1:0] S_AXIS_TDATA,
    input  wire S_AXIS_TLAST,
    input  wire S_AXIS_TVALID,
    output wire S_AXIS_TREADY,
    // AXI Stream interface end

    input  wire run,
    output wire valid,
    output wire [`N*`CHAR_LEN-1:0] q
  );


  // ----------------------------------------
  genvar i;
  integer j;

  // wire fifo
  wire [`CHAR_LEN-1:0] fifo_data_w, fifo_data_r;
  wire fifo_we,    fifo_re;
  wire fifo_empty, fifo_full;

  // reg read fifo controller
  reg  [3:0] count;
  reg  [`CHAR_LEN-1:0] q_buf [0:`N-1];


  // ----------------------------------------
  // assign AXI Stream
  assign S_AXIS_TREADY = ~fifo_full;

  // assign valid
  assign valid = (count == `N);

  // assign fifo
  assign fifo_data_w  = S_AXIS_TDATA;
  assign fifo_we      = S_AXIS_TVALID & S_AXIS_TREADY;
  assign fifo_re      = run & ~fifo_empty & (count != `N);

  // convert shape (N*CHAR_LEN, ) <- (N, CHAR_LEN)
  generate
    for (i = 0; i < `N; i = i + 1) begin
      assign q[i*`CHAR_LEN +: `CHAR_LEN] = q_buf[i];
    end
  endgenerate


  // ----------------------------------------
  // read fifo controller
  always @(posedge ACLK, negedge ARESETN) begin
    if (~ARESETN) begin
      count <= 4'b0;
      for (j = 0; j < `N; j = j + 1)
        q_buf[j] <= `CHAR_LEN'b0;
    end else if (fifo_re) begin
      count <= count + 1;
      q_buf[count] <= fifo_data_r;
    end else if (run) begin
      count <= count;
    end else begin
      count <= 4'b0;
    end
  end


  // ----------------------------------------
  // fifo instance
  fifo #(
    .WIDTH(`CHAR_LEN),
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