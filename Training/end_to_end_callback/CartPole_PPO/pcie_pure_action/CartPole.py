import os
import time
import numpy as np
import gymnasium as gym

from stable_baselines3.common.vec_env.dummy_vec_env import DummyVecEnv
from stable_baselines3.common.monitor import Monitor

class FPGAEnv(DummyVecEnv):
    def __init__(self, num_envs=64):
        def make_env(rank: int):
            def _init() -> gym.Env:
                env = gym.make("CartPole-v1")  # type: ignore[arg-type]
                env = Monitor(env)
                return env

            return _init

        super(FPGAEnv, self).__init__([make_env(i) for i in range(num_envs)])
        self.t_start = time.time()
        self.states = None
        self.num_envs = num_envs
        self.elapsed_steps = np.zeros(num_envs, dtype=np.uint16)
        self.all_env_rewards = [[] for _ in range(num_envs)]
        self.buf_infos = [{} for _ in range(num_envs)]
        self.first_step = None

        self.pc2fpga = os.open('/dev/xdma0_h2c_0', os.O_WRONLY)
        self.fpga2pc = os.open('/dev/xdma0_c2h_0', os.O_RDONLY)

        self.ENV_NUM = num_envs
        self.OBS_SPACE_N = 4
        self.STA_WD_NUM = int(self.ENV_NUM * self.OBS_SPACE_N)
        self.RWD_WD_NUM = int(self.ENV_NUM / 32)
        self.DONE_WD_NUM = int(self.ENV_NUM / 32)
        self.STA_OFFSET = 0
        self.RWD_OFFSET = self.STA_WD_NUM * 4
        self.DONE_OFFSET = (self.STA_WD_NUM + self.RWD_WD_NUM) * 4
        self.start_flag = 0x00000001
        self.start_flag = self.start_flag.to_bytes(4, byteorder='little')
        self.clear_flag = 0x00000002
        self.clear_flag = self.clear_flag.to_bytes(4, byteorder='little')
        self.action_offset = int((self.ENV_NUM*self.OBS_SPACE_N) * 4)
        self.read_offset = int(((self.ENV_NUM*self.OBS_SPACE_N) + (self.ENV_NUM/32) + 1) * 4)
        self.read_byte_num = int(((self.ENV_NUM*self.OBS_SPACE_N) + (self.ENV_NUM/32) + (self.ENV_NUM/32)) * 4)
        self.state_shape = (self.ENV_NUM, self.OBS_SPACE_N)
        self.max_episode_steps = 500

        self.fpga_clear()

    def fpga_close(self):
        os.close(self.pc2fpga)
        os.close(self.fpga2pc)

    def fpga_clear(self):
        all_zero = np.zeros(4096, dtype=np.float32)
        os.pwrite(self.pc2fpga, all_zero, 0x0000)

    def fpga_step(self, actions):
        a_bytes = np.packbits(actions[::-1].reshape(-1, 32), axis=-1).view(np.uint32).tobytes()[::-1]
        src_data = a_bytes + (self.clear_flag if self.first_step else self.start_flag)
        os.pwrite(self.pc2fpga, src_data, self.action_offset)
        # src_data = self.states.tobytes() + a_bytes + self.start_flag
        # os.pwrite(self.pc2fpga, src_data, 0x0000)
        # time.sleep(0.001)
        fpga_raw    = os.pread(self.fpga2pc, self.read_byte_num, self.read_offset)
        next_states = np.frombuffer(fpga_raw, dtype=np.float32, count=self.STA_WD_NUM, offset=self.STA_OFFSET).copy().reshape(self.ENV_NUM, self.OBS_SPACE_N)
        rewards     = np.unpackbits(np.frombuffer(fpga_raw, dtype=np.uint8, count=self.RWD_WD_NUM*4, offset=self.RWD_OFFSET), bitorder='little')
        dones       = np.unpackbits(np.frombuffer(fpga_raw, dtype=np.uint8, count=self.DONE_WD_NUM*4, offset=self.DONE_OFFSET), bitorder='little').astype(np.bool_)

        condition = (next_states[:, 2] < -3.14) | (next_states[:, 2] > 3.14)
        next_states[condition, 2] = self.angle_normalize(next_states[condition, 2])

        return next_states, rewards, dones

    def angle_normalize(self, x):
        return ((x + np.pi) % (2 * np.pi)) - np.pi 

    def reset(self):
        self.states = np.random.uniform(-0.05, 0.05, size=self.state_shape).astype(np.float32)
        os.pwrite(self.pc2fpga, self.states, 0x0000)
        self.first_step = True
        return self.states

    def step(self, actions):
        self.states, rewards, terminates = self.fpga_step(actions)
        # print("terminates in step():", terminates)

        # # do step() in /data1/anaconda/envs/fpga_gym/lib/python3.11/site-packages/gymnasium/wrappers/time_limit.py
        self.elapsed_steps += 1
        truncateds = self.elapsed_steps >= self.max_episode_steps
        dones = terminates | truncateds

        # do step() in /data1/anaconda/envs/fpga_gym/lib/python3.11/site-packages/stable_baselines3/common/monitor.py
        # self.buf_infos = [{} for _ in range(self.num_envs)]
        # for env_idx in range(self.num_envs):
        #     self.all_env_rewards[env_idx].append(float(rewards[env_idx]))
        #     self.buf_infos[env_idx]["TimeLimit.truncated"] = truncateds[env_idx] and not terminates[env_idx]
        #     if dones[env_idx]:
        #         ep_rew = sum(self.all_env_rewards[env_idx])
        #         ep_len = len(self.all_env_rewards[env_idx])
        #         ep_info = {"r": round(ep_rew, 6), "l": ep_len, "t": round(time.time() - self.t_start, 6)}
        #         self.buf_infos[env_idx]["episode"] = ep_info
        #         self.buf_infos[env_idx]["terminal_observation"] = self.states[env_idx]

        #         self.elapsed_steps[env_idx] = 0
        #         self.all_env_rewards[env_idx] = []
        #         self.states[env_idx] = np.random.uniform(-0.05, 0.05, size=self.OBS_SPACE_N).astype(np.float32)
                
        self.all_env_rewards = [self.all_env_rewards[i] + [float(rewards[i])] for i in range(self.num_envs)]
        truncateds_not_terminates = np.logical_and(truncateds, np.logical_not(terminates))
        self.buf_infos = [{"TimeLimit.truncated": truncateds_not_terminates[i]} for i in range(self.num_envs)]

        done_indices = np.where(dones)[0]
        ep_rews = np.array([sum(self.all_env_rewards[i]) for i in done_indices])
        ep_lens = np.array([len(self.all_env_rewards[i]) for i in done_indices])
        ep_infos = [{"r": round(ep_rews[i], 6), "l": ep_lens[i], "t": round(time.time() - self.t_start, 6)} for i in range(len(done_indices))]

        for i, idx in enumerate(done_indices):
            self.buf_infos[idx]["episode"] = ep_infos[i]
            self.buf_infos[idx]["terminal_observation"] = self.states[idx]
            self.elapsed_steps[idx] = 0
            self.all_env_rewards[idx] = []
            # self.states[idx] = np.random.uniform(-0.05, 0.05, size=self.OBS_SPACE_N).astype(np.float32)


        self.first_step = False
        return self.states, rewards, dones, self.buf_infos


