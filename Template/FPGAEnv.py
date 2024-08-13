import os
import time
import numpy as np
import gymnasium as gym


class FPGAEnv(gym.Env):

    def __init__(self):
        self.obs = None
        self.states = None
        self.first_step = None

        try:
            self.pc2fpga = os.open('/dev/xdma0_h2c_0', os.O_WRONLY)
            self.fpga2pc = os.open('/dev/xdma0_c2h_0', os.O_RDONLY)
        except:
            # assert False, "Error: Can't open FPGA device."
            print("Error: Can't open FPGA device.")

        # for write FPGA
        self.STA_WD_NUM    = int(self.ENV_NUM * self.STA_SPACE_N)
        self.START_FLAG    = 0x00000001
        self.START_FLAG    = self.START_FLAG.to_bytes(int(self.DATA_WL/8), byteorder='little')
        self.CLEAR_FLAG    = 0x00000002
        self.CLEAR_FLAG    = self.CLEAR_FLAG.to_bytes(int(self.DATA_WL/8), byteorder='little')
        self.ACTION_OFFSET = int(self.ENV_NUM*self.STA_SPACE_N * self.DATA_WL/8)

        # for read FPGA
        self.READ_OFFSET   = int(self.ACTION_OFFSET + (self.ENV_NUM*self.ACT_WL/self.DATA_WL + 1) * self.DATA_WL/8)
        self.READ_BYTE_NUM = int(self.ENV_NUM * (self.OBS_SPACE_N + self.RWD_WL/self.DATA_WL + 1/self.DATA_WL) * self.DATA_WL/8)
        self.SLEEP_TIME_NS = int(self.ENV_NUM * (self.ACT_WL/self.DATA_WL + self.OBS_SPACE_N + self.RWD_WL/self.DATA_WL + 1/self.DATA_WL) * 10)

        # for data unpack
        self.OBS_WD_NUM  = int(self.ENV_NUM * self.OBS_SPACE_N)
        self.RWD_WD_NUM  = int(self.ENV_NUM * self.RWD_WL / self.DATA_WL)
        self.DONE_WD_NUM = int(self.ENV_NUM / self.DATA_WL)
        self.OBS_OFFSET  = 0
        self.RWD_OFFSET  = self.OBS_WD_NUM * int(self.DATA_WL/8)
        self.DONE_OFFSET = self.RWD_OFFSET + self.RWD_WD_NUM * int(self.DATA_WL/8)

        self.fpga_clear()

    def precise_short_sleep(duration):
        start = time.perf_counter_ns()
        while (time.perf_counter_ns() - start) < duration:
            pass

    def fpga_clear(self):
        all_zero = np.zeros(65536, dtype=np.float32)
        os.pwrite(self.pc2fpga, all_zero, 0x0000)

    def close(self):
        os.close(self.pc2fpga)
        os.close(self.fpga2pc)

    def fpga_step(self):
        raise NotImplementedError
    
    def step(self):
        raise NotImplementedError

    def reset(self):
        raise NotImplementedError

    def _get_obs(self):
        raise NotImplementedError

if __name__ == "__main__":
    env = FPGAEnv()
    print(env.action_space)
    print(env.observation)