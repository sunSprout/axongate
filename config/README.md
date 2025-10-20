# 配置文件说明

本目录包含 AxonGate 各组件的配置文件模板。

---

## 文件列表

| 文件                   | 用途               | 部署位置                            |
| ---------------------- | ------------------ | ----------------------------------- |
| `backend.yaml.example` | Backend 配置模板   | `/opt/axongate/config/backend.yaml` |
| `engine.yaml.example`  | Engine 配置模板    | `/opt/axongate/config/engine.yaml`  |
| `Caddyfile`            | Caddy 反向代理配置 | `/opt/axongate/config/Caddyfile`    |

---

## 使用方法

### 初始化时自动复制

运行 `./scripts/init.sh` 时会自动将模板复制到 `/opt/axongate/config/`。

### 手动复制

```bash
sudo cp backend.yaml.example /opt/axongate/config/backend.yaml
sudo cp engine.yaml.example /opt/axongate/config/engine.yaml
sudo cp Caddyfile /opt/axongate/config/Caddyfile
```

---

## Backend 配置（backend.yaml）

### 核心配置项

```yaml
# API 服务器（面向用户的管理接口）
api_server_host: "0.0.0.0"
api_server_port: 8080

# Engine 服务器（面向 Engine 的内部接口）
engine_server_host: "0.0.0.0"
engine_server_port: 8081

# 数据库
db_host: "postgres"              # Docker 环境使用服务名
db_port: 5432
db_user: "postgres"
db_password: "postgres123"       # ⚠️ 生产环境通过环境变量覆盖
db_name: "ai_proxy"
db_max_connections: 25           # 根据负载调整
db_max_idle_conns: 5

# 日志
log_level: "info"                # debug | info | warn | error
log_dir: "/var/log/ai-gateway"
log_max_size: 100                # MB
log_max_backups: 7               # 保留天数
```

### 环境变量覆盖

配置项可通过环境变量覆盖（优先级更高）：

```bash
# 格式：AIPROXY_<配置项大写>
export AIPROXY_DB_PASSWORD=your_password
export AIPROXY_LOG_LEVEL=debug
```

---

## Engine 配置（engine.yaml）

### 核心配置项

```yaml
server:
  host: "0.0.0.0"
  port: 8090
  workers: 4                     # 工作线程数，建议等于 CPU 核心数

business_api:
  base_url: "http://ai-backend:8081"
  timeout: "5s"
  retry_attempts: 3

cache:
  type: "memory"                 # 当前仅支持 memory
  ttl: "5m"                      # 缓存 TTL（滑动窗口）
  max_size: 10000                # 最大缓存条目数

proxy:
  timeout: "30s"                 # LLM 请求超时
  max_connections: 500           # 最大连接数
  keep_alive: true
  retry_attempts: 3
```

### 性能调优

根据负载调整以下参数：

| 负载级别             | workers | cache.max_size | proxy.max_connections |
| -------------------- | ------- | -------------- | --------------------- |
| 低（<1000 QPM）      | 4       | 10000          | 500                   |
| 中（1000-10000 QPM） | 8       | 50000          | 1000                  |
| 高（>10000 QPM）     | 16      | 100000         | 2000                  |

---

## Caddy 配置（Caddyfile）

### 路由规则

```
{
  # 全局配置
  email {$ACME_EMAIL}
  local_certs                    # 开发环境使用本地证书
}

# 本地调试
:8080 {
  route /health {
    respond "OK"
  }

  route /api/* {
    reverse_proxy ai-backend:8080
  }

  route /v1/* {
    reverse_proxy ai-engine:8090
  }

  route {
    root * /srv
    file_server
    try_files {path} /index.html
  }
}

# 生产环境（启用 HTTPS）
{$DOMAIN} {
  # 同上路由规则
  tls {$ACME_EMAIL}              # 自动申请 Let's Encrypt 证书
}
```

### 自定义域名

编辑 `.env` 文件：

```bash
DOMAIN=your-domain.com
ACME_EMAIL=your@email.com
```

### 自签名证书

如果使用自有证书，修改 Caddyfile：

```
{$DOMAIN} {
  tls /etc/caddy/certs/cert.pem /etc/caddy/certs/key.pem
  # ... 其他配置
}
```

---

## 配置验证

### Backend 配置验证

```bash
docker exec -it axongate-backend aiproxy validate -c /app/config.yaml
```

### Engine 配置验证

```bash
docker exec -it axongate-engine ai-gateway-engine --config /app/config.yaml --validate
```

### Caddy 配置验证

```bash
docker exec -it axongate-caddy caddy validate --config /etc/caddy/Caddyfile
```

---

## 配置更新

修改配置后需重启相应服务：

```bash
# 修改 Backend 配置
sudo nano /opt/axongate/config/backend.yaml
docker-compose restart backend

# 修改 Engine 配置
sudo nano /opt/axongate/config/engine.yaml
docker-compose restart engine

# 修改 Caddy 配置
sudo nano /opt/axongate/config/Caddyfile
docker-compose restart caddy
```

---

## 安全建议

1. **敏感信息**：
   - 数据库密码通过 `.env` 文件注入
   - 不要在配置文件中硬编码密码
   - `.env` 文件不要提交到 Git

2. **文件权限**：
   ```bash
   sudo chmod 600 /opt/axongate/config/*.yaml
   sudo chown root:root /opt/axongate/config/*.yaml
   ```

3. **备份配置**：
   ```bash
   sudo tar -czf /opt/axongate/backups/config_$(date +%Y%m%d).tar.gz \
     /opt/axongate/config/
   ```

---

## 完整配置文档

详细配置说明请参阅 [docs/configuration.md](../docs/configuration.md)

---

**配置支持**：yinhui.zzy@gmail.com
