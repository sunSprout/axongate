#!/bin/bash
# AxonGate 数据备份脚本
# 备份 PostgreSQL 数据库

set -e

# 配置
BACKUP_DIR="/opt/axongate/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="axongate_backup_${TIMESTAMP}.sql"
CONTAINER_NAME="axongate-postgres"

echo "========================================="
echo "  AxonGate 数据备份"
echo "========================================="
echo ""

# 检查是否有 sudo 权限（如果需要）
if [ ! -w "/opt/axongate" ]; then
    echo "错误：没有 /opt/axongate 写权限"
    echo "请使用 sudo 运行：sudo ./scripts/backup.sh"
    exit 1
fi

# 创建备份目录
mkdir -p "$BACKUP_DIR"

# 检查容器是否运行
if ! docker ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "❌ 错误：PostgreSQL 容器未运行"
    exit 1
fi

# 读取环境变量
if [ -f ".env" ]; then
    export $(grep -v '^#' .env | xargs)
fi

DB_NAME=${POSTGRES_DB:-ai_proxy}
DB_USER=${POSTGRES_USER:-postgres}

# 执行备份
echo "正在备份数据库 ${DB_NAME}..."
docker exec -t "$CONTAINER_NAME" pg_dump -U "$DB_USER" "$DB_NAME" > "${BACKUP_DIR}/${BACKUP_FILE}"

# 压缩备份文件
echo "正在压缩备份文件..."
gzip "${BACKUP_DIR}/${BACKUP_FILE}"

BACKUP_SIZE=$(du -h "${BACKUP_DIR}/${BACKUP_FILE}.gz" | cut -f1)

echo ""
echo "========================================="
echo "  备份完成！"
echo "========================================="
echo ""
echo "备份文件：${BACKUP_DIR}/${BACKUP_FILE}.gz"
echo "文件大小：${BACKUP_SIZE}"
echo ""

# 清理旧备份（保留最近 7 天）
echo "正在清理旧备份（保留最近 7 天）..."
find "$BACKUP_DIR" -name "axongate_backup_*.sql.gz" -mtime +7 -delete
echo "当前备份文件："
ls -lh "$BACKUP_DIR"

echo ""
echo "恢复备份命令："
echo "  gunzip -c ${BACKUP_DIR}/${BACKUP_FILE}.gz | docker exec -i ${CONTAINER_NAME} psql -U ${DB_USER} ${DB_NAME}"
echo ""
