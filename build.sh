#!/bin/bash

# 通用多平台构建脚本
# 自动检测目标平台并构建对应架构的镜像

set -e

# 配置
LOCAL_IMAGE="keycloak-custom"
DOCKERFILE="Dockerfile.multi"

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

show_help() {
    cat << EOF
通用多平台Docker构建脚本

用法:
  ./build-universal.sh [选项]

选项:
  --platform PLATFORM    指定目标平台 (linux/amd64, linux/arm64)
  --tag TAG               指定镜像标签 (默认: latest)
  --auto                  自动检测服务器常用平台 (linux/amd64)
  -h, --help              显示此帮助信息

示例:
  ./build-universal.sh                    # 使用当前平台
  ./build-universal.sh --auto             # 自动使用AMD64（服务器常用）
  ./build-universal.sh --platform linux/arm64
  ./build-universal.sh --platform linux/amd64 --tag v1.0

EOF
}

# 检查vendor文件
check_vendor_files() {
    if [[ ! -d "js/themes-vendor/target/classes/theme/" ]]; then
        print_error "vendor文件不存在，需要先运行Maven构建"
        echo ""
        print_info "请执行以下命令："
        echo "export JAVA_HOME=/Volumes/samsungssd/soft/jdk-21.0.8.jdk/Contents/Home"
        echo "export PATH=\$JAVA_HOME/bin:\$PATH"
        echo "mvn clean install -Dproto.skip=true -DskipTests"
        exit 1
    fi
    print_success "vendor文件检查通过"
}

# 主函数
main() {
    PLATFORM=""
    TAG="latest"
    AUTO_DETECT=false
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --platform)
                PLATFORM="$2"
                shift 2
                ;;
            --tag)
                TAG="$2"
                shift 2
                ;;
            --auto)
                AUTO_DETECT=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                print_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 自动检测平台
    if [[ "$AUTO_DETECT" == "true" ]]; then
        PLATFORM="linux/amd64"
        print_info "自动模式：使用服务器常用平台 linux/amd64"
    fi
    
    print_info "开始通用多平台Keycloak镜像构建..."
    
    # 检查vendor文件
    check_vendor_files
    
    # 构建命令
    BUILD_CMD="docker build -f $DOCKERFILE -t $LOCAL_IMAGE:$TAG"
    
    if [[ -n "$PLATFORM" ]]; then
        BUILD_CMD="$BUILD_CMD --platform $PLATFORM"
        print_info "目标平台: $PLATFORM"
    else
        print_info "使用当前主机平台"
    fi
    
    print_info "镜像标签: $TAG"
    print_info "执行构建命令: $BUILD_CMD ."
    
    if $BUILD_CMD .; then
        print_success "镜像构建成功！"
        
        # 显示镜像信息
        print_info "镜像信息："
        docker images | head -1
        docker images | grep "$LOCAL_IMAGE.*$TAG"
        
        # 检查实际架构
        ACTUAL_ARCH=$(docker inspect "$LOCAL_IMAGE:$TAG" | grep '"Architecture"' | cut -d'"' -f4)
        print_info "实际架构: $ACTUAL_ARCH"
        
        print_success "构建完成！🚀"
        echo ""
        print_info "推送到Docker Hub："
        echo "  ./push-image.sh -t $TAG your-username"
        
        if [[ "$ACTUAL_ARCH" == "amd64" ]]; then
            print_success "此镜像可在x86_64/AMD64服务器正常运行"
        elif [[ "$ACTUAL_ARCH" == "arm64" ]]; then
            print_warning "此镜像仅可在ARM64环境运行"
        fi
    else
        print_error "构建失败"
        exit 1
    fi
}

# 运行主函数
main "$@"