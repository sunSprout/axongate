# 配置说明

AxonGate 的配置分为三部分：环境变量（.env）、Backend 配置、Engine 配置。

---

## 环境变量（.env）

位置：`/path/to/axongate/.env`

```bash
# 数据库配置（必需）
POSTGRES_PASSWORD=your_password     # 强密码
POSTGRES_DB=ai_proxy
POSTGRES_USER=postgres

# Caddy 配置
ACME_EMAIL=admin@example.com        # HTTPS 证书邮箱
DOMAIN=your-domain.com              # 生产域名

# 端口配置
HTTP_PORT=80
HTTPS_PORT=443
DEBUG_PORT=8080
```

---

## Backend 配置

位置：`/opt/axongate/config/backend.yaml`

```yaml
# API 服务器
api_server_host: "0.0.0.0"
api_server_port: 8080

# Engine 内部服务器
engine_server_host: "0.0.0.0"
engine_server_port: 8081

# 数据库（Docker 环境）
db_host: "postgres"
db_port: 5432
db_user: "postgres"
db_password: "postgres123"  # 通过环境变量覆盖
db_name: "ai_proxy"
db_max_connections: 25
db_max_idle_conns: 5

# 日志
log_level: "info"                    # debug | info | warn | error
log_dir: "/var/log/ai-gateway"
api_log_file: "api.log"
engine_log_file: "engine.log"
log_max_size: 100                    # MB
log_max_backups: 7                   # 保留7天
log_max_age: 30                      # 天
```

---

## Engine 配置

位置：`/opt/axongate/config/engine.yaml`

```yaml
server:
  host: "0.0.0.0"
  port: 8090
  workers: 4                         # 工作线程数

business_api:
  base_url: "http://ai-backend:8081" # Backend 内部 API
  timeout: "5s"
  retry_attempts: 3

cache:
  type: "memory"                     # memory | redis（未来支持）
  ttl: "5m"                          # 滑动 TTL
  max_size: 10000                    # 最大缓存条目

proxy:
  timeout: "30s"                     # LLM 请求超时
  max_connections: 500               # 最大连接数
  keep_alive: true
  retry_attempts: 3
```

---

## 配置优先级

```
环境变量 > 配置文件 > 默认值
```

示例：数据库密码
1. 环境变量 `POSTGRES_PASSWORD`（优先级最高）
2. `backend.yaml` 中的 `db_password`
3. 默认值

---

## 生产环境推荐配置

### 高负载场景

**Backend**：
```yaml
db_max_connections: 100
db_max_idle_conns: 20
log_level: "warn"
```

**Engine**：
```yaml
server:
  workers: 16                        # 根据 CPU 核心数
cache:
  max_size: 100000
proxy:
  max_connections: 2000
  timeout: "60s"
```

---

**配置支持**：yinhui.zzy@gmail.com
