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

module Sin_Cos (
    input wire i_clk,
    input wire i_ena,

    input  wire [31:0] i_th,

    output wire [31:0] o_sin,
    output wire [31:0] o_cos,
    output wire        o_valid
    );

    // u_Th_Fix ports
        wire        thfx_i_a_valid;
        wire [31:0] thfx_i_a_data;
        wire        thfx_o_result_valid;
        wire [31:0] thfx_o_result_data;
    // u_Sin_Cos_Fix ports
        wire        scfx_i_phase_valid;
        wire [31:0] scfx_i_phase_data;
        wire        scfx_o_dout_valid;
        wire [15:0] sfx_o_dout_data;
        wire [15:0] cfx_o_dout_data;
    // u_Sin ports
        wire        sin_i_a_valid;
        wire [15:0] sin_i_a_data;
        wire        sin_o_result_valid;
        wire [31:0] sin_o_result_data;
    // u_Cos ports
        wire        cos_i_a_valid;
        wire [15:0] cos_i_a_data;
        wire        cos_o_result_valid;
        wire [31:0] cos_o_result_data;

    // connect ports
        // Sin_Cos outputs
            assign o_sin   = sin_o_result_data;
            assign o_cos   = cos_o_result_data;
            assign o_valid = sin_o_result_valid & cos_o_result_valid;
        // u_Th_Fix input
            assign thfx_i_a_valid = i_ena;
            assign thfx_i_a_data  = i_th;
        // u_Sin_Cos_Fix input
            assign scfx_i_phase_valid = thfx_o_result_valid;
            assign scfx_i_phase_data  = thfx_o_result_data;
        // u_Sin input
            assign sin_i_a_valid = scfx_o_dout_valid;
            assign sin_i_a_data  = sfx_o_dout_data;
        // u_Cos input
            assign cos_i_a_valid = scfx_o_dout_valid;
            assign cos_i_a_data  = cfx_o_dout_data;

    Float2Fix u_Th_Fix (
        .aclk                 ( i_clk ),                   // input wire aclk
        .s_axis_a_tvalid      ( thfx_i_a_valid ),          // input wire s_axis_a_tvalid
        .s_axis_a_tdata       ( thfx_i_a_data[31:0] ),     // input wire [31 : 0] s_axis_a_tdata
        .m_axis_result_tvalid ( thfx_o_result_valid ),     // output wire m_axis_result_tvalid
        .m_axis_result_tdata  ( thfx_o_result_data[31:0] ) // output wire [31 : 0] m_axis_result_tdata
    );
    Cordic u_Sin_Cos_Fix (
        .aclk                ( i_clk ),                    // input wire aclk
        .s_axis_phase_tvalid ( scfx_i_phase_valid ),       // input wire s_axis_phase_tvalid
        .s_axis_phase_tdata  ( scfx_i_phase_data[31:0] ),  // input wire [31 : 0] s_axis_phase_tdata
        .m_axis_dout_tvalid  ( scfx_o_dout_valid ),        // output wire m_axis_dout_tvalid
        .m_axis_dout_tdata   ( {sfx_o_dout_data[15:0], cfx_o_dout_data[15:0]} ) // output wire [31 : 0] m_axis_dout_tdata
    );
    Fix2Float u_Sin (
        .aclk                 ( i_clk ),                  // input wire aclk
        .s_axis_a_tvalid      ( sin_i_a_valid ),          // input wire s_axis_a_tvalid
        .s_axis_a_tdata       ( sin_i_a_data[15:0] ),     // input wire [15 : 0] s_axis_a_tdata
        .m_axis_result_tvalid ( sin_o_result_valid ),     // output wire m_axis_result_tvalid
        .m_axis_result_tdata  ( sin_o_result_data[31:0] ) // output wire [31 : 0] m_axis_result_tdata
    );
    Fix2Float u_Cos (
        .aclk                 ( i_clk ),                  // input wire aclk
        .s_axis_a_tvalid      ( cos_i_a_valid ),          // input wire s_axis_a_tvalid
        .s_axis_a_tdata       ( cos_i_a_data[15:0] ),     // input wire [15 : 0] s_axis_a_tdata
        .m_axis_result_tvalid ( cos_o_result_valid ),     // output wire m_axis_result_tvalid
        .m_axis_result_tdata  ( cos_o_result_data[31:0] ) // output wire [31 : 0] m_axis_result_tdata
    );

endmodule
