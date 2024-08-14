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

module Compute_Thdot #(parameter TH_WL = 32, TH_DOT_WL = 32, TOR_WL = 32,
                                          SINTH_WL = 32, COSTH_WL = 32) (
    input wire i_clk,
    input wire i_ena,

    input wire [TH_WL-1:0]     i_th,
    input wire [TH_DOT_WL-1:0] i_thdot,
    input wire [TOR_WL-1:0]    i_tor,

    output wire                 o_thdot_valid,
    output wire [TH_DOT_WL-1:0] o_thdot
    );

    localparam DT = 32'h3d4ccccd; // 0.05
    localparam MAX_TH_DOT = 32'h41000000; // 8
    localparam MIN_TH_DOT = 32'hc1000000; // -8

    localparam CST0 = 32'h3a83126f; // 0.001
    localparam CST1 = 32'h3dcccccd; // 0.1
    localparam CST2 = 32'h40000000; // 2
    localparam CST3 = 32'h40400000; // 3
    localparam CST4 = 32'h41700000; // 3*g/(2*l) = 3*10/(2*1) = 15
    localparam CST5 = 32'h40400000; // 3/(m*l^2) = 3/(1*1^2) = 3

    // intermidiate signals
        wire                sth_valid;
        wire [SINTH_WL-1:0] sth;

    // u_Th_Fix ports
        wire             thfx_i_a_valid;
        wire [TH_WL-1:0] thfx_i_a_data;
        wire             thfx_o_result_valid;
        wire [TH_WL-1:0] thfx_o_result_data;
    // u_Sinth_Fix ports
        wire                  sthfx_i_phase_valid;
        wire [TH_WL-1:0]      sthfx_i_phase_data;
        wire                  sthfx_o_dout_valid;
        wire [SINTH_WL/2-1:0] sthfx_o_dout_data;
        wire [COSTH_WL/2-1:0] cthfx_o_dout_data;
    // u_Sinth ports
        wire                  sth_i_a_valid;
        wire [SINTH_WL/2-1:0] sth_i_a_data;
        wire                  sth_o_result_valid;
        wire [SINTH_WL-1:0]   sth_o_result_data;
    // u_Thdot1 ports
        wire                 thdot1_i_a_valid;
        wire [TH_DOT_WL-1:0] thdot1_i_a_data;
        wire                 thdot1_i_b_valid;
        wire [TH_DOT_WL-1:0] thdot1_i_b_data;
        wire                 thdot1_o_result_valid;
        wire [TH_DOT_WL-1:0] thdot1_o_result_data;
    // u_Thdot2 ports
        wire                 thdot2_i_a_valid;
        wire [TH_DOT_WL-1:0] thdot2_i_a_data;
        wire                 thdot2_i_b_valid;
        wire [TH_DOT_WL-1:0] thdot2_i_b_data;
        wire                 thdot2_i_c_valid;
        wire [TH_DOT_WL-1:0] thdot2_i_c_data;
        wire                 thdot2_o_result_valid;
        wire [TH_DOT_WL-1:0] thdot2_o_result_data;
    // u_Thdot ports
        wire                 thdot_i_a_valid;
        wire [TH_DOT_WL-1:0] thdot_i_a_data;
        wire                 thdot_i_b_valid;
        wire [TH_DOT_WL-1:0] thdot_i_b_data;
        wire                 thdot_i_c_valid;
        wire [TH_DOT_WL-1:0] thdot_i_c_data;
        wire                 thdot_o_result_valid;
        wire [TH_DOT_WL-1:0] thdot_o_result_data;
    // u_Thdot_Clip ports
        wire                 clip_i_ena;
        wire [TH_DOT_WL-1:0] clip_i_data;
        wire [TH_DOT_WL-1:0] clip_i_max;
        wire [TH_DOT_WL-1:0] clip_i_min;
        wire                 clip_o_result_valid;
        wire [TH_DOT_WL-1:0] clip_o_result;

    // set intermidiate signals
        assign sth_valid = sth_o_result_valid;
        assign sth       = sth_o_result_data;

    // connect ports
        // Pendulum_Compute_Thdot outputs
            assign o_thdot_valid = clip_o_result_valid;
            assign o_thdot       = clip_o_result;
        // u_Th_Fix input
            assign thfx_i_a_valid = i_ena;
            assign thfx_i_a_data  = i_th;
        // u_Sinth_Fix input
            assign sthfx_i_phase_valid = thfx_o_result_valid;
            assign sthfx_i_phase_data  = thfx_o_result_data;
        // u_Sinth input
            assign sth_i_a_valid = sthfx_o_dout_valid;
            assign sth_i_a_data  = sthfx_o_dout_data;
        // u_Thdot1 input (CST5 * tor)
            assign thdot1_i_a_valid = i_ena;
            assign thdot1_i_a_data  = CST5;
            assign thdot1_i_b_valid = i_ena;
            assign thdot1_i_b_data  = i_tor;
        // u_Thdot2 input (CST4 * sth + thdot1)
            assign thdot2_i_a_valid = i_ena;
            assign thdot2_i_a_data  = CST4;
            assign thdot2_i_b_valid = sth_valid;
            assign thdot2_i_b_data  = sth;
            assign thdot2_i_c_valid = thdot1_o_result_valid;
            assign thdot2_i_c_data  = thdot1_o_result_data;
        // u_Thdot input (thdot2 * DT + thdot)
            assign thdot_i_a_valid = thdot2_o_result_valid;
            assign thdot_i_a_data  = thdot2_o_result_data;
            assign thdot_i_b_valid = i_ena;
            assign thdot_i_b_data  = DT;
            assign thdot_i_c_valid = i_ena;
            assign thdot_i_c_data  = i_thdot;
        // u_Thdot_Clip input
            assign clip_i_ena   = thdot_o_result_valid;
            assign clip_i_data  = thdot_o_result_data;
            assign clip_i_max   = MAX_TH_DOT;
            assign clip_i_min   = MIN_TH_DOT;

    Float2Fix u_Th_Fix (
        .aclk                 ( i_clk ),                        // input wire aclk
        .s_axis_a_tvalid      ( thfx_i_a_valid ),               // input wire s_axis_a_tvalid
        .s_axis_a_tdata       ( thfx_i_a_data[TH_WL-1:0] ),     // input wire [31 : 0] s_axis_a_tdata
        .m_axis_result_tvalid ( thfx_o_result_valid ),          // output wire m_axis_result_tvalid
        .m_axis_result_tdata  ( thfx_o_result_data[TH_WL-1:0] ) // output wire [31 : 0] m_axis_result_tdata
    );
    Cordic u_Sinth_Fix (
        .aclk                ( i_clk ),                          // input wire aclk
        .s_axis_phase_tvalid ( sthfx_i_phase_valid ),            // input wire s_axis_phase_tvalid
        .s_axis_phase_tdata  ( sthfx_i_phase_data[TH_WL-1:0] ),  // input wire [31 : 0] s_axis_phase_tdata
        .m_axis_dout_tvalid  ( sthfx_o_dout_valid ),             // output wire m_axis_dout_tvalid
        .m_axis_dout_tdata   ( {sthfx_o_dout_data[SINTH_WL/2-1:0], cthfx_o_dout_data[COSTH_WL/2-1:0]} ) // output wire [31 : 0] m_axis_dout_tdata
    );
    Fix2Float u_Sinth (
        .aclk                 ( i_clk ),                          // input wire aclk
        .s_axis_a_tvalid      ( sth_i_a_valid ),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata       ( sth_i_a_data[SINTH_WL/2-1:0] ),   // input wire [15 : 0] s_axis_a_tdata
        .m_axis_result_tvalid ( sth_o_result_valid ),             // output wire m_axis_result_tvalid
        .m_axis_result_tdata  ( sth_o_result_data[SINTH_WL-1:0] ) // output wire [31 : 0] m_axis_result_tdata
    );
    Multiplier u_Thdot1 ( // CST5 * tor
        .aclk                 ( i_clk ),                          // input wire aclk
        .s_axis_a_tvalid      ( thdot1_i_a_valid ),               // input wire s_axis_a_tvalid
        .s_axis_a_tdata       ( thdot1_i_a_data[TH_DOT_WL-1:0] ),     // input wire [31 : 0] s_axis_a_tdata
        .s_axis_b_tvalid      ( thdot1_i_b_valid ),               // input wire s_axis_b_tvalid
        .s_axis_b_tdata       ( thdot1_i_b_data[TH_DOT_WL-1:0] ),     // input wire [31 : 0] s_axis_b_tdata
        .m_axis_result_tvalid ( thdot1_o_result_valid ),          // output wire m_axis_result_tvalid
        .m_axis_result_tdata  ( thdot1_o_result_data[TH_DOT_WL-1:0] ) // output wire [31 : 0] m_axis_result_tdata
    );
    MAC u_Thdot2 ( // CST4 * sth + thdot1
        .aclk                 ( i_clk ),                              // input wire aclk
        .s_axis_a_tvalid      ( thdot2_i_a_valid ),                   // input wire s_axis_a_tvalid
        .s_axis_a_tdata       ( thdot2_i_a_data[TH_DOT_WL-1:0] ),     // input wire [31 : 0] s_axis_a_tdata
        .s_axis_b_tvalid      ( thdot2_i_b_valid ),                   // input wire s_axis_b_tvalid
        .s_axis_b_tdata       ( thdot2_i_b_data[TH_DOT_WL-1:0] ),     // input wire [31 : 0] s_axis_b_tdata
        .s_axis_c_tvalid      ( thdot2_i_c_valid ),                   // input wire s_axis_c_tvalid
        .s_axis_c_tdata       ( thdot2_i_c_data[TH_DOT_WL-1:0] ),     // input wire [31 : 0] s_axis_c_tdata
        .m_axis_result_tvalid ( thdot2_o_result_valid ),              // output wire m_axis_result_tvalid
        .m_axis_result_tdata  ( thdot2_o_result_data[TH_DOT_WL-1:0] ) // output wire [31 : 0] m_axis_result_tdata
    );
    MAC u_Thdot ( // thdot2 * DT + thdot
        .aclk                 ( i_clk ),                             // input wire aclk
        .s_axis_a_tvalid      ( thdot_i_a_valid ),                   // input wire s_axis_a_tvalid
        .s_axis_a_tdata       ( thdot_i_a_data[TH_DOT_WL-1:0] ),     // input wire [31 : 0] s_axis_a_tdata
        .s_axis_b_tvalid      ( thdot_i_b_valid ),                   // input wire s_axis_b_tvalid
        .s_axis_b_tdata       ( thdot_i_b_data[TH_DOT_WL-1:0] ),     // input wire [31 : 0] s_axis_b_tdata
        .s_axis_c_tvalid      ( thdot_i_c_valid ),                   // input wire s_axis_c_tvalid
        .s_axis_c_tdata       ( thdot_i_c_data[TH_DOT_WL-1:0] ),     // input wire [31 : 0] s_axis_c_tdata
        .m_axis_result_tvalid ( thdot_o_result_valid ),              // output wire m_axis_result_tvalid
        .m_axis_result_tdata  ( thdot_o_result_data[TH_DOT_WL-1:0] ) // output wire [31 : 0] m_axis_result_tdata
    );
    Clip32 u_Thdot_Clip(
        .i_clk          ( i_clk ),
        .i_ena          ( clip_i_ena ),
        .i_data         ( clip_i_data[TH_DOT_WL-1:0] ),
        .i_max          ( clip_i_max[TH_DOT_WL-1:0] ),
        .i_min          ( clip_i_min[TH_DOT_WL-1:0] ),
        .o_result_valid ( clip_o_result_valid ),
        .o_result       ( clip_o_result[TH_DOT_WL-1:0] )
    );

endmodule
