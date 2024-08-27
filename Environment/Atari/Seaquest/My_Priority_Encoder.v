`timescale 10ps/1ps

module My_Priority_Encoder #(parameter IN_WIDTH = 5, OUT_WIDTH = 3, HIGH_FIRST = 1'b0, ACTIVE = 1'b0) (
    input [IN_WIDTH-1 : 0] in,
    output [OUT_WIDTH-1 : 0] out,
    output out_valid
    );

    wire [OUT_WIDTH-1 : 0] temp [IN_WIDTH : 0];

    generate
        if (HIGH_FIRST) begin: gen_high_first
            assign temp[0] = 64'd0;
            assign out = temp[IN_WIDTH];
        end else begin: gen_low_first
            assign temp[IN_WIDTH] = ~(64'd0);
            assign out = temp[0];
        end
    endgenerate

    genvar g1;
    generate
        if (~HIGH_FIRST) begin: gen_low_first1
            for (g1 = IN_WIDTH - 1; g1 >= 0; g1 = g1 - 1) begin: gen_low_first2
                assign temp[g1] = (in[g1] == ACTIVE) ? g1 : temp[g1+1];
            end
        end else begin: gen_high_first1
            for (g1 = 1; g1 <= IN_WIDTH; g1 = g1 + 1) begin: gen_high_first2
                assign temp[g1] = (in[g1-1] == ACTIVE) ? (g1-1) : temp[g1-1];
            end
        end
    endgenerate

    generate
        if (~ACTIVE) begin: gen_active_low
            assign out_valid = ~&in;
        end else begin: gen_active_high
            assign out_valid = |in;
        end
    endgenerate

endmodule
