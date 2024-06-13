
import numpy as np
import torch
import torch.nn as nn
import random
from agent import Agent
import time
import matplotlib.pyplot as plt
import argparse
import os
import select
import math


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
# def wait_for_data_ready(fd):
#     """ 使用select等待数据就绪 """
#     epoll = select.epoll()  # 使用epoll，效率更高，特别是监听多个文件描述符时
#     epoll.register(fd, select.EPOLLIN)  # 注册文件描述符和监听事件（EPOLLIN读取事件）
#     while True:
#         events = epoll.poll(timeout=10)  # 阻塞等待事件发生，设置超时为10秒
#         if events:
#             print("Data is ready!")
#             break
#         else:
#             print("Still waiting for data...")

# def step(states, actions):
#     force_mag = 10
#     gravity = 9.8
#     masscart = 1.0
#     masspole = 0.1
#     total_mass = masspole + masscart # 1+0.1
#     length = 0.5
#     polemass_length = masspole * length # 0.1*0.5
#     force_mag = 10.0
#     tau = 0.02
#     theta_threshold_radians = 12 * 2 * math.pi / 360
#     x_threshold = 2.4

#     next_states = []
#     rewards = []
#     dones = []

#     for i in range(len(states)):
#         x, x_dot, theta, theta_dot = states[i]
#         action = actions[i]

#         force = force_mag if action == 1 else -force_mag
#         # force = force_mag if action == 0 else -force_mag
#         costheta = math.cos(theta)
#         sintheta = math.sin(theta)

#         temp = (
#             force + polemass_length * theta_dot**2 * sintheta
#         ) / total_mass
#         thetaacc = (gravity * sintheta - costheta * temp) / (
#             length * (4.0 / 3.0 - masspole * costheta**2 / total_mass)
#         )
#         xacc = temp - polemass_length * thetaacc * costheta / total_mass
#         x = x + tau * x_dot
#         x_dot = x_dot + tau * xacc
#         theta = theta + tau * theta_dot
#         theta_dot = theta_dot + tau * thetaacc

#         theta = angle_normalize(theta)

#         state = (x, x_dot, theta, theta_dot)

#         done = int(
#             x < -x_threshold
#             or x > x_threshold
#             or theta < -theta_threshold_radians
#             or theta > theta_threshold_radians
#         )

#         if not done:
#             reward = 1.0
#         elif steps_beyond_done is None:
#             # Pole just fell!
#             steps_beyond_done = 0
#             reward = 1.0
#         else:
#             steps_beyond_done += 1
#             reward = 0.0

#         next_states.append(state)
#         rewards.append(reward)
#         dones.append(done)

#         # if i == 0:
#         #     print(states[i], actions[i])
#         #     print()
#         #     print("temp = ",temp)
#         #     print(f"thetaacc = {gravity * sintheta - costheta * temp}/{length * (4.0 / 3.0 - masspole * costheta**2 / total_mass)} = {thetaacc}")
#         #     print("xacc = ",xacc)
#         #     print("x = ",x)
#         #     print("x_dot = ",x_dot)
#         #     print("theta = ",theta)
#         #     print("theta_dot = ",theta_dot)
    
#     next_states = np.array(next_states)
#     rewards = np.array(rewards)
#     dones = np.array(dones)
#     return next_states, rewards, dones

def angle_normalize(x):
    return ((x + np.pi) % (2 * np.pi)) - np.pi

DEVICE_NAME_H2C0 = '/dev/xdma0_h2c_0'
DEVICE_NAME_C2H0 = '/dev/xdma0_c2h_0'

pc2fpga = os.open(DEVICE_NAME_H2C0, os.O_WRONLY)
fpga2pc = os.open(DEVICE_NAME_C2H0, os.O_RDONLY)

all_zero = np.zeros(512, dtype=np.float32)
os.pwrite(pc2fpga, all_zero, 0x0000)


ENV_NUM = 64
OBS_SPACE_N = 4
STA_WD_NUM = int(ENV_NUM * OBS_SPACE_N)
RWD_WD_NUM = int(ENV_NUM / 32)
DONE_WD_NUM = int(ENV_NUM / 32)
STA_OFFSET = 0
RWD_OFFSET = STA_WD_NUM * 4
DONE_OFFSET = (STA_WD_NUM + RWD_WD_NUM) * 4
start_flag = 0x00000001
start_flag = start_flag.to_bytes(4)
action_offset = int((ENV_NUM*OBS_SPACE_N) * 4)
read_offset = int(((ENV_NUM*OBS_SPACE_N) + (ENV_NUM/32) + 1) * 4)
read_byte_num = int(((ENV_NUM*OBS_SPACE_N) + (ENV_NUM/32) + (ENV_NUM/32)) * 4)

if __name__ == "__main__":
    start_time = time.time_ns()
    """parameters"""
    EPSILON_START = 1.0
    EPSILON_END = 0.02
    EPSILON_DECAY = 100000
    TARGET_UPDATE_FREQUENCY = 10

    """get the environment information"""
    n_state = 4
    n_action = 2

    agent = Agent(idx=0,
                  n_input=n_state,
                  n_output=n_action,
                  mode='train')
    s_ = np.zeros((ENV_NUM, 4))
    r = np.ones(ENV_NUM)
    done = np.zeros(ENV_NUM)
    """Main Training Loop"""
    n_episode = int(os.getenv('EPISODE_NUM'))
    n_time_step = int(os.getenv('STEP_NUM'))
    REWARD_BUFFER = np.zeros(shape=n_episode)
    TIME_BUFFER = np.zeros(shape=n_episode) 
    AVE_REWARD_BUFFER = np.zeros(shape=n_episode) 
    done_once = np.zeros(ENV_NUM, dtype=bool)
    for episode_i in range(n_episode):
        episode_reward = np.zeros(ENV_NUM)
        shape = (ENV_NUM, OBS_SPACE_N)
        s = np.random.uniform(-0.05, 0.05, size=shape).astype(np.float32)
        for step_i in range(n_time_step):
            epsilon = np.interp(episode_i * n_time_step + step_i, [0, EPSILON_DECAY], [EPSILON_START, EPSILON_END])  # interpolation
            random_sample = random.random()
            if random_sample <= epsilon:
                a = np.random.randint(0, 2, size=ENV_NUM).astype(np.uint8)
            else:
                a = agent.online_net.act(s).astype(np.uint8)
                # a = np.random.randint(0, 2, size=ENV_NUM).astype(np.uint8)
            start_normal_time = time.time_ns()
            # every_step_start_time = time.time_ns()
            a_bytes = np.packbits(a[::-1].reshape(-1, 32), axis=-1).view(np.uint32).tobytes()[::-1]
            src_data = s.tobytes() + a_bytes + start_flag
            # src_data = a_bytes + start_flag

            os.pwrite(pc2fpga, src_data, 0x0000)
            # os.pwrite(pc2fpga, src_data, action_offset)
            fpga_raw = os.pread(fpga2pc, read_byte_num, read_offset)
            # s_ = np.frombuffer(fpga_raw, dtype=np.float32, count=STA_WD_NUM, offset=STA_OFFSET).reshape(ENV_NUM, OBS_SPACE_N)
            # s_ = np.ndarray(buffer=fpga_raw, dtype=np.float32, shape=(ENV_NUM, OBS_SPACE_N), offset=STA_OFFSET)
            s_ = np.frombuffer(fpga_raw, dtype=np.float32, count=STA_WD_NUM, offset=STA_OFFSET).copy().reshape(ENV_NUM, OBS_SPACE_N)
            r = np.unpackbits(np.frombuffer(fpga_raw, dtype=np.uint8, count=RWD_WD_NUM*4, offset=RWD_OFFSET), bitorder='little')  
            done =  np.unpackbits(np.frombuffer(fpga_raw, dtype=np.uint8, count=DONE_WD_NUM*4, offset=DONE_OFFSET), bitorder='little')
            done_once = np.logical_or(done_once, done)

            condition = (s_[:, 2] < -3.14) | (s_[:, 2] > 3.14)
            s_[condition, 2] = angle_normalize(s_[condition, 2])

            for i in range(ENV_NUM):
                agent.memo.add_memo(s[i], a[i], r[i], done[i], s_[i])
                # print(f"Episode: {episode_i}, Step: {step_i}, Env: {i}, s: {s[i]}, a: {a[i]}, Reward: {r[i]}, Done: {done[i]}, s_: {s_[i]}")



            # ref_s_, ref_r, ref_done = step(s, a)
            s = s_
            episode_reward += r

            # diff_s_ = np.abs(np.array(ref_s_) - s_)
            # diff_r = np.abs(np.array(ref_r) - r)
            # diff_done = np.abs(np.array(ref_done) - done)
            # if (diff_s_ > 1e-4).any() | (diff_r > 1e-4).any() | (diff_done > 1e-4).any():
            # # if (diff_s_ > 1e-4).any():
            #     print(f"ERROR Episode: {episode_i}, Step: {step_i}")
            #     # print(f" s: {s[i]}, a: {a[i]}")
            #     # print(f"Reward: {r[i]}, Done: {done[i]}, s_: {s_[i]}")
            #     # print(f"ref_r: {ref_r[i]}, ref_done: {ref_done[i]}, ref_s_: {ref_s_[i]}")

            #     print("\nValues exceeding the threshold:")
            #     indices = np.where(diff_s_ > 1e-4)
            #     print("Indices of values exceeding the threshold in diff_s_:", indices)

            #     indices = np.where(diff_r > 1e-4)
            #     print("Indices of values exceeding the threshold in diff_r:", indices)

            #     indices = np.where(diff_done > 1e-4)
            #     print("Indices of values exceeding the threshold in diff_done:", indices)

            #     print("Source Data:")
            #     print("States:\n", s[indices[0]])
            #     print("Actions:\n", a[indices[0]])

            #     print("\nGround Truth:")
            #     print("Next States:\n", ref_s_[indices[0]])
            #     print("Rewards:\n", ref_r[indices[0]])
            #     print("Dones:\n", ref_done[indices[0]])

            #     print("\nFPGA Answer:")
            #     print("Next States:\n", s_[indices[0]])
            #     print("Rewards:\n", r[indices[0]])
            #     print("Dones:\n", done[indices[0]])

                # print("\nDifferenes:")
                # print("Diff Next States:\n", diff_s_)
                # print("Diff Rewards:\n", diff_r)
            # else:
            #     # print("Test passed!")
            #     pass
            # t1 = time.time()
            for i in range(ENV_NUM):
                if done[i]:
                    # 随机初始化该环境的状态
                    # print ("s[i]", s[i])
                    s[i] = np.random.uniform(-0.05, 0.05, size=OBS_SPACE_N).astype(np.float32)
            # Example arrays
            # s = np.random.rand(ENV_NUM, OBS_SPACE_N).astype(np.float32)  # Random initial states
            # done = np.random.choice([True, False], size=ENV_NUM)         # Randomly chosen done states

            # # Efficient resetting
            # # Find indices where `done` is True
            # indices_to_reset = np.where(done)[0]

            # # Generate random numbers directly into the required positions
            # s[indices_to_reset] = np.random.uniform(-0.05, 0.05, (len(indices_to_reset), OBS_SPACE_N)).astype(np.float32)

            # t2 = time.time()
            # print("Time for reset: ", t2 - t1)  

            if all(done_once):
            # if all(done):
            # if np.sum(done_once) >= ENV_NUM / 2:
                REWARD_BUFFER[episode_i] = np.mean(episode_reward)
                end_time = time.time_ns()
                TIME_BUFFER[episode_i] = end_time - start_time     
                AVE_REWARD_BUFFER[episode_i] = np.mean(REWARD_BUFFER[:episode_i])   
                s = np.random.uniform(-0.05, 0.05, size=shape).astype(np.float32)
                # a = np.random.randint(0, 2, size=ENV_NUM).astype(np.uint8)
                done_once = np.zeros(ENV_NUM, dtype=bool)                
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
            # print("s_float", s_float)
            # # print ("s",  s)
            # print ("a",  a)
            # print ("s_", s_)
            # print ("r",  r)
            # print ("done", done)

    all_end_time = time.time_ns()
    print(f"Total Time: {(all_end_time - start_time)/1e9} s")

with open(f'/data0/FPGA_GYM/python/CartPole/CartPole_pcie/data/reward_buffer_envnum{ENV_NUM}_{curve_idx}.txt', 'w') as f:
    for reward in REWARD_BUFFER:
        f.write(str(reward) + '\n')
with open(f'/data0/FPGA_GYM/python/CartPole/CartPole_pcie/data/time_buffer_envnum{ENV_NUM}_{curve_idx}.txt', 'w') as f:
    for this_time in TIME_BUFFER:
        f.write(str(this_time) + '\n')
with open(f'/data0/FPGA_GYM/python/CartPole/CartPole_pcie/data/ave_reward_buffer_envnum{ENV_NUM}_{curve_idx}.txt', 'w') as f:
    for ave_reward in AVE_REWARD_BUFFER:
        f.write(str(ave_reward) + '\n')    

episodes = list(range(1, len(REWARD_BUFFER) + 1))

# 绘制图表
plt.plot(episodes, REWARD_BUFFER, marker='o', linestyle='-', markersize=2)
plt.xlabel('Episode')
plt.ylabel('Reward')
plt.title('Reward Buffer vs. Episode')
plt.grid(True)
plt.savefig(f'/data0/FPGA_GYM/python/CartPole/CartPole_pcie/data/reward_episode_envnum{ENV_NUM}_{curve_idx}.png')


# 绘制图表
plt.figure()
plt.plot(TIME_BUFFER, REWARD_BUFFER, marker='o', linestyle='-', markersize=2)
plt.xlabel('Time')
plt.ylabel('Reward')
plt.title('Reward Buffer vs. Time')
plt.grid(True)
plt.savefig(f'/data0/FPGA_GYM/python/CartPole/CartPole_pcie/data/reward_time_envnum{ENV_NUM}_{curve_idx}.png')

# 绘制图表
plt.figure()
plt.plot(TIME_BUFFER, AVE_REWARD_BUFFER, marker='o', linestyle='-', markersize=2)
plt.xlabel('Time')
plt.ylabel('Ave_Reward')
plt.title('Ave Reward Buffer vs. Time')
plt.grid(True)
plt.savefig(f'/data0/FPGA_GYM/python/CartPole/CartPole_pcie/data/ave_reward_time_envnum{ENV_NUM}_{curve_idx}.png')

# 绘制图表
plt.figure()
plt.plot(episodes, AVE_REWARD_BUFFER, marker='o', linestyle='-', markersize=2)
plt.xlabel('episodes')
plt.ylabel('Ave_Reward')
plt.title('Ave Reward Buffer vs. episodes')
plt.grid(True)
plt.savefig(f'/data0/FPGA_GYM/python/CartPole/CartPole_pcie/data/ave_reward_episodes_envnum{ENV_NUM}_{curve_idx}.png')


os.close(pc2fpga)
os.close(fpga2pc)