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


module Elaborate #(parameter CARD_WL = 4, CARD_NUM = 21, MAX_SUM = 31, TARGET = 21) (
    input  wire [CARD_NUM*CARD_WL-1:0] i_all_cards,

    output wire [$clog2(MAX_SUM)-1:0]  o_sum_hand, // sum of all cards (including usable_ace)
    output wire [$clog2(MAX_SUM)-1:0]  o_score,    // score of the hand
    output wire                        o_usable_ace,
    output wire                        o_bust
    );

    // split i_all_cards
    wire [CARD_WL-1:0] all_cards [CARD_NUM-1:0];
    genvar g1; generate
        for (g1 = 0; g1 < CARD_NUM; g1 = g1 + 1) begin: gen_player_cards
            assign all_cards[g1] = i_all_cards[g1*CARD_WL +: CARD_WL];
        end
    endgenerate

    reg  [$clog2(CARD_NUM):0] sum;

    wire [CARD_NUM-1:0] is_1;  // whether all_cards[i] is Ace
    wire                has_1; // there is an Ace in hand

    // calculate sum
    always @(*) begin: calculate_sum
        reg [$clog2(CARD_NUM):0] i;
        sum = `ZERO($clog2(MAX_SUM));
        for (i = `ZERO($clog2(CARD_NUM)+1); i < CARD_NUM; i = i + 1) begin
            sum = sum + all_cards[i];
        end
    end

    genvar g2; generate
        for (g2 = 0; g2 < CARD_NUM; g2 = g2 + 1) begin: gen_is_1
            assign is_1[g2] = (all_cards[g2] == `ONE(CARD_WL));
        end
    endgenerate
    assign has_1 = |is_1;

    assign o_sum_hand   = sum + (o_usable_ace ? 10 : 0);
    assign o_score      = o_bust ? `ZERO($clog2(MAX_SUM)) : o_sum_hand;
    assign o_usable_ace = has_1 & (sum + 10 <= TARGET);
    assign o_bust       = (o_sum_hand > TARGET);

endmodule
