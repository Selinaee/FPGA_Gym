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

module Pipeline #(parameter DATA_WL = 32'd32, ADDR_WL = 32'd32, WEA_WL = 32'd4, SW_ENV_NUM = 30'd96) (
    input  wire               i_clk,
    input  wire               i_rstn,
    input  wire [DATA_WL-1:0] i_data,
    output wire [DATA_WL-1:0] o_data,
    output wire [ADDR_WL-1:0] o_addr,
    output wire               o_en,
    output wire [WEA_WL-1:0]  o_wea,
    output wire               o_rstb,

    input  wire [12:0]        i_debug,
    output wire [7:0]         o_debug
    );

    // parameter
        localparam RWD_WL = 2, ACT_WL = 1;
        localparam STA_WL = 160; // a multiple of DATA_WL
        localparam OBS_WL = 32;  // a multiple of DATA_WL
        localparam ENV_NUM = 32; // a multiple of DATA_WL and PE_NUM

        localparam SRC_ENV_WD_NUM  = 30'd6; // STA_WL/DATA_WL + 1
        localparam DST_ENV_WD_NUM  = 30'd3; // OBS_WL/DATA_WL + 2
        localparam ACT_INIT_ADDR   = SW_ENV_NUM*(SRC_ENV_WD_NUM-1);
        localparam START_FLAG_ADDR = ACT_INIT_ADDR + (SW_ENV_NUM*ACT_WL/DATA_WL);
        localparam OUT_INIT_ADDR   = START_FLAG_ADDR + 1;
        localparam RWD_INIT_ADDR   = SW_ENV_NUM*(DST_ENV_WD_NUM-2);
        localparam DONE_INIT_ADDR  = RWD_INIT_ADDR + SW_ENV_NUM*RWD_WL/DATA_WL;

        localparam CLR_FLAG = 32'd2;

        localparam ACT_CNT  = SRC_ENV_WD_NUM - 1; // 5
        localparam RWD_CNT  = DST_ENV_WD_NUM - 2; // 1
        localparam DONE_CNT = DST_ENV_WD_NUM - 1; // 2

        localparam CMPT_LATENCY = 32'd16;
        localparam PE_NUM       = 30'd16; // (RWD_WL == DATA_WL) ? CMPT_LATENCY/(DST_ENV_WD_NUM-1) : CMPT_LATENCY/(DST_ENV_WD_NUM-2)

        localparam STA_RAM_ADDR_WL = 9;    // log₂(SW_ENV_NUM/PE_NUM)
        localparam STA_RAM_DATA_WL = 2576; // PE_NUM*(STA_WL+1)

    // for debug (i_debug = {i_sw_n, i_sw_e, i_sw_s, i_sw_w, i_sw_c, i_dip_sw[7:0]})
        localparam DEBUG_RAM_RD_PTR_L = 5'b00001; // 1
        localparam DEBUG_RAM_RD_PTR_H = 5'b00010; // 2
        localparam DEBUG_O_ADDR_WORD0 = 5'b00100; // 4
        localparam DEBUG_O_ADDR_WORD1 = 5'b01000; // 8
        localparam DEBUG_RAM_CARDS    = 5'b10000; // 16
        localparam DEBUG_CMPT_O_OBS1  = 5'b00011; // 3
        localparam DEBUG_CMPT_O_OBS2  = 5'b00101; // 5
        localparam DEBUG_CMPT_O_OBS3  = 5'b00111; // 7
        localparam DEBUG_CMPT_O_OBS4  = 5'b01001; // 9
        localparam DEBUG_ALL_DST_OBS1 = 5'b00110; // 6
        localparam DEBUG_ALL_DST_OBS2 = 5'b01010; // 10
        localparam DEBUG_ALL_DST_OBS3 = 5'b01011; // 11
        localparam DEBUG_ALL_DST_OBS4 = 5'b01100; // 12
        localparam DEBUG_CMPT_O_DST1  = 5'b01101; // 13
        localparam DEBUG_CMPT_O_DST2  = 5'b01110; // 14
        localparam DEBUG_CMPT_O_DST3  = 5'b01111; // 15
        localparam DEBUG_CMPT_O_DST4  = 5'b10001; // 17

    localparam IDLE   = 3'd0;
    localparam RD_ACT = 3'd1; // read 
    localparam RD_REG = 3'd4; // read the first ENV_NUM environment states into all_src_sta and all_init_sta
    localparam RD_RAM = 3'd5; // the rest environment states into u_Src_Sta_RAM
    localparam CMPT   = 3'd2;
    localparam DONE   = 3'd3;
    reg [2:0] last_state, state, next_state;

    wire [ADDR_WL-3:0] o_addr_word;    // the number of line in BRAM being read/written
    reg  [ADDR_WL-3:0] rd_o_addr_word; // the number of line in BRAM being read
    reg  [ADDR_WL-3:0] wt_o_addr_word; // the number of line in BRAM being written

    // Cartpole_Step_Compute ports
        wire                     cmpt_i_ena;
        wire [PE_NUM*STA_WL-1:0] cmpt_i_sta;
        wire [PE_NUM*ACT_WL-1:0] cmpt_i_act;
        wire [PE_NUM*STA_WL-1:0] cmpt_o_sta;
        wire [PE_NUM*OBS_WL-1:0] cmpt_o_obs;
        wire [PE_NUM*RWD_WL-1:0] cmpt_o_rwd;
        wire [PE_NUM-1:0]        cmpt_o_done;
        wire                     cmpt_o_valid;
    // u_Src_Sta_RAM ports
        wire                       src_sta_ram_i_wea;
        wire [STA_RAM_ADDR_WL-1:0] src_sta_ram_i_addra;
        wire [STA_RAM_DATA_WL-1:0] src_sta_ram_i_dina;
        wire [STA_RAM_ADDR_WL-1:0] src_sta_ram_i_addrb;
        wire [STA_RAM_DATA_WL-1:0] src_sta_ram_o_doutb;
    // u_Init_Sta_RAM ports
        wire                       init_sta_ram_i_wea;
        wire [STA_RAM_ADDR_WL-1:0] init_sta_ram_i_addra;
        wire [STA_RAM_DATA_WL-1:0] init_sta_ram_i_dina;
        wire [STA_RAM_ADDR_WL-1:0] init_sta_ram_i_addrb;
        wire [STA_RAM_DATA_WL-1:0] init_sta_ram_o_doutb;

    // store all input data
        reg  [ENV_NUM*STA_WL-1:0] all_init_sta;                 // all initial state (flatten)
        reg                       init_sta_valid;               // all_init_sta is valid
        reg  [ENV_NUM*STA_WL-1:0] all_src_sta;                  // all source state (flatten)
        wire [STA_WL-1:0]         all_src_sta_N  [ENV_NUM-1:0]; // all source state
        wire [STA_WL-1:0]         all_init_sta_N [ENV_NUM-1:0]; // all initial state

        reg  [SW_ENV_NUM*ACT_WL-1:0] all_src_act;  // all source action
        reg  [ENV_NUM-1:0]           all_src_done; // all source done (if 1, this env state need to refresh by reading from BRAM)
        reg                          use_init_sta; // meet CLR_FLAG in IDLE, all PE should use init_sta even though an env is not done

    // store all output data
        reg [PE_NUM*OBS_WL-1:0] all_dst_obs;  // all obseravation from Compute output
        reg [PE_NUM*RWD_WL-1:0] all_dst_rwd;  // all reward from Cartpole_Step_Compute output
        reg [PE_NUM-1:0]        all_dst_done; // all done from Cartpole_Step_Compute output

    // choose one data to write into BRAM from all output data
        reg [$clog2(PE_NUM)-1:0] pe_ptr;
        reg [DATA_WL-1:0]        cmpt_o_dst; // output data being written into BRAM
        reg [DATA_WL-1:0]        dst_rwd, dst_done;
        reg                      write_done;

    reg [ADDR_WL-3:0] src_env_cnt;      // count the number of words in one environment
    reg [ADDR_WL-3:0] src_env_ptr;      // specify which environment is being processed
    reg [ADDR_WL-3:0] last_src_env_cnt; // for timing alignment
    reg [ADDR_WL-3:0] last_src_env_ptr; // for timing alignment

    reg [ADDR_WL-3:0] dst_env_cnt;      // count the number of words in one environment
    reg [ADDR_WL-3:0] dst_env_ptr;      // specify which environment is being processed
    reg [ADDR_WL-3:0] last_dst_env_cnt; // for timing alignment
    reg [ADDR_WL-3:0] last_dst_env_ptr; // for timing alignment

    reg [STA_RAM_ADDR_WL-1:0] sta_ram_wt_ptr;
    reg [STA_RAM_ADDR_WL-1:0] sta_ram_rd_ptr;
    reg [STA_RAM_DATA_WL-1:0] src_sta_ram_i_data;
    reg [$clog2(PE_NUM)-1:0]  rd_ram_cnt;

    reg  [31:0] cmpt_cnt;    // count the clock cycle number of computing
    reg         start_write; // start writing the output data into BRAM
    wire        cmpt_done;

    // connect ports
        // Cartpole_Step outputs
            assign o_data = ~(state == CMPT & start_write) ? `ZERO(DATA_WL) :
                             (dst_env_cnt == RWD_CNT)      ? dst_rwd :
                             (dst_env_cnt == DONE_CNT)     ? dst_done : cmpt_o_dst;
            assign o_addr = {o_addr_word, 2'b00};
            assign o_en   = 1'b1;
            assign o_wea  = ((state == CMPT & start_write) | state == DONE) ? `ALL1(WEA_WL) : `ZERO(WEA_WL);
            assign o_rstb = ~i_rstn;
            assign o_debug = (i_debug[12:8] == DEBUG_RAM_RD_PTR_L) ? sta_ram_rd_ptr[7:0] :
                             (i_debug[12:8] == DEBUG_RAM_RD_PTR_H) ? {`ZERO(7), sta_ram_rd_ptr[8:8]} :
                             (i_debug[12:8] == DEBUG_O_ADDR_WORD0) ? o_addr_word[7:0]  :
                             (i_debug[12:8] == DEBUG_O_ADDR_WORD1) ? o_addr_word[15:8] :
                             (i_debug[12:8] == DEBUG_RAM_CARDS)    ? {src_sta_ram_o_doutb[87:84], src_sta_ram_o_doutb[3:0]} :
                             (i_debug[12:8] == DEBUG_CMPT_O_OBS1)  ? cmpt_o_obs[7:0]    :
                             (i_debug[12:8] == DEBUG_CMPT_O_OBS2)  ? cmpt_o_obs[15:8]   :
                             (i_debug[12:8] == DEBUG_CMPT_O_OBS3)  ? cmpt_o_obs[23:16]  :
                             (i_debug[12:8] == DEBUG_CMPT_O_OBS4)  ? cmpt_o_obs[31:24]  :
                             (i_debug[12:8] == DEBUG_ALL_DST_OBS1) ? all_dst_obs[7:0]   :
                             (i_debug[12:8] == DEBUG_ALL_DST_OBS2) ? all_dst_obs[15:8]  :
                             (i_debug[12:8] == DEBUG_ALL_DST_OBS3) ? all_dst_obs[23:16] :
                             (i_debug[12:8] == DEBUG_ALL_DST_OBS4) ? all_dst_obs[31:24] :
                             (i_debug[12:8] == DEBUG_CMPT_O_DST1)  ? cmpt_o_dst[7:0]    :
                             (i_debug[12:8] == DEBUG_CMPT_O_DST2)  ? cmpt_o_dst[15:8]   :
                             (i_debug[12:8] == DEBUG_CMPT_O_DST3)  ? cmpt_o_dst[23:16]  :
                             (i_debug[12:8] == DEBUG_CMPT_O_DST4)  ? cmpt_o_dst[31:24]  :
                             i_data[7:0];
        // Cartpole_Step_Compute inputs
            assign cmpt_i_ena = (state != CMPT) ? 1'b0 : 1'b1;
            genvar g2; generate
                for (g2 = 0; g2 < PE_NUM; g2 = g2 + 1) begin
                    assign cmpt_i_sta[g2*STA_WL +: STA_WL] = (all_src_done[g2] | use_init_sta) ? all_init_sta[g2*STA_WL +: STA_WL] : all_src_sta[g2*STA_WL +: STA_WL];
                end
            endgenerate
            assign cmpt_i_act = all_src_act[PE_NUM*ACT_WL-1:0];
        // u_Src_Sta_RAM inputs
            assign src_sta_ram_i_wea   = (state == RD_RAM) | (start_write ? write_done : cmpt_done);
            assign src_sta_ram_i_addra = sta_ram_wt_ptr;
            assign src_sta_ram_i_dina  = (state == CMPT) ? {cmpt_o_done, cmpt_o_sta} :
                                         {`ZERO(PE_NUM), i_data, src_sta_ram_i_data[PE_NUM*STA_WL-1:DATA_WL]};
            assign src_sta_ram_i_addrb = (i_debug[12:8] == DEBUG_RAM_CARDS) ? {`ZERO(STA_RAM_ADDR_WL-8), i_debug[7:0]} :
                                         sta_ram_rd_ptr;
        // u_Init_Sta_RAM inputs
            assign init_sta_ram_i_wea   = (state == RD_RAM) | (start_write ? write_done : cmpt_done);
            assign init_sta_ram_i_addra = sta_ram_wt_ptr;
            assign init_sta_ram_i_dina  = (state == CMPT) ? {`ZERO(PE_NUM), all_init_sta[PE_NUM*STA_WL-1:0]} :
                                          {`ZERO(PE_NUM), i_data, src_sta_ram_i_data[PE_NUM*STA_WL-1:DATA_WL]};
            assign init_sta_ram_i_addrb = sta_ram_rd_ptr;

    // for timing alignment
        always @(posedge i_clk or negedge i_rstn) begin
            if (~i_rstn) begin
                last_src_env_cnt <= `ZERO(ADDR_WL-2);
                last_src_env_ptr <= `ZERO(ADDR_WL-2);
                last_dst_env_cnt <= `ZERO(ADDR_WL-2);
                last_dst_env_ptr <= `ZERO(ADDR_WL-2);
            end else begin
                last_src_env_cnt <= src_env_cnt;
                last_src_env_ptr <= src_env_ptr;
                last_dst_env_cnt <= dst_env_cnt;
                last_dst_env_ptr <= dst_env_ptr;
            end
        end

    assign o_addr_word = (state == IDLE) ? START_FLAG_ADDR : // read the start flag
                         (state == RD_REG | state == RD_RAM | state == RD_ACT) ? rd_o_addr_word : // read the source environment data
                         (state == CMPT) ? wt_o_addr_word  : // write the destination environment data
                         (state == DONE) ? START_FLAG_ADDR : // clear the start flag
                         `ZERO(ADDR_WL-2);
    assign cmpt_done   = (state == CMPT) & (cmpt_cnt == CMPT_LATENCY - 1);
    always @(*) begin // set rd_o_addr_word
        if (state == RD_REG | state == RD_RAM | state == RD_ACT) begin
            case (src_env_cnt)
                ACT_CNT: rd_o_addr_word = ACT_INIT_ADDR + (src_env_ptr>>$clog2(DATA_WL/ACT_WL));
                default: rd_o_addr_word = src_env_ptr*(SRC_ENV_WD_NUM-1) + src_env_cnt;
            endcase
        end else begin
            rd_o_addr_word = `ZERO(ADDR_WL-2);
        end
    end
    always @(*) begin // set wt_o_addr_word
        if (state == CMPT) begin
            case (dst_env_cnt)
                RWD_CNT:  wt_o_addr_word = OUT_INIT_ADDR + RWD_INIT_ADDR + (dst_env_ptr>>$clog2(DATA_WL/RWD_WL));
                DONE_CNT: wt_o_addr_word = OUT_INIT_ADDR + DONE_INIT_ADDR + (dst_env_ptr>>$clog2(DATA_WL));
                default:  wt_o_addr_word = OUT_INIT_ADDR + dst_env_ptr*(DST_ENV_WD_NUM-2) + dst_env_cnt;
            endcase
        end else begin
            wt_o_addr_word = OUT_INIT_ADDR;
        end
    end
    always @(posedge i_clk or negedge i_rstn) begin // set src_env_cnt, src_env_ptr
        if (~i_rstn) begin
            src_env_cnt <= `ZERO(ADDR_WL-2);
            src_env_ptr <= `ZERO(ADDR_WL-2);
        end else begin
            case (state)
                IDLE: begin
                    src_env_cnt <= (next_state == IDLE) ? `ZERO(ADDR_WL-2) :
                                   (init_sta_valid & i_data != CLR_FLAG) ? ACT_CNT : `ZERO(ADDR_WL-2);
                    src_env_ptr <= `ZERO(ADDR_WL-2);
                end
                RD_REG: begin
                    // set src_env_cnt
                    src_env_cnt <= (src_env_cnt == SRC_ENV_WD_NUM - 2) ? `ZERO(ADDR_WL-2) : (src_env_cnt + 1);

                    // set src_env_ptr
                    if (src_env_cnt == SRC_ENV_WD_NUM - 2) begin
                        src_env_ptr <= src_env_ptr + 1;
                    end
                end
                RD_RAM: begin
                    // set src_env_cnt
                    if (next_state != RD_RAM) begin
                        src_env_cnt <= ACT_CNT;
                    end else begin
                        src_env_cnt <= (src_env_cnt == SRC_ENV_WD_NUM - 2) ? `ZERO(ADDR_WL-2) : (src_env_cnt + 1);
                    end

                    // set src_env_ptr
                    if (next_state == RD_RAM & src_env_cnt == SRC_ENV_WD_NUM - 2) begin
                        src_env_ptr <= (src_env_ptr == SW_ENV_NUM - 1) ? `ZERO(ADDR_WL-2) : (src_env_ptr + 1);
                    end
                end
                RD_ACT: begin
                    // set src_env_cnt
                    src_env_cnt <= (next_state != RD_ACT) ? `ZERO(ADDR_WL-2) : src_env_cnt;

                    // set src_env_ptr
                    if (next_state == RD_ACT) begin
                        src_env_ptr <= (src_env_ptr == SW_ENV_NUM - DATA_WL/ACT_WL) ? `ZERO(ADDR_WL-2) : (src_env_ptr + DATA_WL/ACT_WL);
                    end
                end
                CMPT: begin
                    if (next_state == CMPT) begin
                        src_env_ptr <= (start_write ? write_done : cmpt_done) ? (src_env_ptr + PE_NUM) : src_env_ptr;
                    end
                end
                DONE: begin
                    src_env_cnt <= `ZERO(ADDR_WL-2);
                    src_env_ptr <= `ZERO(ADDR_WL-2);
                end
                default: begin
                    src_env_cnt <= `ZERO(ADDR_WL-2);
                    src_env_ptr <= `ZERO(ADDR_WL-2);
                end
            endcase
        end
    end
    always @(posedge i_clk or negedge i_rstn) begin // set all_src_sta, all_src_done, all_init_sta, init_sta_valid
        if (~i_rstn) begin
            all_src_sta <= `ZERO(ENV_NUM*STA_WL);
            all_src_done <= `ALL1(ENV_NUM);
            all_init_sta <= `ZERO(ENV_NUM*STA_WL);
            init_sta_valid <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (next_state != IDLE & i_data == CLR_FLAG) begin
                        all_src_done   <= `ALL1(ENV_NUM);
                        init_sta_valid <= 1'b0;
                    end
                end
                RD_REG: begin
                    if (last_state == RD_REG) begin
                        all_src_sta  <= {i_data,  all_src_sta[ENV_NUM*STA_WL-1:DATA_WL]};
                        all_init_sta <= {i_data, all_init_sta[ENV_NUM*STA_WL-1:DATA_WL]};
                        if (last_src_env_ptr != src_env_ptr) begin
                            all_src_done <= {1'b0, all_src_done[ENV_NUM-1:1]};
                        end
                    end
                end
                RD_RAM: begin
                    if (next_state != RD_RAM) begin
                        init_sta_valid <= 1'b1;
                    end
                end
                CMPT: begin
                    if ((start_write ? write_done : cmpt_done) & next_state == CMPT) begin
                        all_init_sta <= {init_sta_ram_o_doutb[PE_NUM*STA_WL-1:0],  all_init_sta[ENV_NUM*STA_WL-1:PE_NUM*STA_WL]};
                        all_src_sta  <= {src_sta_ram_o_doutb[PE_NUM*STA_WL-1:0],    all_src_sta[ENV_NUM*STA_WL-1:PE_NUM*STA_WL]};
                        all_src_done <= {src_sta_ram_o_doutb[STA_RAM_DATA_WL-1:PE_NUM*STA_WL], all_src_done[ENV_NUM-1:PE_NUM]};
                    end
                end
                DONE: begin
                end
                default: begin
                end
            endcase
        end
    end
    genvar g4; generate // set all_src_sta_N, all_init_sta_N
        for (g4 = 0; g4 < ENV_NUM; g4 = g4 + 1) begin
            assign all_src_sta_N[g4] = all_src_sta[g4*STA_WL +: STA_WL];
            assign all_init_sta_N[g4] = all_init_sta[g4*STA_WL +: STA_WL];
        end
    endgenerate
    always @(posedge i_clk or negedge i_rstn) begin // set all_src_act
        if (~i_rstn) begin: reset_src
            all_src_act <= `ZERO(SW_ENV_NUM*ACT_WL);
        end else begin
            case (state)
                RD_ACT: begin
                    if (last_state == RD_ACT) begin
                        case (last_src_env_cnt)
                            ACT_CNT: begin
                                all_src_act <= {i_data, all_src_act[SW_ENV_NUM*ACT_WL-1:DATA_WL]};
                            end
                        endcase
                    end
                end
                CMPT: begin
                    if ((start_write ? write_done : cmpt_done) & next_state == CMPT) begin
                        all_src_act <= {all_src_act[PE_NUM*ACT_WL-1:0], all_src_act[SW_ENV_NUM*ACT_WL-1:PE_NUM*ACT_WL]};
                    end
                end
            endcase
        end
    end
    always @(posedge i_clk or negedge i_rstn) begin // set rd_ram_cnt, src_sta_ram_i_data, sta_ram_wt_ptr, sta_ram_rd_ptr
        if (~i_rstn) begin
            rd_ram_cnt         <= `ZERO($clog2(PE_NUM));
            src_sta_ram_i_data <= `ZERO(STA_RAM_DATA_WL);
            sta_ram_wt_ptr     <= `ZERO(STA_RAM_ADDR_WL);
            sta_ram_rd_ptr     <= ENV_NUM/PE_NUM;
        end else begin
            case (state)
                RD_REG: begin
                    if (next_state != RD_REG) begin
                        sta_ram_wt_ptr <= ENV_NUM/PE_NUM;
                    end
                end
                RD_RAM: begin
                    if (last_src_env_cnt == SRC_ENV_WD_NUM - 2) begin
                        rd_ram_cnt <= (rd_ram_cnt == PE_NUM - 1) ? `ZERO($clog2(PE_NUM)) : (rd_ram_cnt + 1);
                    end
                    src_sta_ram_i_data[PE_NUM*STA_WL-1:0] <= {i_data, src_sta_ram_i_data[PE_NUM*STA_WL-1:DATA_WL]};
                    if (rd_ram_cnt == PE_NUM - 1 & last_src_env_cnt == SRC_ENV_WD_NUM - 2) begin
                        sta_ram_wt_ptr <= (sta_ram_wt_ptr == SW_ENV_NUM/PE_NUM - 1) ? `ZERO(STA_RAM_ADDR_WL) : (sta_ram_wt_ptr + 1);
                    end
                end
                CMPT: begin
                    if (next_state == CMPT & (start_write ? write_done : cmpt_done)) begin
                        sta_ram_wt_ptr <= (sta_ram_wt_ptr == SW_ENV_NUM/PE_NUM - 1) ? `ZERO(STA_RAM_ADDR_WL) : (sta_ram_wt_ptr + 1);
                        sta_ram_rd_ptr <= (sta_ram_rd_ptr == SW_ENV_NUM/PE_NUM - 1) ? `ZERO(STA_RAM_ADDR_WL) : (sta_ram_rd_ptr + 1);
                    end
                end
            endcase
        end
    end
    always @(posedge i_clk or negedge i_rstn) begin // set all_dst_obs, all_dst_rwd, all_dst_done
        if (~i_rstn) begin
            all_dst_obs  <= `ZERO(PE_NUM*OBS_WL);
            all_dst_rwd  <= `ZERO(PE_NUM*RWD_WL);
            all_dst_done <= `ZERO(PE_NUM);
        end else begin
            if (start_write ? write_done : cmpt_done) begin
                all_dst_obs  <= cmpt_o_obs;
                all_dst_rwd  <= cmpt_o_rwd;
                all_dst_done <= cmpt_o_done;
            end else begin
                if (dst_env_cnt == DST_ENV_WD_NUM-3) begin
                    all_dst_rwd  <= {all_dst_rwd[RWD_WL-1:0], all_dst_rwd[PE_NUM*RWD_WL-1:RWD_WL]};
                    all_dst_done <= {all_dst_done[0], all_dst_done[PE_NUM-1:1]};
                end
                if (dst_env_cnt != RWD_CNT & dst_env_cnt != DONE_CNT) begin
                    all_dst_obs <= {all_dst_obs[DATA_WL-1:0], all_dst_obs[PE_NUM*OBS_WL-1:DATA_WL]};
                end
            end
        end
    end
    always @(posedge i_clk or negedge i_rstn) begin // set use_init_sta
        if (~i_rstn) begin
            use_init_sta <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (next_state != IDLE & i_data == CLR_FLAG) begin
                        use_init_sta <= 1'b1;
                    end
                end
                DONE: begin
                    use_init_sta <= 1'b0;
                end
            endcase
        end
    end
    always @(posedge i_clk or negedge i_rstn) begin // set cmpt_cnt
        if (~i_rstn) begin
            cmpt_cnt <= 32'd0;
        end else begin
            if (state == CMPT) begin
                cmpt_cnt <= cmpt_done ? 32'd0 : cmpt_cnt + 1;
            end else begin
                cmpt_cnt <= 32'd0;
            end
        end
    end
    always @(posedge i_clk or negedge i_rstn) begin // set start_write
        if (~i_rstn) begin
            start_write <= 1'd0;
        end else begin
            if (state == CMPT) begin
                // start_write <= (cmpt_done & cmpt_o_valid) ? 1'd1 : start_write;
                start_write <= cmpt_done ? 1'd1 : start_write;
            end else begin
                start_write <= 1'd0;
            end
        end
    end
    generate // set pe_ptr
        if (RWD_WL == DATA_WL) begin
            always @(posedge i_clk or negedge i_rstn) begin
                if (~i_rstn) begin
                    pe_ptr <= `ZERO($clog2(PE_NUM));
                end else begin
                    if (state == CMPT & start_write) begin
                        if (&dst_env_ptr[$clog2(DATA_WL)-1:0]) begin // (dst_env_ptr+1) % DATA_WL == 0, need to write observations, rewards and dones
                            pe_ptr <= (dst_env_cnt != DST_ENV_WD_NUM - 1) ? pe_ptr :
                                    (pe_ptr == PE_NUM - 1) ? `ZERO($clog2(PE_NUM)) : (pe_ptr + 1);
                        end else begin // dst_env_ptr % DATA_WL != 0, need to write observations and rewards
                            pe_ptr <= (dst_env_cnt != DST_ENV_WD_NUM - 2) ? pe_ptr :
                                    (pe_ptr == PE_NUM - 1) ? `ZERO($clog2(PE_NUM)) : (pe_ptr + 1);
                        end
                    end else begin
                        pe_ptr <= `ZERO($clog2(PE_NUM));
                    end
                end
            end
        end else begin
            always @(posedge i_clk or negedge i_rstn) begin
                if (~i_rstn) begin
                    pe_ptr <= `ZERO($clog2(PE_NUM));
                end else begin
                    if (state == CMPT & start_write) begin
                        if (&dst_env_ptr[$clog2(DATA_WL)-1:0]) begin // (dst_env_ptr+1) % DATA_WL == 0, need to write observations, rewards and dones
                            pe_ptr <= (dst_env_cnt != DST_ENV_WD_NUM - 1) ? pe_ptr :
                                    (pe_ptr == PE_NUM - 1) ? `ZERO($clog2(PE_NUM)) : (pe_ptr + 1);
                        end else if (&dst_env_ptr[$clog2(DATA_WL/RWD_WL)-1:0]) begin // (dst_env_ptr+1) % (DATA_WL/RWD_WL) == 0, need to write observations and rewards
                            pe_ptr <= (dst_env_cnt != DST_ENV_WD_NUM - 2) ? pe_ptr :
                                    (pe_ptr == PE_NUM - 1) ? `ZERO($clog2(PE_NUM)) : (pe_ptr + 1);
                        end else begin // dst_env_ptr % (DATA_WL/RWD_WL) != 0, need to write observations
                            pe_ptr <= (dst_env_cnt != DST_ENV_WD_NUM - 3) ? pe_ptr :
                                    (pe_ptr == PE_NUM - 1) ? `ZERO($clog2(PE_NUM)) : (pe_ptr + 1);
                        end
                    end else begin
                        pe_ptr <= `ZERO($clog2(PE_NUM));
                    end
                end
            end
        end
    endgenerate
    generate // set write_done
        if (RWD_WL == DATA_WL) begin
            always @(*) begin
                if (state == CMPT & start_write & pe_ptr == PE_NUM - 1) begin
                    if (&dst_env_ptr[$clog2(DATA_WL)-1:0]) begin // (dst_env_ptr+1) % DATA_WL == 0, need to write observations, rewards and dones
                        write_done = (dst_env_cnt == DST_ENV_WD_NUM - 1);
                    end else begin // dst_env_ptr % DATA_WL != 0, need to write observations and rewards
                        write_done = (dst_env_cnt == DST_ENV_WD_NUM - 2);
                    end
                end else begin
                    write_done = 1'b0;
                end
            end
        end else begin
            always @(*) begin
                if (state == CMPT & start_write & pe_ptr == PE_NUM - 1) begin
                    if (&dst_env_ptr[$clog2(DATA_WL)-1:0]) begin // (dst_env_ptr+1) % DATA_WL == 0, need to write observations, rewards and dones
                        write_done = (dst_env_cnt == DST_ENV_WD_NUM - 1);
                    end else if (&dst_env_ptr[$clog2(DATA_WL/RWD_WL)-1:0]) begin // (dst_env_ptr+1) % (DATA_WL/RWD_WL) == 0, need to write observations and rewards
                        write_done = (dst_env_cnt == DST_ENV_WD_NUM - 2);
                    end else begin // dst_env_ptr % (DATA_WL/RWD_WL) != 0, need to write observations
                        write_done = (dst_env_cnt == DST_ENV_WD_NUM - 3);
                    end
                end else begin
                    write_done = 1'b0;
                end
            end
        end
    endgenerate
    always @(*) begin // set cmpt_o_dst
        case (dst_env_cnt)
            RWD_CNT:  cmpt_o_dst = {`ZERO(DATA_WL-RWD_WL), all_dst_rwd[RWD_WL-1:0]};
            DONE_CNT: cmpt_o_dst = {`ZERO(DATA_WL-1), all_dst_done[0]};
            default:  cmpt_o_dst = all_dst_obs[DATA_WL-1:0];
            // RWD_CNT:  cmpt_o_dst = {`ZERO(DATA_WL-RWD_WL), all_dst_rwd[pe_ptr]};
            // DONE_CNT: cmpt_o_dst = {`ZERO(DATA_WL-1), all_dst_done[pe_ptr]};
            // default:  cmpt_o_dst = all_dst_obs[pe_ptr*OBS_WL+dst_env_cnt*DATA_WL +: DATA_WL];
        endcase
    end
    generate // set dst_rwd, dst_done
        if (RWD_WL == DATA_WL) begin
            always @(posedge i_clk or negedge i_rstn) begin
                if (~i_rstn) begin
                    dst_rwd     <= `ZERO(DATA_WL);
                    dst_done    <= `ZERO(DATA_WL);
                end else begin
                    if (state == CMPT) begin
                        if (dst_env_cnt == DST_ENV_WD_NUM - 3) begin
                            dst_rwd <= all_dst_rwd[RWD_WL-1:0];
                        end
                        if (dst_env_cnt == DST_ENV_WD_NUM - 3) begin
                            dst_done <= |dst_env_ptr[$clog2(DATA_WL)-1:0] ? {all_dst_done[0], dst_done[DATA_WL-1:1]} : {all_dst_done[0], `ZERO(DATA_WL-1)};
                        end
                    end else begin
                        dst_rwd  <= `ZERO(DATA_WL);
                        dst_done <= `ZERO(DATA_WL);
                    end
                end
            end
        end else begin
            always @(posedge i_clk or negedge i_rstn) begin
                if (~i_rstn) begin
                    dst_rwd     <= `ZERO(DATA_WL);
                    dst_done    <= `ZERO(DATA_WL);
                end else begin
                    if (state == CMPT) begin
                        if (dst_env_cnt == DST_ENV_WD_NUM - 3) begin
                            dst_rwd <= |dst_env_ptr[$clog2(DATA_WL/RWD_WL)-1:0] ? {all_dst_rwd[RWD_WL-1:0], dst_rwd[DATA_WL-1:RWD_WL]} : {all_dst_rwd[RWD_WL-1:0], `ZERO(DATA_WL-RWD_WL)};
                        end
                        if (dst_env_cnt == DST_ENV_WD_NUM - 3) begin
                            dst_done <= |dst_env_ptr[$clog2(DATA_WL)-1:0] ? {all_dst_done[0], dst_done[DATA_WL-1:1]} : {all_dst_done[0], `ZERO(DATA_WL-1)};
                        end
                    end else begin
                        dst_rwd  <= `ZERO(DATA_WL);
                        dst_done <= `ZERO(DATA_WL);
                    end
                end
            end
        end
    endgenerate
    generate // set dst_env_cnt, dst_env_ptr
        if (RWD_WL == DATA_WL) begin
            always @(posedge i_clk or negedge i_rstn) begin
                if (~i_rstn) begin
                    dst_env_cnt <= `ZERO(ADDR_WL-2);
                    dst_env_ptr <= `ZERO(ADDR_WL-2);
                end else begin
                    case (state)
                        IDLE: begin
                            dst_env_ptr <= `ZERO(ADDR_WL-2);
                            dst_env_cnt <= `ZERO(ADDR_WL-2);
                        end
                        CMPT: begin
                            if (start_write) begin
                                if (&dst_env_ptr[$clog2(DATA_WL)-1:0]) begin // (dst_env_ptr+1) % DATA_WL == 0, need to write observations, rewards and dones
                                    dst_env_cnt <= (dst_env_cnt == DST_ENV_WD_NUM - 1) ? `ZERO(ADDR_WL-2) : (dst_env_cnt + 1);
                                    dst_env_ptr <= (dst_env_cnt != DST_ENV_WD_NUM - 1) ? dst_env_ptr :
                                                (dst_env_ptr == SW_ENV_NUM - 1) ? `ZERO(ADDR_WL-2) : (dst_env_ptr + 1);
                                end else begin // dst_env_ptr % DATA_WL != 0, need to write observations and rewards
                                    dst_env_cnt <= (dst_env_cnt == DST_ENV_WD_NUM - 2) ? `ZERO(ADDR_WL-2) : (dst_env_cnt + 1);
                                    dst_env_ptr <= (dst_env_cnt != DST_ENV_WD_NUM - 2) ? dst_env_ptr :
                                                (dst_env_ptr == SW_ENV_NUM - 1) ? `ZERO(ADDR_WL-2) : (dst_env_ptr + 1);
                                end
                            end
                        end
                        DONE: begin
                            dst_env_ptr <= `ZERO(ADDR_WL-2);
                            dst_env_cnt <= `ZERO(ADDR_WL-2);
                        end
                        default: begin
                            dst_env_ptr <= `ZERO(ADDR_WL-2);
                            dst_env_cnt <= `ZERO(ADDR_WL-2);
                        end
                    endcase
                end
            end
        end else begin
            always @(posedge i_clk or negedge i_rstn) begin
                if (~i_rstn) begin
                    dst_env_cnt <= `ZERO(ADDR_WL-2);
                    dst_env_ptr <= `ZERO(ADDR_WL-2);
                end else begin
                    case (state)
                        IDLE: begin
                            dst_env_ptr <= `ZERO(ADDR_WL-2);
                            dst_env_cnt <= `ZERO(ADDR_WL-2);
                        end
                        CMPT: begin
                            if (start_write) begin
                                if (&dst_env_ptr[$clog2(DATA_WL)-1:0]) begin // (dst_env_ptr+1) % DATA_WL == 0, need to write observations, rewards and dones
                                    dst_env_cnt <= (dst_env_cnt == DST_ENV_WD_NUM - 1) ? `ZERO(ADDR_WL-2) : (dst_env_cnt + 1);
                                    dst_env_ptr <= (dst_env_cnt != DST_ENV_WD_NUM - 1) ? dst_env_ptr :
                                                (dst_env_ptr == SW_ENV_NUM - 1) ? `ZERO(ADDR_WL-2) : (dst_env_ptr + 1);
                                end else if (&dst_env_ptr[$clog2(DATA_WL/RWD_WL)-1:0]) begin // (dst_env_ptr+1) % (DATA_WL/RWD_WL) == 0, need to write observations and rewards
                                    dst_env_cnt <= (dst_env_cnt == DST_ENV_WD_NUM - 2) ? `ZERO(ADDR_WL-2) : (dst_env_cnt + 1);
                                    dst_env_ptr <= (dst_env_cnt != DST_ENV_WD_NUM - 2) ? dst_env_ptr :
                                                (dst_env_ptr == SW_ENV_NUM - 1) ? `ZERO(ADDR_WL-2) : (dst_env_ptr + 1);
                                end else begin // dst_env_ptr % (DATA_WL/RWD_WL) != 0, need to write observations
                                    dst_env_cnt <= (dst_env_cnt == DST_ENV_WD_NUM - 3) ? `ZERO(ADDR_WL-2) : (dst_env_cnt + 1);
                                    dst_env_ptr <= (dst_env_cnt != DST_ENV_WD_NUM - 3) ? dst_env_ptr :
                                                (dst_env_ptr == SW_ENV_NUM - 1) ? `ZERO(ADDR_WL-2) : (dst_env_ptr + 1);
                                end
                            end
                        end
                        DONE: begin
                            dst_env_ptr <= `ZERO(ADDR_WL-2);
                            dst_env_cnt <= `ZERO(ADDR_WL-2);
                        end
                        default: begin
                            dst_env_ptr <= `ZERO(ADDR_WL-2);
                            dst_env_cnt <= `ZERO(ADDR_WL-2);
                        end
                    endcase
                end
            end
        end
    endgenerate

    // FSM
        always @(posedge i_clk or negedge i_rstn) begin
            if (~i_rstn) begin
                last_state <= IDLE;
                state      <= IDLE;
            end else begin
                last_state <= state;
                state      <= next_state;
            end
        end
        always @(*) begin
            case (state)
                IDLE:    next_state = (last_state != IDLE) ? IDLE :
                                      (i_data == CLR_FLAG) ? RD_REG :
                                      |i_data ? RD_ACT : IDLE;
                // IDLE:    next_state = ((last_state == IDLE) & |i_data) ? RD_ACT : IDLE;
                RD_REG:  next_state = (last_src_env_ptr == ENV_NUM - 1 & last_src_env_cnt == SRC_ENV_WD_NUM - 2) ? RD_RAM : RD_REG;
                RD_RAM:  next_state = (last_src_env_ptr == SW_ENV_NUM - 1 & last_src_env_cnt == SRC_ENV_WD_NUM - 2) ? RD_ACT : RD_RAM;
                RD_ACT:  next_state = (last_src_env_ptr == SW_ENV_NUM - DATA_WL/ACT_WL & last_src_env_cnt == ACT_CNT) ? CMPT : RD_ACT;
                CMPT:    next_state = (dst_env_ptr == SW_ENV_NUM - 1 & dst_env_cnt == DST_ENV_WD_NUM - 1) ? DONE : CMPT;
                DONE:    next_state = IDLE;
                default: next_state = IDLE;
            endcase
        end

    Compute #(.PE_NUM(PE_NUM), .STA_WL(STA_WL), .ACT_WL(ACT_WL), .OBS_WL(OBS_WL), .RWD_WL(RWD_WL)) u_Compute(
        .i_clk   ( i_clk   ),
        .i_rstn  ( i_rstn  ),
        .i_ena   ( cmpt_i_ena ),
        .i_sta   ( cmpt_i_sta[PE_NUM*STA_WL-1:0] ),
        .i_act   ( cmpt_i_act[PE_NUM*ACT_WL-1:0] ),
        .o_sta   ( cmpt_o_sta[PE_NUM*STA_WL-1:0] ),
        .o_obs   ( cmpt_o_obs[PE_NUM*OBS_WL-1:0] ),
        .o_rwd   ( cmpt_o_rwd[PE_NUM*RWD_WL-1:0] ),
        .o_done  ( cmpt_o_done[PE_NUM-1:0] ),
        .o_valid ( cmpt_o_valid )
    );
    Sta_RAM u_Src_Sta_RAM (
        .clka  ( i_clk ),                                    // input  wire            clka
        .ena   ( 1'b1 ),                                     // input  wire            ena
        .wea   ( src_sta_ram_i_wea ),                        // input  wire [0 : 0]    wea
        .addra ( src_sta_ram_i_addra[STA_RAM_ADDR_WL-1:0] ), // input  wire [8 : 0]    addra
        .dina  ( src_sta_ram_i_dina[STA_RAM_DATA_WL-1:0] ),  // input  wire [2575 : 0] dina
        .clkb  ( i_clk ),                                    // input  wire            clkb
        .enb   ( 1'b1 ),                                     // input  wire            enb
        .addrb ( src_sta_ram_i_addrb[STA_RAM_ADDR_WL-1:0] ), // input  wire [8 : 0]    addrb
        .doutb ( src_sta_ram_o_doutb[STA_RAM_DATA_WL-1:0] )  // output wire [2575 : 0] doutb
    );
    Sta_RAM u_Init_Sta_RAM (
        .clka  ( i_clk ),                                     // input  wire            clka
        .ena   ( 1'b1 ),                                      // input  wire            ena
        .wea   ( init_sta_ram_i_wea ),                        // input  wire [0 : 0]    wea
        .addra ( init_sta_ram_i_addra[STA_RAM_ADDR_WL-1:0] ), // input  wire [8 : 0]    addra
        .dina  ( init_sta_ram_i_dina[STA_RAM_DATA_WL-1:0] ),  // input  wire [2575 : 0] dina
        .clkb  ( i_clk ),                                     // input  wire            clkb
        .enb   ( 1'b1 ),                                      // input  wire            enb
        .addrb ( init_sta_ram_i_addrb[STA_RAM_ADDR_WL-1:0] ), // input  wire [8 : 0]    addrb
        .doutb ( init_sta_ram_o_doutb[STA_RAM_DATA_WL-1:0] )  // output wire [2575 : 0] doutb
    );

endmodule
