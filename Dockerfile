# Dockerfile (多架构支持版 - amd64 + arm64)
FROM node:18-slim AS base

WORKDIR /app

# 1. 安装系统依赖 (amd64 和 arm64 通用)
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    unzip \
    libasound2 libatk-bridge2.0-0 libatk1.0-0 libatspi2.0-0 libcups2 \
    libdbus-1-3 libdrm2 libgbm1 libgtk-3-0 libnspr4 libnss3 libx11-6 \
    libx11-xcb1 libxcb1 libxcomposite1 libxdamage1 libxext6 libxfixes3 \
    libxrandr2 libxss1 libxtst6 xvfb \
    && rm -rf /var/lib/apt/lists/*

# 2. 拷贝 package.json 并安装依赖
COPY package*.json ./
RUN npm install --production

# 3. 根据 CPU 架构下载对应的 Camoufox 浏览器
# 使用 TARGETARCH 自动区分 amd64/arm64
ARG TARGETARCH
ENV CAMOUFOX_VERSION=v152.0.4-beta.28

# 获取最新版本号并下载对应架构的 Camoufox
RUN if [ "$TARGETARCH" = "arm64" ] || [ "$TARGETARCH" = "aarch64" ]; then \
        echo "📦 下载 Camoufox ARM64 版本..." && \
        wget -q "https://github.com/daijro/camoufox/releases/download/${CAMOUFOX_VERSION}/camoufox-152.0.4-beta.28-lin.arm64.zip" -O camoufox.zip; \
    else \
        echo "📦 下载 Camoufox x86_64 版本..." && \
        wget -q "https://github.com/daijro/camoufox/releases/download/${CAMOUFOX_VERSION}/camoufox-152.0.4-beta.28-lin.x86_64.zip" -O camoufox.zip; \
    fi && \
    unzip -q camoufox.zip -d /app/camoufox-linux && \
    rm camoufox.zip && \
    chmod +x /app/camoufox-linux/camoufox-bin 2>/dev/null || true && \
    # 创建 camoufox 软链接 (兼容原项目代码中使用的 camoufox 命令)
    if [ -f /app/camoufox-linux/camoufox-bin ] && [ ! -f /app/camoufox-linux/camoufox ]; then \
        ln -s /app/camoufox-linux/camoufox-bin /app/camoufox-linux/camoufox; \
    fi && \
    chmod +x /app/camoufox-linux/camoufox

# 4. 拷贝项目代码文件
COPY unified-server.js black-browser.js models.json ./

# 5. 创建目录并设置权限
RUN mkdir -p ./auth ./single-line-auth && chown -R node:node /app

# 切换到非 root 用户
USER node

# 暴露服务端口
EXPOSE 7860
EXPOSE 9998

# 设置环境变量
ENV CAMOUFOX_EXECUTABLE_PATH=/app/camoufox-linux/camoufox
ENV NODE_ENV=production

# 定义容器启动命令
CMD ["node", "unified-server.js"]
