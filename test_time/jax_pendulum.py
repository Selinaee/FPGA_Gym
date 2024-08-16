import jax
import jaxlib
print("JAX version:", jax.__version__)
print("JAXLIB version:", jaxlib.__version__)
# print("Devices:", jax.devices())

# jax.config.update("jax_enable_x64", True)
# jax.config.update("jax_platform_name", "cpu")
jax.config.update("jax_platform_name", "gpu")

from jax import vmap
import gymnax
import time
import pandas as pd

print("Devices:", jax.devices())
def run_jax(env_name, num_envs, num_steps):
    rng = jax.random.PRNGKey(0)
    rng, key_reset, key_act, key_step = jax.random.split(rng, 4)

    # Instantiate the environment & its settings.
    env, env_params = gymnax.make(env_name)

    # Reset the environment with vectorized reset function.
    reset_fn = vmap(env.reset, in_axes=(0, None))
    obs, state = reset_fn(jax.random.split(key_reset, num_envs), env_params)
    total_time = 0
    count_steps = 0
    for _ in range(num_steps):
        # Sample a random action using a vectorized sampling function.
        sample_fn = vmap(env.action_space(env_params).sample, in_axes=0)
        action = sample_fn(jax.random.split(key_act, num_envs))

        # Perform the step transition using a vectorized step function.
        step_fn = vmap(env.step, in_axes=(0, 0, 0, None))
        start_time = time.time_ns()
        n_obs, n_state, reward, done, _ = step_fn(jax.random.split(key_step, num_envs), state, action, env_params)
        end_time = time.time_ns()
        total_time += (end_time - start_time)
        count_steps += 1

    steps_per_sec = (count_steps / total_time) * 10e9 * num_envs if total_time > 0 else 0
    return steps_per_sec

envs = ['Pendulum-v1']
    # "MountainCar-v0", "MountainCarContinuous-v0", 
    # "Acrobot-v1", 
    # "Pendulum-v1",
    # "BipedalWalker-v3", "LunarLander-v2", "FrozenLake-v1", "Taxi-v3", "Blackjack-v1",
    # "CliffWalking-v0"]
parallels = [96, 192, 288, 384]

results = []

for env_name in envs:
    for para_num in parallels:
        steps_per_sec = run_jax(env_name, para_num, 10000)
        results.append({
            "Environment": env_name,
            "Parallel": para_num,
            "Steps_per_Sec": steps_per_sec
        })
        print(f"Env: {env_name}, Para: {para_num}, Steps per sec: {steps_per_sec}")

df = pd.DataFrame(results)


df.to_csv("jax_Pendulum_performance_gpu.csv", index=False)