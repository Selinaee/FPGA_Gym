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

module Compute_Single #(parameter STA_WL = 64, ACT_WL = 32, OBS_WL = 96, RWD_WL = 32) (
    input wire i_clk,
    input wire i_ena,

    input  wire [STA_WL-1:0] i_sta,
    input  wire [ACT_WL-1:0] i_act,

    output wire [STA_WL-1:0] o_sta,

    output wire [OBS_WL-1:0] o_obs,
    output wire [RWD_WL-1:0] o_rwd,
    output wire              o_done,

    output wire              o_valid
    );

    localparam DT         = 32'h3d4ccccd; // 0.05
    localparam MAX_TORQUE = 32'h40000000; //  2
    localparam MIN_TORQUE = 32'hc0000000; // -2

    localparam TH_WL = 32, TH_DOT_WL = 32, SINTH_WL = 32, COSTH_WL = 32;

    // split i_sta
        wire [TH_WL-1:0]     i_th;
        wire [TH_DOT_WL-1:0] i_thdot;
        assign {i_thdot, i_th} = i_sta;

    // split o_sta, o_obs
        wire [TH_WL-1:0]     o_th;
        wire [COSTH_WL-1:0]  o_costh;
        wire [SINTH_WL-1:0]  o_sinth;
        wire [TH_DOT_WL-1:0] o_thdot;
        assign o_sta = {o_thdot, o_th};
        assign o_obs = {o_thdot, o_sinth, o_costh};

    // intermidiate signals
        wire                 norm_i_th_valid;
        wire [TH_WL-1:0]     norm_i_th;
        wire                 tor_valid;
        wire [ACT_WL-1:0]    tor;
        wire                 rwd_valid;
        wire [RWD_WL-1:0]    rwd;
        wire                 thdot_valid;
        wire [TH_DOT_WL-1:0] thdot;
        wire                 th_valid;
        wire [TH_WL-1:0]     th;
        wire                 sth_valid;
        wire [SINTH_WL-1:0]  sth;
        wire                 cth_valid;
        wire [COSTH_WL-1:0]  cth;

    // u_Tor ports
        wire [ACT_WL-1:0] tor_i_data;
        wire [ACT_WL-1:0] tor_i_max;
        wire [ACT_WL-1:0] tor_i_min;
        wire              tor_o_result_valid;
        wire [ACT_WL-1:0] tor_o_result;
    // u_Rwd ports
        wire                 rwd_i_ena;
        wire [TH_WL-1:0]     rwd_i_th;
        wire [TH_DOT_WL-1:0] rwd_i_thdot;
        wire [ACT_WL-1:0]    rwd_i_tor;
        wire                 rwd_o_rwd_valid;
        wire [RWD_WL-1:0]    rwd_o_rwd;
    // u_Thdot ports
        wire                 thdot_i_ena;
        wire [TH_WL-1:0]     thdot_i_th;
        wire [TH_DOT_WL-1:0] thdot_i_thdot;
        wire [ACT_WL-1:0]    thdot_i_tor;
        wire                 thdot_o_thdot_valid;
        wire [TH_DOT_WL-1:0] thdot_o_thdot;
    // u_Th ports
        wire [TH_WL-1:0] th_i_a_data;
        wire             th_i_a_valid;
        wire [TH_WL-1:0] th_i_b_data;
        wire             th_i_b_valid;
        wire [TH_WL-1:0] th_i_c_data;
        wire             th_i_c_valid;
        wire [TH_WL-1:0] th_o_result_data;
        wire             th_o_result_valid;
    // u_Normalize_Angle ports
        wire             na_i_ena;
        wire [TH_WL-1:0] na_i_th;
        wire [TH_WL-1:0] na_o_th;
        wire             na_o_valid;
    // u_Sin_Cos ports
        wire                sc_i_ena;
        wire [TH_WL-1:0]    sc_i_th;
        wire [SINTH_WL-1:0] sc_o_sin;
        wire [COSTH_WL-1:0] sc_o_cos;
        wire                sc_o_valid;

    // set intermidiate signals
        assign norm_i_th_valid = na_o_valid;
        assign norm_i_th       = na_o_th;
        assign tor_valid       = tor_o_result_valid;
        assign tor             = tor_o_result;
        assign rwd_valid       = rwd_o_rwd_valid;
        assign rwd             = rwd_o_rwd;
        assign thdot_valid     = thdot_o_thdot_valid;
        assign thdot           = thdot_o_thdot;
        assign th_valid        = th_o_result_valid;
        assign th              = th_o_result_data;
        assign sth_valid       = sc_o_valid;
        assign sth             = sc_o_sin;
        assign cth_valid       = sc_o_valid;
        assign cth             = sc_o_cos;

    // connect ports
        // Compute_Single outputs
            assign o_th     = th;
            assign o_costh  = cth;
            assign o_sinth  = sth;
            assign o_thdot  = thdot;
            assign o_rwd    = rwd;
            assign o_done   = 1'b0;
            assign o_valid  = i_ena & sth_valid & cth_valid & thdot_valid & rwd_valid;
        // u_Normalize_Angle inputs
            assign na_i_ena = i_ena;
            assign na_i_th  = i_th;
        // u_Tor inputs
            assign tor_i_data = i_act;
            assign tor_i_max  = MAX_TORQUE;
            assign tor_i_min  = MIN_TORQUE;
        // u_Rwd inputs
            assign rwd_i_ena   = norm_i_th_valid & tor_valid;
            assign rwd_i_th    = norm_i_th;
            assign rwd_i_thdot = i_thdot;
            assign rwd_i_tor   = tor;
        // u_Thtdot inputs
            assign thdot_i_ena   = norm_i_th_valid & tor_valid;
            assign thdot_i_th    = norm_i_th;
            assign thdot_i_thdot = i_thdot;
            assign thdot_i_tor   = tor;
        // u_Th inputs (thdot * DT + th)
            assign th_i_a_data  = thdot;
            assign th_i_a_valid = thdot_valid;
            assign th_i_b_data  = DT;
            assign th_i_b_valid = i_ena;
            assign th_i_c_data  = norm_i_th;
            assign th_i_c_valid = norm_i_th_valid;
        // u_Sin_Cos inputs
            assign sc_i_ena = th_valid;
            assign sc_i_th  = th;

    Normalize_Angle u_Normalize_Angle(
        .i_clk   ( i_clk ),
        .i_ena   ( na_i_ena ),
        .i_th    ( na_i_th[TH_WL-1:0] ),
        .o_th    ( na_o_th[TH_WL-1:0] ),
        .o_valid ( na_o_valid )
    );
    Clip32 u_Tor(
        .i_clk          ( i_clk ),
        .i_ena          ( i_ena ),
        .i_data         ( tor_i_data[ACT_WL-1:0] ),
        .i_max          ( tor_i_max[ACT_WL-1:0] ),
        .i_min          ( tor_i_min[ACT_WL-1:0] ),
        .o_result_valid ( tor_o_result_valid ),
        .o_result       ( tor_o_result[ACT_WL-1:0] )
    );
    Compute_Rwd #(.TH_WL(TH_WL), .TH_DOT_WL(TH_DOT_WL), .RWD_WL(RWD_WL), .TOR_WL(ACT_WL)) u_Compute_Rwd(
        .i_clk       ( i_clk ),
        .i_ena       ( rwd_i_ena ),
        .i_th        ( rwd_i_th[TH_WL-1:0] ),
        .i_thdot     ( rwd_i_thdot[TH_DOT_WL-1:0] ),
        .i_tor       ( rwd_i_tor[ACT_WL-1:0] ),
        .o_rwd_valid ( rwd_o_rwd_valid ),
        .o_rwd       ( rwd_o_rwd[RWD_WL-1:0] )
    );
    Compute_Thdot #(.TH_WL(TH_WL), .TH_DOT_WL(TH_DOT_WL), .TOR_WL(ACT_WL),
                             .SINTH_WL(SINTH_WL), .COSTH_WL(COSTH_WL)) u_Compute_Thdot(
        .i_clk         ( i_clk ),
        .i_ena         ( thdot_i_ena ),
        .i_th          ( thdot_i_th[TH_WL-1:0] ),
        .i_thdot       ( thdot_i_thdot[TH_DOT_WL-1:0] ),
        .i_tor         ( thdot_i_tor[ACT_WL-1:0] ),
        .o_thdot_valid ( thdot_o_thdot_valid ),
        .o_thdot       ( thdot_o_thdot[TH_DOT_WL-1:0] )
    );
    MAC u_Th ( // thdot * DT + th
        .aclk                 ( i_clk ),                      // input wire aclk
        .s_axis_a_tvalid      ( th_i_a_valid ),               // input wire s_axis_a_tvalid
        .s_axis_a_tdata       ( th_i_a_data[TH_WL-1:0] ),     // input wire [31 : 0] s_axis_a_tdata
        .s_axis_b_tvalid      ( th_i_b_valid ),               // input wire s_axis_b_tvalid
        .s_axis_b_tdata       ( th_i_b_data[TH_WL-1:0] ),     // input wire [31 : 0] s_axis_b_tdata
        .s_axis_c_tvalid      ( th_i_c_valid ),               // input wire s_axis_c_tvalid
        .s_axis_c_tdata       ( th_i_c_data[TH_WL-1:0] ),     // input wire [31 : 0] s_axis_c_tdata
        .m_axis_result_tvalid ( th_o_result_valid ),          // output wire m_axis_result_tvalid
        .m_axis_result_tdata  ( th_o_result_data[TH_WL-1:0] ) // output wire [31 : 0] m_axis_result_tdata
    );
    Sin_Cos u_Sin_Cos(
        .i_clk   ( i_clk ),
        .i_ena   ( sc_i_ena ),
        .i_th    ( sc_i_th[TH_WL-1:0] ),
        .o_sin   ( sc_o_sin[SINTH_WL-1:0] ),
        .o_cos   ( sc_o_cos[COSTH_WL-1:0] ),
        .o_valid ( sc_o_valid )
    );

endmodule
