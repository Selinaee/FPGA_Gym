import time
import csv
import os
import argparse
import matplotlib.pyplot as plt
import numpy as np
from stable_baselines3 import PPO
from stable_baselines3.common.env_util import make_vec_env
from stable_baselines3.common.vec_env import DummyVecEnv
from stable_baselines3.common.callbacks import BaseCallback
from CartPole import FPGAEnv

parser = argparse.ArgumentParser()
parser.add_argument("curve_idx", nargs='?', default='curve_idx=', help="Input in the format 'curve_idx=1'")
parser.add_argument("--seed", type=int, default=456, help="Random seed")  # 新增的命令行参数

args = parser.parse_args()
key, value = args.curve_idx.split('=')
if key == 'curve_idx':
    print(f'Current Curve Index: {value}')
    curve_idx = value
else:
    print(f'Invalid argument. Expected format is curve_idx=<value>')
seed = args.seed
np.random.seed(seed)
print(f"Random seed: {seed}")



class TrainingMonitor(BaseCallback):
    def __init__(self, curve_idx, verbose=0):
        # print("idx in monitor: ", curve_idx)
        super(TrainingMonitor, self).__init__(verbose)
        self.curve_idx = curve_idx
        self.episode_end_times = []  # 新增列表，用于存储每个episode结束的时间
        self.episode_rewards = []
        self.average_rewards = []
        self.episode_timesteps = []  


    def _on_step(self) -> bool:
        # print(self.locals["infos"][0])
        # self.total_timesteps += 1
        # print(self.total_timesteps) 
        info = self.locals["infos"][0]
        # if 'episode' in info:
        #     end_time = time.time()  # 获取当前时间
        #     self.episode_end_times.append(end_time)  # 将结束时间添加到列表中
        #     reward = info['episode']['r']
        #     self.episode_rewards.append(reward)
        #     average_reward = sum(self.episode_rewards) / len(self.episode_rewards)
        #     self.average_rewards.append(average_reward)
        #     # print(self.locals["infos"][0])

        if 'episode' in info:
            # print(info)
            end_time = time.time()
            self.episode_end_times.append(end_time)
            reward = info['episode']['r']
            self.episode_rewards.append(reward)
            average_reward = sum(self.episode_rewards) / len(self.episode_rewards)
            self.average_rewards.append(average_reward)
            self.episode_timesteps.append(self.num_timesteps) 
            # self.episode_timesteps.append(self.total_timesteps)
            # print(self.episode_timesteps)  # 记录此时的累积时间步数
        return True

    def save_to_text(self, data, filename):
        with open(filename, 'w') as file:
            for value in data:
                file.write(f'{value}\n')

    def save_data(self, curve_idx):
        base_path = '/data0/FPGA_GYM/python/CartPole_PPO/pcie/data'
        self.save_to_text(self.episode_end_times, os.path.join(base_path, f'time_buffer_envnum64_{curve_idx}.txt'))
        self.save_to_text(self.average_rewards, os.path.join(base_path, f'ave_reward_buffer_envnum64_{curve_idx}.txt'))
        self.save_to_text(self.episode_rewards, os.path.join(base_path, f'reward_buffer_envnum64_{curve_idx}.txt'))
        self.save_to_text(self.episode_timesteps, os.path.join(base_path, f'total_time_steps_buffer_envnum64_{curve_idx}.txt'))

    def _on_training_end(self) -> None:
        self.save_data(self.curve_idx)
env = FPGAEnv(64)

model = PPO("MlpPolicy", env, verbose=1, batch_size=4096)
monitor = TrainingMonitor(curve_idx)
model.learn(total_timesteps=30000000, callback=monitor)

env.fpga_close()
