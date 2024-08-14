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

module Rwd_tb();

    reg clk, ena;

    reg  [31:0] i_th;
    reg  [31:0] i_thdot;
    reg  [31:0] i_tor;
    wire        o_rwd_valid;
    wire [31:0] o_rwd;

    always #5 clk = ~clk;
    initial begin
        clk = 1'b0; ena = 1'b0;
        #100  ena = 1'b1;
        #2500 ena = 1'b0;
    end
    initial begin
        // 1^2 + 0.1 * 1^2 + 0.001 * 2^2 = 1.104
        i_th    = 32'h3f800000; // 1
        i_thdot = 32'h3f800000; // 1
        i_tor   = 32'h40000000; // 2

        #1000; // 2^2 + 0.1 * 2^2 + 0.001 * 2^2 = 4.404
        i_th    = 32'h40000000; // 2
        i_thdot = 32'h40000000; // 2
        i_tor   = 32'h40000000; // 2

        #1000; // 2^2 + 0.1 * 2^2 + 0.001 * 1^2 = 4.401
        i_th    = 32'h40000000; // 2
        i_thdot = 32'h40000000; // 2
        i_tor   = 32'h3f800000; // 1
        #1000 $finish;
    end

    Pendulum_Compute_Rwd u_Pendulum_Compute_Rwd(
        .i_clk       ( clk ),
        .i_ena       ( ena ),
        .i_th        ( i_th[31:0] ),
        .i_thdot     ( i_thdot[31:0] ),
        .i_tor       ( i_tor[31:0] ),
        .o_rwd_valid ( o_rwd_valid ),
        .o_rwd       ( o_rwd[31:0] )
    );

endmodule
