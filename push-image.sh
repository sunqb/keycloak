#!/bin/bash

# Keycloak Custom Docker镜像推送脚本
# 用途：将本地构建的keycloak-custom镜像推送到Docker Hub

set -e  # 遇到错误立即退出

# 配置变量
LOCAL_IMAGE="keycloak-custom"
DEFAULT_USERNAME=""
DEFAULT_TAG="latest"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示帮助信息
show_help() {
    cat << EOF
Keycloak Custom Docker镜像推送脚本

用法:
  ./push-image.sh [选项] <docker-hub-username>

参数:
  <docker-hub-username>    您的Docker Hub用户名

选项:
  -t, --tag TAG           指定镜像标签 (默认: latest)
  -i, --image IMAGE       指定本地镜像名称 (默认: keycloak-custom)
  -h, --help              显示此帮助信息
  --dry-run               模拟运行，只显示将要执行的命令

示例:
  ./push-image.sh your-username
  ./push-image.sh -t v1.0 your-username  
  ./push-image.sh --tag v1.0 your-username
  ./push-image.sh --dry-run your-username

EOF
}

# 检查Docker是否运行
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker未运行或无权限访问。请确保Docker正在运行。"
        exit 1
    fi
}

# 检查本地镜像是否存在
check_local_image() {
    if ! docker image inspect "$1" >/dev/null 2>&1; then
        print_error "本地镜像 '$1' 不存在。"
        print_info "请先构建镜像："
        echo "  docker build -f Dockerfile.custom -t $1 ."
        exit 1
    fi
    print_success "找到本地镜像: $1"
}

# 检查是否已登录Docker Hub
check_docker_login() {
    if ! docker info | grep -q "Username:"; then
        print_warning "尚未登录Docker Hub"
        print_info "正在登录Docker Hub..."
        if ! docker login; then
            print_error "Docker Hub登录失败"
            exit 1
        fi
    else
        print_success "Docker Hub已登录"
    fi
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--tag)
                TAG="$2"
                shift 2
                ;;
            -i|--image)
                LOCAL_IMAGE="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -*)
                print_error "未知选项: $1"
                show_help
                exit 1
                ;;
            *)
                if [[ -z "$USERNAME" ]]; then
                    USERNAME="$1"
                else
                    print_error "多余的参数: $1"
                    show_help
                    exit 1
                fi
                shift
                ;;
        esac
    done
}

# 主函数
main() {
    # 默认值
    TAG="$DEFAULT_TAG"
    DRY_RUN=false
    
    print_info "开始Keycloak Custom镜像推送流程..."
    
    # 解析参数
    parse_args "$@"
    
    # 检查必需参数
    if [[ -z "$USERNAME" ]]; then
        print_error "缺少Docker Hub用户名参数"
        show_help
        exit 1
    fi
    
    # 构建远程镜像名称
    REMOTE_IMAGE="$USERNAME/$LOCAL_IMAGE:$TAG"
    
    print_info "配置信息:"
    echo "  本地镜像: $LOCAL_IMAGE"
    echo "  远程镜像: $REMOTE_IMAGE"
    echo "  Docker Hub用户: $USERNAME"
    echo "  镜像标签: $TAG"
    echo ""
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_warning "模拟运行模式 - 不会实际执行推送"
        echo ""
        echo "将要执行的命令:"
        echo "  docker tag $LOCAL_IMAGE $REMOTE_IMAGE"
        echo "  docker push $REMOTE_IMAGE"
        exit 0
    fi
    
    # 执行检查
    check_docker
    check_local_image "$LOCAL_IMAGE"
    check_docker_login
    
    print_info "开始标记镜像..."
    if docker tag "$LOCAL_IMAGE" "$REMOTE_IMAGE"; then
        print_success "镜像标记成功: $REMOTE_IMAGE"
    else
        print_error "镜像标记失败"
        exit 1
    fi
    
    print_info "开始推送镜像到Docker Hub..."
    print_warning "这可能需要几分钟时间，请耐心等待..."
    
    if docker push "$REMOTE_IMAGE"; then
        print_success "镜像推送成功！"
        echo ""
        print_info "其他人可以通过以下命令获取您的镜像:"
        echo "  docker pull $REMOTE_IMAGE"
        echo ""
        print_info "启动命令:"
        echo "  docker run -p 8080:8080 \\"
        echo "    -e KEYCLOAK_ADMIN=admin \\"
        echo "    -e KEYCLOAK_ADMIN_PASSWORD=admin \\"
        echo "    $REMOTE_IMAGE start-dev"
        echo ""
        print_success "镜像分发完成！🚀"
    else
        print_error "镜像推送失败"
        exit 1
    fi
}

# 运行主函数
main "$@"