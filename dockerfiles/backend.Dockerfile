# AxonGate Backend Dockerfile
# 使用预编译二进制的轻量级镜像

FROM alpine:3.19

# 替换为阿里云镜像源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# 安装运行时依赖
RUN apk add --no-cache ca-certificates postgresql-client

WORKDIR /app

# 复制预编译二进制（静态链接）
COPY bin/axongate-server /usr/local/bin/axongate-server
COPY bin/dbctl /usr/local/bin/dbctl
RUN chmod +x /usr/local/bin/axongate-server /usr/local/bin/dbctl

# 复制配置文件和迁移文件
COPY config/backend.yaml /app/config.yaml
COPY configs/rbac_model.conf /app/configs/rbac_model.conf
COPY migrations /app/migrations
COPY scripts/backend-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# API 服务端口
EXPOSE 8080
# Engine 内部服务端口
EXPOSE 8081

ENTRYPOINT ["/entrypoint.sh"]
CMD ["axongate-server"]
