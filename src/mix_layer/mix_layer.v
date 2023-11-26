`include "num_data.v"

module mix_layer(
    input wire clk, 
    input wire rst_n, 
    input wire run, 
    input wire [`STATE_LEN-1:0] state, 
    input wire [`HID_LENGTH*`HID_LENGTH*`BIT_LENGTH-1:0] data_in, 
    output wire valid, 
    output wire [`HID_LENGTH*`HID_LENGTH*`BIT_LENGTH-1:0] data_out
);

wire [24*24*16:0] input_line;
wire [24*16-1:0] input_array [0:24-1];
wire [24*16-1:0] output_array [0:24-1];
wire [24*24*16:0] output_line;

genvar x, y;


//入力データを並び替える回路
//転置回路
generate
    for(x=0; x<24; x=x+1) begin :transpose_1
        for(y=0; y<24; y=y+1) begin :transpose_2
            assign input_line[(24*x+y)*`BIT_LENGTH +: `BIT_LENGTH] = data_in[(24*y+x)*`BIT_LENGTH +: `BIT_LENGTH];
        end
    end
endgenerate

//入力データを並び替える回路
//一列に並び替える回路
generate
    for(x=0; x<24; x=x+1) begin :set_in_array_1
        assign input_array[x] = input_line[24*16*x +: 24*16];
    end
endgenerate


//メインの回路を24個インスタンス化
generate
    for(x=0; x<24; x=x+1) begin :main_inst_1
        main_src #(
            .filenum(x)
            ) main_src(
                .clk(clk), 
                .rst_n(rst_n), 
                .run(run), 
                .valid(valid), 
                .data_in(input_array[x]), 
                .state(state), 
                .data_out(output_array[x])
        );
    end
endgenerate


//出力を並び替える回路
generate
    for(x=0; x<24; x=x+1) begin :set_out_array_1
        assign data_out[24*16*x +: 24*16] = output_array[x];
    end
endgenerate


endmodule
