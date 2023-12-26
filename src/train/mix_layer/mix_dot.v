`include "consts_train.vh"

module mix_dot (
    input  wire clk, 
    input  wire rst_n, 
    input  wire run, 
    output wire valid, 
    input  wire [`DATA_N*`N_LEN-1:0] d, 
    input  wire [`DATA_N*`N_LEN_W-1:0] rdata_w, 
    input  wire [`N_LEN_W-1:0] rdata_b, 
    output wire [`HID_DIM*`N_LEN-1:0] q
  );


  // ----------------------------------------
  integer n;
  genvar xx, yy, zz;

  // wire input buffer
  wire [`N_LEN-1:0] indata_array [0:`DATA_N-1];
  wire [`N_LEN_W-1:0] inweight_array [0:`DATA_N-1];

  // reg multiply or add
  reg [`N_LEN-1:0] outdot_array [0:`DATA_N-1];
  reg [`N_LEN-1:0] add1_array [0:2];

  // reg wait and add
  reg [`N_LEN-1:0] midrslt1_array [0:1];
  // reg [`N_LEN-1:0] midrslt2_array [0:1];
  reg [`N_LEN-1:0] midrslt3_array;

  // reg ouput buffer
  reg [`N_LEN-1:0] outrslt_array [0:`HID_DIM-1];

  // reg counter
  reg count1;
  reg [7:0] count2, count3, count4;

  
  // ----------------------------------------
  // assign valid
  assign valid = run & (count2 == 29);

  // convert shape (`DATA_N, `N_LEN) <- (`DATA_N*`N_LEN)
  generate
    for(yy = 0; yy < `DATA_N; yy = yy + 1) begin :set_in_array
      assign indata_array[yy] = d[yy*`N_LEN +: `N_LEN];
      assign inweight_array[yy] = rdata_w[yy*`N_LEN_W +: `N_LEN_W];
    end
  endgenerate

  // convert shape (`DATA_N*`N_LEN) <- (`DATA_N, `N_LEN)
  generate
    for(zz = 0; zz < `HID_DIM; zz = zz + 1) begin :set_out_array
      assign q[`N_LEN*zz +: `N_LEN] = outrslt_array[zz];
    end
  endgenerate


  // function fixed_multiply
  function [`N_LEN-1:0] product;
    input signed [`N_LEN-1:0] in_func_1;
    input signed [`N_LEN_W-1:0] in_func_2;
    
    reg [`N_LEN+`N_LEN_W-1:0] func1_midrslt;
    begin
      func1_midrslt = in_func_1 * in_func_2;
      product = func1_midrslt[`F_LEN +: `N_LEN]; 
    end
  endfunction


  // ----------------------------------------
  // fixed multiply
  generate
    for(xx = 0; xx < `DATA_N; xx = xx + 1) begin :dot_1
      always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
          outdot_array[xx] <= 0;
        end else if(run) begin
          outdot_array[xx] <= product(indata_array[xx], inweight_array[xx]) ;
        end else begin
          outdot_array[xx] <= 0;
        end
      end
    end
  endgenerate

  // first add
  generate
    for(yy = 0; yy < 3; yy = yy + 1) begin :add_1
      always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
          add1_array[yy] <= 0;
        end else if(run) begin
          add1_array[yy] <= outdot_array[2*yy] + outdot_array[2*yy+1];
        end else begin
          add1_array[yy] <= 0;
        end
      end
    end
  endgenerate

  // second, third, fourth add
  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      count1 <= 0;
      for (n = 0; n < 2; n = n + 1) begin
        midrslt1_array[n] <= 0;
      end
      // for (n = 0; n < 2; n = n + 1) begin
      //   midrslt2_array[n] <= 0;
      // end
      midrslt3_array <= 0;
    end else if(run) begin
      count1 <= count1 + 1;
      midrslt1_array[count1] <= add1_array[0] + add1_array[1] + add1_array[2];  // second
      // midrslt2_array[0] <= midrslt1_array[0] + midrslt1_array[1];               // third
      // midrslt2_array[1] <= midrslt1_array[2] + midrslt1_array[3];               // third
      midrslt3_array <= midrslt1_array[0] + midrslt1_array[1];                  // fourth
    end else begin
      count1 <= 0;
      for(n = 0; n < 2; n = n + 1) begin
        midrslt1_array[n] <= 0;
      end
      // for(n = 0; n < 2; n = n + 1) begin
      //   midrslt2_array[n] <= 0;
      // end
      midrslt3_array <= 0;
    end
  end

  // add bias
  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      count2 <= 0;
      count3 <= 0;
      count4 <= 0;
      for(n = 0; n < `HID_DIM; n = n + 1) begin
        outrslt_array[n] <= 0;
      end
    end else if(run) begin
      if (count2 == 29) begin
        count2 <= count2;
      end else begin
        count2 <= count2 + 1;
      end
      if (count2 == count4 + 6)begin
        count3 <= count3 + 1;
        count4 <= count4 + 2;
        outrslt_array[count3] <= midrslt3_array + {{(`N_LEN-`N_LEN_W){rdata_b[`N_LEN_W-1]}}, rdata_b};
      end
    end else begin
      count2 <= 0;
      count3 <= 0;
      count4 <= 0;
    end
  end 


endmodule