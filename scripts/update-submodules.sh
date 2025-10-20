#!/bin/bash
# AxonGate 开源组件更新脚本
# 更新 Engine 和 UI 的 Git Submodules

set -e

echo "========================================="
echo "  更新 AxonGate 开源组件"
echo "========================================="

# 检查是否在 git 仓库中
if [ ! -d ".git" ] && [ ! -f "../.git" ]; then
    echo "错误：请在 AxonGate 仓库根目录运行此脚本"
    exit 1
fi

# 更新 Submodules
echo "正在更新 Git Submodules..."
git submodule update --remote --merge

echo ""
echo "========================================="
echo "  更新完成！"
echo "========================================="
echo ""
echo "变更摘要："
cd axongate-engine && echo "Engine:" && git log -1 --oneline && cd ..
cd axongate-ui && echo "UI:" && git log -1 --oneline && cd ..
echo ""
echo "下一步："
echo "  1. 审查变更：git diff"
echo "  2. 重新构建镜像：docker-compose build engine caddy"
echo "  3. 重启服务：docker-compose up -d"
echo ""
