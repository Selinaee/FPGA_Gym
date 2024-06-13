import os
from typing import Optional
import math

from gymnasium import spaces
import numpy as np

import FPGAEnv


UP = 0
RIGHT = 1
DOWN = 2
LEFT = 3


class CliffWalking(FPGAEnv.FPGAEnv):

    def __init__(self, num_envs=64, render_mode: Optional[str] = None, g=10.0):
        self.shape = (4, 12)
        self.start_state_index = np.ravel_multi_index((3, 0), self.shape)

        self.nS = np.prod(self.shape)
        self.nA = 4

        # Cliff Location
        self._cliff = np.zeros(self.shape, dtype=bool)
        self._cliff[3, 1:-1] = True

        # Calculate transition probabilities and rewards
        self.P = {}
        for s in range(self.nS):
            position = np.unravel_index(s, self.shape)
            self.P[s] = {a: [] for a in range(self.nA)}
            self.P[s][UP] = self._calculate_transition_prob(position, [-1, 0])
            self.P[s][RIGHT] = self._calculate_transition_prob(position, [0, 1])
            self.P[s][DOWN] = self._calculate_transition_prob(position, [1, 0])
            self.P[s][LEFT] = self._calculate_transition_prob(position, [0, -1])

        # Calculate initial state distribution
        # We always start in state (3, 0)
        self.initial_state_distrib = np.zeros(self.nS)
        self.initial_state_distrib[self.start_state_index] = 1.0

        self.observation_space = spaces.Discrete(self.nS)
        self.action_space = spaces.Discrete(self.nA)

        self.render_mode = render_mode

        # pygame utils
        self.cell_size = (60, 60)
        self.window_size = (
            self.shape[1] * self.cell_size[1],
            self.shape[0] * self.cell_size[0],
        )
        self.window_surface = None
        self.clock = None
        self.elf_images = None
        self.start_img = None
        self.goal_img = None
        self.cliff_img = None
        self.mountain_bg_img = None
        self.near_cliff_img = None
        self.tree_img = None

        self.ENV_NUM     = num_envs
        self.STA_SPACE_N = 1 # how many words does one state occupy
        self.OBS_SPACE_N = 1 # how many words does one observation occupy
        self.ACT_WL      = 2
        self.RWD_WL      = 1
        self.DATA_WL     = 32
        self.STA_SHAPE   = (self.ENV_NUM, self.STA_SPACE_N)
        super(CliffWalking, self).__init__()

        # for data unpack
        self.r_map = np.array([-1, -100])

    def fpga_step(self, actions):
        # pack data
        a_bytes = actions.reshape(-1, 16).astype(np.uint32)
        a_bytes = np.bitwise_or(np.bitwise_or(np.bitwise_or(np.bitwise_or(np.bitwise_or(np.bitwise_or(np.bitwise_or(np.bitwise_or(np.bitwise_or(np.bitwise_or(np.bitwise_or(np.bitwise_or(np.bitwise_or(np.bitwise_or(np.bitwise_or(a_bytes[:,0], a_bytes[:,1]<<2), a_bytes[:,2]<<4), a_bytes[:,3]<<6), a_bytes[:,4]<<8), a_bytes[:,5]<<10), a_bytes[:,6]<<12), a_bytes[:,7]<<14), a_bytes[:,8]<<16), a_bytes[:,9]<<18), a_bytes[:,10]<<20), a_bytes[:,11]<<22), a_bytes[:,12]<<24), a_bytes[:,13]<<26), a_bytes[:,14]<<28), a_bytes[:,15]<<30).tobytes()
        src_data = a_bytes + (self.clear_flag if self.first_step else self.start_flag)

        # write data
        os.pwrite(self.pc2fpga, src_data, self.ACTION_OFFSET)

        # wait for computing
        self.precise_short_sleep(self.SLEEP_TIME_NS)

        # read data
        fpga_raw = os.pread(self.fpga2pc, self.READ_BYTE_NUM, self.READ_OFFSET)

        # unpack data
        obs = np.frombuffer(fpga_raw, dtype=np.uint32, count=self.OBS_WD_NUM, offset=self.OBS_OFFSET)
        r   = self.r_map[np.unpackbits(np.frombuffer(fpga_raw, dtype=np.uint8, count=self.RWD_WD_NUM*4, offset=self.RWD_OFFSET), bitorder='little')].flatten()
        terminate = np.unpackbits(np.frombuffer(fpga_raw, dtype=np.uint8, count=self.DONE_WD_NUM*4, offset=self.DONE_OFFSET), bitorder='little')

        return obs, r, terminate

    def step(self, actions):
        self.obs, rewards, terminates = self.fpga_step(actions)
        self.states = self.obs
        return self.obs, rewards, terminates, False, {}

    def reset(self):
        self.states = np.random.randint(1, 48, size=self.ENV_NUM).astype(np.uint32)
        os.pwrite(self.pc2fpga, self.states, 0x0000)
        self.obs = self._get_obs()
        self.first_step = True
        return self.obs, {}

    def _get_obs(self):
        return self.states


if __name__ == "__main__":
    env = CliffWalking(num_envs=4000)
    print(env.observation_space)
    print(env.DONE_OFFSET)
