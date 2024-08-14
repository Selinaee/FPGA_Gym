module Encode(
    input [2:0] taxi_row,    // 假设行和列使用3位二进制数表示（0到4）
    input [2:0] taxi_col,
    input [2:0] pass_loc,    // 乘客位置同样使用3位表示（0到4）
    input [1:0] dest_idx,    // 目的地使用2位表示（0到3）
    output reg [8:0] encoded_state  // 输出编码状态，需要足够的位来存储组合值
);

always @(*) begin
    encoded_state = ((taxi_row * 5 + taxi_col) * 5 + pass_loc)*4 +dest_idx;
end

endmodule
