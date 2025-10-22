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

# 复制配置文件模板
echo "正在复制配置文件模板..."
cp config/backend.yaml /opt/axongate/config/backend.yaml
cp config/engine.yaml /opt/axongate/config/engine.yaml
cp config/Caddyfile /opt/axongate/config/Caddyfile

# 复制证书文件（用于本地 HTTPS 测试）
echo "正在复制自签名证书..."
cp config/certs/* /opt/axongate/config/certs/

# 设置权限
echo "正在设置目录权限..."
chmod -R 755 /opt/axongate
chown -R $(logname):$(logname) /opt/axongate

echo ""
echo "========================================="
echo "  初始化完成！"
echo "========================================="
echo ""
echo "目录结构："
tree -L 2 /opt/axongate || ls -la /opt/axongate
echo ""
echo "下一步："
echo "  1. 复制 .env.example 为 .env 并配置环境变量"
echo "  2. 编辑 /opt/axongate/config/*.yaml 调整配置（可选）"
echo "  3. 运行 docker-compose up -d 启动服务"
echo ""
