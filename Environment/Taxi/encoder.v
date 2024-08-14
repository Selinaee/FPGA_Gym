module Encode(
    input [2:0] taxi_row,    
    input [2:0] taxi_col,
    input [2:0] pass_loc,    
    input [1:0] dest_idx,    
    output reg [8:0] encoded_state  
);

always @(*) begin
    encoded_state = ((taxi_row * 5 + taxi_col) * 5 + pass_loc)*4 +dest_idx;
end

endmodule
