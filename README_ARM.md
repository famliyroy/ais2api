# ais2api ARM 服务器适配说明

## 项目简介

ais2api 是一个将 Google AI Studio 的 Gemini 模型转换为 OpenAI 兼容 API 的代理服务。本项目 Fork 自 [Ellinav/ais2api](https://github.com/Ellinav/ais2api)，添加了 ARM64 架构服务器支持。

## 主要改动

### 1. 多架构 Dockerfile
- 根据 `TARGETARCH` 自动下载对应架构的 Camoufox 浏览器
- amd64 → 下载 `camoufox-*-lin.x86_64.zip`
- arm64 → 下载 `camoufox-*-lin.arm64.zip`
- 自动创建 `camoufox-bin` → `camoufox` 软链接，兼容原项目代码

### 2. 多架构 CI/CD
- 使用 QEMU + Docker Buildx 支持 `linux/amd64` 和 `linux/arm64` 双平台构建
- 自动获取 Camoufox 最新版本号
- 推送到 Docker Hub

### 3. 代码健壮性改进
- `unified-server.js` 支持自动检测 `camoufox` 和 `camoufox-bin` 两种可执行文件名

### 4. 部署便利性
- 提供 `docker-compose.yml` 一键部署
- 包含健康检查配置
- 包含资源限制配置

## ARM 服务器部署

### 方式一：Docker Hub 拉取（推荐）

```bash
# 拉取镜像（自动匹配 ARM64）
docker pull famliyroy/ais2api:latest

# 运行容器
docker run -d \
  --name ais2api \
  --restart unless-stopped \
  -p 7860:7860 \
  -p 9998:9998 \
  -v $(pwd)/auth:/app/auth:ro \
  -e INITIAL_AUTH_INDEX=1 \
  famliyroy/ais2api:latest
```

### 方式二：Docker Compose 部署

```bash
# 1. 创建 auth 目录并放入认证文件
mkdir -p auth
# 将 Google AI Studio 的认证文件放入 auth/ 目录 (auth-1.json, auth-2.json, ...)

# 2. 使用 docker-compose 启动
docker compose up -d
```

### 方式三：本地构建

```bash
# 克隆仓库
git clone https://github.com/famliyroy/ais2api.git
cd ais2api

# 构建 ARM64 镜像
docker build --platform linux/arm64 -t ais2api:arm64 .

# 运行
docker run -d \
  --name ais2api \
  -p 7860:7860 \
  -p 9998:9998 \
  -v $(pwd)/auth:/app/auth:ro \
  ais2api:arm64
```

## 认证文件获取

认证文件需要通过 `save-auth.js` 脚本获取：

```bash
# 安装依赖
npm install

# 运行认证脚本（需要本地有 Camoufox 浏览器）
node save-auth.js
# 按照提示在浏览器中登录 Google 账户
# 认证文件会自动保存到 auth/ 目录
```

也可以使用环境变量方式（适合容器部署）：

```bash
docker run -d \
  --name ais2api \
  -p 7860:7860 \
  -p 9998:9998 \
  -e "AUTH_JSON_1=$(cat auth/auth-1.json)" \
  famliyroy/ais2api:latest
```

## 支持的模型

- gemini-3-pro-preview
- gemini-2.5-flash-image-preview
- gemini-2.5-pro
- gemini-2.5-flash
- gemini-2.5-flash-lite
- gemini-2.0-flash
- gemini-2.0-flash-lite
- learnlm-2.0-flash-experimental

## API 端口

| 端口 | 用途 |
|------|------|
| 7860 | API 服务 (OpenAI 兼容格式) |
| 9998 | WebSocket (浏览器代理通信) |

## 系统要求

- ARM64 (aarch64) 或 AMD64 (x86_64) 架构
- Docker 20.10+
- 至少 512MB 可用内存（推荐 2GB）
- 网络可访问 Google 服务
