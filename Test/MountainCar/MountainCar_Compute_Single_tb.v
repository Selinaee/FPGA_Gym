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

module MountainCar_Compute_Single_tb();

    localparam VEL_WL = 32, POS_WL = 32, ACT_WL = 2, RWD_WL = 1;

    reg clk, ena;

    reg  [VEL_WL-1:0] i_vel;
    reg  [POS_WL-1:0] i_pos;
    reg  [ACT_WL-1:0] i_act;
    wire [POS_WL-1:0] o_pos;
    wire [VEL_WL-1:0] o_vel;
    wire [RWD_WL-1:0] o_rwd;
    wire              o_done;
    wire              o_valid;

    always #5 clk = ~clk;
    initial begin
        clk = 1'b0; ena = 1'b0;
        #100  ena = 1'b1;
    end
    initial begin
        #0;    // GT: [pos, vel, rwd, done] = [-0.4733587993222302, 0.0006292920039598, -1.0, False]; o_vel (before zero) = 0.0006292920039598 
        i_vel = 32'h00000000; // 0.0000000000000000
        i_pos = 32'hbef2ae91; // -0.4739880913261900
        i_act = 2'd2;
        
        #1500; // GT: [pos, vel, rwd, done] = [-0.4721048821644926, 0.0012539171577376, -1.0, False]; o_vel (before zero) = 0.0012539171577376 
        i_vel = 32'h3a24f712; // 0.0006292920039598
        i_pos = 32'hbef25c16; // -0.4733587993222302
        i_act = 2'd2;
        
        #1500; // GT: [pos, vel, rwd, done] = [-0.4702356349385993, 0.0018692472258932, -1.0, False]; o_vel (before zero) = 0.0018692472258932 
        i_vel = 32'h3aa45a7a; // 0.0012539171577376
        i_pos = 32'hbef1b7bb; // -0.4721048821644926
        i_act = 2'd2;
        
        #1500; // GT: [pos, vel, rwd, done] = [-0.4687649039271927, 0.0014707310114066, -1.0, False]; o_vel (before zero) = 0.0014707310114066 
        i_vel = 32'h3af50187; // 0.0018692472258932
        i_pos = 32'hbef0c2ba; // -0.4702356349385993
        i_act = 2'd1;
        
        #1500; // GT: [pos, vel, rwd, done] = [-0.4667035746520681, 0.0020613292751246, -1.0, False]; o_vel (before zero) = 0.0020613292751246 
        i_vel = 32'h3ac0c58b; // 0.0014707310114066
        i_pos = 32'hbef001f4; // -0.4687649039271927
        i_act = 2'd2;
        
        #1500; // GT: [pos, vel, rwd, done] = [-0.4640668904493582, 0.0026366842027100, -1.0, False]; o_vel (before zero) = 0.0026366842027100 
        i_vel = 32'h3b07175e; // 0.0020613292751246
        i_pos = 32'hbeeef3c5; // -0.4667035746520681
        i_act = 2'd2;
        
        #1500; // GT: [pos, vel, rwd, done] = [-0.4628743256011714, 0.0011925648481868, -1.0, False]; o_vel (before zero) = 0.0011925648481868 
        i_vel = 32'h3b2ccc38; // 0.0026366842027100
        i_pos = 32'hbeed9a2d; // -0.4640668904493582
        i_act = 2'd0;
        
        #1500; // GT: [pos, vel, rwd, done] = [-0.4621346792169977, 0.0007396463841736, -1.0, False]; o_vel (before zero) = 0.0007396463841736 
        i_vel = 32'h3a9c4fd6; // 0.0011925648481868
        i_pos = 32'hbeecfddd; // -0.4628743256011714
        i_act = 2'd1;
        
        #1500; // GT: [pos, vel, rwd, done] = [-0.4618534057292430, 0.0002812734877547, -1.0, False]; o_vel (before zero) = 0.0002812734877547 
        i_vel = 32'h3a41e4d4; // 0.0007396463841736
        i_pos = 32'hbeec9ceb; // -0.4621346792169977
        i_act = 2'd1;
        
        #1500; // GT: [pos, vel, rwd, done] = [-0.4610325787642148, 0.0008208269650282, -1.0, False]; o_vel (before zero) = 0.0008208269650282 
        i_vel = 32'h399377e3; // 0.0002812734877547
        i_pos = 32'hbeec780d; // -0.4618534057292430
        i_act = 2'd2;
        
        #500 ena = 1'b0;
        #1000 $finish;
    end

    MountainCar_Compute_Single #(.VEL_WL(VEL_WL), .POS_WL(POS_WL), .ACT_WL(ACT_WL)) u_MountainCar_Compute_Single(
        .i_clk       ( clk ),
        .i_ena       ( ena ),
        .i_vel       ( i_vel[VEL_WL-1:0] ),
        .i_pos       ( i_pos[POS_WL-1:0] ),
        .i_act       ( i_act[ACT_WL-1:0] ),
        .o_pos       ( o_pos[POS_WL-1:0] ),
        .o_vel       ( o_vel[VEL_WL-1:0] ),
        .o_rwd       ( o_rwd[RWD_WL-1:0] ),
        .o_done      ( o_done ),
        .o_valid     ( o_valid )
    );

endmodule
