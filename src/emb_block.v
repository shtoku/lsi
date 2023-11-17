`include "consts.vh"

module emb_block (
    input  wire clk,
    input  wire rst_n,
    input  wire run,//ここらへんは決まってる
    input  wire [`CHAR_LEN-1:0] d,//8
    output wire valid,
    output reg  [`EMB_DIM*`N_LEN-1:0] q//24*16
  ); 


  genvar i;
  integer j;

  // reg/wire rom
  reg  [13-1:0] addr;//2^13>4800
  wire [`N_LEN-1:0] rom_q;//rom_qはrom.vの出力を表している

  // 
  reg  [4:0] count;//emb_dim 24time count
  reg  [`N_LEN-1:0] q_buf [0:`EMB_DIM-1];//q_bufはrom.vで出力された

  assign valid = (count == `EMB_DIM + 1);


  // convert shape (EMB_DIM*N_LEN, ) <- (EMB_DIM, N_LEN)
  generate
    for (i = 0; i < `EMB_DIM; i = i + 1) begin
      assign q[i*`N_LEN +: `N_LEN] = q_buf[i];//0~15 <- mem[0] , q[16:0]==q_buf[0]
    end
  endgenerate


  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      count <= 0;
      addr  <= 0;
      for (j = 0; j < `EMB_DIM; j = j + 1) begin
        q_buf[j] <= 0;
      end
    end else if (run & count == 0) begin
      count <= count + 1;
      addr  <= addr  + 1;
    end else if (run & count != `EMB_DIM + 1) begin//not 24
      count <= count + 1;
      addr  <= addr  + 1;
      q_buf[count-1] <= rom_q; //addr[1]->rom_q[1]->q
    end else if (run) begin
      count <= count;
      addr  <= addr;
    end else begin
      count <= 0;
      addr  <= `EMB_DIM * d;
    end
  end


  // instance import rom.v
  emb_rom emb_rom_inst (
    .clk(clk),
    .addr(addr),
    .q(rom_q)//qの値をrom_qに渡す
  );



  
endmodule