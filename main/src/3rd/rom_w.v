`include "num_data.v"

module rom_w #(
    parameter filenum = 0
    )(
    input wire clk, 
    input wire rst_n, 
    input wire run, 
    input wire [`STATE_LEN-1:0] state, 
    output wire [`BIT_LENGTH*`DATA_N-1:0] output_weight
);


reg [15:0] sub_addr;
wire [15:0] addr;
wire [15:0] addr_bias;


rom_w_core #(
    .filenum(filenum)
    ) rom_w_core(
        .clk(clk), 
        .rst_n(rst_n), 
        .addr(addr), 
        .output_weight(output_weight)
);


function [15:0] decide_addr_bias;
    input [`STATE_LEN-1:0] addr_bias_select;
    
    case (addr_bias_select)
        4'b0011: decide_addr_bias = 0;
        4'b0100: decide_addr_bias = 96;
        4'b0101: decide_addr_bias = 192;
        default : decide_addr_bias = 4'bXXXX;
    endcase
endfunction


assign addr_bias = decide_addr_bias(state);
assign addr = sub_addr + addr_bias;


always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        sub_addr <= 0;
    end
    
    
    else if(run) begin
        if (sub_addr == 95) begin
            sub_addr <= 0;
        end else begin
            sub_addr <= sub_addr + 1;
        end
    end
    
    
    else begin
        sub_addr <= 0;
    end
end


endmodule