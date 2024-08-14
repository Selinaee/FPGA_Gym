import gym
import numpy as np
import gymnasium as gym
import time
import numpy as np
num_steps = 20
def run_env(env_name, num_steps):
    env = gym.make(env_name)
    observation, info = env.reset()
    total_time = 0
    count_steps = 0
    print(f"observation_old: {observation}")
    for _ in range(num_steps):

        action = env.action_space.sample()

        start_time = time.time()
        observation, reward, terminated, truncated, info = env.step(action)
        print(f"action: {action}, observation: {observation}, reward: {reward}, terminated: {terminated}, truncated: {truncated}, info: {info}")
        end_time = time.time()
        total_time += (end_time - start_time)
        count_steps += 1
        if terminated or truncated:
            observation, info = env.reset()
    env.close()
    steps_per_sec = (count_steps / total_time) if total_time > 0 else 0
    return steps_per_sec

envs = [
    # "CartPole-v1",
    #   "MountainCar-v0", "MountainCarContinuous-v0", "Acrobot-v1", "Pendulum-v1",
    # "BipedalWalker-v3", "LunarLander-v2", "FrozenLake-v1", 
    "Taxi-v3"
    # , "Blackjack-v1", "CliffWalking-v0"
]
for env_name in envs:
    single_steps_per_sec = run_env(env_name, num_steps)    