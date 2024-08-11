import numpy as np
import matplotlib.pyplot as plt
import matplotlib as mpl
import matplotlib.pyplot as plt
from matplotlib.ticker import ScalarFormatter

# mpl.rcParams['font.size'] = 7
# plt.rcParams['font.sans-serif'] = 'Arial'
# plt.rcParams['font.style'] = 'normal'

def compute_mean_std(data_list):
    data = np.array(data_list)
    return data.mean(axis=0), data.std(axis=0)


def mm_to_inch(mm):
    return mm * 0.0393701


def load_data(file_path, skip_zero=True):
    data = []
    with open(file_path, 'r') as f:
        for line in f:
            value = float(line.strip())
            if skip_zero and value == 0.0:
                continue
            data.append(value)
    return np.array(data)


n = 5  # 数据集数量


# 存储各个数据集的基础路径
base_paths_cartpole_dqn = {
    'vecenv' : 'CartPole_DQN/CartPole_vecenv/data/',
    'pcie'   : 'CartPole_DQN/CartPole_pcie/data/',
    'envpool': 'CartPole_DQN/CartPole_envpool/data/'
}
base_paths_cliffwalking_dqn = {
    'vecenv' : 'CliffWalking_DQN/cliffwalking_frommehd_vecenv/data/',
    'pcie'   : 'CliffWalking_DQN/cliffwalking_frommehd_pcie/data/',
    'envpool': 'CliffWalking_DQN/cliffwalking_frommehd_envpool/data/'
}
base_paths_cartpole_ppo = {
    'vecenv' : 'CartPole_PPO/vecenv/data/',
    'pcie'   : 'CartPole_PPO/pcie_pure_action/data/',
    'envpool': 'CartPole_PPO/envpool/data/'
}

# 初始化数据集
time_buffers_cartpole_dqn = {}
ave_rewards_cartpole_dqn = {}
ave_max_time_cartpole_dqn = {}
for dataset in ['vecenv', 'pcie', 'envpool']:
    ave_max_time_cartpole_dqn[dataset] = 0
    time_buffers_cartpole_dqn[dataset] = []
    ave_rewards_cartpole_dqn[dataset] = []
    for i in range(n):
        time_buffer = load_data(f'{base_paths_cartpole_dqn[dataset]}time_buffer_envnum64_{i}.txt')
        ave_reward = load_data(f'{base_paths_cartpole_dqn[dataset]}ave_reward_buffer_envnum64_{i}.txt')
        ave_max_time_cartpole_dqn[dataset] += time_buffer.max()
        time_buffers_cartpole_dqn[dataset].append(time_buffer)
        ave_rewards_cartpole_dqn[dataset].append(ave_reward)
    ave_max_time_cartpole_dqn[dataset] /= n

time_buffers_cliffwalking_dqn = {}
ave_rewards_cliffwalking_dqn = {}
ave_max_time_cliffwalking_dqn = {}
for dataset in ['vecenv', 'pcie', 'envpool']:
    time_buffers_cliffwalking_dqn[dataset] = []
    ave_rewards_cliffwalking_dqn[dataset] = []
    ave_max_time_cliffwalking_dqn[dataset] = 0
    for i in range(n):
        time_buffer = load_data(f'{base_paths_cliffwalking_dqn[dataset]}time_buffer_envnum160_{i}.txt')
        ave_reward = load_data(f'{base_paths_cliffwalking_dqn[dataset]}ave_reward_buffer_envnum160_{i}.txt')
        ave_max_time_cliffwalking_dqn[dataset] += time_buffer.max()
        time_buffers_cliffwalking_dqn[dataset].append(time_buffer)
        ave_rewards_cliffwalking_dqn[dataset].append(ave_reward)
    ave_max_time_cliffwalking_dqn[dataset] /= n

ave_max_time_cartpole_ppo = {}
time_buffers_cartpole_ppo = {}
ave_rewards_cartpole_ppo = {}
time_step_buffers_cartpole_ppo = {}
for dataset in ['vecenv', 'pcie', 'envpool']:
    ave_max_time_cartpole_ppo[dataset] = 0
    time_buffers_cartpole_ppo[dataset] = []
    ave_rewards_cartpole_ppo[dataset] = []
    time_step_buffers_cartpole_ppo[dataset] = []
    for i in range(n):
        time_buffer = load_data(f'{base_paths_cartpole_ppo[dataset]}time_buffer_envnum64_{i}.txt')
        ave_reward = load_data(f'{base_paths_cartpole_ppo[dataset]}ave_reward_buffer_envnum64_{i}.txt')
        time_step_buffer = load_data(f'{base_paths_cartpole_ppo[dataset]}total_time_steps_buffer_envnum64_{i}.txt')
        time_buffer -= time_buffer.min() 
        ave_max_time_cartpole_ppo[dataset] += time_buffer.max()
        time_buffers_cartpole_ppo[dataset].append(time_buffer)
        ave_rewards_cartpole_ppo[dataset].append(ave_reward)
        time_step_buffers_cartpole_ppo[dataset].append(time_step_buffer)
    ave_max_time_cartpole_ppo[dataset] /= n

# 处理每个数据集
mean_rewards_cartpole_dqn = {}
std_rewards_cartpole_dqn = {}
new_times_cartpole_dqn = {}
for dataset in ['vecenv', 'pcie', 'envpool']:
    new_times_cartpole_dqn[dataset] = np.unique(np.concatenate(time_buffers_cartpole_dqn[dataset]))
    new_times_cartpole_dqn[dataset] = np.clip(new_times_cartpole_dqn[dataset], 0, ave_max_time_cartpole_dqn[dataset])
    interpolated_rewards = [np.interp(new_times_cartpole_dqn[dataset], time_buffers_cartpole_dqn[dataset][i], ave_rewards_cartpole_dqn[dataset][i]) for i in range(n)]
    mean_rewards_cartpole_dqn[dataset], std_rewards_cartpole_dqn[dataset] = compute_mean_std(interpolated_rewards)

mean_rewards_cliffwalking_dqn = {}
std_rewards_cliffwalking_dqn = {}
new_times_cliffwalking_dqn = {}
for dataset in ['vecenv', 'pcie', 'envpool']:
    new_times_cliffwalking_dqn[dataset] = np.unique(np.concatenate(time_buffers_cliffwalking_dqn[dataset]))
    new_times_cliffwalking_dqn[dataset] = np.clip(new_times_cliffwalking_dqn[dataset], 0, ave_max_time_cliffwalking_dqn[dataset])
    interpolated_rewards = [np.interp(new_times_cliffwalking_dqn[dataset], time_buffers_cliffwalking_dqn[dataset][i], ave_rewards_cliffwalking_dqn[dataset][i]) for i in range(n)]
    mean_rewards_cliffwalking_dqn[dataset], std_rewards_cliffwalking_dqn[dataset] = compute_mean_std(interpolated_rewards)

mean_rewards_cartpole_ppo = {}
std_rewards_cartpole_ppo = {}
new_times_cartpole_ppo = {}
new_time_steps_cartpole_ppo = {}
mean_rewards_step_cartpole_ppo = {}
std_rewards_step_cartpole_ppo = {}
for dataset in ['envpool', 'pcie', 'vecenv']:
    new_times_cartpole_ppo[dataset] = np.unique(np.concatenate(time_buffers_cartpole_ppo[dataset]))
    new_times_cartpole_ppo[dataset] = np.clip(new_times_cartpole_ppo[dataset], 0, ave_max_time_cartpole_ppo[dataset])

    new_time_steps_cartpole_ppo[dataset] = np.unique(np.concatenate(time_step_buffers_cartpole_ppo[dataset]))

    interpolated_rewards = [np.interp(new_times_cartpole_ppo[dataset], time_buffers_cartpole_ppo[dataset][i], ave_rewards_cartpole_ppo[dataset][i]) for i in range(n)]
    mean_rewards_cartpole_ppo[dataset], std_rewards_cartpole_ppo[dataset] = compute_mean_std(interpolated_rewards)
    
    interpolated_rewards_step = [np.interp(new_time_steps_cartpole_ppo[dataset], time_step_buffers_cartpole_ppo[dataset][i], ave_rewards_cartpole_ppo[dataset][i]) for i in range(n)]
    mean_rewards_step_cartpole_ppo[dataset], std_rewards_step_cartpole_ppo[dataset] = compute_mean_std(interpolated_rewards_step)

# 绘图
colors = {'vecenv': '#1E90FF', 'pcie': '#FF8C00', 'envpool': '#228B22'}

plt.figure(figsize=(mm_to_inch(200), mm_to_inch(50)))
ax = plt.subplot(1, 6, 3)
# CartPole: Average Reward vs. Time with Confidence Intervals
for dataset in ['vecenv', 'envpool']:
    plt.plot(new_times_cartpole_dqn[dataset], mean_rewards_cartpole_dqn[dataset], label=dataset.capitalize(), color=colors[dataset])
    plt.fill_between(new_times_cartpole_dqn[dataset], mean_rewards_cartpole_dqn[dataset] - std_rewards_cartpole_dqn[dataset], mean_rewards_cartpole_dqn[dataset] + std_rewards_cartpole_dqn[dataset], color=colors[dataset], alpha=0.2)
for dataset in ['pcie']:
    plt.plot(new_times_cartpole_dqn[dataset], mean_rewards_cartpole_dqn[dataset], label=dataset.capitalize(), color=colors[dataset], zorder=3)
    plt.fill_between(new_times_cartpole_dqn[dataset], mean_rewards_cartpole_dqn[dataset] - std_rewards_cartpole_dqn[dataset], mean_rewards_cartpole_dqn[dataset] + std_rewards_cartpole_dqn[dataset], color=colors[dataset], alpha=0.2, zorder=3)
plt.xlabel('Time')
formatter = ScalarFormatter(useMathText=True)
formatter.set_scientific(True)
formatter.set_powerlimits((-1, 1))
ax.yaxis.set_major_formatter(formatter)
# plt.ylabel('Average Reward')
# plt.title('DQN: CartPole\nReward vs. Time')
# plt.legend()
plt.grid(True)

# CartPole: Detailed Comparison of Reward Curves
plt.subplot(1, 6, 4)
for dataset in ['vecenv', 'envpool']:
    episodes = np.linspace(1, 300, len(mean_rewards_cartpole_dqn[dataset]))
    plt.plot(episodes, mean_rewards_cartpole_dqn[dataset], label=dataset.capitalize(), color=colors[dataset])
    plt.fill_between(episodes, mean_rewards_cartpole_dqn[dataset] - std_rewards_cartpole_dqn[dataset], mean_rewards_cartpole_dqn[dataset] + std_rewards_cartpole_dqn[dataset], color=colors[dataset], alpha=0.2)
for dataset in ['pcie']:
    episodes = np.linspace(1, 300, len(mean_rewards_cartpole_dqn[dataset]))
    plt.plot(episodes, mean_rewards_cartpole_dqn[dataset], label=dataset.capitalize(), color=colors[dataset], zorder = 2)
    plt.fill_between(episodes, mean_rewards_cartpole_dqn[dataset] - std_rewards_cartpole_dqn[dataset], mean_rewards_cartpole_dqn[dataset] + std_rewards_cartpole_dqn[dataset], color=colors[dataset], alpha=0.2, zorder = 2)

plt.xlabel('Episodes')
plt.yticks([100, 200, 300, 400], [])
# plt.ylabel('Average Reward')
# plt.title('DQN: CartPole\nReward Curves')
# plt.legend()
plt.grid(True)

# CliffWalking: Average Reward vs. Time with Confidence Intervals
ax = plt.subplot(1, 6, 5)
for dataset in ['vecenv', 'envpool']:
    plt.plot(new_times_cliffwalking_dqn[dataset], mean_rewards_cliffwalking_dqn[dataset], label=dataset.capitalize(), color=colors[dataset])
    plt.fill_between(new_times_cliffwalking_dqn[dataset], mean_rewards_cliffwalking_dqn[dataset] - std_rewards_cliffwalking_dqn[dataset], mean_rewards_cliffwalking_dqn[dataset] + std_rewards_cliffwalking_dqn[dataset], color=colors[dataset], alpha=0.2)
for dataset in ['pcie']:
    plt.plot(new_times_cliffwalking_dqn[dataset], mean_rewards_cliffwalking_dqn[dataset], label=dataset.capitalize(), color=colors[dataset], zorder = 2)
    plt.fill_between(new_times_cliffwalking_dqn[dataset], mean_rewards_cliffwalking_dqn[dataset] - std_rewards_cliffwalking_dqn[dataset], mean_rewards_cliffwalking_dqn[dataset] + std_rewards_cliffwalking_dqn[dataset], color=colors[dataset], alpha=0.2, zorder = 2)
plt.xlabel('Time')
formatter = ScalarFormatter(useMathText=True)
formatter.set_scientific(True)
formatter.set_powerlimits((-1, 1))
ax.yaxis.set_major_formatter(formatter)
# plt.ylabel('Average Reward')
# plt.title('DQN: CliffWalking\nReward vs. Time')
# plt.legend()
plt.grid(True)

# CliffWalking: Detailed Comparison of Reward Curves
plt.subplot(1, 6, 6)
for dataset in ['vecenv', 'envpool']:
    episodes = np.linspace(1, 300, len(mean_rewards_cliffwalking_dqn[dataset]))
    plt.plot(episodes, mean_rewards_cliffwalking_dqn[dataset], label=dataset.capitalize(), color=colors[dataset])
    plt.fill_between(episodes, mean_rewards_cliffwalking_dqn[dataset] - std_rewards_cliffwalking_dqn[dataset], mean_rewards_cliffwalking_dqn[dataset] + std_rewards_cliffwalking_dqn[dataset], color=colors[dataset], alpha=0.2)
for dataset in ['pcie']:
    episodes = np.linspace(1, 300, len(mean_rewards_cliffwalking_dqn[dataset]))
    plt.plot(episodes, mean_rewards_cliffwalking_dqn[dataset], label=dataset.capitalize(), color=colors[dataset], zorder = 2)
    plt.fill_between(episodes, mean_rewards_cliffwalking_dqn[dataset] - std_rewards_cliffwalking_dqn[dataset], mean_rewards_cliffwalking_dqn[dataset] + std_rewards_cliffwalking_dqn[dataset], color=colors[dataset], alpha=0.2, zorder = 2)
plt.xlabel('Episodes')
plt.yticks([-1000, -750, -500, -250], [])
# plt.ylabel('Average Reward')
plt.title('DQN: CliffWalking\nReward Curves')
# plt.legend()
plt.grid(True)

ax = plt.subplot(1, 6, 1)
for dataset in ['envpool', 'vecenv']:
    # print(f"{dataset:7} Total Time: {new_times_cartpole_ppo[dataset][-1]} s")
    plt.plot(new_times_cartpole_ppo[dataset], mean_rewards_cartpole_ppo[dataset], label=dataset.capitalize(), color=colors[dataset])
    plt.fill_between(new_times_cartpole_ppo[dataset], mean_rewards_cartpole_ppo[dataset] - 3 * std_rewards_cartpole_ppo[dataset], mean_rewards_cartpole_ppo[dataset] + 3 * std_rewards_cartpole_ppo[dataset], color=colors[dataset], alpha=0.2)
for dataset in ['pcie']:
    # print(f"{dataset:7} Total Time: {new_times_cartpole_ppo[dataset][-1]} s")
    plt.plot(new_times_cartpole_ppo[dataset], mean_rewards_cartpole_ppo[dataset], label=dataset.capitalize(), color=colors[dataset], zorder = 2)
    plt.fill_between(new_times_cartpole_ppo[dataset], mean_rewards_cartpole_ppo[dataset] - 3 * std_rewards_cartpole_ppo[dataset], mean_rewards_cartpole_ppo[dataset] + 3 * std_rewards_cartpole_ppo[dataset], color=colors[dataset], alpha=0.2, zorder = 2)

plt.xlabel('Time')
formatter = ScalarFormatter(useMathText=True)
formatter.set_scientific(True)
formatter.set_powerlimits((-1, 1))
ax.yaxis.set_major_formatter(formatter)
# plt.ylabel('Average Reward')
# plt.title('PPO: CartPole\nReward vs. Time')
# plt.legend()
plt.grid(True)

plt.subplot(1, 6, 2)
for dataset in ['envpool', 'vecenv']:
    # print(f"{dataset:7} Total Steps: {new_time_steps_cartpole_ppo[dataset][-1]}")
    plt.plot(new_time_steps_cartpole_ppo[dataset], mean_rewards_step_cartpole_ppo[dataset], label=dataset.capitalize(), color=colors[dataset])
    plt.fill_between(new_time_steps_cartpole_ppo[dataset], mean_rewards_step_cartpole_ppo[dataset] - 3 * std_rewards_step_cartpole_ppo[dataset], mean_rewards_step_cartpole_ppo[dataset] + 3 * std_rewards_step_cartpole_ppo[dataset], color=colors[dataset], alpha=0.2)
for dataset in ['pcie']:
    # print(f"{dataset:7} Total Steps: {new_time_steps_cartpole_ppo[dataset][-1]}")
    plt.plot(new_time_steps_cartpole_ppo[dataset], mean_rewards_step_cartpole_ppo[dataset], label=dataset.capitalize(), color=colors[dataset], zorder = 2)
    plt.fill_between(new_time_steps_cartpole_ppo[dataset], mean_rewards_step_cartpole_ppo[dataset] - 3 * std_rewards_step_cartpole_ppo[dataset], mean_rewards_step_cartpole_ppo[dataset] + 3 * std_rewards_step_cartpole_ppo[dataset], color=colors[dataset], alpha=0.2, zorder = 0)
plt.xlabel('Steps')
plt.yticks([0, 100, 200, 300], [])
# plt.ylabel('Average Reward')
# plt.title('PPO: CartPole\nReward Curves')
# plt.legend()
plt.grid(True)


plt.tight_layout()
plt.subplots_adjust(wspace=0.3)
plt.savefig('ave_reward_both_combined.pdf')
plt.savefig('ave_reward_both_combined.svg')
plt.savefig('ave_reward_both_combined.png')
# plt.show()
