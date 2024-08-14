`timescale 1ns / 1ps
`include "encoder.v"

module Encode_tb;

// Parameters

//Ports
reg [2:0] taxi_row;
reg [2:0] taxi_col;
reg [2:0] pass_loc;
reg [1:0] dest_idx;
wire [8:0] encoded_state;

Encode  Encode_inst (
  .taxi_row(taxi_row),
  .taxi_col(taxi_col),
  .pass_loc(pass_loc),
  .dest_idx(dest_idx),
  .encoded_state(encoded_state)
);


initial begin

    taxi_row = 3'd1;
    taxi_col = 3'd0;
    pass_loc = 3'd2;
    dest_idx = 2'd3;
    #10
    $display("encoded_state = %d", encoded_state);
    #100 $finish;
end
endmodule