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

module MountainCar_Compute_Position #(parameter VEL_WL = 32, POS_WL = 32, ACT_WL = 2) (
    input wire i_clk,
    input wire i_ena,

    input wire [VEL_WL-1:0] i_vel,
    input wire [POS_WL-1:0] i_pos,

    output wire              o_pos_valid,
    output wire [POS_WL-1:0] o_pos
    );

    localparam MIN_P = 32'hbf99999a; // -1.2
    localparam MAX_P = 32'h3f19999a; //  0.6

    // intermidiate signals
        wire [POS_WL-1:0] pos;

    // u_Pos ports
        wire              pos_i_a_valid;
        wire [POS_WL-1:0] pos_i_a_data;
        wire              pos_i_b_valid;
        wire [POS_WL-1:0] pos_i_b_data;
        wire              pos_o_result_valid;
        wire [POS_WL-1:0] pos_o_result_data;
    // u_Pos_Clip ports
        wire              clip_i_ena;
        wire [POS_WL-1:0] clip_i_data;
        wire [POS_WL-1:0] clip_i_max;
        wire [POS_WL-1:0] clip_i_min;
        wire              clip_o_result_valid;
        wire [POS_WL-1:0] clip_o_result;

    // set intermidiate signals
        assign pos = clip_o_result;

    // connect ports
        // MountainCar_Compute_Position outputs
            assign o_pos_valid = clip_o_result_valid;
            assign o_pos       = pos;
        // u_Pos inputs
            assign pos_i_a_valid = i_ena;
            assign pos_i_a_data  = i_pos;
            assign pos_i_b_valid = i_ena;
            assign pos_i_b_data  = i_vel;
        // u_Pos_Clip inputs
            assign clip_i_ena  = pos_o_result_valid;
            assign clip_i_data = pos_o_result_data;
            assign clip_i_max  = MAX_P;
            assign clip_i_min  = MIN_P;

    Adder u_Pos(
        .aclk                 ( i_clk ),                         // input wire aclk
        .s_axis_a_tvalid      ( pos_i_a_valid ),                // input wire s_axis_a_tvalid
        .s_axis_a_tdata       ( pos_i_a_data[POS_WL-1:0] ),     // input wire [31 : 0] s_axis_a_tdata
        .s_axis_b_tvalid      ( pos_i_b_valid ),                // input wire s_axis_b_tvalid
        .s_axis_b_tdata       ( pos_i_b_data[POS_WL-1:0] ),     // input wire [31 : 0] s_axis_b_tdata
        .m_axis_result_tvalid ( pos_o_result_valid ),           // output wire m_axis_result_tvalid
        .m_axis_result_tdata  ( pos_o_result_data[POS_WL-1:0] ) // output wire [31 : 0] m_axis_result_tdata
    );
    Clip32 u_Pos_Clip(
        .i_clk          ( i_clk ),
        .i_ena          ( clip_i_ena ),
        .i_data         ( clip_i_data[POS_WL-1:0] ),
        .i_max          ( clip_i_max[POS_WL-1:0] ),
        .i_min          ( clip_i_min[POS_WL-1:0] ),
        .o_result_valid ( clip_o_result_valid ),
        .o_result       ( clip_o_result[POS_WL-1:0] )
    );

endmodule
