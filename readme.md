Preliminary software and hardware preparations:
1. A FPGA development board with PCIe
        Connect the fpga development board with pcie to the pcie slot on the computer motherboard, just like GPU.
2. PCIe driver: 
        Download the PCIe driver from AMD official website 
        (https://support.xilinx.com/s/article/65444?language=en_US). 
        Follow the steps in readme under the XDMA file.
3. Vivado software(A comprehensive design suite to turn our hardware behavior description language Verilog into the actual computing circuit inside the fpga):
        Download vivado from AMD official website (https://www.xilinx.com/support/download.html).
        We used version 2018.2 in our experiment, you need to open it with a later version of vivado.
File include:
1. the template vivado project
2. Top module(The communication and data management(by BRAM) logic between cpu and fpga through xdma.It has been set up, and the user does not need to modify this part)
        Envs_steps module(The actual computing circuit modules for several individual environments, as well as the logic for passing the calculated data back to external BRAM. It has been set up, and the user just need to modify the number of environments you want to calculate at a time)
            single environment compute logic moudule (standard environment or customized environment)
