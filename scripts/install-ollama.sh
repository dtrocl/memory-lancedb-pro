#!/bin/bash
# =============================================================================
# Ollama 安装脚本 - 中国大陆环境（使用魔塔）
# =============================================================================

set -e

echo "=== 安装 Ollama (中国大陆环境) ==="
echo "使用 ModelScope 魔塔安装..."

# 检查 pip
if ! command -v pip3 &> /dev/null; then
    echo "错误: 需要 pip3"
    exit 1
fi

# 检查是否为 root 或有 sudo 权限
if [ "$EUID" -ne 0 ] && ! sudo -v 2>/dev/null; then
    echo "需要 sudo 权限"
    exit 1
fi

# 1. 安装 ModelScope
echo "[1/5] 安装 ModelScope..."
pip3 install modelscope -U

# 2. 下载 Ollama 安装包
echo "[2/5] 下载 Ollama 安装包..."
cd /tmp
if [ -d "ollama-linux" ]; then
    rm -rf ollama-linux
fi
modelscope download --model=modelscope/ollama-linux --local_dir ./ollama-linux --revision v0.17.5

# 3. 安装 Ollama
echo "[3/5] 安装 Ollama..."
cd ollama-linux
sudo chmod 777 .
sudo ./ollama-modelscope-install.sh

# 4. 验证安装
echo "[4/5] 验证安装..."
if command -v ollama &> /dev/null; then
    echo "Ollama 版本: $(ollama --version)"
else
    echo "Ollama 安装失败"
    exit 1
fi

# 5. 检查服务状态
echo "[5/5] 检查服务..."
if systemctl is-active ollama &> /dev/null; then
    echo "Ollama 服务运行中"
else
    echo "启动 Ollama 服务..."
    sudo systemctl start ollama
fi

# 确认开机自启
sudo systemctl enable ollama
echo "Ollama 已设置为开机自启"

echo ""
echo "=== 安装完成 ==="
echo "下一步: 运行 ./pull-model.sh 拉取 embedding 模型"