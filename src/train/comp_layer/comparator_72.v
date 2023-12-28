`include "consts_train.vh"

module comparator_72 (
    input  wire clk,
    input  wire rst_n,
    input  wire run,
    input  wire [72*`N_LEN-1:0] d,
    output wire valid,
    output wire [`CHAR_LEN-1:0]num,
    output wire [`N_LEN-1:0] q
  );


  // ----------------------------------------
  genvar i;
  wire [`N_LEN-1:0] d_buf [0:72-1];

  // wire comparator_2
  wire [`CHAR_LEN-1:0] comp_1_num [0:36-1];
  wire [`CHAR_LEN-1:0] comp_2_num [0:18-1];
  wire [`CHAR_LEN-1:0] comp_3_num [0:9 -1];
  wire [`CHAR_LEN-1:0] comp_4_num [0:4 -1];
  wire [`CHAR_LEN-1:0] comp_5_num [0:2 -1];
  wire [`CHAR_LEN-1:0] comp_6_num [0:1];
  wire [`CHAR_LEN-1:0] comp_7_num;

  wire [`N_LEN-1:0] comp_1_q [0:36-1];
  wire [`N_LEN-1:0] comp_2_q [0:18-1];
  wire [`N_LEN-1:0] comp_3_q [0:9 -1];
  wire [`N_LEN-1:0] comp_4_q [0:4 -1];
  wire [`N_LEN-1:0] comp_5_q [0:2 -1];
  wire [`N_LEN-1:0] comp_6_q [0:2 -1];
  wire [`N_LEN-1:0] comp_7_q;

  // reg counter
  reg [3:0] count;


  // ----------------------------------------
  // convert shape (72, N_LEN) <- (72*N_LEN, )
  generate
    for (i = 0; i < 72; i = i + 1) begin
      assign d_buf[i] = d[i*`N_LEN +: `N_LEN];
    end
  endgenerate

  // assign comp_6
  // comp_3 has 9 instances. 9/2 = 4.5 is not integer.
  // so, assign comp_3[8] to comp_6[1] to compare.
  assign comp_6_num[1] = comp_3_num[8];
  assign comp_6_q[1]   = comp_3_q[8];

  // assign output
  assign valid = (count == 4'd7);
  assign num   = comp_7_num;
  assign q     = comp_7_q;


  // ----------------------------------------
  // counter for valid
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      count <= 4'b0;
    end else if (run & ~valid) begin
      count <= count + 4'b1;
    end else if (run) begin
      count <= count;
    end else begin
      count <= 4'b0;
    end
  end


  // ----------------------------------------
  // instances of comparator_2
  generate
    // 36 instances of comparator_2
    for (i = 0; i < 36; i = i + 1) begin : comp_2_1
      reg [`CHAR_LEN-1:0] num1 = 2*i;
      reg [`CHAR_LEN-1:0] num2 = 2*i+1;
      comparator_2 comp_1 (
        .clk(clk),
        .rst_n(rst_n),
        .run(run),
        .num1(num1),
        .num2(num2),
        .d1(d_buf[2*i]),
        .d2(d_buf[2*i+1]),
        .num(comp_1_num[i]),
        .q(comp_1_q[i])
      );
    end

    // 18 instances of comparator_2
    for (i = 0; i < 18; i = i + 1) begin : comp_2_2
      comparator_2 comp_2 (
        .clk(clk),
        .rst_n(rst_n),
        .run(run),
        .num1(comp_1_num[2*i]),
        .num2(comp_1_num[2*i+1]),
        .d1(comp_1_q[2*i]),
        .d2(comp_1_q[2*i+1]),
        .num(comp_2_num[i]),
        .q(comp_2_q[i])
      );
    end

    // 9 instances of comparator_2
    for (i = 0; i < 9; i = i + 1) begin : comp_2_3
      comparator_2 comp_3 (
        .clk(clk),
        .rst_n(rst_n),
        .run(run),
        .num1(comp_2_num[2*i]),
        .num2(comp_2_num[2*i+1]),
        .d1(comp_2_q[2*i]),
        .d2(comp_2_q[2*i+1]),
        .num(comp_3_num[i]),
        .q(comp_3_q[i])
      );
    end

    // 4 instances of comparator_2
    for (i = 0; i < 4; i = i + 1) begin : comp_2_4
      comparator_2 comp_4 (
        .clk(clk),
        .rst_n(rst_n),
        .run(run),
        .num1(comp_3_num[2*i]),
        .num2(comp_3_num[2*i+1]),
        .d1(comp_3_q[2*i]),
        .d2(comp_3_q[2*i+1]),
        .num(comp_4_num[i]),
        .q(comp_4_q[i])
      );
    end

    // 2 instances of comparator_2
    for (i = 0; i < 2; i = i + 1) begin : comp_2_5
      comparator_2 comp_5 (
        .clk(clk),
        .rst_n(rst_n),
        .run(run),
        .num1(comp_4_num[2*i]),
        .num2(comp_4_num[2*i+1]),
        .d1(comp_4_q[2*i]),
        .d2(comp_4_q[2*i+1]),
        .num(comp_5_num[i]),
        .q(comp_5_q[i])
      );
    end

    // 1 instances of comparator_2
    comparator_2 comp_6 (
      .clk(clk),
      .rst_n(rst_n),
      .run(run),
      .num1(comp_5_num[0]),
      .num2(comp_5_num[1]),
      .d1(comp_5_q[0]),
      .d2(comp_5_q[1]),
      .num(comp_6_num[0]),
      .q(comp_6_q[0])
    );

    // 1 instances of comparator_2
    comparator_2 comp_2_7 (
      .clk(clk),
      .rst_n(rst_n),
      .run(run),
      .num1(comp_6_num[0]),
      .num2(comp_6_num[1]),
      .d1(comp_6_q[0]),
      .d2(comp_6_q[1]),
      .num(comp_7_num),
      .q(comp_7_q)
    );
  endgenerate
  
endmodule