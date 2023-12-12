`include "consts_trained.vh"

module rom_w #(
    parameter filenum = 0
  ) (
    input  wire clk, 
    input  wire rst_n, 
    input  wire run, 
    input  wire [`STATE_LEN-1:0] state, 
    output wire [`DATA_N*`N_LEN-1:0] output_weight
  );


  reg  [`N_LEN-1:0] sub_addr;
  wire [`N_LEN-1:0] addr;
  wire [`N_LEN-1:0] addr_bias;


  rom_w_core #(
    .filenum(filenum)
  ) rom_w_core (
    .clk(clk), 
    .rst_n(rst_n), 
    .addr(addr), 
    .output_weight(output_weight)
  );


  function [`N_LEN-1:0] decide_addr_bias;
    input [`STATE_LEN-1:0] addr_bias_select;
    
    case (addr_bias_select)
      `MIX1   : decide_addr_bias = 0*(`HID_DIM*`HID_DIM/`DATA_N);
      `MIX2   : decide_addr_bias = 1*(`HID_DIM*`HID_DIM/`DATA_N);
      `MIX3   : decide_addr_bias = 2*(`HID_DIM*`HID_DIM/`DATA_N);
      default : decide_addr_bias = {`STATE_LEN{1'bX}};
    endcase
  endfunction


  assign addr_bias = decide_addr_bias(state);
  // assign addr = sub_addr + addr_bias;
  assign addr = sub_addr;


  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      sub_addr <= 0;
    end
    
    
    else if(run) begin
      // if (sub_addr == 95) begin
      //   sub_addr <= 0;
      // end else begin
      //   sub_addr <= sub_addr + 1;
      // end
      sub_addr <= sub_addr + 1;
    end
    
    
    else begin
      sub_addr <= addr_bias;
    end
  end


endmodule