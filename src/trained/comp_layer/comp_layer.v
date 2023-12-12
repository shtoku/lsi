//
// this module needs CHAR_NUM == 200.
//

`include "consts_trained.vh"

module comp_layer (
    input  wire clk,
    input  wire rst_n,
    input  wire run,
    input  wire [`N*`CHAR_NUM*`N_LEN-1:0] d,
    output wire valid,
    output wire [`N*`CHAR_LEN-1:0] q
  );


  // ----------------------------------------
  genvar i;
  wire [`CHAR_NUM*`N_LEN-1:0] d_buf [0:`N-1];
  wire [`N-1:0] valid_buf;
  wire [`CHAR_LEN-1:0] q_buf [0:`N-1];


  // ----------------------------------------
  generate
    // convert shape (N, CHAR_NUM) <- (N*CHAR_NUM, )
    for (i = 0; i < `N; i = i + 1) begin
      assign d_buf[i] = d[i*`CHAR_NUM*`N_LEN +: `CHAR_NUM*`N_LEN];
    end

    // convert shape (N*CHAR_LEN, ) <= (N, CHAR_LEN)
    for (i = 0; i < `N; i = i + 1) begin
      assign q[i*`CHAR_LEN +: `CHAR_LEN] = q_buf[i];
    end
  endgenerate

  // assign valid
  assign valid = (|valid_buf);


  // ----------------------------------------
  // N instances of comparator_200
  generate
    for (i = 0; i < `N; i = i + 1) begin
      comparator_200 comp_200_inst (
        .clk(clk),
        .rst_n(rst_n),
        .run(run),
        .d(d_buf[i]),
        .valid(valid_buf[i]),
        .q(q_buf[i])
      );
    end
  endgenerate

endmodule