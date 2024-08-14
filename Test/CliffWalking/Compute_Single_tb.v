`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/26/2024 12:10:43 PM
// Design Name: 
// Module Name: tb_Cartpole_Step_Compute
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`ifndef ONE // 1
`define ONE(WL) {{(WL-1){1'b0}}, 1'b1}
`endif

`ifndef ZERO // 0
`define ZERO(WL) {(WL){1'b0}}
`endif

`ifndef ALL1 // 111111
`define ALL1(WL) {(WL){1'b1}}
`endif

module Compute_Single_tb();

    reg clk, ena;

    //Ports
    reg  [31:0] i_sta;
    reg  [1:0]  i_act;
    wire [31:0] o_sta;
    wire [31:0] o_obs;
    wire [1:0]  o_rwd;
    wire        o_done;
    wire        o_valid;


    reg [31:0] i_x, i_x_dot, i_theta, i_theta_dot;

    always #5  clk = ! clk ;
    initial begin
        clk = 0;
        ena = 1'b0;
        #5
        ena = 1'b1;
        #10 i_sta = 32'd40; i_act = 2'd1; // ENV  0
        #10 i_sta = 32'd20; i_act = 2'd2; // ENV  1
        #10 i_sta = 32'd47; i_act = 2'd2; // ENV  2
        #10 i_sta = 32'd1;  i_act = 2'd2; // ENV  3
        #10 i_sta = 32'd40; i_act = 2'd3; // ENV  4
        #10 i_sta = 32'd32; i_act = 2'd3; // ENV  5
        #10 i_sta = 32'd35; i_act = 2'd1; // ENV  6
        #10 i_sta = 32'd6;  i_act = 2'd2; // ENV  7
        #10 i_sta = 32'd41; i_act = 2'd2; // ENV  8
        #10 i_sta = 32'd32; i_act = 2'd2; // ENV  9
        #10 i_sta = 32'd39; i_act = 2'd3; // ENV 10
        #10 i_sta = 32'd25; i_act = 2'd3; // ENV 11
        #10 i_sta = 32'd21; i_act = 2'd3; // ENV 12
        #10 i_sta = 32'd9;  i_act = 2'd0; // ENV 13
        #10 i_sta = 32'd22; i_act = 2'd2; // ENV 14
        #10 i_sta = 32'd2;  i_act = 2'd2; // ENV 15
        #10 i_sta = 32'd19; i_act = 2'd3; // ENV 16
        #10 i_sta = 32'd26; i_act = 2'd1; // ENV 17
        #10 i_sta = 32'd16; i_act = 2'd1; // ENV 18
        #10 i_sta = 32'd7;  i_act = 2'd1; // ENV 19
        #10 i_sta = 32'd17; i_act = 2'd1; // ENV 20
        #10 i_sta = 32'd43; i_act = 2'd1; // ENV 21
        #10 i_sta = 32'd2;  i_act = 2'd2; // ENV 22
        #10 i_sta = 32'd1;  i_act = 2'd1; // ENV 23
        #10 i_sta = 32'd27; i_act = 2'd3; // ENV 24
        #10 i_sta = 32'd6;  i_act = 2'd3; // ENV 25
        #10 i_sta = 32'd35; i_act = 2'd0; // ENV 26
        #10 i_sta = 32'd21; i_act = 2'd3; // ENV 27
        #10 i_sta = 32'd11; i_act = 2'd3; // ENV 28
        #10 i_sta = 32'd21; i_act = 2'd3; // ENV 29
        #10 i_sta = 32'd14; i_act = 2'd3; // ENV 30
        #10 i_sta = 32'd7;  i_act = 2'd1; // ENV 31
        #10 $finish;
    end

    Compute_Single u_Compute_Single(
        .i_clk   ( clk ),
        .i_ena   ( ena ),
        .i_sta   ( i_sta[63:0] ),
        .i_act   ( i_act[31:0] ),
        .o_sta   ( o_sta[63:0] ),
        .o_obs   ( o_obs[95:0] ),
        .o_rwd   ( o_rwd[31:0] ),
        .o_done  ( o_done ),
        .o_valid ( o_valid )
    );
  
endmodule