#!/bin/bash

# 数据集生成（单核）
python dataset-generation/dataset_gen.py

# 多核生成
python dataset-generation/dataset_pargen.py

# 预处理
python dataset-generation/preprocessing.py

# 训练（4卡）
CUDA_VISIBLE_DEVICES=0 nohup python transformer/main_train.py > train.log 2>&1 &

# 优化
python optimization/main_optimization.py