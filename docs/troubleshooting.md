# 故障排查手册

本文档列出常见问题及解决方案。

---

## 容器问题

### 问题：容器无法启动

**症状**：
```bash
docker-compose up -d
# 容器立即退出
```

**排查步骤**：

1. 查看容器日志
   ```bash
   docker-compose logs backend
   docker-compose logs engine
   ```

2. 检查端口占用
   ```bash
   sudo netstat -tlnp | grep -E '(80|443|8080|5432)'
   ```

3. 检查 .env 配置
   ```bash
   cat .env
   # 确保 POSTGRES_PASSWORD 已设置
   ```

---

### 问题：健康检查失败

**症状**：
```bash
./scripts/health-check.sh
# ❌ axongate-backend: 健康检查 unhealthy
```

**解决方案**：

1. 检查依赖服务
   ```bash
   docker exec axongate-postgres pg_isready -U postgres
   ```

2. 检查配置文件
   ```bash
   cat /opt/axongate/config/backend.yaml
   # 确保数据库配置正确
   ```

3. 重启服务
   ```bash
   docker-compose restart backend
   ```

---

## 网络问题

### 问题：无法访问管理面板

**症状**：
```
http://localhost:8080 无法访问
```

**排查步骤**：

1. 检查 Caddy 容器状态
   ```bash
   docker ps | grep caddy
   docker logs axongate-caddy
   ```

2. 检查防火墙
   ```bash
   sudo ufw status
   # 确保 8080 端口开放
   ```

3. 检查端口绑定
   ```bash
   docker ps --format "table {{.Names}}\t{{.Ports}}" | grep caddy
   ```

---

### 问题：HTTPS 证书申请失败

**症状**：
```
caddy: obtaining certificate: ... failed
```

**解决方案**：

1. 确认 DNS 解析
   ```bash
   nslookup your-domain.com
   # 应解析到当前服务器 IP
   ```

2. 确认端口开放
   ```bash
   sudo netstat -tlnp | grep -E '(80|443)'
   # 确保 80 和 443 端口对外开放
   ```

3. 检查 .env 配置
   ```bash
   cat .env | grep DOMAIN
   # 确保 DOMAIN 和 ACME_EMAIL 正确
   ```

---

## 数据库问题

### 问题：数据库连接失败

**症状**：
```
Backend 日志：dial tcp postgres:5432: connect: connection refused
```

**解决方案**：

1. 检查 PostgreSQL 容器
   ```bash
   docker ps | grep postgres
   docker logs axongate-postgres
   ```

2. 检查健康状态
   ```bash
   docker inspect axongate-postgres | grep Health -A 10
   ```

3. 重启 PostgreSQL
   ```bash
   docker-compose restart postgres
   # 等待健康检查通过
   sleep 10
   docker-compose restart backend
   ```

---

### 问题：数据库迁移失败

**症状**：
```
Backend 启动时报错：migration failed
```

**解决方案**：

1. 手动运行迁移
   ```bash
   docker exec -it axongate-backend dbctl init \
     --config /app/config.yaml \
     --model /app/configs/rbac_model.conf
   ```

2. 检查迁移状态
   ```bash
   docker exec -it axongate-postgres psql -U postgres ai_proxy
   \dt
   # 查看表是否创建
   ```

---

## 性能问题

### 问题：响应缓慢

**症状**：API 响应时间超过 5 秒

**排查步骤**：

1. 检查资源使用
   ```bash
   docker stats
   # 查看 CPU 和内存使用
   ```

2. 检查数据库连接池
   ```bash
   docker exec -it axongate-postgres psql -U postgres ai_proxy \
     -c "SELECT count(*) FROM pg_stat_activity;"
   ```

3. 增加连接池大小
   ```yaml
   # /opt/axongate/config/backend.yaml
   db_max_connections: 50  # 从 25 增加到 50
   ```

---

### 问题：Engine 缓存未命中率高

**症状**：Backend API 调用频繁

**解决方案**：

1. 检查缓存配置
   ```bash
   cat /opt/axongate/config/engine.yaml | grep -A 3 cache
   ```

2. 增加缓存大小
   ```yaml
   cache:
     max_size: 50000  # 从 10000 增加
   ```

3. 重启 Engine
   ```bash
   docker-compose restart engine
   ```

---

## 日志问题

### 问题：日志文件过大

**症状**：/opt/axongate/logs/ 占用大量空间

**解决方案**：

1. 检查日志大小
   ```bash
   du -sh /opt/axongate/logs/*
   ```

2. 调整日志轮转配置
   ```yaml
   # /opt/axongate/config/backend.yaml
   log_max_size: 50        # 从 100MB 减少
   log_max_backups: 3      # 从 7 减少
   ```

3. 手动清理
   ```bash
   sudo rm /opt/axongate/logs/*.log.*
   ```

---

## 更新问题

### 问题：更新后服务无法启动

**症状**：
```
docker-compose up -d
ERROR: Service 'backend' failed to build
```

**解决方案**：

1. 清理旧镜像
   ```bash
   docker-compose down
   docker system prune -a
   ```

2. 重新构建
   ```bash
   docker-compose build --no-cache
   docker-compose up -d
   ```

3. 如果问题仍存在，回滚到旧版本
   ```bash
   git checkout previous_tag
   git submodule update
   docker-compose up -d
   ```

---

## 获取帮助

如果以上方案无法解决问题：

1. **收集信息**：
   ```bash
   # 保存所有日志
   docker-compose logs > /tmp/axongate-logs.txt
   
   # 保存系统信息
   docker version >> /tmp/axongate-logs.txt
   docker-compose version >> /tmp/axongate-logs.txt
   uname -a >> /tmp/axongate-logs.txt
   ```

2. **提交 Issue**：
   - https://github.com/sunSprout/axongate/issues
   - 附上日志文件和详细描述

3. **商业支持**：
   - Email: yinhui.zzy@gmail.com
   - 企业客户享有优先技术支持

---

**紧急支持**：yinhui.zzy@gmail.com
