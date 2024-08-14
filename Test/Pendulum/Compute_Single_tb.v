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

module Compute_Single_tb();

    reg clk, ena;

    wire [63:0] i_sta;
    reg  [31:0] i_th;
    reg  [31:0] i_thdot;
    reg  [31:0] i_act;
    wire [63:0] o_sta;
    wire [95:0] o_obs;
    wire [31:0] o_th;
    wire [31:0] o_sinth;
    wire [31:0] o_costh;
    wire [31:0] o_thdot;
    wire [31:0] o_rwd;
    wire        o_done;
    wire        o_valid;

    always #5 clk = ~clk;
    initial begin
        clk = 1'b0; ena = 1'b0;
        #100  ena = 1'b1;
        #5500 ena = 1'b0;
    end
    initial begin
        #0;    // [th, cos, sin, thdot, rwd, done] = [ -3.0913418989367942 -0.9987377 -0.05022961 0.83686817 -9.87108043845901 False ]
        i_th    = 32'h4049999a; // 3.15
        i_thdot = 32'h3f3b93a1; // 0.732721370381203
        i_act   = 32'h3f3c8151; // 0.7363482

        #1500; // [th, cos, sin, thdot, rwd, done] = [ 3.1260542948355745 -0.9998793 0.015537733 -0.14262025 -9.818889352261612 False ]
        i_th    = 32'hc049999a; // -3.15
        i_thdot = 32'hbe122a8c; // -0.14274042190560132
        i_act   = 32'hbd28e61b; // -0.04123507

        #1500; // [th, cos, sin, thdot, rwd, done] = [-2.005907474966395 -0.4215112 -0.9068232 -0.9672726 -3.867806203865478 False]
        i_th    = 32'hbffa90cc; // -1.9575438464964259
        i_thdot = 32'hbf10d68d; // -0.5657738087417351
        i_act   = 32'h3ffa1e27; // 1.9540452

        #1500; // [th, cos, sin, thdot, rwd, done] = [-2.08777562772482 -0.49425647 -0.86931616 -1.6373631 -4.117230890271055 False]
        i_th    = 32'hc00060ca; // -2.0059074751425996
        i_thdot = 32'hbf779f2d; // -0.9672725729234766
        i_act   = 32'h3d88e6a0; // 0.06684613
        #1500 $finish;
    end

    assign i_sta = {i_thdot, i_th};
    assign o_th = o_sta[31:0];
    assign {o_thdot, o_sinth, o_costh} = o_obs;

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
    // Compute_Single u_Compute_Single(
    //     .i_clk   ( clk ),
    //     .i_ena   ( ena ),
    //     .i_th    ( i_th[31:0] ),
    //     .i_thdot ( i_thdot[31:0] ),
    //     .i_act   ( i_act[31:0] ),
    //     .o_costh ( o_costh[31:0] ),
    //     .o_sinth ( o_sinth[31:0] ),
    //     .o_thdot ( o_thdot[31:0] ),
    //     .o_rwd   ( o_rwd[31:0] ),
    //     .o_done  ( o_done ),
    //     .o_valid ( o_valid )
    // );

endmodule
