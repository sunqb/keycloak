# Keycloak 自定义主题 Docker 构建指南

## 🚀 快速开始

### 🎯 建议选择

- **同事/新环境** → 使用 `Dockerfile`（完整构建）
- **您的开发环境** → 使用 `Dockerfile.custom`（快速构建）

### 方法1：完整构建（推荐给同事）
适用于任何环境，不依赖本地Java版本：

```bash
# 构建镜像
docker build -t keycloak-custom .

# 启动容器
docker run -p 8080:8080 \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=admin \
  keycloak-custom start-dev
```

### 方法2：快速构建（推荐开发环境）
如果您本地有Java 21环境，推荐使用这个经过验证的流程：

```bash
# 1. 临时切换到JDK21环境
export JAVA_HOME=/Volumes/samsungssd/soft/jdk-21.0.8.jdk/Contents/Home
export PATH=$JAVA_HOME/bin:$PATH

# 2. 预构建vendor文件（会跳过proto编译）
mvn clean install -Dproto.skip=true -DskipTests

# 3. 快速构建镜像
docker build -f Dockerfile.custom -t keycloak-custom .

# 4. 启动容器
docker run -p 8080:8080 \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=admin \
  keycloak-custom start-dev
```

> ⚠️ **重要说明**：Maven构建可能会在最后阶段报错，但这不影响js/themes-vendor的构建。只要`js/themes-vendor/target/classes/theme/`目录存在vendor文件即可。

## 📁 文件说明

### Docker构建文件

- **`Dockerfile`** - **完整自动构建版本（推荐给同事使用）**
  - ✅ 自动构建js模块生成vendor文件
  - ✅ 使用阿里云Maven镜像加速下载
  - ✅ **不依赖本地Java环境**
  - ✅ 一条命令完成所有构建：`docker build -t keycloak-custom .`
  - ⏱️ 首次构建时间较长（需下载依赖）
  - 🎯 **适用场景：同事的机器、CI/CD环境**

- **`Dockerfile.custom`** - **快速构建版本（推荐开发环境）**
  - ⚠️ 需要预先构建js/themes-vendor/target目录
  - ⚡ 构建速度更快（跳过Maven构建）
  - 🛠️ 适合开发时频繁重建
  - 📋 **使用步骤（经过验证的流程）：**
    ```bash
    # 1. 临时切换到JDK21
    export JAVA_HOME=/path/to/jdk-21
    export PATH=$JAVA_HOME/bin:$PATH
    
    # 2. 预构建vendor文件
    mvn clean install -Dproto.skip=true -DskipTests
    
    # 3. Docker构建
    docker build -f Dockerfile.custom -t keycloak-custom .
    ```
  - 🎯 **适用场景：开发环境，修改theme文件后快速重建**
  - ✅ **包含完整vendor文件，不会有JS 404错误**

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