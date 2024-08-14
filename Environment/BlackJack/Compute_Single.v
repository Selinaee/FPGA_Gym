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


module Compute_Single #(parameter STA_WL = 160, ACT_WL = 1, OBS_WL = 32, RWD_WL = 2) (
    input wire i_clk,
    input wire i_rstn,
    input wire i_ena,

    input  wire [STA_WL-1:0] i_sta,
    input  wire [ACT_WL-1:0] i_act,

    output wire [STA_WL-1:0] o_sta,

    output wire [OBS_WL-1:0] o_obs,
    output wire [RWD_WL-1:0] o_rwd,
    output wire              o_done,

    output wire o_valid
    );

    localparam HIT = 1'b1, STICK = 1'b0;
    localparam CARD_WL = 4;
    localparam PLAYER_MAX_CARD_NUM = 21;
    localparam DEALER_MAX_CARD_NUM = 17;
    localparam MAX_CARD_VAL = 10;
    localparam MAX_SUM = 31;

    localparam IDLE = 1'b0;
    localparam DEALER_ADD_CARD = 1'b1;
    reg [0:0] next_state, state, last_state;

    // split i_sta
        wire [PLAYER_MAX_CARD_NUM*CARD_WL-1:0] i_player_cards;
        wire [DEALER_MAX_CARD_NUM*CARD_WL-1:0] i_dealer_cards;
        assign {i_dealer_cards, i_player_cards} = i_sta[DEALER_MAX_CARD_NUM*CARD_WL + PLAYER_MAX_CARD_NUM*CARD_WL - 1 : 0];
    // split o_sta
        wire [PLAYER_MAX_CARD_NUM*CARD_WL-1:0] o_player_cards;
        wire [DEALER_MAX_CARD_NUM*CARD_WL-1:0] o_dealer_cards;
        assign o_sta = {`ZERO(STA_WL-DEALER_MAX_CARD_NUM*CARD_WL-PLAYER_MAX_CARD_NUM*CARD_WL),
                        o_dealer_cards, o_player_cards};
    // split o_obs
        wire [$clog2(MAX_SUM)-1:0] o_player_sum_hand;
        wire [CARD_WL-1:0]         o_dealer_card0; // the dealer's showing card
        wire                       o_usable_ace;
        assign o_obs = {`ALL1(OBS_WL-$clog2(MAX_SUM)-CARD_WL-1), o_player_sum_hand, o_dealer_card0, o_usable_ace};

    wire [CARD_WL-1:0] new_card;

    // player info
    wire [$clog2(MAX_SUM)-1:0] player_sum_hand;
    wire [$clog2(MAX_SUM)-1:0] player_score;
    wire                       player_usable_ace;
    wire                       player_bust;

    // dealer info
    wire [$clog2(MAX_SUM)-1:0] dealer_sum_hand;
    wire [$clog2(MAX_SUM)-1:0] dealer_score;
    wire                       dealer_usable_ace;
    wire                       dealer_bust;

    wire [RWD_WL-1:0]                      hit_rwd, stick_rwd;
    reg  [DEALER_MAX_CARD_NUM*CARD_WL-1:0] stick_dealer_cards;

    reg  [STA_WL+ACT_WL-1:0] input_dly1;
    wire new_round;
    reg  valid;

    assign hit_rwd   = player_bust ? 2'b11 : 2'b00;            // 2'b11 = -1
    assign stick_rwd = (player_score > dealer_score) ? 2'b01 : // 2'b01 = 1
                       (player_score < dealer_score) ? 2'b11 : // 2'b11 = -1
                       2'b00;
    assign o_player_cards    = (i_act == HIT) ? {i_player_cards[(PLAYER_MAX_CARD_NUM-1)*CARD_WL-1:0], new_card} : i_player_cards;
    assign o_dealer_cards    = (i_act == HIT) ? i_dealer_cards : stick_dealer_cards;
    assign o_player_sum_hand = player_sum_hand;
    assign o_dealer_card0    = i_dealer_cards[CARD_WL-1:0];
    assign o_usable_ace      = player_usable_ace;
    assign o_rwd             = (i_act == HIT) ? hit_rwd : stick_rwd;
    assign o_done            = (i_act == HIT) ? player_bust : 1'b1;
    assign o_valid           = (i_act == HIT) ? i_ena : ((i_ena & state == DEALER_ADD_CARD & next_state == IDLE) | valid);

    // set new_round, input_dly1
        always @(posedge i_clk) begin
            input_dly1 <= {i_act, i_sta};
        end
        assign new_round = (i_ena & input_dly1 != {i_act, i_sta});

    // set valid
        always @(posedge i_clk or negedge i_rstn) begin
            if (~i_rstn) begin
                valid <= 1'b0;
            end else begin
                if (i_ena) begin
                    valid <= (i_act == HIT) ? 1'b1 : (i_ena & state == DEALER_ADD_CARD & next_state == IDLE | valid);
                end else begin
                    valid <= 1'b0;
                end
            end
        end

    // set stick_dealer_cards
        always @(posedge i_clk or negedge i_rstn) begin
            if (~i_rstn) begin
                stick_dealer_cards <= `ZERO(DEALER_MAX_CARD_NUM*CARD_WL);
            end else if (i_ena) begin
                case (state)
                    IDLE: begin
                        if (next_state != IDLE) begin
                            stick_dealer_cards <= i_dealer_cards;
                        end
                    end
                    DEALER_ADD_CARD: begin
                        if (next_state == DEALER_ADD_CARD) begin
                            stick_dealer_cards <= {stick_dealer_cards[CARD_WL +: (DEALER_MAX_CARD_NUM-2)*CARD_WL],
                                                   new_card, stick_dealer_cards[CARD_WL-1:0]};
                        end
                    end
                endcase
            end
        end

    // FSM
        always @(posedge i_clk or negedge i_rstn) begin
            if (~i_rstn) begin
                state <= IDLE;
                last_state <= IDLE;
            end else if (i_ena) begin
                state <= next_state;
                last_state <= state;
            end
        end
        always @(*) begin
            case (state)
                IDLE:            next_state = ((i_ena & i_act == STICK & dealer_sum_hand < DEALER_MAX_CARD_NUM) | new_round) ? DEALER_ADD_CARD : IDLE;
                DEALER_ADD_CARD: next_state = (i_ena & i_act == STICK & dealer_sum_hand < DEALER_MAX_CARD_NUM) ? DEALER_ADD_CARD : IDLE;
                default:         next_state = IDLE;
            endcase
        end

    Elaborate #(.CARD_WL(CARD_WL), .CARD_NUM(PLAYER_MAX_CARD_NUM), .MAX_SUM(MAX_SUM), .TARGET(PLAYER_MAX_CARD_NUM)) u_Player_Elaborate(
        .i_all_cards  ( o_player_cards[PLAYER_MAX_CARD_NUM*CARD_WL-1:0] ),
        .o_sum_hand   ( player_sum_hand[$clog2(MAX_SUM)-1:0] ),
        .o_score      ( player_score[$clog2(MAX_SUM)-1:0] ),
        .o_usable_ace ( player_usable_ace ),
        .o_bust       ( player_bust )
    );
    Elaborate #(.CARD_WL(CARD_WL), .CARD_NUM(DEALER_MAX_CARD_NUM), .MAX_SUM(MAX_SUM), .TARGET(PLAYER_MAX_CARD_NUM)) u_Dealer_Elaborate(
        .i_all_cards  ( o_dealer_cards[DEALER_MAX_CARD_NUM*CARD_WL-1:0] ),
        .o_sum_hand   ( dealer_sum_hand[$clog2(MAX_SUM)-1:0] ),
        .o_score      ( dealer_score[$clog2(MAX_SUM)-1:0] ),
        .o_usable_ace ( dealer_usable_ace ),
        .o_bust       ( dealer_bust )
    );
    LFSR #(.N(CARD_WL), .MIN(1), .MAX(MAX_CARD_VAL)) u_LFSR (
        .i_clk  ( i_clk ),
        .i_rstn ( i_rstn ),
        .i_ena  ( i_ena ),
        .o_out  ( new_card[CARD_WL-1:0] )
    );

endmodule
