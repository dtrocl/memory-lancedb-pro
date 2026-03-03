#!/bin/bash
# =============================================================================
# Ollama 安装脚本 - Ubuntu 22.04
# =============================================================================

set -e

echo "=== 安装 Ollama (Ubuntu 22.04) ==="

# 检查是否为 root 或有 sudo 权限
if [ "$EUID" -ne 0 ] && ! sudo -v 2>/dev/null; then
    echo "需要 sudo 权限"
    exit 1
fi

# 安装依赖
echo "[1/4] 安装依赖..."
if command -v apt-get &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y curl
elif command -v yum &> /dev/null; then
    sudo yum install -y curl
else
    echo "不支持的包管理器"
    exit 1
fi

# 安装 Ollama
echo "[2/4] 下载并安装 Ollama..."
curl -fsSL https://ollama.com/install.sh | sh

# 验证安装
echo "[3/4] 验证安装..."
if command -v ollama &> /dev/null; then
    echo "Ollama 版本: $(ollama --version)"
else
    echo "Ollama 安装失败"
    exit 1
fi

# 启动服务 (如果未自动启动)
echo "[4/4] 启动服务..."
if pgrep -x "ollama" > /dev/null; then
    echo "Ollama 服务已在运行"
else
    ollama serve &
    sleep 3
    echo "Ollama 服务已启动"
fi

echo ""
echo "=== 安装完成 ==="
echo "下一步: 运行 ./scripts/pull-model.sh 拉取 embedding 模型"