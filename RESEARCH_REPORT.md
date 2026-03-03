# memory-lancedb-pro 本地化部署研究报告

> 目标硬件: Intel N150 (4核/6W), 16GB RAM, 512GB SATA SSD
> 系统: Ubuntu 22.04 Desktop
> OpenClaw: 2026.3.1
> Fork 仓库: https://github.com/dtrocl/memory-lancedb-pro

---

## 1. 研究成果总结

### 1.1 项目基本信息
- **类型**: OpenClaw 插件 (plugin)
- **功能**: 增强版长期记忆系统，使用 LanceDB 向量数据库
- **核心能力**: 混合检索、多 scope 隔离、自动捕获/回忆

### 1.2 代码安全审查 ✅
| 检查项 | 结果 |
|--------|------|
| 恶意代码 | 无 |
| 数据外传 | 无 |
| 隐藏收集 | 无 |
| 敏感信息泄露 | 极低 |

### 1.3 本地化可行性
| 功能 | 云端API | 本地化方案 |
|------|---------|------------|
| Embedding | OpenAI/Jina | ✅ Ollama |
| Reranker | Jina AI | ⚠️ 禁用或 lightweight |
| 存储 | - | ✅ 本地 LanceDB |

---

## 2. 硬件环境分析

### 2.1 N150 处理器性能
- **核心数**: 4 核 4 线程
- **TDP**: 6W (低功耗)
- **单核性能**: 约等于 i3-7100U 级别
- **适合场景**: 轻量级推理、嵌入式部署

### 2.2 资源限制
| 资源 | 容量 | 建议 |
|------|------|------|
| CPU | 4核 | 并发限制 ≤2 |
| 内存 | 16GB | LanceDB 缓存 ≤2GB |
| 存储 | 512GB SSD | 约 100MB/万条 |

---

## 3. 需要改进的问题

### 3.1 当前问题清单
| # | 问题 | 影响 | 优先级 |
|---|------|------|--------|
| 1 | 默认使用云端 API | 需要翻墙/付费 | 🔴 高 |
| 2 | rerank 默认 cross-encoder | 依赖外部 API | 🔴 高 |
| 3 | 未内置 Ollama 中文模型 | 需手动配置 dimensions | 🟡 中 |
| 4 | 无资源限制 | N150 可能卡顿 | 🟡 中 |
| 5 | 无中文本地部署文档 | 部署困难 | 🟡 中 |

### 3.2 需要修改的文件
1. `src/embedder.ts` - 添加本地模型维度
2. `src/retriever.ts` - 修改默认 rerank 配置
3. `openclaw.plugin.json` - 更新 UI hints
4. 新增 `scripts/` - 部署脚本

---

## 4. 推荐的中文 Embedding 模型

| 模型 | 大小 | 维度 | 适合场景 |
|------|------|------|----------|
| **jina-embeddings-v2-base-zh** | 160MB | 768 | ⭐ 推荐，轻量效果好 |
| text2vec-base-chinese | 363MB | 768 | 纯中文优化 |
| bge-small-zh-v1.5 | 270MB | 512 | 极轻量 |
| bge-base-zh-v1.5 | 410MB | 768 | 均衡 |

---

## 5. 完整本地化配置

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

---

## 6. 实施计划

### Phase 1: 代码修改 (1-2天)
- [ ] 添加本地模型到 EMBEDDING_DIMENSIONS
- [ ] 修改 rerank 默认值为 lightweight
- [ ] 添加本地模式自动检测

### Phase 2: 部署脚本 (1天)
- [ ] `scripts/install-ollama.sh` - 安装 Ollama
- [ ] `scripts/pull-model.sh` - 拉取模型
- [ ] `scripts/deploy.sh` - 一键部署

### Phase 3: 文档 (1天)
- [ ] 更新 README_CN.md
- [ ] 添加硬件特定配置指南

### Phase 4: 测试验证 (1天)
- [ ] 本地部署测试
- [ ] 性能基准测试
- [ ] 功能验证

---

## 7. 预期效果

| 指标 | 预期值 |
|------|--------|
| Embedding 延迟 | ~500ms (本地) |
| 检索延迟 | ~100ms |
| 内存占用 | ~2GB |
| 离线可用 | ✅ 完全离线 |

---

## 8. 仓库信息

- **上游**: https://github.com/win4r/memory-lancedb-pro
- **Fork**: https://github.com/dtrocl/memory-lancedb-pro
- **分支**: `local` (本地化改进)
- **当前状态**: 已创建计划，等待实施