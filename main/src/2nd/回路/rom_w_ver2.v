//`include "num_data.v"

`define BIT_LENGTH 16
`define HID_LENGTH 24
`define DATA_N 6
`define DATA_ALL 96


module rom_w_ver2(clk, rst_n, run, selecter, output_weight);
input clk, rst_n, run;
input [1:0] selecter;
output [`BIT_LENGTH*`DATA_N-1:0] output_weight;

reg [15:0] addr;
reg  [`BIT_LENGTH*`DATA_N-1:0] output_weight;

(* ram_style = "block" *)
reg [`BIT_LENGTH*`DATA_N-1:0] mem [0:`DATA_ALL*3-1];


//always でもいいな
function [15:0] decide_addr_bias;
    input addr_bias_select;
    
    //値テキトー
    case (addr_bias_select)
        2'b00: decide_addr_bias = 0;
        2'b01: decide_addr_bias = 96;
        2'b10: decide_addr_bias = 192;
        default : decide_addr_bias = 16'hXX;
    endcase
endfunction
assign addr_bias = decide_addr_bias(selecter);



always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        output_weight <= 0;
        addr <= 0;
    end
    
    
    else if(run) begin
        if (addr == 95) begin
            addr <= 0;
        end else begin
            addr <= addr + 1;
        end
        output_weight <= mem[addr_bias+addr];
    end
    
    
    else begin
        output_weight <= 0;
        addr <= 0;
    end
end



//同時に入れるべきかifでわけるべきか不明
initial begin
    $readmemb("/home/hirahara/lsi_data/weight_1.txt", mem);
end

endmodule