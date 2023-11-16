`timescale 1ns / 1ps

`define BIT_LENGTH 16
`define HID_LENGTH 24
`define DATA_N 6
`define DATA_ALL 96

module data_in_src(clk, rst_n, run, input_data, output_data);
input clk, rst_n, run;
input [4*`BIT_LENGTH*`DATA_N-1:0] input_data;
output reg [`BIT_LENGTH*`DATA_N-1:0] output_data;

reg [15:0] cnt_1, cnt_2;

/*
always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        output_data <= 0;
        cnt_1 <= 0;
    end
    
    
    else if(run) begin
        if (cnt_1 == 95) begin
            cnt_1 <= 0;
        end else begin
            cnt_1 <= cnt_1 + 1;
        end
        output_weight <= mem[addr_bias+addr];
    end
    
    
    else begin
        output_weight <= 0;
        addr <= 0;
    end
end
*/


function [`BIT_LENGTH*`DATA_N-1:0] outdata_selecter;
    input [4*`BIT_LENGTH*`DATA_N-1:0] fn_input_data;
    input [`BIT_LENGTH*`DATA_N-1:0] selecter;
    
    case (selecter)
        0: outdata_selecter = fn_input_data[`BIT_LENGTH*`DATA_N-1:0];
        1: outdata_selecter = fn_input_data[2*`BIT_LENGTH*`DATA_N-1:`BIT_LENGTH*`DATA_N];
        2: outdata_selecter = fn_input_data[3*`BIT_LENGTH*`DATA_N-1:2*`BIT_LENGTH*`DATA_N];
        3: outdata_selecter = fn_input_data[4*`BIT_LENGTH*`DATA_N-1:3*`BIT_LENGTH*`DATA_N];
        default: outdata_selecter = 16'hxx;
    endcase
endfunction



always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        cnt_1 <= 0;
        cnt_2 <= 0;
        output_data <= 0;
    end
    

//    else if(run) begin
//        if (cnt_1 == 101) begin
//            cnt_1 <= 0;
//        end else begin
//            cnt_1 <= cnt_1 + 1;
//        end
        
//        if (cnt_2 == 3) begin
//            cnt_2 <= 0;
//        end else begin
//            cnt_2 <= cnt_2 + 1;
//        end
//        output_data <= outdata_selecter(input_data, cnt_2);
        
//        /*
//        case (cnt_2)
//            0: output_data <= input_data[`BIT_LENGTH*`DATA_N-1:0];
//            1: output_data <= input_data[2*`BIT_LENGTH*`DATA_N-1:`BIT_LENGTH*`DATA_N];
//            2: output_data <= input_data[3*`BIT_LENGTH*`DATA_N-1:2*`BIT_LENGTH*`DATA_N];
//            3: output_data <= [4*`BIT_LENGTH*`DATA_N-1:0]input_data;
//            default: output_data <= 8'h44;
//        endcase
//        */
//        /*    
//        //もともと+9で考えていたが間違っていた。
//        //ここの8を変えれば他の回路の余分クロックも考慮することができる
//        //main回路を1クロックずらせば+8でちょうど良くなるはず
//        if (cnt_1 == cnt_saved+8) begin
//            cnt_saved <= cnt_saved + 4;
//            output_data <= input_data[`BIT_LENGTH*`DATA_N-1:0];//biasはsignedにすべき？
//        end else if()

//        */
//    end
 
 
    else if(run) begin
        if (cnt_1 == 101) begin
            cnt_1 <= 0;
            cnt_2 <= 0;
        end else begin
            cnt_1 <= cnt_1 + 1;
            
            if (cnt_2 == 3) begin
                cnt_2 <= 0;
            end else begin
                cnt_2 <= cnt_2 + 1;
            end
                        
        end
        

        output_data <= outdata_selecter(input_data, cnt_2);
        
        /*
        case (cnt_2)
            0: output_data <= input_data[`BIT_LENGTH*`DATA_N-1:0];
            1: output_data <= input_data[2*`BIT_LENGTH*`DATA_N-1:`BIT_LENGTH*`DATA_N];
            2: output_data <= input_data[3*`BIT_LENGTH*`DATA_N-1:2*`BIT_LENGTH*`DATA_N];
            3: output_data <= [4*`BIT_LENGTH*`DATA_N-1:0]input_data;
            default: output_data <= 8'h44;
        endcase
        */
        /*    
        //もともと+9で考えていたが間違っていた。
        //ここの8を変えれば他の回路の余分クロックも考慮することができる
        //main回路を1クロックずらせば+8でちょうど良くなるはず
        if (cnt_1 == cnt_saved+8) begin
            cnt_saved <= cnt_saved + 4;
            output_data <= input_data[`BIT_LENGTH*`DATA_N-1:0];//biasはsignedにすべき？
        end else if()

        */
    end 
    
    
    else begin
        cnt_1 <= 0;
        cnt_2 <= 0;
        output_data <= 0;
    end
end


endmodule
