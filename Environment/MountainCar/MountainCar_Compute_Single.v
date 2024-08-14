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

module MountainCar_Compute_Single #(parameter VEL_WL = 32, POS_WL = 32, ACT_WL = 2, RWD_WL = 1) (
    input wire i_clk,
    input wire i_ena,

    input wire [VEL_WL-1:0] i_vel,
    input wire [POS_WL-1:0] i_pos,
    input wire [ACT_WL-1:0] i_act,

    output wire [POS_WL-1:0] o_pos,
    output wire [VEL_WL-1:0] o_vel,
    output wire [RWD_WL-1:0] o_rwd,
    output wire              o_done,

    output wire o_valid
    );

    localparam MIN_POS  = 32'hbf99999a; // -1.2
    localparam GOAL_POS = 32'h3f000000; //  0.5
    localparam GOAL_VEL = 32'h00000000; //  0

    // intermidiate signals
        wire [POS_WL-1:0] pos;
        wire [VEL_WL-1:0] vel;

    // u_MountainCar_Compute_Velocity ports
        wire              v_i_ena;
        wire [VEL_WL-1:0] v_i_vel;
        wire [POS_WL-1:0] v_i_pos;
        wire [ACT_WL-1:0] v_i_act;
        wire              v_o_vel_valid;
        wire [VEL_WL-1:0] v_o_vel;
    // u_MountainCar_Compute_Position ports
        wire              p_i_ena;
        wire [VEL_WL-1:0] p_i_vel;
        wire [POS_WL-1:0] p_i_pos;
        wire              p_o_pos_valid;
        wire [POS_WL-1:0] p_o_pos;
    // u_Goal_Pos ports
        wire              lp_i_a_valid;
        wire [POS_WL-1:0] lp_i_a;
        wire              lp_i_b_valid;
        wire [POS_WL-1:0] lp_i_b;
        wire              lp_o_result_valid;
        wire [7:0]        lp_o_result;
    // u_Goal_Vel ports
        wire              lv_i_a_valid;
        wire [VEL_WL-1:0] lv_i_a;
        wire              lv_i_b_valid;
        wire [VEL_WL-1:0] lv_i_b;
        wire              lv_o_result_valid;
        wire [7:0]        lv_o_result;

    // set intermidiate signals
        assign pos = p_o_pos;
        assign vel = (pos == MIN_POS & v_o_vel[ACT_WL-1]) ? `ZERO(VEL_WL) : v_o_vel;

    // connect ports
        // MountainCar_Compute_Single outputs
            assign o_pos   = pos;
            assign o_vel   = vel;
            assign o_rwd   = 1'b1;
            assign o_done  = ~|lp_o_result & ~|lv_o_result;
            assign o_valid = lp_o_result_valid & lv_o_result_valid;
        // u_MountainCar_Compute_Velocity inputs
            assign v_i_ena = i_ena;
            assign v_i_vel = i_vel;
            assign v_i_pos = i_pos;
            assign v_i_act = i_act;
        // u_MountainCar_Compute_Position inputs
            assign p_i_ena = v_o_vel_valid;
            assign p_i_vel = v_o_vel;
            assign p_i_pos = i_pos;
        // u_Goal_Pos inputs
            assign lp_i_a_valid = p_o_pos_valid;
            assign lp_i_a       = pos;
            assign lp_i_b_valid = i_ena;
            assign lp_i_b       = GOAL_POS;
        // u_Goal_Vel inputs
            assign lv_i_a_valid = v_o_vel_valid;
            assign lv_i_a       = vel;
            assign lv_i_b_valid = i_ena;
            assign lv_i_b       = GOAL_VEL;

    MountainCar_Compute_Velocity u_MountainCar_Compute_Velocity(
        .i_clk       ( i_clk ),
        .i_ena       ( v_i_ena ),
        .i_vel       ( v_i_vel[VEL_WL-1:0] ),
        .i_pos       ( v_i_pos[POS_WL-1:0] ),
        .i_act       ( v_i_act[ACT_WL-1:0] ),
        .o_vel_valid ( v_o_vel_valid ),
        .o_vel       ( v_o_vel[VEL_WL-1:0] )
    );
    MountainCar_Compute_Position u_MountainCar_Compute_Position(
        .i_clk       ( i_clk ),
        .i_ena       ( p_i_ena ),
        .i_vel       ( p_i_vel[VEL_WL-1:0] ),
        .i_pos       ( p_i_pos[POS_WL-1:0] ),
        .o_pos_valid ( p_o_pos_valid ),
        .o_pos       ( p_o_pos[POS_WL-1:0] )
    );
    Comparator_Less u_Goal_Pos ( // pos < GOAL_POS
        .aclk                 ( i_clk ),              // input  wire          aclk
        .s_axis_a_tvalid      ( lp_i_a_valid ),       // input  wire          s_axis_a_tvalid
        .s_axis_a_tdata       ( lp_i_a[POS_WL-1:0] ), // input  wire [31 : 0] s_axis_a_tdata
        .s_axis_b_tvalid      ( lp_i_b_valid ),       // input  wire          s_axis_b_tvalid
        .s_axis_b_tdata       ( lp_i_b[POS_WL-1:0] ), // input  wire [31 : 0] s_axis_b_tdata
        .m_axis_result_tvalid ( lp_o_result_valid ),  // output wire          m_axis_result_tvalid
        .m_axis_result_tdata  ( lp_o_result[7:0] )    // output wire [7 : 0]  m_axis_result_tdata
    );
    Comparator_Less u_Goal_Vel ( // vel < GOAL_VEL
        .aclk                 ( i_clk ),              // input  wire          aclk
        .s_axis_a_tvalid      ( lv_i_a_valid ),       // input  wire          s_axis_a_tvalid
        .s_axis_a_tdata       ( lv_i_a[VEL_WL-1:0] ), // input  wire [31 : 0] s_axis_a_tdata
        .s_axis_b_tvalid      ( lv_i_b_valid ),       // input  wire          s_axis_b_tvalid
        .s_axis_b_tdata       ( lv_i_b[VEL_WL-1:0] ), // input  wire [31 : 0] s_axis_b_tdata
        .m_axis_result_tvalid ( lv_o_result_valid ),  // output wire          m_axis_result_tvalid
        .m_axis_result_tdata  ( lv_o_result[7:0] )    // output wire [7 : 0]  m_axis_result_tdata
    );

endmodule
