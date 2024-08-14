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

module Sin_Cos_tb();

    reg clk, ena;

    reg  [31:0] i_th;
    wire [31:0] o_sin;
    wire [31:0] o_cos;
    wire        o_valid;

    always #5 clk = ~clk;
    initial begin
        clk = 1'b0; ena = 1'b0;
        #100  ena = 1'b1;
        #3500 ena = 1'b0;
    end
    initial begin
        i_th = 32'h00000000; // 0
        
        #1000; // GT: 0.5, 0.8660254038
        i_th = 32'h3f060a92; // pi/6

        #1000; // GT: 0.707, 0.707
        i_th = 32'h3f490fdb; // pi/4
        
        #1000; // GT: 0.8660254038, 0.5
        i_th = 32'h3f860a92; // pi/3

        #1000; // GT: 1, 0
        i_th = 32'h3fc90fdb; // pi/2
        #1000 $finish;
    end

    Sin_Cos u_Sin_Cos(
        .i_clk   ( clk ),
        .i_ena   ( ena ),
        .i_th    ( i_th[31:0] ),
        .o_sin   ( o_sin[31:0] ),
        .o_cos   ( o_cos[31:0] ),
        .o_valid ( o_valid )
    );

endmodule
