`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/26/2024 12:10:43 PM
// Design Name: 
// Module Name: tb_Cartpole_Step_Compute
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_Cartpole_Step_Compute_Single();

  // Parameters
  localparam  TAU        = 32'b00111100101000111101011100001010;
  localparam  GRAVITY    = 32'b01000001000111001100110011001101;
  localparam  CNST_2     = 32'b00111101001110100010111010001100;
  localparam  CNST_3     = 32'b00111111001010101010101010101011;
  localparam  CNST_4     = 32'b01000000000110011001100110011010;
  localparam  CNST_N4    = 32'b11000000000110011001100110011010;
  localparam  CNST_5     = 32'b00111110010101101000011100101011;
  localparam  CNST_N5    = 32'b10111110010101101000011100101011;
  localparam  INPUT_BIT  = 32'd32;
  localparam  OUTPUT_BIT = 32'd32;

  //Ports
  reg  aclk;
  reg  i_signal;
  reg   [INPUT_BIT-1:0] i_action;
  reg   [INPUT_BIT-1:0] i_x;
  reg   [INPUT_BIT-1:0] i_x_dot;
  reg   [INPUT_BIT-1:0] i_float_theta;
  reg   [INPUT_BIT-1:0] i_theta_dot;
  wire  [OUTPUT_BIT-1:0] o_next_x;
  wire  [OUTPUT_BIT-1:0] o_next_x_dot;
  wire  [OUTPUT_BIT-1:0] o_next_float_theta;
  wire  [OUTPUT_BIT-1:0] o_next_theta_dot;
  wire  [OUTPUT_BIT-1:0] o_terminated;
  wire  [OUTPUT_BIT-1:0] o_reward;
  wire  [OUTPUT_BIT-1:0] o_valid;

  Cartpole_Step_Compute_Single # (
    .TAU(TAU),
    .GRAVITY(GRAVITY),
    .CNST_2(CNST_2),
    .CNST_3(CNST_3),
    .CNST_4(CNST_4),
    .CNST_N4(CNST_N4),
    .CNST_5(CNST_5),
    .CNST_N5(CNST_N5),
    .INPUT_BIT(INPUT_BIT),
    .OUTPUT_BIT(OUTPUT_BIT)
  )
  Cartpole_Step_Compute_Single_inst (
    .aclk(aclk),
    .i_signal(i_signal),
    .i_action(i_action),
    .i_x(i_x),
    .i_x_dot(i_x_dot),
    .i_float_theta(i_float_theta),
    .i_theta_dot(i_theta_dot),
    .o_next_x(o_next_x),
    .o_next_x_dot(o_next_x_dot),
    .o_next_float_theta(o_next_float_theta),
    .o_next_theta_dot(o_next_theta_dot),
    .o_terminated(o_terminated),
    .o_reward(o_reward),
    .o_valid(o_valid)
  );

always #5  aclk = ! aclk ;
initial begin
    aclk = 0;
    #5
    i_signal      = 1;
    i_action      = 32'h00000001;

//    i_action      = 32'h00000000;
    i_x           = 32'hBDDA4B6F; 
    i_x_dot       = 32'hBE7002B9; 
    i_float_theta = 32'h3E53E72E; 
    i_theta_dot   = 32'h3F5F1AFC; 
end
  
endmodule