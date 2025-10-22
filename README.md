# AxonGate - 高性能 AI 模型网关

> 企业级 AI 模型路由与协议转换网关，支持 OpenAI 与 Anthropic 协议无缝切换

[![License](https://img.shields.io/badge/license-Mixed-blue.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/docker-ready-brightgreen.svg)](docker-compose.yml)
[![GitHub Stars](https://img.shields.io/github/stars/sunSprout/axongate.svg)](https://github.com/sunSprout/axongate/stargazers)

---

## 📖 项目简介

AxonGate 是一个采用微服务架构的高性能 AI 模型网关系统，专为企业级应用设计。它提供统一的 API 入口，自动处理不同 LLM 服务商之间的协议转换，并内置完善的权限管理、请求追踪和性能监控能力。

### 核心组件

| 组件                                                       | 技术栈                          | 许可证       | 仓库                                                            |
| ---------------------------------------------------------- | ------------------------------- | ------------ | --------------------------------------------------------------- |
| **Backend**                                                | Go + Gin + Ent                  | 专有（闭源） | -                                                               |
| **[Engine](https://github.com/sunSprout/axongate-engine)** | Rust + Axum + Tokio             | Apache-2.0   | [axongate-engine](https://github.com/sunSprout/axongate-engine) |
| **[UI](https://github.com/sunSprout/axongate-ui)**         | React + TypeScript + Ant Design | MIT          | [axongate-ui](https://github.com/sunSprout/axongate-ui)         |

---

## ✨ 核心特性

- 🚀 **协议自动转换** - OpenAI ↔ Anthropic 双向转换，客户端无感知
- ⚡ **高性能引擎** - Rust 实现的代理引擎，多层缓存策略，毫秒级响应
- 🔐 **企业级安全** - RBAC 权限管理
- 📊 **完整监控** - 请求全链路追踪，实时性能指标，健康检查
- 🔄 **智能路由** - 支持故障转移和负载均衡
- 🐳 **容器化部署** - 一键启动，开箱即用

---

## 📸 界面预览

### 登录与仪表盘

<table>
  <tr>
    <td align="center">
      <img src="images/login.png" alt="登录页面" width="600"/>
      <br/>
      <b>登录页面</b>
      <br/>
      简洁美观的登录界面，支持用户身份认证
    </td>
  </tr>
  <tr>
    <td align="center">
      <img src="images/dashboard.png" alt="仪表盘主页" width="600"/>
      <br/>
      <b>仪表盘主页</b>
      <br/>
      一目了然的系统概览，提供活跃供应商、可用模型、请求统计等关键指标
    </td>
  </tr>
</table>

### 配置管理

<table>
  <tr>
    <td align="center">
      <img src="images/provide.png" alt="供应商管理" width="600"/>
      <br/>
      <b>供应商管理</b>
      <br/>
      管理 AI 模型供应商配置，支持 OpenAI、Anthropic 等多种服务商
    </td>
  </tr>
  <tr>
    <td align="center">
      <img src="images/model.png" alt="模型管理" width="600"/>
      <br/>
      <b>模型管理</b>
      <br/>
      配置 AI 模型参数，设置价格和状态，灵活管理模型资源
    </td>
  </tr>
  <tr>
    <td align="center">
      <img src="images/provide_token.png" alt="供应商 Token 管理" width="600"/>
      <br/>
      <b>供应商 Token 管理</b>
      <br/>
      安全管理各供应商的 API 密钥，支持加密存储和健康检测
    </td>
  </tr>
</table>

### 访问控制

<table>
  <tr>
    <td align="center">
      <img src="images/user_token.png" alt="用户 Token 管理" width="600"/>
      <br/>
      <b>用户 Token 管理</b>
      <br/>
      生成和管理 API 访问令牌，控制系统访问权限和速率限制
    </td>
  </tr>
</table>

### 监控与分析

<table>
  <tr>
    <td align="center">
      <img src="images/status.png" alt="使用统计" width="600"/>
      <br/>
      <b>使用统计与分析</b>
      <br/>
      实时追踪请求数、Token 消耗、费用统计和模型使用分布
    </td>
  </tr>
</table>

### 系统设置

<table>
  <tr>
    <td align="center">
      <img src="images/setting.png" alt="系统设置" width="600"/>
      <br/>
      <b>个人设置</b>
      <br/>
      管理个人信息和系统配置，包括安全设置和系统参数
    </td>
  </tr>
</table>

---

## 🚀 快速启动

### 前置要求

- Docker 20.10+
- Docker Compose 2.0+
- Git
- 4GB+ 可用内存

### 安装步骤

```bash
# 1. 克隆仓库（包含开源组件 Submodules）
git clone --recursive git@github.com:sunSprout/axongate.git
cd axongate

# 2. 初始化环境（创建 /opt/axongate/ 目录结构）
sudo ./scripts/init.sh

# 3. 配置环境变量
cp .env.example .env
nano .env  # 修改 POSTGRES_PASSWORD 等敏感配置

# 4. 启动所有服务（首次启动约需 5-10 分钟构建镜像）
docker-compose up -d

# 5. 检查服务状态
./scripts/health-check.sh
```

### 访问地址

| 服务     | 地址                                     | 说明             |
| -------- | ---------------------------------------- | ---------------- |
| 管理面板 | http://localhost:8080                    | Web UI 管理界面  |
| API 文档 | http://localhost:8080/swagger/index.html | Swagger API 文档 |
| 健康检查 | http://localhost:8080/health             | 服务健康状态     |

### 默认账户

- **用户名**：`admin`
- **密码**：`admin123`

⚠️ **安全提示**：首次登录后请立即修改默认密码！

---

## 🏗️ 架构设计

```
┌─────────────────────────────────────────────────────────────┐
│                         用户/应用                            │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
                    ┌──────────┐
                    │  Caddy   │ (反向代理 + 前端静态文件)
                    └─────┬────┘
                          │
         ┌────────────────┼────────────────┐
         ▼                                 ▼
   ┌──────────┐                      ┌──────────┐
   │ Backend  │ (Go, 闭源)           │  Engine  │ (Rust, 开源)
   │          │◄─────────────────────│          │
   │ - 用户管理                       │ - 协议转换│
   │ - 权限控制                       │ - 智能路由│
   │ - 配置管理                       │ - 多层缓存│
   └─────┬────┘                      └──────────┘
         │
         ▼
   ┌──────────┐
   │PostgreSQL│ (数据持久化)
   └──────────┘
```

详细架构说明请参阅 [docs/architecture.md](docs/architecture.md)

---

## 📚 文档

| 文档                                | 说明                 |
| ----------------------------------- | -------------------- |
| [部署指南](docs/deployment.md)      | 生产环境部署详细步骤 |
| [配置说明](docs/configuration.md)   | 所有配置项详解       |
| [架构设计](docs/architecture.md)    | 系统架构与组件说明   |
| [故障排查](docs/troubleshooting.md) | 常见问题与解决方案   |

---

## 🔧 常用操作

### 更新开源组件

```bash
# 更新 Engine 和 UI 到最新版本
./scripts/update-submodules.sh

# 重新构建镜像
docker-compose build engine caddy

# 重启服务
docker-compose up -d
```

### 数据备份

```bash
# 备份 PostgreSQL 数据库
sudo ./scripts/backup.sh

# 恢复备份（示例）
gunzip -c /opt/axongate/backups/axongate_backup_20250101_120000.sql.gz | \
  docker exec -i axongate-postgres psql -U postgres ai_proxy
```

### 查看日志

```bash
# 查看所有服务日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f backend
docker-compose logs -f engine
docker-compose logs -f caddy
```

### 停止服务

```bash
# 停止所有服务
docker-compose down

# 停止并删除所有数据（危险操作！）
docker-compose down -v
```

---

## 🤝 开源与商业

AxonGate 采用 **混合许可模式**：

- **Backend（闭源）** - 核心业务逻辑，提供商业支持和定制化服务
- **Engine（开源）** - Apache-2.0 许可，欢迎社区贡献
- **UI（开源）** - MIT 许可，可自由修改和分发

开源组件接受 Pull Requests！贡献指南请参阅各组件仓库。

---

## 💬 技术支持

- 🐛 **问题反馈**：[GitHub Issues](https://github.com/sunSprout/axongate/issues)
- 📧 **商业支持**：yinhui.zzy@gmail.com


---

## 📄 许可证

- 开源组件遵循各自许可证（Apache-2.0 / MIT）
- Backend 为专有软件，保留所有权利
- 详见 [LICENSE](LICENSE) 文件

---

## ⭐ 星标支持

如果这个项目对您有帮助，请给我们一个 Star ⭐️

---

**Made with ❤️ by SunSprout Team**
