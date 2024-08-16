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

    reg [DATA_WIDTH-1 : 0] Memory [2**ADDR_WIDTH-1 : 0];

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
endmodule
