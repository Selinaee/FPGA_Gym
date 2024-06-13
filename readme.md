File include:
1. VivadoProjectExample：
   You can download the environment's Vivado project in this connection: https://disk.pku.edu.cn/link/AAA5847B47B5C84CFD987D4B0A803A7CC0
   it includes
   the template Vivado project
   the CartPole, CliffWalking, Pendulum, Blackjack Vivado project
2. FPGAEnv(python code, use directly with training connections)
3. Training(Examples of training, including CartPole + DQN, CartPole + PPO, CliffWalking + DQN)

Preliminary software and hardware preparations:
1. An FPGA development board with PCIe
        Connect the FPGA development board with PCIe to the PCIe slot on the computer motherboard, just like GPU.
2. PCIe driver: 
        Download the PCIe driver from AMD's official website 
        (https://support.xilinx.com/s/article/65444?language=en_US). 
        Follow the steps in the readme under the XDMA file.
3. Vivado software(A comprehensive design suite to turn our hardware behavior description language Verilog into the actual computing circuit inside the FPGA):
        Download the software Vivado from AMD's official website (https://www.xilinx.com/support/download.html).
        We used version 2018.2 in our experiment, please open it with a later version of Vivado.

