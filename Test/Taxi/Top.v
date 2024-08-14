`timescale 1ns / 1ps
`include "encoder.v"
`include "taxi_step.v"
`include "decoder.v"

module Top(
    input clk,
    input reset,
    input [2:0] action,
    input [8:0] agent_state,
    output [8:0] next_agnet_state,
    output [1:0] reward,
    output terminated
);
    wire [1:0] dest_idx;
    wire [2:0] pass_idx;
    wire [2:0] taxi_col;
    wire [2:0] taxi_row;
    wire [1:0] dest_idx_out;
    wire [2:0] pass_idx_out;
    wire [2:0] taxi_col_out;
    wire [2:0] taxi_row_out;
    //decode
        decode  decode_inst (
            .encoded_state(agent_state),
            .dest_idx(dest_idx),
            .pass_idx(pass_idx),
            .taxi_col(taxi_col),
            .taxi_row(taxi_row)
        );
    //pure logic compute
        TaxiStep  TaxiStep_inst (
            .clk(clk),
            .reset(reset),
            .action(action),
            .taxi_row_in(taxi_row),
            .taxi_col_in(taxi_col),
            .pass_idx_in(pass_idx),
            .dest_idx_in(dest_idx),
            .taxi_row_out(taxi_row_out),
            .taxi_col_out(taxi_col_out),
            .pass_idx_out(pass_idx_out),
            .dest_idx_out(dest_idx_out),
            .reward(reward),
            .terminated(terminated)
          );
    //encode
          Encode  Encode_inst (
            .taxi_row(taxi_row_out),
            .taxi_col(taxi_col_out),
            .pass_loc(pass_idx_out),
            .dest_idx(dest_idx_out),
            .encoded_state(next_agnet_state)
        );

endmodule