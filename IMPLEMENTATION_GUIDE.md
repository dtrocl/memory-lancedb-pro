# 实施指南 - 审核版

> 审核后请备份系统，然后按步骤部署

---

## 1. 代码修改清单

### 1.1 修改文件: `src/embedder.ts`

**位置**: 第 104-120 行

**修改内容**: 添加本地化模型到 EMBEDDING_DIMENSIONS

```typescript
// 在现有模型列表末尾添加:
  // ========================================
  // 本地化模型 (Ollama) - 轻量中文优化
  // ========================================
  // Jina 中文模型 (推荐)
  "jina-embeddings-v2-base-zh": 768,
  // BGE 中文模型
  "bge-large-zh-v1.5": 1024,
  "bge-base-zh-v1.5": 768,
  "bge-small-zh-v1.5": 512,
  // 纯中文模型
  "text2vec-base-chinese": 768,
  "text2vec-large-chinese": 1024,
```

---

### 1.2 修改文件: `src/retriever.ts`

**位置**: 查找 `DEFAULT_RETRIEVAL_CONFIG`

**修改内容**: 将 `rerank` 默认值从 `"cross-encoder"` 改为 `"lightweight"`

```typescript
export const DEFAULT_RETRIEVAL_CONFIG: RetrievalConfig = {
  // ... 其他配置保持不变
  rerank: "lightweight",  // 原来是 "cross-encoder"
  // ...
};
```

---

### 1.3 新增文件: `scripts/install-ollama.sh`

创建一键安装 Ollama 脚本

---

### 1.4 新增文件: `scripts/pull-model.sh`

创建一键拉取 embedding 模型脚本

---

### 1.5 修改文件: `openclaw.plugin.json`

可选：更新 UI hints 添加本地模型提示

---

## 2. 部署前检查清单

- [ ] 备份当前系统 (快照/镜像)
- [ ] 检查磁盘空间 (至少 2GB 可用)
- [ ] 检查网络 (用于下载 Ollama 安装包)
- [ ] 准备 OpenClaw 配置备份

---

## 3. 部署步骤 (审核后执行)

### 步骤 1: 安装 Ollama
```bash
curl -fsSL https://ollama.com/install.sh | sh
```

### 步骤 2: 拉取 embedding 模型
```bash
ollama pull jina-embeddings-v2-base-zh
```

### 步骤 3: 安装插件
```bash
# 方式1: 软链接
ln -s /path/to/memory-lancedb-pro ~/.openclaw/plugins/

# 方式2: 等待 clawhub 支持
```

### 步骤 4: 配置 OpenClaw
在 `openclaw.json` 中添加:
```json
{
  "plugins": {
    "memory-lancedb-pro": {
      "enabled": true,
      "embedding": {
        "apiKey": "ollama",
        "model": "jina-embeddings-v2-base-zh",
        "baseURL": "http://localhost:11434/v1"
      },
      "retrieval": {
        "rerank": "lightweight"
      },
      "autoCapture": false,
      "autoRecall": false
    }
  }
}
```

### 步骤 5: 重启 OpenClaw
```bash
openclaw gateway restart
```

### 步骤 6: 验证
```bash
# 检查 Ollama 服务
curl http://localhost:11434/api/tags

# 检查插件日志
tail -f ~/.openclaw/logs/gateway.log
```

---

## 4. 回滚方案

如果部署失败:
1. 恢复 `openclaw.json` 备份
2. 删除插件链接: `rm ~/.openclaw/plugins/memory-lancedb-pro`
3. 重启 OpenClaw: `openclaw gateway restart`

---

## 5. 预期效果

| 指标 | 预期值 |
|------|--------|
| Embedding 延迟 | ~500ms (本地) |
| 检索延迟 | ~100ms |
| 内存占用 | ~2GB |
| 离线可用 | ✅ 完全离线 |

---

## 6. 当前代码状态

- **仓库**: https://github.com/dtrocl/memory-lancedb-pro
- **分支**: `local`
- **状态**: 计划文档已完成，等待实施代码修改

---

**请审核以上计划，确认无误后再进行部署。**