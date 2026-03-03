#!/bin/bash
# =============================================================================
# 一键部署脚本 - memory-lancedb-pro 本地化版本
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== memory-lancedb-pro 一键部署 ==="
echo ""

# 检查系统
echo "[检查] 系统要求..."
if ! grep -q "Ubuntu" /etc/os-release 2>/dev/null; then
    echo "警告: 推荐使用 Ubuntu 22.04"
fi

# 检查 OpenClaw
echo "[检查] OpenClaw..."
if command -v openclaw &> /dev/null; then
    echo "OpenClaw 已安装: $(openclaw --version 2>/dev/null || echo 'unknown')"
else
    echo "错误: OpenClaw 未安装"
    exit 1
fi

# 步骤 1: 安装 Ollama
echo ""
echo "[步骤 1/5] 安装 Ollama..."
if command -v ollama &> /dev/null; then
    echo "Ollama 已安装"
else
    curl -fsSL https://ollama.com/install.sh | sh
fi

# 步骤 2: 拉取模型
echo ""
echo "[步骤 2/5] 拉取 Embedding 模型..."
if ollama list | grep -q "jina-embeddings-v2-base-zh"; then
    echo "模型已存在"
else
    ollama pull jina-embeddings-v2-base-zh
fi

# 步骤 3: 安装插件
echo ""
echo "[步骤 3/5] 安装插件..."
PLUGIN_LINK="$HOME/.openclaw/plugins/memory-lancedb-pro"
if [ -L "$PLUGIN_LINK" ]; then
    echo "插件已链接"
elif [ -d "$PLUGIN_LINK" ]; then
    echo "插件目录已存在"
else
    mkdir -p "$(dirname "$PLUGIN_LINK")"
    ln -sf "$PLUGIN_DIR" "$PLUGIN_LINK"
    echo "插件链接完成"
fi

# 步骤 4: 配置
echo ""
echo "[步骤 4/5] 配置 OpenClaw..."
CONFIG_FILE="$HOME/.openclaw/openclaw.json"
BACKUP_FILE="$CONFIG_FILE.backup.$(date +%Y%m%d%H%M%S)"

if [ -f "$CONFIG_FILE" ]; then
    cp "$CONFIG_FILE" "$BACKUP_FILE"
    echo "配置已备份到: $BACKUP_FILE"
fi

# 检查是否已有插件配置
if grep -q "memory-lancedb-pro" "$CONFIG_FILE" 2>/dev/null; then
    echo "插件配置已存在"
else
    echo "请手动添加插件配置到 $CONFIG_FILE"
    echo "参见: $PLUGIN_DIR/IMPLEMENTATION_GUIDE.md"
fi

# 步骤 5: 重启
echo ""
echo "[步骤 5/5] 重启 OpenClaw..."
if command -v openclaw &> /dev/null; then
    echo "请手动运行: openclaw gateway restart"
else
    echo "无法重启，请手动操作"
fi

echo ""
echo "=== 部署完成 ==="
echo ""
echo "后续步骤:"
echo "1. 配置 openclaw.json (见 IMPLEMENTATION_GUIDE.md)"
echo "2. 运行: openclaw gateway restart"
echo "3. 检查日志: tail -f ~/.openclaw/logs/gateway.log"