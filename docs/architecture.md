# 架构设计

本文档详细说明 AxonGate 的系统架构、组件职责和数据流。

---

## 系统架构图

```
                    ┌─────────────────────┐
                    │   用户/应用客户端    │
                    └──────────┬──────────┘
                               │
                               │ HTTP/HTTPS
                               ▼
                    ┌──────────────────────┐
                    │       Caddy          │
                    │ (反向代理 + 前端)     │
                    └──────────┬───────────┘
                               │
                    ┌──────────┴──────────┐
                    │                     │
        /api/v1/*   ▼         /v1/*      ▼
      ┌─────────────────┐    ┌─────────────────┐
      │    Backend      │    │     Engine      │
      │    (Go)         │◄───│    (Rust)       │
      │   【闭源】       │    │   【开源】       │
      └────────┬────────┘    └─────────────────┘
               │
               │ SQL
               ▼
      ┌─────────────────┐
      │   PostgreSQL    │
      │  (数据持久化)    │
      └─────────────────┘
```

---

## 组件职责

### 1. Caddy（反向代理 + 前端）

**技术栈**：Caddy 2.7 + React 19

**职责**：
- 反向代理路由（/api → Backend, /v1 → Engine）
- 前端静态文件服务
- 自动 HTTPS 证书管理（Let's Encrypt）
- 请求日志记录

**端口**：
- 80（HTTP）
- 443（HTTPS）
- 8080（调试端口）

---

### 2. Backend（业务逻辑层）

**技术栈**：Go 1.24 + Gin + Ent + Casbin

**职责**：
- 用户认证与会话管理
- RBAC 权限控制
- 供应商/模型配置管理
- API 密钥加密存储（RSA）
- 路由解析 API（供 Engine 调用）
- 遥测事件收集

**API 端点**：
- `/api/v1/user-tokens` - 用户 Token 管理
- `/api/v1/providers` - 供应商配置
- `/api/v1/ai-models` - 模型管理
- `/v1/route/resolve` - 路由解析（Engine 专用）
- `/v1/telemetry/events` - 遥测上报

**端口**：
- 8080（对外 API）
- 8081（Engine 内部 API）

**许可**：专有（闭源）

---

### 3. Engine（代理引擎）

**技术栈**：Rust 1.83 + Axum + Tokio + Hyper

**职责**：
- HTTP 代理转发
- 协议自动检测与转换（OpenAI ↔ Anthropic）
- 多层缓存（DashMap + Moka）
- 故障转移与负载均衡
- 流式响应支持（SSE）
- 请求生命周期监控

**核心模块**：
- `protocol/` - 协议检测与转换
- `router/` - 请求路由与故障转移
- `proxy/` - HTTP 转发与连接池
- `cache/` - 多层缓存管理
- `telemetry/` - 指标采集

**端口**：
- 8090（内部端口，不对外暴露）

**许可**：Apache-2.0（开源）
**仓库**：https://github.com/sunSprout/axongate-engine

---

### 4. UI（管理面板）

**技术栈**：React 19 + TypeScript + Ant Design 5 + Zustand

**职责**：
- 用户管理界面
- 供应商配置界面
- 模型管理界面
- 使用统计仪表板

**许可**：MIT（开源）
**仓库**：https://github.com/sunSprout/axongate-ui

---

### 5. PostgreSQL（数据库）

**版本**：15-alpine

**存储内容**：
- 用户与角色（RBAC）
- 供应商配置
- 加密的 API 密钥
- 模型配置
- 使用统计

---

## 请求流程

### OpenAI 请求流程

```
1. 客户端 → Caddy (:8080)
   POST /v1/chat/completions
   Authorization: Bearer user_token_xxx

2. Caddy → Engine (:8090)
   透传请求

3. Engine → Backend (:8081)
   POST /v1/route/resolve
   解析 user_token，获取路由信息

4. Engine 检查缓存
   - 命中：直接使用缓存的路由
   - 未命中：调用 Backend API

5. Engine → Target Provider
   转发请求到目标 LLM 服务
   - 如果目标是 Anthropic，自动转换协议

6. Target Provider → Engine
   返回响应（支持流式）

7. Engine → Caddy → 客户端
   返回响应（协议转换，如果需要）
```

### 协议转换矩阵

| 客户端协议 | 目标供应商 | 转换操作           |
| ---------- | ---------- | ------------------ |
| OpenAI     | OpenAI     | 透传               |
| OpenAI     | Anthropic  | OpenAI → Anthropic |
| Anthropic  | OpenAI     | Anthropic → OpenAI |
| Anthropic  | Anthropic  | 透传               |

---

## 数据流

### 配置数据流

```
管理员 → UI → Backend → PostgreSQL
     (创建供应商/模型配置)

Backend → Engine (被动拉取)
     (Engine 通过 /v1/route/resolve 获取)

Engine 缓存 (5分钟 TTL)
     (减少 Backend 调用)
```

### 遥测数据流

```
Engine → Backend
     POST /v1/telemetry/events
     (请求开始/结束/错误事件)

Backend → PostgreSQL
     (持久化到 usage 表)

UI → Backend
     GET /api/v1/usage
     (查询统计数据)
```

---

## 缓存策略

### Engine 缓存

**L1 缓存**（内存，DashMap）：
- 键：用户 Token 哈希
- 值：路由信息（供应商、模型、API 密钥）
- TTL：5分钟（滑动窗口）
- 失效条件：TTL 过期 or 请求失败

**L2 缓存**（Backend API）：
- 数据库查询结果
- 连接池复用

---

## 安全设计

### 认证流程

1. 用户登录 → Backend 创建 Session（Redis）
2. 客户端使用 User Token 调用 API
3. Engine 转发 Token 到 Backend 验证
4. Backend 返回解密后的 Provider Token
5. Engine 使用 Provider Token 调用 LLM 服务

### 密钥加密

- 供应商 API 密钥使用 RSA 加密存储
- 私钥仅 Backend 持有
- Engine 通过 Backend API 获取明文密钥（内部网络）

---

## 扩展性设计

### 水平扩展

- **Backend**：无状态，可通过负载均衡水平扩展
- **Engine**：无状态，可通过负载均衡水平扩展
- **PostgreSQL**：主从复制 + 读写分离

### 故障隔离

- Engine 与 Backend 解耦，Backend 故障不影响已缓存路由
- Engine 内置故障转移，自动切换到备用供应商
- 健康检查机制自动摘除不健康节点

---

## 开源与闭源边界

```
┌─────────────────────────────────────────┐
│              开源组件                    │
│  ┌────────────────┐  ┌────────────────┐│
│  │     Engine     │  │       UI       ││
│  │   (Apache-2.0) │  │     (MIT)      ││
│  └────────────────┘  └────────────────┘│
└─────────────┬───────────────────────────┘
              │ API 调用
              ▼
┌─────────────────────────────────────────┐
│           闭源核心（商业化）              │
│  ┌────────────────────────────────────┐ │
│  │          Backend                   │ │
│  │  - 用户管理与认证                   │ │
│  │  - 权限控制（RBAC）                 │ │
│  │  - 配置管理                         │ │
│  │  - 密钥加密                         │ │
│  └────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

**开源组件**：
- 贡献者可自由查看、修改、分发
- 接受 Pull Requests

**闭源核心**：
- 核心业务逻辑
- 企业级功能
- 商业支持与定制化服务

---

**架构问题**：yinhui.zzy@gmail.com
