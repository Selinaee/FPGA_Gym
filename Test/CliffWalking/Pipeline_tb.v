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

module Pipline_tb();

    parameter DATA_WL = 32'd32;
    parameter ADDR_WL = 32'd32;
    parameter WEA_WL  = 32'd4;
    parameter SW_ENV_NUM = 30'd64;
    parameter RAM_ADDR_WL = 12; // if RAM_ADDR_WL is 32, simulation will be very slow 

    reg        clk = 0;
    reg        rstn;
    reg [63:0] clk_cnt;
    reg [63:0] cycle_cnt;

    reg new_round; // a new round of compute is started

    // Pipeline ports
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
        // #10000 $finish;
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
        // round 1:
            #20 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd0;  ram_i_data1 = 32'd40; // ENV  0
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd1;  ram_i_data1 = 32'd20; // ENV  1
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd2;  ram_i_data1 = 32'd47; // ENV  2
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd3;  ram_i_data1 = 32'd1;  // ENV  3
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd4;  ram_i_data1 = 32'd40; // ENV  4
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd5;  ram_i_data1 = 32'd32; // ENV  5
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd6;  ram_i_data1 = 32'd35; // ENV  6
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd7;  ram_i_data1 = 32'd6;  // ENV  7
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd8;  ram_i_data1 = 32'd41; // ENV  8
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd9;  ram_i_data1 = 32'd32; // ENV  9
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd10; ram_i_data1 = 32'd39; // ENV 10
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd11; ram_i_data1 = 32'd25; // ENV 11
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd12; ram_i_data1 = 32'd21; // ENV 12
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd13; ram_i_data1 = 32'd9;  // ENV 13
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd14; ram_i_data1 = 32'd22; // ENV 14
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd15; ram_i_data1 = 32'd2;  // ENV 15
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd16; ram_i_data1 = 32'd19; // ENV 16
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd17; ram_i_data1 = 32'd26; // ENV 17
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd18; ram_i_data1 = 32'd16; // ENV 18
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd19; ram_i_data1 = 32'd7;  // ENV 19
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd20; ram_i_data1 = 32'd17; // ENV 20
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd21; ram_i_data1 = 32'd43; // ENV 21
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd22; ram_i_data1 = 32'd2;  // ENV 22
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd23; ram_i_data1 = 32'd1;  // ENV 23
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd24; ram_i_data1 = 32'd27; // ENV 24
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd25; ram_i_data1 = 32'd6;  // ENV 25
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd26; ram_i_data1 = 32'd35; // ENV 26
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd27; ram_i_data1 = 32'd21; // ENV 27
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd28; ram_i_data1 = 32'd11; // ENV 28
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd29; ram_i_data1 = 32'd21; // ENV 29
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd30; ram_i_data1 = 32'd14; // ENV 30
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd31; ram_i_data1 = 32'd7;  // ENV 31
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd32; ram_i_data1 = 32'd47; // ENV 32
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd33; ram_i_data1 = 32'd3;  // ENV 33
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd34; ram_i_data1 = 32'd1;  // ENV 34
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd35; ram_i_data1 = 32'd8;  // ENV 35
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd36; ram_i_data1 = 32'd8;  // ENV 36
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd37; ram_i_data1 = 32'd6;  // ENV 37
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd38; ram_i_data1 = 32'd7;  // ENV 38
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd39; ram_i_data1 = 32'd7;  // ENV 39
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd40; ram_i_data1 = 32'd5;  // ENV 40
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd41; ram_i_data1 = 32'd30; // ENV 41
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd42; ram_i_data1 = 32'd35; // ENV 42
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd43; ram_i_data1 = 32'd11; // ENV 43
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd44; ram_i_data1 = 32'd47; // ENV 44
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd45; ram_i_data1 = 32'd14; // ENV 45
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd46; ram_i_data1 = 32'd3;  // ENV 46
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd47; ram_i_data1 = 32'd47; // ENV 47
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd48; ram_i_data1 = 32'd12; // ENV 48
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd49; ram_i_data1 = 32'd34; // ENV 49
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd50; ram_i_data1 = 32'd31; // ENV 50
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd51; ram_i_data1 = 32'd43; // ENV 51
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd52; ram_i_data1 = 32'd44; // ENV 52
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd53; ram_i_data1 = 32'd23; // ENV 53
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd54; ram_i_data1 = 32'd14; // ENV 54
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd55; ram_i_data1 = 32'd36; // ENV 55
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd56; ram_i_data1 = 32'd47; // ENV 56
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd57; ram_i_data1 = 32'd46; // ENV 57
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd58; ram_i_data1 = 32'd30; // ENV 58
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd59; ram_i_data1 = 32'd14; // ENV 59
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd60; ram_i_data1 = 32'd29; // ENV 60
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd61; ram_i_data1 = 32'd6;  // ENV 61
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd62; ram_i_data1 = 32'd26; // ENV 62
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd63; ram_i_data1 = 32'd23; // ENV 63

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd64; ram_i_data1 = 32'ha3fa9fa9; // action  0 ~ 15
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd65; ram_i_data1 = 32'h7fcf6557; // action 16 ~ 31
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd66; ram_i_data1 = 32'ha6acba96; // action 32 ~ 47
            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd67; ram_i_data1 = 32'ha8f63450; // action 48 ~ 63

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd68; ram_i_data1 = 32'd2; new_round = 1'b1; // clear flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;  ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 2:
            #18000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd64; ram_i_data1 = 32'h11a4ecf4; // action  0 ~ 15
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd65; ram_i_data1 = 32'hbe929888; // action 16 ~ 31
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd66; ram_i_data1 = 32'hfd489ecf; // action 32 ~ 47
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd67; ram_i_data1 = 32'h240cc7f9; // action 48 ~ 63

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd68; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;  ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 3:
            #18000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd64; ram_i_data1 = 32'h6e8ddd8d; // action  0 ~ 15
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd65; ram_i_data1 = 32'hc1ff6c20; // action 16 ~ 31
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd66; ram_i_data1 = 32'ha9e89cd3; // action 32 ~ 47
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd67; ram_i_data1 = 32'he5e3a040; // action 48 ~ 63

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd68; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;  ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 4:
            #18000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd64; ram_i_data1 = 32'hc30f5d71; // action  0 ~ 15
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd65; ram_i_data1 = 32'h8254085a; // action 16 ~ 31
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd66; ram_i_data1 = 32'h723a48bd; // action 32 ~ 47
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd67; ram_i_data1 = 32'h1ff84c98; // action 48 ~ 63

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd68; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;  ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 5:
            #18000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd64; ram_i_data1 = 32'h766e27f2; // action  0 ~ 15
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd65; ram_i_data1 = 32'h17d4be29; // action 16 ~ 31
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd66; ram_i_data1 = 32'h89fee040; // action 32 ~ 47
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd67; ram_i_data1 = 32'hc864fb73; // action 48 ~ 63

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd68; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;  ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 6:
            #18000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd64; ram_i_data1 = 32'h8a1492e9; // action  0 ~ 15
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd65; ram_i_data1 = 32'hfdcdf5aa; // action 16 ~ 31
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd66; ram_i_data1 = 32'h0b2e1bca; // action 32 ~ 47
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd67; ram_i_data1 = 32'hf6d1ef5e; // action 48 ~ 63

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd68; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;  ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 7:
            #18000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd64; ram_i_data1 = 32'h88c9ad30; // action  0 ~ 15
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd65; ram_i_data1 = 32'hd9999d47; // action 16 ~ 31
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd66; ram_i_data1 = 32'hae0c8b58; // action 32 ~ 47
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd67; ram_i_data1 = 32'hfb4421ee; // action 48 ~ 63

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd68; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;  ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 8:
            #18000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd64; ram_i_data1 = 32'h4ff088fe; // action  0 ~ 15
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd65; ram_i_data1 = 32'hd34956f7; // action 16 ~ 31
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd66; ram_i_data1 = 32'hcca1c0ca; // action 32 ~ 47
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd67; ram_i_data1 = 32'hf10a5d6e; // action 48 ~ 63

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd68; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;  ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 9:
            #18000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd64; ram_i_data1 = 32'hceb80d13; // action  0 ~ 15
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd65; ram_i_data1 = 32'hdb690082; // action 16 ~ 31
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd66; ram_i_data1 = 32'h2ad1a725; // action 32 ~ 47
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd67; ram_i_data1 = 32'h16cc6402; // action 48 ~ 63

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd68; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;  ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 10:
            #18000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd64; ram_i_data1 = 32'hc10d001a; // action  0 ~ 15
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd65; ram_i_data1 = 32'h2b35fdad; // action 16 ~ 31
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd66; ram_i_data1 = 32'hf1defa96; // action 32 ~ 47
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd67; ram_i_data1 = 32'h9fb49dc1; // action 48 ~ 63

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd68; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;  ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 11:
            #18000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd64; ram_i_data1 = 32'ha2db2ff7; // action  0 ~ 15
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd65; ram_i_data1 = 32'h46feba11; // action 16 ~ 31
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd66; ram_i_data1 = 32'h95a58e63; // action 32 ~ 47
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd67; ram_i_data1 = 32'hcec0e8dc; // action 48 ~ 63

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd68; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;  ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 12:
            #18000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd64; ram_i_data1 = 32'h7fe92110; // action  0 ~ 15
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd65; ram_i_data1 = 32'hd1ad4755; // action 16 ~ 31
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd66; ram_i_data1 = 32'hc7a184db; // action 32 ~ 47
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd67; ram_i_data1 = 32'h261af0d3; // action 48 ~ 63

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd68; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;  ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 13:
            #18000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd64; ram_i_data1 = 32'h33fa3412; // action  0 ~ 15
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd65; ram_i_data1 = 32'he6215caa; // action 16 ~ 31
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd66; ram_i_data1 = 32'ha7879b90; // action 32 ~ 47
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd67; ram_i_data1 = 32'hac2ca016; // action 48 ~ 63

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd68; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;  ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 14:
            #18000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd64; ram_i_data1 = 32'h09f4ff71; // action  0 ~ 15
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd65; ram_i_data1 = 32'hed1a1635; // action 16 ~ 31
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd66; ram_i_data1 = 32'hd9b932ae; // action 32 ~ 47
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd67; ram_i_data1 = 32'h7a50352f; // action 48 ~ 63

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd68; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;  ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 15:
            #18000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd64; ram_i_data1 = 32'hf46e09e8; // action  0 ~ 15
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd65; ram_i_data1 = 32'h96c84c8b; // action 16 ~ 31
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd66; ram_i_data1 = 32'ha560b596; // action 32 ~ 47
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd67; ram_i_data1 = 32'h32ff11ee; // action 48 ~ 63

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd68; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;  ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 16:
            #18000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd64; ram_i_data1 = 32'h4af186ab; // action  0 ~ 15
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd65; ram_i_data1 = 32'h9d91e884; // action 16 ~ 31
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd66; ram_i_data1 = 32'h800ecea1; // action 32 ~ 47
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd67; ram_i_data1 = 32'hbb9232c9; // action 48 ~ 63

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd68; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;  ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 17:
            #18000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd64; ram_i_data1 = 32'h10a6a7ee; // action  0 ~ 15
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd65; ram_i_data1 = 32'hceef40ea; // action 16 ~ 31
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd66; ram_i_data1 = 32'hb62644b7; // action 32 ~ 47
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd67; ram_i_data1 = 32'hcef42ed4; // action 48 ~ 63

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd68; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;  ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 18:
            #18000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd64; ram_i_data1 = 32'hcbc1cb43; // action  0 ~ 15
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd65; ram_i_data1 = 32'hfcb35d49; // action 16 ~ 31
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd66; ram_i_data1 = 32'h31deef21; // action 32 ~ 47
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd67; ram_i_data1 = 32'hd31934a7; // action 48 ~ 63

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd68; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;  ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 19:
            #18000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd64; ram_i_data1 = 32'hc96735aa; // action  0 ~ 15
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd65; ram_i_data1 = 32'h5b98b9f3; // action 16 ~ 31
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd66; ram_i_data1 = 32'hd7f4a47e; // action 32 ~ 47
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd67; ram_i_data1 = 32'hdf860c8e; // action 48 ~ 63

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd68; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;  ram_i_data1 = 32'd0; new_round = 1'b0;
        // round 20:
            #18000 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd64; ram_i_data1 = 32'he3d59270; // action  0 ~ 15
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd65; ram_i_data1 = 32'hb72c7c82; // action 16 ~ 31
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd66; ram_i_data1 = 32'h354d04ae; // action 32 ~ 47
            #10    ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd67; ram_i_data1 = 32'hafd18113; // action 48 ~ 63

            #10 ram_i_wr1 = 1'b0; ram_i_addr1 = 32'd68; ram_i_data1 = 32'd1; new_round = 1'b1; // start flag
            #10 ram_i_wr1 = 1'b1; ram_i_addr1 = 32'd0;  ram_i_data1 = 32'd0; new_round = 1'b0;
    end

    // record observations
        integer fpga_ans;
        localparam FPGA_ANS_WD_NUM = SW_ENV_NUM*(u_Pipeline.DST_ENV_WD_NUM-2) +
                                    SW_ENV_NUM*u_Pipeline.RWD_WL/DATA_WL +
                                    SW_ENV_NUM/DATA_WL;
        initial begin
            fpga_ans = $fopen("/data0/FPGA_GYM/verilog/LocalStoreTemplate/LocalStoreTemplate.srcs/sim_1/new/fpga_ans.txt", "w");
            // fpga_ans = $fopen("E:\\OneDrive\\Projects\\Projects_FPGA\\NeurIPS_2024\\CliffWalking.srcs\\sim_1\\new\\fpga_ans.txt", "w");
            #640000 $fclose(fpga_ans);
        end
        always @(posedge new_round or negedge rstn) begin
            if (~rstn) begin
                cycle_cnt <= `ALL1(64);
            end else begin: write_fpga_ans
                reg [DATA_WL : 0] i;
                cycle_cnt <= cycle_cnt + 1;
                if (cycle_cnt[63] == 0) begin // there has been some result in BRAM
                    $fwrite(fpga_ans, "Iteration %d:\n", cycle_cnt);
                    for (i = `ZERO($clog2(SW_ENV_NUM)+1); i < FPGA_ANS_WD_NUM; i = i + 1) begin
                        $fwrite(fpga_ans, "%h%h%h%h ",
                                        u_My_RAM.Memory[u_Pipeline.OUT_INIT_ADDR+i][ 7: 0],
                                        u_My_RAM.Memory[u_Pipeline.OUT_INIT_ADDR+i][15: 8],
                                        u_My_RAM.Memory[u_Pipeline.OUT_INIT_ADDR+i][23:16],
                                        u_My_RAM.Memory[u_Pipeline.OUT_INIT_ADDR+i][31:24]);
                    end
                    $fwrite(fpga_ans, "\n\n");
                end
            end
        end

    // connect ports
        // cliffwalking_step inputs
            assign uut_i_data = ram_o_data2;
        // BRAM inputs
            assign ram_i_wr2   = ~&uut_o_wea;
            assign ram_i_addr2 = uut_o_addr[ADDR_WL-1:2];
            assign ram_i_data2 = uut_o_data;

    Pipeline #(.DATA_WL(DATA_WL), .ADDR_WL(ADDR_WL), .WEA_WL(WEA_WL), .SW_ENV_NUM(SW_ENV_NUM)) u_Pipeline(
        .i_clk   ( clk  ),
        .i_rstn  ( rstn ),
        .i_data  ( uut_i_data[DATA_WL-1:0] ),
        .o_data  ( uut_o_data[DATA_WL-1:0] ),
        .o_addr  ( uut_o_addr[ADDR_WL-1:0] ),
        .o_en    ( uut_o_en ),
        .o_wea   ( uut_o_wea[WEA_WL-1:0] ),
        .o_rstb  ( uut_o_rstb ),
        .i_debug ( 13'd0 ),
        .o_debug ()
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