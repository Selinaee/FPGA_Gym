`timescale 1ns / 1ps

`ifndef ONE // 1
`define ONE(WL) {{(WL-1){1'b0}}, 1'b1}
`endif

`ifndef ZERO // 0
`define ZERO(WL) {(WL){1'b0}}
`endif

`ifndef ALL1 // 111111
`define ALL1(WL) {(WL){1'b1}}
`endif

module Thdot_tb();

    reg clk, ena;

    reg  [31:0] i_th;
    reg  [31:0] i_thdot;
    reg  [31:0] i_tor;
    wire        o_thdot_valid;
    wire [31:0] o_thdot;

    always #5 clk = ~clk;
    initial begin
        clk = 1'b0; ena = 1'b0;
        #100  ena = 1'b1;
        #3500 ena = 1'b0;
    end
    initial begin
        // GT: 0.8025073182802188
        i_th    = 32'h3e9136b8; // 0.2836206029275261
        i_thdot = 32'h3eda3dff; // 0.4262542485643579
        i_tor   = 32'h3f8df9d4; // 1.1091866

        #1000; // GT: 1.3126625116382546
        i_th    = 32'h3ea5c208; // 0.32374596884153706
        i_thdot = 32'h3f4d711f; // 0.8025073182802188
        i_tor   = 32'h3fe7bc4c; // 1.8104339

        #1000; // GT: 1.5508646078331054
        i_th    = 32'h3ec75cb2; // 0.3893790944234498
        i_thdot = 32'h3fa80553; // 1.3126625116382546
        i_tor   = 32'hbe9ebfb4; // -0.31005633

        #1000; // GT: 2.0969070539428003
        i_th    = 32'h3eef1071; // 0.4669223248151051
        i_thdot = 32'h3fc682bb; // 1.5508646078331054
        i_tor   = 32'h3fb1ddd3; // 1.389582
        #1000 $finish;
    end

    Pendulum_Compute_Thdot u_Pendulum_Compute_Thdot(
        .i_clk         ( clk ),
        .i_ena         ( ena ),
        .i_th          ( i_th[31:0] ),
        .i_thdot       ( i_thdot[31:0] ),
        .i_tor         ( i_tor[31:0] ),
        .o_thdot_valid ( o_thdot_valid ),
        .o_thdot       ( o_thdot[31:0] )
    );

endmodule
