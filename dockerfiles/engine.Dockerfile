# AxonGate Engine Dockerfile
# 多阶段构建：从 axongate-engine submodule 编译 Rust 项目

# ============ 构建阶段 ============
FROM rust:1.83-alpine AS builder

# 替换为阿里云镜像源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# 安装构建依赖
RUN apk add --no-cache musl-dev openssl-dev openssl-libs-static pkgconfig

WORKDIR /app

# 配置 Rust cargo 镜像源（优化中国区下载速度）
RUN mkdir -p /usr/local/cargo && \
    cat > /usr/local/cargo/config.toml <<'EOF'
[source.crates-io]
replace-with = 'rsproxy-sparse'
[source.rsproxy]
registry = "https://rsproxy.cn/crates.io-index"
[source.rsproxy-sparse]
registry = "sparse+https://rsproxy.cn/index/"
[registries.rsproxy]
index = "https://rsproxy.cn/crates.io-index"
[net]
git-fetch-with-cli = true
EOF

# 复制 Cargo 文件并预构建依赖（利用 Docker 缓存）
COPY axongate-engine/Cargo.toml axongate-engine/Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release && rm -rf src

# 复制源码并构建
COPY axongate-engine/src ./src
RUN touch src/main.rs && cargo build --release

# ============ 运行阶段 ============
FROM alpine:3.19

# 替换为阿里云镜像源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# 安装运行时依赖
RUN apk add --no-cache ca-certificates libgcc

WORKDIR /app

# 复制二进制文件
COPY --from=builder /app/target/release/axongate-engine /usr/local/bin/axongate-engine
RUN chmod +x /usr/local/bin/axongate-engine

# 复制配置文件
COPY config/engine.yaml /app/config.yaml

# 服务端口
EXPOSE 8090

CMD ["axongate-engine", "-c", "/app/config.yaml"]
