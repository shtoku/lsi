`timescale 10ns / 100ps
`define clk_num 0.5 //clk_scaleの半分にする
`define clk_scale 1 //1clock = timescale*clk_scale
`define all_clock 1000

`define BIT_LENGTH 16
`define HID_LENGTH 24
`define DATA_N 6


module main_src_test();
reg clk, rst_n, run;
reg [1:0] selecter;
reg [4*`BIT_LENGTH*`DATA_N-1:0] input_data;
wire [`HID_LENGTH*`BIT_LENGTH-1:0] output_data;
genvar yy;

//デバック用
reg [4*`BIT_LENGTH*`DATA_N-1:0] input_data_array [0:2];
wire [`BIT_LENGTH-1:0] output_data_array [0:`HID_LENGTH-1];

//インスタンス化
main_src main_src(.clk(clk), .rst_n(rst_n), .run(run), .valid(valid), .data_in(input_data), .selecter(selecter), .data_out(output_data));

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
generate
    for(yy=0; yy<24; yy=yy+1) begin :set_array
        assign output_data_array[yy] = output_data[`BIT_LENGTH*(yy+1)-1 : `BIT_LENGTH*yy];
    end
endgenerate

initial begin
    $readmemb("/home/hirahara/lsi_data/indata_1.txt", input_data_array);
end

always @(posedge clk, negedge rst_n) begin
    if (valid) begin
        run <= 0;
    end
end


//本体
initial begin
    $dumpvars;
        rst_n <= 0;
        run <= 0;
        input_data <= 0;
        selecter <=0;
        
    #12
        rst_n <= 1'b1;
        input_data <= 0;

    #11.1//0クロック目
        run <= 1;
        input_data <= input_data_array[0];
        selecter <=0;
    #12
    $finish;

end

endmodule