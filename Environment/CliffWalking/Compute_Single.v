`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/26/2024 10:45:29 AM
// Design Name: 
// Module Name: Cartpole_Step_Compute
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
module Compute_Single #(parameter STA_WL = 32, ACT_WL = 2, OBS_WL = 32, RWD_WL = 1) (
    input wire i_clk,
    input wire i_ena,

    input  wire [STA_WL-1:0] i_sta,
    input  wire [ACT_WL-1:0] i_act,

    output reg  [STA_WL-1:0] o_sta,

    output wire [OBS_WL-1:0] o_obs, // observations
    output reg  [RWD_WL-1:0] o_rwd,
    output reg               o_done,

    output wire              o_valid
    );

    reg [STA_WL-1:0] o_sta_mid;

    always @(*) begin
        case (i_act) // calculate o_sta_mid
            2'd0: o_sta_mid = (i_sta >= 32'd0  & i_sta <= 32'd11) ? i_sta : i_sta - 32'd12;
            2'd1: o_sta_mid = (i_sta == 32'd11 | i_sta == 32'd23  |
                               i_sta == 32'd35 | i_sta == 32'd47) ? i_sta : i_sta + 32'd1;
            2'd2: o_sta_mid = (i_sta >= 32'd36 & i_sta <= 32'd47) ? i_sta : i_sta + 32'd12;
            2'd3: o_sta_mid = (i_sta == 32'd0  | i_sta == 32'd12  |
                               i_sta == 32'd24 | i_sta == 32'd36) ? i_sta : i_sta - 32'd1;
            default: o_sta_mid = `ZERO(STA_WL);
        endcase

        // calculate o_sta, o_done, o_rwd
        if (o_sta_mid > 32'd36 & o_sta_mid < 32'd47) begin
            o_sta  = 32'd36;
            o_rwd  = 1'd1;
            o_done = 1'b0;
        end else if (o_sta_mid == 32'd47) begin
            o_sta  = o_sta_mid;
            o_rwd  = 1'd0;
            o_done = 1'b1;
        end else begin
            o_sta  = o_sta_mid;
            o_rwd  = 1'd0;
            o_done = 1'b0;
        end
    end
    
    assign o_obs = o_sta;
    assign o_valid = 1'b1;

endmodule
