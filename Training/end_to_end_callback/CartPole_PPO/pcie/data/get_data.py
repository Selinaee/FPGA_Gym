import pandas as pd
import os

def save_to_text(data, filename):
    """将数据保存到文本文件中"""
    with open(filename, 'w') as file:
        for value in data:
            file.write(f'{value}\n')

def process_files(base_path, file_prefix, n_files=5):
    """处理CSV文件并保存相关数据到文本文件"""
    for i in range(n_files):
        # 构建文件路径
        csv_path = os.path.join(base_path, f'{file_prefix}_{i}.csv')
        # 读取CSV文件
        data = pd.read_csv(csv_path)
        
        # 保存End Time到文本文件
        save_to_text(data['End Time'], os.path.join(base_path, f'time_buffer_envnum64_{i}.txt'))
        save_to_text(data['Average Reward'], os.path.join(base_path, f'ave_reward_buffer_envnum64_{i}.txt'))
        # 保存Average Reward到文本文件
        save_to_text(data['Reward'], os.path.join(base_path, f'reward_buffer_envnum64_{i}.txt'))
        # 保存Total Time Steps到文本文件
        save_to_text(data['Total Time Steps'], os.path.join(base_path, f'total_time_steps_buffer_envnum64_{i}.txt'))

# 基本路径和文件前缀
base_path = '/data0/FPGA_GYM/python/CartPole_PPO/pcie/data'
file_prefix = 'episode_data'

# 处理文件
process_files(base_path, file_prefix)
