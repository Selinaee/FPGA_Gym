import csv
import os
import time
import envpool
import argparse
import numpy as np
import torch as th
import gymnasium as gym
import matplotlib.pyplot as plt
from envpool.python.protocol import EnvPool
from stable_baselines3 import PPO
from stable_baselines3.common.env_util import make_vec_env
from stable_baselines3.common.callbacks import BaseCallback
from typing import Optional
from packaging import version
from stable_baselines3 import PPO
from stable_baselines3.common.evaluation import evaluate_policy
from stable_baselines3.common.vec_env import VecEnvWrapper, VecMonitor
from stable_baselines3.common.vec_env.base_vec_env import (
  VecEnvObs,
  VecEnvStepReturn,
)

parser = argparse.ArgumentParser()
parser.add_argument("curve_idx", nargs='?', default='curve_idx=0', help="Input in the format 'curve_idx=1'")
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



num_envs = 64
env_id = "CartPole-v1"
use_env_pool = True  # whether to use EnvPool or Gym for training
render = False  # whether to render final policy using Gym
is_legacy_gym = version.parse(gym.__version__) < version.parse("0.26.0")

class VecAdapter(VecEnvWrapper):
  """
  Convert EnvPool object to a Stable-Baselines3 (SB3) VecEnv.

  :param venv: The envpool object.
  """

  def __init__(self, venv: EnvPool):
    # Retrieve the number of environments from the config
    venv.num_envs = venv.spec.config.num_envs
    super().__init__(venv=venv)

  def step_async(self, actions: np.ndarray) -> None:
    self.actions = actions

  def reset(self) -> VecEnvObs:
    if is_legacy_gym:
      return self.venv.reset()
    else:
      return self.venv.reset()[0]

  def seed(self, seed: Optional[int] = None) -> None:
    # You can only seed EnvPool env by calling envpool.make()
    pass

  def step_wait(self) -> VecEnvStepReturn:
    if is_legacy_gym:
      obs, rewards, dones, info_dict = self.venv.step(self.actions)
    else:
      obs, rewards, terms, truncs, info_dict = self.venv.step(self.actions)
      dones = terms + truncs
    infos = []
    # Convert dict to list of dict
    # and add terminal observation
    for i in range(self.num_envs):
      infos.append(
        {
          key: info_dict[key][i]
          for key in info_dict.keys()
          if isinstance(info_dict[key], np.ndarray)
        }
      )
      if dones[i]:
        infos[i]["terminal_observation"] = obs[i]
        if is_legacy_gym:
          obs[i] = self.venv.reset(np.array([i]))
        else:
          obs[i] = self.venv.reset(np.array([i]))[0]
    return obs, rewards, dones, infos

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
        base_path = '/data0/FPGA_GYM/python/CartPole_PPO_4000/envpool/data'
        self.save_to_text(self.episode_end_times, os.path.join(base_path, f'time_buffer_envnum64_{curve_idx}.txt'))
        self.save_to_text(self.average_rewards, os.path.join(base_path, f'ave_reward_buffer_envnum64_{curve_idx}.txt'))
        self.save_to_text(self.episode_rewards, os.path.join(base_path, f'reward_buffer_envnum64_{curve_idx}.txt'))
        self.save_to_text(self.episode_timesteps, os.path.join(base_path, f'total_time_steps_buffer_envnum64_{curve_idx}.txt'))

    def _on_training_end(self) -> None:
        self.save_data(self.curve_idx)
    # def plot_rewards(self, curve_idx):
    #     plt.figure(figsize=(10, 5))
    #     plt.plot(self.episode_timesteps, self.average_rewards)  # 使用累积时间步数作为x轴
    #     plt.xlabel('Total Time Steps')
    #     plt.ylabel('Average Reward')
    #     plt.title('Average Rewards Over Time Steps')
    #     plt.grid(True)
    #     plt.savefig(f"data/ppo_cartpole_64_{curve_idx}.png")

  

    #     with open(f'data/episode_data_{curve_idx}.csv', 'w', newline='') as file:
    #         writer = csv.writer(file)
    #         writer.writerow(["End Time", "Reward", "Average Reward", "Total Time Steps"])
    #         for i in range(len(self.episode_end_times)):
    #             writer.writerow([self.episode_end_times[i], self.episode_rewards[i], self.average_rewards[i], self.episode_timesteps[i]])
# Parallel environments
# vec_env = make_vec_env("CartPole-v1", n_envs=4)

# model = PPO("MlpPolicy", vec_env, verbose=1)
# model.learn(total_timesteps=25000)
# model.save("ppo_cartpole")

env = envpool.make(env_id, env_type="gymnasium", num_envs=num_envs, seed=seed)
env.spec.id = env_id
env = VecAdapter(env)
env = VecMonitor(env)
# env = make_vec_env("CartPole-v1", n_envs=64)
model = PPO("MlpPolicy", env, verbose=1, batch_size=8192)
print("idx before monitor: ", curve_idx)
monitor = TrainingMonitor(curve_idx)
model.learn(total_timesteps=12000000, callback=monitor)
# monitor.plot_rewards(curve_idx)
