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
module Compute_Single #(parameter STA_WL = 128, ACT_WL = 1, OBS_WL = 128, RWD_WL = 1) (
    input wire i_clk,
    input wire i_ena,

    input  wire [STA_WL-1:0] i_sta,
    input  wire [ACT_WL-1:0] i_act,

    output wire [STA_WL-1:0] o_sta,

    output wire [OBS_WL-1:0] o_obs, // observations
    output wire [RWD_WL-1:0] o_rwd,
    output wire              o_done,

    output wire              o_valid
    );

    parameter INPUT_BIT  = 32'd32, OUTPUT_BIT = 32'd32;

    parameter TAU     = 32'b00111100101000111101011100001010; // 0.02
    parameter GRAVITY = 32'b01000001000111001100110011001101; // 9.8
    parameter CNST_2  = 32'b00111101001110100010111010001100; // 0.05/1.1
    parameter CNST_3  = 32'b00111111001010101010101010101011; // 2/3
    parameter CNST_4  = 32'b01000000000110011001100110011010; //  2.4
    parameter CNST_N4 = 32'b11000000000110011001100110011010; // -2.4
    parameter CNST_5  = 32'b00111110010101100111011101010000; //  0.20943952 rad =  12 deg
    parameter CNST_N5 = 32'b10111110010101100111011101010000; // -0.20943952 rad = -12 deg

    // split i_sta
        wire [INPUT_BIT-1:0] i_x;
        wire [INPUT_BIT-1:0] i_x_dot;
        wire [INPUT_BIT-1:0] i_float_theta;
        wire [INPUT_BIT-1:0] i_theta_dot;
        assign {i_theta_dot, i_float_theta, i_x_dot, i_x} = i_sta;

    // split o_sta, o_obs, o_rwd, o_done
        wire [OUTPUT_BIT-1:0] o_next_x;
        wire [OUTPUT_BIT-1:0] o_next_x_dot;
        wire [OUTPUT_BIT-1:0] o_next_float_theta;
        wire [OUTPUT_BIT-1:0] o_next_theta_dot;
        wire [OUTPUT_BIT-1:0] o_reward;
        wire [OUTPUT_BIT-1:0] o_terminated;
        assign o_sta = {o_next_theta_dot, o_next_float_theta, o_next_x_dot, o_next_x};
        assign o_obs = {o_next_theta_dot, o_next_float_theta, o_next_x_dot, o_next_x};
        assign o_rwd = o_reward[0];
        assign o_done = o_terminated[0];

    wire o_terminated_valid;
    wire o_next_x_valid;
    wire o_next_x_dot_valid;
    wire o_next_float_theta_valid;
    wire o_next_theta_dot_valid;
    wire o_reward_valid;

    wire o_no_terminated;

    wire [31:0] x;
    wire [31:0] x_dot;
    wire x_valid;
    wire x_dot_valid;

    wire [31:0] float_theta;
    wire [31:0] theta_dot;
    wire float_theta_tvalid;
    wire theta_dot_valid;

    wire s_theta_float_to_fixed_tvalid;
    wire [31:0] s_theta;
    wire m_theta_float_to_fixed_tvalid;
    wire [31:0] m_theta_float_to_fixed;

    wire s_cordic_tvalid;
    wire [31:0] s_cordic;
    wire [31:0] m_cordic;
    wire m_cordic_tvalid;

    wire [15:0] s_costheta;
    wire [31:0] m_costheta;
    wire [31:0] costheta;
    wire s_sintheta_tvalid;
    wire [15:0] s_sintheta;
    wire [31:0] m_sintheta;
    wire m_sintheta_tvalid;
    wire [31:0] sintheta;
    wire s_TAU_mul_x_dot_tvalid;
    wire [31:0] s_x_dot;
    wire [31:0] m_TAU_mul_x_dot;
    wire s_next_x_tvalid;
    wire [31:0] s_time_mul_x_dot;
    wire [31:0] s_x;
    wire [31:0] m_next_x;
    wire s_TAU_mul_theta_dot_tvalid;
    wire [31:0] s_theta_dot;
    wire [31:0] m_TAU_mul_theta_dot;
    wire s_next_theta_tvalid;
    wire [31:0] s_next_theta_theta;
    wire [31:0] s_TAU_mul_theta_dot;
    wire [31:0] next_theta;
    wire s_theta_dot_mul_theta_dot_tvalid;
    wire [31:0] m_theta_dot_mul_theta_dot;
    wire m_theta_dot_mul_theta_dot_tvalid;
    wire [31:0] m_theta_dot_2;
    wire [31:0] s_theta_dot_2;
    wire [31:0] cnst_1;
    wire s_cnst_2_mul_theta_dot_2_tvalid;
    wire [31:0] s_cnst_2_mul_theta_dot_2;
    wire m_cnst_2_mul_theta_dot_2_tvalid;
    wire [31:0] m_cnst_2_mul_theta_dot_2;  
    wire s_cnst_2_mul_theta_dot_2_mul_sintheta_tvalid;
    wire [31:0] s_cnst_2_mul_theta_dot_2_mul_sintheta;
    wire m_cnst_2_mul_theta_dot_2_mul_sintheta_tvalid;
    wire [31:0] m_cnst_2_mul_theta_dot_2_mul_sintheta;
    wire s_temp_tvalid;
    wire [31:0] m_temp;
    wire m_temp_tvalid;
    wire s_gravity_mul_sintheta_tvalid;
    wire [31:0] m_gravity_mul_sintheta;
    wire m_gravity_mul_sintheta_tvalid;
    wire s_temp_mul_costheta_tvalid;
    wire [31:0] s_temp_mul_costheta;
    wire m_temp_mul_costheta_tvalid;
    wire [31:0] m_temp_mul_costheta;
    wire s_graxsintheta_sub_cnst_3xtheta_dot_2xsintheta_add_cnst_1xcostheta_tvalid;
    wire [31:0] s_graxsintheta;
    wire [31:0] s_cnst_3xtheta_dot_2xsintheta_add_cnst_1xcostheta_tdata;
    wire m_graxsintheta_sub_cnst_3xtheta_dot_2xsintheta_add_cnst_1xcostheta_tvalid;
    wire [31:0] m_graxsintheta_sub_cnst_3xtheta_dot_2xsintheta_add_cnst_1xcostheta;
    wire [31:0] m_costheta_2;
    wire s_costheta_2_tvalid;
    wire [31:0] s_costheta_2_costheta;
    wire m_costheta_2_tvalid;
    wire s_cnst_2xcostheta_2_u_tvalid;
    wire [31:0] s_costheta_2;
    wire m_cnst_2xcostheta_2_tvalid;
    wire [31:0] m_cnst_2xcostheta_2;
    wire s_cnst_2_sub_cnst_2xcostheta_2_tvalid;
    wire m_cnst_2_sub_cnst_2xcostheta_2_tvalid;
    wire [31:0] s_cnst_2xcostheta_2;
    wire [31:0] m_cnst_2_sub_cnst_2xcostheta_2;
    wire s_thetaacc_tvalid;
    wire [31:0] s_graxsintheta_sub_cnst_3xtheta_dot_2xsintheta_add_cnst_1xcostheta;
    wire [31:0] s_cnst_2_sub_cnst_2xcostheta_2;
    wire m_thetaacc_tvalid;
    wire [31:0] m_thetaacc;
    wire s_cnst_2_tvalid;
    wire [31:0] m_cnst_2xcostheta;
    wire s_cnst_2xcosthetaxthetaacc_tvalid;
    wire [31:0] s_cnst_2xcostheta;
    wire [31:0] s_thetaacc;
    wire [31:0] m_cnst_2xcosthetaxthetaacc;
    wire [31:0] s_temp;
    wire [31:0] s_cnst_2xcosthetaxthetaacc;
    wire m_xacc_tvalid;
    wire [31:0] m_xacc;
    wire s_TAUxthetaacc_tvalid;
    wire [31:0] thetaacc;
    wire m_TAUxthetaacc_tvalid;
    wire [31:0] m_TAUxthetaacc;
    wire [31:0] s_TAUxthetaacc;
    wire [31:0] m_next_theta_dot;
    wire s_TAUxxacc_tvalid;
    wire [31:0] s_TAUxxacc_xacc;
    wire [31:0] m_TAUxxacc;
    wire s_next_x_dot_tvalid;
    wire [31:0] s_TAUxxacc;
    wire [31:0] m_next_x_dot;
    wire [31:0] s_next_x_greater_threshold_a;      
    wire [0:0] s_next_x_greater_threshold_tvalid; 
    wire [31:0] s_next_x_greater_threshold_b;        
    wire [0:0] m_next_x_greater_threshold_tvalid; 
    wire [7:0] m_next_x_greater_threshold;
    wire [31:0] s_next_theta_greater_threshold_a;     
    wire [0:0]  s_next_theta_greater_threshold_tvalid;
    wire [31:0] s_next_theta_greater_threshold_b;     
    wire [0:0]  m_next_theta_greater_threshold_tvalid;
    wire [7:0]  m_next_theta_greater_threshold;
    wire [31:0] s_next_x_less_threshold_a;   
    wire [0:0] s_next_x_less_threshold_tvalid;
    wire [31:0] s_next_x_less_threshold_b;     
    wire [0:0] m_next_x_less_threshold_tvalid;
    wire [7:0] m_next_x_less_threshold;
    wire [31:0] s_next_theta_less_threshold_a;
    wire [0:0] s_next_theta_less_threshold_tvalid;
    wire [31:0] s_next_theta_less_threshold_b;     
    wire [0:0] m_next_theta_less_threshold_tvalid;
    wire [7:0] m_next_theta_less_threshold;

    assign s_cordic_tvalid = m_theta_float_to_fixed_tvalid;
    assign s_cordic = m_theta_float_to_fixed;
    assign s_costheta_tvalid = m_cordic_tvalid;
    assign s_costheta = m_cordic[15:0];
    assign costheta = m_costheta;
    assign s_sintheta_tvalid = m_cordic_tvalid;
    assign s_sintheta = m_cordic[31:16];
    assign sintheta = m_sintheta;
    assign s_x_dot = x_dot;
    assign s_TAU_mul_x_dot_tvalid = x_dot_valid;
    assign s_time_mul_x_dot = m_TAU_mul_x_dot;
    assign s_x = x;
    assign s_next_x_tvalid = m_TAU_mul_x_dot_tvalid;
    assign s_theta_dot = theta_dot;
    assign s_TAU_mul_theta_dot_tvalid = theta_dot_valid;
    assign s_TAU_mul_theta_dot = m_TAU_mul_theta_dot;
    assign s_next_theta_tvalid = m_TAU_mul_theta_dot_tvalid;
    assign s_next_theta_theta = float_theta;
    assign s_theta_dot_mul_theta_dot_tvalid =  m_sintheta_tvalid;
    assign s_theta_dot_2 = m_theta_dot_2;
    assign cnst_1 = (i_act == `ONE(ACT_WL)) ? 32'b01000001000100010111010001011101 : 32'b11000001000100010111010001011101;
    assign s_cnst_2_mul_theta_dot_2_tvalid = m_theta_dot_mul_theta_dot_tvalid;
    assign s_cnst_2_mul_theta_dot_2_mul_sintheta_tvalid = m_cnst_2_mul_theta_dot_2_tvalid;
    assign s_cnst_2_mul_theta_dot_2 = m_cnst_2_mul_theta_dot_2;
    assign s_temp_tvalid = m_cnst_2_mul_theta_dot_2_mul_sintheta_tvalid;
    assign s_cnst_2_mul_theta_dot_2_mul_sintheta = m_cnst_2_mul_theta_dot_2_mul_sintheta;
    assign s_gravity_mul_sintheta_tvalid = m_sintheta_tvalid;
    assign s_temp_mul_costheta_tvalid = m_temp_tvalid;
    assign s_temp_mul_costheta = m_temp;
    assign s_graxsintheta = m_gravity_mul_sintheta;
    assign s_cnst_3xtheta_dot_2xsintheta_add_cnst_1xcostheta_tdata = m_temp_mul_costheta;
    assign s_graxsintheta_sub_cnst_3xtheta_dot_2xsintheta_add_cnst_1xcostheta_tvalid = m_temp_mul_costheta_tvalid;
    assign s_costheta_2_tvalid =  m_costheta_tvalid;
    assign s_costheta_2_costheta = m_costheta;
    assign s_cnst_2xcostheta_2_u_tvalid = m_costheta_2_tvalid;
    assign s_costheta_2 = m_costheta_2;
    assign s_cnst_2_sub_cnst_2xcostheta_2_tvalid = m_cnst_2xcostheta_2_tvalid;
    assign s_cnst_2xcostheta_2 = m_cnst_2xcostheta_2;
    assign s_thetaacc_tvalid = m_graxsintheta_sub_cnst_3xtheta_dot_2xsintheta_add_cnst_1xcostheta_tvalid;
    assign s_graxsintheta_sub_cnst_3xtheta_dot_2xsintheta_add_cnst_1xcostheta = m_graxsintheta_sub_cnst_3xtheta_dot_2xsintheta_add_cnst_1xcostheta;
    assign s_cnst_2_sub_cnst_2xcostheta_2 = m_cnst_2_sub_cnst_2xcostheta_2;
    assign s_cnst_2_tvalid = m_costheta_tvalid;
    assign s_cnst_2xcosthetaxthetaacc_tvalid = m_cnst_2xcostheta_tvalid;
    assign s_cnst_2xcostheta = m_cnst_2xcostheta;
    assign s_thetaacc = m_thetaacc;
    assign s_temp = m_temp;
    assign s_xacc_tvalid = m_cnst_2xcosthetaxthetaacc_tvalid;
    assign s_cnst_2xcosthetaxthetaacc = m_cnst_2xcosthetaxthetaacc;
    assign s_TAUxthetaacc_tvalid = m_thetaacc_tvalid;
    assign thetaacc = m_thetaacc;
    assign s_next_theta_dot_tvalid = m_TAUxthetaacc_tvalid;
    assign s_TAUxthetaacc = m_TAUxthetaacc;
    assign s_TAUxxacc_tvalid = m_xacc_tvalid;
    assign s_TAUxxacc_xacc = m_xacc;
    assign s_next_x_dot_tvalid = m_TAUxxacc_tvalid;
    assign s_TAUxxacc = m_TAUxxacc;
    assign s_next_x_greater_threshold_a = m_next_x;    
    assign s_next_x_greater_threshold_tvalid = m_next_x_tvalid;
    assign s_next_x_greater_threshold_b = CNST_N4;      
    assign s_next_theta_greater_threshold_a = next_theta;     
    assign s_next_theta_greater_threshold_tvalid = next_theta_valid;
    assign s_next_theta_greater_threshold_b = CNST_N5;     
    assign s_next_x_less_threshold_a = m_next_x;  
    assign s_next_x_less_threshold_tvalid = m_next_x_tvalid;
    assign s_next_x_less_threshold_b = CNST_4;
    assign s_next_theta_less_threshold_a = next_theta;     
    assign s_next_theta_less_threshold_tvalid = next_theta_valid;
    assign s_next_theta_less_threshold_b = CNST_5;

    assign o_terminated_valid = ((m_next_theta_less_threshold_tvalid) & (m_next_x_less_threshold_tvalid) &
                                 (m_next_theta_greater_threshold_tvalid) & (m_next_x_greater_threshold_tvalid));
    assign o_no_terminated =  ((m_next_theta_less_threshold != 8'b0) & (m_next_x_less_threshold != 8'b0) &
                               (m_next_theta_greater_threshold != 8'b0) & (m_next_x_greater_threshold != 8'b0));
    assign o_terminated = ! o_no_terminated;
    assign o_reward = (o_no_terminated == 1'b1) ? `ONE(OUTPUT_BIT) : `ONE(OUTPUT_BIT);
    assign o_reward_valid = o_terminated_valid;
    assign o_valid = (o_reward_valid) & (o_terminated_valid) & (o_next_theta_dot_valid) & (o_next_x_dot_valid);
    assign o_next_x_valid = m_next_x_tvalid;
    assign o_next_x_dot_valid = m_next_x_dot_tvalid;
    assign o_next_float_theta_valid = next_theta_valid;
    assign o_next_theta_dot_valid = m_next_theta_dot_tvalid;

    assign x = i_x;
    assign x_dot = i_x_dot;
    assign float_theta = i_float_theta;
    assign theta_dot = i_theta_dot;

    assign x_valid = (i_ena) ? 1'b1 : 1'b0;
    assign x_dot_valid = (i_ena) ? 1'b1 : 1'b0;
    assign float_theta_tvalid = (i_ena) ? 1'b1 : 1'b0;
    assign theta_dot_valid = (i_ena) ? 1'b1 : 1'b0;

    assign o_next_x = m_next_x;
    assign o_next_float_theta = next_theta;
    assign o_next_x_dot = m_next_x_dot;
    assign o_next_theta_dot = m_next_theta_dot;


    assign s_theta = float_theta;
    assign s_theta_float_to_fixed_tvalid = float_theta_tvalid;

    assign x = i_x;
    assign x_dot = i_x_dot;
    assign float_theta = i_float_theta;
    assign theta_dot = i_theta_dot;

    assign x_valid = (i_ena) ? 1'b1 : 1'b0;
    assign x_dot_valid = (i_ena) ? 1'b1 : 1'b0;
    assign float_theta_tvalid = (i_ena) ? 1'b1 : 1'b0;
    assign theta_dot_valid = (i_ena) ? 1'b1 : 1'b0;

    assign o_next_x = m_next_x;
    assign o_next_float_theta = next_theta;
    assign o_next_x_dot = m_next_x_dot;
    assign o_next_theta_dot = m_next_theta_dot;


    assign s_theta = float_theta;
    assign s_theta_float_to_fixed_tvalid = float_theta_tvalid;

    floating_point_float_to_fixed theta_float_to_fixed_u (
        .aclk                 (i_clk),
        .s_axis_a_tvalid      (s_theta_float_to_fixed_tvalid),
        .s_axis_a_tdata       (s_theta),
        .m_axis_result_tvalid (m_theta_float_to_fixed_tvalid),
        .m_axis_result_tdata  (m_theta_float_to_fixed)
    );
    cordic_0 cordic_u (
        .aclk                 (i_clk),
        .s_axis_phase_tvalid (s_cordic_tvalid),
        .s_axis_phase_tdata  (s_cordic),
        .m_axis_dout_tvalid  (m_cordic_tvalid),
        .m_axis_dout_tdata   (m_cordic)
    );
    floating_point_fixed_to_float costheta_u (
        .aclk                 (i_clk),
        .s_axis_a_tvalid      (s_costheta_tvalid),
        .s_axis_a_tdata       (s_costheta),
        .m_axis_result_tvalid (m_costheta_tvalid),
        .m_axis_result_tdata  (m_costheta)
    );
    floating_point_fixed_to_float sintheta_u (
        .aclk                 (i_clk),
        .s_axis_a_tvalid      (s_sintheta_tvalid),
        .s_axis_a_tdata       (s_sintheta),
        .m_axis_result_tvalid (m_sintheta_tvalid),
        .m_axis_result_tdata  (m_sintheta)
    );
    floating_multiply TAU_mul_x_dot_u (
        .aclk                 (i_clk),
        .s_axis_a_tvalid      (s_TAU_mul_x_dot_tvalid),
        .s_axis_a_tdata       (TAU),
        .s_axis_b_tvalid      (s_TAU_mul_x_dot_tvalid),
        .s_axis_b_tdata       (s_x_dot),
        .m_axis_result_tvalid (m_TAU_mul_x_dot_tvalid),
        .m_axis_result_tdata  (m_TAU_mul_x_dot)
    );
    floating_point_adder next_x_u (
        .aclk                 (i_clk),
        .s_axis_a_tvalid      (s_next_x_tvalid),
        .s_axis_a_tdata       (s_time_mul_x_dot),
        .s_axis_b_tvalid      (s_next_x_tvalid),
        .s_axis_b_tdata       (s_x),
        .m_axis_result_tvalid (m_next_x_tvalid),
        .m_axis_result_tdata  (m_next_x)
    );
    floating_multiply TAU_mul_theta_dot_u (
        .aclk                 (i_clk),
        .s_axis_a_tvalid      (s_TAU_mul_theta_dot_tvalid),
        .s_axis_a_tdata       (TAU),
        .s_axis_b_tvalid      (s_TAU_mul_theta_dot_tvalid),
        .s_axis_b_tdata       (s_theta_dot),
        .m_axis_result_tvalid (m_TAU_mul_theta_dot_tvalid),
        .m_axis_result_tdata  (m_TAU_mul_theta_dot)
    );
    floating_point_adder next_theta_u (
        .aclk                 (i_clk),
        .s_axis_a_tvalid      (s_next_theta_tvalid),
        .s_axis_a_tdata       (s_next_theta_theta),
        .s_axis_b_tvalid      (s_next_theta_tvalid),
        .s_axis_b_tdata       (s_TAU_mul_theta_dot),
        .m_axis_result_tvalid (next_theta_valid),
        .m_axis_result_tdata  (next_theta)
    );
    floating_multiply theta_dot_mul_theta_dot_u (
        .aclk                 (i_clk),
        .s_axis_a_tvalid      (s_theta_dot_mul_theta_dot_tvalid),
        .s_axis_a_tdata       (theta_dot),
        .s_axis_b_tvalid      (s_theta_dot_mul_theta_dot_tvalid),
        .s_axis_b_tdata       (theta_dot),
        .m_axis_result_tvalid (m_theta_dot_mul_theta_dot_tvalid),
        .m_axis_result_tdata  (m_theta_dot_2)
    );
    floating_multiply cnst_2_mul_theta_dot_2_u (
        .aclk                 (i_clk),
        .s_axis_a_tvalid      (s_cnst_2_mul_theta_dot_2_tvalid),
        .s_axis_a_tdata       (s_theta_dot_2),
        .s_axis_b_tvalid      (s_cnst_2_mul_theta_dot_2_tvalid),
        .s_axis_b_tdata       (CNST_2),
        .m_axis_result_tvalid (m_cnst_2_mul_theta_dot_2_tvalid),
        .m_axis_result_tdata  (m_cnst_2_mul_theta_dot_2)
    );
    floating_multiply cnst_2_mul_theta_dot_2_mul_sintheta_u (
        .aclk                 (i_clk),
        .s_axis_a_tvalid      (s_cnst_2_mul_theta_dot_2_mul_sintheta_tvalid),
        .s_axis_a_tdata       (s_cnst_2_mul_theta_dot_2),
        .s_axis_b_tvalid      (s_cnst_2_mul_theta_dot_2_mul_sintheta_tvalid),
        .s_axis_b_tdata       (sintheta),
        .m_axis_result_tvalid (m_cnst_2_mul_theta_dot_2_mul_sintheta_tvalid),
        .m_axis_result_tdata  (m_cnst_2_mul_theta_dot_2_mul_sintheta)
    );
    floating_point_adder temp_u (
        .aclk                 (i_clk),
        .s_axis_a_tvalid      (s_temp_tvalid),
        .s_axis_a_tdata       (s_cnst_2_mul_theta_dot_2_mul_sintheta),
        .s_axis_b_tvalid      (s_temp_tvalid),
        .s_axis_b_tdata       (cnst_1),
        .m_axis_result_tvalid (m_temp_tvalid),
        .m_axis_result_tdata  (m_temp)
    );
    floating_multiply gravity_mul_sintheta_u (
        .aclk                 (i_clk),
        .s_axis_a_tvalid      (s_gravity_mul_sintheta_tvalid),
        .s_axis_a_tdata       (GRAVITY),
        .s_axis_b_tvalid      (s_gravity_mul_sintheta_tvalid),
        .s_axis_b_tdata       (sintheta),
        .m_axis_result_tvalid (m_gravity_mul_sintheta_tvalid),
        .m_axis_result_tdata  (m_gravity_mul_sintheta)
    );
    floating_multiply temp_mul_costheta_u (
        .aclk                 (i_clk),
        .s_axis_a_tvalid      (s_temp_mul_costheta_tvalid),
        .s_axis_a_tdata       (s_temp_mul_costheta),
        .s_axis_b_tvalid      (s_temp_mul_costheta_tvalid),
        .s_axis_b_tdata       (costheta),
        .m_axis_result_tvalid (m_temp_mul_costheta_tvalid),
        .m_axis_result_tdata  (m_temp_mul_costheta)
    );
    floating_point_subtract graxsintheta_sub_cnst_3xtheta_dot_2xsintheta_add_cnst_1xcostheta_u(
        .aclk                 (i_clk),
        .s_axis_a_tvalid      (s_graxsintheta_sub_cnst_3xtheta_dot_2xsintheta_add_cnst_1xcostheta_tvalid),
        .s_axis_a_tdata       (s_graxsintheta),
        .s_axis_b_tvalid      (s_graxsintheta_sub_cnst_3xtheta_dot_2xsintheta_add_cnst_1xcostheta_tvalid),
        .s_axis_b_tdata       (s_cnst_3xtheta_dot_2xsintheta_add_cnst_1xcostheta_tdata),
        .m_axis_result_tvalid (m_graxsintheta_sub_cnst_3xtheta_dot_2xsintheta_add_cnst_1xcostheta_tvalid),
        .m_axis_result_tdata  (m_graxsintheta_sub_cnst_3xtheta_dot_2xsintheta_add_cnst_1xcostheta)
    );
    floating_multiply costheta_2_u (
        .aclk                 (i_clk),
        .s_axis_a_tvalid      (s_costheta_2_tvalid),
        .s_axis_a_tdata       (s_costheta_2_costheta),
        .s_axis_b_tvalid      (s_costheta_2_tvalid),
        .s_axis_b_tdata       (s_costheta_2_costheta),
        .m_axis_result_tvalid (m_costheta_2_tvalid),
        .m_axis_result_tdata  (m_costheta_2)
    );
    floating_multiply cnst_2xcostheta_2_u (
        .aclk                 (i_clk),
        .s_axis_a_tvalid      (s_cnst_2xcostheta_2_u_tvalid),
        .s_axis_a_tdata       (s_costheta_2),
        .s_axis_b_tvalid      (s_cnst_2xcostheta_2_u_tvalid),
        .s_axis_b_tdata       (CNST_2),
        .m_axis_result_tvalid (m_cnst_2xcostheta_2_tvalid),
        .m_axis_result_tdata  (m_cnst_2xcostheta_2)
    );
    floating_point_subtract cnst_2_sub_cnst_2xcostheta_2_u(
        .aclk                 (i_clk),
        .s_axis_a_tvalid      (s_cnst_2_sub_cnst_2xcostheta_2_tvalid),
        .s_axis_a_tdata       (CNST_3),
        .s_axis_b_tvalid      (s_cnst_2_sub_cnst_2xcostheta_2_tvalid),
        .s_axis_b_tdata       (s_cnst_2xcostheta_2),
        .m_axis_result_tvalid (m_cnst_2_sub_cnst_2xcostheta_2_tvalid),
        .m_axis_result_tdata  (m_cnst_2_sub_cnst_2xcostheta_2)
    );
    floating_divide thetaacc_u (
        .aclk                 (i_clk),
        .s_axis_a_tvalid      (s_thetaacc_tvalid),
        .s_axis_a_tdata       (s_graxsintheta_sub_cnst_3xtheta_dot_2xsintheta_add_cnst_1xcostheta),
        .s_axis_b_tvalid      (s_thetaacc_tvalid),
        .s_axis_b_tdata       (s_cnst_2_sub_cnst_2xcostheta_2),
        .m_axis_result_tvalid (m_thetaacc_tvalid),
        .m_axis_result_tdata  (m_thetaacc)
    );
    floating_multiply cnst_2xcostheta_u (
        .aclk                 (i_clk),
        .s_axis_a_tvalid      (s_cnst_2_tvalid),
        .s_axis_a_tdata       (CNST_2),
        .s_axis_b_tvalid      (s_cnst_2_tvalid),
        .s_axis_b_tdata       (costheta),
        .m_axis_result_tvalid (m_cnst_2xcostheta_tvalid),
        .m_axis_result_tdata  (m_cnst_2xcostheta)
    );
    floating_multiply cnst_2xcosthetaxthetaacc_u (
        .aclk                 (i_clk),
        .s_axis_a_tvalid      (s_cnst_2xcosthetaxthetaacc_tvalid),
        .s_axis_a_tdata       (s_cnst_2xcostheta),
        .s_axis_b_tvalid      (s_cnst_2xcosthetaxthetaacc_tvalid),
        .s_axis_b_tdata       (s_thetaacc),
        .m_axis_result_tvalid (m_cnst_2xcosthetaxthetaacc_tvalid),
        .m_axis_result_tdata  (m_cnst_2xcosthetaxthetaacc)
    );
    floating_point_subtract xacc_u(
        .aclk                 (i_clk),
        .s_axis_a_tvalid      (s_xacc_tvalid),
        .s_axis_a_tdata       (s_temp),
        .s_axis_b_tvalid      (s_xacc_tvalid),
        .s_axis_b_tdata       (s_cnst_2xcosthetaxthetaacc),
        .m_axis_result_tvalid (m_xacc_tvalid),
        .m_axis_result_tdata  (m_xacc)
    );
    floating_multiply TAUxthetaacc_u (
        .aclk                 (i_clk),
        .s_axis_a_tvalid      (s_TAUxthetaacc_tvalid),
        .s_axis_a_tdata       (TAU),
        .s_axis_b_tvalid      (s_TAUxthetaacc_tvalid),
        .s_axis_b_tdata       (thetaacc),
        .m_axis_result_tvalid (m_TAUxthetaacc_tvalid),
        .m_axis_result_tdata  (m_TAUxthetaacc)
    );
    floating_point_adder next_theta_dot_u (
        .aclk                 (i_clk),
        .s_axis_a_tvalid      (s_next_theta_dot_tvalid),
        .s_axis_a_tdata       (theta_dot),
        .s_axis_b_tvalid      (s_next_theta_dot_tvalid),
        .s_axis_b_tdata       (s_TAUxthetaacc),
        .m_axis_result_tvalid (m_next_theta_dot_tvalid),
        .m_axis_result_tdata  (m_next_theta_dot)
    );
    floating_multiply TAUxxacc_u (
        .aclk                 (i_clk),
        .s_axis_a_tvalid      (s_TAUxxacc_tvalid),
        .s_axis_a_tdata       (TAU),
        .s_axis_b_tvalid      (s_TAUxxacc_tvalid),
        .s_axis_b_tdata       (s_TAUxxacc_xacc),
        .m_axis_result_tvalid (m_TAUxxacc_tvalid),
        .m_axis_result_tdata  (m_TAUxxacc)
    );
    floating_point_adder next_x_dot_u (
        .aclk                 (i_clk),
        .s_axis_a_tvalid      (s_next_x_dot_tvalid),
        .s_axis_a_tdata       (x_dot),
        .s_axis_b_tvalid      (s_next_x_dot_tvalid),
        .s_axis_b_tdata       (s_TAUxxacc),
        .m_axis_result_tvalid (m_next_x_dot_tvalid),
        .m_axis_result_tdata  (m_next_x_dot)
    );
    floating_point_greater_than_or_equal next_x_greater_threshold_u (
        .aclk                 (i_clk),
        .s_axis_a_tvalid      (s_next_x_greater_threshold_tvalid),
        .s_axis_a_tdata       (s_next_x_greater_threshold_a),
        .s_axis_b_tvalid      (s_next_x_greater_threshold_tvalid),
        .s_axis_b_tdata       (s_next_x_greater_threshold_b),
        .m_axis_result_tvalid (m_next_x_greater_threshold_tvalid),
        .m_axis_result_tdata  (m_next_x_greater_threshold)
    );
    floating_point_greater_than_or_equal next_theta_greater_threshold_u (
        .aclk                 (i_clk),
        .s_axis_a_tvalid      (s_next_theta_greater_threshold_tvalid),
        .s_axis_a_tdata       (s_next_theta_greater_threshold_a),
        .s_axis_b_tvalid      (s_next_theta_greater_threshold_tvalid),
        .s_axis_b_tdata       (s_next_theta_greater_threshold_b),
        .m_axis_result_tvalid (m_next_theta_greater_threshold_tvalid),
        .m_axis_result_tdata  (m_next_theta_greater_threshold)
    );
    floating_point_less_than_or_equal next_x_less_threshold_u (
        .aclk                 (i_clk),
        .s_axis_a_tvalid      (s_next_x_less_threshold_tvalid),
        .s_axis_a_tdata       (s_next_x_less_threshold_a),
        .s_axis_b_tvalid      (s_next_x_less_threshold_tvalid),
        .s_axis_b_tdata       (s_next_x_less_threshold_b),
        .m_axis_result_tvalid (m_next_x_less_threshold_tvalid),
        .m_axis_result_tdata  (m_next_x_less_threshold)
    );
    floating_point_less_than_or_equal next_theta_less_threshold_u (
        .aclk                 (i_clk),
        .s_axis_a_tvalid      (s_next_theta_less_threshold_tvalid),
        .s_axis_a_tdata       (s_next_theta_less_threshold_a),
        .s_axis_b_tvalid      (s_next_theta_less_threshold_tvalid),
        .s_axis_b_tdata       (s_next_theta_less_threshold_b),
        .m_axis_result_tvalid (m_next_theta_less_threshold_tvalid),
        .m_axis_result_tdata  (m_next_theta_less_threshold)
    );


endmodule
