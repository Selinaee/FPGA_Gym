import os
from typing import Optional

from gymnasium import spaces
import numpy as np

import FPGAEnv


class BlackJack(FPGAEnv.FPGAEnv):

    def __init__(self, num_envs=64, render_mode: Optional[str] = None, natural=False, sab=False):
        self.action_space = spaces.Discrete(2)
        self.observation_space = spaces.Tuple(
            (spaces.Discrete(32), spaces.Discrete(11), spaces.Discrete(2))
        )

        # Flag to payout 1.5 on a "natural" blackjack win, like casino rules
        # Ref: http://www.bicyclecards.com/how-to-play/blackjack/
        self.natural = natural

        # Flag for full agreement with the (Sutton and Barto, 2018) definition. Overrides self.natural
        self.sab = sab

        self.render_mode = render_mode

        self.ENV_NUM     = num_envs
        self.STA_SPACE_N = 5 # how many words does one state occupy. explain why it is 5
        self.OBS_SPACE_N = 1 # how many words does one observation occupy
        self.ACT_WL      = 1
        self.RWD_WL      = 2
        self.DATA_WL     = 32
        self.STA_SHAPE   = (self.ENV_NUM, 17+21)
        super(BlackJack, self).__init__()

        # for data unpack
        self.MASK5 = (1 << 5) - 1
        self.MASK4 = (1 << 4) - 1
        self.MASK2 = 3
        self.r_map = np.array([0, 1, 1.5, -1])
    
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
        data = np.frombuffer(fpga_raw, dtype=np.uint32)
        player_sum  = data[:self.OBS_WD_NUM]>>5 & self.MASK5
        dealer_card = data[:self.OBS_WD_NUM]>>1 & self.MASK4
        usable_ace  = data[:self.OBS_WD_NUM] & 1
        obs = np.stack([player_sum, dealer_card, usable_ace], axis=1)
        r   = self.r_map[(data[self.OBS_WD_NUM:self.OBS_WD_NUM+self.RWD_WD_NUM].reshape(-1, 1) >> np.arange(0, 32, 2)) & self.MASK2].flatten()
        terminate = np.unpackbits(np.frombuffer(fpga_raw, dtype=np.uint8, count=self.DONE_WD_NUM*self.DATA_WL/8, offset=self.DONE_OFFSET), bitorder='little')

        return obs, r, terminate

    def step(self, actions):
        self.obs, rewards, terminates = self.fpga_step(actions)
        return self.obs, rewards, terminates, False, {}

    def reset(self):
        self.states = np.random.randint(1, 11, size=self.STA_SHAPE).astype(np.uint8)
        for i in range(len(self.states)):
            for j in range(len(self.states[i])):
                if j != 0 and j != 21:
                    self.states[i][j] = 0
        os.pwrite(self.pc2fpga, self.states, 0x0000)
        self.obs = self._get_obs()
        self.first_step = True
        return self.obs, {}

    def _get_obs(self):
        obs = []
        for env_idx in range(self.ENV_NUM):
            player_cards = self.states[env_idx][:21]
            dealer_cards = self.states[env_idx][21:]
            
            usable_ace = 1 in player_cards and sum(player_cards) + 10 <= 21
            player_sum = sum(player_cards) + 10 if usable_ace else sum(player_cards)
            this_obs = [player_sum, dealer_cards[0], usable_ace]
            obs.append(this_obs)
        return np.array(obs)


if __name__ == "__main__":
    env = BlackJack(num_envs=8064)
    print(env.observation_space)
    print(env.DONE_OFFSET)
