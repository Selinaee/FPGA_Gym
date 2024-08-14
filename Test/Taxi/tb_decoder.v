`timescale 1ns / 1ps
`include "decoder.v"
module decode_tb;

  // Parameters

  //Ports
  reg clk;
  reg [8:0] encoded_state;
  wire [1:0] dest_idx;
  wire [2:0] pass_idx;
  wire [2:0] taxi_col;
  wire [2:0] taxi_row;

  decode  decode_inst (
    .encoded_state(encoded_state),
    .dest_idx(dest_idx),
    .pass_idx(pass_idx),
    .taxi_col(taxi_col),
    .taxi_row(taxi_row)
  );

  initial begin
    $dumpfile("tb_decoder.vcd");
    $dumpvars(0, decode_tb); // tb的模块名
  end

always #5  clk = ! clk ;
initial begin
  encoded_state = 9'b000000000;
  clk = 0;
  #10 encoded_state = 9'd211;
  #10
  $display("dest_idx = %d, pass_idx = %d, taxi_col = %d, taxi_row = %d", dest_idx, pass_idx, taxi_col, taxi_row);
  #1000 $finish;
end

endmodule