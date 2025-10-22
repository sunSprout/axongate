#!/bin/bash
# AxonGate 开源组件更新脚本
# 更新 Engine 和 UI 到最新版本

set -e

echo "========================================="
echo "  更新 AxonGate 开源组件"
echo "========================================="

# 获取项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# 更新 Engine
if [ -d "axongate-engine" ]; then
    echo "正在更新 axongate-engine..."
    cd axongate-engine
    git fetch origin
    git pull origin main
    echo "✓ Engine 更新完成: $(git log -1 --oneline)"
    cd ..
else
    echo "⚠️  axongate-engine 目录不存在，跳过"
fi

echo ""

# 更新 UI
if [ -d "axongate-ui" ]; then
    echo "正在更新 axongate-ui..."
    cd axongate-ui
    git fetch origin
    git pull origin main
    echo "✓ UI 更新完成: $(git log -1 --oneline)"
    cd ..
else
    echo "⚠️  axongate-ui 目录不存在，跳过"
fi

echo ""
echo "========================================="
echo "  更新完成！"
echo "========================================="
echo ""
echo "下一步："
echo "  1. 重新构建镜像：docker compose build axongate-engine axongate-frontend"
echo "  2. 重启服务：docker compose up -d"
echo ""
