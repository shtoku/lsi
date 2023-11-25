`include "num_data.v"

module data_in_src(
    input wire clk, 
    input wire rst_n, 
    input wire run, 
    input wire [4*`BIT_LENGTH*`DATA_N-1:0] input_data, 
    output reg [`BIT_LENGTH*`DATA_N-1:0] output_data
);

reg [15:0] cnt_1, cnt_2;



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
    end 
    
    else begin
        cnt_1 <= 0;
        cnt_2 <= 0;
        output_data <= 0;
    end
end


endmodule