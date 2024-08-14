import gymnasium as gym

env = gym.make('MountainCar-v0')
env.reset()

for i in range(10):
    if i == 0:
        print("#0;    // GT: ")
    else:
        print("#1500; // GT: ")
    a = env.action_space.sample()
    s, r, d, _, _ = env.step(a)
    print()
    if d == True:
        s, _ = env.reset()
        a = env.action_space.sample()