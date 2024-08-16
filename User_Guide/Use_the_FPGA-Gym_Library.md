This file provides a step-by-step approach for users who want to use available environment in this library.

This section uses CartPole as an example.


Step 1: Open the corresponding Vivado project file in Vivado and set the number of parallel environments.

![alt text](image.png)
shows the Vivado GUI after opening the project. 
Line 15 of `Pipline.v` sets the number of parallel environments, for example, 160. ① in figure

```Verilog
module Pipeline #(parameter DATA_WL = 32'd32, ADDR_WL = 32'd32, WEA_WL = 32'd4, SW_ENV_NUM = 30'd160 // 160 can be changed to the needed number of parallel environments) 
```
We perform software and hardware co-optimization in the current version 1.0.0 of FPGA-Gym to achieve the most efficient computation.
Given the constraints from software, the number of parallel environments must be a multiple of the number of processing elements (e.g., 20 for CartPole and a multiple of the BRAM data width in the FPGA (which is currently 32 bits).

Step 2: Generate the bitstream.

Click the button following the arrows ② to ⑦ in Fig.~\ref{fig: Vivado_workspace} to generate a bitstream. When the bitstream is successfully generated "Bitstream generated" will show up at arrow ⑧, click arrow ⑨ to flash the bitstream into the FPGA board.
This bitstream contains all the information to map the logical design to FPGA hardware resources such as lookup tables, registers, wiring, and so on. At this point, all operations on the hardware end are finished.

Step 3. Import the `FPGAEnv` package into your code.

We design this package with reference to the gymnasium library, so its usage is similar to the package gymnasium.
Here is an example:

```python
import os
from CartPole import FPGAEnv
env = FPGAEnv(env_num)
env.reset
obs, rewards, terminates, _ , _ = env.step(actions)
env.fpga_close()
```