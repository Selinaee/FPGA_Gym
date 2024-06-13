export EPISODE_NUM = 300
export STEP_NUM = 1000
export ENV_NUM = 64
CURVE_NUM = 5

SEEDS := 2024 456 789 101112 131415 
CURVE_IDX := $(shell awk 'BEGIN { for (i = 0; i < $(CURVE_NUM); i += 1) print i }')

# cpp_pcie: pcie_rd_wt.cpp pcie_rd_wt pcie_rd_wt_jyy.cpp pcie_rd_wt_jyy
# 	# ./pcie_rd_wt
# 	./pcie_rd_wt_jyy

all: 

	$(foreach i,$(CURVE_IDX), \
		python3 -u /data0/FPGA_GYM/python/CartPole/CartPole_pcie/main_SARL_train_burst_state_action.py  curve_idx=$(i) --seed $(word $(shell expr $(i) + 1), $(SEEDS));)
		# python3 -u DQN_CartPole_fromMehd_vecenv.py curve_idx=$(i); \)

# cln:
# 	cd CartPole_DQN_cpu; \
# 	rm -rf __pycache__/; \
# 	rm -rf *.txt *.png; \

# pcie_rd_wt: pcie_rd_wt.cpp
# 	g++ pcie_rd_wt.cpp -o pcie_rd_wt

# pcie_rd_wt_jyy: pcie_rd_wt_jyy.cpp
# 	g++ pcie_rd_wt_jyy.cpp -o pcie_rd_wt_jyy

# time_record:
# 	@echo "Start time: $$(python -c 'import time; print(time.time_ns())')"
# 	@echo "End   time: $$(python -c 'import time; print(time.time_ns())')"