#!/bin/bash
# =============================================================================
# Embedding 模型拉取脚本
# =============================================================================

set -e

# 默认模型
MODEL="${1:-jina-embeddings-v2-base-zh}"

echo "=== 拉取 Embedding 模型: $MODEL ==="

# 检查 Ollama 是否运行
if ! pgrep -x "ollama" > /dev/null; then
    echo "Ollama 未运行，正在启动..."
    ollama serve &
    sleep 5
fi

# 拉取模型
echo "正在拉取模型 (约 160MB)..."
ollama pull $MODEL

# 验证
echo "验证模型..."
ollama list | grep -q $MODEL && echo "模型 $MODEL 安装成功!" || echo "模型安装失败"

echo ""
echo "=== 完成 ==="
echo "下一步: 配置 OpenClaw 并重启"