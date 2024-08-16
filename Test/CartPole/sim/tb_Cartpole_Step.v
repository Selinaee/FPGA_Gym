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

module tb_Cartpole_Step ();

    parameter DATA_WL = 32'd32;
    parameter ADDR_WL = 32'd32;
    parameter WEA_WL  = 32'd4;
    parameter ENV_NUM = 30'd64;
    parameter RAM_ADDR_WL = 10; // if RAM_ADDR_WL is 32, simulation will be very slow 

    reg        clk = 0;
    reg        rstn;
    reg [63:0] clk_cnt;

    reg new_round; // a new round of compute is started

    // cliffwalking_step ports
        wire [DATA_WL-1:0] uut_i_data;
        wire [DATA_WL-1:0] uut_o_data;
        wire [ADDR_WL-1:0] uut_o_addr;
        wire               uut_o_en;
        wire [WEA_WL-1:0]  uut_o_wea;
        wire               uut_o_rstb;

    // BRAM ports
        reg                    ram_i_wr1;
        reg  [RAM_ADDR_WL-1:0] ram_i_addr1;
        reg  [DATA_WL-1:0]     ram_i_data1;
        wire [DATA_WL-1:0]     ram_o_data1;
        wire                   ram_i_wr2;
        wire [RAM_ADDR_WL-1:0] ram_i_addr2;
        wire [DATA_WL-1:0]     ram_i_data2;
        wire [DATA_WL-1:0]     ram_o_data2;

    always #5 clk = !clk;

    initial begin
        rstn = 1;
        #10 rstn = 0;
        #10 rstn = 1;
    //  #10000 $finish;
    end

    always @(posedge clk or negedge rstn) begin
        if (rstn == 1'b0) begin
            clk_cnt <= 64'b0;
        end else begin
            clk_cnt <= clk_cnt + 1'b1;
        end
    end
    initial begin // write initial data
        #0  ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0; ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 0:
            // GT: [x ẋ θ ω rwd done] = [ 2.45968297e-02 -1.84701249e-01 -1.97765249e-02  2.44075819e-01 1 False]
            #20 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd0; ram_i_data1 = 32'h3cc7d5cf; // x0:0.024393944069743156
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd1; ram_i_data1 = 32'h3c263435; // ẋ0:0.010144283063709736
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd2; ram_i_data1 = 32'hbc9b0897; // θ0:-0.01892499439418316
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd3; ram_i_data1 = 32'hbd2e64b9; // ω0:-0.04257652536034584

            // GT: [x ẋ θ ω rwd done] = [-7.52122276e-03  2.09290121e-01 -1.67155253e-02 -3.47115657e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd4; ram_i_data1 = 32'hbbff9862; // x1:-0.007800147868692875
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd5; ram_i_data1 = 32'h3c647ed6; // ẋ1:0.013946255668997765
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd6; ram_i_data1 = 32'hbc80d245; // θ1:-0.015725264325737953
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd7; ram_i_data1 = 32'hbd4ace32; // ω1:-0.04951304942369461

            // GT: [x ẋ θ ω rwd done] = [ 1.21383196e-02  2.38116957e-01  3.80678753e-02 -2.75183985e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd8; ram_i_data1 = 32'h3c3899c6; // x2:0.011267131194472313
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd9; ram_i_data1 = 32'h3d326b5d; // ẋ2:0.043559420853853226
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd10; ram_i_data1 = 32'h3d1b7e40; // θ2:0.03796219825744629
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd11; ram_i_data1 = 32'h3bad2429; // ω2:0.005283851642161608

            // GT: [x ẋ θ ω rwd done] = [ 4.14016392e-03  2.18427125e-01 -2.83868017e-02 -3.02147126e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd12; ram_i_data1 = 32'h3b714d1c; // x3:0.0036819642409682274
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd13; ram_i_data1 = 32'h3cbbadb8; // ẋ3:0.0229099839925766
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd14; ram_i_data1 = 32'hbce8703b; // θ3:-0.028373828157782555
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd15; ram_i_data1 = 32'hba2a0bd4; // ω3:-0.000648674787953496

            // GT: [x ẋ θ ω rwd done] = [ 4.27164425e-02  2.43597451e-01  4.38688906e-02 -3.01575043e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd16; ram_i_data1 = 32'h3d2af0ee; // x4:0.041733674705028534
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd17; ram_i_data1 = 32'h3d494556; // ẋ4:0.0491383895277977
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd18; ram_i_data1 = 32'h3d359676; // θ4:0.044332943856716156
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd19; ram_i_data1 = 32'hbcbe1384; // ω4:-0.023202665150165558

            // GT: [x ẋ θ ω rwd done] = [ 3.32505038e-02  1.80424502e-01 -3.94838271e-02 -3.38872282e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd20; ram_i_data1 = 32'h3d09711d; // x5:0.03355513885617256
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd21; ram_i_data1 = 32'hbc798e98; // ẋ5:-0.015231750905513763
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd22; ram_i_data1 = 32'hbd1eec79; // θ5:-0.03879973664879799
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd23; ram_i_data1 = 32'hbd0c1a0b; // ω5:-0.034204524010419846

            // GT: [x ẋ θ ω rwd done] = [-1.66065985e-02 -2.21954213e-01 -7.14693476e-03  2.68819218e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd24; ram_i_data1 = 32'hbc83a112; // x6:-0.01606801524758339
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd25; ram_i_data1 = 32'hbcdc9a8b; // ẋ6:-0.026929160580039024
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd26; ram_i_data1 = 32'hbbdbf1bc; // θ6:-0.006712166592478752
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd27; ram_i_data1 = 32'hbcb214bf; // ω6:-0.021738408133387566

            // GT: [x ẋ θ ω rwd done] = [ 2.01825430e-04  1.76409164e-01 -3.81879958e-02 -3.45557076e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd28; ram_i_data1 = 32'h3a19b7c2; // x7:0.0005863868864253163
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd29; ram_i_data1 = 32'hbc9d8431; // ẋ7:-0.019228072836995125
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd30; ram_i_data1 = 32'hbd190862; // θ7:-0.0373615100979805
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd31; ram_i_data1 = 32'hbd2943a7; // ω7:-0.04132428392767906

            // GT: [x ẋ θ ω rwd done] = [ 4.52012147e-02 -1.93295660e-01  1.36948387e-02  2.69075353e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd32; ram_i_data1 = 32'h3d38fa62; // x8:0.04516065865755081
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd33; ram_i_data1 = 32'h3b04e4e6; // ẋ8:0.0020278035663068295
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd34; ram_i_data1 = 32'h3c69931b; // θ8:0.014256264083087444
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd35; ram_i_data1 = 32'hbce5f5b8; // ω8:-0.028071269392967224

            // GT: [x ẋ θ ω rwd done] = [ 3.65642757e-02  2.14842034e-01  4.69013805e-02 -2.39105913e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd36; ram_i_data1 = 32'h3d141860; // x9:0.0361560583114624
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd37; ram_i_data1 = 32'h3ca734b2; // ẋ9:0.020410869270563126
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd38; ram_i_data1 = 32'h3d3cf09d; // θ9:0.04612790420651436
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd39; ram_i_data1 = 32'h3d1e686f; // ω9:0.03867381438612938

            // GT: [x ẋ θ ω rwd done] = [ 2.40917016e-02  1.61051125e-01  4.28650223e-02 -2.66705328e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd40; ram_i_data1 = 32'h3ccad64e; // x10:0.02476039156317711
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd41; ram_i_data1 = 32'hbd08f29d; // ẋ10:-0.03343449905514717
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd42; ram_i_data1 = 32'h3d2e92b8; // θ10:0.04262039065361023
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd43; ram_i_data1 = 32'h3c4866fc; // ω10:0.012231584638357162

            // GT: [x ẋ θ ω rwd done] = [ 1.49850140e-02  1.60885084e-01  4.32552395e-03 -2.58914375e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd44; ram_i_data1 = 32'h3c805ba2; // x11:0.01566869392991066
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd45; ram_i_data1 = 32'hbd0c0485; // ẋ11:-0.03418399766087532
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd46; ram_i_data1 = 32'h3b70bd0e; // θ11:0.00367337791249156
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd47; ram_i_data1 = 32'h3d058f3c; // ω11:0.032607302069664

            // GT: [x ẋ θ ω rwd done] = [-1.70697552e-02 -2.09199943e-01 -1.93572310e-02  3.10573655e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd48; ram_i_data1 = 32'hbc897b3b; // x12:-0.01678239367902279
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd49; ram_i_data1 = 32'hbc6b6812; // ẋ12:-0.014368074014782906
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd50; ram_i_data1 = 32'hbca28ac4; // θ12:-0.01984155923128128
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd51; ram_i_data1 = 32'h3cc66180; // ω12:0.024216413497924805

            // GT: [x ẋ θ ω rwd done] = [ 1.63754971e-02  2.01376285e-01 -3.63546563e-02 -3.09498463e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd52; ram_i_data1 = 32'h3c853493; // x13:0.0162604209035635
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd53; ram_i_data1 = 32'h3bbc8a78; // ẋ13:0.005753811448812485
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd54; ram_i_data1 = 32'hbd147316; // θ13:-0.036242567002773285
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd55; ram_i_data1 = 32'hbbb7a5ac; // ω13:-0.005604466423392296

            // GT: [x ẋ θ ω rwd done] = [-2.36793279e-02  1.71902542e-01 -3.60718238e-02 -3.08068788e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd56; ram_i_data1 = 32'hbcbe1868; // x14:-0.023204997181892395
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd57; ram_i_data1 = 32'hbcc2492f; // ẋ14:-0.023716537281870842
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd58; ram_i_data1 = 32'hbd1366df; // θ14:-0.035986777395009995
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd59; ram_i_data1 = 32'hbb8b570f; // ω14:-0.004252321552485228

            // GT: [x ẋ θ ω rwd done] = [ 4.85936865e-02 -1.79659043e-01 -3.34734520e-03  3.37686191e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd60; ram_i_data1 = 32'h3d45c72f; // x15:0.04828565940260887
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd61; ram_i_data1 = 32'h3c7c55f7; // ẋ15:0.015401354990899563
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd62; ram_i_data1 = 32'hbb8c10a3; // θ15:-0.004274444188922644
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd63; ram_i_data1 = 32'h3d3ddeb0; // ω15:0.04635494947433472

            // GT: [x ẋ θ ω rwd done] = [-2.20233473e-02  2.13874980e-01  2.48910051e-02 -3.09435606e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd64; ram_i_data1 = 32'hbcb78c84; // x16:-0.022405870258808136
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd65; ram_i_data1 = 32'h3c9cae70; // ẋ16:0.019126147031784058
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd66; ram_i_data1 = 32'h3ccffb57; // θ16:0.025388402864336967
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd67; ram_i_data1 = 32'hbccbbbef; // ω16:-0.02486988715827465

            // GT: [x ẋ θ ω rwd done] = [-1.59368421e-02 -2.04884036e-01  1.89516897e-02  2.71326174e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd68; ram_i_data1 = 32'hbc810007; // x17:-0.015747083351016045
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd69; ram_i_data1 = 32'hbc1b734d; // ẋ17:-0.009487939067184925
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd70; ram_i_data1 = 32'h3c9fbfb4; // θ17:0.01950059086084366
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd71; ram_i_data1 = 32'hbce0d474; // ω17:-0.027445055544376373

            // GT: [x ẋ θ ω rwd done] = [-2.06740928e-03  1.62173306e-01  7.27320669e-03 -2.73395325e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd72; ram_i_data1 = 32'hbab8de73; // x18:-0.0014104380970820785
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd73; ram_i_data1 = 32'hbd068c36; // ẋ18:-0.03284855931997299
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd74; ram_i_data1 = 32'h3be32069; // θ18:0.006931353826075792
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd75; ram_i_data1 = 32'h3c8c05df; // ω18:0.017092643305659294

            // GT: [x ẋ θ ω rwd done] = [-3.99170692e-02 -2.33788748e-01  2.49436560e-02  3.30189513e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd76; ram_i_data1 = 32'hbd205c52; // x19:-0.03915054351091385
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd77; ram_i_data1 = 32'hbd1cfc06; // ẋ19:-0.038326285779476166
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd78; ram_i_data1 = 32'h3cc76f74; // θ19:0.024345137178897858
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd79; ram_i_data1 = 32'h3cf5273e; // ω19:0.029925938695669174

            // GT: [x ẋ θ ω rwd done] = [-2.45208194e-02 -2.32501283e-01  4.45679783e-02  3.55714347e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd80; ram_i_data1 = 32'hbcc2d91e; // x20:-0.023785170167684555
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd81; ram_i_data1 = 32'hbd16a935; // ẋ20:-0.036782462149858475
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd82; ram_i_data1 = 32'h3d327c91; // θ20:0.04357582703232765
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd83; ram_i_data1 = 32'h3d4b314d; // ω20:0.04960756376385689

            // GT: [x ẋ θ ω rwd done] = [-6.16776894e-04 -2.22087176e-01 -4.44923986e-02  2.69446864e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd84; ram_i_data1 = 32'hb886adef; // x21:-6.42201557639055e-05
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd85; ram_i_data1 = 32'hbce253c6; // ẋ21:-0.027627836912870407
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd86; ram_i_data1 = 32'hbd358259; // θ21:-0.044313762336969376
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd87; ram_i_data1 = 32'hbc1256bd; // ω21:-0.008931812830269337

            // GT: [x ẋ θ ω rwd done] = [ 1.79011542e-02 -1.84988774e-01 -4.44535178e-02  2.76865726e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd88; ram_i_data1 = 32'h3c91184a; // x22:0.017711777240037918
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd89; ram_i_data1 = 32'h3c1b233b; // ẋ22:0.009468848817050457
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd90; ram_i_data1 = 32'hbd35f5ed; // θ22:-0.04442398622632027
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd91; ram_i_data1 = 32'hbac189c4; // ω22:-0.0014765788801014423

            // GT: [x ẋ θ ω rwd done] = [ 4.82387303e-02  1.84173658e-01  4.46704835e-03 -3.13848000e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd92; ram_i_data1 = 32'h3d467a17; // x23:0.04845627769827843
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd93; ram_i_data1 = 32'hbc3236ff; // ẋ23:-0.010877369903028011
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd94; ram_i_data1 = 32'h3ba1446c; // θ23:0.004921486601233482
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd95; ram_i_data1 = 32'hbcba234e; // ω23:-0.02272191271185875

            // GT: [x ẋ θ ω rwd done] = [ 2.54273751e-02  2.23221821e-01 -1.15132855e-02 -3.05361062e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd96; ram_i_data1 = 32'h3ccbb937; // x24:0.024868590757250786
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd97; ram_i_data1 = 32'h3ce4e0ca; // ẋ24:0.027939219027757645
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd98; ram_i_data1 = 32'hbc39a4c7; // θ24:-0.011330789886415005
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd99; ram_i_data1 = 32'hbc15801c; // ω24:-0.00912478193640709

            // GT: [x ẋ θ ω rwd done] = [-4.64653667e-02 -1.85521915e-01 -3.82031265e-02  2.99436245e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd100; ram_i_data1 = 32'hbd3f0fc2; // x25:-0.046645887196063995
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd101; ram_i_data1 = 32'h3c13e1e6; // ẋ25:0.009026026353240013
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd102; ram_i_data1 = 32'hbd1e0cf9; // θ25:-0.03858659043908119
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd103; ram_i_data1 = 32'h3c9d111d; // ω25:0.01917319931089878

            // GT: [x ẋ θ ω rwd done] = [-3.93535397e-02 -1.86125362e-01 -2.52916315e-02  2.34937343e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd104; ram_i_data1 = 32'hbd21e65f; // x26:-0.03952633962035179
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd105; ram_i_data1 = 32'h3c0d8ec4; // ẋ26:0.008639995008707047
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd106; ram_i_data1 = 32'hbcc6fff1; // θ26:-0.02429196424782276
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd107; ram_i_data1 = 32'hbd4cbb5b; // ω26:-0.04998336359858513

            // GT: [x ẋ θ ω rwd done] = [-4.20029853e-02  2.43569074e-01 -1.57352682e-03 -2.93147660e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd108; ram_i_data1 = 32'hbd3002dc; // x27:-0.042971476912498474
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd109; ram_i_data1 = 32'h3d4658db; // ẋ27:0.04842458292841911
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd110; ram_i_data1 = 32'hbace53f3; // θ27:-0.0015741571551188827
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd111; ram_i_data1 = 32'h38043120; // ω27:3.1517003662884235e-05

            // GT: [x ẋ θ ω rwd done] = [-4.79922035e-02 -1.93201290e-01 -2.94142951e-02  2.94206310e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd112; ram_i_data1 = 32'hbd44b295; // x28:-0.04802187159657478
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd113; ram_i_data1 = 32'h3ac26eba; // ẋ28:0.0014834024477750063
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd114; ram_i_data1 = 32'hbcf2c469; // θ28:-0.029634671285748482
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd115; ram_i_data1 = 32'h3c34883f; // ω28:0.011018811725080013

            // GT: [x ẋ θ ω rwd done] = [-1.28047467e-02  1.92377898e-01  4.69684762e-02 -3.26482694e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd116; ram_i_data1 = 32'hbc512126; // x29:-0.012764250859618187
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd117; ram_i_data1 = 32'hbb04b26a; // ẋ29:-0.002024794463068247
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd118; ram_i_data1 = 32'h3d446c10; // θ29:0.04795461893081665
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd119; ram_i_data1 = 32'hbd49f648; // ω29:-0.04930713772773743

            // GT: [x ẋ θ ω rwd done] = [ 3.76676784e-02 -2.12440435e-01 -2.99689161e-02  2.45922759e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd120; ram_i_data1 = 32'h3d1bbda8; // x30:0.03802266716957092
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd121; ram_i_data1 = 32'hbc916744; // ẋ30:-0.01774943619966507
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd122; ram_i_data1 = 32'hbcef60bb; // θ30:-0.029220929369330406
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd123; ram_i_data1 = 32'hbd19300c; // ω30:-0.03739933669567108

            // GT: [x ẋ θ ω rwd done] = [-2.51672529e-02  2.41922306e-01  2.01165886e-02 -3.01216710e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd124; ram_i_data1 = 32'hbcd5e308; // x31:-0.026109233498573303
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd125; ram_i_data1 = 32'h3d40eae9; // ẋ31:0.047099027782678604
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd126; ram_i_data1 = 32'h3ca74294; // θ31:0.020417489111423492
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd127; ram_i_data1 = 32'hbc767f6b; // ω31:-0.015045027248561382

            // GT: [x ẋ θ ω rwd done] = [ 4.61953346e-02 -1.63766152e-01 -2.89725055e-02  2.54613566e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd128; ram_i_data1 = 32'h3d3aae84; // x32:0.045576587319374084
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd129; ram_i_data1 = 32'h3cfd705a; // ẋ32:0.03093736246228218
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd130; ram_i_data1 = 32'hbce89857; // θ32:-0.028392953798174858
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd131; ram_i_data1 = 32'hbced6267; // ω32:-0.028977585956454277

            // GT: [x ẋ θ ω rwd done] = [ 2.89783238e-02 -2.27662227e-01  4.10845126e-02  3.03402337e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd132; ram_i_data1 = 32'h3cf2a118; // x33:0.029617831110954285
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd133; ram_i_data1 = 32'hbd02f89a; // ẋ33:-0.03197536617517471
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd134; ram_i_data1 = 32'h3d28717b; // θ33:0.04112384840846062
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd135; ram_i_data1 = 32'hbb00e53e; // ω33:-0.001966788899153471

            // GT: [x ẋ θ ω rwd done] = [-3.86777632e-02  1.95396623e-01  1.93065978e-02 -2.78260687e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd136; ram_i_data1 = 32'hbd1e7833; // x34:-0.03868884965777397
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd137; ram_i_data1 = 32'h3a11500b; // ẋ34:0.0005543238366954029
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd138; ram_i_data1 = 32'h3c9ccbce; // θ34:0.019140150398015976
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd139; ram_i_data1 = 32'h3c085a8b; // ω34:0.008322368375957012

            // GT: [x ẋ θ ω rwd done] = [-1.13488028e-02  2.04784337e-01  4.94315016e-02 -2.40233327e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd140; ram_i_data1 = 32'hbc3d582f; // x35:-0.011556669138371944
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd141; ram_i_data1 = 32'h3c2a48bb; // ẋ35:0.010393316857516766
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd142; ram_i_data1 = 32'h3d47771d; // θ35:0.048697579652071
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd143; ram_i_data1 = 32'h3d164ea6; // ω35:0.03669609874486923

            // GT: [x ẋ θ ω rwd done] = [-1.52961536e-02 -1.45126492e-01 -2.23412625e-02  3.03969356e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd144; ram_i_data1 = 32'hbc85715b; // x36:-0.016289403662085533
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd145; ram_i_data1 = 32'h3d4b6ae9; // ẋ36:0.049662504345178604
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd146; ram_i_data1 = 32'hbcba0e90; // θ36:-0.022712022066116333
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd147; ram_i_data1 = 32'h3c97dcf5; // ω36:0.01853797771036625

            // GT: [x ẋ θ ω rwd done] = [-5.63081868e-03  2.34898525e-01  3.93212214e-02 -3.07864690e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd148; ram_i_data1 = 32'hbbd2f7c8; // x37:-0.0064382292330265045
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd149; ram_i_data1 = 32'h3d255b91; // ẋ37:0.040370527654886246
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd150; ram_i_data1 = 32'h3d235b0e; // θ37:0.03988175839185715
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd151; ram_i_data1 = 32'hbce5988f; // ω37:-0.028026847168803215

            // GT: [x ẋ θ ω rwd done] = [-2.52995883e-02  1.68714755e-01  4.24432767e-02 -3.07150134e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd152; ram_i_data1 = 32'hbccb086d; // x38:-0.02478429116308689
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd153; ram_i_data1 = 32'hbcd310d1; // ẋ38:-0.02576485462486744
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd154; ram_i_data1 = 32'h3d302b5e; // θ38:0.043010108172893524
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd155; ram_i_data1 = 32'hbce82c96; // ω38:-0.028341572731733322

            // GT: [x ẋ θ ω rwd done] = [-1.62871418e-02  2.11161390e-01  1.54225646e-02 -3.09462094e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd156; ram_i_data1 = 32'hbc88170b; // x39:-0.016612550243735313
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd157; ram_i_data1 = 32'h3c85498c; // ẋ39:0.01627042144536972
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd158; ram_i_data1 = 32'h3c81eadc; // θ39:0.015859059989452362
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd159; ram_i_data1 = 32'hbcb2c9dd; // ω39:-0.021824771538376808

            // GT: [x ẋ θ ω rwd done] = [ 1.11452918e-02  2.40990715e-01 -3.33328015e-02 -3.06765845e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd160; ram_i_data1 = 32'h3c27b9a5; // x40:0.0102371321991086
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd161; ram_i_data1 = 32'h3d39fdb8; // ẋ40:0.0454079806804657
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd162; ram_i_data1 = 32'hbd0838be; // θ40:-0.03325723856687546
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd163; ram_i_data1 = 32'hbb779ac5; // ω40:-0.00377814588136971

            // GT: [x ẋ θ ω rwd done] = [-4.02697624e-02 -2.29856853e-01 -3.43310211e-03  3.23766177e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd164; ram_i_data1 = 32'hbd22183b; // x41:-0.03957388922572136
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd165; ram_i_data1 = 32'hbd0e83cb; // ẋ41:-0.034793656319379807
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd166; ram_i_data1 = 32'hbb85b652; // θ41:-0.004080572165548801
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd167; ram_i_data1 = 32'h3d049a14; // ω41:0.03237350285053253

            // GT: [x ẋ θ ω rwd done] = [-1.14364194e-02 -1.95143044e-01  2.56039523e-02  3.26045834e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd168; ram_i_data1 = 32'hbc3b7b78; // x42:-0.011443011462688446
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd169; ram_i_data1 = 32'h39accee2; // ẋ42:0.00032960536191239953
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd170; ram_i_data1 = 32'h3ccd8fa0; // θ42:0.025092899799346924
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd171; ram_i_data1 = 32'h3cd153be; // ω42:0.025552626699209213

            // GT: [x ẋ θ ω rwd done] = [-4.06721598e-02 -1.56904389e-01  4.12140613e-03  3.42547549e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd172; ram_i_data1 = 32'hbd29ba46; // x43:-0.041437409818172455
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd173; ram_i_data1 = 32'h3d1cb924; // ẋ43:0.0382625013589859
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd174; ram_i_data1 = 32'h3b4e0a36; // θ43:0.003143919166177511
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd175; ram_i_data1 = 32'h3d483078; // ω43:0.048874348402023315

            // GT: [x ẋ θ ω rwd done] = [ 1.14636199e-02 -1.60179260e-01  1.54257222e-02  2.63860911e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd176; ram_i_data1 = 32'h3c304ba5; // x44:0.010760222561657429
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd177; ram_i_data1 = 32'h3d100e47; // ẋ44:0.03516986593604088
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd178; ram_i_data1 = 32'h3c83ea3a; // θ44:0.016102898865938187
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd179; ram_i_data1 = 32'hbd0aaf90; // ω44:-0.03385883569717407

            // GT: [x ẋ θ ω rwd done] = [-4.26815348e-02  2.07009158e-01  8.53655215e-03 -3.37579252e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd180; ram_i_data1 = 32'hbd2fcf02; // x45:-0.04292202740907669
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd181; ram_i_data1 = 32'h3c4502f6; // ẋ45:0.012024631723761559
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd182; ram_i_data1 = 32'h3c1b8fa1; // θ45:0.009494693018496037
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd183; ram_i_data1 = 32'hbd443a2d; // ω45:-0.04790704324841499

            // GT: [x ẋ θ ω rwd done] = [-2.13552011e-03  2.25419206e-01 -4.38336696e-02 -3.23839855e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd184; ram_i_data1 = 32'hbb32e246; // x46:-0.002729551400989294
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd185; ram_i_data1 = 32'h3cf350b2; // ẋ46:0.029701564460992813
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd186; ram_i_data1 = 32'hbd32166f; // θ46:-0.04347842559218407
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd187; ram_i_data1 = 32'hbc91820a; // ω46:-0.0177622027695179

            // GT: [x ẋ θ ω rwd done] = [ 3.01440983e-04 -1.90033401e-01  5.56633759e-03  2.74050335e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd188; ram_i_data1 = 32'h394f9519; // x47:0.00019796601554844528
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd189; ram_i_data1 = 32'h3ba9888c; // ẋ47:0.005173748359084129
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd190; ram_i_data1 = 32'h3bc3d736; // θ47:0.005976582877337933
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd191; ram_i_data1 = 32'hbca80956; // ω47:-0.020512264221906662

            // GT: [x ẋ θ ω rwd done] = [ 2.96976459e-02 -2.09060345e-01  3.45576500e-02  2.94068528e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd192; ram_i_data1 = 32'h3cf57cf0; // x48:0.029966801404953003
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd193; ram_i_data1 = 32'hbc5c7dfe; // ẋ48:-0.013457773253321648
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd194; ram_i_data1 = 32'h3d0e50da; // θ48:0.034745074808597565
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd195; ram_i_data1 = 32'hbc1989d7; // ω48:-0.009371242485940456

            // GT: [x ẋ θ ω rwd done] = [ 1.31852734e-02  2.30830822e-01  2.23244424e-06 -2.71484599e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd196; ram_i_data1 = 32'h3c4c5414; // x49:0.012471217662096024
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd197; ram_i_data1 = 32'h3d123d16; // ẋ49:0.03570278733968735
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd198; ram_i_data1 = 32'hb9de8391; // θ49:-0.00042441164259798825
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd199; ram_i_data1 = 32'h3caec0e0; // ω49:0.021332204341888428

            // GT: [x ẋ θ ω rwd done] = [-1.09019819e-02 -1.45799389e-01 -3.75612995e-02  3.05728610e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd200; ram_i_data1 = 32'hbc429839; // x50:-0.01187711302191019
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd201; ram_i_data1 = 32'h3d47b4f4; // ẋ50:0.04875655472278595
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd202; ram_i_data1 = 32'hbd1bec5b; // θ50:-0.038067203015089035
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd203; ram_i_data1 = 32'h3ccf37d3; // ω50:0.02529517374932766

            // GT: [x ẋ θ ω rwd done] = [-4.61396270e-02  2.35191978e-01  3.74866764e-02 -2.44577413e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd204; ram_i_data1 = 32'hbd4050af; // x51:-0.04695194587111473
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd205; ram_i_data1 = 32'h3d265ce7; // ẋ51:0.04061594232916832
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd206; ram_i_data1 = 32'h3d1692b2; // θ51:0.03676099330186844
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd207; ram_i_data1 = 32'h3d149eb2; // ω51:0.036284156143665314

            // GT: [x ẋ θ ω rwd done] = [-2.23994621e-02  1.93811628e-01  2.27885508e-02 -3.21125986e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd208; ram_i_data1 = 32'hbcb75695; // x52:-0.022380152717232704
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd209; ram_i_data1 = 32'hba7d179a; // ẋ52:-0.0009654700988903642
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd210; ram_i_data1 = 32'h3cc092fa; // θ52:0.023507583886384964
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd211; ram_i_data1 = 32'hbd13420b; // ω52:-0.035951655358076096

            // GT: [x ẋ θ ω rwd done] = [ 3.90872176e-02 -1.70155274e-01 -3.74250590e-02  3.22923817e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd212; ram_i_data1 = 32'h3d1e1a44; // x53:0.03859926760196686
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd213; ram_i_data1 = 32'h3cc7dd43; // ẋ53:0.02439749799668789
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd214; ram_i_data1 = 32'hbd1cc78b; // θ53:-0.03827623650431633
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd215; ram_i_data1 = 32'h3d2e5237; // ω53:0.04255887493491173

            // GT: [x ẋ θ ω rwd done] = [ 3.06954530e-02  1.84204747e-01  3.01203442e-02 -2.96553138e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd216; ram_i_data1 = 32'h3cfd2c1c; // x54:0.030904822051525116
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd217; ram_i_data1 = 32'hbc2b83dd; // ẋ54:-0.010468450374901295
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd218; ram_i_data1 = 32'h3cf8f9e1; // θ54:0.030392589047551155
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd219; ram_i_data1 = 32'hbc5f05e3; // ω54:-0.013612243346869946

            // GT: [x ẋ θ ω rwd done] = [ 1.37163212e-02  1.92934123e-01  3.41725415e-04 -2.49606380e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd220; ram_i_data1 = 32'h3c617294; // x55:0.013760227710008621
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd221; ram_i_data1 = 32'hbb0fdf74; // ẋ55:-0.002195325680077076
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd222; ram_i_data1 = 32'hba092104; // θ55:-0.0005231054965406656
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd223; ram_i_data1 = 32'h3d311e0c; // ω55:0.04324154555797577

            // GT: [x ẋ θ ω rwd done] = [ 2.92933527e-02 -1.85661587e-01 -1.35891121e-02  2.78396703e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd224; ram_i_data1 = 32'h3cee73fa; // x56:0.029108036309480667
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd225; ram_i_data1 = 32'h3c17cfac; // ẋ56:0.009265821427106857
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd226; ram_i_data1 = 32'hbc5b5b50; // θ56:-0.013388469815254211
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd227; ram_i_data1 = 32'hbc245dba; // ω56:-0.010032111778855324

            // GT: [x ẋ θ ω rwd done] = [-1.04546861e-02 -2.12898669e-01  1.14778436e-02  2.66958836e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd228; ram_i_data1 = 32'hbc258541; // x57:-0.010102570988237858
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd229; ram_i_data1 = 32'hbc9039f1; // ẋ57:-0.017605753615498543
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd230; ram_i_data1 = 32'h3c45b8cd; // θ57:0.012067985720932484
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd231; ram_i_data1 = 32'hbcf1b8e4; // ω57:-0.0295071080327034

            // GT: [x ẋ θ ω rwd done] = [-1.52897447e-02 -1.63673940e-01  2.91643795e-02  3.51382465e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd232; ram_i_data1 = 32'hbc827866; // x58:-0.015926551073789597
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd233; ram_i_data1 = 32'h3d026afe; // ẋ58:0.03184031695127487
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd234; ram_i_data1 = 32'h3ce6bb2c; // θ58:0.02816542237997055
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd235; ram_i_data1 = 32'h3d4c9620; // ω58:0.04994785785675049

            // GT: [x ẋ θ ω rwd done] = [-2.48681653e-02 -1.86353850e-01 -3.75577082e-02  2.58900303e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd236; ram_i_data1 = 32'hbccd10f4; // x59:-0.025032497942447662
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd237; ram_i_data1 = 32'h3c069f0d; // ẋ59:0.008216631598770618
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd238; ram_i_data1 = 32'hbd180c06; // θ59:-0.037120841443538666
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd239; ram_i_data1 = 32'hbcb2f0cd; // ω59:-0.021843338385224342

            // GT: [x ẋ θ ω rwd done] = [-1.65185016e-02 -2.03333405e-01 -2.64389505e-02  2.57217378e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd240; ram_i_data1 = 32'hbc85e96d; // x60:-0.016346657648682594
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd241; ram_i_data1 = 32'hbc0cc64b; // ẋ60:-0.008592198602855206
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd242; ram_i_data1 = 32'hbcd42250; // θ60:-0.025895267724990845
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd243; ram_i_data1 = 32'hbcdeb146; // ω60:-0.0271841399371624

            // GT: [x ẋ θ ω rwd done] = [ 2.72261473e-02 -2.37509935e-01 -9.38578166e-03  3.36697649e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd244; ram_i_data1 = 32'h3ce60187; // x61:0.02807690016925335
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd245; ram_i_data1 = 32'hbd2e3bf4; // ẋ61:-0.04253764450550079
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd246; ram_i_data1 = 32'hbc2945fc; // θ61:-0.010331626981496811
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd247; ram_i_data1 = 32'h3d41b589; // ω61:0.04729226604104042

            // GT: [x ẋ θ ω rwd done] = [ 3.68387363e-02  1.66679177e-01 -4.03455113e-02 -2.95220115e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd248; ram_i_data1 = 32'h3d194464; // x62:0.03741873800754547
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd249; ram_i_data1 = 32'hbced9195; // ẋ62:-0.02900008298456669
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd250; ram_i_data1 = 32'hbd261284; // θ62:-0.04054500162601471
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd251; ram_i_data1 = 32'h3c236c27; // ω62:0.009974515996873379

            // GT: [x ẋ θ ω rwd done] = [ 1.04006133e-02  1.68064995e-01 -2.12939740e-02 -3.40345308e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd252; ram_i_data1 = 32'h3c335d26; // x63:0.01094750128686428
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd253; ram_i_data1 = 32'hbce0015c; // ẋ63:-0.027344398200511932
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd254; ram_i_data1 = 32'hbca7ad7d; // θ63:-0.020468467846512794
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd255; ram_i_data1 = 32'hbd29104c; // ω63:-0.04127530753612518

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd256; ram_i_data1 = 32'b10101001100001010110111010111110; // action31~0
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd257; ram_i_data1 = 32'b11000000110110100110000111101100; // action63~32

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd258; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;   ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 1:
            #11000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd256; ram_i_data1 = 32'b00111111111011011000010000110011; // action31~0
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd257; ram_i_data1 = 32'b00000010000010000101101011001100; // action63~32

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd258; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;   ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 2:
            #6000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd256; ram_i_data1 = 32'b00011011101111111001000011011001; // action31~0
            #10   ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd257; ram_i_data1 = 32'b11111110100100000001000010111010; // action63~32

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd258; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;   ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 3:
            #6000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd256; ram_i_data1 = 32'b01100100111011000111010111001000; // action31~0
            #10   ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd257; ram_i_data1 = 32'b00010010001100001110010010010000; // action63~32

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd258; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;   ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 4:
            #6000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd256; ram_i_data1 = 32'b11101100011001110101110010001010; // action31~0
            #10   ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd257; ram_i_data1 = 32'b11111000100001111111000010110000; // action63~32

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd258; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;   ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 5:
            #6000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd256; ram_i_data1 = 32'b11000110111111101110001001111110; // action31~0
            #10   ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd257; ram_i_data1 = 32'b01001011101111010000111110110001; // action63~32

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd258; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;   ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 6:
            #6000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd256; ram_i_data1 = 32'b10100101010011000000010011011001; // action31~0
            #10   ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd257; ram_i_data1 = 32'b00000100111111000001000011101111; // action63~32

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd258; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;   ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 7:
            #6000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd256; ram_i_data1 = 32'b11110111101011101001110000101011; // action31~0
            #10   ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd257; ram_i_data1 = 32'b10001000001111001110111011001111; // action63~32

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd258; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;   ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 8:
            #6000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd256; ram_i_data1 = 32'b00101001110010000111110111111111; // action31~0
            #10   ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd257; ram_i_data1 = 32'b10001000001110111111100010110011; // action63~32

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd258; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;   ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 9:
            #6000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd256; ram_i_data1 = 32'b01111010010010100010001011011111; // action31~0
            #10   ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd257; ram_i_data1 = 32'b10011001111001000000001011110011; // action63~32

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd258; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;   ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 10:
            #6000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd256; ram_i_data1 = 32'b01101100101000010111010010100110; // action31~0
            #10   ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd257; ram_i_data1 = 32'b10100100000010110011000001111001; // action63~32

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd258; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;   ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 11:
            #6000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd256; ram_i_data1 = 32'b00100100011000011100100001101111; // action31~0
            #10   ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd257; ram_i_data1 = 32'b11000101010001101100011000010100; // action63~32

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd258; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;   ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 12:
            #6000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd256; ram_i_data1 = 32'b01110010101110110011011001011011; // action31~0
            #10   ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd257; ram_i_data1 = 32'b11011100110010010110000111011000; // action63~32

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd258; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;   ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 13:
            #6000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd256; ram_i_data1 = 32'b01111001010011101100011000001010; // action31~0
            #10   ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd257; ram_i_data1 = 32'b01100110010010101111000101111010; // action63~32

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd258; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;   ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 14:
            #6000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd256; ram_i_data1 = 32'b10001010011100001111111001011101; // action31~0
            #10   ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd257; ram_i_data1 = 32'b10011010010001101110011011001101; // action63~32

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd258; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;   ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 15:
            #6000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd256; ram_i_data1 = 32'b00111011000010110011111111010010; // action31~0
            #10   ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd257; ram_i_data1 = 32'b01010111111000100101110110110101; // action63~32

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd258; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;   ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 16:
            #6000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd256; ram_i_data1 = 32'b01010011101110010100111100000010; // action31~0
            #10   ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd257; ram_i_data1 = 32'b10110000110010110110001111100110; // action63~32

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd258; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;   ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 17:
            #6000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd256; ram_i_data1 = 32'b00101101110010101101101100001101; // action31~0
            #10   ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd257; ram_i_data1 = 32'b11111110101110011011111001110000; // action63~32

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd258; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;   ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 18:
            #6000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd256; ram_i_data1 = 32'b01111001111110000111110101000110; // action31~0
            #10   ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd257; ram_i_data1 = 32'b00111101000001001000100110000101; // action63~32

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd258; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;   ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 19:
            #6000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd256; ram_i_data1 = 32'b01010111010101011001010100000000; // action31~0
            #10   ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd257; ram_i_data1 = 32'b11011011110101101101101010011010; // action63~32

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd258; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;   ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 20:
            #6000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd256; ram_i_data1 = 32'b10010001100010100011001111010110; // action31~0
            #10   ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd257; ram_i_data1 = 32'b00000101001000101110011101111111; // action63~32

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd258; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;   ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 21:
            #6000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd256; ram_i_data1 = 32'b01110011100000100010011011110011; // action31~0
            #10   ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd257; ram_i_data1 = 32'b10111010000000011000101011011100; // action63~32

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd258; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;   ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 22:
            // GT: [x ẋ θ ω rwd done] = [ 4.15082413e-02 -1.69603141e-01 -1.29966353e-02  3.29435337e-01 1 False]
            #6000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd0; ram_i_data1 = 32'h3d27f197; // x0:0.041001882404088974
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd1; ram_i_data1 = 32'h3ccf6793; // ẋ0:0.02531794272363186
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd2; ram_i_data1 = 32'hbc626b49; // θ0:-0.013819524087011814
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd3; ram_i_data1 = 32'h3d288713; // ω0:0.041144441813230515

            // GT: [x ẋ θ ω rwd done] = [-4.87845205e-02  1.67984043e-01  4.16376717e-02 -2.38164407e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd4; ram_i_data1 = 32'hbd45a5e9; // x1:-0.04825392737984657
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd5; ram_i_data1 = 32'hbcd954b8; // ẋ1:-0.02652965486049652
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd6; ram_i_data1 = 32'h3d2728b5; // θ1:0.04081030562520027
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd7; ram_i_data1 = 32'h3d2971d0; // ω1:0.041368305683135986

            // GT: [x ẋ θ ω rwd done] = [ 8.55685422e-03 -2.08928596e-01 -4.26862608e-02  3.20490349e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd8; ram_i_data1 = 32'h3c10eec8; // x2:0.008845992386341095
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd9; ram_i_data1 = 32'hbc6cdcab; // ẋ2:-0.014456908218562603
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd10; ram_i_data1 = 32'hbd324577; // θ2:-0.04352327808737755
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd11; ram_i_data1 = 32'h3d2b6bd0; // ω2:0.04185086488723755

            // GT: [x ẋ θ ω rwd done] = [ 1.46123675e-02  1.60832797e-01  1.82952944e-02 -2.76305836e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd12; ram_i_data1 = 32'h3c7a8ef4; // x3:0.015292871743440628
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd13; ram_i_data1 = 32'hbd0b5e06; // ẋ3:-0.03402521461248398
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd14; ram_i_data1 = 32'h3c9422b1; // θ3:0.01808294840157032
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd15; ram_i_data1 = 32'h3c2df42d; // ω3:0.010617298074066639

            // GT: [x ẋ θ ω rwd done] = [ 1.46391150e-02 -1.94100719e-01  6.91639503e-03  2.54397304e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd16; ram_i_data1 = 32'h3c6f7a01; // x4:0.014616490341722965
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd17; ram_i_data1 = 32'h3a9445cf; // ẋ4:0.0011312308488413692
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd18; ram_i_data1 = 32'h3bfd51b7; // θ4:0.007730688434094191
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd19; ram_i_data1 = 32'hbd26c46d; // ω4:-0.04071466997265816

            // GT: [x ẋ θ ω rwd done] = [-2.98888127e-02 -1.86658582e-01  1.21300510e-02  3.31470064e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd20; ram_i_data1 = 32'hbcf64328; // x5:-0.03006131947040558
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd21; ram_i_data1 = 32'h3c0d514d; // ẋ5:0.008625340647995472
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd22; ram_i_data1 = 32'h3c3b33fc; // θ5:0.011425968259572983
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd23; ram_i_data1 = 32'h3d103237; // ω5:0.03520413860678673

            // GT: [x ẋ θ ω rwd done] = [-1.23830219e-02 -1.68633932e-01 -4.63023361e-02  2.94978219e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd24; ram_i_data1 = 32'hbc535580; // x6:-0.012898802757263184
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd25; ram_i_data1 = 32'h3cd3438a; // ẋ6:0.025789041072130203
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd26; ram_i_data1 = 32'hbd3f13d1; // θ6:-0.0466497577726841
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd27; ram_i_data1 = 32'h3c8e4dce; // ω6:0.017371084541082382

            // GT: [x ẋ θ ω rwd done] = [ 3.45027432e-02 -1.98797964e-01 -2.37095227e-02  2.66080462e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd28; ram_i_data1 = 32'h3d0da704; // x7:0.03458310663700104
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd29; ram_i_data1 = 32'hbb83aadf; // ẋ7:-0.0040181721560657024
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd30; ram_i_data1 = 32'hbcbf172a; // θ7:-0.02332647517323494
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd31; ram_i_data1 = 32'hbc9ce573; // ω7:-0.019152378663420677

            // GT: [x ẋ θ ω rwd done] = [ 2.45376050e-02  1.62133327e-01 -4.49149313e-02 -3.14385324e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd32; ram_i_data1 = 32'h3cce846a; // x8:0.02520962432026863
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd33; ram_i_data1 = 32'hbd09a12b; // ẋ8:-0.03360096737742424
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd34; ram_i_data1 = 32'hbd37528b; // θ8:-0.0447564534842968
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd35; ram_i_data1 = 32'hbc01d334; // ω8:-0.00792388990521431

            // GT: [x ẋ θ ω rwd done] = [-1.15022126e-02  1.69110209e-01  2.48092889e-02 -2.49464189e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd36; ram_i_data1 = 32'hbc340b6d; // x9:-0.01098905224353075
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd37; ram_i_data1 = 32'hbcd230c3; // ẋ9:-0.02565801702439785
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd38; ram_i_data1 = 32'h3cc56b14; // θ9:0.02409891039133072
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd39; ram_i_data1 = 32'h3d117c4b; // ω9:0.03551892563700676

            // GT: [x ẋ θ ω rwd done] = [ 3.45050941e-02 -2.10614332e-01  4.20404818e-02  2.87584789e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd40; ram_i_data1 = 32'h3d0e8dea; // x10:0.03480330854654312
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd41; ram_i_data1 = 32'hbc744c1a; // ẋ10:-0.014910722151398659
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd42; ram_i_data1 = 32'h3d2dafb0; // θ10:0.04240387678146362
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd43; ram_i_data1 = 32'hbc94d8ba; // ω10:-0.018169749528169632

            // GT: [x ẋ θ ω rwd done] = [-1.46326654e-02 -1.65420265e-01  3.07623960e-02  2.85344595e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd44; ram_i_data1 = 32'hbc799da3; // x11:-0.015235337428748608
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd45; ram_i_data1 = 32'h3cf6dabf; // ẋ11:0.030133603140711784
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd46; ram_i_data1 = 32'h3cfec9e7; // θ11:0.0311021339148283
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd47; ram_i_data1 = 32'hbc8b281a; // ω11:-0.016986895352602005

            // GT: [x ẋ θ ω rwd done] = [-3.45792241e-02  1.50325119e-01  4.34060896e-02 -2.80260723e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd48; ram_i_data1 = 32'hbd0a0519; // x12:-0.03369626775383949
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd49; ram_i_data1 = 32'hbd34d458; // ẋ12:-0.04414781928062439
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd50; ram_i_data1 = 32'h3d31ebff; // θ12:0.04343795403838158
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd51; ram_i_data1 = 32'hbad0d3aa; // ω12:-0.0015932221431285143

            // GT: [x ẋ θ ω rwd done] = [-1.20261789e-02 -2.14567196e-01  1.91898908e-02  2.56108176e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd52; ram_i_data1 = 32'hbc3ec1e4; // x13:-0.011642906814813614
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd53; ram_i_data1 = 32'hbc9cfcff; // ẋ13:-0.01916360668838024
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd54; ram_i_data1 = 32'h3ca4389b; // θ13:0.020046522840857506
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd55; ram_i_data1 = 32'hbd2f7030; // ω13:-0.042831599712371826

            // GT: [x ẋ θ ω rwd done] = [ 2.98218372e-02 -1.51831764e-01 -3.57804018e-02  3.16972074e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd56; ram_i_data1 = 32'h3ced4bef; // x14:0.0289668720215559
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd57; ram_i_data1 = 32'h3d2f18cd; // ẋ14:0.042748261243104935
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd58; ram_i_data1 = 32'hbd1581fa; // θ14:-0.03650090843439102
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd59; ram_i_data1 = 32'h3d138f4c; // ω14:0.03602533042430878

            // GT: [x ẋ θ ω rwd done] = [-1.92142995e-02 -2.05240782e-01 -1.10234667e-02  3.30392906e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd60; ram_i_data1 = 32'hbc9bb7ae; // x15:-0.019008483737707138
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd61; ram_i_data1 = 32'hbc289ab1; // ẋ15:-0.010290787555277348
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd62; ram_i_data1 = 32'hbc4232ca; // θ15:-0.01185292936861515
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd63; ram_i_data1 = 32'h3d29dfbc; // ω15:0.041473135352134705

            // GT: [x ẋ θ ω rwd done] = [-2.62771592e-02 -2.44919382e-01  2.56883771e-03  3.06513055e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd64; ram_i_data1 = 32'hbccf1bed; // x16:-0.025281870737671852
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd65; ram_i_data1 = 32'hbd4bd5c8; // ẋ16:-0.049764424562454224
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd66; ram_i_data1 = 32'h3b172d3d; // θ16:0.0023067735601216555
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd67; ram_i_data1 = 32'h3c56aed6; // ω16:0.01310320757329464

            // GT: [x ẋ θ ω rwd done] = [ 3.73886842e-02 -1.53983932e-01 -2.29596233e-02  2.73062691e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd68; ram_i_data1 = 32'h3d15cd22; // x17:0.03657258301973343
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd69; ram_i_data1 = 32'h3d272334; // ẋ17:0.04080505669116974
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd70; ram_i_data1 = 32'hbcba0f0b; // θ17:-0.02271225117146969
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd71; ram_i_data1 = 32'hbc4aa5b2; // ω17:-0.01236860640347004

            // GT: [x ẋ θ ω rwd done] = [-3.70540255e-02 -2.06467099e-01 -6.69276999e-03  3.32412746e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd72; ram_i_data1 = 32'hbd16d5c1; // x18:-0.036824945360422134
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd73; ram_i_data1 = 32'hbc3ba994; // ẋ18:-0.011454004794359207
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd74; ram_i_data1 = 32'hbbf6e909; // θ18:-0.007535104174166918
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd75; ram_i_data1 = 32'h3d2c8292; // ω18:0.04211670905351639

            // GT: [x ẋ θ ω rwd done] = [ 3.39401449e-02 -2.34353824e-01  4.44611935e-02  3.29114235e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd76; ram_i_data1 = 32'h3d0e2ef0; // x19:0.03471273183822632
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd77; ram_i_data1 = 32'hbd1e39ce; // ẋ19:-0.03862934559583664
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd78; ram_i_data1 = 32'h3d343d23; // θ19:0.04400361701846123
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd79; ram_i_data1 = 32'h3cbb6c5e; // ω19:0.022878821939229965

            // GT: [x ẋ θ ω rwd done] = [ 3.12504574e-02 -1.68945263e-01 -3.26395036e-02  3.15099345e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd80; ram_i_data1 = 32'h3cfbcbb5; // x20:0.030736783519387245
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd81; ram_i_data1 = 32'h3cd2669d; // ẋ20:0.025683695450425148
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd82; ram_i_data1 = 32'hbd08674c; // θ20:-0.03330163657665253
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd83; ram_i_data1 = 32'h3d079ad6; // ω20:0.03310664743185043

            // GT: [x ẋ θ ω rwd done] = [-1.47410701e-04 -1.69080208e-01 -3.84307639e-02  2.86448743e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd84; ram_i_data1 = 32'hba2c2b6e; // x21:-0.0006567750824615359
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd85; ram_i_data1 = 32'h3cd0a2ba; // ẋ21:0.025468219071626663
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd86; ram_i_data1 = 32'hbd1deb14; // θ21:-0.03855426609516144
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd87; ram_i_data1 = 32'h3bca5893; // ω21:0.006175109650939703

            // GT: [x ẋ θ ω rwd done] = [-3.11665148e-03 -1.73243705e-01  1.38898577e-02  2.89199574e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd88; ram_i_data1 = 32'hbb693080; // x22:-0.0035581886768341064
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd89; ram_i_data1 = 32'h3cb4da88; // ẋ22:0.022076860070228577
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd90; ram_i_data1 = 32'h3c66277e; // θ22:0.014047501608729362
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd91; ram_i_data1 = 32'hbc012455; // ω22:-0.007882197387516499

            // GT: [x ẋ θ ω rwd done] = [ 4.61062784e-02 -1.75368350e-01  9.63815134e-03  2.68933605e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd92; ram_i_data1 = 32'h3d3b38a5; // x23:0.045708317309617996
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd93; ram_i_data1 = 32'h3ca30140; // ẋ23:0.019898056983947754
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd94; ram_i_data1 = 32'h3c26bd77; // θ23:0.010177007876336575
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd95; ram_i_data1 = 32'hbcdcb734; // ω23:-0.026942826807498932

            // GT: [x ẋ θ ω rwd done] = [-7.00449750e-04 -2.16868775e-01  4.25579802e-02  3.40111771e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd96; ram_i_data1 = 32'hb9913b0a; // x24:-0.0002770054270513356
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd97; ram_i_data1 = 32'hbcad715b; // ẋ24:-0.021172216162085533
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd98; ram_i_data1 = 32'h3d2b7d5e; // θ24:0.04186760634183884
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd99; ram_i_data1 = 32'h3d0d6379; // ω24:0.03451869264245033

            // GT: [x ẋ θ ω rwd done] = [ 3.30424143e-02  2.08337784e-01  2.93333174e-02 -3.01368440e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd100; ram_i_data1 = 32'h3d063923; // x25:0.0327693335711956
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd101; ram_i_data1 = 32'h3c5fb52d; // ẋ25:0.01365403551608324
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd102; ram_i_data1 = 32'h3cf347d8; // θ25:0.029697343707084656
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd103; ram_i_data1 = 32'hbc951aee; // ω25:-0.018201317638158798

            // GT: [x ẋ θ ω rwd done] = [ 1.47167245e-02 -1.60076312e-01 -1.85418439e-02  2.60702969e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd104; ram_i_data1 = 32'h3c65b8a2; // x26:0.014021070674061775
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd105; ram_i_data1 = 32'h3d0e784b; // ẋ26:0.034782689064741135
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd106; ram_i_data1 = 32'hbc93986c; // θ26:-0.018017016351222992
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd107; ram_i_data1 = 32'hbcd6f828; // ω26:-0.026241376996040344

            // GT: [x ẋ θ ω rwd done] = [-3.12708537e-02 -2.39585589e-01  3.71503458e-02  3.15192549e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd108; ram_i_data1 = 32'hbcf8f82b; // x27:-0.030391773208975792
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd109; ram_i_data1 = 32'hbd340923; // ẋ27:-0.0439540259540081
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd110; ram_i_data1 = 32'h3d17425f; // θ27:0.036928530782461166
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd111; ram_i_data1 = 32'h3c35b5fc; // ω27:0.011090751737356186

            // GT: [x ẋ θ ω rwd done] = [ 4.64186690e-02  2.05739690e-01 -8.94024439e-03 -2.52819911e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd112; ram_i_data1 = 32'h3d3d45c0; // x28:0.046209096908569336
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd113; ram_i_data1 = 32'h3c2bae74; // ẋ28:0.010478604584932327
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd114; ram_i_data1 = 32'hbc208c0c; // θ28:-0.009799014776945114
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd115; ram_i_data1 = 32'h3d2fe04d; // ω28:0.04293851926922798

            // GT: [x ẋ θ ω rwd done] = [ 1.82813442e-02  1.47614080e-01  3.24365455e-02 -2.52756749e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd116; ram_i_data1 = 32'h3c9d77a3; // x29:0.019222086295485497
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd117; ram_i_data1 = 32'hbd40a9fb; // ẋ29:-0.04703710600733757
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd118; ram_i_data1 = 32'h3d026d14; // θ29:0.03184230625629425
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd119; ram_i_data1 = 32'h3cf36681; // ω29:0.02971196360886097

            // GT: [x ẋ θ ω rwd done] = [ 2.69415849e-02  1.52602307e-01  3.97135653e-02 -2.47163379e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd120; ram_i_data1 = 32'h3ce393a0; // x30:0.027780354022979736
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd121; ram_i_data1 = 32'hbd2bc7a8; // ẋ30:-0.041938453912734985
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd122; ram_i_data1 = 32'h3d1ff7c3; // θ30:0.039054643362760544
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd123; ram_i_data1 = 32'h3d06f27d; // ω30:0.03294609859585762

            // GT: [x ẋ θ ω rwd done] = [ 3.76440948e-02 -2.39905896e-01  2.61403426e-02  3.14150063e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd124; ram_i_data1 = 32'h3d1dd44e; // x31:0.038532547652721405
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd125; ram_i_data1 = 32'hbd35f485; // ẋ31:-0.04442264512181282
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd126; ram_i_data1 = 32'h3cd3f17d; // θ31:0.025871986523270607
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd127; ram_i_data1 = 32'h3c5bd657; // ω31:0.013417801819741726

            // GT: [x ẋ θ ω rwd done] = [-3.65403485e-02  2.44499380e-01  1.17087903e-02 -2.71255522e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd128; ram_i_data1 = 32'hbd19ba4e; // x32:-0.03753118962049484
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd129; ram_i_data1 = 32'h3d4aec9d; // ẋ32:0.049542058259248734
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd130; ram_i_data1 = 32'h3c39ff08; // θ32:0.011352308094501495
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd131; ram_i_data1 = 32'h3c9203de; // ω32:0.01782410964369774

            // GT: [x ẋ θ ω rwd done] = [ 1.29864480e-02  2.19524909e-01 -1.03603810e-03 -3.15077790e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd132; ram_i_data1 = 32'h3c4cc6c1; // x33:0.01249855849891901
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd133; ram_i_data1 = 32'h3cc7d6ec; // ẋ33:0.024394474923610687
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd134; ram_i_data1 = 32'hba1b2807; // θ33:-0.0005918745300732553
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd135; ram_i_data1 = 32'hbcb5eded; // ω33:-0.02220817841589451

            // GT: [x ẋ θ ω rwd done] = [-1.04869607e-02  1.54273438e-01  3.59947982e-02 -2.37934047e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd136; ram_i_data1 = 32'hbc1e9a92; // x34:-0.009680407121777534
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd137; ram_i_data1 = 32'hbd252ea3; // ẋ34:-0.04032767936587334
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd138; ram_i_data1 = 32'h3d0fdfcd; // θ34:0.03512554243206978
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd139; ram_i_data1 = 32'h3d320609; // ω34:0.043462786823511124

            // GT: [x ẋ θ ω rwd done] = [-1.83986764e-02  2.42644658e-01 -1.03046477e-02 -2.96258492e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd140; ram_i_data1 = 32'hbc9e7bf0; // x35:-0.0193462073802948
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd141; ram_i_data1 = 32'h3d420de9; // ẋ35:0.04737654700875282
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd142; ram_i_data1 = 32'hbc28b7f0; // θ35:-0.010297760367393494
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd143; ram_i_data1 = 32'hb9b48c5d; // ω35:-0.0003443685418460518

            // GT: [x ẋ θ ω rwd done] = [ 1.74323197e-02 -1.58254529e-01  2.71519044e-02  2.98882728e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd144; ram_i_data1 = 32'h3c88b3fc; // x36:0.016687385737895966
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd145; ram_i_data1 = 32'h3d188ffe; // ẋ36:0.0372466966509819
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd146; ram_i_data1 = 32'h3cdecc47; // θ36:0.027197016403079033
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd147; ram_i_data1 = 32'hbb13d2a7; // ω36:-0.0022555978503078222

            // GT: [x ẋ θ ω rwd done] = [-4.32433767e-03 -1.85442606e-01 -3.46721928e-02  2.78189520e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd148; ram_i_data1 = 32'hbb93b50b; // x37:-0.004507665988057852
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd149; ram_i_data1 = 32'h3c162ebc; // ẋ37:0.0091664157807827
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd150; ram_i_data1 = 32'hbd0dbd99; // θ37:-0.034604642540216446
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd151; ram_i_data1 = 32'hbb5d594c; // ω37:-0.0033775148913264275

            // GT: [x ẋ θ ω rwd done] = [-2.88655104e-02  2.05426278e-01  2.82767995e-02 -2.74437826e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd152; ram_i_data1 = 32'hbcee38eb; // x38:-0.029079874977469444
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd153; ram_i_data1 = 32'h3c2f9b83; // ẋ38:0.010718229226768017
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd154; ram_i_data1 = 32'h3ce620ba; // θ38:0.028091777116060257
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd155; ram_i_data1 = 32'h3c179200; // ω38:0.009251117706298828

            // GT: [x ẋ θ ω rwd done] = [ 2.60813326e-03  1.77406312e-01 -2.50593012e-02 -3.07606077e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd156; ram_i_data1 = 32'h3b429a78; // x39:0.0029694121330976486
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd157; ram_i_data1 = 32'hbc93fad6; // ẋ39:-0.018063943833112717
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd158; ram_i_data1 = 32'hbccc1c8d; // θ39:-0.02491595782339573
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd159; ram_i_data1 = 32'hbbeada8d; // ω39:-0.007167166564613581

            // GT: [x ẋ θ ω rwd done] = [ 2.16090686e-02  2.43967235e-01  4.31874114e-02 -2.65394964e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd160; ram_i_data1 = 32'h3ca8e9e6; // x40:0.02061934396624565
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd161; ram_i_data1 = 32'h3d4ab213; // ẋ40:0.04948623105883598
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd162; ram_i_data1 = 32'h3d2fcb59; // θ40:0.04291853681206703
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd163; ram_i_data1 = 32'h3c5c4318; // ω40:0.013443730771541595

            // GT: [x ẋ θ ω rwd done] = [ 1.54601092e-02 -2.24139488e-01 -2.30600374e-03  3.16919360e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd164; ram_i_data1 = 32'h3c8368fa; // x41:0.016041267663240433
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd165; ram_i_data1 = 32'hbcee0ae3; // ẋ41:-0.029057925567030907
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd166; ram_i_data1 = 32'hbb380e7e; // θ41:-0.002808480989187956
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd167; ram_i_data1 = 32'h3ccdd08f; // ω41:0.02512386254966259

            // GT: [x ẋ θ ω rwd done] = [-1.01371625e-02 -1.70070819e-01  1.60002020e-02  2.48579398e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd168; ram_i_data1 = 32'hbc2e5fde; // x42:-0.010642973706126213
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd169; ram_i_data1 = 32'h3ccf2e26; // ẋ42:0.025290559977293015
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd170; ram_i_data1 = 32'h3c8b2b76; // θ42:0.016988497227430344
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd171; ram_i_data1 = 32'hbd4a6722; // ω42:-0.04941476136445999

            // GT: [x ẋ θ ω rwd done] = [-7.88722791e-03 -1.74640334e-01 -4.52426694e-02  2.99532429e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd172; ram_i_data1 = 32'hbc07b632; // x43:-0.008283184841275215
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd173; ram_i_data1 = 32'h3ca22f18; // ẋ43:0.01979784667491913
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd174; ram_i_data1 = 32'hbd3b156d; // θ43:-0.045674730092287064
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd175; ram_i_data1 = 32'h3cb0f8d8; // ω43:0.02160303294658661

            // GT: [x ẋ θ ω rwd done] = [ 5.01006093e-02 -1.62069779e-01  5.05418447e-02  3.54758374e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd176; ram_i_data1 = 32'h3d4a72fd; // x44:0.04942606762051582
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd177; ram_i_data1 = 32'h3d0a2569; // ẋ44:0.03372708335518837
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd178; ram_i_data1 = 32'h3d4b2e86; // θ44:0.04960491508245468
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd179; ram_i_data1 = 32'h3d3fe219; // ω44:0.046846482902765274

            // GT: [x ẋ θ ω rwd done] = [-2.24739859e-02  2.22563920e-01  9.02781352e-03 -3.39050094e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd180; ram_i_data1 = 32'hbcbca073; // x45:-0.02302572689950466
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd181; ram_i_data1 = 32'h3ce1fe3d; // ẋ45:0.027587050572037697
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd182; ram_i_data1 = 32'h3c242586; // θ45:0.010018711909651756
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd183; ram_i_data1 = 32'hbd4aef9d; // ω45:-0.04954491928219795

            // GT: [x ẋ θ ω rwd done] = [-4.29072176e-02 -1.87415004e-01  1.94643838e-03  2.54677821e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd184; ram_i_data1 = 32'hbd3061ec; // x46:-0.04306213557720184
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd185; ram_i_data1 = 32'h3bfdd14f; // ẋ46:0.007745898794382811
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd186; ram_i_data1 = 32'h3b328026; // θ46:0.002723702695220709
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd187; ram_i_data1 = 32'hbd1f2f09; // ω46:-0.03886321559548378

            // GT: [x ẋ θ ω rwd done] = [ 2.26646250e-02  1.56169802e-01  1.91076403e-02 -3.12079496e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd188; ram_i_data1 = 32'h3cc000e8; // x47:0.02343793213367462
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd189; ram_i_data1 = 32'hbd1e5f91; // ẋ47:-0.03866535797715187
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd190; ram_i_data1 = 32'h3ca0bb83; // θ47:0.019620662555098534
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd191; ram_i_data1 = 32'hbcd22249; // ω47:-0.0256511140614748

            // GT: [x ẋ θ ω rwd done] = [-9.78627231e-03  1.90904003e-01 -1.15931014e-02 -3.13769485e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd192; ram_i_data1 = 32'hbc1ee767; // x48:-0.009698725305497646
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd193; ram_i_data1 = 32'hbb8f6fe0; // ẋ48:-0.004377350211143494
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd194; ram_i_data1 = 32'hbc382fe0; // θ48:-0.011241883039474487
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd195; ram_i_data1 = 32'hbc8fdbeb; // ω48:-0.017560919746756554

            // GT: [x ẋ θ ω rwd done] = [-7.96566695e-03  1.85193128e-01  3.04328974e-02 -3.22973300e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd196; ram_i_data1 = 32'hbbfed084; // x49:-0.007776321843266487
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd197; ram_i_data1 = 32'hbc1b1c8c; // ẋ49:-0.00946725532412529
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd198; ram_i_data1 = 32'h3cffe90d; // θ49:0.031239056959748268
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd199; ram_i_data1 = 32'hbd2519fa; // ω49:-0.04030797630548477

            // GT: [x ẋ θ ω rwd done] = [-2.04469953e-02 -1.50172840e-01  3.00488228e-02  3.43142631e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd200; ram_i_data1 = 32'hbcaeeed0; // x50:-0.021354109048843384
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd201; ram_i_data1 = 32'h3d39c6e2; // ẋ50:0.04535568505525589
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd202; ram_i_data1 = 32'h3cef6120; // θ50:0.02922111749649048
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd203; ram_i_data1 = 32'h3d298399; // ω50:0.04138526692986488

            // GT: [x ẋ θ ω rwd done] = [-9.65443863e-03  2.06439411e-01  1.51562213e-02 -2.52243853e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd204; ram_i_data1 = 32'hbc21f4a5; // x51:-0.009884987957775593
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd205; ram_i_data1 = 32'h3c3cddb3; // ẋ51:0.011527466587722301
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd206; ram_i_data1 = 32'h3c6c929a; // θ51:0.014439249411225319
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd207; ram_i_data1 = 32'h3d12d5fa; // ω51:0.03584859520196915

            // GT: [x ẋ θ ω rwd done] = [ 2.45663690e-02 -2.41691978e-01  3.48759351e-02  3.48591446e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd208; ram_i_data1 = 32'h3cd0ccfa; // x52:0.025488365441560745
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd209; ram_i_data1 = 32'hbd3cd32b; // ẋ52:-0.04609982296824455
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd210; ram_i_data1 = 32'h3d0b2238; // θ52:0.033968180418014526
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd211; ram_i_data1 = 32'h3d39e87d; // ω52:0.04538773372769356

            // GT: [x ẋ θ ω rwd done] = [ 3.97707594e-02  2.26329921e-01  4.33546578e-02 -2.48991713e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd212; ram_i_data1 = 32'h3d204acc; // x53:0.03913383185863495
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd213; ram_i_data1 = 32'h3d027159; // ẋ53:0.03184637799859047
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd214; ram_i_data1 = 32'h3d2f2199; // θ53:0.04275665059685707
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd215; ram_i_data1 = 32'h3cf4f19a; // ω53:0.029900360852479935

            // GT: [x ẋ θ ω rwd done] = [-4.83294245e-03  1.50369374e-01 -1.82316791e-02 -3.17875023e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd216; ram_i_data1 = 32'hbb80df46; // x54:-0.003932866267859936
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd217; ram_i_data1 = 32'hbd3855ea; // ẋ54:-0.04500380903482437
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd218; ram_i_data1 = 32'hbc9223ca; // θ54:-0.017839331179857254
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd219; ram_i_data1 = 32'hbca0b4a8; // ω54:-0.019617393612861633

            // GT: [x ẋ θ ω rwd done] = [-1.84475558e-02 -2.36231050e-01 -3.37952909e-03  2.62546559e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd220; ram_i_data1 = 32'hbc906167; // x55:-0.017624570056796074
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd221; ram_i_data1 = 32'hbd288c27; // ẋ55:-0.041149284690618515
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd222; ram_i_data1 = 32'hbb372349; // θ55:-0.0027944615576416254
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd223; ram_i_data1 = 32'hbcefa4c7; // ω55:-0.02925337664783001

            // GT: [x ẋ θ ω rwd done] = [-4.47518548e-02  2.04426439e-01 -3.52944053e-02 -2.86790295e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd224; ram_i_data1 = 32'hbd380686; // x56:-0.04492809623479843
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd225; ram_i_data1 = 32'h3c106080; // ẋ56:0.0088120698928833
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd226; ram_i_data1 = 32'hbd11f3ae; // θ56:-0.03563278168439865
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd227; ram_i_data1 = 32'h3c8a9957; // ω56:0.01691882126033306

            // GT: [x ẋ θ ω rwd done] = [-3.02683862e-02 -2.21673777e-01 -1.64069915e-02  2.39954642e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd228; ram_i_data1 = 32'hbcf3924f; // x57:-0.029732851311564445
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd229; ram_i_data1 = 32'hbcdb5ae8; // ẋ57:-0.026776745915412903
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd230; ram_i_data1 = 32'hbc7d2502; // θ57:-0.015450717881321907
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd231; ram_i_data1 = 32'hbd43d847; // ω57:-0.04781368002295494

            // GT: [x ẋ θ ω rwd done] = [-3.83617702e-02  1.59132076e-01 -1.22655548e-02 -2.92980467e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd232; ram_i_data1 = 32'hbd1a2ace; // x58:-0.037638477981090546
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd233; ram_i_data1 = 32'hbd142158; // ẋ58:-0.03616461157798767
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd234; ram_i_data1 = 32'hbc4a20e0; // θ58:-0.012336939573287964
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd235; ram_i_data1 = 32'h3b69e9e9; // ω58:0.0035692399833351374

            // GT: [x ẋ θ ω rwd done] = [ 2.60372147e-02 -1.91514875e-01 -3.26943383e-02  2.41064796e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd236; ram_i_data1 = 32'h3cd4c877; // x59:0.025974495336413383
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd237; ram_i_data1 = 32'h3b4d84d5; // ẋ59:0.00313596916384995
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd238; ram_i_data1 = 32'hbd02865c; // θ59:-0.031866416335105896
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd239; ram_i_data1 = 32'hbd298ef4; // ω59:-0.04139609634876251

            // GT: [x ẋ θ ω rwd done] = [ 4.14010259e-02  2.19479958e-01  2.16567486e-02 -2.54484214e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd240; ram_i_data1 = 32'h3d278ed8; // x60:0.040907710790634155
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd241; ram_i_data1 = 32'h3cca0fd7; // ẋ60:0.02466575615108013
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd242; ram_i_data1 = 32'h3cac40aa; // θ60:0.02102692797780037
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd243; ram_i_data1 = 32'h3d00fcbd; // ω60:0.031491030007600784

            // GT: [x ẋ θ ω rwd done] = [-2.90220953e-02  2.06755918e-01 -2.81150091e-02 -3.33226288e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd244; ram_i_data1 = 32'hbcef97a5; // x61:-0.029247114434838295
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd245; ram_i_data1 = 32'h3c3855ef; // ẋ61:0.011250956915318966
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd246; ram_i_data1 = 32'hbce11326; // θ61:-0.02747495099902153
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd247; ram_i_data1 = 32'hbd03157b; // ω61:-0.03200290724635124

            // GT: [x ẋ θ ω rwd done] = [-2.18143330e-02  2.02305213e-01  2.42348982e-02 -2.41645689e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd248; ram_i_data1 = 32'hbcb3efa2; // x62:-0.021964851766824722
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd249; ram_i_data1 = 32'h3bf69c28; // ẋ62:0.007525939494371414
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd250; ram_i_data1 = 32'h3cbf6496; // θ62:0.023363392800092697
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd251; ram_i_data1 = 32'h3d327bfc; // ω62:0.04357527196407318

            // GT: [x ẋ θ ω rwd done] = [ 2.88980154e-02 -2.38723054e-01  2.14767099e-02  3.43479367e-01 1 False]
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd252; ram_i_data1 = 32'h3cf3d42b; // x63:0.02976425550878048
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd253; ram_i_data1 = 32'hbd3167ee; // ẋ63:-0.04331200569868088
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd254; ram_i_data1 = 32'h3ca8aad3; // θ63:0.02058926783502102
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd255; ram_i_data1 = 32'h3d35bf86; // ω63:0.04437210410833359

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd256; ram_i_data1 = 32'b01110010000000000001001100001010; // action 31~0
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd257; ram_i_data1 = 32'b01110101011010111010000111001111; // action 63~32

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd258; ram_i_data1 = 32'd2; new_round = 1'b1; // clear flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;   ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 23 (dummy):
            #11000 new_round = 1'b1;
            #10    new_round = 1'b0;
    end

    // connect ports
        // cliffwalking_step inputs
            assign uut_i_data = ram_o_data2;
        // BRAM inputs
            assign ram_i_wr2   = ~&uut_o_wea;
            assign ram_i_addr2 = uut_o_addr[ADDR_WL-1:2];
            assign ram_i_data2 = uut_o_data;

    Cartpole_Step #(.DATA_WL(DATA_WL), .ADDR_WL(ADDR_WL), .WEA_WL(WEA_WL), .ENV_NUM(ENV_NUM)) uut(
        .i_clk  ( clk  ),
        .i_rstn ( rstn ),
        .i_data ( uut_i_data[DATA_WL-1:0] ),
        .o_data ( uut_o_data[DATA_WL-1:0] ),
        .o_addr ( uut_o_addr[ADDR_WL-1:0] ),
        .o_en   ( uut_o_en ),
        .o_wea  ( uut_o_wea[WEA_WL-1:0] ),
        .o_rstb ( uut_o_rstb )
    );
    My_RAM #(.ADDR_WIDTH(RAM_ADDR_WL), .DATA_WIDTH(DATA_WL)) u_My_RAM(
        .i_clk   ( clk ),
        .i_rstn  ( rstn ),
        .i_wr1   ( ram_i_wr1 ),
        .i_addr1 ( ram_i_addr1[RAM_ADDR_WL-1:0] ),
        .i_data1 ( ram_i_data1[DATA_WL-1:0] ),
        .o_data1 ( ram_o_data1[DATA_WL-1:0] ),
        .i_wr2   ( ram_i_wr2 ),
        .i_addr2 ( ram_i_addr2[RAM_ADDR_WL-1:0] ),
        .i_data2 ( ram_i_data2[DATA_WL-1:0] ),
        .o_data2 ( ram_o_data2[DATA_WL-1:0] )
    );

endmodule
