`include "consts_train.vh"

module comp_layer (
    input  wire clk,
    input  wire rst_n,
    input  wire run,
    input  wire [`N*`CHAR_NUM*`N_LEN-1:0] d,
    output wire valid,
    output wire [`N*`CHAR_LEN-1:0] num,
    output wire [`N*`N_LEN-1:0] q
  );


  // ----------------------------------------
  genvar i;
  wire [`CHAR_NUM*`N_LEN-1:0] d_buf [0:`N-1];
  wire [`N-1:0] valid_buf;
  wire [`CHAR_LEN-1:0] num_buf [0:`N-1];
  wire [`N_LEN-1:0] q_buf [0:`N-1];


  // ----------------------------------------
  generate
    // convert shape (N, CHAR_NUM) <- (N*CHAR_NUM, )
    for (i = 0; i < `N; i = i + 1) begin
      assign d_buf[i] = d[i*`CHAR_NUM*`N_LEN +: `CHAR_NUM*`N_LEN];
    end

    for (i = 0; i < `N; i = i + 1) begin
      // convert shape (N*CHAR_LEN, ) <- (N, CHAR_LEN)
      assign num[i*`CHAR_LEN +: `CHAR_LEN] = num_buf[i];
      // convert shape (N*N_LEN, ) <- (N, N_LEN)
      assign q[i*`N_LEN +: `N_LEN] = q_buf[i];
    end
  endgenerate

  // assign valid
  assign valid = &valid_buf;


  // ----------------------------------------
  // N instances of comparator_72
  generate
    for (i = 0; i < `N; i = i + 1) begin : comp_72
      comparator_72 comp_72_inst (
        .clk(clk),
        .rst_n(rst_n),
        .run(run),
        .d(d_buf[i]),
        .valid(valid_buf[i]),
        .num(num_buf[i]),
        .q(q_buf[i])
      );
    end
  endgenerate

endmodule