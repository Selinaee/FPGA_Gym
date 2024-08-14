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

module Clip32 (
    input wire i_clk,
    input wire i_ena,

    input wire  [31:0] i_data,
    input wire  [31:0] i_max,
    input wire  [31:0] i_min,

    output wire        o_result_valid,
    output wire [31:0] o_result
    );

    // u_Greater ports
    wire        gtr_i_a_valid;
    wire [31:0] gtr_i_a;
    wire        gtr_i_b_valid;
    wire [31:0] gtr_i_b;
    wire        gtr_o_result_valid;
    wire [7:0]  gtr_o_result;

    // u_Less ports
    wire        les_i_a_valid;
    wire [31:0] les_i_a;
    wire        les_i_b_valid;
    wire [31:0] les_i_b;
    wire        les_o_result_valid;
    wire [7:0]  les_o_result;

    // connect ports
        // Clip32 outputs
        assign o_result_valid = gtr_o_result_valid & les_o_result_valid;
        assign o_result       = |gtr_o_result ? i_max :
                                |les_o_result ? i_min : i_data;
        // u_Greater inputs
        assign gtr_i_a_valid = i_ena;
        assign gtr_i_a = i_data;
        assign gtr_i_b_valid = i_ena;
        assign gtr_i_b = i_max;
        // u_Less inputs
        assign les_i_a_valid = i_ena;
        assign les_i_a = i_data;
        assign les_i_b_valid = i_ena;
        assign les_i_b = i_min;

    Comparator_Greater u_Greater ( // i_data > i_max
        .aclk                 ( i_clk ),               // input  wire          aclk
        .s_axis_a_tvalid      ( gtr_i_a_valid ),       // input  wire          s_axis_a_tvalid
        .s_axis_a_tdata       ( gtr_i_a[31:0] ),       // input  wire [31 : 0] s_axis_a_tdata
        .s_axis_b_tvalid      ( gtr_i_b_valid ),       // input  wire          s_axis_b_tvalid
        .s_axis_b_tdata       ( gtr_i_b[31:0] ),       // input  wire [31 : 0] s_axis_b_tdata
        .m_axis_result_tvalid ( gtr_o_result_valid ), // output wire          m_axis_result_tvalid
        .m_axis_result_tdata  ( gtr_o_result[7:0] )    // output wire [7 : 0]  m_axis_result_tdata
    );
    Comparator_Less u_Less ( // i_data < i_min
        .aclk                 ( i_clk ),               // input  wire          aclk
        .s_axis_a_tvalid      ( les_i_a_valid ),       // input  wire          s_axis_a_tvalid
        .s_axis_a_tdata       ( les_i_a[31:0] ),       // input  wire [31 : 0] s_axis_a_tdata
        .s_axis_b_tvalid      ( les_i_b_valid ),       // input  wire          s_axis_b_tvalid
        .s_axis_b_tdata       ( les_i_b[31:0] ),       // input  wire [31 : 0] s_axis_b_tdata
        .m_axis_result_tvalid ( les_o_result_valid ), // output wire          m_axis_result_tvalid
        .m_axis_result_tdata  ( les_o_result[7:0] )    // output wire [7 : 0]  m_axis_result_tdata
    );
endmodule
