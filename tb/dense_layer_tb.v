`include "consts.vh"

module dense_layer_tb ();

    reg  clk;
    reg  rst_n;
    reg  run;//ここらへんは決まってる
    reg  [`N*`HID_DIM*`N_LEN-1:0] d;
    wire valid;
    wire [`N*`CHAR_NUM*`N_LEN-1:0] q;//10*200*16;縦10個、横24*16

    dense_layer dense_layer_inst (.*);

    reg  [`N_LEN-1:0] d_mem [0:`N*`HID_DIM-1];

    genvar i;

    generate
        for (i = 0; i < `N*`HID_DIM; i = i + 1) begin
            assign d[i*`N_LEN +: `N_LEN] = d_mem[i];
        end
    //     for (i = 0; i < `N*`EMB_DIM; i = i + 1) begin
    //         assign q_ans[i*`N_LEN +: `N_LEN] = q_mem[i];
    //     end
    endgenerate

    initial begin
        $readmemb("../data/tb/dense_layer_in_tb.txt", d_mem);
        // $readmemb("../data/tb/emb_layer_out_tb.txt", q_mem);
    end


    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpvars;
        rst_n=0; run=0; #10
        rst_n=1; #10
        run=1; #10
        #55000
        $display("%h\n", q);
        $finish;
    end
 

endmodule