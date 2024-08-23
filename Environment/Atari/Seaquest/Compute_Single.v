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
//state_data:23*32=736(bit), action_data:3bit, obs_data:23*32=736(bit), reward_data:32bit
module Compute_Single #(parameter STA_WL = 736, ACT_WL = 3, OBS_WL = 736, RWD_WL = 32) (
    input wire i_clk,
    input wire i_rstn,
    input wire i_ena,
    input  wire [STA_WL-1:0] i_sta,
    input  wire [ACT_WL-1:0] i_act,
    output wire [STA_WL-1:0] o_sta,
    output wire [OBS_WL-1:0] o_obs, // observations
    output wire [RWD_WL-1:0] o_rwd,
    output wire              o_done,
    output reg               o_valid
    );

    // parameters
        localparam INPUT_BIT = 32;
        localparam OUTPUT_BIT = 32;
        localparam MAX_BULLETS = 5;
        localparam MAX_ENEMIES = 5;
        localparam MAX_DIVERS = 5;
        localparam MAX_ENEMY_BULLETS = 5;

        localparam SCREEN_WIDTH = 210;  // 屏幕宽度
        localparam SCREEN_HEIGHT = 160; // 屏幕高度
        localparam PLAYER_SIZE = 10;    // 玩家大小
        localparam ENEMY_SIZE = 10;     // 敌人大小
        localparam MAX_LIVES = 6;       // 最大生命值
        localparam PLAYER_SPEED = 1;    // 玩家速度
        localparam ENEMY_SPEED = 1;     // 敌人速度
        localparam DIVER_SPEED = 1;     // 潜水员速度
        localparam BULLET_SPEED = 1;    // 子弹速度
        localparam ENEMY_BULLET_SPEED = 1; // 敌人子弹速度
        localparam MAX_OXYGEN = 1000;   // 最大氧气量
        localparam RAND_THRESH = 8'h05;
        localparam IDLE = 0, COMPUTE_1 = 1, COMPUTE_2 = 2, COMPUTE_3 = 3, COMPUTE_4 = 4, COMPUTE_5 = 5, COMPUTE_6 = 6, COMPUTE_7 = 7;
        reg [2:0] next_state, state;
        reg [9:0] succeed_reward, shoot_reward, diver_reward;
        wire[9:0] one_shoot_reward;
        wire [31:0] temp_score;

    // split i_sta  
        wire [INPUT_BIT-1:0]                    i_player;
        wire [INPUT_BIT-1:0]                    i_bullets [MAX_BULLETS-1: 0];
        wire [INPUT_BIT-1:0]                    i_enemy [MAX_ENEMIES-1: 0];
        wire [INPUT_BIT-1:0]                    i_diver [MAX_DIVERS-1: 0];
        wire [INPUT_BIT-1:0]                    i_enemy_bullets [MAX_ENEMY_BULLETS-1: 0];
        wire [INPUT_BIT-1:0]                    i_psub;
        wire [INPUT_BIT-1:0]                    i_score;

        wire [INPUT_BIT*MAX_BULLETS-1:0]        i_bullets_flat;
        wire [INPUT_BIT*MAX_ENEMIES-1:0]        i_enemy_flat;
        wire [INPUT_BIT*MAX_DIVERS-1:0]         i_diver_flat;
        wire [INPUT_BIT*MAX_ENEMY_BULLETS-1:0]  i_enemy_bullets_flat;
        // for unflatten
            genvar g0;
            genvar g1;
            genvar g2;
            genvar g3;

            generate
                for (g0 = 0; g0 < MAX_BULLETS; g0 = g0 + 1) begin : i_unpack_bullets
                    assign i_bullets[g0] = i_bullets_flat[(g0+1)*INPUT_BIT-1:g0*INPUT_BIT];
                end
            endgenerate

            generate
                for (g1 = 0; g1 < MAX_ENEMIES; g1 = g1 + 1) begin : i_enemies
                    assign i_enemy[g1] = i_enemy_flat[(g1+1)*INPUT_BIT-1:g1*INPUT_BIT];
                end
            endgenerate

            generate
                for (g2 = 0; g2 < MAX_DIVERS; g2 = g2 + 1) begin : i_divers
                    assign i_diver[g2] = i_diver_flat[(g2+1)*INPUT_BIT-1:g2*INPUT_BIT];
                end
            endgenerate

            generate
                for (g3 = 0; g3 < MAX_ENEMY_BULLETS; g3 = g3 + 1) begin : i_unpack_enemy_bullets
                    assign i_enemy_bullets[g3] = i_enemy_bullets_flat[(g3+1)*INPUT_BIT-1:g3*INPUT_BIT];
                end
            endgenerate

        assign {i_player, i_bullets_flat , i_enemy_flat, i_diver_flat, i_enemy_bullets_flat, i_psub, i_score} = i_sta;

    // split o_sta, o_obs, o_rwd, o_done
        wire [OUTPUT_BIT-1:0]                    o_player;
        reg  [OUTPUT_BIT-1:0]                    o_bullets [MAX_BULLETS-1: 0];
        reg  [OUTPUT_BIT-1:0]                    o_enemies [MAX_ENEMIES-1: 0];
        reg  [OUTPUT_BIT-1:0]                    o_divers [MAX_DIVERS-1: 0];
        reg  [OUTPUT_BIT-1:0]                    o_enemy_bullets [MAX_ENEMY_BULLETS-1: 0];
        reg  [OUTPUT_BIT-1:0]                    o_psub;
        reg [OUTPUT_BIT-1:0]                     o_score;
        reg                                      o_terminated;  

        wire [OUTPUT_BIT*MAX_BULLETS-1:0]        o_bullets_flat;
        wire [OUTPUT_BIT*MAX_ENEMIES-1:0]        o_enemy_flat;
        wire [OUTPUT_BIT*MAX_DIVERS-1:0]         o_diver_flat;
        wire [OUTPUT_BIT*MAX_ENEMY_BULLETS-1:0]  o_enemy_bullets_flat;

        // for flatten
            genvar b0;
            genvar b1;
            genvar b2;
            genvar b3;

            generate
                for (b0 = 0; b0 < MAX_BULLETS; b0 = b0 + 1) begin : flatten_o_bullets
                    assign o_bullets_flat[(b0+1)*INPUT_BIT-1:b0*INPUT_BIT] = o_bullets[b0];
                end
            endgenerate

            generate
                for (b1 = 0; b1 < MAX_ENEMIES; b1 = b1 + 1) begin : flatten_o_enemies
                    assign o_enemy_flat[(b1+1)*INPUT_BIT-1:b1*INPUT_BIT] = o_enemies[b1];
                end
            endgenerate

            generate
                for (b2 = 0; b2 < MAX_DIVERS; b2 = b2 + 1) begin : flatten_o_divers
                    assign o_diver_flat[(b2+1)*INPUT_BIT-1:b2*INPUT_BIT] = o_divers[b2];
                end
            endgenerate

            generate
                for (b3 = 0; b3 < MAX_ENEMY_BULLETS; b3 = b3 + 1) begin : flatten_o_enemy_bullets
                    assign o_enemy_bullets_flat[(b3+1)*INPUT_BIT-1:b3*INPUT_BIT] = o_enemy_bullets[b3];
                end
            endgenerate

        assign o_sta = {o_player, o_bullets_flat , o_enemy_flat, o_diver_flat, o_enemy_bullets_flat, o_psub, o_score};
        assign o_obs = {o_player, o_bullets_flat , o_enemy_flat, o_diver_flat, o_enemy_bullets_flat, o_psub, o_score};
        // assign o_rwd = o_score;
        assign o_rwd = temp_score;
        assign o_done = o_terminated;


    
    
    
    // compute logic
    // i_player_info
        wire [7:0]   i_player_x     ;
        wire [7:0]   i_player_y     ;
        wire [9:0]   i_player_oxygen ;
        wire [2:0]   i_player_lives ;
        wire [2:0]   i_player_divc;
 
        assign i_player_x      = i_player[31:24];
        assign i_player_y      = i_player[23:16];
        assign i_player_oxygen  = i_player[15:6];
        assign i_player_lives  = i_player[5:3];
        assign i_player_divc = i_player[2:0];
    // o_player_info
        reg [7:0]   o_player_x      ;
        reg [7:0]   o_player_y      ;
        reg [9:0]   o_player_oxygen ;
        reg [2:0]   o_player_lives  ;
        reg [2:0]   o_player_divc   ;

        assign o_player = {o_player_x, o_player_y, o_player_oxygen, o_player_lives, o_player_divc};

    // priority
        wire [2:0] bullet_idx;
        wire       bullets_valid;

        wire [2:0] enemy_bullets_idx;
        wire       enemy_bullets_valid;

        wire [2:0] enemies_idx;
        wire       enemies_valid;

        wire [2:0] divers_idx;
        wire       divers_valid;
    
    // i_bullets_info
        wire [7:0]   i_bullets_x [MAX_BULLETS-1: 0];
        wire [7:0]   i_bullets_y [MAX_BULLETS-1: 0];
        wire [0:0]   i_bullets_dir [MAX_BULLETS-1: 0];
        wire [0:0]   i_bullets_active [MAX_BULLETS-1: 0];
        genvar c0;
        generate
            for (c0 = 0; c0 < MAX_BULLETS; c0 = c0 + 1) begin : i_bullets_info
                assign i_bullets_x[c0]      = i_bullets[c0][17:10];  // 提取 x 坐标
                assign i_bullets_y[c0]      = i_bullets[c0][9:2];    // 提取 y 坐标
                assign i_bullets_dir[c0]    = i_bullets[c0][1:1];    // 提取方向
                assign i_bullets_active[c0] = i_bullets[c0][0];      // 提取 active 状态
            end
        endgenerate

    // i_enemy_bullets_info
        wire [7:0]   i_enemy_bullets_x [MAX_ENEMY_BULLETS-1: 0];
        wire [7:0]   i_enemy_bullets_y [MAX_ENEMY_BULLETS-1: 0];
        wire [0:0]   i_enemy_bullets_dir [MAX_ENEMY_BULLETS-1: 0];
        wire [0:0]   i_enemy_bullets_active [MAX_ENEMY_BULLETS-1: 0];


        genvar c3;
        generate
            for (c3 = 0; c3 < MAX_ENEMY_BULLETS; c3 = c3 + 1) begin : i_enemy_bullets_info
                assign i_enemy_bullets_x[c3]      = i_enemy_bullets[c3][17:10];  // 提取 x 坐标
                assign i_enemy_bullets_y[c3]      = i_enemy_bullets[c3][9:2];    // 提取 y 坐标
                assign i_enemy_bullets_dir[c3]    = i_enemy_bullets[c3][1:1];    // 提取方向
                assign i_enemy_bullets_active[c3] = i_enemy_bullets[c3][0];      // 提取 active 状态
            end
        endgenerate

    // i_enemies_info
        wire [7:0]   i_enemies_x [MAX_ENEMIES-1: 0];
        wire [7:0]   i_enemies_y [MAX_ENEMIES-1: 0];
        wire [0:0]   i_enemies_dir [MAX_ENEMIES-1: 0];
        wire [0:0]   i_enemies_type [MAX_ENEMIES-1: 0];
        wire [0:0]   i_enemies_active [MAX_ENEMIES-1: 0];
        wire [3:0]   i_enemies_count [MAX_ENEMIES-1: 0];
        wire [0:0]   i_enemies_canfire [MAX_ENEMIES-1: 0];
        genvar c1;
        generate
            for (c1 = 0; c1 < MAX_ENEMIES; c1 = c1 + 1) begin : i_enemies_info
                assign i_enemies_x[c1]      = i_enemy[c1][18:11];  // 提取 x 坐标
                assign i_enemies_y[c1]      = i_enemy[c1][10:3];    // 提取 y 坐标
                assign i_enemies_dir[c1]    = i_enemy[c1][2:2];    // 提取方向
                assign i_enemies_type[c1]   = i_enemy[c1][1:1];    // 提取类型
                assign i_enemies_active[c1] = i_enemy[c1][0];      // 提取 active 状态
                assign i_enemies_count[c1]  = i_enemy[c1][22:19];  // 提取计数
                assign i_enemies_canfire[c1] = i_enemy[c1][23];    // 提取是否可以发射子弹
            end
        endgenerate

    // i_divers_info
        wire [7:0]   i_divers_x [MAX_DIVERS-1: 0];
        wire [7:0]   i_divers_y [MAX_DIVERS-1: 0];
        wire [0:0]   i_divers_dir [MAX_DIVERS-1: 0];
        wire [0:0]   i_divers_active [MAX_DIVERS-1: 0];
        genvar c2;
        generate
            for (c2 = 0; c2 < MAX_DIVERS; c2 = c2 + 1) begin : i_divers_info
                assign i_divers_x[c2]      = i_diver[c2][17:10];  // 提取 x 坐标
                assign i_divers_y[c2]      = i_diver[c2][9:2];    // 提取 y 坐标
                assign i_divers_dir[c2]    = i_diver[c2][1:1];    // 提取方向
                assign i_divers_active[c2] = i_diver[c2][0];      // 提取 active 状态
            end
        endgenerate

    // i_psub
        wire [7:0]   i_has_succeed;
        wire         i_has_surface;
        wire [7:0]   i_psub_x;
        wire [7:0]   i_psub_y;
        wire [0:0]   i_psub_dir;
        wire [0:0]   i_psub_active;

        assign i_has_succeed = i_psub[27:19];
        assign i_has_surface = i_psub[18:18];
        assign i_psub_x = i_psub[17:10];
        assign i_psub_y = i_psub[9:2];
        assign i_psub_dir = i_psub[1:1];
        assign i_psub_active = i_psub[0];



    // o_bullets_info
        reg [7:0]   o_bullets_x [MAX_BULLETS-1: 0];
        reg [7:0]   o_bullets_y [MAX_BULLETS-1: 0];
        reg [0:0]   o_bullets_dir [MAX_BULLETS-1: 0];
        reg [0:0]   o_bullets_active [MAX_BULLETS-1: 0];
        genvar d0;
        generate
            for (d0 = 0; d0 < MAX_BULLETS; d0 = d0 + 1) begin : o_bullets_info
                always @(*) begin
                        o_bullets[d0] <= {`ZERO(14), o_bullets_x[d0], o_bullets_y[d0], o_bullets_dir[d0], o_bullets_active[d0]};
                end
            end
        endgenerate
   
    // o_enemy_bullets_info
        reg [7:0]   o_enemy_bullets_x [MAX_ENEMY_BULLETS-1: 0];
        reg [7:0]   o_enemy_bullets_y [MAX_ENEMY_BULLETS-1: 0];
        reg [0:0]   o_enemy_bullets_dir [MAX_ENEMY_BULLETS-1: 0];
        reg [0:0]   o_enemy_bullets_active [MAX_ENEMY_BULLETS-1: 0];
        genvar d2;
        generate
            for (d2 = 0; d2 < MAX_ENEMY_BULLETS; d2 = d2 + 1) begin : o_enemy_bullets_info
                always @(*) begin
                        o_enemy_bullets[d2] <= {`ZERO(14), o_enemy_bullets_x[d2], o_enemy_bullets_y[d2], o_enemy_bullets_dir[d2], o_enemy_bullets_active[d2]};
                end
            end
        endgenerate
    // o_enemies_info
        reg [7:0]   o_enemies_x [MAX_ENEMIES-1: 0];
        reg [7:0]   o_enemies_y [MAX_ENEMIES-1: 0];
        reg [0:0]   o_enemies_dir [MAX_ENEMIES-1: 0];
        reg [0:0]   o_enemies_type [MAX_ENEMIES-1: 0];
        reg [0:0]   o_enemies_active [MAX_ENEMIES-1: 0];
        reg [3:0]   o_enemies_count [MAX_ENEMIES-1: 0];
        reg [0:0]   o_enemies_canfire [MAX_ENEMIES-1: 0];
        genvar d3;
        generate
            for (d3 = 0; d3 < MAX_ENEMIES; d3 = d3 + 1) begin : o_enemies_info
                always @(*) begin
                        o_enemies[d3] <= {`ZERO(8),  o_enemies_canfire[d3], o_enemies_count[d3], o_enemies_x[d3], o_enemies_y[d3], o_enemies_dir[d3], o_enemies_type[d3], o_enemies_active[d3]};
                end
            end
        endgenerate
    // o_divers_info
        reg [7:0]   o_divers_x [MAX_DIVERS-1: 0];
        reg [7:0]   o_divers_y [MAX_DIVERS-1: 0];
        reg [0:0]   o_divers_dir [MAX_DIVERS-1: 0];
        reg [0:0]   o_divers_active [MAX_DIVERS-1: 0];
        genvar d1;
        generate
            for (d1 = 0; d1 < MAX_DIVERS; d1 = d1 + 1) begin : o_divers_info
                always @(*) begin
                    o_divers[d1] <= {`ZERO(14), o_divers_x[d1], o_divers_y[d1], o_divers_dir[d1], o_divers_active[d1]};
                end
            end
        endgenerate
    // o_psub
        reg [7:0]   o_psub_x;
        reg [7:0]   o_psub_y;
        reg [0:0]   o_psub_dir;
        reg [0:0]   o_psub_active;
        reg [7:0]   o_has_succeed;
        reg         o_has_surface;
        always @(*) begin
            o_psub <= {`ZERO(5), o_has_succeed, o_has_surface, o_psub_x, o_psub_y, o_psub_dir, o_psub_active};
        end

    // score
        assign temp_score = (succeed_reward + shoot_reward + diver_reward);
        assign one_shoot_reward = (20 + 10 * i_has_succeed);

    // lfsr
        reg [31:0] lfsr;  // 伪随机数生成器 (LFSR)
        always @(posedge i_clk or negedge i_rstn) begin
            if (~i_rstn) begin
                lfsr <= 32'hABCD1234; 
            end else begin
                lfsr <= {lfsr[30:0], lfsr[31] ^ lfsr[6] ^ lfsr[4] ^ lfsr[1]};  // LFSR 更新
            end
        end
        wire rand_valid;
        wire enemy_type;
        wire [7:0] rand_x;  
        wire [7:0] rand_y; 
        wire [7:0] rand_x_diver;  
        wire [7:0] rand_y_diver;  
        wire rand_dir;
        wire rand_dir_diver;
        assign rand_valid = (lfsr[7:0] < RAND_THRESH);
        assign rand_x = lfsr[7:0] % SCREEN_WIDTH;  
        assign rand_y = lfsr[15:8] % SCREEN_HEIGHT;  
        assign rand_x_diver = lfsr[31:24] % SCREEN_WIDTH;
        assign rand_y_diver = lfsr[23:16] % SCREEN_HEIGHT;
        assign enemy_type = lfsr[0];
        assign rand_dir = lfsr[1];
        assign rand_dir_diver = lfsr[2];

    // compute logic
        reg[31:0] e0;//enemy
        reg[31:0] e1;//diver
        reg[31:0] e2;//enemy_bullet
        reg[31:0] e3;//bullet
        reg[31:0] e4;//enemy_bullet_add

    // state logic
        always @(posedge i_clk or negedge i_rstn) begin
            if (~i_rstn) begin
                state <= IDLE;
                o_player_x <= 0;
                o_player_y <= 0;
                o_has_succeed <= 0;
                o_terminated <= 0;
                succeed_reward <= 0;
                shoot_reward <= 0;
                diver_reward <= 0;
                o_psub <= 0;
                for (e0=0; e0 < MAX_ENEMIES; e0 = e0 + 1) begin
                    o_enemies[e0] <= 0;
                end
                for (e1=0; e1 < MAX_DIVERS; e1 = e1 + 1) begin
                    o_divers[e1] <= 0;
                end
                for (e2=0; e2 < MAX_ENEMY_BULLETS; e2 = e2 + 1) begin
                    o_enemy_bullets[e2] <= 0;
                end
                for (e3=0; e3 < MAX_BULLETS; e3 = e3 + 1) begin
                    o_bullets[e3] <= 0;
                end
            end else if (i_ena) begin
                case (state)
                    IDLE: begin
                        if (next_state != IDLE) begin
                            o_player_lives <= i_player_lives;
                            o_player_divc <= i_player_divc;
                            o_player_x <= i_player_x;
                            o_player_y <= i_player_y;
                            o_has_succeed <= i_has_succeed;
                            o_has_surface <= i_has_surface;
                            o_psub_x <= i_psub_x;
                            o_psub_y <= 10;
                            diver_reward <= 0;
                            shoot_reward <= 0;
                            o_psub_dir <= i_psub_dir;
                            o_psub_active <= i_psub;
                            for (e0=0; e0 < MAX_ENEMIES; e0 = e0 + 1) begin
                                o_enemies_x[e0] <= i_enemies_x[e0];
                                o_enemies_y[e0] <= i_enemies_y[e0];
                                o_enemies_dir[e0] <= i_enemies_dir[e0];
                                o_enemies_type[e0] <= i_enemies_type[e0];
                                o_enemies_active[e0] <= i_enemies_active[e0];
                                o_enemies_count[e0] <= i_enemies_count[e0];
                                o_enemies_canfire[e0] <= i_enemies_canfire[e0];
                            end
                            for (e1=0; e1 < MAX_DIVERS; e1 = e1 + 1) begin
                                o_divers_x[e1] <= i_divers_x[e1];
                                o_divers_y[e1] <= i_divers_y[e1];
                                o_divers_dir[e1] <= i_divers_dir[e1];
                                o_divers_active[e1] <= i_divers_active[e1];
                            end
                            for (e2=0; e2 < MAX_ENEMY_BULLETS; e2 = e2 + 1) begin
                                o_enemy_bullets_x[e2] <= i_enemy_bullets_x[e2];
                                o_enemy_bullets_y[e2] <= i_enemy_bullets_y[e2];
                                o_enemy_bullets_dir[e2] <= i_enemy_bullets_dir[e2];
                                o_enemy_bullets_active[e2] <= i_enemy_bullets_active[e2];
                            end
                            for (e3=0; e3 < MAX_BULLETS; e3 = e3 + 1) begin
                                o_bullets_x[e3] <= i_bullets_x[e3];
                                o_bullets_y[e3] <= i_bullets_y[e3];
                                o_bullets_dir[e3] <= i_bullets_dir[e3];
                                o_bullets_active[e3] <= i_bullets_active[e3];
                            end
                        end
                    end
                    COMPUTE_1: begin
                    // player_action(move_player or add bullets): 001: left, 010: right, 100: up, 011: down, 101: fire_left, 110: fire_right
                        case (i_act)
                            3'b001: begin
                                if (i_player_x > 0) begin
                                    o_player_x <= i_player_x - PLAYER_SPEED;
                                end
                            end
                            3'b010: begin
                                if ((i_player_x + PLAYER_SIZE) < SCREEN_WIDTH) begin
                                    o_player_x <= i_player_x + PLAYER_SPEED;
                                end
                            end
                            3'b100: begin
                                if (i_player_y > 0) begin
                                    o_player_y <= i_player_y - PLAYER_SPEED;
                                end
                            end
                            3'b011: begin
                                if ((i_player_y + PLAYER_SIZE) < SCREEN_HEIGHT) begin
                                    o_player_y <= i_player_y + PLAYER_SPEED;
                                end
                            end
                            3'b101: begin
                                if (bullets_valid) begin
                                    o_bullets[bullet_idx][17:10] <= (i_player_x - PLAYER_SPEED - BULLET_SPEED);
                                    o_bullets[bullet_idx][9:2] <= i_player_y;
                                    o_bullets[bullet_idx][1:1] <= 0;
                                    o_bullets[bullet_idx][0] <= 1;
                                end
                            end
                            3'b110: begin
                                if (bullets_valid) begin
                                    o_bullets[bullet_idx][17:10] <= (i_player_x + PLAYER_SPEED + BULLET_SPEED);
                                    o_bullets[bullet_idx][9:2] <= i_player_y;
                                    o_bullets[bullet_idx][1:1] <= 1;
                                    o_bullets[bullet_idx][0] <= 1;
                                end
                            end
                            default: begin
                            end
                        endcase
                    // move_enemy+remove_enemy
                        for (e0 = 0; e0 < MAX_ENEMIES; e0 = e0 + 1) begin
                            if (i_enemies_active[e0]) begin
                                if (i_enemies_dir[e0]) begin
                                    if (i_enemies_x[e0] > 0) begin
                                        o_enemies_x[e0] <= i_enemies_x[e0] - ENEMY_SPEED;
                                    end else begin
                                        o_enemies_active[e0] <= 0;
                                    end
                                end else begin
                                    if (i_enemies_x[e0] < SCREEN_WIDTH) begin
                                        o_enemies_x[e0] <= i_enemies_x[e0] + ENEMY_SPEED;
                                    end else begin
                                        o_enemies_active[e0] <= 0;
                                    end
                                end
                            end
                        end

                    // move_diver+remove_diver
                        for (e1 = 0; e1 < MAX_DIVERS; e1 = e1 + 1) begin
                            if (i_divers_active[e1]) begin
                                if (i_divers_dir[e1]) begin
                                    if (i_divers_x[e1] > 0) begin
                                        o_divers_x[e1] <= i_divers_x[e1] - DIVER_SPEED;
                                    end
                                    else begin
                                        o_divers_active[e1] <= 0;
                                    end
                                end else begin
                                    if (i_divers_x[e1] < SCREEN_WIDTH) begin
                                        o_divers_x[e1] <= i_divers_x[e1] + DIVER_SPEED;
                                    end
                                    else begin
                                        o_divers_active[e1] <= 0;
                                    end
                                end
                            end
                        end
                    // move_enemy_bullet+remove_enemy_bullet
                        for (e2 = 0; e2 < MAX_ENEMY_BULLETS; e2 = e2 + 1) begin
                            if (i_enemy_bullets_active[e2]) begin
                                if (i_enemy_bullets_dir[e2]) begin
                                    if (i_enemy_bullets_x[e2] > 0) begin
                                        o_enemy_bullets_x[e2] <= i_enemy_bullets_x[e2] - ENEMY_BULLET_SPEED;
                                    end
                                    else begin
                                        o_enemy_bullets_active[e2] <= 0;
                                    end
                                end else begin
                                    if (i_enemy_bullets_x[e2] < SCREEN_WIDTH) begin
                                        o_enemy_bullets_x[e2] <= i_enemy_bullets_x[e2] + ENEMY_BULLET_SPEED;
                                    end
                                    else begin
                                        o_enemy_bullets_active[e2] <= 0;
                                    end
                                end
                            end
                        end
                    // move_bullet+remove_bullet
                        for (e3 = 0; e3 < MAX_BULLETS; e3 = e3 + 1) begin
                            if (i_bullets_active[e3]) begin
                                if (i_bullets_dir[e3]) begin
                                    if (i_bullets_x[e3] > 0) begin
                                        o_bullets_x[e3] <= i_bullets_x[e3] - BULLET_SPEED;
                                    end else begin
                                        o_bullets_active[e3] <= 0;
                                    end
                                end else begin
                                    if (i_bullets_x[e3] < SCREEN_WIDTH) begin
                                        o_bullets_x[e3] <= i_bullets_x[e3] + BULLET_SPEED;
                                    end else begin
                                        o_bullets_active[e3] <= 0;
                                    end
                                end
                            end
                        end
                    // move_psub+remove_psub
                        if (i_psub_active) begin
                            if (i_psub_dir) begin
                                if (i_psub_x > 0) begin
                                    o_psub_x <= i_psub_x - ENEMY_SPEED;
                                end else begin
                                    o_psub_active <= 0;
                                end
                            end else begin
                                if (i_psub_x < SCREEN_WIDTH) begin
                                    o_psub_x <= i_psub_x + ENEMY_SPEED;
                                end else begin
                                    o_psub_active <= 0;
                                end
                            end
                        end

                    // enemies_can_fire + enemies_count
                        for (e4 = 0; e4 < MAX_ENEMIES; e4 = e4 + 1) begin
                            if (i_enemies_type[e4] && i_enemies_active[e4]) begin
                                if(i_enemies_count[e4] == 15) begin
                                    o_enemies_canfire[e4] <= 1;
                                end else begin 
                                    o_enemies_count[e4] <= i_enemies_count[e4] + 1;
                                end
                            end
                        end
                end

                    COMPUTE_2:begin    
                    // add enemy_bullets
                        for (e4 = 0; e4 < MAX_ENEMIES; e4 = e4 + 1) begin
                            if (enemy_bullets_valid && i_enemies_type[e4] && i_enemies_active[e4] && i_enemies_canfire[e4]) begin
                                if (i_enemies_dir[e4]) begin
                                    o_enemy_bullets_x[enemy_bullets_idx] <= (i_enemies_x[e4] - ENEMY_BULLET_SPEED - ENEMY_SPEED);
                                end else begin
                                    o_enemy_bullets_x[enemy_bullets_idx] <= (i_enemies_x[e4] + ENEMY_BULLET_SPEED + ENEMY_SPEED);             
                                end
                                o_enemy_bullets_y[enemy_bullets_idx] <= i_enemies_y[e4];
                                o_enemy_bullets_dir[enemy_bullets_idx] <= i_enemies_dir[e4];
                                o_enemy_bullets_active[enemy_bullets_idx] <= 1;
                                o_enemies_count[e4] <= 0;
                            end
                        end
                    // add_enemy
                        if ((enemies_valid) && (rand_valid)) begin
                            if (rand_dir) begin
                                o_enemies_x[enemies_idx] <= SCREEN_WIDTH - ENEMY_SIZE;
                            end else begin
                                o_enemies_x[enemies_idx] <= ENEMY_SIZE;
                            end
                            o_enemies_y[enemies_idx] <= rand_y;
                            o_enemies_dir[enemies_idx] <= rand_dir;
                            o_enemies_active[enemies_idx] <= 1;
                            o_enemies_type[enemies_idx] <= enemy_type;  // 1 表示潜艇                            
                        end
                    // add_diver
                        if (divers_valid) begin
                            o_divers_x[divers_idx] <= rand_x_diver;
                            o_divers_y[divers_idx] <= rand_y_diver;
                            o_divers_dir[divers_idx] <= rand_dir_diver;
                            o_divers_active[divers_idx] <= 1;                            
                        end
                    // surface_check(oxygen, lives, current_diverse, has_surface_succeed, diver_reward, has_surface)
                        if (o_player_y < 10) begin
                            o_has_surface <= 1;
                            if (i_has_surface) begin
                                o_player_oxygen <= MAX_OXYGEN;
                            end else begin
                                o_player_oxygen <= MAX_OXYGEN;
                                if (i_player_divc == 6) begin
                                    o_player_divc <= 0;
                                    o_has_succeed <= i_has_succeed + 1;
                                    succeed_reward <= 50 + i_has_succeed * 50;
                                end else if ((i_player_divc == 0)&&(i_player_lives == 1)) begin
                                    o_player_lives <= 0;
                                    o_terminated <= 1;
                                end else if ((i_player_divc == 0)&&(i_player_lives > 1))begin
                                    o_player_lives <= o_player_lives - 1;
                                end else if ((i_player_divc > 0) && (i_player_divc < 6)) begin
                                    o_player_divc <= i_player_divc - 1;
                                end
                            end
                        end else begin
                            if (i_player_oxygen > 1) begin
                                o_player_oxygen <= i_player_oxygen - 1;
                            end else begin
                                if (o_player_lives > 1) begin
                                    o_player_lives <= o_player_lives - 1;
                                    o_player_oxygen<= MAX_OXYGEN;
                                end else begin
                                    o_player_lives <= 0;
                                    o_terminated <= 1;  
                                end    
                            end
                            o_has_surface <= 0;
                        end
                    end
                    COMPUTE_3:begin
                    // add_psub
                        if ((o_has_succeed[0] == 1'b0)&&(i_psub_active==0)) begin //(对2取余为0)
                            o_psub_y <= 10;
                            o_psub_dir <= lfsr[1];
                            if (lfsr[1]) begin
                                o_psub_x <= SCREEN_WIDTH - PLAYER_SIZE;
                            end else 
                                o_psub_x <= PLAYER_SIZE;
                            o_psub_active <= 1;
                        end
                    // change enemy(by compare with bullets),change score
                        for (e0 = 0; e0 < MAX_ENEMIES; e0 = e0 + 1) begin
                            if (o_enemies_active[e0]) begin
                                for (e3 = 0; e3 < MAX_BULLETS; e3 = e3 + 1) begin
                                    if (o_bullets_active[e3]) begin
                                        if ((o_bullets_x[e3] > o_enemies_x[e0]) && (o_bullets_x[e3] < o_enemies_x[e0] + ENEMY_SIZE) && (o_bullets_y[e3] > o_enemies_y[e0]) && (o_bullets_y[e3] < o_enemies_y[e0] + ENEMY_SIZE)) begin
                                            o_enemies_active[e0] <= 0;
                                            shoot_reward <= shoot_reward + one_shoot_reward;
                                            o_bullets_active[e3] <= 0;
                                        end
                                    end
                                end
                            end
                        end
                    // change diver and player(by compare with player),change_score
                        for (e1 = 0; e1 < MAX_DIVERS; e1 = e1 + 1) begin
                            if (o_divers_active[e1]) begin
                                if ((o_divers_x[e1] >= o_player_x) && (o_divers_x[e1] < o_player_x + PLAYER_SIZE) && (o_divers_y[e1] >= o_player_y) && (o_divers_y[e1] < o_player_y + PLAYER_SIZE)) begin
                                    o_divers_active[e1] <= 0;
                                    if (i_player_divc < 6) begin
                                        o_player_divc <= i_player_divc + 1;
                                    end
                                    diver_reward <= diver_reward + 50;
                                end
                            end
                        end
                    
                    end
                    COMPUTE_4:begin
                    // change player(by compare with psub+enemy_bullet+enemy)
                        if (o_psub_active) begin
                            if ((o_psub_x >= o_player_x) && (o_psub_x < o_player_x + PLAYER_SIZE) && (o_psub_y >= o_player_y) && (o_psub_y < o_player_y + PLAYER_SIZE)) begin
                                o_psub_active <= 0;
                                if (o_player_lives > 1) begin
                                    o_player_lives <= o_player_lives - 1;
                                end else begin
                                    o_player_lives <= 0;
                                    o_terminated <= 1;                            
                                end
                            end
                        end
                    end
                    
                    COMPUTE_5:begin
                    // change player(by compare with enemy_bullet)
                        for (e2 = 0; e2 < MAX_ENEMY_BULLETS; e2 = e2 + 1) begin
                            if (o_enemy_bullets_active[e2]) begin
                                if ((o_enemy_bullets_x[e2] > o_player_x) && (o_enemy_bullets_x[e2] < o_player_x + PLAYER_SIZE) && (o_enemy_bullets_y[e2] > o_player_y) && (o_enemy_bullets_y[e2] < o_player_y + PLAYER_SIZE)) begin
                                    o_enemy_bullets_active[e2] <= 0;
                                    if (o_player_lives > 1) begin
                                        o_player_lives <= o_player_lives - 1;
                                    end else begin
                                        o_player_lives <= 0;
                                        o_terminated <= 1;
                                    end
                                end
                            end
                        end
                    end

                    COMPUTE_6:begin
                    // change player(by compare with enemy) (lives)
                        o_score <= (i_score + succeed_reward + shoot_reward + diver_reward);
                        for (e0 = 0; e0 < MAX_ENEMIES; e0 = e0 + 1) begin
                            if (o_enemies_active[e0]) begin
                                if ((o_enemies_x[e0] > o_player_x) && (o_enemies_x[e0] < o_player_x + PLAYER_SIZE) && (o_enemies_y[e0] > o_player_y) && (o_enemies_y[e0] < o_player_y + PLAYER_SIZE)) begin
                                    o_enemies_active[e2] <= 0;
                                    if (o_player_lives > 1) begin
                                        o_player_lives <= o_player_lives - 1;
                                    end else begin
                                        o_player_lives <= 0;
                                        o_terminated <= 1;                            
                                    end
                                end
                            end
                        end
                    end
                    // add_lives
                    COMPUTE_7:begin
                        if ((o_score % 10000) & (temp_score))begin
                            if (o_player_lives < 6) begin
                                o_player_lives <= o_player_lives + 1;
                            end
                        end
                        o_valid <= 1;
                    end
                endcase
            end
        end


    // FSM
    always @(posedge i_clk or negedge i_rstn) begin
        if (~i_rstn) begin
            state <= IDLE;
        end else if (i_ena) begin
            state <= next_state;
        end
    end

    always @(*) begin
        case (state)
            IDLE:            next_state = (i_ena ? COMPUTE_1 : IDLE);
            COMPUTE_1:       next_state = COMPUTE_2 ;
            COMPUTE_2:       next_state = COMPUTE_3 ;
            COMPUTE_3:       next_state = COMPUTE_4 ;
            COMPUTE_4:       next_state = COMPUTE_5 ;
            COMPUTE_5:       next_state = COMPUTE_6 ;
            COMPUTE_6:       next_state = COMPUTE_7 ;
            COMPUTE_7:       next_state = IDLE;
            default:         next_state = IDLE;
        endcase
    end


    My_Priority_Encoder # (
        .IN_WIDTH(5),
        .OUT_WIDTH(3),
        .HIGH_FIRST(0),
        .ACTIVE(0)
      )
      u_bullets (
        .in({i_bullets_active[0], i_bullets_active[1], i_bullets_active[2], i_bullets_active[3], i_bullets_active[4]}),
        .out(bullet_idx),
        .out_valid(bullets_valid)
      );

      My_Priority_Encoder # (
        .IN_WIDTH(5),
        .OUT_WIDTH(3),
        .HIGH_FIRST(0),
        .ACTIVE(0)
      )
      u_enemy_bullets (
        .in({o_enemy_bullets_active[0], o_enemy_bullets_active[1], o_enemy_bullets_active[2], o_enemy_bullets_active[3], o_enemy_bullets_active[4]}),
        .out(enemy_bullets_idx),
        .out_valid(enemy_bullets_valid)
      );

      My_Priority_Encoder # (
        .IN_WIDTH(5),
        .OUT_WIDTH(3),
        .HIGH_FIRST(0),
        .ACTIVE(0)
      )
      u_enemies (
        .in({i_enemies_active[0], i_enemies_active[1], i_enemies_active[2], i_enemies_active[3], i_enemies_active[4]}),
        .out(enemies_idx),
        .out_valid(enemies_valid)
      );

      My_Priority_Encoder # (
        .IN_WIDTH(5),
        .OUT_WIDTH(3),
        .HIGH_FIRST(0),
        .ACTIVE(0)
      )
      u_divers (
        .in({i_divers_active[0], i_divers_active[1], i_divers_active[2], i_divers_active[3], i_divers_active[4]}),
        .out(divers_idx),
        .out_valid(divers_valid)
      );
endmodule