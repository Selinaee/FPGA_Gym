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

module Clip32_tb();

    reg clk, ena;

    reg  [31:0] i_data;
    reg  [31:0] i_max;
    reg  [31:0] i_min;
    wire        o_result_valid;
    wire [31:0] o_result;

    always #5 clk = ~clk;
    initial begin
        clk = 1'b0; ena = 1'b0;
        #100 ena = 1'b1;
        #200 ena = 1'b0;
    end
    initial begin
        i_data = 32'h00000000; i_max = 32'h00000000; i_min = 32'h00000000;
        #100 i_data = 32'h00000000; i_max = 32'h40000000; i_min = 32'hc0000000; // -2 < 0 < 2 -> 0
        #100 i_data = 32'hc0400000; i_max = 32'h40000000; i_min = 32'hc0000000; // -3 < -2    -> -2
        #100 i_data = 32'h40400000; i_max = 32'h40000000; i_min = 32'hc0000000; //  3 > 2     -> 2
        #100 $finish;
    end

    Clip32 u_Clip32(
    	.i_clk          ( clk ),
        .i_ena          ( ena ),
        .i_data         ( i_data[31:0] ),
        .i_max          ( i_max[31:0] ),
        .i_min          ( i_min[31:0] ),
        .o_result_valid ( o_result_valid ),
        .o_result       ( o_result[31:0] )
    );

endmodule
