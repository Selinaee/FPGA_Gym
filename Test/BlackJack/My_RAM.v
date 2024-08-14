`timescale 1ns/1ps

module My_RAM #(parameter ADDR_WIDTH = 10, DATA_WIDTH = 48) (
    input i_clk,
    input i_rstn,

    input i_wr1,
    input [ADDR_WIDTH - 1 : 0] i_addr1,
    input [DATA_WIDTH - 1 : 0] i_data1,
    output reg [DATA_WIDTH - 1 : 0] o_data1,

    input i_wr2,
    input [ADDR_WIDTH - 1 : 0] i_addr2,
    input [DATA_WIDTH - 1 : 0] i_data2,
    output reg [DATA_WIDTH - 1 : 0] o_data2
    );

    // reg [DATA_WIDTH-1 : 0] Memory [2**ADDR_WIDTH-1 : 0];
    reg [DATA_WIDTH-1 : 0] Memory [1200-1 : 0];

    always @(posedge i_clk or negedge i_rstn) begin
        if (~i_rstn) begin: reset1
            reg [ADDR_WIDTH - 1 : 0] j;
            for (j = 0; j < 2**ADDR_WIDTH - 1; j = j + 1) begin
                Memory[j] <= 640'd0;
            end
            Memory[2**ADDR_WIDTH - 1] <= 640'd0;
        end else if (~i_wr1) begin
            Memory[i_addr1] <= i_data1;
        end
        o_data1 <= Memory[i_addr1];
    end

    always @(posedge i_clk or negedge i_rstn) begin
        if (~i_rstn) begin: reset2
            reg [ADDR_WIDTH - 1 : 0] j;
            for (j = 0; j < 2**ADDR_WIDTH - 1; j = j + 1) begin
                Memory[j] <= 640'd0;
            end
            Memory[2**ADDR_WIDTH - 1] <= 640'd0;
        end else if (~i_wr2) begin
            Memory[i_addr2] <= i_data2;
        end
        o_data2 <= Memory[i_addr2];
    end

    localparam SW_ENV_NUM = 192;
    localparam STA_WD_NUM = 5;
    localparam OBS_WD_NUM = 1;
    localparam ACT_WL     = 1;
    localparam RWD_WL     = 2;

    localparam ACT_INIT_ADDR   = SW_ENV_NUM*STA_WD_NUM;
    localparam START_FLAG_ADDR = ACT_INIT_ADDR + (SW_ENV_NUM*ACT_WL/DATA_WIDTH);
    localparam OUT_INIT_ADDR   = START_FLAG_ADDR + 1;
    localparam RWD_INIT_ADDR   = OUT_INIT_ADDR + SW_ENV_NUM*OBS_WD_NUM;
    localparam DONE_INIT_ADDR  = RWD_INIT_ADDR + SW_ENV_NUM*RWD_WL/DATA_WIDTH;

    wire [DATA_WIDTH-1:0] sta [ACT_INIT_ADDR-1:0];
    wire [DATA_WIDTH-1:0] act [SW_ENV_NUM*ACT_WL/DATA_WIDTH-1:0];
    wire [DATA_WIDTH-1:0] obs [SW_ENV_NUM*OBS_WD_NUM-1:0];
    wire [DATA_WIDTH-1:0] rwd [SW_ENV_NUM*RWD_WL/DATA_WIDTH-1:0];
    wire [DATA_WIDTH-1:0] done [SW_ENV_NUM/DATA_WIDTH-1:0];
    wire [DATA_WIDTH-1:0] start_flag;
    genvar g1; generate
        for (g1 = 0; g1 < ACT_INIT_ADDR; g1 = g1 + 1) begin
            assign sta[g1] = Memory[g1];
        end
        for (g1 = ACT_INIT_ADDR; g1 < START_FLAG_ADDR; g1 = g1 + 1) begin
            assign act[g1-ACT_INIT_ADDR] = Memory[g1];
        end
        for (g1 = OUT_INIT_ADDR; g1 < RWD_INIT_ADDR; g1 = g1 + 1) begin
            assign obs[g1-OUT_INIT_ADDR] = Memory[g1];
        end
        for (g1 = RWD_INIT_ADDR; g1 < DONE_INIT_ADDR; g1 = g1 + 1) begin
            assign rwd[g1-RWD_INIT_ADDR] = Memory[g1];
        end
        for (g1 = DONE_INIT_ADDR; g1 < DONE_INIT_ADDR+SW_ENV_NUM/DATA_WIDTH; g1 = g1 + 1) begin
            assign done[g1-DONE_INIT_ADDR] = Memory[g1];
        end
        assign start_flag = Memory[START_FLAG_ADDR];
    endgenerate

endmodule
