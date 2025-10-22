# AxonGate Caddy Dockerfile
# 多阶段构建：前端构建 + Caddy 反向代理

# ============ 阶段1: 构建前端 ============
FROM node:20-alpine AS frontend-builder

WORKDIR /app

# 复制 package 文件并安装依赖
COPY axongate-ui/package*.json ./
RUN npm ci --no-audit --no-fund

# 复制源码并构建
COPY axongate-ui/ .
ENV VITE_API_BASE_URL=/api/v1
RUN npm run build

# ============ 阶段2: Caddy 运行环境 ============
FROM caddy:2.7-alpine

WORKDIR /srv

# 健康检查所需工具
RUN apk add --no-cache wget

# 复制前端构建产物
COPY --from=frontend-builder /app/dist /srv

# 复制 Caddy 配置文件
COPY config/Caddyfile /etc/caddy/Caddyfile

# 暴露端口
EXPOSE 80 443 8080

# Caddy 会自动使用 /etc/caddy/Caddyfile
