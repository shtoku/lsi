`include "consts.vh"

module dense_block (
    input  wire clk,
    input  wire rst_n,
    input  wire run,//ここらへんは決まってる
    input  wire [`CHAR_LEN-1:0] d,//8,2^8>200であるため8bit用意
    output wire valid,
    output wire  [`HID_DIM*`N_LEN-1:0] q//24*16
  ); 


  genvar i;
  integer j;

  // reg/wire rom
  reg  [10-1:0] addr;//2^10>800
  wire [`DATA_N*`N_LEN-1:0] rom_q;//rom_qはrom.vの出力を表している。6*16

  // 
  reg  [4:0] count;//HID_DIM 24time count
  reg  [`DATA_N*`N_LEN-1:0] q_buf [0:`HID_DIM/`DATA_N-1];//q_bufはrom.vで出力された。16bitの数字が24個

  assign valid = (count == `HID_DIM/`DATA_N + 1);


  // convert shape (HID_DIM*N_LEN, ) <- (HID_DIM, N_LEN)
  generate
    for (i = 0; i < `HID_DIM/`DATA_N; i = i + 1) begin
      assign q[i*`DATA_N*`N_LEN +: `DATA_N*`N_LEN] = q_buf[i];
    end
  endgenerate


  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      count <= 0;
      addr  <= 0;
      for (j = 0; j < `HID_DIM/`DATA_N; j = j + 1) begin
        q_buf[j] <= 0;
      end
    end else if (run & count == 0) begin
      count <= count + 1;
      addr  <= addr  + 1;
    end else if (run & count != `HID_DIM/`DATA_N + 1) begin//not 24
      count <= count + 1;
      addr  <= addr  + 1;
      q_buf[count-1] <= rom_q; //addr[1]->rom_q[1]->q
    end else if (run) begin
      count <= count;
      addr  <= addr;
    end else begin
      count <= 0;
      addr  <= `HID_DIM/`DATA_N * d;
    end
  end


  // instance import rom.v
  dense_rom dense_rom_inst (
    .clk(clk),
    .addr(addr),
    .q(rom_q)//qの値をrom_qに渡す
  );



  
endmodule