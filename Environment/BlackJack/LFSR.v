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


module LFSR #(parameter N = 4, MIN = 1, MAX = 10) (
    input  wire         i_clk,
    input  wire         i_rstn,
    input  wire         i_ena,

    output wire [N-1:0] o_out
    );

    reg [N-1:0] out_raw;

    wire feedback;
    assign feedback = out_raw[N-1];

    always @(posedge i_clk or negedge i_rstn) begin
        if (~i_rstn) begin
            out_raw <= `ONE(N);
        end else if (i_ena) begin
            out_raw <= {out_raw[N-2:1], feedback^out_raw[0], feedback};
        end
    end

    assign o_out = (out_raw < MIN) ? MIN :
                   (out_raw > MAX) ? MAX : out_raw;

endmodule
