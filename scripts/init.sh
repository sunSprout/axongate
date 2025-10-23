#!/bin/bash
# AxonGate 初始化脚本
# 创建 /opt/axongate/ 目录结构和配置文件

set -e

echo "========================================="
echo "  AxonGate 环境初始化"
echo "========================================="

# 检查是否有 sudo 权限
if [ "$EUID" -ne 0 ]; then
    echo "错误：此脚本需要 root 权限"
    echo "请使用 sudo 运行：sudo ./scripts/init.sh"
    exit 1
fi

# ========== 数据库配置变量 ==========
# 可以修改这些变量来自定义数据库配置
DB_NAME="axongate"
DB_USER="axongate"
DB_PASSWORD="axongate_password"
POSTGRES_PASSWORD="axongate_password"

echo "数据库配置："
echo "  数据库名: $DB_NAME"
echo "  用户名: $DB_USER"
echo "  密码: $DB_PASSWORD"
echo ""

# 检查并克隆开源组件（如果不存在）
echo "正在检查开源组件..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

if [ ! -d "$PROJECT_ROOT/axongate-engine" ] || [ -z "$(ls -A "$PROJECT_ROOT/axongate-engine")" ]; then
    echo "正在克隆 axongate-engine..."
    rm -rf "$PROJECT_ROOT/axongate-engine"
    git clone https://github.com/sunSprout/axongate-engine.git "$PROJECT_ROOT/axongate-engine"
else
    echo "✓ axongate-engine 已存在"
fi

if [ ! -d "$PROJECT_ROOT/axongate-ui" ] || [ -z "$(ls -A "$PROJECT_ROOT/axongate-ui")" ]; then
    echo "正在克隆 axongate-ui..."
    rm -rf "$PROJECT_ROOT/axongate-ui"
    git clone https://github.com/sunSprout/axongate-ui.git "$PROJECT_ROOT/axongate-ui"
else
    echo "✓ axongate-ui 已存在"
fi

# 创建目录结构
echo "正在创建目录结构..."
mkdir -p /opt/axongate/{data/{postgres,caddy_data,caddy_config},logs,config/certs}

# 生成 .env 文件（项目根目录）
echo "正在生成 .env 文件到项目根目录..."
cat > .env << EOF
# AxonGate 环境变量配置
# 由 init.sh 自动生成，请勿手动修改

# ============ 数据库配置 ============
# PostgreSQL 数据库密码
POSTGRES_PASSWORD=$POSTGRES_PASSWORD

# 数据库名称
POSTGRES_DB=$DB_NAME

# 数据库用户名
POSTGRES_USER=$DB_USER

# ============ Caddy 配置 ============
# ACME 证书邮箱（用于 Let's Encrypt）
ACME_EMAIL=admin@example.com

# 生产域名（用于 HTTPS 证书）
DOMAIN=ai.example.com

# ============ 端口配置（可选）============
# HTTP 端口（默认 80）
HTTP_PORT=80

# HTTPS 端口（默认 443）
HTTPS_PORT=443

# 调试端口（默认 8080，用于本地开发）
DEBUG_PORT=8080

# ============ 应用配置（可选）============
# 日志级别（debug | info | warn | error）
LOG_LEVEL=info
EOF

# 生成 backend.yaml 配置文件
echo "正在生成 backend.yaml 配置文件..."
cat > /opt/axongate/config/backend.yaml << EOF
# Backend config for Docker runtime
# 由 init.sh 自动生成，请勿手动修改

# API server (management API)
api_server_host: "0.0.0.0"
api_server_port: 8080

# Internal engine server exposed by Go backend
engine_server_host: "0.0.0.0"
engine_server_port: 8081

# PostgreSQL
db_host: "postgres"
db_port: 5432
db_user: "$DB_USER"
db_password: "$DB_PASSWORD"
db_name: "$DB_NAME"
db_max_connections: 25
db_max_idle_conns: 5

# Logging
log_level: "info"
log_dir: "/var/log/ai-gateway"
api_log_file: "api.log"
engine_log_file: "engine.log"
log_max_size: 100
log_max_backups: 7
log_max_age: 30
EOF

# 复制其他配置文件模板
echo "正在复制其他配置文件模板..."
if [ -f config/engine.yaml ]; then
    cp config/engine.yaml /opt/axongate/config/engine.yaml
else
    echo "警告：config/engine.yaml 不存在，跳过复制"
fi

if [ -f config/Caddyfile ]; then
    cp config/Caddyfile /opt/axongate/config/Caddyfile
else
    echo "警告：config/Caddyfile 不存在，跳过复制"
fi

# 复制证书文件（用于本地 HTTPS 测试）
echo "正在复制自签名证书..."
cp config/certs/* /opt/axongate/config/certs/

# 设置权限
echo "正在设置目录权限..."
chmod -R 755 /opt/axongate
chown -R "$(logname)":"$(logname)" /opt/axongate

echo ""
echo "========================================="
echo "  初始化完成！"
echo "========================================="
echo ""
echo "生成的配置文件："
echo "  ./.env                           - Docker Compose 环境变量"
echo "  /opt/axongate/config/backend.yaml - 后端配置文件"
echo "  /opt/axongate/config/engine.yaml  - 引擎配置文件"
echo ""
echo "数据库配置："
echo "  数据库名: $DB_NAME"
echo "  用户名: $DB_USER"
echo "  密码: $DB_PASSWORD"
echo ""
echo "下一步："
echo "  1. 启动服务：docker-compose up -d"
echo "  2. 查看日志：docker-compose logs -f axongate-server"
echo "  3. 如需修改密码，请编辑脚本顶部的变量并重新运行 init.sh"
echo ""
