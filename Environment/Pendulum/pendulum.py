import os
from typing import Optional
import math

from gymnasium import spaces
import numpy as np

import FPGAEnv


class Pendulum(FPGAEnv.FPGAEnv):

    def __init__(self, num_envs=64, render_mode: Optional[str] = None, g=10.0):
        self.max_speed = 8
        self.max_torque = 2.0
        self.dt = 0.05
        self.g = g
        self.m = 1.0
        self.l = 1.0

        self.render_mode = render_mode

        self.screen_dim = 500
        self.screen = None
        self.clock = None
        self.isopen = True

        high = np.array([1.0, 1.0, self.max_speed], dtype=np.float32)
        # This will throw a warning in tests/envs/test_envs in utils/env_checker.py as the space is not symmetric
        #   or normalised as max_torque == 2 by default. Ignoring the issue here as the default settings are too old
        #   to update to follow the gymnasium api
        self.action_space = spaces.Box(
            low=-self.max_torque, high=self.max_torque, shape=(1,), dtype=np.float32
        )
        self.observation_space = spaces.Box(low=-high, high=high, dtype=np.float32)

        self.ENV_NUM     = num_envs
        self.STA_SPACE_N = 2 # how many words does one state occupy
        self.OBS_SPACE_N = 3 # how many words does one observation occupy
        self.ACT_WL      = 32
        self.RWD_WL      = 32
        self.DATA_WL     = 32
        self.STA_SHAPE   = (self.ENV_NUM, self.STA_SPACE_N)
        super(Pendulum, self).__init__()
    
    def fpga_step(self, actions):
        # pack data
        src_data = actions.tobytes() + (self.clear_flag if self.first_step else self.start_flag)

        # write data
        os.pwrite(self.pc2fpga, src_data, self.ACTION_OFFSET)

        # wait for computing
        self.precise_short_sleep(self.SLEEP_TIME_NS)

        # read data
        fpga_raw = os.pread(self.fpga2pc, self.READ_BYTE_NUM, self.READ_OFFSET)

        # unpack data
        obs = np.frombuffer(fpga_raw, dtype=np.float32, count=self.OBS_WD_NUM, offset=self.OBS_OFFSET).reshape(self.ENV_NUM, self.OBS_SPACE_N)
        r   = np.frombuffer(fpga_raw, dtype=np.float32, count=self.RWD_WD_NUM, offset=self.RWD_OFFSET)
        terminate = np.unpackbits(np.frombuffer(fpga_raw, dtype=np.uint8, count=self.DONE_WD_NUM*4, offset=self.DONE_OFFSET), bitorder='little')

        return obs, r, terminate

    def step(self, actions):
        self.obs, rewards, terminates = self.fpga_step(actions)
        return self.obs, rewards, terminates, False, {}

    def reset(self):
        self.states = np.random.uniform(-np.pi, np.pi, size=self.STA_SHAPE).astype(np.float32)
        os.pwrite(self.pc2fpga, self.states, 0x0000)
        self.obs = self._get_obs()
        self.first_step = True
        return self.obs, {}

    def _get_obs(self):
        obs = []
        for env_idx in range(self.ENV_NUM):
            theta, thetadot = self.states[env_idx]
            
            this_obs = np.array([np.cos(theta), np.sin(theta), thetadot], dtype=np.float32)
            obs.append(this_obs)
        return np.array(obs)


if __name__ == "__main__":
    env = Pendulum(num_envs=4000)
    print(env.observation_space)
    print(env.DONE_OFFSET)
