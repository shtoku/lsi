`include "consts_train.vh"

module softmax_block #(
    parameter integer ADDR_WIDTH = 10     // D_I_LEN + D_F_LEN
  ) (
    input  wire clk,
    input  wire rst_n,
    input  wire run,
    input  wire [`CHAR_NUM*`N_LEN-1:0] d,
    input  wire [`CHAR_LEN-1:0] d_num,
    input  wire [`N_LEN-1:0] d_max,
    output wire valid,
    output wire [`CHAR_NUM*`N_LEN-1:0] q
  );


  // ----------------------------------------
  genvar i;
  integer j;

  // wire input buffer
  wire [`N_LEN-1:0] d_buf [0:`CHAR_NUM-1];
  reg  [`N_LEN-1:0] q_buf [0:`CHAR_NUM-1];

  // reg calculate buffer
  reg  [`N_LEN-1:0] sum;
  wire [`N_LEN-1:0] mul;
  wire [`N_LEN-1:0] sub_1;

  // reg counter
  reg [`CHAR_LEN-1:0] count1, count1_delay [0:5];

  // wire index
  wire [`CHAR_LEN-1:0] d_buf_index;
  wire [`CHAR_LEN-1:0] exp_index, sum_index, inv_index, inv_index_delay;
  reg  [`CHAR_LEN-1:0] mul_index, mul_index_delay;

  // wire softmax_exp_table
  wire [`N_LEN-1:0] exp_table_d;
  wire [`N_LEN_W-1:0] exp_table_q;

  // wire inverse_rom
  wire [ADDR_WIDTH-1:0] inv_addr;
  wire [`N_LEN_W-1:0] inv_data;


  // ----------------------------------------
  // assign valid
  assign valid = run & (mul_index_delay == `CHAR_NUM - 1);
  
  // convert shape (`CHAR_NUM, `N_LEN) <-> (`CHAR_NUM*`N_LEN,)
  generate
    for (i = 0; i < `CHAR_NUM; i = i + 1) begin
      assign d_buf[i] = d[i*`N_LEN +: `N_LEN] - d_max;
      assign q[i*`N_LEN +: `N_LEN] = q_buf[i];
    end
  endgenerate

  // assign calculate
  assign mul = fixed_mul(q_buf[mul_index], inv_data);
  assign sub_1 = mul - {`I_LEN_W'h1, {`F_LEN_W{1'b0}}};

  // assign index
  assign d_buf_index = count1;
  assign exp_index = count1_delay[2];
  assign sum_index = count1_delay[3];
  assign inv_index = count1_delay[4];
  assign inv_index_delay = count1_delay[5];

  // assign softmax_exp_table
  assign exp_table_d = d_buf[d_buf_index];

  // assign invese_rom
  assign inv_addr = sum[(`N_LEN-ADDR_WIDTH) +: ADDR_WIDTH];


  // fucntion fixed multiply 
  function [`N_LEN-1:0] fixed_mul;
    input [`N_LEN-1:0] num1;
    input [`N_LEN_W-1:0] num2;

    reg [`N_LEN+`N_LEN_W-1:0] mul;
    begin
      mul = num1 * num2;
      fixed_mul = mul[`F_LEN +: `N_LEN]; 
    end
  endfunction


  // ----------------------------------------
  // main counter
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      count1 <= 0;
    end else if (run) begin
      if (count1 != `CHAR_NUM - 1) begin
        count1 <= count1 + 1;
      end else begin
        count1 <= count1;
      end
    end else begin
      count1 <= 0;
    end
  end

  // count delay
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      for (j = 0; j < 6; j = j + 1) begin
        count1_delay[j] <= 0;
      end
    end else begin
      count1_delay[0] <= count1;
      for (j = 0; j < 5; j = j + 1) begin
        count1_delay[j+1] <= count1_delay[j];
      end
    end
  end

  // mul_index controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      mul_index <= 0;
      mul_index_delay <= 0;
    end else if (inv_index_delay == `CHAR_NUM - 1) begin
      if (mul_index != `CHAR_NUM - 1) begin
        mul_index <= mul_index + 1;
      end else begin
        mul_index <= mul_index;
      end
      mul_index_delay <= mul_index;
    end else begin
      mul_index <= 0;
      mul_index_delay <= mul_index;
    end
  end


  // exp & multiply controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      for (j = 0; j < `HID_DIM; j = j + 1) begin
        q_buf[j] <= 0;
      end
    end else if (run) begin
      if (sum_index != `CHAR_NUM - 1) begin
        q_buf[exp_index] <= exp_table_q;
      end else if ((inv_index_delay == `CHAR_NUM - 1) & (mul_index_delay != `CHAR_NUM - 1)) begin
        if (mul_index == d_num) begin
          q_buf[mul_index] <= {{`BATCH_SHIFT{sub_1[`N_LEN-1]}}, sub_1[`N_LEN-1:`BATCH_SHIFT]};
        end else begin
          q_buf[mul_index] <= {{`BATCH_SHIFT{mul[`N_LEN-1]}}, mul[`N_LEN-1:`BATCH_SHIFT]};          
        end
      end
    end
  end

  // sum controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      sum <= 0;
    end else if (run) begin
      if ((exp_index != 0) & (inv_index != `CHAR_NUM - 1)) begin
        sum <= sum + q_buf[sum_index];
      end
    end else begin
      sum <= 0;
    end
  end


  // ----------------------------------------
  // softmax_exp_table
  softmax_exp_table #(
    .ADDR_WIDTH(ADDR_WIDTH)
  ) softmax_exp_table_inst (
    .clk(clk),
    .rst_n(rst_n),
    .d(exp_table_d),
    .q(exp_table_q)
  );

  // softmax_inverse_rom
  rom #(
    .FILENAME("../../data/parameter/train/binary18/inverse_table.txt"),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(`N_LEN_W),
    .DATA_DEPTH(2**ADDR_WIDTH)
  ) softmax_inv_rom (
    .clk(clk),
    .raddr(inv_addr),
    .rdata(inv_data)
  );



  
endmodule