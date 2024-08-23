`timescale 1ns / 1ps

module Compute_Single_tb;

    // Parameters
    parameter STA_WL = 736;
    parameter ACT_WL = 3;
    parameter OBS_WL = 736;
    parameter RWD_WL = 32;

    // Inputs
    reg i_clk;
    reg i_rstn;
    reg i_ena;
    reg [STA_WL-1:0] i_sta;
    reg [ACT_WL-1:0] i_act;

    // Outputs
    wire [STA_WL-1:0] o_sta;
    wire [OBS_WL-1:0] o_obs;
    wire [RWD_WL-1:0] o_rwd;
    wire o_done;
    wire o_valid;

    // File for saving output data
    integer outfile;

    // for player data
        wire [7:0] player_x;
        wire [7:0] player_y;
        wire [9:0] oxygen;
        wire [2:0] lives;
        wire [2:0] current_divers_count;

        assign player_x = i_sta[735:728];
        assign player_y = i_sta[727:720];
        assign oxygen = i_sta[719:710];
        assign lives = i_sta[709:707];
        assign current_divers_count = i_sta[706:704];

    // for bullets
        wire [7:0] bullet_x[4:0];
        wire [7:0] bullet_y[4:0];
        wire bullet_direction[4:0];
        wire bullet_active[4:0];

        assign bullet_x[0] = i_sta[689:682];
        assign bullet_y[0] = i_sta[681:674];
        assign bullet_direction[0] = i_sta[673];
        assign bullet_active[0] = i_sta[672];

        assign bullet_x[1] = i_sta[657:650];
        assign bullet_y[1] = i_sta[649:642];
        assign bullet_direction[1] = i_sta[641];
        assign bullet_active[1] = i_sta[640];

        assign bullet_x[2] = i_sta[625:618];
        assign bullet_y[2] = i_sta[617:610];
        assign bullet_direction[2] = i_sta[609];
        assign bullet_active[2] = i_sta[608];

        assign bullet_x[3] = i_sta[593:586];
        assign bullet_y[3] = i_sta[585:578];
        assign bullet_direction[3] = i_sta[577];
        assign bullet_active[3] = i_sta[576];

        assign bullet_x[4] = i_sta[561:554];
        assign bullet_y[4] = i_sta[553:546];
        assign bullet_direction[4] = i_sta[545];
        assign bullet_active[4] = i_sta[544];
    
    // for enemies
        wire [7:0] enemy_x[4:0];
        wire [7:0] enemy_y[4:0];
        wire [0:0] enemy_type[4:0];
        wire [0:0] enemy_active[4:0];

        assign enemy_x[0] = i_sta[530:523];
        assign enemy_y[0] = i_sta[522:515];
        assign enemy_type[0] = i_sta[513];
        assign enemy_active[0] = i_sta[512];

        assign enemy_x[1] = i_sta[498:491];
        assign enemy_y[1] = i_sta[490:483];
        assign enemy_type[1] = i_sta[481];
        assign enemy_active[1] = i_sta[480];

        assign enemy_x[2] = i_sta[466:459];
        assign enemy_y[2] = i_sta[458:451];
        assign enemy_type[2] = i_sta[449];
        assign enemy_active[2] = i_sta[448];

        assign enemy_x[3] = i_sta[434:427];
        assign enemy_y[3] = i_sta[426:419];
        assign enemy_type[3] = i_sta[417];
        assign enemy_active[3] = i_sta[416];

        assign enemy_x[4] = i_sta[402:395];
        assign enemy_y[4] = i_sta[394:387];
        assign enemy_type[4] = i_sta[385];
        assign enemy_active[4] = i_sta[384];

    // for divers
        wire [7:0] diver_x[4:0];
        wire [7:0] diver_y[4:0];
        wire [0:0] diver_active[4:0];

        assign diver_x[0] = i_sta[369:362];
        assign diver_y[0] = i_sta[361:354];
        assign diver_active[0] = i_sta[352];

        assign diver_x[1] = i_sta[337:330];
        assign diver_y[1] = i_sta[329:322];
        assign diver_active[1] = i_sta[320];

        assign diver_x[2] = i_sta[305:298];
        assign diver_y[2] = i_sta[297:290];
        assign diver_active[2] = i_sta[288];

        assign diver_x[3] = i_sta[273:266];
        assign diver_y[3] = i_sta[265:258];
        assign diver_active[3] = i_sta[256];

        assign diver_x[4] = i_sta[241:234];
        assign diver_y[4] = i_sta[233:226];
        assign diver_active[4] = i_sta[224];

    // for enemy bullets
        wire [7:0] enemy_bullet_x[4:0];
        wire [7:0] enemy_bullet_y[4:0];
        wire [0:0] enemy_bullet_active[4:0];

        assign enemy_bullet_x[0] = i_sta[209:202];
        assign enemy_bullet_y[0] = i_sta[201:194];
        assign enemy_bullet_active[0] = i_sta[192];

        assign enemy_bullet_x[1] = i_sta[177:170];
        assign enemy_bullet_y[1] = i_sta[169:162];
        assign enemy_bullet_active[1] = i_sta[160];

        assign enemy_bullet_x[2] = i_sta[145:138];
        assign enemy_bullet_y[2] = i_sta[137:130];
        assign enemy_bullet_active[2] = i_sta[128];

        assign enemy_bullet_x[3] = i_sta[113:106];
        assign enemy_bullet_y[3] = i_sta[105:98];
        assign enemy_bullet_active[3] = i_sta[96];

        assign enemy_bullet_x[4] = i_sta[81:74];
        assign enemy_bullet_y[4] = i_sta[73:66];
        assign enemy_bullet_active[4] = i_sta[64];

    // for patrol submarine
        wire [7:0] patrol_submarine_x;
        wire [7:0] patrol_submarine_y;
        wire patrol_submarine_active;

        assign patrol_submarine_x = i_sta[49:42];
        assign patrol_submarine_y = i_sta[41:34];
        assign patrol_submarine_active = i_sta[32];
    // for score
        wire [31:0] score;
            assign score = i_sta[31:0];
    // Instantiate the Unit Under Test (UUT)
    Compute_Single #(
        .STA_WL(STA_WL),
        .ACT_WL(ACT_WL),
        .OBS_WL(OBS_WL),
        .RWD_WL(RWD_WL)
    ) uut (
        .i_clk(i_clk),
        .i_rstn(i_rstn),
        .i_ena(i_ena),
        .i_sta(i_sta),
        .i_act(i_act),
        .o_sta(o_sta),
        .o_obs(o_obs),
        .o_rwd(o_rwd),
        .o_done(o_done),
        .o_valid(o_valid)
    );

    // Clock generation
    always #5 i_clk = ~i_clk;  // 10ns clock period (100MHz)
    reg [3:0] i;
    // Test vectors
    initial begin
        // Initialize inputs
        i_clk = 0;
        i_rstn = 0;
        i_ena = 0;
        i_sta = 0;
        i_act = 0;

        // Open a file to store the output results
        outfile = $fopen("simulation_output.json", "w");
        if (!outfile) begin
            $display("Error opening file!");
            $finish;
        end

        // Apply reset
        #10;
        i_rstn = 1;
        
        // Initialize i_sta with initial values
        i_sta[735:704] = {8'd81, 8'd40, 10'd800, 3'd1, 3'd2};  // player data
        i_sta[703:672] = {8'd120, 8'd40, 1'b0, 1'b1};  // bullet 0
        i_sta[671:640] = {8'd130, 8'd45, 1'b1, 1'b1};  // bullet 1
        i_sta[639:608] = {8'd140, 8'd50, 1'b0, 1'b0};  // bullet 2
        i_sta[607:576] = {8'd150, 8'd55, 1'b1, 1'b1};  // bullet 3
        i_sta[575:544] = {8'd160, 8'd60, 1'b0, 1'b1};  // bullet 4
        i_sta[543:512] = {1'b1, 4'd15, 8'd70, 8'd100, 1'b1, 1'b1, 1'b1};  // enemy 0
        i_sta[511:480] = {1'b0, 4'd14, 8'd80, 8'd110, 1'b0, 1'b0, 1'b1};  // enemy 1
        i_sta[479:448] = {1'b0, 4'd5, 8'd90, 8'd120, 1'b1, 1'b1, 1'b1};   // enemy 2
        i_sta[447:416] = {1'b0, 4'd8, 8'd100, 8'd130, 1'b0, 1'b1, 1'b1};  // enemy 3
        i_sta[415:384] = {1'b0, 4'd12, 8'd110, 8'd140, 1'b1, 1'b0, 1'b1}; // enemy 4
        i_sta[383:352] = {8'd150, 8'd90, 1'b0, 1'b1};  // diver 0
        i_sta[351:320] = {8'd160, 8'd95, 1'b1, 1'b1};  // diver 1
        i_sta[319:288] = {8'd170, 8'd100, 1'b0, 1'b0}; // diver 2
        i_sta[287:256] = {8'd180, 8'd105, 1'b1, 1'b1}; // diver 3
        i_sta[255:224] = {8'd190, 8'd110, 1'b0, 1'b1}; // diver 4
        i_sta[223:192] = {8'd200, 8'd70, 1'b0, 1'b1};  // enemy_bullet 0
        i_sta[191:160] = {8'd210, 8'd75, 1'b1, 1'b1};  // enemy_bullet 1
        i_sta[159:128] = {8'd220, 8'd80, 1'b0, 1'b0};  // enemy_bullet 2
        i_sta[127:96]  = {8'd230, 8'd85, 1'b1, 1'b1};  // enemy_bullet 3
        i_sta[95:64]   = {8'd239, 8'd90, 1'b0, 1'b1};  // enemy_bullet 4
        i_sta[63:32]   = {8'd3, 1'b1, 8'd80, 8'd10, 1'b0, 1'b1};  // patrol_submarine
        i_sta[31:0]    = 32'd10000;  // score

        // Repeat the process for multiple cycles
        repeat (100) begin
            // Enable the compute for one cycle
            i_ena = 1;
            i_act = 3'b011;

            // Wait for the outputs to stabilize
            #75;

            // Write the key data in JSON-like format
            $fwrite(outfile, "{\n");
            $fwrite(outfile, "  \"player\": {\n");
            $fwrite(outfile, "    \"x\": %d,\n", player_x);
            $fwrite(outfile, "    \"y\": %d,\n", player_y);
            $fwrite(outfile, "    \"oxygen\": %d,\n", oxygen);
            $fwrite(outfile, "    \"lives\": %d,\n", lives);
            $fwrite(outfile, "    \"current_divers_count\": %d\n", current_divers_count);
            $fwrite(outfile, "  },\n");

            $fwrite(outfile, "  \"bullets\": [\n");
            for (i = 0; i < 5; i = i + 1) begin
                $fwrite(outfile, "    {\"x\": %d, \"y\": %d, \"direction\": %b, \"active\": %b}%s\n",
                        bullet_x[i], bullet_y[i], bullet_direction[i], bullet_active[i], (i == 4) ? "" : ",");
            end
            $fwrite(outfile, "  ],\n");

            $fwrite(outfile, "  \"enemy_bullets\": [\n");
            for (i = 0; i < 5; i = i + 1) begin
                $fwrite(outfile, "    {\"x\": %d, \"y\": %d, \"active\": %b}%s\n",
                        enemy_bullet_x[i], enemy_bullet_y[i], enemy_bullet_active[i], (i == 4) ? "" : ",");
            end
            $fwrite(outfile, "  ],\n");

            $fwrite(outfile, "  \"enemies\": [\n");
            for (i = 0; i < 5; i = i + 1) begin
                $fwrite(outfile, "    {\"x\": %d, \"y\": %d, \"type\": %b, \"active\": %b}%s\n",
                        enemy_x[i], enemy_y[i], enemy_type[i], enemy_active[i], (i == 4) ? "" : ",");
            end
            $fwrite(outfile, "  ],\n");

            $fwrite(outfile, "  \"divers\": [\n");
            for (i = 0; i < 5; i = i + 1) begin
                $fwrite(outfile, "    {\"x\": %d, \"y\": %d, \"active\": %b}%s\n",
                        diver_x[i], diver_y[i], diver_active[i], (i == 4) ? "" : ",");
            end
            $fwrite(outfile, "  ],\n");

            $fwrite(outfile, "  \"patrol_submarine\": {\n");
            $fwrite(outfile, "    \"x\": %d,\n", patrol_submarine_x);
            $fwrite(outfile, "    \"y\": %d,\n", patrol_submarine_y);
            $fwrite(outfile, "    \"active\": %b\n", patrol_submarine_active);
            $fwrite(outfile, "  },\n");

            $fwrite(outfile, "  \"score\": %d\n", score);
            $fwrite(outfile, "},\n\n");

            // Feed the next input with the current output
            i_sta = o_sta;

            // Wait for some time before the next iteration
            #10;
            i_ena = 1;
        end

        // Close the file and end simulation
        $fclose(outfile);
        $finish;
    end

endmodule