# memory-lancedb-pro 本地化部署指南（中国环境）

> 针对中国大陆环境优化，使用魔塔(ModelScope)安装Ollama

---

## 1. Ollama 安装（使用魔塔）

由于中国大陆网络原因，无法直接从 ollama.com 下载，需要使用魔塔安装。

### 1.1 安装步骤

```bash
# 1. 安装 ModelScope（如果已安装可跳过）
pip install modelscope -U

# 2. 下载 Ollama 安装包（最新版本 v0.17.5）
modelscope download --model=modelscope/ollama-linux --local_dir ./ollama-linux --revision v0.17.5

# 3. 进入目录并安装
cd ollama-linux
sudo chmod 777
sudo ./ollama-modelscope-install.sh
```

### 1.2 验证安装

```bash
# 检查 Ollama 是否为系统服务
systemctl status ollama

# 检查版本
ollama --version

# 确认服务开机自启
systemctl is-enabled ollama
```

### 1.3 拉取 Embedding 模型

**重要**：必须用 systemd 服务的 ollama 拉取模型，不能用手动启动的 ollama！

```bash
# 拉取推荐模型（274MB）
ollama pull nomic-embed-text

# 验证模型已安装
curl -s http://localhost:11434/api/tags
```

---

## 2. 插件安装

### 2.1 克隆插件

```bash
# 进入 OpenClaw 工作区
cd ~/.openclaw/workspace-jarvis

# 克隆我们修改后的版本
git clone https://github.com/dtrocl/memory-lancedb-pro.git

# 或者克隆原版
git clone https://github.com/win4r/memory-lancedb-pro.git
```

### 2.2 安装依赖

```bash
cd memory-lancedb-pro
npm install
```

### 2.3 链接插件

```bash
mkdir -p ~/.openclaw/plugins
ln -sf ~/.openclaw/workspace-jarvis/memory-lancedb-pro ~/.openclaw/plugins/memory-lancedb-pro
```

---

## 3. OpenClaw 配置

### 3.1 添加插件配置

在 `~/.openclaw/openclaw.json` 中添加：

```json
{
  "plugins": {
    "allow": ["memory-lancedb-pro"],
    "load": {
      "paths": [
        "~/.openclaw/plugins/memory-lancedb-pro"
      ]
    },
    "entries": {
      "memory-lancedb-pro": {
        "enabled": true,
        "config": {
          "embedding": {
            "apiKey": "ollama",
            "model": "nomic-embed-text",
            "baseURL": "http://localhost:11434/v1",
            "dimensions": 768
          },
          "dbPath": "~/.openclaw/memory/lancedb-pro",
          "autoCapture": false,
          "autoRecall": false,
          "retrieval": {
            "mode": "vector",
            "rerank": "lightweight"
          },
          "enableManagementTools": true
        }
      }
    },
    "slots": {
      "memory": "memory-lancedb-pro"
    }
  }
}
```

### 3.2 重启 OpenClaw

```bash
openclaw gateway restart
```

---

## 4. 验证

### 4.1 检查插件状态

```bash
openclaw plugins info memory-lancedb-pro
```

应该看到：
- Status: loaded
- embedding: OK
- retrieval: OK
- FTS: enabled

### 4.2 检查日志

```bash
tail -20 /tmp/openclaw/openclaw-2026-03-03.log | grep memory-lancedb-pro
```

应该看到：
```
memory-lancedb-pro: initialized successfully (embedding: OK, retrieval: OK, ...)
```

---

## 5. 常见问题

### Q: ollama 命令报 "cannot execute binary file"

A: 可能是手动安装的 ollama 和 systemd 服务冲突。请使用 systemd 服务的 ollama：
```bash
systemctl status ollama
systemctl restart ollama
```

### Q: embedding test failed: 404 model not found

A: 模型没有用 systemd 服务的 ollama 拉取。请运行：
```bash
ollama pull nomic-embed-text
```

### Q: plugins.allow is empty 警告

A: 添加 `"allow": ["memory-lancedb-pro"]` 到配置文件。

---

## 6. 一键部署脚本（待完善）

```bash
#!/bin/bash
# 一键部署脚本 - 待测试

set -e

echo "=== 1. 安装 Ollama (使用魔塔) ==="
pip install modelscope -U
modelscope download --model=modelscope/ollama-linux --local_dir ./ollama-linux --revision v0.17.5
cd ollama-linux
sudo ./ollama-modelscope-install.sh

echo "=== 2. 拉取模型 ==="
ollama pull nomic-embed-text

echo "=== 3. 安装插件 ==="
cd ~
git clone https://github.com/dtrocl/memory-lancedb-pro.git ~/.openclaw/workspace-jarvis/memory-lancedb-pro
cd ~/.openclaw/workspace-jarvis/memory-lancedb-pro
npm install

echo "=== 4. 链接插件 ==="
mkdir -p ~/.openclaw/plugins
ln -sf ~/.openclaw/workspace-jarvis/memory-lancedb-pro ~/.openclaw/plugins/memory-lancedb-pro

echo "=== 5. 重启 OpenClaw ==="
openclaw gateway restart

echo "=== 完成！==="
```

---

## 7. 仓库信息

- **修改版**: https://github.com/dtrocl/memory-lancedb-pro
- **原版**: https://github.com/win4r/memory-lancedb-pro
- **分支**: local