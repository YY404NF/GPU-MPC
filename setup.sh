#!/usr/bin/env bash
# GPU-MPC 项目环境初始化脚本
# 用途：安装所有依赖、构建外部库、准备数据集及输出目录
#
# 使用方法：
#   CUDA_VERSION=<版本号> GPU_ARCH=<GPU架构> bash setup.sh [CUTLASS版本/标签]
#
# 必须提前设置的环境变量：
#   CUDA_VERSION  — 已安装的 CUDA 版本号，例如 11.8
#   GPU_ARCH      — 目标 GPU 的 CUDA 计算能力，例如 80（对应 A100）
#
# 可选参数：
#   $1            — CUTLASS 的 git 版本号或标签（如 v2.9.0），默认使用当前 HEAD

# 遇到错误时立即退出，避免错误被忽略
set -e

# ────────────────────────────────────────────────
# 1. 设置环境变量
# ────────────────────────────────────────────────
# 根据系统中已安装的 CUDA 版本确定 nvcc 编译器路径
export NVCC_PATH="/usr/local/cuda-${CUDA_VERSION}/bin/nvcc"

# ────────────────────────────────────────────────
# 2. 初始化 Git 子模块
# ────────────────────────────────────────────────
echo "正在更新 Git 子模块..."
git submodule update --init --recursive

# ────────────────────────────────────────────────
# 3. 安装系统依赖（合并为单次 apt 调用以加快速度）
# ────────────────────────────────────────────────
echo "正在安装系统依赖..."
sudo apt-get update -y
sudo apt-get install -y \
    gcc-9 g++-9 \
    cmake make \
    libssl-dev \
    python3-pip \
    libgmp-dev \
    libmpfr-dev \
    libeigen3-dev

# 将 gcc-9/g++-9 设置为默认编译器
echo "正在配置 gcc-9/g++-9 为默认编译器..."
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 60 \
    --slave /usr/bin/g++ g++ /usr/bin/g++-9
sudo update-alternatives --config gcc

# ────────────────────────────────────────────────
# 4. 构建 CUTLASS（CUDA 模板线性代数库）
# ────────────────────────────────────────────────
echo "正在构建 CUTLASS..."
cd ext/cutlass

# 若传入了版本参数 $1（CUTLASS git 标签/版本号），则切换到指定版本
if [ -n "$1" ]; then
    git checkout "$1"
fi

mkdir -p build && cd build
cmake .. \
    -DCUTLASS_NVCC_ARCHS="${GPU_ARCH}" \
    -DCMAKE_CUDA_COMPILER_WORKS=1 \
    -DCMAKE_CUDA_COMPILER="${NVCC_PATH}"
make -j"$(nproc)"
cd ../../..

# ────────────────────────────────────────────────
# 5. 构建 Sytorch（安全深度学习框架）
# ────────────────────────────────────────────────
echo "正在构建 Sytorch..."
cd ext/sytorch
mkdir -p build && cd build
cmake \
    -DCMAKE_INSTALL_PREFIX=./install \
    -DCMAKE_BUILD_TYPE=Release \
    -DCUDAToolkit_ROOT="/usr/local/cuda-${CUDA_VERSION}/bin/" \
    ../
make sytorch -j"$(nproc)"
cd ../../..

# ────────────────────────────────────────────────
# 6. 下载 CIFAR-10 数据集
# ────────────────────────────────────────────────
echo "正在下载 CIFAR-10 数据集..."
cd experiments/orca/datasets/cifar-10
sh download-cifar10.sh
cd ../../../..

# ────────────────────────────────────────────────
# 7. 生成数据分片（用于安全多方计算）
# ────────────────────────────────────────────────
echo "正在生成数据分片..."
make share_data
cd experiments/orca
./share_data
cd ../..

# ────────────────────────────────────────────────
# 8. 创建输出目录（使用 -p 避免目录已存在时报错）
# ────────────────────────────────────────────────
echo "正在创建输出目录..."

# Orca 实验输出目录（P0/P1 双方，分训练和推理两类）
mkdir -p \
    experiments/orca/output/P0/training \
    experiments/orca/output/P0/inference \
    experiments/orca/output/P1/training \
    experiments/orca/output/P1/inference

# Sigma 实验输出目录（P0/P1 双方）
mkdir -p \
    experiments/sigma/output/P0 \
    experiments/sigma/output/P1

# ────────────────────────────────────────────────
# 9. 安装 Python 依赖
# ────────────────────────────────────────────────
echo "正在安装 Python 依赖..."
pip3 install matplotlib

echo "初始化完成！"

# ════════════════════════════════════════════════
# 以下为原始脚本内容（保留供参考）
# ════════════════════════════════════════════════
#
# # Set environment variables
# export NVCC_PATH="/usr/local/cuda-$CUDA_VERSION/bin/nvcc"
#
# echo "Updating submodules"
# git submodule update --init --recursive
#
# # Install dependencies
# echo "Installing g++-9"
# sudo apt install -y gcc-9 g++-9;
# sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 60 --slave /usr/bin/g++ g++ /usr/bin/g++-9;
# sudo update-alternatives --config gcc;
#
#
# #installing dependencies
# sudo apt install libssl-dev cmake python3-pip libgmp-dev libmpfr-dev;
#
#
# echo "Installing dependencies"
# sudo apt install cmake make libeigen3-dev;
#
# echo "Building CUTLASS"
# # Build CUTLASS
# cd ext/cutlass;
# if [ -n "$1" ]
# then
# git checkout $1;
# fi
# mkdir build && cd build;
# cmake .. -DCUTLASS_NVCC_ARCHS=$GPU_ARCH -DCMAKE_CUDA_COMPILER_WORKS=1 -DCMAKE_CUDA_COMPILER=$NVCC_PATH;
# make -j;
# cd ../../..;
#
# # Build sytorch
# echo "Building Sytorch"
# cd ext/sytorch;
# mkdir build && cd build;
# cmake -DCMAKE_INSTALL_PREFIX=./install -DCMAKE_BUILD_TYPE=Release ../ -DCUDAToolkit_ROOT="/usr/local/cuda-$CUDA_VERSION/bin/";
# make sytorch -j;
# cd ../../..;
#
# # Download CIFAR-10
# cd experiments/orca/datasets/cifar-10;
# sh download-cifar10.sh;
# cd ../../../..;
#
#
# # Make shares of data
# make share_data;
# cd experiments/orca;
# ./share_data;
# cd ../..;
#
# # Build the orca codebase
# # make orca;
#
# # Make output directories
# # Orca
# mkdir experiments/orca/output;
# mkdir experiments/orca/output/P0;
# mkdir experiments/orca/output/P1;
# mkdir experiments/orca/output/P0/training;
# mkdir experiments/orca/output/P1/training;
# mkdir experiments/orca/output/P0/inference;
# mkdir experiments/orca/output/P1/inference;
#
# # Sigma
# mkdir experiments/sigma/output;
# mkdir experiments/sigma/output/P0;
# mkdir experiments/sigma/output/P1;
#
# # install matplotlib
# pip3 install matplotlib
