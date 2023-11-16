`timescale 1ns / 1ps
`define BIT_LENGTH 16
`define HID_LENGTH 24
`define DATA_N 6


module main_src(clk, rst_n, run, valid, data_in, selecter, data_out);

input clk, rst_n, run;
input [1:0] selecter;
input  [4*`DATA_N*`BIT_LENGTH-1:0] data_in;
output valid;
output [`HID_LENGTH*`BIT_LENGTH-1:0] data_out;

wire [`BIT_LENGTH*`DATA_N-1:0] data_in_to_main_logic;
wire [`BIT_LENGTH-1:0] rom_b_to_main_logic;
wire [`BIT_LENGTH*`DATA_N-1:0] rom_w_to_main_logic;



main_logic main_logic(.clk(clk), .rst_n(rst_n), .run(run), .valid(valid), .data_in(data_in_to_main_logic), .weight_in(rom_w_to_main_logic), .bias_in(rom_b_to_main_logic), .data_out(data_out));
data_in_src data_in_src(.clk(clk), .rst_n(rst_n), .run(run), .input_data(data_in), .output_data(data_in_to_main_logic));
rom_w_ver2 rom_w_ver2(.clk(clk), .rst_n(rst_n), .run(run), .selecter(selecter), .output_weight(rom_w_to_main_logic));
rom_b_ver2 rom_b_ver2(.clk(clk), .rst_n(rst_n), .run(run), .selecter(selecter), .output_bias(rom_b_to_main_logic));

endmodule
