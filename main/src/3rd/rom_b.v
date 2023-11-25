`include "num_data.v"

module rom_b#(
    parameter filenum = 0
    )(
    input wire clk, 
    input wire rst_n, 
    input wire run, 
    input wire [`STATE_LEN-1:0] state, 
    output wire [`BIT_LENGTH-1:0] output_bias
);


wire [15:0] addr;
wire [15:0] addr_bias;
reg [15:0] sub_addr;
reg [15:0] cnt_1, cnt_saved;


rom_b_core #(
    .filenum(filenum)
    ) rom_b_core(
        .clk(clk), 
        .rst_n(rst_n), 
        .addr(addr), 
        .output_bias(output_bias)
);


function [15:0] decide_addr_bias;
    input [`STATE_LEN-1:0] addr_bias_select;
    
    case (addr_bias_select)
        4'b0011: decide_addr_bias = 0;
        4'b0100: decide_addr_bias = 24;
        4'b0101: decide_addr_bias = 48;
        default : decide_addr_bias = 16'hXX;
    endcase
endfunction


assign addr_bias = decide_addr_bias(state);
assign addr = sub_addr + addr_bias;


always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        cnt_1 <= 0;
        sub_addr <= 0;
        cnt_saved <= 0;
    end
    
    
    else if(run) begin
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
        sub_addr <= 0;
        cnt_saved <= 0;
    end
end



endmodule