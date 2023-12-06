`include "consts.vh"

module rom_b#(
    parameter filenum = 0
  ) (
    input  wire clk, 
    input  wire rst_n, 
    input  wire run, 
    input  wire [`STATE_LEN-1:0] state, 
    output wire [`N_LEN-1:0] output_bias
  );


  wire [`N_LEN-1:0] addr;
  wire [`N_LEN-1:0] addr_bias;
  reg  [`N_LEN-1:0] sub_addr;
  reg  [7:0] cnt_1, cnt_saved;


  rom_b_core #(
    .filenum(filenum)
    ) rom_b_core (
      .clk(clk), 
      .rst_n(rst_n), 
      .addr(addr), 
      .output_bias(output_bias)
  );


  function [`N_LEN-1:0] decide_addr_bias;
    input [`STATE_LEN-1:0] addr_bias_select;
    
    case (addr_bias_select)
      `MIX1   : decide_addr_bias = 0*`HID_DIM;
      `MIX2   : decide_addr_bias = 1*`HID_DIM;
      `MIX3   : decide_addr_bias = 2*`HID_DIM;
      default : decide_addr_bias = {`STATE_LEN{1'bX}};
    endcase
  endfunction


  assign addr_bias = decide_addr_bias(state);
  // assign addr = sub_addr + addr_bias;
  assign addr = sub_addr;


  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      cnt_1 <= 0;
      sub_addr <= 0;
      cnt_saved <= 0;
    end
    
    
    else if(run) begin
      // 101の理由はmain_logic.vに書いた
      if (cnt_1 == 101) begin
        cnt_1 <= 0;
        sub_addr <= 0;
        cnt_saved <= 0;
      end else begin
        cnt_1 <= cnt_1 + 1;
      end

      //もともと+9で考えていたが間違っていた。
      //ここの8を変えれば他の回路の余分クロックも考慮することができる
      //main回路を1クロックずらせば+8でちょうど良くなるはず
      if (cnt_1 == cnt_saved+8) begin
        sub_addr <= sub_addr + 1;
        cnt_saved <= cnt_saved + 4;
      end
    end
    
    
    else begin
      cnt_1 <= 0;
      sub_addr <= addr_bias;
      cnt_saved <= 0;
    end
  end



endmodule