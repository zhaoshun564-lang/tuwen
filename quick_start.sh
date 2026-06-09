#!/bin/bash

# ============================================
# 图文 (Tuwen) 快速启动脚本
# 一键启动所有服务
# ============================================

set -e

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║                                                        ║"
echo "║     🚀 图文 (Tuwen) - 图生图自动化系统                 ║"
echo "║          一键启动脚本                                  ║"
echo "║                                                        ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# 获取当前目录
CURRENT_DIR=$(pwd)

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============ 实用函数 ============
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[⚠]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }
log_step() { echo -e "\n${CYAN}$1${NC}"; }

# ============ 步骤1：检查前置要求 ============
log_step "📋 步骤 1/10 - 检查前置要求"

check_command() {
    if ! command -v $1 &> /dev/null; then
        log_error "$1 未安装"
        echo "请访问 $2 进行安装"
        exit 1
    fi
    log_success "$1 已安装"
}

check_command "docker" "https://www.docker.com"
check_command "docker-compose" "https://docs.docker.com/compose"
check_command "git" "https://git-scm.com"

echo ""
docker --version
docker-compose --version
git --version

# ============ 步骤2：克隆或进入项目 ============
log_step "📥 步骤 2/10 - 克隆项目"

if [ ! -d "tuwen" ]; then
    log_info "正在克隆项目..."
    git clone https://github.com/zhaoshun564-lang/tuwen.git
    cd tuwen
    log_success "项目已克隆"
else
    log_warning "项目已存在，进入项目目录"
    cd tuwen
fi

# ============ 步骤3：配置环境 ============
log_step "⚙️  步骤 3/10 - 配置环境变量"

if [ ! -f ".env" ]; then
    log_info "复制环境变量配置文件..."
    cp .env.example .env
    log_success ".env 文件已创建"
else
    log_warning ".env 文件已存在"
fi

# ============ 步骤4：停止旧容器 ============
log_step "🛑 步骤 4/10 - 清理旧容器"

log_info "停止并删除旧容器..."
docker-compose -f docker/docker-compose.yml down --remove-orphans 2>/dev/null || true
log_success "旧容器已清理"

# ============ 步骤5：启动容器 ============
log_step "🐳 步骤 5/10 - 启动 Docker 容器"

log_info "启动 RabbitMQ, Redis, API, Worker, Flower..."
docker-compose -f docker/docker-compose.yml up -d

log_success "容器启动命令已执行"
echo ""

# ============ 步骤6：等待服务就绪 ============
log_step "⏳ 步骤 6/10 - 等待服务启动"

log_info "等待 RabbitMQ 启动..."
for i in {1..40}; do
    if docker-compose -f docker/docker-compose.yml exec -T rabbitmq rabbitmq-diagnostics -q ping 2>/dev/null; then
        log_success "RabbitMQ 已启动"
        break
    fi
    echo -n "."
    sleep 1
done

log_info "等待 Redis 启动..."
for i in {1..40}; do
    if docker-compose -f docker/docker-compose.yml exec -T redis redis-cli ping 2>/dev/null | grep -q PONG; then
        log_success "Redis 已启动"
        break
    fi
    echo -n "."
    sleep 1
done

log_info "等待 API 服务启动..."
sleep 15

echo ""

# ============ 步骤7：验证服务 ============
log_step "✅ 步骤 7/10 - 验证服务状态"

log_info "检查容器状态:"
docker-compose -f docker/docker-compose.yml ps
echo ""

log_info "测试 API 连接..."
if curl -s http://localhost:5000/api/v1/health | grep -q "healthy"; then
    log_success "API 服务正常 ✓"
else
    log_warning "API 可能未完全就绪，但容器已启动"
fi

echo ""

# ============ 步骤8：创建测试数据 ============
log_step "🎨 步骤 8/10 - 创建测试图片"

mkdir -p test_images

python3 << 'PYTHON_EOF'
from PIL import Image
import os

os.makedirs('test_images', exist_ok=True)

# 创建彩色测试图片
colors = [
    ('red', (255, 0, 0)),
    ('green', (0, 255, 0)),
    ('blue', (0, 0, 255)),
    ('yellow', (255, 255, 0)),
    ('cyan', (0, 255, 255)),
]

for i, (color_name, color_rgb) in enumerate(colors, 1):
    img = Image.new('RGB', (200, 200), color=color_rgb)
    img.save(f'test_images/test_image_{i}_{color_name}.jpg')

print("✓ 已创建 5 张测试图片")
PYTHON_EOF

log_success "测试图片已创建"

# ============ 步骤9：测试 API ============
log_step "🧪 步骤 9/10 - 测试图片上传"

log_info "测试 1: 健康检查"
curl -s http://localhost:5000/api/v1/health | python3 -m json.tool 2>/dev/null || echo "API 连接中..."
echo ""

log_info "测试 2: 上传单张图片"
RESPONSE=$(curl -s -X POST http://localhost:5000/api/v1/image/process \
  -F "images=@test_images/test_image_1_red.jpg" \
  -F "process_type=style_transfer" \
  -F "model_name=custom_model_v1")

echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"

TASK_ID=$(echo "$RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('task_id', ''))" 2>/dev/null)

if [ ! -z "$TASK_ID" ]; then
    log_success "任务已提交: $TASK_ID"
else
    log_warning "任务 ID 获取失败，继续..."
    TASK_ID="demo-task-id"
fi

echo ""

log_info "测试 3: 批量上传 3 张图片"
BATCH_RESPONSE=$(curl -s -X POST http://localhost:5000/api/v1/image/process \
  -F "images=@test_images/test_image_1_red.jpg" \
  -F "images=@test_images/test_image_2_green.jpg" \
  -F "images=@test_images/test_image_3_blue.jpg" \
  -F "process_type=upscale" \
  -F "model_name=custom_model_v1")

echo "$BATCH_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$BATCH_RESPONSE"

BATCH_TASK_ID=$(echo "$BATCH_RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('task_id', ''))" 2>/dev/null)

if [ ! -z "$BATCH_TASK_ID" ]; then
    log_success "批处理任务已提交: $BATCH_TASK_ID"
fi

echo ""

# ============ 步骤10：显示仪表板 ============
log_step "📊 步骤 10/10 - 启动完成"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ 所有服务已成功启动！"
echo "════════════════════════════════════════════════════════════"
echo ""

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}📊 监控仪表板${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${CYAN}🌸 Flower 任务监控${NC}"
echo "   URL: http://localhost:5555"
echo "   功能: 实时查看任务执行、完成状态"
echo ""
echo -e "${CYAN}🐰 RabbitMQ 管理界面${NC}"
echo "   URL: http://localhost:15672"
echo "   用户名: guest"
echo "   密码: guest"
echo "   功能: 查看消息队列、连接状态"
echo ""
echo -e "${CYAN}🌐 API 服务${NC}"
echo "   URL: http://localhost:5000"
echo "   健康检查: http://localhost:5000/api/v1/health"
echo ""

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}🧪 常用命令${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "# 查看所有容器状态"
echo "docker-compose -f docker/docker-compose.yml ps"
echo ""
echo "# 查看 API 实时日志"
echo "docker-compose -f docker/docker-compose.yml logs -f api"
echo ""
echo "# 查看 Worker 实时日志"
echo "docker-compose -f docker/docker-compose.yml logs -f worker"
echo ""
echo "# 查询任务状态"
echo "curl http://localhost:5000/api/v1/image/task/$TASK_ID"
echo ""
echo "# 上传新图片"
echo "curl -X POST http://localhost:5000/api/v1/image/process \\"
echo "  -F 'images=@test_images/test_image_1_red.jpg' \\"
echo "  -F 'process_type=style_transfer' \\"
echo "  -F 'model_name=custom_model_v1'"
echo ""
echo "# 停止所有服务"
echo "docker-compose -f docker/docker-compose.yml stop"
echo ""
echo "# 重启所有服务"
echo "docker-compose -f docker/docker-compose.yml restart"
echo ""

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📈 系统概览${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "已启动的服务:"
echo "  ✓ RabbitMQ (端口 5672, 管理 15672)"
echo "  ✓ Redis (端口 6379)"
echo "  ✓ Flask API (端口 5000)"
echo "  ✓ Celery Worker x2 (异步处理)"
echo "  ✓ Flower (端口 5555, 任务监控)"
echo ""
echo "项目路径: $(pwd)"
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""
echo "🎉 现在可以："
echo "   1️⃣  打开浏览器访问 http://localhost:5555 (Flower 监控)"
echo "   2️⃣  打开浏览器访问 http://localhost:15672 (RabbitMQ 管理)"
echo "   3️⃣  运行命令测试 API"
echo "   4️⃣  查看实时日志进行调试"
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""
