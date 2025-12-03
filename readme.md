
<h1 align="center"><img src="Docs/image/logo.png" alt="Description" width="200"/>
<h1 align="center">Parallel Reinforcement Learning Environments on FPGA 🌍</h1>


![Static Badge](https://img.shields.io/badge/test-passing-green)
![Static Badge](https://img.shields.io/badge/license-MIT-orange)

[Introduction](#introduction) | [Environments](#environments) | [Template](#template) | [Quickstart](#quickstart)｜[Training Example](#training-example)｜[Other Great Tools](#other-great-tools) 

<table>
  <tr>
    <td><img src="Docs/image/blackjack1.gif" alt="Image 1" width="100"/></td>
    <td><img src="Docs/image/cart_pole.gif" alt="Image 2" width="100"/></td>
    <td><img src="Docs/image/cliff_walking.gif" alt="Image 3" width="100"/></td>
    <td><img src="Docs/image/frozen_lake.gif" alt="Image 4" width="100"/></td>
  </tr>
  <tr>
    <td><img src="Docs/image/mountain_car.gif" alt="Image 5" width="100"/></td>
    <td><img src="Docs/image/pendulum.gif" alt="Image 6" width="100"/></td>
    <td><img src="Docs/image/taxi.gif" alt="Image 7" width="100"/></td>

  </tr>
    <td><img src="Docs/image/seaquest.gif" alt="Image 7" width="100"/></td>
</table>

## Introduction
💎 FPGA-Gym is the first diverse suite of scalable reinforcement learning environments based on FPGA technology.

It features very fast environment computation speed⚡️, large-scale parallelism🏅, and high flexibility🌊.

🏠 FPGA-Gym provides a [Template](Template/Pipeline.v) for parallel reinforcement learning environments on FPGA.
Its modular and parameterized features allow users to conveniently customize new environments without extensive FPGA knowledge.

🌌 It now features 7 environments based on this template!

## Environments
FPGA-Gym currently offers a variety of environments, including classical control, gridworld, and strategy games🌍. 
We are committed to continually expanding and enhancing the range of environments available.
| Environment                           | Category | Registered Version(s)                                           | Source  | Reference |
|---------------------------------------|----------|------------------------------------------------------------------|---------|-------------|
|  🍎 CartPole                            | Classic Control    | CartPole-v1                                                     | [code](Environment/CartPole) | [Click](https://gymnasium.farama.org/environments/classic_control/cart_pole/)    |
| 🪵 Pendulum                       | Classic Control    | Pendulum-v1                                                | [code](Environment/Pendulum) | [Click](https://gymnasium.farama.org/environments/classic_control/pendulum/)    |
|  ⛰️MountainCar                       | Classic Control    | MountainCar-v0                                              | [code](Environment/MountainCar) | [Click](https://gymnasium.farama.org/environments/classic_control/mountain_car/)   
| 🧊 FrozenLake                        | gridworld    | FrozenLake-v1                                                  | [code](Environment/FrozenLake) | [Click](https://gymnasium.farama.org/environments/toy_text/frozen_lake/)    |
|  🕳️ CliffWalking                          | gridworld    | CliffWalking-v0                | [code](Environment/CliffWalking) | [Click](https://gymnasium.farama.org/environments/toy_text/cliff_walking/)    |
| 🚕 Taxi                             | gridworld    | Taxi-v3                                 | [code](Environment/Taxi) | [Click](https://gymnasium.farama.org/environments/toy_text/taxi/)    |
|🃏 Blackjack                   | strategy games    | Blackjack-v1                                            | [code](Environment/BlackJack) | [Click](https://gymnasium.farama.org/environments/toy_text/blackjack/)    |
|🚢 Seaquest                   | Atari games    |          [Seaquest-v0](https://github.com/Selinaee/FPGA_Gym/blob/main/Environment/Atari/Seaquest/Seaquest_fig_210x160.py)                                  | [code](Environment/Seaquest) | [Click](https://atariage.com/manual_html_page.php?SoftwareLabelID=424)    |

## Template
we provide the verilog template and python template, The hierarchical structure of the file is illustrated as follows:
* [`FPGA-Top.v`](Template/FPGA_Top.v) This file is just a wrapper.
    * [`Pipline.v`](Template/Pipeline.v) This file defines our carefully designed parallel template.
        * [`Compute.v`](Template/Compute.v) This file defines the number of hardware compute resources. 
            * [`Compute_Single.v`](Template/Compute_Single.v) This file defines a single environment compute logic. This corresponds to a computational resource on the development board. If the user wants to add a new environment, they need to customize this file. We add CartPole as example in the template.
* [`FPGAEnv.py`](Template/FPGAEnv.py) This file defines the parent class. After inheriting the parent class, different environment son classes need to modify the main places as follows.
Please see the ["How to Add New Environments Using the FPGA-Gym Template"](User_Guide/Add_New_Environments.md) for details on how to add your own environment to the template.

## Quickstart
If the environment you need is already available in the FPGA-Gym library, we provide a guide on ["How to Use the FPGA-Gym Library"](User_Guide/Use_the_FPGA-Gym_Library.md). 

If the environment you need is not available in the FPGA-Gym library, we provide instructions on ["How to Add New Environments Using the FPGA-Gym Template"](User_Guide/Write _Single_Environment_Compute_in_Verilog.md).

Please see the ["How to Write Single Environment Compute in Verilog.md"](User_Guide) for details on how to add your own environment to the template.

You can see an example in this [Video](https://www.bilibili.com/video/BV12tV4e1EVw/?vd_source=3bfa69ca5962fd1ea8f48c880ae9844c). We demo
an example of PPO algorithm training based on FPGA-Gym.

You can see an example in this [Video](https://youtu.be/hgF3JZtLvZw). We demo
an example of how to write an atari game seaquest based on FPGA-Gym in verilog.


Preliminary software and hardware preparations:
1. An FPGA development board with PCIe
        Connect the FPGA development board with PCIe to the PCIe slot on the computer motherboard, just like the GPU.
2. PCIe driver: 
        Download the PCIe driver from [AMD's official website](https://support.xilinx.com/s/article/65444?language=en_US). 
        Follow the steps in the readme under the XDMA file.
3. Vivado software(A comprehensive design suite to turn our hardware behavior description language Verilog into the actual computing circuit inside the FPGA):
        Download the software Vivado from [AMD's official website](https://www.xilinx.com/support/download.html).
        We used version 2018.2 in our experiment, please open it with a later version of Vivado.

## Training Example
We provide examples of training, including [CartPole + DQN](Training_Example/CartPole_DQN), [CartPole + PPO](Training_Example/CartPole_PPO), [CliffWalking + DQN](Training_Example/CliffWalking_DQN).


## Other Great Tools

Other works have embraced the approach of parallel RL environments. In particular, we suggest users check out the following sister repositories:

In building

| Type                           | Name |  Paper                                 |  Feature|
|-------------------------------|------------------|---------------------------------------------------------------------------|-------------|
|  CPU                         |  [VectorEnv](https://gymnasium.farama.org/api/vector/)  | [Click]()                                                   | The base class for vectorized environments to run multiple independent copies of the same environment in parallel. | 
|  CPU                         |  [EnvPool](https://github.com/sail-sg/envpool)  | [Click]()                                                   |   A C++-based batched environment pool with pybind11 and thread pool. |

## Citing PEARL

If you find FPGA-Gym useful in your research, please cite our paper:

```bibtex
@inproceedings{li2025pearl,
  author    = {Li, Jiayi and Zhao, Hanrui and Yue, Wenjun and Fu, Yao and Shi, Dongyang and Fan, Aohui and Yang, Yifan and Yan, Bangqi},
  title     = {{PEARL}: FPGA-Based Reinforcement Learning Acceleration with Pipelined Parallel Environments},
  booktitle = {Proceedings of the 2025 Design, Automation \& Test in Europe Conference (DATE)},
  year      = {2025},
  pages     = {1--7},
  doi       = {10.23919/DATE64628.2025.10992886}
}
