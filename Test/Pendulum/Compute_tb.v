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

module Compute_tb();

    localparam PE_NUM = 40, STA_WL = 64, ACT_WL = 32, OBS_WL = 96, RWD_WL = 32;
    localparam TH_WL = 32, TH_DOT_WL = 32, SINTH_WL = 32, COSTH_WL = 32;

    reg clk, rstn;

    // Compute ports
        reg                      cmpt_i_ena;
        wire [PE_NUM*STA_WL-1:0] cmpt_i_sta;
        wire [PE_NUM*ACT_WL-1:0] cmpt_i_act;
        wire [PE_NUM*STA_WL-1:0] cmpt_o_sta;
        wire [PE_NUM*OBS_WL-1:0] cmpt_o_obs;
        wire [PE_NUM*RWD_WL-1:0] cmpt_o_rwd;
        wire [PE_NUM-1:0]        cmpt_o_done;
        wire                     cmpt_o_valid;
    
    // split the input and output signals
        reg  [TH_WL-1:0]     src_th     [PE_NUM-1:0];
        reg  [TH_DOT_WL-1:0] src_th_dot [PE_NUM-1:0];
        reg  [ACT_WL-1:0]    src_act    [PE_NUM-1:0];
        wire [TH_WL-1:0]     dst_th     [PE_NUM-1:0];
        wire [TH_DOT_WL-1:0] dst_th_dot [PE_NUM-1:0];
        wire [COSTH_WL-1:0]  dst_costh  [PE_NUM-1:0];
        wire [SINTH_WL-1:0]  dst_sinth  [PE_NUM-1:0];
        wire [RWD_WL-1:0]    dst_rwd    [PE_NUM-1:0];
        wire [PE_NUM-1:0]    dst_done;
        genvar g1; generate
            for (g1 = 0; g1 < PE_NUM; g1 = g1 + 1) begin
                assign cmpt_i_sta[g1*STA_WL +: STA_WL] = {src_th_dot[g1], src_th[g1]};
                assign cmpt_i_act[g1*ACT_WL +: ACT_WL] = src_act[g1];

                assign dst_th[g1] = cmpt_o_sta[g1*STA_WL +: TH_WL];
                assign {dst_th_dot[g1], dst_sinth[g1], dst_costh[g1]} = cmpt_o_obs[g1*OBS_WL +: OBS_WL];
                assign dst_rwd[g1]  = cmpt_o_rwd[g1*RWD_WL +: RWD_WL];
                assign dst_done[g1] = cmpt_o_done[g1];
            end
        endgenerate

    always #5 clk = ~clk;
    initial begin
        clk = 1'b0; rstn = 1'b1; cmpt_i_ena = 1'b0;
        #10 rstn = 1'b0;
        #10 rstn = 1'b1; cmpt_i_ena = 1'b1;
    end
    initial begin
        // GT: [th, cos, sin, thdot, rwd, done] = [-2.73376699, -0.91798538, -0.39661425, -3.19242382, -7.47048988, False]
        src_th[0]     = 32'hc024bece; // θ0: -2.574145793914795
        src_th_dot[0] = 32'hc039e509; // ω0: -2.904604196548462
        src_act[0]    = 32'h3f44c360; //  0.76860619

        // GT: [th, cos, sin, thdot, rwd, done] = [ 3.12963706, -0.99992853,  0.01195531, -0.01633530, -9.80118825, False]
        src_th[1]     = 32'h4048595b; // θ1: 3.1304538249969482
        src_th_dot[1] = 32'h3dbc18f5; // ω1: 0.09184447675943375
        src_act[1]    = 32'hbf46e25d; // -0.77689153

        // GT: [th, cos, sin, thdot, rwd, done] = [-2.97686924, -0.98646373, -0.16397950,  2.58600926, -10.18719771, False]
        src_th[2]     = 32'hc046cb7c; // θ2: -3.1061697006225586
        src_th_dot[2] = 32'h40140543; // ω2: 2.31282114982605
        src_act[2]    = 32'h3fffc959; //  1.99833214

        // GT: [th, cos, sin, thdot, rwd, done] = [ 1.69464342, -0.12353074,  0.99234074,  2.82841277, -2.76923385, False]
        src_th[3]     = 32'h3fc6d001; // θ3: 1.5532227754592896
        src_th_dot[3] = 32'h3ff13085; // ω3: 1.8842931985855103
        src_act[3]    = 32'h3fa5bf63; //  1.29490316

        // GT: [th, cos, sin, thdot, rwd, done] = [ 0.98430344,  0.55344343,  0.83288682, -0.70887870, -1.23313242, False]
        src_th[4]     = 32'h3f828715; // θ4: 1.0197473764419556
        src_th_dot[4] = 32'hbfb1e6ba; // ω4: -1.3898537158966064
        src_act[4]    = 32'h3e8f562d; //  0.27995434

        // GT: [th, cos, sin, thdot, rwd, done] = [-1.24919660,  0.31608468, -0.94873101, -1.29078758, -1.44035685, False]
        src_th[5]     = 32'hbf97a2d9; // θ5: -1.1846572160720825
        src_th_dot[5] = 32'hbf1b9693; // ω5: -0.607766330242157
        src_act[5]    = 32'h3da082f2; //  0.07837476

        // GT: [th, cos, sin, thdot, rwd, done] = [-0.37835098,  0.92927504, -0.36938858, -0.03358088, -0.15610945, False]
        src_th[6]     = 32'hbec0db25; // θ6: -0.3766719400882721
        src_th_dot[6] = 32'h3ebc501f; // ω6: 0.367798775434494
        src_act[6]    = 32'hbf5633a4; // -0.83672547

        // GT: [th, cos, sin, thdot, rwd, done] = [-2.76706201, -0.93067944, -0.36583576,  1.90821517, -8.64411046, False]
        src_th[7]     = 32'hc03732c1; // θ7: -2.8624727725982666
        src_th_dot[7] = 32'h4007d186; // ω7: 2.1221632957458496
        src_act[7]    = 32'hbd47c561; // -0.04877222

        // GT: [th, cos, sin, thdot, rwd, done] = [-1.55928145,  0.01151462, -0.99993372,  2.03758502, -3.44901012, False]
        src_th[8]     = 32'hbfd4a0ea; // θ8: -1.6611607074737549
        src_th_dot[8] = 32'h4027eb85; // ω8: 2.6237499713897705
        src_act[8]    = 32'h3f8931da; //  1.07183385

        // GT: [th, cos, sin, thdot, rwd, done] = [-2.63386336, -0.87385076, -0.48619425,  1.55975521, -7.67689853, False]
        src_th[9]     = 32'hc02d8ef8; // θ9: -2.711851119995117
        src_th_dot[9] = 32'h3fe5ddf3; // ω9: 1.7958358526229858
        src_act[9]    = 32'h3f026201; //  0.50930792

        // GT: [th, cos, sin, thdot, rwd, done] = [-0.96865615,  0.56640756, -0.82412529, -2.76535082, -1.11488239, False]
        src_th[10]     = 32'hbf549459; // θ10: -0.830388605594635
        src_th_dot[10] = 32'hc003d529; // ω10: -2.059885263442993
        src_act[10]    = 32'hbf818daf; // -1.01213634

        // GT: [th, cos, sin, thdot, rwd, done] = [ 0.56167633,  0.84636348,  0.53260571, -1.65247071, -0.83033579, False]
        src_th[11]     = 32'h3f24f0d6; // θ11: 0.6442998647689819
        src_th_dot[11] = 32'hc002619b; // ω11: -2.0372073650360107
        src_act[11]    = 32'hbee066a7; // -0.43828318

        // GT: [th, cos, sin, thdot, rwd, done] = [ 1.43238836,  0.13796648,  0.99043691,  1.04401934, -1.91791251, False]
        src_th[12]     = 32'h3fb0a9fb; // θ12: 1.3801873922348022
        src_th_dot[12] = 32'h3eb7bd48; // ω12: 0.35886597633361816
        src_act[12]    = 32'hbeaefaaf; // -0.34175631

        // GT: [th, cos, sin, thdot, rwd, done] = [ 1.52323956,  0.04753884,  0.99886942, -0.05991555, -2.38931303, False]
        src_th[13]     = 32'h3fc35bae; // θ13: 1.5262353420257568
        src_th_dot[13] = 32'hbf4611e8; // ω13: -0.7737107276916504
        src_act[13]    = 32'hbe72136d; // -0.23640223

        // GT: [th, cos, sin, thdot, rwd, done] = [-2.79469707, -0.94043267, -0.33997995,  0.60916847, -8.08569385, False]
        src_th[14]     = 32'hc034cf59; // θ14: -2.82515549659729
        src_th_dot[14] = 32'h3f81d46a; // ω14: 1.0142948627471924
        src_act[14]    = 32'hbf928d0d; // -1.14492953

        // GT: [th, cos, sin, thdot, rwd, done] = [ 2.40510374, -0.74083149,  0.67169094, -1.24330413, -6.38793999, False]
        src_th[15]     = 32'h401de7bc; // θ15: 2.467268943786621
        src_th_dot[15] = 32'hbfdde35d; // ω15: -1.7335010766983032
        src_act[15]    = 32'h3e15a426; //  0.14613399

        // GT: [th, cos, sin, thdot, rwd, done] = [-1.36974783,  0.19969681, -0.97985774,  1.02905357, -2.27243757, False]
        src_th[16]     = 32'hbfb5e9e6; // θ16: -1.4212005138397217
        src_th_dot[16] = 32'h3fcad34f; // ω16: 1.5845736265182495
        src_act[16]    = 32'h3f9ecef0; //  1.24069023

        // GT: [th, cos, sin, thdot, rwd, done] = [ 2.63735348, -0.87554234,  0.48314145, -1.26607764, -7.52885548, False]
        src_th[17]     = 32'h402cd792; // θ17: 2.700657367706299
        src_th_dot[17] = 32'hbfc44bdf; // ω17: -1.5335654020309448
        src_act[17]    = 32'hbeb38bca; // -0.35067588

        // GT: [th, cos, sin, thdot, rwd, done] = [-1.22816290,  0.33596861, -0.94187319,  1.88424551, -2.46531656, False]
        src_th[18]     = 32'hbfa94397; // θ18: -1.3223751783370972
        src_th_dot[18] = 32'h402b4e60; // ω18: 2.6766586303710938
        src_act[18]    = 32'hbedf5b75; // -0.43624464

        // GT: [th, cos, sin, thdot, rwd, done] = [-3.16223832, -0.99978691,  0.02064420, -1.91713262, -9.69775523, False]
        src_th[19]     = 32'hc0443f99; // θ19: -3.0663816928863525
        src_th_dot[19] = 32'hbfdb8448; // ω19: -1.7149744033813477
        src_act[19]    = 32'hbf78d65b; // -0.97202080

        // GT: [th, cos, sin, thdot, rwd, done] = [ 2.21858051, -0.60342097,  0.79742283,  2.42724943, -4.78223311, False]
        src_th[20]     = 32'h400638d2; // θ20: 2.0972180366516113
        src_th_dot[20] = 32'h3ffa57cb; // ω20: 1.9558042287826538
        src_act[20]    = 32'hbf970cfe; // -1.18008399

        // GT: [th, cos, sin, thdot, rwd, done] = [-0.88852406,  0.63055825, -0.77614194, -2.30833769, -0.93825596, False]
        src_th[21]     = 32'hbf45ea5a; // θ21: -0.7731071710586548
        src_th_dot[21] = 32'hbfec28a6; // ω21: -1.8449904918670654
        src_act[21]    = 32'h3ece3fe5; //  0.40283123

        // GT: [th, cos, sin, thdot, rwd, done] = [-1.53448404,  0.03630431, -0.99934077,  0.77918273, -2.64750403, False]
        src_th[22]     = 32'hbfc96696; // θ22: -1.5734431743621826
        src_th_dot[22] = 32'h3fa6a35a; // ω22: 1.3018600940704346
        src_act[22]    = 32'h3fc1fad0; //  1.51546669

        // GT: [th, cos, sin, thdot, rwd, done] = [ 2.70513530, -0.90625495,  0.42273158, -2.36920929, -8.58637101, False]
        src_th[23]     = 32'h4034b5cb; // θ23: 2.8235957622528076
        src_th_dot[23] = 32'hc01e733f; // ω23: -2.4757840633392334
        src_act[23]    = 32'hbf5a52b0; // -0.85282421

        // GT: [th, cos, sin, thdot, rwd, done] = [-2.13212849, -0.53231442, -0.84654671,  0.67912078, -4.94031966, False]
        src_th[24]     = 32'hc00aa121; // θ24: -2.1660845279693604
        src_th_dot[24] = 32'h3fc8749d; // ω24: 1.5660587549209595
        src_act[24]    = 32'hbfe2f130; // -1.77298546

        // GT: [th, cos, sin, thdot, rwd, done] = [-1.56734732,  0.00344900, -0.99999404,  0.71552211, -2.73960916, False]
        src_th[25]     = 32'hbfcd3326; // θ25: -1.603123426437378
        src_th_dot[25] = 32'h3fa61524; // ω25: 1.2975201606750488
        src_act[25]    = 32'h3f8f06fb; //  1.11740053

        // GT: [th, cos, sin, thdot, rwd, done] = [ 0.20778631,  0.97849000,  0.20629433, -2.56084871, -1.07179744, False]
        src_th[26]     = 32'h3eabf1bf; // θ26: 0.3358287513256073
        src_th_dot[26] = 32'hc045d3b0; // ω26: -3.091045379638672
        src_act[26]    = 32'h3ff18574; //  1.88688517

        // GT: [th, cos, sin, thdot, rwd, done] = [-0.61855691,  0.81471610, -0.57986003, -2.87058806, -0.73890104, False]
        src_th[27]     = 32'hbef336ce; // θ27: -0.47502750158309937
        src_th_dot[27] = 32'hc010895a; // ω27: -2.258383274078369
        src_act[27]    = 32'hbfe5b3d8; // -1.79455090

        // GT: [th, cos, sin, thdot, rwd, done] = [ 2.50488653, -0.80405849,  0.59455019,  1.28517437, -6.02073241, False]
        src_th[28]     = 32'h401c333f; // θ28: 2.4406278133392334
        src_th_dot[28] = 32'h3f4ce8be; // ω28: 0.8004263639450073
        src_act[28]    = 32'h3be157f4; //  0.00687694

        // GT: [th, cos, sin, thdot, rwd, done] = [ 1.31472974,  0.25327736,  0.96739370, -1.75420904, -2.66945630, False]
        src_th[29]     = 32'h3fb38329; // θ29: 1.4024401903152466
        src_th_dot[29] = 32'hc02983ed; // ω29: -2.648677110671997
        src_act[29]    = 32'h3f8453f8; //  1.03381252

        // GT: [th, cos, sin, thdot, rwd, done] = [-3.15227276, -0.99994296,  0.01067991, -0.40540341, -9.81477046, False]
        src_th[30]     = 32'hc04872bb; // θ30: -3.132002592086792
        src_th_dot[30] = 32'hbe36b0e2; // ω30: -0.1784091293811798
        src_act[30]    = 32'hbfbb9072; // -1.46534562

        // GT: [th, cos, sin, thdot, rwd, done] = [-2.27376266, -0.64648360, -0.76292789, -3.02378082, -4.98587102, False]
        src_th[31]     = 32'hc007d83f; // θ31: -2.1225736141204834
        src_th_dot[31] = 32'hc00c0bc3; // ω31: -2.188217878341675
        src_act[31]    = 32'hbfa7fe54; // -1.31244898

        // GT: [th, cos, sin, thdot, rwd, done] = [ 2.86092449, -0.96087056,  0.27699775, -1.37794960, -8.86363540, False]
        src_th[32]     = 32'h403b8234; // θ32: 2.9298219680786133
        src_th_dot[32] = 32'hbfd5caae; // ω32: -1.6702477931976318
        src_act[32]    = 32'h3f65cf87; //  0.89769787

        // GT: [th, cos, sin, thdot, rwd, done] = [ 0.87785309,  0.63880438,  0.76936918,  3.35556626, -1.26682436, False]
        src_th[33]     = 32'h3f35c776; // θ33: 0.710074782371521
        src_th_dot[33] = 32'h4030ae7d; // ω33: 2.7606499195098877
        src_act[33]    = 32'h3f34e76a; //  0.70665610

        // GT: [th, cos, sin, thdot, rwd, done] = [ 1.82040021, -0.24702014,  0.96901035,  3.17012954, -3.31428552, False]
        src_th[34]     = 32'h3fd4b8ef; // θ34: 1.6618937253952026
        src_th_dot[34] = 32'h40166317; // ω34: 2.3497979640960693
        src_act[34]    = 32'h3efaae30; //  0.48961020

        // GT: [th, cos, sin, thdot, rwd, done] = [ 2.30526195, -0.67019063,  0.74218899,  3.58990407, -5.31237364, False]
        src_th[35]     = 32'h40080c90; // θ35: 2.1257667541503906
        src_th_dot[35] = 32'h40342fb6; // ω35: 2.8154120445251465
        src_act[35]    = 32'h3f69e832; //  0.91369927

        // GT: [th, cos, sin, thdot, rwd, done] = [ 2.61680246, -0.86542910,  0.50103146,  2.59665036, -6.69948097, False]
        src_th[36]     = 32'h401f2a84; // θ36: 2.4869699478149414
        src_th_dot[36] = 32'h40111008; // ω36: 2.266603469848633
        src_act[36]    = 32'hbf580f9c; // -0.84398818

        // GT: [th, cos, sin, thdot, rwd, done] = [ 1.61160805, -0.04080040,  0.99916732,  1.26312065, -2.45895863, False]
        src_th[37]     = 32'h3fc633ad; // θ37: 1.5484520196914673
        src_th_dot[37] = 32'h3f43b7ff; // ω37: 0.7645263075828552
        src_act[37]    = 32'hbfd65f84; // -1.67478991

        // GT: [th, cos, sin, thdot, rwd, done] = [-2.90948011, -0.97318262, -0.23003392,  0.79708540, -8.78658790, False]
        src_th[38]     = 32'hc03cc1e5; // θ38: -2.9493343830108643
        src_th_dot[38] = 32'h3f702b3d; // ω38: 0.9381597638130188
        src_act[38]    = 32'h3c73de9f; //  0.01488462

        // GT: [th, cos, sin, thdot, rwd, done] = [ 1.58899744, -0.01820011,  0.99983436, -1.19366264, -3.01452913, False]
        src_th[39]     = 32'h3fd307f7; // θ39: 1.648680567741394
        src_th_dot[39] = 32'hbfdb8335; // ω39: -1.7149416208267212
        src_act[39]    = 32'hbfc13c30; // -1.50964928
    end

    Compute #(.PE_NUM(PE_NUM), .STA_WL(STA_WL), .ACT_WL(ACT_WL), .RWD_WL(RWD_WL)) u_Compute(
        .i_clk   ( clk ),
        .i_rstn  ( rstn ),
        .i_ena   ( cmpt_i_ena ),
        .i_sta   ( cmpt_i_sta[PE_NUM*STA_WL-1:0] ),
        .i_act   ( cmpt_i_act[PE_NUM*ACT_WL-1:0] ),
        .o_sta   ( cmpt_o_sta[PE_NUM*STA_WL-1:0] ),
        .o_obs   ( cmpt_o_obs[PE_NUM*OBS_WL-1:0] ),
        .o_rwd   ( cmpt_o_rwd[PE_NUM*RWD_WL-1:0] ),
        .o_done  ( cmpt_o_done[PE_NUM-1:0] ),
        .o_valid ( cmpt_o_valid )
    );

endmodule