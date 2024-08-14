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

module MountainCar_Compute_Velocity_tb();

    localparam VEL_WL = 32, POS_WL = 32, ACT_WL = 2;

    reg clk, ena;

    reg  [VEL_WL-1:0] i_vel;
    reg  [POS_WL-1:0] i_pos;
    reg  [ACT_WL-1:0] i_act;
    wire              o_vel_valid;
    wire [VEL_WL-1:0] o_vel;

    always #5 clk = ~clk;
    initial begin
        clk = 1'b0; ena = 1'b0;
        #100  ena = 1'b1;
        #5500 ena = 1'b0;
    end
    initial begin
        #0;    // GT: o_vel = 0.0003311344813265
        i_vel = 32'h00000000; // 0.0000000000000000
        i_pos = 32'hbf116098; // -0.5678801681025067
        i_act = 2'd1;
        
        #1500; // GT: o_vel = 0.0006598071728023
        i_vel = 32'h39ad9c1e; // 0.0003311344813265
        i_pos = 32'hbf114ae5; // -0.5675490336211803
        i_act = 2'd1;        
        
        #1500; // GT: o_vel = 0.0019835736218983
        i_vel = 32'h3a2cf6e9; // 0.0006598071728023
        i_pos = 32'hbf111fa7; // -0.5668892264483780
        i_act = 2'd2;

        #1500; // GT: o_vel = 0.0032925829075064
        i_vel = 32'h3b01fed8; // 0.0019835736218983
        i_pos = 32'hbf109da8; // -0.5649056528264798
        i_act = 2'd2;
        
        #1500 $finish;
    end

    MountainCar_Compute_Velocity #(.VEL_WL(VEL_WL), .POS_WL(POS_WL), .ACT_WL(ACT_WL)) u_MountainCar_Compute_Velocity(
        .i_clk       ( clk ),
        .i_ena       ( ena ),
        .i_vel       ( i_vel[VEL_WL-1:0] ),
        .i_pos       ( i_pos[POS_WL-1:0] ),
        .i_act       ( i_act[ACT_WL-1:0] ),
        .o_vel_valid ( o_vel_valid ),
        .o_vel       ( o_vel[VEL_WL-1:0] )
    );
    

endmodule
