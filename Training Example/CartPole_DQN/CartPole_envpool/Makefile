export EPISODE_NUM = 300
export STEP_NUM = 1000
export ENV_NUM = 64
# CURVE_NUM = 5

# CURVE_IDX := $(shell awk 'BEGIN { for (i = 0; i < $(CURVE_NUM); i += 1) print i }')

# # cpp_pcie: pcie_rd_wt.cpp pcie_rd_wt pcie_rd_wt_jyy.cpp pcie_rd_wt_jyy
# # 	# ./pcie_rd_wt
# # 	./pcie_rd_wt_jyy

# train:
# 	$(foreach i,$(CURVE_IDX), \
# 		python3 -u /data0/FPGA_GYM/python/CartPole/CartPole_vecenv/main_SARL_train.py curve_idx=$(i); \
# 	)


# export EPISODE_NUM = 300
# export STEP_NUM = 1000
SEEDS := 2024 456 789 101112 131415 
# 161718 192021 222324 252627 282930 313233 343536 373839 404142 434445

CURVE_NUM = 5
CURVE_IDX := $(shell awk 'BEGIN { for (i = 0; i < $(CURVE_NUM); i += 1) print i }')

all: 

	$(foreach i,$(CURVE_IDX), \
		python3 -u /data0/FPGA_GYM/python/CartPole/CartPole_envpool/main_SARL_train.py  curve_idx=$(i) --seed $(word $(shell expr $(i) + 1), $(SEEDS));)
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