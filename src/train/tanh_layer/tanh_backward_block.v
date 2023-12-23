`include "consts_train.vh"

module tanh_backward_block (
    input  wire clk,
    input  wire rst_n,
    input  wire run,
    input  wire [`HID_DIM*`N_LEN-1:0] d,
    input  wire [`HID_DIM*`N_LEN_W-1:0] q_forward,
    output wire valid,
    output wire [`HID_DIM*`N_LEN-1:0] q_backward
  );

  
  // ----------------------------------------
  genvar i;
  integer j;

  // reg/ input/output buffer
  wire [`N_LEN-1:0] d_buf [0:`HID_DIM-1];
  wire [`N_LEN_W-1:0] q_forward_buf  [0:`HID_DIM-1];
  reg  [`N_LEN-1:0] q_backward_buf [0:`HID_DIM-1];

  // wire buf_index
  wire [4:0] d_buf_index, q_forward_index, q_backward_index;

  // reg counter
  reg  [4:0] count1, count1_delay [0:2];

  // reg calculate
  reg  [`N_LEN_W-1:0] mul_forward, sub;


  // ----------------------------------------
  // assign valid
  assign valid = run & (count1_delay[2] == `HID_DIM - 1);

  generate
    for (i = 0; i < `HID_DIM; i = i + 1) begin
      // convert shape (`HID_DIM, `N_LEN) <-> (`HID_DIM*`N_LEN,)
      assign d_buf[i] = d[i*`N_LEN +: `N_LEN];
      assign q_forward_buf[i] = q_forward[i*`N_LEN_W +: `N_LEN_W];
      assign q_backward[i*`N_LEN +: `N_LEN] = q_backward_buf[i];
    end
  endgenerate

  // assign index
  assign d_buf_index      = count1_delay[1];
  assign q_forward_index  = count1;
  assign q_backward_index = count1_delay[1];


  // fucntion fixed multiply 
  function [`N_LEN_W-1:0] fixed_mul1;
    input signed [`N_LEN_W-1:0] num1, num2;
    reg [2*`N_LEN_W-1:0] mul;
    begin
      mul = num1 * num2;
      fixed_mul1 = mul[`F_LEN_W +: `N_LEN_W]; 
    end
  endfunction

  // fucntion fixed multiply 
  function [`N_LEN-1:0] fixed_mul2;
    input signed [`N_LEN-1:0] num1;
    input signed [`N_LEN_W-1:0] num2;

    reg [`N_LEN+`N_LEN_W-1:0] mul;
    begin
      mul = num1 * num2;
      fixed_mul2 = mul[`F_LEN +: `N_LEN]; 
    end
  endfunction


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
      for (j = 0; j < 3; j = j + 1) begin
        count1_delay[j] <= 0;
      end
    end else begin
      count1_delay[0] <= count1;
      for (j = 0; j < 2; j = j + 1) begin
        count1_delay[j+1] <= count1_delay[j];
      end
    end
  end

  // calculate q_forward * q_forward
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      mul_forward <= 0;
    end else begin
      mul_forward <= fixed_mul1(q_forward_buf[q_forward_index], q_forward_buf[q_forward_index]);
    end
  end

  // calculate 1.0 - q_forward * q_forward
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      sub <= 0;
    end else begin
      sub <= {`I_LEN_W'd1, {`F_LEN_W{1'b0}}} - mul_forward;
    end
  end

  // output controller
  always @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
      for (j = 0; j < `HID_DIM; j = j + 1) begin
        q_backward_buf[j] <= 0;
      end
    end else if (run & ~valid) begin
      q_backward_buf[q_backward_index] <= fixed_mul2(d_buf[d_buf_index], sub);
    end
  end

endmodule