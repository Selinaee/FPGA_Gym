`timescale 1ns / 1ps
`include "taxi_step.v"
module TaxiStep_tb;

// Parameters

//Ports
reg  clk;
reg  reset;
reg [2:0] action;
reg [2:0] taxi_row_in;
reg [2:0] taxi_col_in;
reg [2:0] pass_idx_in;
reg [1:0] dest_idx_in;
wire [2:0] taxi_row_out;
wire [2:0] taxi_col_out;
wire [2:0] pass_idx_out;
wire [1:0] dest_idx_out;
wire [1:0] reward;
wire  terminated;

TaxiStep  TaxiStep_inst (
    .clk(clk),
    .reset(reset),
    .action(action),
    .taxi_row_in(taxi_row_in),
    .taxi_col_in(taxi_col_in),
    .pass_idx_in(pass_idx_in),
    .dest_idx_in(dest_idx_in),
    .taxi_row_out(taxi_row_out),
    .taxi_col_out(taxi_col_out),
    .pass_idx_out(pass_idx_out),
    .dest_idx_out(dest_idx_out),
    .reward(reward),
    .terminated(terminated)
  );


always #5  clk = ! clk ;
initial begin
    clk = 0;
    reset = 1;
    action = 0;
    #10
    reset = 0;
    action = 1;
    taxi_row_in = 'd2;
    taxi_col_in = 'd0;
    pass_idx_in = 'd2;
    dest_idx_in = 'd3;
    #10
    $display("taxi_row_out = %d, taxi_col_out = %d, pass_idx_out = %d, dest_idx_out = %d, reward = %d, terminated = %d", taxi_row_out, taxi_col_out, pass_idx_out, dest_idx_out, reward, terminated);
    #1000 $finish;
end

endmodule

