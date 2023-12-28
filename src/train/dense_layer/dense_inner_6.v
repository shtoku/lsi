`include "consts_train.vh"

module dense_inner_6 #(
    parameter integer DATA_WIDTH1 = `N_LEN,
    parameter integer DATA_WIDTH2 = `N_LEN
  ) (
    input  wire clk,
    input  wire rst_n,
    input  wire [6*DATA_WIDTH1-1:0] d1,
    input  wire [6*DATA_WIDTH2-1:0] d2,
    output reg  [DATA_WIDTH1-1:0] q
  );


  // ----------------------------------------
  genvar i;

  // reg result
  reg  [DATA_WIDTH1-1:0] mul [0:5];
  reg  [DATA_WIDTH1-1:0] add [0:1];


  // ----------------------------------------
  // function fixed_multiply
  function [DATA_WIDTH1-1:0] fixed_mul;
    input signed [DATA_WIDTH1-1:0] num1;
    input signed [DATA_WIDTH2-1:0] num2;

    reg [DATA_WIDTH1*DATA_WIDTH2-1:0] mul;
    begin
      mul = num1 * num2;
      fixed_mul = mul[`F_LEN +: DATA_WIDTH1]; 
    end
  endfunction  


  // ----------------------------------------
  // fixed multiply
  generate
    for (i = 0; i < 6; i = i + 1) begin
      always @(posedge clk, negedge rst_n) begin
        if (~rst_n)
          mul[i] <= 0;
        else
          mul[i] <= fixed_mul(d1[i*DATA_WIDTH1 +: DATA_WIDTH1], d2[i*DATA_WIDTH2 +: DATA_WIDTH2]);
      end
    end
  endgenerate

  // first add
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      add[0] <= 0;
      add[1] <= 0;
    end else begin
      add[0] <= mul[0] + mul[1] + mul[2];
      add[1] <= mul[3] + mul[4] + mul[5];
    end
  end

  // ouput add
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      q <= 0;
    end else begin
      q <= add[0] + add[1];
    end
  end
  
endmodule