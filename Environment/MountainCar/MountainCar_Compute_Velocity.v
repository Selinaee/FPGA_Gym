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

module MountainCar_Compute_Velocity #(parameter VEL_WL = 32, POS_WL = 32, ACT_WL = 2) (
    input wire i_clk,
    input wire i_ena,

    input wire [VEL_WL-1:0] i_vel,
    input wire [POS_WL-1:0] i_pos,
    input wire [ACT_WL-1:0] i_act,

    output wire              o_vel_valid,
    output wire [VEL_WL-1:0] o_vel
    );

    localparam G     = 32'hbb23d70a; // -0.0025
    localparam MIN_V = 32'hbd8f5c29; // -0.07
    localparam MAX_V = 32'h3d8f5c29; //  0.07

    localparam CST0 = 32'hba83126f; // -0.001
    localparam CST1 = 32'h3a83126f; //  0.001
    localparam CST2 = 32'h40400000; //  3

    localparam F_WL = 32;

    // intermidiate signals
        wire [F_WL-1:0]   f;
        wire [VEL_WL-1:0] vel;

    // u_3Pos ports
        wire              pos3_i_a_valid;
        wire [POS_WL-1:0] pos3_i_a_data;
        wire              pos3_i_b_valid;
        wire [POS_WL-1:0] pos3_i_b_data;
        wire              pos3_o_result_valid;
        wire [POS_WL-1:0] pos3_o_result_data;
    // u_Cos ports
        wire              cos_i_ena;
        wire [POS_WL-1:0] cos_i_th;
        wire [POS_WL-1:0] cos_o_cos;
        wire              cos_o_valid;
    // u_Delta_Vel ports
        wire              dv_i_a_valid;
        wire [VEL_WL-1:0] dv_i_a_data;
        wire              dv_i_b_valid;
        wire [VEL_WL-1:0] dv_i_b_data;
        wire              dv_i_c_valid;
        wire [VEL_WL-1:0] dv_i_c_data;
        wire              dv_o_result_valid;
        wire [VEL_WL-1:0] dv_o_result_data;
    // u_Vel ports
        wire              vel_i_a_valid;
        wire [VEL_WL-1:0] vel_i_a_data;
        wire              vel_i_b_valid;
        wire [VEL_WL-1:0] vel_i_b_data;
        wire              vel_o_result_valid;
        wire [VEL_WL-1:0] vel_o_result_data;
    // u_Vel_Clip ports
        wire              clip_i_ena;
        wire [VEL_WL-1:0] clip_i_data;
        wire [VEL_WL-1:0] clip_i_max;
        wire [VEL_WL-1:0] clip_i_min;
        wire              clip_o_result_valid;
        wire [VEL_WL-1:0] clip_o_result;

    // set intermidiate signals
        assign f = (i_act == `ZERO(ACT_WL)) ? CST0 :
                   (i_act == `ONE(ACT_WL))  ? `ZERO(F_WL) : CST1;
        assign vel = clip_o_result;

    // connect ports
        // MountainCar_Compute_Velocity outputs
            assign o_vel_valid = clip_o_result_valid;
            assign o_vel       = vel;
        // u_3Pos inputs
            assign pos3_i_a_valid = i_ena;
            assign pos3_i_a_data  = CST2;
            assign pos3_i_b_valid = i_ena;
            assign pos3_i_b_data  = i_pos;
        // u_Cos inputs
            assign cos_i_ena = pos3_o_result_valid;
            assign cos_i_th  = pos3_o_result_data;
        // u_Delta_Vel inputs (cos(3*pos) * G + f)
            assign dv_i_a_valid = cos_o_valid;
            assign dv_i_a_data  = cos_o_cos;
            assign dv_i_b_valid = i_ena;
            assign dv_i_b_data  = G;
            assign dv_i_c_valid = i_ena;
            assign dv_i_c_data  = f;
        // u_Vel inputs
            assign vel_i_a_valid = i_ena;
            assign vel_i_a_data  = i_vel;
            assign vel_i_b_valid = dv_o_result_valid;
            assign vel_i_b_data  = dv_o_result_data;
        // u_Vel_Clip inputs
            assign clip_i_ena  = vel_o_result_valid;
            assign clip_i_data = vel_o_result_data;
            assign clip_i_max  = MAX_V;
            assign clip_i_min  = MIN_V;

    Multiplier u_3Pos( // 3 * pos
        .aclk                 ( i_clk ),                         // input wire aclk
        .s_axis_a_tvalid      ( pos3_i_a_valid ),                // input wire s_axis_a_tvalid
        .s_axis_a_tdata       ( pos3_i_a_data[POS_WL-1:0] ),     // input wire [31 : 0] s_axis_a_tdata
        .s_axis_b_tvalid      ( pos3_i_b_valid ),                // input wire s_axis_b_tvalid
        .s_axis_b_tdata       ( pos3_i_b_data[POS_WL-1:0] ),     // input wire [31 : 0] s_axis_b_tdata
        .m_axis_result_tvalid ( pos3_o_result_valid ),           // output wire m_axis_result_tvalid
        .m_axis_result_tdata  ( pos3_o_result_data[POS_WL-1:0] ) // output wire [31 : 0] m_axis_result_tdata
    );
    Sin_Cos u_Cos( // cos(3 * pos)
        .i_clk   ( i_clk ),
        .i_ena   ( cos_i_ena ),
        .i_th    ( cos_i_th[POS_WL-1:0] ),
        .o_sin   (  ),
        .o_cos   ( cos_o_cos[POS_WL-1:0] ),
        .o_valid ( cos_o_valid )
    );
    MAC u_Delta_Vel( // cos(3*pos) * G + f
        .aclk                 ( i_clk ),                       // input wire aclk
        .s_axis_a_tvalid      ( dv_i_a_valid ),                // input wire s_axis_a_tvalid
        .s_axis_a_tdata       ( dv_i_a_data[VEL_WL-1:0] ),     // input wire [31 : 0] s_axis_a_tdata
        .s_axis_b_tvalid      ( dv_i_b_valid ),                // input wire s_axis_b_tvalid
        .s_axis_b_tdata       ( dv_i_b_data[VEL_WL-1:0] ),     // input wire [31 : 0] s_axis_b_tdata
        .s_axis_c_tvalid      ( dv_i_c_valid ),                // input wire s_axis_c_tvalid
        .s_axis_c_tdata       ( dv_i_c_data[VEL_WL-1:0] ),     // input wire [31 : 0] s_axis_c_tdata
        .m_axis_result_tvalid ( dv_o_result_valid ),           // output wire m_axis_result_tvalid
        .m_axis_result_tdata  ( dv_o_result_data[VEL_WL-1:0] ) // output wire [31 : 0] m_axis_result_tdata
    );
    Adder u_Vel(
        .aclk                 ( i_clk ),                         // input wire aclk
        .s_axis_a_tvalid      ( vel_i_a_valid ),                // input wire s_axis_a_tvalid
        .s_axis_a_tdata       ( vel_i_a_data[VEL_WL-1:0] ),     // input wire [31 : 0] s_axis_a_tdata
        .s_axis_b_tvalid      ( vel_i_b_valid ),                // input wire s_axis_b_tvalid
        .s_axis_b_tdata       ( vel_i_b_data[VEL_WL-1:0] ),     // input wire [31 : 0] s_axis_b_tdata
        .m_axis_result_tvalid ( vel_o_result_valid ),           // output wire m_axis_result_tvalid
        .m_axis_result_tdata  ( vel_o_result_data[VEL_WL-1:0] ) // output wire [31 : 0] m_axis_result_tdata
    );
    Clip32 u_Vel_Clip(
        .i_clk          ( i_clk ),
        .i_ena          ( clip_i_ena ),
        .i_data         ( clip_i_data[VEL_WL-1:0] ),
        .i_max          ( clip_i_max[VEL_WL-1:0] ),
        .i_min          ( clip_i_min[VEL_WL-1:0] ),
        .o_result_valid ( clip_o_result_valid ),
        .o_result       ( clip_o_result[VEL_WL-1:0] )
    );

endmodule
