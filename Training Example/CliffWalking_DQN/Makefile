# export EPISODE_NUM = 300
# export STEP_NUM = 1000
# export ENV_NUM = 16
SEEDS := 2024 456 789 101112 131415 

CURVE_NUM = 5
CURVE_IDX := $(shell seq 0 $(shell expr $(CURVE_NUM) - 1))

all: envpool vec_env pcie

envpool:
	cd cliffwalking_frommehd_envpool && $(foreach i, $(CURVE_IDX), \
		python3 -u DQN_CliffWalking_fromMehd_envpool.py curve_idx=$(i) --seed $(word $(shell expr $(i) + 1), $(SEEDS));)

vec_env:
	cd cliffwalking_frommehd_vecenv && $(foreach i, $(CURVE_IDX), \
		python3 -u DQN_CliffWalking_fromMehd_vecenv.py curve_idx=$(i) --seed $(word $(shell expr $(i) + 1), $(SEEDS));)

pcie:
	cd cliffwalking_frommehd_pcie && $(foreach i, $(CURVE_IDX), \
		python3 -u DQN_CliffWalking_fromMehd_pcie.py curve_idx=$(i) --seed $(word $(shell expr $(i) + 1), $(SEEDS));)
