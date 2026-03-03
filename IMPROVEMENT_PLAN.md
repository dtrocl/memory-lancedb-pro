# memory-lancedb-pro 本地化改进计划

> 目标硬件: Intel N150 (4核), 16GB RAM, 512GB SATA SSD
> 系统: Ubuntu 22.04 Desktop
> OpenClaw: 2026.3.1

## 1. 当前问题

| 问题 | 影响 | 优先级 |
|------|------|--------|
| 默认使用云端 API (Jina/OpenAI) | 需要翻墙/付费 | 🔴 高 |
| rerank 默认开启 cross-encoder | 依赖外部 API | 🔴 高 |
| 未内置 Ollama 模型支持 | 需要手动配置 dimensions | 🟡 中 |
| 无资源限制 | N150 性能有限，可能卡顿 | 🟡 中 |
| 无中文本地部署文档 | 部署困难 | 🟡 中 |

## 2. 改进方案

### 2.1 默认配置修改

**修改文件**: `src/embedder.ts`

```typescript
// 添加默认支持的中文模型
const EMBEDDING_DIMENSIONS: Record<string, number> = {
  // ... 现有模型 ...
  
  // 新增: Ollama 本地模型 (轻量中文)
  "jina-embeddings-v2-base-zh": 768,    // 160MB, 中英双语
  "text2vec-base-chinese": 768,         // 363MB, 纯中文
  "nomic-embed-text": 768,              // 轻量多语言
  "bge-small-zh-v1.5": 512,             // 极轻量中文
};
```

**修改文件**: `src/retriever.ts`

```typescript
// 将 rerank 默认值改为 lightweight
const DEFAULT_RETRIEVAL_CONFIG = {
  // ...
  rerank: "lightweight",  // 原来是 "cross-encoder"
  // ...
};
```

### 2.2 添加本地模型自动检测

**修改**: 当 `baseURL` 包含 `localhost:11434` 时，自动使用 lightweight rerank

### 2.3 资源优化

- 添加并发限制 (maxConcurrent = 2)
- 添加超时配置
- 优化 LanceDB 缓存大小

### 2.4 部署脚本

添加以下脚本：
- `scripts/install-ollama.sh` - 安装 Ollama
- `scripts/pull-model.sh` - 拉取 embedding 模型
- `scripts/deploy.sh` - 一键部署

### 2.5 文档

- `README_CN.md` - 中文部署指南 (已存在，需更新)
- 添加硬件特定配置建议

## 3. 推荐的本地配置

```json
{
  "embedding": {
    "apiKey": "ollama",
    "model": "jina-embeddings-v2-base-zh",
    "baseURL": "http://localhost:11434/v1",
    "dimensions": 768,
    "chunking": true
  },
  "dbPath": "~/.openclaw/memory/lancedb-pro",
  "autoCapture": false,
  "autoRecall": false,
  "retrieval": {
    "mode": "vector",
    "rerank": "lightweight",
    "filterNoise": true
  },
  "enableManagementTools": true
}
```

## 4. 部署步骤

### 4.1 安装 Ollama
```bash
curl -fsSL https://ollama.com/install.sh | sh
```

### 4.2 拉取 embedding 模型
```bash
ollama pull jina-embeddings-v2-base-zh
```

### 4.3 安装插件
```bash
# 方式1: 链接到 ~/.openclaw/plugins/
ln -s /path/to/memory-lancedb-pro ~/.openclaw/plugins/memory-lancedb-pro

# 方式2: 使用 clawhub
clawhub install dtrocl/memory-lancedb-pro
```

### 4.4 配置 OpenClaw
在 `openclaw.json` 中添加插件配置

## 5. 性能预期

| 指标 | 预期值 |
|------|--------|
| Embedding 延迟 | ~500ms (本地) |
| 检索延迟 | ~100ms |
| 内存占用 | ~2GB |
| 磁盘占用 | ~100MB/万条记忆 |

## 6. 待实现功能

- [ ] 添加默认本地模型到 EMBEDDING_DIMENSIONS
- [ ] 修改 rerank 默认值为 lightweight
- [ ] 添加本地模式自动检测逻辑
- [ ] 创建安装脚本
- [ ] 更新中文文档
- [ ] 添加资源限制配置

## 7. 分支策略

- `main` - 保持与上游同步
- `local` - 本地化改进分支