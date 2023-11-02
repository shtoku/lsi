`timescale 1ns / 100ps

`define BIT_LENGTH 16
`define HID_LENGTH 24
`define DATA_N 6

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/31/2023 09:22:48 PM
// Design Name: 
// Module Name: main_dot
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module main_dotv2(clk, rst_n, run, valid, data_in, weight_in, data_out);

input clk, rst_n, run;
input  [`DATA_N*`BIT_LENGTH-1:0] data_in, weight_in;
output valid;
output [`HID_LENGTH*`BIT_LENGTH-1:0] data_out;
//output [`BIT_LENGTH-1:0] data_out;

wire signed [`BIT_LENGTH:0] indata_array [0:`DATA_N-1];
wire signed [`BIT_LENGTH:0] inweight_array [0:`DATA_N-1];


reg signed [`BIT_LENGTH:0] outdot_array [0:`DATA_N-1];
reg signed [`BIT_LENGTH:0] add1_array [0:2];

reg signed [`BIT_LENGTH:0] midrslt1_array[0:3];
reg signed [`BIT_LENGTH:0] midrslt2_array[0:1];
reg signed [`BIT_LENGTH:0] midrslt3_array;
reg signed [`BIT_LENGTH:0] outrslt_array [0:`HID_LENGTH-1];

reg [3:0] cnt_1;
reg [16:0] cnt_2, cnt_saved;

reg valid;

integer n;
genvar xx,yy,zz;

//ここマイナス1し忘れてて最初動かなかった
generate
    for(yy=0; yy<6; yy=yy+1) begin :set_in_array
        assign indata_array[yy] = data_in[`BIT_LENGTH*(yy+1)-1 : `BIT_LENGTH*yy];
        assign inweight_array[yy] = weight_in[`BIT_LENGTH*(yy+1)-1 : `BIT_LENGTH*yy];
    end
endgenerate

/*
===固定小数点用掛け算回路===
function [15:0] product;
    input [15:0] in_func_1, in_func_2;
    
    reg [31:0] func1_midrslt;
    
    begin
        func1_midrslt = in_func_1 * in_func_2;
        product = func1_midrslt[20:5]; 
    end
endfunction
*/

//①の部分
generate
    for(xx=0; xx<6; xx=xx+1) begin :dot_1
        always @(posedge clk, negedge rst_n) begin
            if (!rst_n) begin
                outdot_array[xx] <= 0;
            end 
            
            else if(run) begin
                outdot_array[xx] <= indata_array[xx] * inweight_array[xx];
            end
            
            else begin
                outdot_array[xx] <= 0;
            end
        end
    end
endgenerate


//②の部分
generate
    for(yy=0; yy<3; yy=yy+1) begin :add_1
        always @(posedge clk, negedge rst_n) begin
            if (!rst_n) begin
                add1_array[yy] <= 0;
            end 
            
            else if(run) begin
                add1_array[yy] <= outdot_array[2*yy] + outdot_array[2*yy+1];
            end
            
            else begin
                add1_array[yy] <= 0;
            end
        end
    end
endgenerate



always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        cnt_1 <= 0;
        for(n=0; n<4; n=n+1) begin
            midrslt1_array[n] <= 0;
        end
        for(n=0; n<2; n=n+1) begin
            midrslt2_array[n] <= 0;
        end
        midrslt3_array <= 0;
    end 
    
    else if(run) begin
        if (cnt_1 == 3) begin
            cnt_1 <= 0;
        end else begin
            cnt_1 <= cnt_1 + 1;
        end
        midrslt1_array[cnt_1] <= add1_array[0] + add1_array[1] + add1_array[2];
        midrslt2_array[0] <= midrslt1_array[0] + midrslt1_array[1];
        midrslt2_array[1] <= midrslt1_array[2] + midrslt1_array[3];
        midrslt3_array <= midrslt2_array[0] + midrslt2_array[1];
    end
    
    else begin
        cnt_1 <= 0;
        for(n=0; n<4; n=n+1) begin
            midrslt1_array[n] <= 0;
        end
        for(n=0; n<2; n=n+1) begin
            midrslt2_array[n] <= 0;
        end
        midrslt3_array <= 0;
    end
end


//データアライメント
always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        cnt_2 <= 0;
        cnt_saved <= 0;
        valid <= 0;
        for(n=0; n<96; n=n+1) begin
            outrslt_array[n] <= 0;
        end
    end
    
    else if(run) begin
        if (cnt_2 == 101) begin
            cnt_2 <= 0;
            cnt_saved <= 0;
            valid <= 1;
        end else begin
            cnt_2 <= cnt_2 + 1;
        end
        
        if (cnt_2 == (4*cnt_saved)+9)begin
            cnt_saved <= cnt_saved + 1;
            outrslt_array[cnt_saved] <= midrslt3_array;
        end
    end
    
    else begin
        cnt_2 <= 0;
        cnt_saved <= 0;
        valid <= 0;
        for(n=0; n<96; n=n+1) begin
            outrslt_array[n] <= 0;
        end
    end
end

//エラー箇所がgenerateだからといってそこが間違えているとは限らない。上のendが抜けてたりする。
generate
    for(zz=0; zz<24; zz=zz+1) begin :set_out_array
        assign data_out[`BIT_LENGTH*(zz+1)-1 : `BIT_LENGTH*zz] = outrslt_array[zz];
    end
endgenerate





/*
//デバッグ用
assign data_out = midrslt3_array;
always @(posedge clk, negedge rst_n) begin
    valid <= 1;
end
*/




/*
always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        cnt_2 <= 0;
        for(n=0; n<95; n=n+1) begin
            outrslt_array[n] <= 0;
        end
    end 
    
    else if(run) begin
        if (cnt_2 == 99) begin
            cnt_2 <= 0;
            cnt_saved <= 0;
        end else begin
            cnt_2 <= cnt_2 + 1;
        end
        
        if (cnt_2 == (4*cnt_saved)+7)begin
            cnt_saved <= cnt_saved + 1;
            midrslt_array[cnt_saved] <= midrslt_array[0] + midrslt_array[1] + midrslt_array[2] + midrslt_array[3];
        end
    end
    
    else begin
        cnt_2 <= 0;
        cnt_saved <= 0;
        for(n=0; n<3; n=n+1) begin
            midrslt_array[n] <= 0;
        end
end






always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        cnt_2 <= 0;
        cnt_saved <= 0;
        for(n=0; n<95; n=n+1) begin
            outrslt_array[n] <= 0;
        end
    end 
    
    else if(run) begin
        if (cnt_2 == 99) begin
            cnt_2 <= 0;
            cnt_saved <= 0;
        end else begin
            cnt_2 <= cnt_2 + 1;
        end
        
        if (cnt_2 == (4*cnt_saved)+7)begin
            cnt_saved <= cnt_saved + 1;
            midrslt_array[cnt_saved] <= midrslt_array[0] + midrslt_array[1] + midrslt_array[2] + midrslt_array[3];
        end
    end
    
    else begin
        cnt_2 <= 0;
        cnt_saved <= 0;
        for(n=0; n<3; n=n+1) begin
            midrslt_array[n] <= 0;
        end
end


*/














/*
always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        add2_array <= 0;
    end 
    
    else if(run) begin
        add2_array <= add1_array[0] + add1_array[1] + add1_array[2];
    end
    
    else begin
        add2_array <= 0;
    end
end
*/





endmodule
