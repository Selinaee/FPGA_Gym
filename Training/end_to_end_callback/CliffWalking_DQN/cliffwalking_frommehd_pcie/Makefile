# export EPISODE_NUM = 300
# export STEP_NUM = 1000
# SEEDS := 12 13 14 15 16
SEEDS := 2024 456 789 101112 131415

CURVE_NUM := 5
CURVE_IDX := $(shell seq 0 $$(($(CURVE_NUM) - 1)))

all: 
	$(foreach i, $(CURVE_IDX), \
		python3 -u DQN_CliffWalking_fromMehd_pcie.py curve_idx=$(i) --seed $(word $(shell expr $(i) + 1), $(SEEDS));)
