`include "consts.vh"

module data_in_src(
    input  wire clk, 
    input  wire rst_n, 
    input  wire run, 
    input  wire [`HID_DIM*`N_LEN-1:0] input_data, 
    output reg  [`DATA_N*`N_LEN-1:0] output_data
  );

  // reg [7:0] cnt_1;
  reg [1:0] cnt_2;



  function [`DATA_N*`N_LEN-1:0] outdata_selecter;
    input [`HID_DIM*`N_LEN-1:0] fn_input_data;
    input [1:0] selecter;
    
    case (selecter)
      0: outdata_selecter = fn_input_data[0*`DATA_N*`N_LEN +: `DATA_N*`N_LEN];
      1: outdata_selecter = fn_input_data[1*`DATA_N*`N_LEN +: `DATA_N*`N_LEN];
      2: outdata_selecter = fn_input_data[2*`DATA_N*`N_LEN +: `DATA_N*`N_LEN];
      3: outdata_selecter = fn_input_data[3*`DATA_N*`N_LEN +: `DATA_N*`N_LEN];
      // default: outdata_selecter = 16'hxx;
    endcase
  endfunction



  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      // cnt_1 <= 0;
      cnt_2 <= 0;
      output_data <= 0;
    end
    
    else if(run) begin
      // 101の理由はmain_logic.vに書いた
      // if (cnt_1 == 101) begin
      //   cnt_1 <= 0;
      //   cnt_2 <= 0;
      // end else begin
      //   cnt_1 <= cnt_1 + 1;
      
      //   if (cnt_2 == 3) begin
      //     cnt_2 <= 0;
      //   end else begin
      //     cnt_2 <= cnt_2 + 1;
      //   end
                      
      // end
      cnt_2 <= cnt_2 + 1;
      output_data <= outdata_selecter(input_data, cnt_2);
    end 
    
    else begin
      // cnt_1 <= 0;
      cnt_2 <= 0;
      output_data <= 0;
    end
  end


endmodule