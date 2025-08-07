# Keycloak 自定义主题 Docker 构建指南

## 🚀 快速开始

### 🎯 推荐构建方式

使用通用多平台构建脚本，一键解决所有平台兼容性问题：

```bash
# 1. 临时切换到JDK21环境（预构建vendor文件）
export JAVA_HOME=/Volumes/samsungssd/soft/jdk-21.0.8.jdk/Contents/Home
export PATH=$JAVA_HOME/bin:$PATH

# 2. 预构建vendor文件（会跳过proto编译，这一步报错也不影响，js 文件生成即可）
mvn clean install -Dproto.skip=true -DskipTests

# 3. 智能构建镜像
./build.sh --auto              # 自动构建AMD64版本（服务器通用）
# 或
./build.sh --platform linux/arm64    # 指定ARM64平台（Mac本地）
# 或  
./build.sh                     # 使用当前平台

# 4. 启动容器
docker run -p 8080:8080 \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=admin \
  keycloak-custom:latest start-dev
```

### 📋 构建选项说明

**`build.sh`** 支持以下选项：
- `--auto` - 自动构建AMD64版本（推荐，服务器通用）
- `--platform linux/amd64` - 明确指定AMD64平台
- `--platform linux/arm64` - 明确指定ARM64平台
- `--tag v1.0` - 自定义镜像标签
- `--help` - 显示完整帮助信息

## 📁 构建文件说明

### 核心文件

- **`Dockerfile.multi`** - **通用多平台Dockerfile（推荐）**
  - ✅ 单文件支持ARM64和AMD64
  - ✅ 自动平台检测和适配
  - ✅ 使用ARG实现平台灵活性

- **`build.sh`** - **智能构建脚本（推荐）**
  - ✅ 自动检测vendor文件
  - ✅ 智能平台选择
  - ✅ 完整的错误处理和提示
  - ✅ 彩色输出和构建信息

- **`push-image.sh`** - **镜像推送脚本**
  - ✅ 支持多平台推送
  - ✅ 自动Docker Hub登录
  - ✅ 模拟运行模式

### 传统构建文件（向下兼容）

- **`Dockerfile`** - 完整构建版本（包含Maven构建）
- **`Dockerfile.custom`** - 快速构建版本（需预构建vendor文件）

## 🔧 镜像推送到Docker Hub

```bash
# 推送镜像到Docker Hub
./push-image.sh your-dockerhub-username

# 指定标签和平台
./push-image.sh -t v1.0 -p linux/amd64 your-username
```

## 🎯 完整工作流程（从零开始）

### 第一次使用完整流程

```bash
# 1. 确保环境准备
# 检查Docker是否运行
docker --version

# 检查JDK21路径（根据实际路径调整）
ls /Volumes/samsungssd/soft/jdk-21.0.8.jdk/Contents/Home

# 2. 设置Java环境
export JAVA_HOME=/Volumes/samsungssd/soft/jdk-21.0.8.jdk/Contents/Home
export PATH=$JAVA_HOME/bin:$PATH
java -version  # 验证版本为21.x

# 3. 预构建vendor文件（必须步骤）
mvn clean install -Dproto.skip=true -DskipTests
# ⚠️ 这一步可能在最后proto阶段报错，但不影响vendor文件生成
# ✅ 只要看到 js/themes-vendor/target/classes/theme/ 有文件即可

# 4. 构建服务器兼容镜像
./build.sh --auto
# ✅ 构建成功后会显示镜像信息和架构（应为amd64）

# 5. 推送到Docker Hub（可选）
./push-image.sh your-dockerhub-username
# 💡 首次会提示登录Docker Hub

# 6. 启动测试（可选）
docker run -p 8080:8080 \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=admin \
  keycloak-custom:latest start-dev
```

### 日常开发流程（修改theme后）

```bash
# 1. 快速重建（vendor文件已存在）
./build.sh --auto

# 2. 推送更新（如需要）
./push-image.sh your-dockerhub-username
```

### 为不同平台构建

```bash
# Mac本地使用（ARM64）
./build.sh --platform linux/arm64

# 服务器使用（AMD64，推荐）
./build.sh --auto
# 等价于
./build.sh --platform linux/amd64

# 查看构建选项
./build.sh --help
```

## ⚠️ 重要提醒

### 必须先执行的步骤

1. **JDK21环境设置**：
   ```bash
   export JAVA_HOME=/Volumes/samsungssd/soft/jdk-21.0.8.jdk/Contents/Home
   export PATH=$JAVA_HOME/bin:$PATH
   ```

2. **Maven构建vendor文件**：
   ```bash
   mvn clean install -Dproto.skip=true -DskipTests
   ```
   - ✅ 成功标志：`js/themes-vendor/target/classes/theme/` 目录存在并包含React相关JS文件
   - ⚠️ proto阶段可能超时报错，但不影响vendor文件生成

3. **平台选择**：
   - 服务器部署：**必须使用** `./build.sh --auto` 构建AMD64版本
   - Mac本地测试：可以使用 `./build.sh` 构建ARM64版本

### 常见错误和解决方案

1. **"exec format error"**：
   - 原因：在AMD64服务器运行了ARM64镜像
   - 解决：重新用 `./build.sh --auto` 构建AMD64版本

2. **"vendor文件不存在"**：
   - 原因：没有运行Maven构建
   - 解决：执行 `mvn clean install -Dproto.skip=true -DskipTests`

3. **"Java版本错误"**：
   - 原因：没有切换到JDK21
   - 解决：重新设置JAVA_HOME环境变量

4. **"Maven构建失败"**：
   - 如果是proto阶段超时：可以忽略，继续Docker构建
   - 如果是编译错误：检查JDK版本是否为21

## 📝 文件用途快速参考

| 文件 | 用途 | 何时使用 |
|------|------|----------|
| `build.sh` | 智能构建脚本 | ⭐ **主要使用** - 构建任何平台镜像 |
| `push-image.sh` | 推送镜像到Hub | 需要分享镜像时 |
| `Dockerfile.multi` | 多平台Dockerfile | build.sh自动调用 |
| `Dockerfile` | 传统完整构建 | 特殊场景或老版本兼容 |
| `Dockerfile.custom` | 传统快速构建 | 特殊场景或老版本兼容 |

### 配置文件

- **`settings-china.xml`** - Maven配置文件
  - 使用阿里云镜像加速依赖下载
  - 配置JBoss仓库

- **`.dockerignore`** - 优化构建上下文
  - 排除不必要的文件减少构建时间

## 🔧 故障排除

### 常见问题

1. **Maven依赖下载失败**
   ```
   Solution: 使用完整构建的Dockerfile，已配置阿里云镜像
   ```

2. **js文件夹不存在**
   ```
   Solution: js文件夹是Maven构建生成的，使用完整构建版本
   ```

3. **vendor文件缺失导致JS错误**
   ```
   Solution: 确保使用正确的Dockerfile，会自动生成vendor文件
   ```

### 网络问题

对于特殊网络环境，可以修改`settings-china.xml`中的镜像地址：

```xml
<mirror>
  <id>custom-mirror</id>
  <mirrorOf>*</mirrorOf>
  <name>自定义镜像</name>
  <url>https://your-maven-mirror.com/repository/public</url>
</mirror>
```

## 🎯 访问应用

启动成功后访问：
- **主页**: http://localhost:8080
- **管理控制台**: http://localhost:8080/admin
- **账户控制台**: http://localhost:8080/realms/master/account

默认管理员账号：
- 用户名: `admin`
- 密码: `admin`

## 📦 构建产物

- **镜像大小**: 约655MB
- **包含组件**:
  - Keycloak 最新版
  - 自定义主题 keycloak.v2
  - React/PatternFly vendor文件
  - 优化后的配置

## 🔄 更新主题

修改主题文件后，重新构建镜像：

```bash
docker build -t keycloak-custom .
```

主题文件位置：
- `themes/src/main/resources/theme/keycloak.v2/`
- `themes/src/main/resources-community/theme/`