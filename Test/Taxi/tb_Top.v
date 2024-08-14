`timescale 1ns / 1ps
//`include "encoder.v"
//`include "taxi_step.v"
//`include "decoder.v"
`include "Top.v"

module Top_tb;

  // Parameters

  //Ports
  reg  clk;
  reg  reset;
  reg [2:0] action;
  reg [8:0] agent_state;
  wire [8:0] next_agnet_state;
  wire [1:0] reward;
  wire  terminated;

  Top  Top_inst (
    .clk(clk),
    .reset(reset),
    .action(action),
    .agent_state(agent_state),
    .next_agnet_state(next_agnet_state),
    .reward(reward),
    .terminated(terminated)
  );


  always #5  clk = ! clk ;
  initial begin
      clk = 0;
      reset = 1;
      action = 0;
      #10
      reset = 0;

      agent_state = 'd451;
      action = 'd3;
      #10
      $display("next_agent_state = %d, reward = %d, terminated = %d", next_agnet_state, reward, terminated);

      #10
      agent_state = 'd431;
      action = 'd2;
      #10
      $display("next_agent_state = %d, reward = %d, terminated = %d", next_agnet_state, reward, terminated);

      #10
      agent_state = 'd451;
      action = 'd4;
      #10
      $display("next_agent_state = %d, reward = %d, terminated = %d", next_agnet_state, reward, terminated);

      #10
      agent_state = 'd451;
      action = 'd2;
      #10
      $display("next_agent_state = %d, reward = %d, terminated = %d", next_agnet_state, reward, terminated);

      #10
      agent_state = 'd451;
      action = 'd5;
      #10
      $display("next_agent_state = %d, reward = %d, terminated = %d", next_agnet_state, reward, terminated);

      #10
      agent_state = 'd441;
      action = 'd1;
      #10
      $display("next_agent_state = %d, reward = %d, terminated = %d", next_agnet_state, reward, terminated);

      #10
      agent_state = 'd351;
      action = 'd3;
      #10
      $display("next_agent_state = %d, reward = %d, terminated = %d", next_agnet_state, reward, terminated);


      #1000 $finish;
  end

endmodule