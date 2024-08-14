`timescale 1ns / 1ps

module decode(
    input [8:0] encoded_state, // 
    output reg [1:0] dest_idx, // 
    output reg [2:0] pass_idx, // 
    output reg [2:0] taxi_col, // 
    output reg [2:0] taxi_row  // 
);

integer intermediate;

always @ (*) begin
    // Decode the destination index
    dest_idx = encoded_state % 4;  // 

    // Compute intermediate for the next calculation
    intermediate = encoded_state / 4;

    // Decode the passenger index
    pass_idx = intermediate % 5;  // 

    // Compute intermediate for the next calculation
    intermediate = intermediate / 5;

    // Decode the taxi column
    taxi_col = intermediate % 5;  // 

    // Compute intermediate for the final calculation
    intermediate = intermediate / 5;

    // Decode the taxi row
    taxi_row = intermediate;  // 
end

endmodule
