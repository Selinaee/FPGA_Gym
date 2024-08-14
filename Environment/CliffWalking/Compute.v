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

module Compute #(parameter PE_NUM = 1, STA_WL = 32, ACT_WL = 2, OBS_WL = 32, RWD_WL = 1) (
    input wire i_clk,
    input wire i_rstn,
    input wire i_ena,

    input  wire [PE_NUM*STA_WL-1:0] i_sta,
    input  wire [PE_NUM*ACT_WL-1:0] i_act,

    output wire [PE_NUM*STA_WL-1:0] o_sta,

    output wire [PE_NUM*OBS_WL-1:0] o_obs,
    output wire [PE_NUM*RWD_WL-1:0] o_rwd,
    output wire [PE_NUM-1:0]        o_done,

    output wire                     o_valid
    );

    // Compute_Single (Processing Element, PE) ports
    wire [PE_NUM-1:0]        pe_i_ena;
    wire [PE_NUM*STA_WL-1:0] pe_i_sta;
    wire [PE_NUM*ACT_WL-1:0] pe_i_act;
    wire [PE_NUM*STA_WL-1:0] pe_o_sta;
    wire [PE_NUM*OBS_WL-1:0] pe_o_obs;
    wire [PE_NUM*RWD_WL-1:0] pe_o_rwd;
    wire [PE_NUM-1:0]        pe_o_done;
    wire [PE_NUM-1:0]        pe_o_valid;

    // connect ports
        // Cartpole_Step_Compute outputs
            assign o_sta   = pe_o_sta;
            assign o_obs   = pe_o_obs;
            assign o_rwd   = pe_o_rwd;
            assign o_done  = pe_o_done;
            assign o_valid = &pe_o_valid;
        // PE inputs
            assign pe_i_ena = {PE_NUM{i_ena}};
            assign pe_i_sta = i_sta;
            assign pe_i_act = i_act;

    Compute_Single #(.STA_WL(STA_WL), .ACT_WL(ACT_WL), .OBS_WL(OBS_WL), .RWD_WL(RWD_WL)) u_Compute_Single[PE_NUM-1:0](
        .i_clk   ( i_clk ),
        .i_ena   ( pe_i_ena[PE_NUM-1:0] ),
        .i_sta   ( pe_i_sta[PE_NUM*STA_WL-1:0] ),
        .i_act   ( pe_i_act[PE_NUM*ACT_WL-1:0] ),
        .o_sta   ( pe_o_sta[PE_NUM*STA_WL-1:0] ),
        .o_obs   ( pe_o_obs[PE_NUM*OBS_WL-1:0] ),
        .o_rwd   ( pe_o_rwd[PE_NUM*RWD_WL-1:0] ),
        .o_done  ( pe_o_done[PE_NUM-1:0] ),
        .o_valid ( pe_o_valid[PE_NUM-1:0] )
    );

endmodule
