`include "consts.vh"

module rand_layer #(
    parameter integer WIDTH = 32,
    parameter integer SEED  = 32'd5671
  ) (
    input  wire clk,
    input  wire rst_n,
    input  wire run,
    output wire valid,
    output wire [`HID_DIM*`N_LEN-1:0] q
  );
  

  // ----------------------------------------
  genvar i;
  integer j;

  // wire xorshift
  wire xorshift_run;
  wire [WIDTH-1:0] xorshift_q;

  // reg/wire xorshift controller
  reg  [5:0] count;
  reg  [`N_LEN-1:0] q_buf [0:`HID_DIM-1];
  wire [`N_LEN-1:0] q_temp;


  // ----------------------------------------
  // assign valid
  assign valid = (count == `HID_DIM + 1);

  // assign xorshift
  assign xorshift_run = run & (count != `HID_DIM) & ~valid;

  // convert shape (HID_DIM*N_LEN, ) <- (HID_DIM, N_LEN)
  generate
    for (i = 0; i < `HID_DIM; i = i + 1) begin
      assign q[i*`N_LEN +: `N_LEN] = q_buf[i];
    end
  endgenerate

  // convert 32bit integer to 16bit decimal fraction (-1 < x < 1).
  assign q_temp = {{`I_LEN{xorshift_q[`F_LEN]}}, xorshift_q[`F_LEN-1:0]};


  // ----------------------------------------
  // xorshift controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      count <= 5'b0;
      for (j = 0; j < `HID_DIM; j = j + 1) begin
        q_buf[j] <= `N_LEN'b0;
      end
    end else if (run & count == 5'b0) begin
      count <= count + 5'b1;
    end else if (run & ~valid) begin
      count <= count + 5'b1;
      q_buf[count - 5'b1] <= q_temp;
    end else if (run) begin
      count <= count;
    end else begin
      count <= 5'b0;
    end
  end


  // ----------------------------------------
  // xorshift
  xorshift #(
    .WIDTH(WIDTH),
    .SEED(SEED)
  ) xorshift_inst (
    .clk(clk),
    .rst_n(rst_n),
    .run(xorshift_run),
    .q(xorshift_q)
  );


endmodule