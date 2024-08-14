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

module Compute_Rwd #(parameter TH_WL = 32, TH_DOT_WL = 32, RWD_WL = 32, TOR_WL = 32) (
    input wire i_clk,
    input wire i_ena,

    input wire [TH_WL-1:0]     i_th,
    input wire [TH_DOT_WL-1:0] i_thdot,
    input wire [TOR_WL-1:0]    i_tor,

    output wire                 o_rwd_valid,
    output wire [RWD_WL-1:0]    o_rwd
    );

    localparam CST0 = 32'h3a83126f; // 0.001
    localparam CST1 = 32'h3dcccccd; // 0.1

    // u_Th2 ports
        wire             th2_i_a_valid;
        wire [TH_WL-1:0] th2_i_a_data;
        wire             th2_i_b_valid;
        wire [TH_WL-1:0] th2_i_b_data;
        wire             th2_o_result_valid;
        wire [TH_WL-1:0] th2_o_result_data;
    // u_Thdot2 ports
        wire                 thdot2_i_a_valid;
        wire [TH_DOT_WL-1:0] thdot2_i_a_data;
        wire                 thdot2_i_b_valid;
        wire [TH_DOT_WL-1:0] thdot2_i_b_data;
        wire                 thdot2_o_result_valid;
        wire [TH_DOT_WL-1:0] thdot2_o_result_data;
    // u_Tor2 ports
        wire              tor2_i_a_valid;
        wire [TOR_WL-1:0] tor2_i_a_data;
        wire              tor2_i_b_valid;
        wire [TOR_WL-1:0] tor2_i_b_data;
        wire              tor2_o_result_valid;
        wire [TOR_WL-1:0] tor2_o_result_data;
    // u_Rwd1 ports
        wire              rwd1_i_a_valid;
        wire [RWD_WL-1:0] rwd1_i_a_data;
        wire              rwd1_i_b_valid;
        wire [RWD_WL-1:0] rwd1_i_b_data;
        wire              rwd1_i_c_valid;
        wire [RWD_WL-1:0] rwd1_i_c_data;
        wire              rwd1_o_result_valid;
        wire [RWD_WL-1:0] rwd1_o_result_data;
    // u_Rwd ports
        wire              rwd_i_a_valid;
        wire [RWD_WL-1:0] rwd_i_a_data;
        wire              rwd_i_b_valid;
        wire [RWD_WL-1:0] rwd_i_b_data;
        wire              rwd_i_c_valid;
        wire [RWD_WL-1:0] rwd_i_c_data;
        wire              rwd_o_result_valid;
        wire [RWD_WL-1:0] rwd_o_result_data;

    // intermidiate signals
        wire                 th2_valid;
        wire [TH_WL-1:0]     th2;
        wire                 thdot2_valid;
        wire [TH_DOT_WL-1:0] thdot2;
        wire                 tor2_valid;
        wire [TOR_WL-1:0]    tor2;
        wire                 rwd1_valid;
        wire [RWD_WL-1:0]    rwd1;
        wire                 rwd_valid;
        wire [RWD_WL-1:0]    rwd;

    // set intermidiate signals
        assign th2_valid    = th2_o_result_valid;
        assign th2          = th2_o_result_data;
        assign thdot2_valid = thdot2_o_result_valid;
        assign thdot2       = thdot2_o_result_data;
        assign tor2_valid   = tor2_o_result_valid;
        assign tor2         = tor2_o_result_data;
        assign rwd1_valid   = rwd1_o_result_valid;
        assign rwd1         = rwd1_o_result_data;
        assign rwd_valid    = rwd_o_result_valid;
        assign rwd          = rwd_o_result_data;

    // connect ports
        // Pendulum_Compute_Rwd outputs
            assign o_rwd_valid = rwd_valid;
            assign o_rwd       = rwd ^ {{1'b1}, `ZERO(RWD_WL-1)};
        // u_Th2 inputs
            assign th2_i_a_valid = i_ena;
            assign th2_i_a_data  = i_th;
            assign th2_i_b_valid = i_ena;
            assign th2_i_b_data  = i_th;
        // u_Thdot2 inputs
            assign thdot2_i_a_valid = i_ena;
            assign thdot2_i_a_data  = i_thdot;
            assign thdot2_i_b_valid = i_ena;
            assign thdot2_i_b_data  = i_thdot;
        // u_Tor2 inputs
            assign tor2_i_a_valid = i_ena;
            assign tor2_i_a_data  = i_tor;
            assign tor2_i_b_valid = i_ena;
            assign tor2_i_b_data  = i_tor;
        // u_Rwd1 inputs (CST1 * thdot2 + th2)
            assign rwd1_i_a_valid = i_ena;
            assign rwd1_i_a_data  = CST1;
            assign rwd1_i_b_valid = thdot2_valid;
            assign rwd1_i_b_data  = thdot2;
            assign rwd1_i_c_valid = th2_valid;
            assign rwd1_i_c_data  = th2;
        // u_Rwd inputs (CST0 * tor2 + rwd1)
            assign rwd_i_a_valid = i_ena;
            assign rwd_i_a_data  = CST0;
            assign rwd_i_b_valid = tor2_valid;
            assign rwd_i_b_data  = tor2;
            assign rwd_i_c_valid = rwd1_valid;
            assign rwd_i_c_data  = rwd1;

    Multiplier u_Th2 ( // th * th
        .aclk                 ( i_clk ),                       // input wire aclk
        .s_axis_a_tvalid      ( th2_i_a_valid ),               // input wire s_axis_a_tvalid
        .s_axis_a_tdata       ( th2_i_a_data[TH_WL-1:0] ),     // input wire [31 : 0] s_axis_a_tdata
        .s_axis_b_tvalid      ( th2_i_b_valid ),               // input wire s_axis_b_tvalid
        .s_axis_b_tdata       ( th2_i_b_data[TH_WL-1:0] ),     // input wire [31 : 0] s_axis_b_tdata
        .m_axis_result_tvalid ( th2_o_result_valid ),          // output wire m_axis_result_tvalid
        .m_axis_result_tdata  ( th2_o_result_data[TH_WL-1:0] ) // output wire [31 : 0] m_axis_result_tdata
    );
    Multiplier u_Thdot2 ( // thdot * thdot
        .aclk                 ( i_clk ),                              // input wire aclk
        .s_axis_a_tvalid      ( thdot2_i_a_valid ),                   // input wire s_axis_a_tvalid
        .s_axis_a_tdata       ( thdot2_i_a_data[TH_DOT_WL-1:0] ),     // input wire [31 : 0] s_axis_a_tdata
        .s_axis_b_tvalid      ( thdot2_i_b_valid ),                   // input wire s_axis_b_tvalid
        .s_axis_b_tdata       ( thdot2_i_b_data[TH_DOT_WL-1:0] ),     // input wire [31 : 0] s_axis_b_tdata
        .m_axis_result_tvalid ( thdot2_o_result_valid ),              // output wire m_axis_result_tvalid
        .m_axis_result_tdata  ( thdot2_o_result_data[TH_DOT_WL-1:0] ) // output wire [31 : 0] m_axis_result_tdata
    );
    Multiplier u_Tor2 ( // tor * tor
        .aclk                 ( i_clk ),                         // input wire aclk
        .s_axis_a_tvalid      ( tor2_i_a_valid ),                // input wire s_axis_a_tvalid
        .s_axis_a_tdata       ( tor2_i_a_data[TOR_WL-1:0] ),     // input wire [31 : 0] s_axis_a_tdata
        .s_axis_b_tvalid      ( tor2_i_b_valid ),                // input wire s_axis_b_tvalid
        .s_axis_b_tdata       ( tor2_i_b_data[TOR_WL-1:0] ),     // input wire [31 : 0] s_axis_b_tdata
        .m_axis_result_tvalid ( tor2_o_result_valid ),           // output wire m_axis_result_tvalid
        .m_axis_result_tdata  ( tor2_o_result_data[TOR_WL-1:0] ) // output wire [31 : 0] m_axis_result_tdata
    );
    MAC u_Rwd1 ( // CST1 * th_dot2 + th2
        .aclk                 ( i_clk ),                         // input wire aclk
        .s_axis_a_tvalid      ( rwd1_i_a_valid ),                // input wire s_axis_a_tvalid
        .s_axis_a_tdata       ( rwd1_i_a_data[RWD_WL-1:0] ),     // input wire [31 : 0] s_axis_a_tdata
        .s_axis_b_tvalid      ( rwd1_i_b_valid ),                // input wire s_axis_b_tvalid
        .s_axis_b_tdata       ( rwd1_i_b_data[RWD_WL-1:0] ),     // input wire [31 : 0] s_axis_b_tdata
        .s_axis_c_tvalid      ( rwd1_i_c_valid ),                // input wire s_axis_c_tvalid
        .s_axis_c_tdata       ( rwd1_i_c_data[RWD_WL-1:0] ),     // input wire [31 : 0] s_axis_c_tdata
        .m_axis_result_tvalid ( rwd1_o_result_valid ),           // output wire m_axis_result_tvalid
        .m_axis_result_tdata  ( rwd1_o_result_data[RWD_WL-1:0] ) // output wire [31 : 0] m_axis_result_tdata
    );
    MAC u_Rwd ( // CST0 * tor2 + rwd1
        .aclk                 ( i_clk ),                        // input wire aclk
        .s_axis_a_tvalid      ( rwd_i_a_valid ),                // input wire s_axis_a_tvalid
        .s_axis_a_tdata       ( rwd_i_a_data[RWD_WL-1:0] ),     // input wire [31 : 0] s_axis_a_tdata
        .s_axis_b_tvalid      ( rwd_i_b_valid ),                // input wire s_axis_b_tvalid
        .s_axis_b_tdata       ( rwd_i_b_data[RWD_WL-1:0] ),     // input wire [31 : 0] s_axis_b_tdata
        .s_axis_c_tvalid      ( rwd_i_c_valid ),                // input wire s_axis_c_tvalid
        .s_axis_c_tdata       ( rwd_i_c_data[RWD_WL-1:0] ),     // input wire [31 : 0] s_axis_c_tdata
        .m_axis_result_tvalid ( rwd_o_result_valid ),           // output wire m_axis_result_tvalid
        .m_axis_result_tdata  ( rwd_o_result_data[RWD_WL-1:0] ) // output wire [31 : 0] m_axis_result_tdata
    );

endmodule
