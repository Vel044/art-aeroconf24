# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

ART (Autonomous Rendezvous Transformer) 是论文 "Transformers for Trajectory Optimization with Applications to Spacecraft Rendezvous" (IEEE Aerospace Conference 2024) 的官方实现。使用 Decision Transformer 为航天器交会任务提供轨迹优化热启动。

## 常用命令

### 安装依赖
```bash
pip install -r requirements.txt
```

### 运行演示（使用预训练模型）
```bash
cd optimization && python main_optimization.py
```

### 训练 ART 模型
```bash
cd transformer && python main_train.py
```

### 生成数据集
```bash
# 并行生成（多核）
python dataset-generation/dataset_pargen.py
# 顺序生成
python dataset-generation/dataset_gen.py
# 预处理
python dataset-generation/preprocessing.py
```

### 外部数据
需要从 [Google Drive](https://drive.google.com/drive/folders/1_4UsfcMR9zUqGmg0NsX_qs3xbXXFtdgQ) 下载：
- 预训练权重：`checkpoint_rtn_art` 放入 `transformer/saved_files/checkpoints/`
- 数据集文件：放入 `dataset/` 目录

## 代码架构

### 核心模块

**dynamics/orbit_dynamics.py**
- 轨道动力学定义，使用 J2 摄动的相对轨道运动
- 两种状态表示：ROE (Relative Orbital Elements) 和 RTN (Radial-Transverse-Normal)
- `state_transition()`: 状态转移矩阵 (Koenig et al. 2017)
- `map_roe_to_rtn()` / `map_rtn_to_roe()`: 坐标系统转换

**optimization/ocp.py**
- OCP  formulations using CVXPY
- `ocp_cvx()`: 凸优化问题（终点约束 + 对接走廊约束）
- `ocp_scp()`: 序列凸规划 (SCP)，带信任域
- `solve_scp()`: SCP 迭代求解器

**optimization/rpod_scenario.py**
- 交会场景参数（ISS 参考轨道、对接参数、keep-out-zone）
- `state_roe_target`: ROE 目标状态
- `dock_wyp`: 对接航路点
- `E_koz`, `DEED_koz`: Keep-out-zone 椭圆约束矩阵

**transformer/art.py**
- `AutonomousRendezvousTransformer`: 基于 Hugging Face DecisionTransformer 的模型

**transformer/manage.py**
- 数据加载：`get_train_val_test_data()`
- 模型推理：`torch_model_inference_dyn()` (动态) / `torch_model_inference_ol()` (开环)

### 状态表示

- **ROE**: 6维相对轨道根数 [δa, δλ, δe_x, δe_y, δi_x, δi_y]
- **RTN**: 6维径向-横向-法向位置/速度 [r, t, n, ṙ, ṫ, ṅ]

### 优化流程 (main_optimization.py)

1. 加载测试数据或定义场景参数
2. 预计算动力学矩阵 (STM, CIM, PSI)
3. **CVX 热启动**: 求解凸优化问题
4. **ART 热启动**: 使用 Decision Transformer 预测轨迹
5. **SCP 精化**: 以热启动为初值求解非凸优化
6. 生成可视化图表

### 关键配置 (main_optimization.py)

```python
warmstart = 'both'           # 'cvx' / 'transformer' / 'both'
state_representation = 'rtn' # 'roe' / 'rtn'
transformer_ws = 'dyn'       # 'dyn' (动态) / 'ol' (开环)
transformer_model_name = 'checkpoint_rtn_art'
```
