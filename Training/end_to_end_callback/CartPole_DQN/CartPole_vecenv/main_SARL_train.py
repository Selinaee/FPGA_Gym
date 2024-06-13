import gymnasium as gym
import numpy as np
import torch
import torch.nn as nn
import random
from agent import Agent
import time
import os
import argparse
import matplotlib.pyplot as plt

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

if __name__ == "__main__":
    start_time = time.time_ns()

    """parameters"""
    EPSILON_START = 1.0
    EPSILON_END = 0.02
    EPSILON_DECAY = 100000
    TARGET_UPDATE_FREQUENCY = 10
    ENV_NUM = int(os.getenv('ENV_NUM'))

    """get the environment information"""
    print("Gym version:", gym.__version__)
    env = gym.make(id="CartPole-v1")
    s, info = env.reset()
    n_state = len(s)
    n_action = env.action_space.n

    """initialize the agent and environments"""
    # envs = gym.vector.make(id="CartPole-v1", num_envs=ENV_NUM, context="forkserver")
    # envs = gym.vector.make(id="CartPole-v1", num_envs=ENV_NUM, context="spawn")
    envs = gym.make_vec(id="CartPole-v1", num_envs=ENV_NUM)
    s, info = envs.reset()
    agent = Agent(idx=0,
                  n_input=n_state,
                  n_output=n_action,
                  mode='train')

    """Main Training Loop"""
    n_episode = int(os.getenv('EPISODE_NUM'))
    n_time_step = int(os.getenv('STEP_NUM'))
    REWARD_BUFFER = np.zeros(shape=n_episode)
    TIME_BUFFER = np.zeros(shape=n_episode) 
    AVE_REWARD_BUFFER = np.zeros(shape=n_episode) 
    done_once = np.zeros(ENV_NUM, dtype=bool)
    for episode_i in range(n_episode):
        episode_reward = np.zeros(ENV_NUM)
        for step_i in range(n_time_step):
            epsilon = np.interp(episode_i * n_time_step + step_i, [0, EPSILON_DECAY], [EPSILON_START, EPSILON_END])  # interpolation
            
            random_sample = random.random()
            if random_sample <= epsilon:
                a = envs.action_space.sample()
            else:
                a = agent.online_net.act(s)
            # start_time = time.time_ns()
            s_, r, done, timelimit, info = envs.step(a)  # timelimit and info are not used in this case
            
            # print("s_:", s_)    
            # end_time = time.time_ns()
            # print(f"Time: {(end_time - start_time)/1e9} s")
            done_once = np.logical_or(done_once, done)
            # print(f"Step Reward: {r}")
            for i in range(len(s)):
                agent.memo.add_memo(s[i], a[i], r[i], done[i], s_[i])
            s = s_
            episode_reward += r

            # for i in range(ENV_NUM):
            #     if done[i]:
            #         # 随机初始化该环境的状态
            #         # print ("s[i]", s[i])
            #         s[i] = np.random.uniform(-0.05, 0.05, size=4).astype(np.float32)

            # if True in done:
            if all(done_once):
                s, info = envs.reset()
                done_once = np.zeros(ENV_NUM, dtype=bool)     
                REWARD_BUFFER[episode_i] = np.mean(episode_reward)
                end_time = time.time_ns()
                TIME_BUFFER[episode_i] = end_time - start_time     
                AVE_REWARD_BUFFER[episode_i] = np.mean(REWARD_BUFFER[:episode_i])     
                break

            # Start Gradient Step
            batch_s, batch_a, batch_r, batch_done, batch_s_ = agent.memo.sample()  # update batch-size amounts of Q
            # Compute Targets
            target_q_values = agent.target_net(batch_s_)
            max_target_q_values = target_q_values.max(dim=1, keepdim=True)[0]  # ?
            targets = batch_r + agent.GAMMA * (1 - batch_done) * max_target_q_values

            # Compute Q_values
            q_values = agent.online_net(batch_s)
            a_q_values = torch.gather(input=q_values, dim=1, index=batch_a)  # ?

            # Compute Loss
            loss = nn.functional.smooth_l1_loss(a_q_values, targets)

            # Gradient Descent
            agent.optimizer.zero_grad()
            loss.backward()
            agent.optimizer.step()

        # Update target network
        if episode_i % TARGET_UPDATE_FREQUENCY == 0:
            agent.target_net.load_state_dict(agent.online_net.state_dict())
        
        # Print the training progress
        if episode_i % 10 == 0:
            print(f"Episode: {episode_i}, Reward: {episode_reward}")

    all_end_time = time.time_ns()
    print(f"Total Time: {(all_end_time - start_time)/1e9} s")



with open(f'/data0/FPGA_GYM/python/CartPole/CartPole_vecenv/data/reward_buffer_envnum{ENV_NUM}_{curve_idx}.txt', 'w') as f:
    for reward in REWARD_BUFFER:
        f.write(str(reward) + '\n')
with open(f'/data0/FPGA_GYM/python/CartPole/CartPole_vecenv/data/time_buffer_envnum{ENV_NUM}_{curve_idx}.txt', 'w') as f:
    for this_time in TIME_BUFFER:
        f.write(str(this_time) + '\n')
with open(f'/data0/FPGA_GYM/python/CartPole/CartPole_vecenv/data/ave_reward_buffer_envnum{ENV_NUM}_{curve_idx}.txt', 'w') as f:
    for ave_reward in AVE_REWARD_BUFFER:
        f.write(str(ave_reward) + '\n')    


episodes = list(range(1, len(REWARD_BUFFER) + 1))

# 绘制图表
plt.plot(episodes, REWARD_BUFFER, marker='o', linestyle='-', markersize=2)
plt.xlabel('Episode')
plt.ylabel('Reward')
plt.title('Reward Buffer vs. Episode')
plt.grid(True)
plt.savefig(f'/data0/FPGA_GYM/python/CartPole/CartPole_vecenv/data/reward_episode_envnum{ENV_NUM}_{curve_idx}.png')


# 绘制图表
plt.figure()
plt.plot(TIME_BUFFER, REWARD_BUFFER, marker='o', linestyle='-', markersize=2)
plt.xlabel('Time')
plt.ylabel('Reward')
plt.title('Reward Buffer vs. Time')
plt.grid(True)
plt.savefig(f'/data0/FPGA_GYM/python/CartPole/CartPole_vecenv/data/reward_time_envnum{ENV_NUM}_{curve_idx}.png')

# 绘制图表
plt.figure()
plt.plot(TIME_BUFFER, AVE_REWARD_BUFFER, marker='o', linestyle='-', markersize=2)
plt.xlabel('Time')
plt.ylabel('Ave_Reward')
plt.title('Ave Reward Buffer vs. Time')
plt.grid(True)
plt.savefig(f'/data0/FPGA_GYM/python/CartPole/CartPole_vecenv/data/ave_reward_time_envnum{ENV_NUM}_{curve_idx}.png')

# 绘制图表
plt.figure()
plt.plot(episodes, AVE_REWARD_BUFFER, marker='o', linestyle='-', markersize=2)
plt.xlabel('episodes')
plt.ylabel('Ave_Reward')
plt.title('Ave Reward Buffer vs. episodes')
plt.grid(True)
plt.savefig(f'/data0/FPGA_GYM/python/CartPole/CartPole_vecenv/data/ave_reward_episodes_envnum{ENV_NUM}_{curve_idx}.png')
                        