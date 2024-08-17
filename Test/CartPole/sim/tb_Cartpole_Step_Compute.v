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

module tb_Cartpole_Step_Compute();

    parameter PE_NUM = 20, ACT_WL = 1;
    parameter X_WL     = 32, X_DOT_WL = 32;
    parameter THETA_WL = 32, THETA_DOT_WL = 32;
    parameter RWD_WL = 1, DONE_WL = 1;

    reg clk, rstn;

    // Cartpole_Step_Compute ports
        reg                            cmpt_i_ena;
        wire [PE_NUM*X_WL-1:0]         cmpt_i_x;
        wire [PE_NUM*X_DOT_WL-1:0]     cmpt_i_x_dot;
        wire [PE_NUM*THETA_WL-1:0]     cmpt_i_theta;
        wire [PE_NUM*THETA_DOT_WL-1:0] cmpt_i_theta_dot;
        wire [PE_NUM*ACT_WL-1:0]       cmpt_i_act;
        wire [PE_NUM*X_WL-1:0]         cmpt_o_x;
        wire [PE_NUM*X_DOT_WL-1:0]     cmpt_o_x_dot;
        wire [PE_NUM*THETA_WL-1:0]     cmpt_o_theta;
        wire [PE_NUM*THETA_DOT_WL-1:0] cmpt_o_theta_dot;
        wire [PE_NUM*RWD_WL-1:0]       cmpt_o_rwd;
        wire [PE_NUM*DONE_WL-1:0]      cmpt_o_done;
        wire                           cmpt_o_valid;
    
    // split the input and output signals
        reg  [X_WL-1:0]         src_x         [PE_NUM-1:0];
        reg  [X_DOT_WL-1:0]     src_x_dot     [PE_NUM-1:0];
        reg  [THETA_WL-1:0]     src_theta     [PE_NUM-1:0];
        reg  [THETA_DOT_WL-1:0] src_theta_dot [PE_NUM-1:0];
        reg  [ACT_WL-1:0]       src_act       [PE_NUM-1:0];
        wire [X_WL-1:0]         dst_x         [PE_NUM-1:0];
        wire [X_DOT_WL-1:0]     dst_x_dot     [PE_NUM-1:0];
        wire [THETA_WL-1:0]     dst_theta     [PE_NUM-1:0];
        wire [THETA_DOT_WL-1:0] dst_theta_dot [PE_NUM-1:0];
        wire [RWD_WL-1:0]       dst_rwd       [PE_NUM-1:0];
        wire [DONE_WL-1:0]      dst_done      [PE_NUM-1:0];
        genvar g1;
        generate
            for (g1 = 0; g1 < PE_NUM; g1 = g1 + 1) begin
                assign cmpt_i_x[(g1+1)*X_WL-1:g1*X_WL]                         = src_x[g1];
                assign cmpt_i_x_dot[(g1+1)*X_DOT_WL-1:g1*X_DOT_WL]             = src_x_dot[g1];
                assign cmpt_i_theta[(g1+1)*THETA_WL-1:g1*THETA_WL]             = src_theta[g1];
                assign cmpt_i_theta_dot[(g1+1)*THETA_DOT_WL-1:g1*THETA_DOT_WL] = src_theta_dot[g1];
                assign cmpt_i_act[(g1+1)*ACT_WL-1:g1*ACT_WL]                   = src_act[g1];

                assign dst_x[g1]         = cmpt_o_x[(g1+1)*X_WL-1:g1*X_WL];
                assign dst_x_dot[g1]     = cmpt_o_x_dot[(g1+1)*X_DOT_WL-1:g1*X_DOT_WL];
                assign dst_theta[g1]     = cmpt_o_theta[(g1+1)*THETA_WL-1:g1*THETA_WL];
                assign dst_theta_dot[g1] = cmpt_o_theta_dot[(g1+1)*THETA_DOT_WL-1:g1*THETA_DOT_WL];
                assign dst_rwd[g1]       = cmpt_o_rwd[(g1+1)*RWD_WL-1:g1*RWD_WL];
                assign dst_done[g1]      = cmpt_o_done[(g1+1)*DONE_WL-1:g1*DONE_WL];
            end
        endgenerate

    always #5 clk = ~clk;
    initial begin
        clk = 1'b0; rstn = 1'b1; cmpt_i_ena = 1'b0;
        #10 rstn = 1'b0;
        #10 rstn = 1'b1; cmpt_i_ena = 1'b1;
    end
    initial begin
        src_x[0]         = 32'h3cc7d5cf; // x0:0.024393944069743156
        src_x_dot[0]     = 32'h3c263435; // ẋ0:0.010144283063709736
        src_theta[0]     = 32'hbc9b0897; // θ0:-0.01892499439418316
        src_theta_dot[0] = 32'hbd2e64b9; // ω0:-0.04257652536034584

        src_x[1]         = 32'hbbff9862; // x1:-0.007800147868692875
        src_x_dot[1]     = 32'h3c647ed6; // ẋ1:0.013946255668997765
        src_theta[1]     = 32'hbc80d245; // θ1:-0.015725264325737953
        src_theta_dot[1] = 32'hbd4ace32; // ω1:-0.04951304942369461

        src_x[2]         = 32'h3c3899c6; // x2:0.011267131194472313
        src_x_dot[2]     = 32'h3d326b5d; // ẋ2:0.043559420853853226
        src_theta[2]     = 32'h3d1b7e40; // θ2:0.03796219825744629
        src_theta_dot[2] = 32'h3bad2429; // ω2:0.005283851642161608

        src_x[3]         = 32'h3b714d1c; // x3:0.0036819642409682274
        src_x_dot[3]     = 32'h3cbbadb8; // ẋ3:0.0229099839925766
        src_theta[3]     = 32'hbce8703b; // θ3:-0.028373828157782555
        src_theta_dot[3] = 32'hba2a0bd4; // ω3:-0.000648674787953496

        src_x[4]         = 32'h3d2af0ee; // x4:0.041733674705028534
        src_x_dot[4]     = 32'h3d494556; // ẋ4:0.0491383895277977
        src_theta[4]     = 32'h3d359676; // θ4:0.044332943856716156
        src_theta_dot[4] = 32'hbcbe1384; // ω4:-0.023202665150165558

        src_x[5]         = 32'h3d09711d; // x5:0.03355513885617256
        src_x_dot[5]     = 32'hbc798e98; // ẋ5:-0.015231750905513763
        src_theta[5]     = 32'hbd1eec79; // θ5:-0.03879973664879799
        src_theta_dot[5] = 32'hbd0c1a0b; // ω5:-0.034204524010419846

        src_x[6]         = 32'hbc83a112; // x6:-0.01606801524758339
        src_x_dot[6]     = 32'hbcdc9a8b; // ẋ6:-0.026929160580039024
        src_theta[6]     = 32'hbbdbf1bc; // θ6:-0.006712166592478752
        src_theta_dot[6] = 32'hbcb214bf; // ω6:-0.021738408133387566

        src_x[7]         = 32'h3a19b7c2; // x7:0.0005863868864253163
        src_x_dot[7]     = 32'hbc9d8431; // ẋ7:-0.019228072836995125
        src_theta[7]     = 32'hbd190862; // θ7:-0.0373615100979805
        src_theta_dot[7] = 32'hbd2943a7; // ω7:-0.04132428392767906

        src_x[8]         = 32'h3d38fa62; // x8:0.04516065865755081
        src_x_dot[8]     = 32'h3b04e4e6; // ẋ8:0.0020278035663068295
        src_theta[8]     = 32'h3c69931b; // θ8:0.014256264083087444
        src_theta_dot[8] = 32'hbce5f5b8; // ω8:-0.028071269392967224

        src_x[9]         = 32'h3d141860; // x9:0.0361560583114624
        src_x_dot[9]     = 32'h3ca734b2; // ẋ9:0.020410869270563126
        src_theta[9]     = 32'h3d3cf09d; // θ9:0.04612790420651436
        src_theta_dot[9] = 32'h3d1e686f; // ω9:0.03867381438612938

        src_x[10]         = 32'h3ccad64e; // x10:0.02476039156317711
        src_x_dot[10]     = 32'hbd08f29d; // ẋ10:-0.03343449905514717
        src_theta[10]     = 32'h3d2e92b8; // θ10:0.04262039065361023
        src_theta_dot[10] = 32'h3c4866fc; // ω10:0.012231584638357162

        src_x[11]         = 32'h3c805ba2; // x11:0.01566869392991066s
        src_x_dot[11]     = 32'hbd0c0485; // ẋ11:-0.03418399766087532s
        src_theta[11]     = 32'h3b70bd0e; // θ11:0.00367337791249156s
        src_theta_dot[11] = 32'h3d058f3c; // ω11:0.032607302069664s

        src_x[12]         = 32'hbc897b3b; // x12:-0.01678239367902279
        src_x_dot[12]     = 32'hbc6b6812; // ẋ12:-0.014368074014782906
        src_theta[12]     = 32'hbca28ac4; // θ12:-0.01984155923128128
        src_theta_dot[12] = 32'h3cc66180; // ω12:0.024216413497924805

        src_x[13]         = 32'h3c853493; // x13:0.0162604209035635
        src_x_dot[13]     = 32'h3bbc8a78; // ẋ13:0.005753811448812485
        src_theta[13]     = 32'hbd147316; // θ13:-0.036242567002773285
        src_theta_dot[13] = 32'hbbb7a5ac; // ω13:-0.005604466423392296

        src_x[14]         = 32'hbcbe1868; // x14:-0.023204997181892395
        src_x_dot[14]     = 32'hbcc2492f; // ẋ14:-0.023716537281870842
        src_theta[14]     = 32'hbd1366df; // θ14:-0.035986777395009995
        src_theta_dot[14] = 32'hbb8b570f; // ω14:-0.004252321552485228

        src_x[15]         = 32'h3d45c72f; // x15:0.04828565940260887
        src_x_dot[15]     = 32'h3c7c55f7; // ẋ15:0.015401354990899563
        src_theta[15]     = 32'hbb8c10a3; // θ15:-0.004274444188922644
        src_theta_dot[15] = 32'h3d3ddeb0; // ω15:0.04635494947433472

        src_x[16]         = 32'hbcb78c84; // x16:-0.022405870258808136
        src_x_dot[16]     = 32'h3c9cae70; // ẋ16:0.019126147031784058
        src_theta[16]     = 32'h3ccffb57; // θ16:0.025388402864336967
        src_theta_dot[16] = 32'hbccbbbef; // ω16:-0.02486988715827465

        src_x[17]         = 32'hbc810007; // x17:-0.015747083351016045
        src_x_dot[17]     = 32'hbc1b734d; // ẋ17:-0.009487939067184925
        src_theta[17]     = 32'h3c9fbfb4; // θ17:0.01950059086084366
        src_theta_dot[17] = 32'hbce0d474; // ω17:-0.027445055544376373

        src_x[18]         = 32'hbab8de73; // x18:-0.0014104380970820785
        src_x_dot[18]     = 32'hbd068c36; // ẋ18:-0.03284855931997299
        src_theta[18]     = 32'h3be32069; // θ18:0.006931353826075792
        src_theta_dot[18] = 32'h3c8c05df; // ω18:0.017092643305659294

        src_x[19]         = 32'hbd205c52; // x19:-0.03915054351091385
        src_x_dot[19]     = 32'hbd1cfc06; // ẋ19:-0.038326285779476166
        src_theta[19]     = 32'h3cc76f74; // θ19:0.024345137178897858
        src_theta_dot[19] = 32'h3cf5273e; // ω19:0.029925938695669174

        src_act[0]  = 1'b0;
        src_act[1]  = 1'b1;
        src_act[2]  = 1'b1;
        src_act[3]  = 1'b1;
        src_act[4]  = 1'b1;
        src_act[5]  = 1'b1;
        src_act[6]  = 1'b0;
        src_act[7]  = 1'b1;
        src_act[8]  = 1'b0;
        src_act[9]  = 1'b1;
        src_act[10] = 1'b1;
        src_act[11] = 1'b1;
        src_act[12] = 1'b0;
        src_act[13] = 1'b1;
        src_act[14] = 1'b1;
        src_act[15] = 1'b0;
        src_act[16] = 1'b1;
        src_act[17] = 1'b0;
        src_act[18] = 1'b1;
        src_act[19] = 1'b0;
    end

    Cartpole_Step_Compute #(.PE_NUM(PE_NUM),     .ACT_WL(ACT_WL),
                            .X_WL(X_WL),         .X_DOT_WL(X_DOT_WL),
                            .THETA_WL(THETA_WL), .THETA_DOT_WL(THETA_DOT_WL),
                            .RWD_WL(RWD_WL),     .DONE_WL(DONE_WL)) u_Cartpole_Step_Compute(
        .i_clk       ( clk ),
        .i_rstn      ( rstn ),
        .i_ena       ( cmpt_i_ena ),
        .i_x         ( cmpt_i_x[PE_NUM*X_WL-1:0] ),
        .i_x_dot     ( cmpt_i_x_dot[PE_NUM*X_DOT_WL-1:0] ),
        .i_theta     ( cmpt_i_theta[PE_NUM*THETA_WL-1:0] ),
        .i_theta_dot ( cmpt_i_theta_dot[PE_NUM*THETA_DOT_WL-1:0] ),
        .i_act       ( cmpt_i_act[PE_NUM*ACT_WL-1:0] ),
        .o_x         ( cmpt_o_x[PE_NUM*X_WL-1:0] ),
        .o_x_dot     ( cmpt_o_x_dot[PE_NUM*X_DOT_WL-1:0] ),
        .o_theta     ( cmpt_o_theta[PE_NUM*THETA_WL-1:0] ),
        .o_theta_dot ( cmpt_o_theta_dot[PE_NUM*THETA_DOT_WL-1:0] ),
        .o_rwd       ( cmpt_o_rwd[PE_NUM*RWD_WL-1:0] ),
        .o_done      ( cmpt_o_done[PE_NUM*DONE_WL-1:0] ),
        .o_valid     ( cmpt_o_valid )
    );

endmodule