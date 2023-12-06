`include "consts.vh"

module main_src #(
    parameter integer filenum = 0
  ) (
    input  wire clk, 
    input  wire rst_n, 
    input  wire run,
    input  wire [`STATE_LEN-1:0] state,
    input  wire [`HID_DIM*`N_LEN-1:0] data_in,
    output wire valid,
    output wire [`HID_DIM*`N_LEN-1:0] data_out
  );


  wire [`DATA_N*`N_LEN-1:0] data_in_to_main_logic;
  wire [`N_LEN-1:0] rom_b_to_main_logic;
  wire [`DATA_N*`N_LEN-1:0] rom_w_to_main_logic;


  main_logic main_logic (
    .clk(clk),
    .rst_n(rst_n),
    .run(run),
    .valid(valid),
    .data_in(data_in_to_main_logic),
    .weight_in(rom_w_to_main_logic),
    .bias_in(rom_b_to_main_logic),
    .data_out(data_out)
  );

  data_in_src data_in_src (
    .clk(clk),
    .rst_n(rst_n),
    .run(run),
    .input_data(data_in),
    .output_data(data_in_to_main_logic)
  );

  rom_w #(
    .filenum(filenum)
  ) rom_w (
    .clk(clk), 
    .rst_n(rst_n), 
    .run(run), 
    .state(state), 
    .output_weight(rom_w_to_main_logic)
  );

  rom_b #(
    .filenum(filenum)
  ) rom_b (
    .clk(clk), 
    .rst_n(rst_n), 
    .run(run), 
    .state(state), 
    .output_bias(rom_b_to_main_logic)
  );

endmodule