`timescale 1ns / 1ps

module TaxiStep(
    input clk,
    input reset,
    input [2:0] action,
    input [2:0] taxi_row_in,
    input [2:0] taxi_col_in,
    input [2:0] pass_idx_in,
    input [1:0] dest_idx_in,
    output reg [2:0] taxi_row_out,
    output reg [2:0] taxi_col_out,
    output reg [2:0] pass_idx_out,
    output reg [1:0] dest_idx_out,
    output reg [1:0] reward, //3 types of reward: 0(-1), 1(-10), 2(20)
    output reg terminated
);

// 参数定义
parameter MAX_ROW = 4;  // 最大行
parameter MAX_COL = 4;  // 最大列

// reg [4:0] map [0:MAX_ROW] = {
//     5'b01110,  // 行0
//     5'b00000,  // 行1
//     5'b00100,  // 行2
//     5'b00000,  // 行3
//     5'b00010   // 行4
// };
// reg [4:0] map_row_1 = 5'b01110;
// reg [4:0] map_row_2 = 5'b00000;
// reg [4:0] map_row_3 = 5'b00100;
// reg [4:0] map_row_4 = 5'b00000;
// reg [4:0] map_row_5 = 5'b00010;

// reg [24:0] map = {map_row_1[4:0], map_row_2[4:0], map_row_3[4:0], map_row_4[4:0], map_row_5[4:0]};
reg[24:0] map = 25'b0111000000010000000000100;
reg [2:0] pass_row;
reg [2:0] pass_col;
reg [2:0] dest_row;
reg [2:0] dest_col;

always@(*) begin
    case (pass_idx_in)
        0: begin
            pass_row = 0;
            pass_col = 0;
        end
        1: begin
            pass_row = 0;
            pass_col = 4;
        end
        2: begin
            pass_row = 4;
            pass_col = 0;
        end
        3: begin
            pass_row = 4;
            pass_col = 3;
        end
        4: begin
            pass_row = 0;
            pass_col = 0;
        end
    endcase
    case (dest_idx_in)
        0: begin
            dest_row = 0;
            dest_col = 0;
        end
        1: begin
            dest_row = 0;
            dest_col = 4;
        end
        2: begin
            dest_row = 4;
            dest_col = 0;
        end
        3: begin
            dest_row = 4;
            dest_col = 3;
        end
    endcase
end

always @(posedge clk) begin
    if (reset) begin
        // Reset logic
        taxi_row_out <= 0;
        taxi_col_out <= 0;
        pass_idx_out <= 0;
        dest_idx_out <= 0;
        reward <= 0;
        terminated <= 0;
    end else begin
        // Default outputs

        dest_idx_out <= dest_idx_in;
        case (action)
            0: begin// South
                reward <= 0;
                terminated <= 0;
                pass_idx_out <= pass_idx_in;
                if (taxi_row_in < MAX_ROW && map[(5*(taxi_row_in + 1)+(taxi_col_in))] == 0)begin
                    taxi_row_out <= taxi_row_in + 1;
                    taxi_col_out <= taxi_col_in;
                end
                else begin
                    taxi_row_out <= taxi_row_in;
                    taxi_col_out <= taxi_col_in;
                end
            end
            1: begin// North
                reward <= 0;
                terminated <= 0;
                pass_idx_out <= pass_idx_in;
                if (taxi_row_in > 0 && map[(5*(taxi_row_in - 1)+(taxi_col_in))] == 0)begin
                    taxi_row_out <= taxi_row_in - 1;
                    taxi_col_out <= taxi_col_in;
                end
                else begin
                    taxi_row_out <= taxi_row_in;
                    taxi_col_out <= taxi_col_in;
                end
            end
            2: begin// East
                reward <= 0;
                terminated <= 0;
                pass_idx_out <= pass_idx_in;
                if (taxi_col_in < MAX_COL && map[(5*taxi_row_in+(taxi_col_in + 1))] == 0) begin
                    taxi_col_out <= taxi_col_in + 1;
                    taxi_row_out <= taxi_row_in;
                end
                else begin
                    taxi_col_out <= taxi_col_in;
                    taxi_row_out <= taxi_row_in;
                end
            end
            3: begin// West
                reward <= 0;
                terminated <= 0;
                pass_idx_out <= pass_idx_in;
                if (taxi_col_in > 0 && map[(5*taxi_row_in+(taxi_col_in - 1))] == 0) begin
                    taxi_col_out <= taxi_col_in - 1;
                    taxi_row_out <= taxi_row_in;
                end
                else begin
                    taxi_col_out <= taxi_col_in;
                    taxi_row_out <= taxi_row_in;
                end
            end
            4: begin// Pickup
                reward <= 1;  // Assuming pickup is always 1 for simplicity here
                taxi_row_out <= taxi_row_in;
                taxi_col_out <= taxi_col_in;
                terminated <= 0;
                if ((pass_idx_in < 4) && (taxi_row_in == pass_row) && (taxi_col_in == pass_col)) begin
                    pass_idx_out <= 4;
                end
                else begin
                    pass_idx_out <= pass_idx_in;
                end
            end
            5: begin// Dropoff
                taxi_row_out <= taxi_row_in;
                taxi_col_out <= taxi_col_in;
                if ((pass_idx_in == 4) && (taxi_row_in == dest_row) && (taxi_col_in == dest_col)) begin
                    terminated <= 1;
                    reward <= 2;
                    pass_idx_out <= dest_idx_in;
                end 
                else begin
                    terminated <= 0;
                    reward <= 1;
                    pass_idx_out <= pass_idx_in;
                end
            end
        endcase
    end
end

endmodule
