`timescale 1ns / 1ps

module decode(
    input [8:0] encoded_state, // 假设状态编码为9位宽
    output reg [1:0] dest_idx, // 目的地索引：0到3
    output reg [2:0] pass_idx, // 乘客位置索引：0到4
    output reg [2:0] taxi_col, // 出租车列位置：0到4
    output reg [2:0] taxi_row  // 出租车行位置：0到4
);

integer intermediate;

always @ (*) begin
    // Decode the destination index
    dest_idx = encoded_state % 4;  // 取最低2位，目的地索引

    // Compute intermediate for the next calculation
    intermediate = encoded_state / 4;

    // Decode the passenger index
    pass_idx = intermediate % 5;  // 接下来3位，乘客位置索引

    // Compute intermediate for the next calculation
    intermediate = intermediate / 5;

    // Decode the taxi column
    taxi_col = intermediate % 5;  // 再接下来3位，出租车列位置

    // Compute intermediate for the final calculation
    intermediate = intermediate / 5;

    // Decode the taxi row
    taxi_row = intermediate;  // 最高位，出租车行位置
end

endmodule
