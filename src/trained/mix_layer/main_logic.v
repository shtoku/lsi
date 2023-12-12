`include "consts_trained.vh"

module main_logic(
    input  wire clk, 
    input  wire rst_n, 
    input  wire run, 
    output wire valid, 
    input  wire [`DATA_N*`N_LEN-1:0] data_in, 
    input  wire [`DATA_N*`N_LEN-1:0] weight_in, 
    input  wire [`N_LEN-1:0] bias_in, 
    output wire [`HID_DIM*`N_LEN-1:0] data_out
  );


  //掛け算のときだけ必ずsignedにする
  wire [`N_LEN-1:0] indata_array [0:`DATA_N-1];   //もともとsignedをつけていた
  wire [`N_LEN-1:0] inweight_array [0:`DATA_N-1]; //もともとsignedをつけていた


  reg [`N_LEN-1:0] outdot_array [0:`DATA_N-1];    //もともとsignedをつけていた
  reg [`N_LEN-1:0] add1_array [0:2];              //もともとsignedをつけていた

  reg [`N_LEN-1:0] midrslt1_array [0:3];          //もともとsignedをつけていた
  reg [`N_LEN-1:0] midrslt2_array [0:1];          //もともとsignedをつけていた
  reg [`N_LEN-1:0] midrslt3_array;                //もともとsignedをつけていた

  reg [`N_LEN-1:0] outrslt_array [0:`HID_DIM-1];  //もともとsignedをつけていた

  reg [1:0] cnt_1;
  reg [7:0] cnt_2, cnt_3, cnt_saved;

  integer n;
  genvar xx,yy,zz;

  // 102の理由は下に書いた
  assign valid = run & (cnt_2 == 102);



  //ここマイナス1し忘れてて最初動かなかった
  //1行で入ってきたデータを配列に直している。
  generate
    for(yy = 0; yy < `DATA_N; yy = yy + 1) begin :set_in_array
      assign indata_array[yy] = data_in[yy*`N_LEN +: `N_LEN];
      assign inweight_array[yy] = weight_in[yy*`N_LEN +: `N_LEN];
    end
  endgenerate



  //===固定小数点用掛け算回路===
  function [`N_LEN-1:0] product;
    input signed [`N_LEN-1:0] in_func_1, in_func_2;
    
    reg [2*`N_LEN-1:0] func1_midrslt;
    
    begin
      func1_midrslt = in_func_1 * in_func_2;
      product = func1_midrslt[`F_LEN +: `N_LEN]; 
    end
  endfunction

  //①の部分(掛け算)
  generate
    for(xx = 0; xx < `DATA_N; xx = xx + 1) begin :dot_1
      always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
          outdot_array[xx] <= 0;
        end 
        
        else if(run) begin
          outdot_array[xx] <= product(indata_array[xx], inweight_array[xx]) ;
        end
        
        else begin
          outdot_array[xx] <= 0;
        end
      end
    end
  endgenerate



  //②の部分
  generate
    for(yy = 0; yy < 3; yy = yy + 1) begin :add_1
      always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
          add1_array[yy] <= 0;
        end 
        
        else if(run) begin
          add1_array[yy] <= outdot_array[2*yy] + outdot_array[2*yy+1];
        end
        
        else begin
          add1_array[yy] <= 0;
        end
      end
    end
  endgenerate


  //③~⑤の部分(垂れ流し)
  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      cnt_1 <= 0;
      for (n = 0; n < 4; n = n + 1) begin
        midrslt1_array[n] <= 0;
      end
      for (n = 0; n < 2; n = n + 1) begin
        midrslt2_array[n] <= 0;
      end
      midrslt3_array <= 0;
    end 
    
    else if(run) begin
      cnt_1 <= cnt_1 + 1;
      // if (cnt_1 == 3) begin
      //   cnt_1 <= 0;
      // end else begin
      //   cnt_1 <= cnt_1 + 1;
      // end

      midrslt1_array[cnt_1] <= add1_array[0] + add1_array[1] + add1_array[2];

      midrslt2_array[0] <= midrslt1_array[0] + midrslt1_array[1];
      midrslt2_array[1] <= midrslt1_array[2] + midrslt1_array[3];

      midrslt3_array <= midrslt2_array[0] + midrslt2_array[1];
    end
    
    else begin
      cnt_1 <= 0;
      for(n = 0; n < 4; n = n + 1) begin
        midrslt1_array[n] <= 0;
      end
      for(n = 0; n < 2; n = n + 1) begin
        midrslt2_array[n] <= 0;
      end
      midrslt3_array <= 0;
    end
  end


  /*
  適切なタイミング2n+8回目で値を抜き出し、24個のデータからなる配列outrslt_arrayにデータを順番に格納している。
  cnt2は回路の動作から最後までカウントするカウンター
  cnt3はアライメントしたデータの個数をカウントするやつ
  cnt_savedは条件式4n+8を実現するためのやつ。cnt_saved + 4で4nを再現し、cnt_2 == cnt_saved+で+8を作っている。
  cnt2が条件式(4n+8)に合致したとき、アウトプットの配列に入れている。
  条件式に掛け算は使わない
  */
  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      cnt_2 <= 0;
      cnt_3 <= 0;
      cnt_saved <= 0;
      // valid <= 0;
      for(n = 0; n < `HID_DIM; n = n + 1) begin
        outrslt_array[n] <= 0;
      end
    end

    
    else if(run) begin
      //クロックの調整に伴い101から102へと変えた
      // 初回のデータ読み出し:1 clk, 初回6×6内積:4+1 clk, 計:6 clk
      // 6×6内積の計算を4回加算して24×24内積　-> 4 clk
      // 24×24内積を24回行う
      // パイプラインにより，合計:6+4*24=102 clk
      if (cnt_2 == 102) begin
        cnt_2 <= cnt_2;
        // cnt_3 <= 0;
        // cnt_saved <= 0;
        // valid <= 1;
      end else begin
        cnt_2 <= cnt_2 + 1;
        // valid <= 0;//11/22追加
      end

      //もともと+9で考えていたが間違っていた。
      //ここの8を変えれば他の回路の余分クロックも考慮することができる
      // 初回データ読み出し+初回6×6内積+6×6内積(パイプライン)3回加算:1+(4+1)+3=9 clk
      if (cnt_2 == cnt_saved + 9)begin
        cnt_3 <= cnt_3 + 1;
        cnt_saved <= cnt_saved + 4;
        outrslt_array[cnt_3] <= midrslt3_array + bias_in;//biasはsignedにすべき？
      end
    end

    
    else begin
      cnt_2 <= 0;
      cnt_3 <= 0;
      cnt_saved <= 0;
      // valid <= 0;
    end
  end

  //エラー箇所がgenerateだからといってそこが間違えているとは限らない。上のendが抜けてたりする。
  //配列を1行に直している
  generate
    for(zz = 0; zz < `HID_DIM; zz = zz + 1) begin :set_out_array
      assign data_out[`N_LEN*zz +: `N_LEN] = outrslt_array[zz];
    end
  endgenerate

endmodule