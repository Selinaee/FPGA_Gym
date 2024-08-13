This file provides a step-by-step approach for users who want to add a new environment.

<span style="font-size:24px; font-weight:bold">Software</span>

We have defined the parent class called [FPGAEnv](https://github.com/Selinaee/FPGA_Gym).
After inheriting the parent class, different environment son classes need to modify the main places as follows.
Take adding the CartPole to a template as an example:

1. Set the ENV\_NUM, STA\_SPACE\_N, OBS\_SPACE\_N, ACT\_WL and RWD\_WL attributes in the son class.
The meanings of each attribute is shown in the comment below.

```python
self.ENV_NUM     = num_envs # number of the parallel environments
self.STA_SPACE_N = 4 # number of words one state occupys (1 word = 32 bits)
self.OBS_SPACE_N = 4 # number of words one observation occupys
self.ACT_WL      = 1 # number of words one action occupys
self.RWD_WL      = 1 # number of words one reward occupys
```

2. Change the ```def fpga_step``` in the son class.
This part of the code needs to be fine-tuned for the new environment, mainly because the packaging and unpackaging of data in different environments are slightly different.
We annotate ```# need to modify``` after the code that needs to be modified.

```python
def fpga_step(self, actions):
    # pack data, since the actions of Cartpole is only 0 or 1, we compress the action space to only 1 bit before transmission. The code is as follows, and different environments need to be fine-tuned accordingly.
    a_bytes  = np.packbits(actions[::-1].reshape(-1, 32), axis=-1).view(np.uint32).tobytes()[::-1] # need to modify
    src_data = a_bytes + (self.clear_flag if self.first_step else self.start_flag)

    # write data
    os.pwrite(self.pc2FPGA, src_data, self.ACTION_OFFSET)

    # wait for computing
    self.precise_short_sleep(self.SLEEP_TIME_NS)

    # read data
    FPGA_raw = os.pread(self.FPGA2pc, self.READ_BYTE_NUM, self.READ_OFFSET)

    # unpack data
    np.frombuffer(FPGA_raw, dtype=np.float32, count=self.OBS_WD_NUM, offset=self.OBS_OFFSET) 
    np.frombuffer(FPGA_raw, dtype=np.uint8, count=self.RWD_WD_NUM*4, offset=self.RWD_OFFSET) 
    np.frombuffer(FPGA_raw, dtype=np.uint8, count=self.DONE_WD_NUM*4, offset=self.DONE_OFFSET) 
    # These are the byte forms of completed observations, rewards, and dones, respectively, which need to be modified for different tasks
    obs = np.frombuffer(FPGA_raw, dtype=np.float32, count=self.OBS_WD_NUM, offset=self.OBS_OFFSET).reshape(self.ENV_NUM, self.OBS_SPACE_N) # need to modify
    r   = np.unpackbits(np.frombuffer(FPGA_raw, dtype=np.uint8, count=self.RWD_WD_NUM*4, offset=self.RWD_OFFSET), bitorder='little') # need to modify
    terminate = np.unpackbits(np.frombuffer(FPGA_raw, dtype=np.uint8, count=self.DONE_WD_NUM*4, offset=self.DONE_OFFSET), bitorder='little')

    return obs, r, terminate
```

<span style="font-size:24px; font-weight:bold">Hardware</span>

To add a new environment in the template, the following modifications should be made on the hardware end:

1. Modify `Compute_Single.v`. The module “ Compute_Single” defined in ```Compute_Single.v``` is the processing element (PE) that compute the step of a single environment.
In our modular design, the input and output ports of this module is fixed as shown below and can not be changed.

```verilog
module Compute_Single #(parameter STA_WL = 128, ACT_WL = 1, OBS_WL = 128, RWD_WL = 1) (
    input  wire i_clk,
    input  wire i_ena,

    input  wire [STA_WL-1:0] i_sta,  // current state
    input  wire [ACT_WL-1:0] i_act,  // action

    output wire [STA_WL-1:0] o_sta,  // next state

    output wire [OBS_WL-1:0] o_obs,  // observations
    output wire [RWD_WL-1:0] o_rwd,  // reward
    output wire              o_done, // terminate

    output wire              o_valid // whether the output is valid
    );
```

The content of the module should be modified so that the next state, observation, reward, and termination of the environment (i.e. the outputs of the module) can be computed correctly according to the current state and action (the inputs of the module).

2. Modify `Compute.v`. Open `Compute.v` and modify the value of PE\_NUM, STA\_WL, ACT\_WL, OBS\_WL, and RWD\_WL in line 15.
STA\_WL, ACT\_WL, OBS\_WL, and RWD\_WL is defined by the environment.
The recommend PE\_NUM is $c / (k_{2} / v_{b} )$
(eg. 80 clock cycles / (4*32bit / (32 bit/clock cycle)) = 20).

```verilog
module Compute #(parameter 
    PE_NUM = 20,  # number of processing elements
    STA_WL = 128, # number of bits one state occupys
    ACT_WL = 1,   # number of bits one action occupys
    OBS_WL = 128, # number of bits one observation occupys
    RWD_WL = 1    # number of bits one reward occupys
)
```
After finishing the above modifications, the user has successfully defined a new environment based on the template and can follow [Usage of FPGA-Gym library](https://github.com/Selinaee/FPGA_Gym) to training.
