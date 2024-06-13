import os
import gc
import torch
import pygame
import numpy as np
import torch.nn as nn
import gymnasium as gym
import torch.optim as optim
from collections import deque
import matplotlib.pyplot as plt
import time
import argparse
import cProfile

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

# device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
# # device = torch.device("cpu")
device = torch.device("cpu")
torch.set_num_threads(20)  # 可以设置使用更多的CPU核心

print(f"Device: {device}")
gc.collect()
torch.cuda.empty_cache()
os.environ['CUDA_LAUNCH_BLOCKING'] = '1' # Used for debugging; CUDA related errors shown immediately.

# Seed everything for reproducible results
seed = args.seed
np.random.seed(seed)
np.random.default_rng(seed)
os.environ['PYTHONHASHSEED'] = str(seed)
torch.manual_seed(seed)
if torch.cuda.is_available():
    torch.cuda.manual_seed(seed)
    torch.backends.cudnn.deterministic = True
    torch.backends.cudnn.benchmark = False


class ReplayMemory:
    def __init__(self, capacity):
    
        self.capacity = capacity
        self.states       = deque(maxlen=capacity)
        self.actions      = deque(maxlen=capacity)
        self.next_states  = deque(maxlen=capacity)
        self.rewards      = deque(maxlen=capacity)
        self.dones        = deque(maxlen=capacity)


    def store(self, state, action, next_state, reward, done):
        """
        Append (store) the transitions to their respective deques
        """

        self.states.append(state)
        self.actions.append(action)
        self.next_states.append(next_state)
        self.rewards.append(reward)
        self.dones.append(done)


    def sample(self, batch_size):
        """
        Randomly sample transitions from memory, then convert sampled transitions
        to tensors and move to device (CPU or GPU).
        """

        indices = np.random.choice(len(self), size=batch_size, replace=False)

        states = torch.stack([torch.as_tensor(self.states[i], dtype=torch.float32, device=device) for i in indices]).to(device)
        actions = torch.as_tensor([self.actions[i] for i in indices], dtype=torch.long, device=device)
        next_states = torch.stack([torch.as_tensor(self.next_states[i], dtype=torch.float32, device=device) for i in indices]).to(device)
        rewards = torch.as_tensor([self.rewards[i] for i in indices], dtype=torch.float32, device=device)
        dones = torch.as_tensor([self.dones[i] for i in indices], dtype=torch.bool, device=device)

        return states, actions, next_states, rewards, dones


    def __len__(self):
        """
        To check how many samples are stored in the memory. self.dones deque
        represents the length of the entire memory.
        """

        return len(self.dones)


class DQN_Network(nn.Module):
    """
    The Deep Q-Network (DQN) model for reinforcement learning.
    This network consists of Fully Connected (FC) layers with ReLU activation functions.
    """

    def __init__(self, num_actions, input_dim):
        """
        Initialize the DQN network.

        Parameters:
            num_actions (int): The number of possible actions in the environment.
            input_dim (int): The dimensionality of the input state space.
        """

        super(DQN_Network, self).__init__()

        self.FC = nn.Sequential(
            nn.Linear(input_dim, 12),
            nn.ReLU(inplace=True),
            nn.Linear(12, 8),
            nn.ReLU(inplace=True),
            nn.Linear(8, num_actions)
            )

        # Initialize FC layer weights using He initialization
        for layer in [self.FC]:
            for module in layer:
                if isinstance(module, nn.Linear):
                    nn.init.kaiming_uniform_(module.weight, nonlinearity='relu')


    def forward(self, x):
        """
        Forward pass of the network to find the Q-values of the actions.

        Parameters:
            x (torch.Tensor): Input tensor representing the state.

        Returns:
            Q (torch.Tensor): Tensor containing Q-values for each action.
        """
        Q = self.FC(x)
        return Q


class DQN_Agent:
    """
    DQN Agent Class. This class defines some key elements of the DQN algorithm,
    such as the learning method, hard update, and action selection based on the
    Q-value of actions or the epsilon-greedy policy.
    """

    def __init__(self, env, epsilon_max, epsilon_min, epsilon_decay,
                  clip_grad_norm, learning_rate, discount, memory_capacity):

        # To save the history of network loss
        self.loss_history = []
        self.running_loss = 0
        self.learned_counts = 0

        # RL hyperparameters
        self.epsilon_max   = epsilon_max
        self.epsilon_min   = epsilon_min
        self.epsilon_decay = epsilon_decay
        self.discount      = discount

        self.action_space  = env.action_space
        self.action_space.seed(seed) # Set the seed to get reproducible results when sampling the action space
        self.observation_space = env.observation_space
        self.replay_memory = ReplayMemory(memory_capacity)

        # Initiate the network models
        self.main_network = DQN_Network(num_actions=4, input_dim=48).to(device)
        self.target_network = DQN_Network(num_actions=4, input_dim=48).to(device).eval()
        self.target_network.load_state_dict(self.main_network.state_dict())

        self.clip_grad_norm = clip_grad_norm # For clipping exploding gradients caused by high reward value
        self.critertion = nn.MSELoss()
        self.optimizer = optim.Adam(self.main_network.parameters(), lr=learning_rate)


    def select_action(self, state):
        # print("state: ", state)
        # print("state_shape", state.shape)
        """
        Selects an action using epsilon-greedy strategy OR based on the Q-values.

        Parameters:
            state (torch.Tensor): Input tensor representing the state.

        Returns:
            action (int): The selected action.
        """

        # Exploration: epsilon-greedy
        if np.random.random() < self.epsilon_max:
            return self.action_space.sample()

        # Exploitation: the action is selected based on the Q-values.
        with torch.no_grad():

            Q_values = self.main_network(state)
            action = torch.argmax(Q_values, dim=1).tolist()
            return action


    def learn(self, batch_size, done):
        """
        Train the main network using a batch of experiences sampled from the replay memory.

        Parameters:
            batch_size (int): The number of experiences to sample from the replay memory.
            done (bool): Indicates whether the episode is done or not. If done,
            calculate the loss of the episode and append it in a list for plot.
        """

        # Sample a batch of experiences from the replay memory
        states, actions, next_states, rewards, dones = self.replay_memory.sample(batch_size)


        # # The following prints are for debugging. Use them to indicate the correct shape of the tensors.
        # print('Before--------Before')
        # print("states:", states.shape)
        # print("actions:", actions.shape)
        # print("next_states:", next_states.shape)
        # print("rewards:", rewards.shape)
        # print("dones:", dones.shape)


        # # Preprocess the data for training
        # states        = states.unsqueeze(1)
        # next_states   = next_states.unsqueeze(1)
        actions       = actions.unsqueeze(1)
        rewards       = rewards.unsqueeze(1)
        dones         = dones.unsqueeze(1)


        # # The following prints are for debugging. Use them to indicate the correct shape of the tensors.
        # print()
        # print('After--------After')
        # print("states:", states.shape)
        # print("actions:", actions.shape)
        # print("next_states:", next_states.shape)
        # print("rewards:", rewards.shape)
        # print("dones:", dones.shape)

        predicted_q = self.main_network(states) # forward pass through the main network to find the Q-values of the states
        predicted_q = predicted_q.gather(dim=1, index=actions) # selecting the Q-values of the actions that were actually taken

        # Compute the maximum Q-value for the next states using the target network
        with torch.no_grad():
            next_target_q_value = self.target_network(next_states).max(dim=1, keepdim=True)[0] # not argmax (cause we want the maxmimum q-value, not the action that maximize it)


        next_target_q_value [dones.any()] = 0 # Set the Q-value for terminal states to zero
        y_js = rewards + (self.discount * next_target_q_value) # Compute the target Q-values
        loss = self.critertion(predicted_q, y_js) # Compute the loss

        # Update the running loss and learned counts for logging and plotting
        self.running_loss += loss.item()
        self.learned_counts += 1

        if done:
            episode_loss = self.running_loss / self.learned_counts # The average loss for the episode
            self.loss_history.append(episode_loss) # Append the episode loss to the loss history for plotting
            # Reset the running loss and learned counts
            self.running_loss = 0
            self.learned_counts = 0

        self.optimizer.zero_grad() # Zero the gradients
        loss.backward() # Perform backward pass and update the gradients

        # # Uncomment the following two lines to find the best value for clipping gradient (Comment torch.nn.utils.clip_grad_norm_ while uncommenting the following two lines)
        # grad_norm_before_clip = torch.nn.utils.clip_grad_norm_(self.main_network.parameters(), float('inf'))
        # print("Gradient norm before clipping:", grad_norm_before_clip)

        # Clip the gradients to prevent exploding gradients
        torch.nn.utils.clip_grad_norm_(self.main_network.parameters(), self.clip_grad_norm)

        self.optimizer.step() # Update the parameters of the main network using the optimizer


    def hard_update(self):
        """
        Navie update: Update the target network parameters by directly copying
        the parameters from the main network.
        """

        self.target_network.load_state_dict(self.main_network.state_dict())


    def update_epsilon(self):
        """
        Update the value of epsilon for epsilon-greedy exploration.

        This method decreases epsilon over time according to a decay factor, ensuring
        that the agent becomes less exploratory and more exploitative as training progresses.
        """

        self.epsilon_max = max(self.epsilon_min, self.epsilon_max * self.epsilon_decay)


    def save(self, path):
        """
        Save the parameters of the main network to a file with .pth extention.

        """
        torch.save(self.main_network.state_dict(), path)


class Model_TrainTest:
    def __init__(self, hyperparams):

        self.REWARD_BUFFER = np.zeros(hyperparams["max_episodes"])
        self.TIME_BUFFER = np.zeros(hyperparams["max_episodes"])
        self.AVE_REWARD_BUFFER = np.zeros(hyperparams["max_episodes"])

        # Define RL Hyperparameters
        self.train_mode             = hyperparams["train_mode"]
        self.RL_load_path           = hyperparams["RL_load_path"]
        self.save_path              = hyperparams["save_path"]
        self.save_interval          = hyperparams["save_interval"]

        self.clip_grad_norm         = hyperparams["clip_grad_norm"]
        self.learning_rate          = hyperparams["learning_rate"]
        self.discount_factor        = hyperparams["discount_factor"]
        self.batch_size             = hyperparams["batch_size"]
        self.update_frequency       = hyperparams["update_frequency"]
        self.max_episodes           = hyperparams["max_episodes"]
        self.max_steps              = hyperparams["max_steps"]
        self.render                 = hyperparams["render"]

        self.epsilon_max            = hyperparams["epsilon_max"]
        self.epsilon_min            = hyperparams["epsilon_min"]
        self.epsilon_decay          = hyperparams["epsilon_decay"]

        self.memory_capacity        = hyperparams["memory_capacity"]

        self.render_fps             = hyperparams["render_fps"]
        self.env_num                = hyperparams["env_num"]
        # Define Env
        # self.env = gym.make('CliffWalking-v0', max_episode_steps=self.max_steps,
        #                     render_mode="human" if self.render else None)

        self.env = gym.make_vec(id='CliffWalking-v0', num_envs=hyperparams["env_num"])
        # self.env.metadata['render_fps'] = self.render_fps # For max frame rate make it 0

        # Define the agent class
        self.agent = DQN_Agent( env               = self.env,
                                epsilon_max       = self.epsilon_max,
                                epsilon_min       = self.epsilon_min,
                                epsilon_decay     = self.epsilon_decay,
                                clip_grad_norm    = self.clip_grad_norm,
                                learning_rate     = self.learning_rate,
                                discount          = self.discount_factor,
                                memory_capacity   = self.memory_capacity)

    def state_preprocess(self, state: list, num_states: int):
        """
        Convert a list of states to a tensor of one-hot encoded vectors.

        Args:
        - state (list): A list of integers representing states.
        - num_states (int): Total number of states.

        Returns:
        - onehot_tensor (torch.Tensor): A tensor containing the one-hot encoded vectors for each state.
        """
        onehot_tensor = torch.zeros(len(state), num_states, dtype=torch.float32)
        for i, s in enumerate(state):
            onehot_tensor[i][s] = 1
        return onehot_tensor


    def train(self):
        """
        Reinforcement learning training loop.
        """
        strat_time = time.time_ns()
        total_steps = 0
        # self.REWARD_BUFFER = np.zeros(shape=self.max_episodes)
        # self.TIME_BUFFER = np.zeros(shape=self.max_episodes)
        # self.AVE_REWARD_BUFFER = np.zeros(shape=self.max_episodes)  
        # Training loop over episodes
        for episode in range(0, self.max_episodes):
            start_episode_time = time.time_ns()
            state, _ = self.env.reset(seed=seed)
            state = self.state_preprocess(state, num_states=48)
            done = False
            truncation = False
            step_size = 0
            episode_reward = 0

            while not np.any(done) and not np.any(truncation):
                # action_start_time = time.time_ns()
                action = self.agent.select_action(state)
                # action_end_time = time.time_ns()
                # action_time = (action_end_time - action_start_time)/10**9
                # print(f"Action time: {action_time}")
                # time_step_start = time.time_ns()
                next_state, reward, done, truncation, _ = self.env.step(action)
                # time_step_end = time.time_ns()
                # time_step = (time_step_end - time_step_start)/10**9
                # print(f"Time step: {time_step}")

                next_state = self.state_preprocess(next_state, num_states=48)

                for i in range(len(state)):
                    self.agent.replay_memory.store(state[i], action[i], next_state[i], reward[i], done[i])
                # train_start_time = time.time_ns()
                if len(self.agent.replay_memory) > self.batch_size:
                    self.agent.learn(self.batch_size, (np.any(done) or np.any(truncation)))

                    # Update target-network weights
                    if total_steps % self.update_frequency == 0:
                        self.agent.hard_update()
                # train_end_time = time.time_ns()
                # train_time = (train_end_time - train_start_time)/10**9
                # print(f"Train time: {train_time}")

                state = next_state
                episode_reward += reward
                step_size +=1

            episode_end_time = time.time_ns()
            episode_time = (episode_end_time - start_time)/10**9
            self.TIME_BUFFER[episode] = episode_time
            self.REWARD_BUFFER[episode] = np.mean(episode_reward)
            self.AVE_REWARD_BUFFER[episode] = np.mean(self.REWARD_BUFFER[:episode])
            # Appends for tracking history
            # print (f"Episode: {episode}, Reward: {episode_reward}, Time: {episode_time}, Average Reward: {self.AVE_REWARD_BUFFER[episode]}")
            total_steps += step_size

            # Decay epsilon at the end of each episode
            self.agent.update_epsilon()

            #-- based on interval
            # if episode % self.save_interval == 0:
            #     self.agent.save(self.save_path + '_' + f'{episode}' + '.pth')

            reward_str = ', '.join([f"{r:.2f}" for r in episode_reward])
            result = (f"Episode: {episode}, "
                      f"Total Steps: {total_steps}, "
                      f"Ep Step: {step_size}, "
                    #   f"Raw Reward: {episode_reward[0]:.2f}, "
                      f"Raw Reward: {reward_str}, "
                      f"Epsilon: {self.agent.epsilon_max:.2f}")
            if episode % 10 == 0:
                print(result) 

        return total_steps


    def test(self, max_episodes):
        """
        Reinforcement learning policy evaluation.
        """

        # Load the weights of the test_network
        self.agent.main_network.load_state_dict(torch.load(self.RL_load_path))
        self.agent.main_network.eval()

        # Testing loop over episodes
        for episode in range(1, max_episodes+1):
            state, _ = self.env.reset(seed=seed)
            done = False
            truncation = False
            step_size = 0
            episode_reward = 0

            while not np.any(done) and not np.any(truncation):
                state = self.state_preprocess(state, num_states=48)
                action = self.agent.select_action(state)
                next_state, reward, done, truncation, _ = self.env.step(action)
                # print(f"run test")
                state = next_state
                episode_reward += reward
                step_size += 1
            reward_str = ', '.join([f"{r:.2f}" for r in episode_reward])
            # Print log
            result = (f"Episode: {episode}, "
                      f"Steps: {step_size:}, "
                      f"Raw Reward: {reward_str}, ")
                    #   f"Reward: {episode_reward:.2f}, ")
            print(result)

        pygame.quit() # close the rendering window

    

if __name__ == '__main__':
    # Parameters:

    start_time = time.time_ns()
    train_mode = True
    render = not train_mode
    render = None

    RL_hyperparams = {
        # "max_episodes"          : 10, 
        "train_mode"            : train_mode,
        "RL_load_path"          : './final_weights' + '_' + '800' + '.pth',
        "save_path"             : './final_weights',
        "save_interval"         : 100,

        "clip_grad_norm"        : 4,
        "learning_rate"         : 1e-3,
        "discount_factor"       : 0.92,
        "batch_size"            : 32,
        "update_frequency"      : 10,
        "max_episodes"          : 200         if train_mode else 2,
        "max_steps"             : 500,
        "render"                : render,

        "epsilon_max"           : 0.999         if train_mode else -1,
        "epsilon_min"           : 0.01,
        "epsilon_decay"         : 0.994,

        "memory_capacity"       : 10_000000        if train_mode else 0,

        "render_fps"            : 6,
        "env_num"               : 160
        }
    # Run
    DRL = Model_TrainTest(RL_hyperparams) # Define the instance
    ENV_NUM = Model_TrainTest(RL_hyperparams).env_num
    print(f"ENV_NUM: {ENV_NUM}")
    # Train
    if train_mode:
        total_steps = DRL.train()
    else:
        # Test
        DRL.test(max_episodes = RL_hyperparams['max_episodes'])


    
    total_end_time = time.time_ns()
    total_time = total_end_time - start_time
    print(f"Time cost: {(total_end_time - start_time) / 1e9}s")
  
    steps_per_second =  total_steps / (total_time / 1e9)
    print(f"steps_per_second: {steps_per_second}")
# # 运行并分析main函数
# import cProfile
# cProfile.run('main()', 'output_2.txt')

with open(f'/data0/FPGA_GYM/python/CliffWalking/cliffwalking_frommehd_vecenv/data/reward_buffer_envnum{ENV_NUM}_{curve_idx}.txt', 'w') as f:
    for reward in DRL.REWARD_BUFFER:
        f.write(str(reward) + '\n')
with open(f'/data0/FPGA_GYM/python/CliffWalking/cliffwalking_frommehd_vecenv/data/time_buffer_envnum{ENV_NUM}_{curve_idx}.txt', 'w') as f:
    for this_time in DRL.TIME_BUFFER:
        f.write(str(this_time) + '\n')
with open(f'/data0/FPGA_GYM/python/CliffWalking/cliffwalking_frommehd_vecenv/data/ave_reward_buffer_envnum{ENV_NUM}_{curve_idx}.txt', 'w') as f:
    for ave_reward in DRL.AVE_REWARD_BUFFER:
        f.write(str(ave_reward) + '\n')    


episodes = list(range(1, len(DRL.REWARD_BUFFER) + 1))

# 绘制图表
plt.plot(episodes, DRL.REWARD_BUFFER, marker='o', linestyle='-', markersize=2)
plt.xlabel('Episode')
plt.ylabel('Reward')
plt.title('Reward Buffer vs. Episode')
plt.grid(True)
plt.savefig(f'/data0/FPGA_GYM/python/CliffWalking/cliffwalking_frommehd_vecenv/data/reward_episode_envnum{ENV_NUM}_{curve_idx}.png')


# 绘制图表
plt.figure()
plt.plot(DRL.TIME_BUFFER, DRL.REWARD_BUFFER, marker='o', linestyle='-', markersize=2)
plt.xlabel('Time')
plt.ylabel('Reward')
plt.title('Reward Buffer vs. Time')
plt.grid(True)
plt.savefig(f'/data0/FPGA_GYM/python/CliffWalking/cliffwalking_frommehd_vecenv/data/reward_time_envnum{ENV_NUM}_{curve_idx}.png')

# 绘制图表
plt.figure()
plt.plot(DRL.TIME_BUFFER, DRL.AVE_REWARD_BUFFER, marker='o', linestyle='-', markersize=2)
plt.xlabel('Time')
plt.ylabel('Ave_Reward')
plt.title('Ave Reward Buffer vs. Time')
plt.grid(True)
plt.savefig(f'/data0/FPGA_GYM/python/CliffWalking/cliffwalking_frommehd_vecenv/data/ave_reward_time_envnum{ENV_NUM}_{curve_idx}.png')

# 绘制图表
plt.figure()
plt.plot(episodes, DRL.AVE_REWARD_BUFFER, marker='o', linestyle='-', markersize=2)
plt.xlabel('episodes')
plt.ylabel('Ave_Reward')
plt.title('Ave Reward Buffer vs. episodes')
plt.grid(True)
plt.savefig(f'/data0/FPGA_GYM/python/CliffWalking/cliffwalking_frommehd_vecenv/data/ave_reward_episodes_envnum{ENV_NUM}_{curve_idx}.png')
                        