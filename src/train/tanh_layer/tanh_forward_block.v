`include "consts_train.vh"

module tanh_forward_block (
    input  wire clk,
    input  wire rst_n,
    input  wire run,
    input  wire [`HID_DIM*`N_LEN-1:0] d,
    output wire valid,
    output wire [`HID_DIM*`N_LEN_W-1:0] q
  );

  
  // ----------------------------------------
  genvar i;
  integer j;

  // reg/wire input/output buffer
  wire [`N_LEN-1:0] d_buf [0:`HID_DIM-1];
  reg  [`N_LEN_W-1:0] q_buf [0:`HID_DIM-1];

  // wire buf_index
  wire [4:0] d_buf_index, q_buf_index;

  // reg counter
  reg  [4:0] count1, count1_delay [0:3];

  // wire tanh_table
  wire [`N_LEN-1:0] tanh_table_d;
  wire [`N_LEN_W-1:0] tanh_table_q;

  
  // ----------------------------------------
  // assign valid
  assign valid = run & (count1_delay[3] == `HID_DIM - 1);

  generate
    for (i = 0; i < `HID_DIM; i = i + 1) begin
      // convert shape (`HID_DIM, `N_LEN) <-> (`HID_DIM*`N_LEN,)
      assign d_buf[i] = d[i*`N_LEN +: `N_LEN];
      assign q[i*`N_LEN_W +: `N_LEN_W] = q_buf[i];
    end
  endgenerate

  // assign index
  assign d_buf_index = count1;
  assign q_buf_index = count1_delay[2];

  // assign tanh_table
  assign tanh_table_d = d_buf[d_buf_index];


  // ----------------------------------------
  // main counter
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      count1 <= 0;
    end else if (run) begin
      if (count1 != `HID_DIM - 1) begin
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
      for (j = 0; j < 4; j = j + 1) begin
        count1_delay[j] <= 0;
      end
    end else begin
      count1_delay[0] <= count1;
      for (j = 0; j < 3; j = j + 1) begin
        count1_delay[j+1] <= count1_delay[j];
      end
    end
  end

  // q_buf controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      for (j = 0; j < `HID_DIM; j = j + 1) begin
        q_buf[j] <= 0;
      end
    end else if (run) begin
      q_buf[q_buf_index] <= tanh_table_q;
    end
  end


  // ----------------------------------------
  // tanh_table
  tanh_table tanh_table (
    .clk(clk),
    .rst_n(rst_n),
    .d(tanh_table_d),
    .q(tanh_table_q)
  );


endmodule