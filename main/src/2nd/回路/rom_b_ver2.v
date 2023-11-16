//`include "num_data.v"

`define BIT_LENGTH 16
`define HID_LENGTH 24
`define DATA_N 6
`define DATA_ALL 96


module rom_b_ver2(clk, rst_n, run, selecter, output_bias);
input clk, rst_n, run;
input [1:0] selecter;
output [`BIT_LENGTH-1:0] output_bias;

reg [15:0] addr;
reg  [`BIT_LENGTH-1:0] output_bias;
reg [15:0] cnt_1, cnt_saved;

(* ram_style = "block" *)
reg [`BIT_LENGTH-1:0] mem [0:24*3-1];


//always でもいいな
function [15:0] decide_addr_bias;
    input addr_bias_select;
    
    //値テキトー
    case (addr_bias_select)
        2'b00: decide_addr_bias = 0;
        2'b01: decide_addr_bias = 24;
        2'b10: decide_addr_bias = 48;
        default : decide_addr_bias = 16'hXX;
    endcase
endfunction
assign addr_bias = decide_addr_bias(selecter);



always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        cnt_1 <= 0;
        addr <= 0;
        cnt_saved <= 0;
        output_bias <= 0;

    end
    
    else if(run) begin
        if (cnt_1 == 101) begin
            cnt_1 <= 0;
            addr <= 0;
            cnt_saved <= 0;
        end else begin
            cnt_1 <= cnt_1 + 1;
        end

        //もともと+9で考えていたが間違っていた。
        //ここの8を変えれば他の回路の余分クロックも考慮することができる
        //main回路を1クロックずらせば+8でちょうど良くなるはず
        if (cnt_1 == cnt_saved+8) begin
            addr <= addr + 1;
            cnt_saved <= cnt_saved + 4;
            output_bias <= mem[addr_bias+addr];//biasはsignedにすべき？
        end
    end
    
    else begin
        cnt_1 <= 0;
        addr <= 0;
        cnt_saved <= 0;
        output_bias <= 0;
    end
end



//同時に入れるべきかifでわけるべきか不明
initial begin
    $readmemb("/home/hirahara/lsi_data/bias_1.txt", mem);
end



endmodule