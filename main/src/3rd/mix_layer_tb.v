// 作り直した

`define BIT_LENGTH 16
`define HID_LENGTH 24
`define DATA_N 6
`define STATE_LEN 4
`define DATA_ALL 96

module mix_layer_tb();

reg clk;
reg rst_n;
reg run;
reg [`STATE_LEN-1:0] state;
wire [`HID_LENGTH*`HID_LENGTH*`BIT_LENGTH-1:0] data_in;
wire valid;
wire [`HID_LENGTH*`HID_LENGTH*`BIT_LENGTH-1:0] data_out;

mix_layer mix_layer_inst (.*);


genvar i;

reg [`BIT_LENGTH-1:0] d_mem [0:`HID_LENGTH*`HID_LENGTH-1];
reg [`BIT_LENGTH-1:0] q_mem [0:`HID_LENGTH*`HID_LENGTH-1];
wire [`HID_LENGTH*`HID_LENGTH*`BIT_LENGTH-1:0] q_ans;
wire correct;

assign correct = (data_out == q_ans);

generate
    for (i = 0; i < `HID_LENGTH*`HID_LENGTH; i = i + 1) begin
        assign data_in[i*`BIT_LENGTH +: `BIT_LENGTH] = d_mem[i];
        assign   q_ans[i*`BIT_LENGTH +: `BIT_LENGTH] = q_mem[i];
    end
endgenerate

initial begin
    $readmemb("../../data/tb/mix_layer3_in_tb.txt",  d_mem);
    $readmemb("../../data/tb/mix_layer3_out_tb.txt", q_mem);
end


initial clk = 0;
always #5 clk = ~clk;

//本体
initial begin
    $dumpvars;
    rst_n=0; run=0; state=`STATE_LEN'd0; #10
    rst_n=1; #10
    state=`STATE_LEN'd5; #10
    run=1; #10
    #1030
    $finish;
end

endmodule