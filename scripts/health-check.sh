#!/bin/bash
# AxonGate 服务健康检查脚本
# 检查所有服务的运行状态和健康状态

set -e

echo "========================================="
echo "  AxonGate 服务健康检查"
echo "========================================="
echo ""

# 检查 Docker 和 Docker Compose
if ! command -v docker &> /dev/null; then
    echo "❌ 错误：Docker 未安装"
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ 错误：Docker Compose 未安装"
    exit 1
fi

# 定义服务列表
SERVICES=("axongate-postgres" "axongate-server" "axongate-engine" "axongate-frontend")
HEALTH_URLS=(
    "postgres:5432 (TCP)"
    "http://localhost:8080/health"
    "http://localhost:8090/health"
    "http://localhost:8080/health"
)

# 检查容器状态
echo "📦 容器状态："
echo "----------------------------------------"
for service in "${SERVICES[@]}"; do
    if docker ps --format "{{.Names}}" | grep -q "^${service}$"; then
        status=$(docker inspect --format='{{.State.Status}}' "$service")
        health=$(docker inspect --format='{{.State.Health.Status}}' "$service" 2>/dev/null || echo "none")

        if [ "$status" == "running" ]; then
            if [ "$health" == "healthy" ] || [ "$health" == "none" ]; then
                echo "✅ $service: 运行中 (健康)"
            else
                echo "⚠️  $service: 运行中 (健康检查: $health)"
            fi
        else
            echo "❌ $service: $status"
        fi
    else
        echo "❌ $service: 未运行"
    fi
done

echo ""
echo "🌐 服务可访问性："
echo "----------------------------------------"

# 检查 PostgreSQL
if nc -z localhost 5432 2>/dev/null; then
    echo "✅ PostgreSQL (5432): 可连接"
else
    echo "❌ PostgreSQL (5432): 不可连接"
fi

# 检查 Backend API
if curl -sf http://localhost:8080/health > /dev/null 2>&1; then
    echo "✅ Backend API (8080): 健康"
else
    echo "❌ Backend API (8080): 不可访问"
fi

# 检查 Engine API (注意：engine 不对外暴露，通过 backend 访问)
if docker exec axongate-engine wget -q -O- http://127.0.0.1:8090/health > /dev/null 2>&1; then
    echo "✅ Engine API (8090): 健康"
else
    echo "❌ Engine API (8090): 不可访问"
fi

# 检查前端
if curl -sf http://localhost:8080 > /dev/null 2>&1; then
    echo "✅ 前端 (8080): 可访问"
else
    echo "❌ 前端 (8080): 不可访问"
fi

echo ""
echo "📊 资源使用："
echo "----------------------------------------"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" $(docker ps -q --filter "name=axongate")

echo ""
echo "========================================="
echo "  检查完成"
echo "========================================="
