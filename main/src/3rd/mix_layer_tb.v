`define clk_num 0.5 //clk_scaleの半分にする
`define clk_scale 1 //1clock = timescale*clk_scale
`define all_clock 1000

`timescale 10ns / 100ps
`define BIT_LENGTH 16
`define HID_LENGTH 24
`define DATA_N 6
`define STATE_LEN 4
`define DATA_ALL 96

module mix_layer_tb();
reg clk, rst_n, run;
reg [`STATE_LEN-1:0] state;
reg [`HID_LENGTH*`HID_LENGTH*`BIT_LENGTH-1:0] input_data;
wire [`HID_LENGTH*`HID_LENGTH*`BIT_LENGTH-1:0] input_data_1;
wire [`HID_LENGTH*`HID_LENGTH*`BIT_LENGTH-1:0] input_data_2;
wire [`HID_LENGTH*`HID_LENGTH*`BIT_LENGTH-1:0] input_data_3;
wire [`HID_LENGTH*`HID_LENGTH*`BIT_LENGTH-1:0] output_data;

genvar x, y;

//デバック用
reg [`BIT_LENGTH-1:0] input_data_array_1[0:`HID_LENGTH*`HID_LENGTH-1];
reg [`BIT_LENGTH-1:0] input_data_array_2[0:`HID_LENGTH*`HID_LENGTH-1];
reg [`BIT_LENGTH-1:0] input_data_array_3[0:`HID_LENGTH*`HID_LENGTH-1];
wire [`BIT_LENGTH-1:0] output_data_array [0:`HID_LENGTH-1][0:`HID_LENGTH-1];

reg [15:0] cnt;

//インスタンス化
mix_layer mix_layer(
    .clk(clk), 
    .rst_n(rst_n), 
    .run(run), 
    .state(state), 
    .data_in(input_data), 
    .valid(valid), 
    .data_out(output_data)
);

//クロック部
initial begin
    clk <= 1;
    
    #`all_clock
    $finish;
end

always #`clk_num begin
    clk <= ~clk;
end




//デバック用
//入力部分
generate
    for(x=0; x<576; x=x+1) begin :set_input_data_1
        assign input_data_1[`BIT_LENGTH*(x+1)-1 : `BIT_LENGTH*x] = input_data_array_1[x];
    end
endgenerate

generate
    for(x=0; x<576; x=x+1) begin :set_input_data_2
        assign input_data_2[`BIT_LENGTH*(x+1)-1 : `BIT_LENGTH*x] = input_data_array_2[x];
    end
endgenerate

generate
    for(x=0; x<576; x=x+1) begin :set_input_data_3
        assign input_data_3[`BIT_LENGTH*(x+1)-1 : `BIT_LENGTH*x] = input_data_array_3[x];
    end
endgenerate

//出力部分
generate
    for(x=0; x<24; x=x+1) begin :set_output_array1_1
        for(y=0; y<24; y=y+1) begin :set_output_array1_2
            assign output_data_array[x][y] = output_data[`BIT_LENGTH*(24*x+y+1)-1 : `BIT_LENGTH*(24*x+y)];
        end
    end
endgenerate
//デバック用終了




//レジスタにデータをセット
initial begin
    $readmemb("../../data/tb/mix_layer1_in_tb.txt", input_data_array_1);
end

initial begin
    $readmemb("../../data/tb/mix_layer2_in_tb.txt", input_data_array_2);
end

initial begin
    $readmemb("../../data/tb/mix_layer3_in_tb.txt", input_data_array_3);
end


//validに応じてrunを0にする回路
always @(posedge clk, negedge rst_n) begin
    if (valid) begin
        run <= 0;
    end
end


always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        cnt <= 0;
    end else begin
        cnt <= cnt + 1;
    end
end


function [`HID_LENGTH*`HID_LENGTH*`BIT_LENGTH-1:0] input_select;
    input [2:0] selecter;
    input [`HID_LENGTH*`HID_LENGTH*`BIT_LENGTH-1:0] indata_1;
    input [`HID_LENGTH*`HID_LENGTH*`BIT_LENGTH-1:0] indata_2;
    input [`HID_LENGTH*`HID_LENGTH*`BIT_LENGTH-1:0] indata_3;
    
    case(selecter)
        3'b000 : input_select = indata_1;
        3'b001 : input_select = indata_2;
        3'b010 : input_select = indata_3;
    endcase
endfunction


//本体
initial begin
    $dumpvars;
        rst_n <= 0;
        run <= 0;
        input_data <= 0;
        state <= 4'b0011;
        
    #12
        rst_n <= 1;
        input_data <= input_select(0,input_data_1,input_data_2,input_data_3);
        state <= 4'b0011;


    #11.1//0クロック目
        run <= 1;
    #0.9



    #103
        state <= 4'b0100;
    #5
        run <= 1;
        input_data <= input_select(1,input_data_1,input_data_2,input_data_3);

   
    #103
        state <= 4'b0101;
    #5
        run <= 1;
        input_data <= input_select(2,input_data_1,input_data_2,input_data_3);


    #130
    $finish;

end

endmodule