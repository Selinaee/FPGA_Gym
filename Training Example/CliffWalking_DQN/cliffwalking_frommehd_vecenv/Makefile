# export EPISODE_NUM = 300
# export STEP_NUM = 1000
SEEDS := 2024 456 789 101112 131415 
# 161718 192021 222324 252627 282930 313233 343536 373839 404142 434445

CURVE_NUM = 5
CURVE_IDX := $(shell awk 'BEGIN { for (i = 0; i < $(CURVE_NUM); i += 1) print i }')

all: 

	$(foreach i,$(CURVE_IDX), \
		python3 -u DQN_CliffWalking_fromMehd_vecenv.py curve_idx=$(i) --seed $(word $(shell expr $(i) + 1), $(SEEDS));)
		# python3 -u DQN_CliffWalking_fromMehd_vecenv.py curve_idx=$(i); \)

