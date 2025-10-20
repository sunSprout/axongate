# 部署指南

本文档提供 AxonGate 在生产环境中的完整部署流程。

---

## 目录

- [系统要求](#系统要求)
- [快速部署](#快速部署)
- [生产环境配置](#生产环境配置)
- [HTTPS 配置](#https-配置)
- [性能优化](#性能优化)
- [监控与日志](#监控与日志)

---

## 系统要求

### 硬件要求

| 规模               | CPU  | 内存  | 存储       |
| ------------------ | ---- | ----- | ---------- |
| 小型（<1000 QPM）  | 2核  | 4GB   | 20GB SSD   |
| 中型（<10000 QPM） | 4核  | 8GB   | 50GB SSD   |
| 大型（>10000 QPM） | 8核+ | 16GB+ | 100GB+ SSD |

### 软件要求

- **操作系统**：Linux (Ubuntu 20.04+, CentOS 8+, Debian 11+)
- **Docker**：20.10 或更高版本
- **Docker Compose**：2.0 或更高版本
- **Git**：任意版本

---

## 快速部署

### 1. 克隆仓库

```bash
git clone --recursive git@github.com:sunSprout/axongate.git
cd axongate
```

### 2. 初始化环境

```bash
sudo ./scripts/init.sh
```

### 3. 配置环境变量

```bash
cp .env.example .env
nano .env
```

**必需配置项**：
```bash
POSTGRES_PASSWORD=your_secure_password  # 强密码
ACME_EMAIL=your@email.com              # 用于 HTTPS 证书
DOMAIN=your-domain.com                  # 生产域名
```

### 4. 启动服务

```bash
docker-compose up -d
```

### 5. 验证部署

```bash
./scripts/health-check.sh
```

---

## 生产环境配置

### Backend 配置

编辑 `/opt/axongate/config/backend.yaml`：

```yaml
# API 服务器
api_server_host: "0.0.0.0"
api_server_port: 8080

# 数据库连接池
db_max_connections: 50      # 根据负载调整
db_max_idle_conns: 10

# 日志
log_level: "info"           # 生产环境使用 info 或 warn
log_max_size: 100           # MB
log_max_backups: 30         # 保留30天
```

### Engine 配置

编辑 `/opt/axongate/config/engine.yaml`：

```yaml
server:
  workers: 8                # 根据 CPU 核心数调整

cache:
  ttl: "5m"
  max_size: 50000           # 根据内存调整

proxy:
  timeout: "60s"            # 根据 LLM 响应时间调整
  max_connections: 1000     # 根据负载调整
```

---

## HTTPS 配置

### 自动 HTTPS（Let's Encrypt）

Caddy 会自动申请和续期 HTTPS 证书：

```bash
# .env 配置
DOMAIN=your-domain.com
ACME_EMAIL=your@email.com
```

确保：
1. 域名 DNS 已正确解析到服务器
2. 端口 80 和 443 对外开放
3. 服务器可访问 Let's Encrypt API

### 手动证书

如果使用自有证书：

1. 将证书放置在 `/opt/axongate/config/certs/`：
   ```bash
   /opt/axongate/config/certs/
   ├── cert.pem
   └── key.pem
   ```

2. 修改 Caddyfile：
   ```
   your-domain.com {
       tls /etc/caddy/certs/cert.pem /etc/caddy/certs/key.pem
       # ...
   }
   ```

3. 在 docker-compose.yml 中挂载证书目录：
   ```yaml
   volumes:
     - /opt/axongate/config/certs:/etc/caddy/certs:ro
   ```

---

## 性能优化

### 数据库优化

```bash
# 在宿主机编辑 PostgreSQL 配置
sudo nano /opt/axongate/data/postgres/postgresql.conf
```

推荐配置（8GB 内存服务器）：
```
shared_buffers = 2GB
effective_cache_size = 6GB
maintenance_work_mem = 512MB
max_connections = 200
```

重启数据库：
```bash
docker-compose restart postgres
```

### 缓存优化

Engine 使用多层缓存策略：

- **L1 缓存**（内存）：路由信息，5分钟 TTL
- **L2 缓存**（Backend API）：用户/配置信息

根据负载调整 `engine.yaml` 中的 `cache.max_size`。

### 资源限制

在 `docker-compose.yml` 中添加资源限制：

```yaml
services:
  backend:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G
```

---

## 监控与日志

### 日志管理

日志位置：
- Backend: `/opt/axongate/logs/api.log`
- Engine: `/opt/axongate/logs/engine.log`

日志轮转已自动配置（30天保留期）。

### 实时日志

```bash
# 查看所有服务日志
docker-compose logs -f

# 查看特定服务
docker-compose logs -f backend
docker-compose logs -f engine
```

### 健康检查

```bash
# 定期运行健康检查
./scripts/health-check.sh

# 或配置 cron 任务
crontab -e
# 每5分钟检查一次
*/5 * * * * /path/to/axongate/scripts/health-check.sh >> /var/log/axongate-health.log 2>&1
```

### 性能监控

推荐集成：
- **Prometheus** - 指标收集
- **Grafana** - 可视化仪表板
- **Loki** - 日志聚合

---

## 备份与恢复

### 自动备份

```bash
# 配置每日备份
crontab -e
0 2 * * * /path/to/axongate/scripts/backup.sh >> /var/log/axongate-backup.log 2>&1
```

### 手动备份

```bash
sudo ./scripts/backup.sh
```

### 恢复数据

```bash
# 恢复最新备份
BACKUP_FILE=$(ls -t /opt/axongate/backups/*.sql.gz | head -1)
gunzip -c $BACKUP_FILE | docker exec -i axongate-postgres psql -U postgres ai_proxy
```

---

## 故障排查

遇到问题请参阅 [故障排查文档](troubleshooting.md)。

---

## 更新升级

### 更新开源组件

```bash
./scripts/update-submodules.sh
docker-compose build engine caddy
docker-compose up -d
```

### 更新 Backend

由维护人员提供新的二进制文件到 `bin/` 目录后：

```bash
docker-compose build backend
docker-compose up -d backend
```

---

## 安全加固

1. **修改默认密码**
   - 登录后立即修改 admin 账户密码
   - 使用强密码策略

2. **网络隔离**
   - 仅暴露必要端口（80, 443）
   - 使用防火墙限制访问来源

3. **定期更新**
   - 及时更新 Docker 镜像
   - 关注安全公告

4. **审计日志**
   - 定期审查访问日志
   - 监控异常请求

---

**部署支持**：yinhui.zzy@gmail.com
