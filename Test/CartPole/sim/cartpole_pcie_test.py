import math
import numpy as np
import os
import time

DEVICE_NAME_H2C0 = '/dev/xdma0_h2c_0'
DEVICE_NAME_C2H0 = '/dev/xdma0_c2h_0'
state_hex = 'state.txt'
action_hex = 'action.txt'
next_state_txt = 'next_state.txt'

iterations = 10000
ENV_NUM = 64
OBS_SPACE_N = 4

start_flag = 0x00000001
start_flag = start_flag.to_bytes(4, byteorder='little')
clear_flag = 0x00000002
clear_flag = clear_flag.to_bytes(4, byteorder='little')
action_offset = int((ENV_NUM*OBS_SPACE_N) * 4)
read_offset = int(((ENV_NUM*OBS_SPACE_N) + (ENV_NUM/32) + 1) * 4)
read_byte_num = int(((ENV_NUM*OBS_SPACE_N) + (ENV_NUM/32) + (ENV_NUM/32)) * 4)

pc2fpga = os.open(DEVICE_NAME_H2C0, os.O_WRONLY)
fpga2pc = os.open(DEVICE_NAME_C2H0, os.O_RDONLY)

all_zero = np.zeros(4096, dtype=np.float32)
os.pwrite(pc2fpga, all_zero, 0x0000)

def write_state(float_array, filepath=''):
    hex_array = []
    byte_array = float_array.tobytes()
    for i in range(float_array.size):
        single_float_bytes = byte_array[i*4:(i+1)*4] # Extract each float as bytes (4 bytes per float32)
        hex_representation = ''.join(f'{c:02x}' for c in single_float_bytes[::-1]) # Convert to binary
        hex_array.append(hex_representation)
    hex_array = np.array(hex_array).reshape(float_array.shape)

    if filepath:
        cnt = 0
        with open(filepath, 'w') as file:
            file.write('        initial begin\n')
            file.write('            #0  ram_i_wr1 = 1\'b1; ram_i_addr1 = 32\'d0;  ram_i_data1 = 32\'d0;\n\n')
            for i in hex_array.flatten():
                if cnt == 0:
                    file.write(f'            #20 ram_i_wr1 = 1\'b0; ram_i_addr1 = 32\'d{cnt}; ram_i_data1 = 32\'h{i}; // x0:{float_array[0][0]}\n')
                else:
                    idx0 = cnt // 4
                    idx1 = cnt % 4
                    if idx1 == 0:
                        file.write(f'            #10 ram_i_wr1 = 1\'b0; ram_i_addr1 = 32\'d{cnt}; ram_i_data1 = 32\'h{i}; // x{idx0}:{float_array[idx0][idx1]}\n')
                    elif idx1 == 1:
                        file.write(f'            #10 ram_i_wr1 = 1\'b0; ram_i_addr1 = 32\'d{cnt}; ram_i_data1 = 32\'h{i}; // ẋ{idx0}:{float_array[idx0][idx1]}\n')
                    elif idx1 == 2:
                        file.write(f'            #10 ram_i_wr1 = 1\'b0; ram_i_addr1 = 32\'d{cnt}; ram_i_data1 = 32\'h{i}; // θ{idx0}:{float_array[idx0][idx1]}\n')
                    elif idx1 == 3:
                        file.write(f'            #10 ram_i_wr1 = 1\'b0; ram_i_addr1 = 32\'d{cnt}; ram_i_data1 = 32\'h{i}; // ω{idx0}:{float_array[idx0][idx1]}\n\n')
                cnt += 1
            file.write('        end')
            
    return hex_array

def write_action(action, filepath=''):
    action_flatten = action.flatten()
    with open(filepath, 'a') as file:
        for i in range(len(action_flatten)):
            if i % 32 == 0:
                file.write('\n32\'b')
            file.write(str(action_flatten[32*(i//32+1)-1-(i%32)]))
        file.write('\n')

def parse_data(fpga_raw):
    STA_WD_NUM = int(ENV_NUM * OBS_SPACE_N)
    RWD_WD_NUM = int(ENV_NUM / 32)
    DONE_WD_NUM = int(ENV_NUM / 32)
    STA_OFFSET = 0
    RWD_OFFSET = STA_WD_NUM * 4
    DONE_OFFSET = (STA_WD_NUM + RWD_WD_NUM) * 4

    s_ = np.frombuffer(fpga_raw, dtype=np.float32, count=STA_WD_NUM, offset=STA_OFFSET).reshape(ENV_NUM, OBS_SPACE_N)
    r = np.unpackbits(np.frombuffer(fpga_raw, dtype=np.uint8, count=RWD_WD_NUM*4, offset=RWD_OFFSET), bitorder='little')
    done =  np.unpackbits(np.frombuffer(fpga_raw, dtype=np.uint8, count=DONE_WD_NUM*4, offset=DONE_OFFSET), bitorder='little')
    return s_, r, done

def step(states, actions):
    force_mag = 10
    gravity = 9.8
    masscart = 1.0
    masspole = 0.1
    total_mass = masspole + masscart # 1+0.1
    length = 0.5
    polemass_length = masspole * length # 0.1*0.5
    force_mag = 10.0
    tau = 0.02
    # theta_threshold_radians = 12 * 2 * math.pi / 360
    theta_threshold_radians = 0.2095
    x_threshold = 2.4

    next_states = []
    rewards = []
    dones = []

    for i in range(len(states)):
        x, x_dot, theta, theta_dot = states[i]
        action = actions[i]

        force = force_mag if action == 1 else -force_mag
        # force = force_mag if action == 0 else -force_mag
        costheta = math.cos(theta)
        sintheta = math.sin(theta)

        temp = (
            force + polemass_length * theta_dot**2 * sintheta
        ) / total_mass
        thetaacc = (gravity * sintheta - costheta * temp) / (
            length * (4.0 / 3.0 - masspole * costheta**2 / total_mass)
        )
        xacc = temp - polemass_length * thetaacc * costheta / total_mass
        x = x + tau * x_dot
        x_dot = x_dot + tau * xacc
        theta = theta + tau * theta_dot
        theta_dot = theta_dot + tau * thetaacc
        
        state = (x, x_dot, theta, theta_dot)

        done = int(
            x < -x_threshold
            or x > x_threshold
            or theta < -theta_threshold_radians
            or theta > theta_threshold_radians
        )

        if not done:
            reward = 1.0
        else:
            reward = 1.0

        next_states.append(state)
        rewards.append(reward)
        dones.append(done)

        # if i == 0:
        #     print(states[i], actions[i])
        #     print()
        #     print("temp = ",temp)
        #     print(f"thetaacc = {gravity * sintheta - costheta * temp}/{length * (4.0 / 3.0 - masspole * costheta**2 / total_mass)} = {thetaacc}")
        #     print("xacc = ",xacc)
        #     print("x = ",x)
        #     print("x_dot = ",x_dot)
        #     print("theta = ",theta)
        #     print("theta_dot = ",theta_dot)
    
    next_states = np.array(next_states)
    rewards = np.array(rewards)
    dones = np.array(dones)
    return next_states, rewards, dones


init_s = np.array([
        [ 2.4393944e-02,  1.0144283e-02, -1.8924994e-02, -4.2576525e-02],
        [-7.8001479e-03,  1.3946256e-02, -1.5725264e-02, -4.9513049e-02],
        [ 1.1267131e-02,  4.3559421e-02,  3.7962198e-02,  5.2838516e-03],
        [ 3.6819642e-03,  2.2909984e-02, -2.8373828e-02, -6.4867479e-04],
        [ 4.1733675e-02,  4.9138390e-02,  4.4332944e-02, -2.3202665e-02],
        [ 3.3555139e-02, -1.5231751e-02, -3.8799737e-02, -3.4204524e-02],
        [-1.6068015e-02, -2.6929161e-02, -6.7121666e-03, -2.1738408e-02],
        [ 5.8638689e-04, -1.9228073e-02, -3.7361510e-02, -4.1324284e-02],
        [ 4.5160659e-02,  2.0278036e-03,  1.4256264e-02, -2.8071269e-02],
        [ 3.6156058e-02,  2.0410869e-02,  4.6127904e-02,  3.8673814e-02],
        [ 2.4760392e-02, -3.3434499e-02,  4.2620391e-02,  1.2231585e-02],
        [ 1.5668694e-02, -3.4183998e-02,  3.6733779e-03,  3.2607302e-02],
        [-1.6782394e-02, -1.4368074e-02, -1.9841559e-02,  2.4216413e-02],
        [ 1.6260421e-02,  5.7538114e-03, -3.6242567e-02, -5.6044664e-03],
        [-2.3204997e-02, -2.3716537e-02, -3.5986777e-02, -4.2523216e-03],
        [ 4.8285659e-02,  1.5401355e-02, -4.2744442e-03,  4.6354949e-02],
        [-2.2405870e-02,  1.9126147e-02,  2.5388403e-02, -2.4869887e-02],
        [-1.5747083e-02, -9.4879391e-03,  1.9500591e-02, -2.7445056e-02],
        [-1.4104381e-03, -3.2848559e-02,  6.9313538e-03,  1.7092643e-02],
        [-3.9150544e-02, -3.8326286e-02,  2.4345137e-02,  2.9925939e-02],
        [-2.3785170e-02, -3.6782462e-02,  4.3575827e-02,  4.9607564e-02],
        [-6.4220156e-05, -2.7627837e-02, -4.4313762e-02, -8.9318128e-03],
        [ 1.7711777e-02,  9.4688488e-03, -4.4423986e-02, -1.4765789e-03],
        [ 4.8456278e-02, -1.0877370e-02,  4.9214866e-03, -2.2721913e-02],
        [ 2.4868591e-02,  2.7939219e-02, -1.1330790e-02, -9.1247819e-03],
        [-4.6645887e-02,  9.0260264e-03, -3.8586590e-02,  1.9173199e-02],
        [-3.9526340e-02,  8.6399950e-03, -2.4291964e-02, -4.9983364e-02],
        [-4.2971477e-02,  4.8424583e-02, -1.5741572e-03,  3.1517004e-05],
        [-4.8021872e-02,  1.4834024e-03, -2.9634671e-02,  1.1018812e-02],
        [-1.2764251e-02, -2.0247945e-03,  4.7954619e-02, -4.9307138e-02],
        [ 3.8022667e-02, -1.7749436e-02, -2.9220929e-02, -3.7399337e-02],
        [-2.6109233e-02,  4.7099028e-02,  2.0417489e-02, -1.5045027e-02],
        [ 4.5576587e-02,  3.0937362e-02, -2.8392954e-02, -2.8977586e-02],
        [ 2.9617831e-02, -3.1975366e-02,  4.1123848e-02, -1.9667889e-03],
        [-3.8688850e-02,  5.5432384e-04,  1.9140150e-02,  8.3223684e-03],
        [-1.1556669e-02,  1.0393317e-02,  4.8697580e-02,  3.6696099e-02],
        [-1.6289404e-02,  4.9662504e-02, -2.2712022e-02,  1.8537978e-02],
        [-6.4382292e-03,  4.0370528e-02,  3.9881758e-02, -2.8026847e-02],
        [-2.4784291e-02, -2.5764855e-02,  4.3010108e-02, -2.8341573e-02],
        [-1.6612550e-02,  1.6270421e-02,  1.5859060e-02, -2.1824772e-02],
        [ 1.0237132e-02,  4.5407981e-02, -3.3257239e-02, -3.7781459e-03],
        [-3.9573889e-02, -3.4793656e-02, -4.0805722e-03,  3.2373503e-02],
        [-1.1443011e-02,  3.2960536e-04,  2.5092900e-02,  2.5552627e-02],
        [-4.1437410e-02,  3.8262501e-02,  3.1439192e-03,  4.8874348e-02],
        [ 1.0760223e-02,  3.5169866e-02,  1.6102899e-02, -3.3858836e-02],
        [-4.2922027e-02,  1.2024632e-02,  9.4946930e-03, -4.7907043e-02],
        [-2.7295514e-03,  2.9701564e-02, -4.3478426e-02, -1.7762203e-02],
        [ 1.9796602e-04,  5.1737484e-03,  5.9765829e-03, -2.0512264e-02],
        [ 2.9966801e-02, -1.3457773e-02,  3.4745075e-02, -9.3712425e-03],
        [ 1.2471218e-02,  3.5702787e-02, -4.2441164e-04,  2.1332204e-02],
        [-1.1877113e-02,  4.8756555e-02, -3.8067203e-02,  2.5295174e-02],
        [-4.6951946e-02,  4.0615942e-02,  3.6760993e-02,  3.6284156e-02],
        [-2.2380153e-02, -9.6547010e-04,  2.3507584e-02, -3.5951655e-02],
        [ 3.8599268e-02,  2.4397498e-02, -3.8276237e-02,  4.2558875e-02],
        [ 3.0904822e-02, -1.0468450e-02,  3.0392589e-02, -1.3612243e-02],
        [ 1.3760228e-02, -2.1953257e-03, -5.2310550e-04,  4.3241546e-02],
        [ 2.9108036e-02,  9.2658214e-03, -1.3388470e-02, -1.0032112e-02],
        [-1.0102571e-02, -1.7605754e-02,  1.2067986e-02, -2.9507108e-02],
        [-1.5926551e-02,  3.1840317e-02,  2.8165422e-02,  4.9947858e-02],
        [-2.5032498e-02,  8.2166316e-03, -3.7120841e-02, -2.1843338e-02],
        [-1.6346658e-02, -8.5921986e-03, -2.5895268e-02, -2.7184140e-02],
        [ 2.8076900e-02, -4.2537645e-02, -1.0331627e-02,  4.7292266e-02],
        [ 3.7418738e-02, -2.9000083e-02, -4.0545002e-02,  9.9745160e-03],
        [ 1.0947501e-02, -2.7344398e-02, -2.0468468e-02, -4.1275308e-02]]).astype(np.float32)

s = init_s
a = np.array([0, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 0, 1, 1, 0, 1, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 1, 0, 1,
              0, 0, 1, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1]).astype(np.uint8)
a_bytes = np.packbits(a[::-1].reshape(-1, 32), axis=-1).view(np.uint32).tobytes()[::-1]
src_data = s.tobytes() + a_bytes + clear_flag
os.pwrite(pc2fpga, src_data, 0x0000)
time.sleep(0.01)

for iter_idx in range(iterations):
    # s = np.array([
    #      [ 2.4393944e-02,  1.0144283e-02, -1.8924994e-02, -4.2576525e-02],
    #      [-7.8001479e-03,  1.3946256e-02, -1.5725264e-02, -4.9513049e-02],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0],
    #      [0, 0, 0, 0]]).astype(np.float32)
    # a = np.array([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    #               1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]).astype(np.uint8)
    # shape = (ENV_NUM, OBS_SPACE_N)
    # s = np.random.uniform(-0.05, 0.05, size=shape).astype(np.float32)
    # a = np.random.randint(0, 2, size=ENV_NUM).astype(np.uint8)

    # write_state(s, filepath=state_hex)
    # write_action(a, filepath=action_hex)

    fpga_raw = os.pread(fpga2pc, read_byte_num, read_offset)
    # fpga_raw = os.pread(fpga2pc, 4*1, 0x000c)
    # print("FPGA Data:\n", fpga_raw)
    s_, r, done = parse_data(fpga_raw)

    ref_s_, ref_r, ref_done = step(s, a)

    diff_s_ = np.abs(np.array(ref_s_) - s_)
    diff_r = np.abs(np.array(ref_r) - r)
    diff_done = np.abs(np.array(ref_done) - done)
    print("========================================================================")
    print(f"Iteration {iter_idx}: ")
    print("Dones:", done)
    if (diff_s_ > 1e-4).any() | (diff_r > 1e-4).any() | (diff_done > 1e-4).any():
    # if True:
        indices = np.where(diff_s_ > 1e-4)
        print("Indices of error in s_:", np.unique(indices))
        # indices = np.where(diff_r > 1e-4)
        # print("Indices of error in r:", indices)
        # indices = np.where(diff_done > 1e-4)
        # print("Indices of error in done:", indices)

        print("Source Data:")
        print("States:\n", s[np.unique(indices[0])])
        print("Actions:", a[np.unique(indices[0])])
        # print("States:\n", s)
        # print("Actions:", a)

        print("\nGround Truth:")
        print("Next States:\n", ref_s_)
        print("Rewards:", ref_r)
        print("Dones:", ref_done)

        print("\nFPGA Answer:")
        print("Next States:\n", s_[np.unique(indices[0])])
        print("Rewards:", r)
        print("Dones:", done)

        print("\nDifferenes:")
        print("Diff Next States:\n", diff_s_[np.unique(indices[0])])
        print("Diff Rewards:", diff_r)
        print("Diff Dones:", diff_done)
        break
    else:
        # print("\nGround Truth:")
        # print("Next States:\n", ref_s_[0])
        # if iter_idx == 0:
        #     with open("test.txt", 'w') as file:
        #         file.write(f'Iteration {iter_idx} [x ẋ θ ω rwd done]:\n')
        #         for i in range(ENV_NUM):
        #             file.write(f"     {i:2}: [{ref_s_[i][0]:11.8f} {ref_s_[i][1]:11.8f} {ref_s_[i][2]:11.8f} {ref_s_[i][3]:11.8f} {int(ref_r[i])} {bool(ref_done[i])}]\n")
        #         file.write('\n')
        # else:
        #     with open("test.txt", 'a') as file:
        #         file.write(f'Iteration {iter_idx} [x ẋ θ ω rwd done]:\n')
        #         for i in range(ENV_NUM):
        #             file.write(f"     {i:2}: [{ref_s_[i][0]:11.8f} {ref_s_[i][1]:11.8f} {ref_s_[i][2]:11.8f} {ref_s_[i][3]:11.8f} {int(ref_r[i])} {bool(ref_done[i])}]\n")
        #         file.write('\n')
        print("Test passed!")
    print("========================================================================")
    print()

    s = np.copy(s_)
    for i in range(len(done)):
        if done[i]:
            s[i] = init_s[i]

    if iter_idx % 21 == 0:
        a = np.array([1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0,
                      0, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0]).astype(np.uint8)
    elif iter_idx % 21 == 1:
        a = np.array([1, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 0, 0, 0,
                      0, 1, 0, 1, 1, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1]).astype(np.uint8)
    elif iter_idx % 21 == 2:
        a = np.array([0, 0, 0, 1, 0, 0, 1, 1, 1, 0, 1, 0, 1, 1, 1, 0, 0, 0, 1, 1, 0, 1, 1, 1, 0, 0, 1, 0, 0, 1, 1, 0,
                      0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0]).astype(np.uint8)
    elif iter_idx % 21 == 3:
        a = np.array([0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 1, 1, 1, 0, 1, 0, 1, 1, 1, 0, 0, 1, 1, 0, 0, 0, 1, 1, 0, 1, 1, 1,
                      0, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 1, 1, 1]).astype(np.uint8)
    elif iter_idx % 21 == 4:
        a = np.array([0, 1, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 0, 0, 0, 1, 1,
                      1, 0, 0, 0, 1, 1, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, 0, 0, 1, 0]).astype(np.uint8)
    elif iter_idx % 21 == 5:
        a = np.array([1, 0, 0, 1, 1, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0, 1,
                      1, 1, 1, 1, 0, 1, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0]).astype(np.uint8)
    elif iter_idx % 21 == 6:
        a = np.array([1, 1, 0, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1,
                      1, 1, 1, 1, 0, 0, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1]).astype(np.uint8)
    elif iter_idx % 21 == 7:
        a = np.array([1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 0, 0, 1, 1, 1, 0, 0, 1, 0, 1, 0, 0,
                      1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1]).astype(np.uint8)
    elif iter_idx % 21 == 8:
        a = np.array([1, 1, 1, 1, 1, 0, 1, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 1, 1, 1, 0,
                      1, 1, 0, 0, 1, 1, 1, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 1, 1, 0, 0, 1, 1, 0, 0, 1]).astype(np.uint8)
    elif iter_idx % 21 == 9:
        a = np.array([0, 1, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 1, 1, 1, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 1, 0, 1, 1, 0,
                      1, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 1]).astype(np.uint8)
    elif iter_idx % 21 == 10:
        a = np.array([1, 1, 1, 1, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 1, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0,
                      0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 1]).astype(np.uint8)
    elif iter_idx % 21 == 11:
        a = np.array([1, 1, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 0, 1, 1, 1, 0,
                      0, 0, 0, 1, 1, 0, 1, 1, 1, 0, 0, 0, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0, 0, 1, 1, 1, 0, 1, 1]).astype(np.uint8)
    elif iter_idx % 21 == 12:
        a = np.array([0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 0, 1, 1, 1, 0, 0, 1, 0, 1, 0, 0, 1, 1, 1, 1, 0,
                      0, 1, 0, 1, 1, 1, 1, 0, 1, 0, 0, 0, 1, 1, 1, 1, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0]).astype(np.uint8)
    elif iter_idx % 21 == 13:
        a = np.array([1, 0, 1, 1, 1, 0, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 0, 1, 0, 0, 0, 1,
                      1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 1, 0, 0, 1, 1, 1, 0, 1, 1, 0, 0, 0, 1, 0, 0, 1, 0, 1, 1, 0, 0, 1]).astype(np.uint8)
    elif iter_idx % 21 == 14:
        a = np.array([0, 1, 0, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, 1, 0, 1, 1, 1, 0, 0,
                      1, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 1, 0, 1, 0, 0, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 0]).astype(np.uint8)
    elif iter_idx % 21 == 15:
        a = np.array([0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 1, 0, 1, 0, 0, 1, 1, 1, 0, 1, 1, 1, 0, 0, 1, 0, 1, 0,
                      0, 1, 1, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 1]).astype(np.uint8)
    elif iter_idx % 21 == 16:
        a = np.array([1, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 0, 0, 1, 1, 1, 0, 1, 1, 0, 1, 0, 0,
                      0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 0, 1, 1, 0, 0, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1]).astype(np.uint8)
    elif iter_idx % 21 == 17:
        a = np.array([0, 1, 1, 0, 0, 0, 1, 0, 1, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 0,
                      1, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 1, 1, 1, 0, 0]).astype(np.uint8)
    elif iter_idx % 21 == 18:
        a = np.array([0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1, 0,
                      0, 1, 0, 1, 1, 0, 0, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 1, 1, 1, 0, 1, 1, 0, 1, 1]).astype(np.uint8)
    elif iter_idx % 21 == 19:
        a = np.array([0, 1, 1, 0, 1, 0, 1, 1, 1, 1, 0, 0, 1, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 1,
                      1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0, 0, 1, 1, 1, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0]).astype(np.uint8)
    elif iter_idx % 21 == 20:
        a = np.array([1, 1, 0, 0, 1, 1, 1, 1, 0, 1, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 0,
                      0, 0, 1, 1, 1, 0, 1, 1, 0, 1, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 1, 0, 1]).astype(np.uint8)
    else:
        a = np.array([0, 0, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1,
                      0, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 1, 0, 0, 1]).astype(np.uint8)
    # if iter_idx == 0:
    #     with open("test.txt", 'w') as file:
    #         file.write(f"a = np.array({a.tolist()}).astype(np.uint8)\n")
    # else:
    #     with open("test.txt", 'a') as file:
    #         file.write(f"a = np.array({a.tolist()}).astype(np.uint8)\n")
    # a = np.random.randint(low=0, high=2, size=ENV_NUM, dtype=np.uint8)
    a_bytes = np.packbits(a[::-1].reshape(-1, 32), axis=-1).view(np.uint32).tobytes()[::-1]
    src_data = a_bytes + start_flag
    # print("Source Data:\n", src_data)
    os.pwrite(pc2fpga, src_data, action_offset)

    # time.sleep(10*1*ENV_NUM/1e9)
    # time.sleep(0.001)
all_zero = np.zeros(40960, dtype=np.float32)
os.pwrite(pc2fpga, all_zero, 0x0000)
os.close(pc2fpga)
os.close(fpga2pc)