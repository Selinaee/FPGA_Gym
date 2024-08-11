# export EPISODE_NUM = 300
# export STEP_NUM = 1000
export ENV_NUM = 64

SEEDS :=  789 101112 131415 2024 456

CURVE_NUM = 3
CURVE_IDX := $(shell awk 'BEGIN { for (i = 0; i < $(CURVE_NUM); i += 1) print i }')

all: 

	$(foreach i,$(CURVE_IDX), \
		python3 -u CartPole_PPO_pcie.py  curve_idx=$(i) --seed $(word $(shell expr $(i) + 1), $(SEEDS));)

