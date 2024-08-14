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


module Compute_Single_tb();

    localparam STA_WL = 160, OBS_WL = 32;

    localparam CARD_WL = 4;
    localparam PLAYER_MAX_CARD_NUM = 21;
    localparam DEALER_MAX_CARD_NUM = 17;
    localparam MAX_CARD_VAL = 10;
    localparam MAX_SUM = 31;
    localparam ACT_WL = 1;
    localparam RWD_WL = 2;
    localparam HIT = 1'b1, STICK = 1'b0;

    reg clk;
    reg rstn;
    reg ena;
    always #5 clk = ~clk;
    initial begin
        clk = 1'b0;
        rstn = 1'b1;
        ena = 1'b0;

        #10 rstn = 1'b0;
        #10 rstn = 1'b1;
        #10 ena  = 1'b1;
    end

    reg  [PLAYER_MAX_CARD_NUM*CARD_WL-1:0] bj_i_player_cards;
    reg  [DEALER_MAX_CARD_NUM*CARD_WL-1:0] bj_i_dealer_cards;
    reg  [ACT_WL-1:0]                      bj_i_act;
    wire [PLAYER_MAX_CARD_NUM*CARD_WL-1:0] bj_o_player_cards;
    wire [DEALER_MAX_CARD_NUM*CARD_WL-1:0] bj_o_dealer_cards;
    wire [$clog2(MAX_SUM)-1:0]             bj_o_player_sum_hand;
    wire [CARD_WL-1:0]                     bj_o_dealer_card0; // the dealer's showing card
    wire                                   bj_o_usable_ace;
    wire [RWD_WL-1:0]                      bj_o_rwd;
    wire                                   bj_o_done;
    wire                                   bj_o_valid;
    wire [STA_WL-DEALER_MAX_CARD_NUM*CARD_WL-PLAYER_MAX_CARD_NUM*CARD_WL-1:0] NC1;
    wire [OBS_WL-$clog2(MAX_SUM)-CARD_WL-1:0] NC2;

    initial begin
        #20;
        bj_i_player_cards = {4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0,
                             4'd0, 4'd0, 4'd0, 4'd0, 4'd6, 4'd5, 4'd4, 4'd3, 4'd2, 4'd1};
        bj_i_dealer_cards = {4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0,
                             4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0};
        bj_i_act = HIT;

        #10;
        bj_i_player_cards = {4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0,
                             4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd5, 4'd4, 4'd3, 4'd2, 4'd1};
        bj_i_dealer_cards = {4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0,
                             4'd0, 4'd0, 4'd0, 4'd0, 4'd4, 4'd3, 4'd2, 4'd1};
        bj_i_act = HIT;

        #10;
        bj_i_player_cards = {4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0,
                             4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd4, 4'd3, 4'd2, 4'd1};
        bj_i_dealer_cards = {4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0,
                             4'd0, 4'd0, 4'd0, 4'd0, 4'd4, 4'd3, 4'd2, 4'd1};
        bj_i_act = HIT;

        #10;
        bj_i_player_cards = {4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0,
                             4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd4, 4'd3, 4'd2, 4'd1};
        bj_i_dealer_cards = {4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0,
                             4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd3, 4'd2, 4'd1};
        bj_i_act = HIT;

        #10;
        bj_i_player_cards = {4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0,
                             4'd0, 4'd0, 4'd0, 4'd0, 4'd6, 4'd5, 4'd4, 4'd3, 4'd2, 4'd1};
        bj_i_dealer_cards = {4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0,
                             4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd3, 4'd1, 4'd1};
        bj_i_act = STICK;

        #30;
        bj_i_player_cards = {4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0,
                             4'd0, 4'd0, 4'd0, 4'd0, 4'd6, 4'd5, 4'd4, 4'd3, 4'd2, 4'd1};
        bj_i_dealer_cards = {4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0,
                             4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd2};
        bj_i_act = STICK;
        #100 $finish;
    end

    Compute_Single u_Compute_Single(
    	.i_clk   ( clk ),
        .i_rstn  ( rstn ),
        .i_ena   ( ena ),
        .i_sta   ( {`ZERO(STA_WL-DEALER_MAX_CARD_NUM*CARD_WL-PLAYER_MAX_CARD_NUM*CARD_WL),
                    bj_i_dealer_cards[DEALER_MAX_CARD_NUM*CARD_WL-1:0],
                    bj_i_player_cards[PLAYER_MAX_CARD_NUM*CARD_WL-1:0]} ),
        .i_act   ( bj_i_act[ACT_WL-1:0] ),
        .o_sta   ( {NC1[STA_WL-DEALER_MAX_CARD_NUM*CARD_WL-PLAYER_MAX_CARD_NUM*CARD_WL-1:0],
                    bj_o_dealer_cards[DEALER_MAX_CARD_NUM*CARD_WL-1:0],
                    bj_o_player_cards[PLAYER_MAX_CARD_NUM*CARD_WL-1:0]} ),
        .o_obs   ( {NC2[OBS_WL-$clog2(MAX_SUM)-CARD_WL-1:0],
                    bj_o_player_sum_hand[$clog2(MAX_SUM)-1:0],
                    bj_o_dealer_card0[CARD_WL-1:0],
                    bj_o_usable_ace} ),
        .o_rwd   ( bj_o_rwd[RWD_WL-1:0] ),
        .o_done  ( bj_o_done ),
        .o_valid ( bj_o_valid )
    );

endmodule
