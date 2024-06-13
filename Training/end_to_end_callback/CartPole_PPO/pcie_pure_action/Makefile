SEEDS := 789 101112 131415 456 2024
CURVE_NUM = 5
CURVE_IDX := $(shell awk 'BEGIN { for (i = 0; i < $(CURVE_NUM); i += 1) print i }')

all: 
	clear
	$(foreach i,$(CURVE_IDX), \
		python3 -u CartPole_PPO_pcie.py  curve_idx=$(i) --seed $(word $(shell expr $(i) + 1), $(SEEDS));)

