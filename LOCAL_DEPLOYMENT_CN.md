# memory-lancedb-pro 本地化改进说明

> 本版本针对中国大陆环境优化，支持完全本地离线部署

---

## 1. 主要改动

### 1.1 新增本地模型支持 (embedder.ts)

添加了以下 Ollama 本地中文 embedding 模型：

```typescript
"jina-embeddings-v2-base-zh": 768,   // 推荐：160MB，中英双语
"bge-small-zh-v1.5": 512,            // 极轻量：270MB
```

### 1.2 默认使用 lightweight rerank (retriever.ts)

将默认 rerank 模式从 `cross-encoder` 改为 `lightweight`：

```typescript
// 之前
rerank: "cross-encoder"  // 需要外部 API

// 现在
rerank: "lightweight"   // 本地 cosine 计算
```

### 1.3 新增部署脚本

| 脚本 | 功能 |
|------|------|
| `scripts/install-ollama.sh` | 一键安装 Ollama |
| `scripts/pull-model.sh` | 拉取 embedding 模型 |
| `scripts/deploy.sh` | 一键部署 |

---

## 2. 工作原理详解

### 2.1 自动 Chunking 机制

当存储的文本超过 embedding 模型的长度限制时，会自动触发 chunking：

```
用户存储记忆 (text)
    ↓
embedder.embedPassage(text)
    ↓
尝试直接 embedding
    ↓ 失败 (context length error)
smartChunk(text, model) ← 自动分块
    ↓
对每个 chunk 分别 embedding
    ↓
取平均值作为最终向量
    ↓
存入 LanceDB
```

**位置**: `src/embedder.ts` 第 294 行和第 402 行

### 2.2 Hook 机制

插件注册了 3 个 OpenClaw 钩子：

| 钩子 | 触发时机 | 功能 | 默认 |
|------|----------|------|------|
| `before_agent_start` | Agent 启动前 | 自动注入记忆到上下文 | 关闭 |
| `agent_end` | Agent 结束后 | 自动捕获重要信息 | 开启 |
| `command:new` | 用户输入 `/new` | 保存会话摘要 | 开启 |

### 2.3 会话 /new 和 agent_end 的关系

- `/new` 触发 `command:new` hook，读取**上一个会话**内容并存储
- `/new` **不触发** `agent_end`（因为会话不是"结束"是"切换"）
- 两者是**独立的**，不会丢失数据

---

## 3. 数据迁移

### 3.1 现有记忆迁移

可以将内置 `memory-lancedb` 的数据迁移到本插件：

```bash
# 检查有多少数据可迁移
openclaw memory-pro migrate check

# 执行迁移
openclaw memory-pro migrate run

# 验证
openclaw memory-pro stats
```

现有数据位置：`~/.openclaw/memory/jarvis.sqlite`

### 3.2 存储路径

- 本插件：`~/.openclaw/memory/lancedb-pro/`
- 格式：LanceDB (Parquet 文件)

---

## 4. 推荐的本地配置

```json
{
  "embedding": {
    "apiKey": "ollama",
    "model": "jina-embeddings-v2-base-zh",
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
```

---

## 5. 推荐的中文 Embedding 模型

| 模型 | 大小 | 维度 | 说明 |
|------|------|------|------|
| **jina-embeddings-v2-base-zh** | 160MB | 768 | ⭐ 推荐 |
| text2vec-base-chinese | 363MB | 768 | 纯中文 |
| bge-small-zh-v1.5 | 270MB | 512 | 极轻量 |
| bge-base-zh-v1.5 | 410MB | 768 | 均衡 |

---

## 6. 部署步骤

### 方式一：一键部署

```bash
cd scripts
chmod +x *.sh
./deploy.sh
```

### 方式二：手动部署

```bash
# 1. 安装 Ollama
./scripts/install-ollama.sh

# 2. 拉取模型
./scripts/pull-model.sh

# 3. 链接插件
ln -s /path/to/memory-lancedb-pro ~/.openclaw/plugins/memory-lancedb-pro

# 4. 配置 openclaw.json

# 5. 重启
openclaw gateway restart
```

---

## 7. 仓库信息

- **上游**: https://github.com/win4r/memory-lancedb-pro
- **Fork**: https://github.com/dtrocl/memory-lancedb-pro
- **分支**: local (本地化改进)

---

## 8. 常见问题

### Q: 安装需要 API Key 吗？

A: `npm install` 不需要任何 API Key。API Key 是运行时配置。

### Q: 数据会丢失吗？

A: 不会。现有数据可以迁移，原有 SQLite 文件保留。

### Q: chunking 是什么时候发生的？

A: 当文本超过 embedding 模型上下文限制时自动触发，对用户透明。

### Q: /new 和 agent_end 哪个先触发？

A: 两者独立。/new 触发 command:new hook，读取上一个会话内容；agent_end 触发自动捕获。不会重复也不会丢失。