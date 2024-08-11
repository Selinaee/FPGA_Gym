import numpy as np
import matplotlib.pyplot as plt

n = 5  # 数据集数量

def compute_mean_std(data_list):
    data = np.array(data_list)
    return data.mean(axis=0), data.std(axis=0)

def load_data(file_path, skip_zero=True):
    data = []
    with open(file_path, 'r') as f:
        for line in f:
            value = float(line.strip())
            if skip_zero and value == 0.0:
                continue
            data.append(value)
    return np.array(data)

# 存储各个数据集的基础路径
base_paths = {
    'vecenv': 'CartPole_vecenv/data/',
    'pcie': 'CartPole_pcie/data/',
    'envpool': 'CartPole_envpool/data/'
}

# 初始化数据集
time_buffers = {}
ave_rewards = {}
for dataset in ['vecenv', 'pcie', 'envpool']:
    time_buffers[dataset] = []
    ave_rewards[dataset] = []
    for i in range(n):
        time_buffer = load_data(f'{base_paths[dataset]}time_buffer_envnum64_{i}.txt')
        ave_reward = load_data(f'{base_paths[dataset]}ave_reward_buffer_envnum64_{i}.txt')
        time_buffers[dataset].append(time_buffer)
        ave_rewards[dataset].append(ave_reward)

# 处理每个数据集
mean_rewards = {}
std_rewards = {}
new_times = {}
for dataset in ['vecenv', 'pcie', 'envpool']:
    new_times[dataset] = np.unique(np.concatenate(time_buffers[dataset]))
    interpolated_rewards = [np.interp(new_times[dataset], time_buffers[dataset][i], ave_rewards[dataset][i]) for i in range(n)]
    mean_rewards[dataset], std_rewards[dataset] = compute_mean_std(interpolated_rewards)

# 绘图
plt.figure(figsize=(16, 6))
plt.subplot(1, 2, 1)
colors = {'vecenv': '#1E90FF', 'pcie': '#FF8C00', 'envpool': '#228B22'}

for dataset in ['vecenv', 'pcie', 'envpool']:
    plt.plot(new_times[dataset], mean_rewards[dataset], label=dataset.capitalize(), color=colors[dataset])
    plt.fill_between(new_times[dataset], mean_rewards[dataset] - std_rewards[dataset], mean_rewards[dataset] + std_rewards[dataset], color=colors[dataset], alpha=0.2)

plt.xlabel('Time')
plt.ylabel('Average Reward')
plt.title('Average Reward vs. Time with Confidence Intervals')
plt.legend()
plt.grid(True)
# plt.xlim(0, 1.5e11)

plt.subplot(1, 2, 2)
# for dataset in ['vecenv', 'pcie', 'envpool']:
#     episodes = np.arange(1, len(mean_rewards[dataset]) + 1)
#     plt.plot(episodes, mean_rewards[dataset], label=dataset.capitalize(), color=colors[dataset])
#     plt.fill_between(episodes, mean_rewards[dataset] - std_rewards[dataset], mean_rewards[dataset] + std_rewards[dataset], color=colors[dataset], alpha=0.2)

for dataset in ['vecenv', 'pcie', 'envpool']:
    episodes = np.linspace(1, 300, len(mean_rewards[dataset]))
    plt.plot(episodes, mean_rewards[dataset], label=dataset.capitalize(), color=colors[dataset])
    plt.fill_between(episodes, mean_rewards[dataset] - std_rewards[dataset], mean_rewards[dataset] + std_rewards[dataset], color=colors[dataset], alpha=0.2)
plt.xlabel('Episodes')
plt.ylabel('Average Reward')
plt.title('Detailed Comparison of Reward Curves')
plt.legend()
plt.grid(True)
# plt.xlim(0, 200)
plt.savefig('ave_reward_both.png')
plt.savefig('ave_reward_both.svg')


