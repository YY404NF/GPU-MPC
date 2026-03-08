
# GPU-MPC

## 声明

本项目非原创。最初版本来自 [EzPC 项目](https://github.com/mpc-msri/EzPC)中的 GPU-MPC 文件夹。

---

这是论文 [Orca](https://eprint.iacr.org/2023/206) 和 [SIGMA](https://eprint.iacr.org/2023/1269) 所提出协议的实现。

**警告**：这是一个学术概念验证原型，尚未接受严格的代码审查。此实现**不适合**在生产环境中使用。

## 构建

此项目需要 NVIDIA GPU，并假设已安装 GPU 驱动和 [NVIDIA CUDA 工具包](https://docs.nvidia.com/cuda/)。以下构建已在 Ubuntu 20.04（CUDA 11.7、CMake 3.27.2 和 g++-9）上测试。

请注意，Sytorch 需要 CMake 版本 >= 3.17，如果不满足此依赖项，构建将失败。

代码默认使用 CUTLASS 版本 2.11，因此如果更改 CUDA 版本，请确保正在构建的 CUTLASS 版本与新 CUDA 版本兼容。

`setup.sh` 的最后一行尝试安装 `matplotlib`，这是生成图 5a 和 5b 所需的。根据我们的经验，如果 Python 和 `pip` 的版本不匹配，安装会失败。如果安装失败，请在运行 `run_experiment.py` 之前手动安装 `matplotlib`。

1. 导出环境变量

```
export CUDA_VERSION=11.7
export GPU_ARCH=86
```

2. 设置环境

```
sh setup.sh <CUTLASS branch>
```

要更改要构建的 CUTLASS 版本，可以选择性地包括应该构建的 CUTLASS 分支

```
sh setup.sh <CUTLASS branch>
```
例如，要构建主分支，请运行

```
sh setup.sh main
```

3. 构建 Orca

```
make orca
```

4. 构建 SIGMA（这不需要构建 Orca）

```
make sigma
```

## 运行 Orca

请参阅 [Orca README](experiments/orca/README.md)。

## 运行 SIGMA

请参阅 [SIGMA README](experiments/sigma/README.md)

## Docker 构建

您也可以使用提供的 Dockerfile_Gen 构建 Docker 镜像来构建环境。

### 安装 NVIDIA 容器工具包
- 配置仓库：
```
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey |sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
&& curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list \
&& sudo apt-get update
```

- 安装 NVIDIA 容器工具包：
```
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

### 构建 Docker 镜像或从 Docker Hub 拉取镜像
```
# 本地构建
docker build -t gpu_mpc -f Dockerfile_Gen .

# 从 Docker Hub 拉取 (Cuda 11.8)
docker pull trajore/gpu_mpc
```

### 运行 Docker 容器
```
sudo docker run --gpus all --network host -v /home/$USER/path_to_GPU-MPC/:/home -it container_name /bin/bash
```

然后运行 setup.sh 以根据 GPU_arch 进行配置，并按上述说明构建 Orca/SIGMA。

