`include "consts.vh"

module emb_layer (
    input  wire clk,
    input  wire rst_n,
    input  wire run,//ここらへんは決まってる
    input  wire [`N*`CHAR_LEN-1:0] d,//10*8,dには1~200の数字が入る
    output wire valid,
    output wire  [`N*`EMB_DIM*`N_LEN-1:0] q//10*24*16,縦10個、横24*16
  ); 


  genvar i;

  wire [`CHAR_LEN-1:0] d_buf [0:`N-1];//ここはwireでいい。`CHAR_LENビットの数字が`N個あるイメージ
  wire [`EMB_DIM*`N_LEN-1:0] q_buf [0:`N-1];
  wire [`N-1:0] valid_buf ;


  assign valid = &valid_buf;
  
  generate
    for (i = 0; i < `N; i = i + 1) begin
      // convert shape (`N, `CHAR_LEN) <- (`N*`CHAR_LEN, )
      assign d_buf[i] = d[i*`CHAR_LEN +: `CHAR_LEN];//d_buf[0]=d[7:0]

      // convert shape (`N*`EMB_DIM*`N_LEN, ) <- (`N, `EMB_DIM*`N_LEN)
      assign q[i*`EMB_DIM*`N_LEN +: `EMB_DIM*`N_LEN] = q_buf[i];//q[24*16:0]=q_buf[0]
    end
  endgenerate


  generate
    for (genvar i = 0; i < `N; i=i+1) begin
      emb_block emb_block_inst (
        .clk(clk),
        .rst_n(rst_n),
        .run(run),
        .d(d_buf[i]),
        .valid(valid_buf[i]),
        .q(q_buf[i])
      );
    end
  endgenerate

  
endmodule