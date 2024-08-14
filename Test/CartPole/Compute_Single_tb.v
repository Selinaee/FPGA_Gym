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

    localparam STA_WL = 128, ACT_WL = 1, RWD_WL = 1;

    //Ports
    reg               clk;
    reg               i_ena;
    wire [STA_WL-1:0] i_sta;
    reg  [ACT_WL-1:0] i_act;
    wire [STA_WL-1:0] o_sta;
    wire [RWD_WL-1:0] o_rwd;
    wire              o_done;
    wire              o_valid;

    reg [31:0] i_x, i_x_dot, i_theta, i_theta_dot;

    always #5  clk = ! clk ;
    initial begin
        clk = 0;
        i_ena = 1'b0;
        #5
        i_ena = 1'b1;
        i_act = `ONE(ACT_WL);

        i_x         = 32'hBDDA4B6F; 
        i_x_dot     = 32'hBE7002B9; 
        i_theta     = 32'h3E53E72E; 
        i_theta_dot = 32'h3F5F1AFC; 
    end
    assign i_sta = {i_x, i_x_dot, i_theta, i_theta_dot};

    Compute_Single #(.STA_WL(STA_WL), .ACT_WL(ACT_WL), .RWD_WL(RWD_WL)) u_Compute_Single(
        .i_clk   ( clk ),
        .i_ena   ( i_ena ),
        .i_sta   ( i_sta[STA_WL-1:0] ),
        .i_act   ( i_act[ACT_WL-1:0] ),
        .o_sta   ( o_sta[STA_WL-1:0] ),
        .o_rwd   ( o_rwd[RWD_WL-1:0] ),
        .o_done  ( o_done ),
        .o_valid ( o_valid )
    );
  
endmodule