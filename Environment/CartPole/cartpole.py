import os
from typing import Optional
import math

from gymnasium import spaces
import numpy as np

import FPGAEnv


class CartPole(FPGAEnv.FPGAEnv):

    def __init__(self, num_envs=64, render_mode: Optional[str] = None):
        self.gravity = 9.8
        self.masscart = 1.0
        self.masspole = 0.1
        self.total_mass = self.masspole + self.masscart
        self.length = 0.5  # actually half the pole's length
        self.polemass_length = self.masspole * self.length
        self.force_mag = 10.0
        self.tau = 0.02  # seconds between state updates
        self.kinematics_integrator = "euler"

        # Angle at which to fail the episode
        self.theta_threshold_radians = 12 * 2 * math.pi / 360
        self.x_threshold = 2.4

        # Angle limit set to 2 * theta_threshold_radians so failing observation
        # is still within bounds.
        high = np.array(
            [
                self.x_threshold * 2,
                np.finfo(np.float32).max,
                self.theta_threshold_radians * 2,
                np.finfo(np.float32).max,
            ],
            dtype=np.float32,
        )

        self.action_space = spaces.Discrete(2)
        self.observation_space = spaces.Box(-high, high, dtype=np.float32)

        self.render_mode = render_mode

        self.screen_width = 600
        self.screen_height = 400
        self.screen = None
        self.clock = None
        self.isopen = True
        self.states = None

        self.steps_beyond_terminated = None

        self.ENV_NUM     = num_envs
        self.STA_SPACE_N = 4 # how many words does one state occupy
        self.OBS_SPACE_N = 4 # how many words does one observation occupy
        self.ACT_WL      = 1
        self.RWD_WL      = 1
        self.DATA_WL     = 32
        self.STA_SHAPE   = (self.ENV_NUM, self.STA_SPACE_N)
        super(CartPole, self).__init__()
    
    def fpga_step(self, actions):
        # pack data
        a_bytes  = np.packbits(actions[::-1].reshape(-1, 32), axis=-1).view(np.uint32).tobytes()[::-1]
        src_data = a_bytes + (self.clear_flag if self.first_step else self.start_flag)

        # write data
        os.pwrite(self.pc2fpga, src_data, self.ACTION_OFFSET)

        # wait for computing
        self.precise_short_sleep(self.SLEEP_TIME_NS)

        # read data
        fpga_raw = os.pread(self.fpga2pc, self.READ_BYTE_NUM, self.READ_OFFSET)

        # unpack data
        obs = np.frombuffer(fpga_raw, dtype=np.float32, count=self.OBS_WD_NUM, offset=self.OBS_OFFSET).reshape(self.ENV_NUM, self.OBS_SPACE_N)
        r   = np.unpackbits(np.frombuffer(fpga_raw, dtype=np.uint8, count=self.RWD_WD_NUM*4, offset=self.RWD_OFFSET), bitorder='little')
        terminate = np.unpackbits(np.frombuffer(fpga_raw, dtype=np.uint8, count=self.DONE_WD_NUM*4, offset=self.DONE_OFFSET), bitorder='little')

        return obs, r, terminate

    def step(self, actions):
        self.obs, rewards, terminates = self.fpga_step(actions)
        self.states = self.obs
        return self.obs, rewards, terminates, False, {}

    def reset(self):
        self.states = np.random.uniform(-0.05, 0.05, size=self.STA_SHAPE).astype(np.float32)
        os.pwrite(self.pc2fpga, self.states, 0x0000)
        self.obs = self._get_obs()
        self.first_step = True
        return self.obs, {}

    def _get_obs(self):
        return self.states


if __name__ == "__main__":
    env = CartPole(num_envs=4000)
    print(env.observation_space)
    print(env.DONE_OFFSET)
