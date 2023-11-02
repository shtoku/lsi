`timescale 10ns / 100ps
`define clk_num 0.5 //clk_scaleの半分にする
`define clk_scale 1 //1clock = timescale*clk_scale
`define all_clock 1000


//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/27/2023 06:09:24 PM
// Design Name: 
// Module Name: compute_logic_test
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

//module main_dot(clk, rst_n, run, valid, data_in, weight_in, data_out);

module main_dot_testv2();
reg clk, rst_n, run;
reg [`DATA_N*`BIT_LENGTH-1:0] data_in, weight_in;
wire [`HID_LENGTH*`BIT_LENGTH-1:0] data_out;
wire valid;


main_dotv2 main_dotv2(.clk(clk), .rst_n(rst_n), .run(run),.valid(valid), .data_in(data_in), .weight_in(weight_in), .data_out(data_out));

initial begin
    $monitor("%t: %b, %b, %b, %b, %d, %d, %d", $time, rst_n, run, clk, valid, data_in, weight_in, data_out);
end


//クロック部
initial begin
    clk <= 1;
    
    #`all_clock
    $finish;
end

always #`clk_num begin
    clk <= ~clk;
end


//本体
initial begin
        rst_n <= 1'b0;
        run <= 0;
        data_in <= 0;
        weight_in <= 0;

        
    #12
        rst_n <= 1'b1;
/*
    #12
        run <= 1;
        data_in <= {`BIT_LENGTH'd3, `BIT_LENGTH'd5, `BIT_LENGTH'd1, `BIT_LENGTH'd5, `BIT_LENGTH'd8, `BIT_LENGTH'd9};
        weight_in <= {`BIT_LENGTH'd2, `BIT_LENGTH'd5, `BIT_LENGTH'd9, `BIT_LENGTH'd2, `BIT_LENGTH'd3, `BIT_LENGTH'd5};

*/


    #12
        run <= 1;
        data_in <= {16'd3, 16'd5, 16'd1, 16'd5, 16'd8, 16'd9};
        weight_in <= {16'd2, 16'd5, 16'd9, 16'd2, 16'd3, 16'd5};
    
    #`clk_scale
        data_in <= {16'd5, 16'd6, 16'd1, 16'd2, 16'd3, 16'd4};
        weight_in <= {16'd2, 16'd2, 16'd4, 16'd5, 16'd1, 16'd2};
    
    #`clk_scale
        data_in <= {16'd8, 16'd14, 16'd2, 16'd5, 16'd9, 16'd1};
        weight_in <= {16'd5, 16'd7, 16'd1, 16'd2, 16'd5, 16'd6};
    
    #`clk_scale
        data_in <= {16'd3, 16'd6, 16'd4, 16'd1, 16'd5, 16'd2};
        weight_in <= {16'd9, 16'd5, 16'd5, 16'd6, 16'd2, 16'd7};
        
    #`clk_scale
        data_in <= {16'd8, 16'd2, 16'd5, 16'd8, 16'd1, 16'd3};
        weight_in <= {16'd1, 16'd3, 16'd5, 16'd8, 16'd7, 16'd5};
        
    #`clk_scale
        data_in <= {16'd2, 16'd3, 16'd5, 16'd5, 16'd1, 16'd7};
        weight_in <= {16'd8, 16'd5, 16'd3, 16'd1, 16'd8, 16'd2};
        
    #`clk_scale
        data_in <= {16'd4, 16'd9, 16'd5, 16'd7, 16'd9, 16'd3};
        weight_in <= {16'd6, 16'd6, 16'd5, 16'd3, 16'd7, 16'd5};
        
    #`clk_scale
        data_in <= {16'd12, 16'd12, 16'd6, 16'd5, 16'd8, 16'd7};
        weight_in <= {16'd2, 16'd9, 16'd8, 16'd11, 16'd6, 16'd2};
    
    

end

endmodule