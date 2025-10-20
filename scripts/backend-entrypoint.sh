#!/bin/sh
set -e

# 等待数据库就绪（固定容器内默认连接）
echo "Waiting for database (postgres:5432)..."
until pg_isready -h postgres -p 5432 -U postgres; do
    echo "Database is not ready, waiting..."
    sleep 2
done

echo "Database is ready!"

# 运行数据库迁移与种子（从配置文件读取数据库 DSN）
echo "Initializing database from /app/config.yaml..."
dbctl init \
    --config /app/config.yaml \
    --model /app/configs/rbac_model.conf

echo "Database initialization complete!"

# 启动服务
echo "Starting AI Proxy backend..."
exec aiproxy serve -c /app/config.yaml
