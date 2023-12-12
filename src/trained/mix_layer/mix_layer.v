`include "consts_trained.vh"

module mix_layer(
    input  wire clk, 
    input  wire rst_n, 
    input  wire run, 
    input  wire [`STATE_LEN-1:0] state, 
    input  wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] d, 
    output wire valid, 
    output wire [`HID_DIM*`HID_DIM*`N_LEN-1:0] q
  );


  wire [`HID_DIM*`HID_DIM*`N_LEN:0] input_line;
  wire [`HID_DIM*`N_LEN-1:0] input_array  [0:`HID_DIM-1];
  wire [`HID_DIM*`HID_DIM*`N_LEN:0] output_line;
  wire [`HID_DIM*`N_LEN-1:0] output_array [0:`HID_DIM-1];
  
  wire [`HID_DIM-1:0] valid_buf;


  genvar x, y;
  assign valid = &valid_buf;


  //入力データを並び替える回路
  //転置回路
  generate
    for(x = 0; x < `HID_DIM; x = x + 1) begin :transpose_1
      for(y = 0; y < `HID_DIM; y = y + 1) begin :transpose_2
        assign input_line[(`HID_DIM*x+y)*`N_LEN +: `N_LEN] = d[(`HID_DIM*y+x)*`N_LEN +: `N_LEN];
      end
    end
  endgenerate

  //入力データを並び替える回路
  //一列に並び替える回路
  generate
    for(x = 0; x < `HID_DIM; x = x + 1) begin :set_in_array_1
      assign input_array[x] = input_line[`HID_DIM*`N_LEN*x +: `HID_DIM*`N_LEN];
    end
  endgenerate


  //メインの回路を`HID_DIM個インスタンス化
  generate
    for(x = 0; x < `HID_DIM; x = x + 1) begin :main_inst_1
      main_src #(
        .filenum(x)
      ) main_src(
        .clk(clk), 
        .rst_n(rst_n), 
        .run(run), 
        .valid(valid_buf[x]), 
        .data_in(input_array[x]), 
        .state(state), 
        .data_out(output_array[x])
      );
    end
  endgenerate


  //出力を並び替える回路
  generate
    for(x = 0; x < `HID_DIM; x = x + 1) begin :set_out_array_1
      assign q[`HID_DIM*`N_LEN*x +: `HID_DIM*`N_LEN] = output_array[x];
    end
  endgenerate


endmodule