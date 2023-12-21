`include "consts_train.vh"

module comparator_200 (
    input  wire clk,
    input  wire rst_n,
    input  wire run,
    input  wire [200*`N_LEN-1:0] d,
    output wire valid,
    output wire [`CHAR_LEN-1:0]num,
    output wire [`N_LEN-1:0] q
  );


  // ----------------------------------------
  genvar i;
  wire [`N_LEN-1:0] d_buf [0:200-1];

  // wire comparator_2
  wire [`CHAR_LEN-1:0] comp_1_num [0:100-1];
  wire [`CHAR_LEN-1:0] comp_2_num [0:50 -1];
  wire [`CHAR_LEN-1:0] comp_3_num [0:25 -1];
  wire [`CHAR_LEN-1:0] comp_4_num [0:12 -1];
  wire [`CHAR_LEN-1:0] comp_5_num [0:6  -1];
  wire [`CHAR_LEN-1:0] comp_6_num [0:3];
  wire [`CHAR_LEN-1:0] comp_7_num [0:1];
  wire [`CHAR_LEN-1:0] comp_8_num;

  wire [`N_LEN-1:0] comp_1_q [0:100-1];
  wire [`N_LEN-1:0] comp_2_q [0:50 -1];
  wire [`N_LEN-1:0] comp_3_q [0:25 -1];
  wire [`N_LEN-1:0] comp_4_q [0:12 -1];
  wire [`N_LEN-1:0] comp_5_q [0:6  -1];
  wire [`N_LEN-1:0] comp_6_q [0:3];
  wire [`N_LEN-1:0] comp_7_q [0:1];
  wire [`N_LEN-1:0] comp_8_q;

  // reg counter
  reg [3:0] count;


  // ----------------------------------------
  // convert shape (200, N_LEN) <- (200*N_LEN, )
  generate
    for (i = 0; i < 200; i = i + 1) begin
      assign d_buf[i] = d[i*`N_LEN +: `N_LEN];
    end
  endgenerate

  // assign comp_6
  // comp_3 has 25 instances. 25/2 = 12.5 is not integer.
  // so, assign comp_3[24] to comp_6[3] to compare.
  assign comp_6_num[3] = comp_3_num[25-1];
  assign comp_6_q[3]   = comp_3_q[25-1];

  // assign output
  assign valid = (count == 4'd8);
  assign num   = comp_8_num;
  assign q     = comp_8_q;


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
    // 100 instances of comparator_2
    for (i = 0; i < 100; i = i + 1) begin : comp_2_1
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

    // 50 instances of comparator_2
    for (i = 0; i < 50; i = i + 1) begin : comp_2_2
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

    // 25 instances of comparator_2
    for (i = 0; i < 25; i = i + 1) begin : comp_2_3
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

    // 12 instances of comparator_2
    for (i = 0; i < 12; i = i + 1) begin : comp_2_4
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

    // 6 instances of comparator_2
    for (i = 0; i < 6; i = i + 1) begin : comp_2_5
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

    // 3 instances of comparator_2
    for (i = 0; i < 3; i = i + 1) begin : comp_2_6
      comparator_2 comp_6 (
        .clk(clk),
        .rst_n(rst_n),
        .run(run),
        .num1(comp_5_num[2*i]),
        .num2(comp_5_num[2*i+1]),
        .d1(comp_5_q[2*i]),
        .d2(comp_5_q[2*i+1]),
        .num(comp_6_num[i]),
        .q(comp_6_q[i])
      );
    end

    // 2 instances of comparator_2
    for (i = 0; i < 2; i = i + 1) begin : comp_2_7
      comparator_2 comp_7 (
        .clk(clk),
        .rst_n(rst_n),
        .run(run),
        .num1(comp_6_num[2*i]),
        .num2(comp_6_num[2*i+1]),
        .d1(comp_6_q[2*i]),
        .d2(comp_6_q[2*i+1]),
        .num(comp_7_num[i]),
        .q(comp_7_q[i])
      );
    end

    // 1 instances of comparator_2
    comparator_2 comp_2_8 (
      .clk(clk),
      .rst_n(rst_n),
      .run(run),
      .num1(comp_7_num[0]),
      .num2(comp_7_num[1]),
      .d1(comp_7_q[0]),
      .d2(comp_7_q[1]),
      .num(comp_8_num),
      .q(comp_8_q)
    );
  endgenerate
  
endmodule