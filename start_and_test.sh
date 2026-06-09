#!/bin/bash

# ============================================
# 图文 (Tuwen) 完整启动和测试脚本
# ============================================

set -e

echo "╔════════════════════════════════════════════════════════╗"
echo "║     图文 (Tuwen) - 图生图自动化系统                     ║"
echo "║          完整启动和集成测试脚本                        ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 函数：打印日志
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[��]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# ============================================
# 第1步：克隆项目
# ============================================
echo ""
echo -e "${BLUE}═══════════════════════════════════════${NC}"
log_info "第1步：克隆项目"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo ""

if [ ! -d "tuwen" ]; then
    log_info "正在克隆项目..."
    git clone https://github.com/zhaoshun564-lang/tuwen.git
    cd tuwen
else
    log_warning "项目已存在，跳过克隆"
    cd tuwen
fi

log_success "项目已准备就绪"
echo ""

# ============================================
# 第2步：配置环境
# ============================================
echo ""
echo -e "${BLUE}═══════════════════════════════════════${NC}"
log_info "第2步：配置环境变量"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo ""

if [ ! -f ".env" ]; then
    log_info "复制环境变量配置..."
    cp .env.example .env
    log_success ".env文件已创建"
else
    log_warning ".env文件已存在，跳过复制"
fi

echo ""

# ============================================
# 第3步：启动所有服务
# ============================================
echo ""
echo -e "${BLUE}═══════════════════════════════════════${NC}"
log_info "第3步：启动所有Docker服务"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo ""

log_info "停止可能运行的旧容器..."
docker-compose -f docker/docker-compose.yml down 2>/dev/null || true

log_info "启动新容器..."
docker-compose -f docker/docker-compose.yml up -d

log_success "容器已启动"
echo ""

# ============================================
# 第4步：等待服务就绪
# ============================================
echo ""
echo -e "${BLUE}══════════════════════════════════════��${NC}"
log_info "第4步：等待服务启动"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo ""

log_info "等待RabbitMQ启动..."
for i in {1..30}; do
    if docker-compose -f docker/docker-compose.yml exec -T rabbitmq rabbitmq-diagnostics -q ping 2>/dev/null; then
        log_success "RabbitMQ已启动"
        break
    fi
    echo -n "."
    sleep 1
done

log_info "等待Redis启动..."
for i in {1..30}; do
    if docker-compose -f docker/docker-compose.yml exec -T redis redis-cli ping 2>/dev/null | grep -q PONG; then
        log_success "Redis已启动"
        break
    fi
    echo -n "."
    sleep 1
done

log_info "等待API服务启动..."
sleep 10

echo ""

# ============================================
# 第5步：验证服务状态
# ============================================
echo ""
echo -e "${BLUE}═══════════════════════════════════════${NC}"
log_info "第5步：验证服务状态"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo ""

log_info "检查容器状态..."
docker-compose -f docker/docker-compose.yml ps

echo ""
log_info "测试服务连接..."
echo ""

# 测试API
log_info "测试API健康检查 (http://localhost:5000/api/v1/health)"
if curl -s http://localhost:5000/api/v1/health | grep -q "healthy"; then
    log_success "✓ API服务正常"
else
    log_warning "API服务可能未完全就绪，请稍候..."
fi

# 测试RabbitMQ
log_info "测试RabbitMQ (http://localhost:15672)"
if curl -s -u guest:guest http://localhost:15672/api/overview | grep -q "rabbitmq_version"; then
    log_success "✓ RabbitMQ管理界面正常"
else
    log_warning "RabbitMQ可能未完全就绪"
fi

# 测试Redis
log_info "测试Redis (localhost:6379)"
if docker-compose -f docker/docker-compose.yml exec -T redis redis-cli ping | grep -q PONG; then
    log_success "✓ Redis正常"
fi

echo ""

# ============================================
# 第6步：创建测试图片
# ============================================
echo ""
echo -e "${BLUE}═══════════════════════════════════════${NC}"
log_info "第6步：创建测试图片"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo ""

# 创建测试目录
mkdir -p test_images

# 创建一个简单的测试图片（100x100像素的红色图片）
python3 << 'EOF'
from PIL import Image
import os

os.makedirs('test_images', exist_ok=True)

# 创建测试图片
img1 = Image.new('RGB', (100, 100), color='red')
img1.save('test_images/test_image_1.jpg')

img2 = Image.new('RGB', (100, 100), color='blue')
img2.save('test_images/test_image_2.jpg')

img3 = Image.new('RGB', (100, 100), color='green')
img3.save('test_images/test_image_3.jpg')

print("测试图片已创建：")
print("  - test_images/test_image_1.jpg (红色)")
print("  - test_images/test_image_2.jpg (蓝色)")
print("  - test_images/test_image_3.jpg (绿色)")
EOF

log_success "测试图片已创建"
echo ""

# ============================================
# 第7步：测试图片上传API
# ============================================
echo ""
echo -e "${BLUE}═══════════════════════════════════════${NC}"
log_info "第7步：测试图片上传API"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo ""

log_info "上传单张图片进行处理..."
RESPONSE=$(curl -s -X POST http://localhost:5000/api/v1/image/process \
  -F "images=@test_images/test_image_1.jpg" \
  -F "process_type=style_transfer" \
  -F "model_name=custom_model_v1")

echo ""
log_info "API响应："
echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
echo ""

# 提取task_id
TASK_ID=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('task_id', ''))" 2>/dev/null)

if [ -z "$TASK_ID" ]; then
    log_error "无法获取任务ID"
    log_warning "API可能需要更多时间启动，请稍候再试"
    exit 1
fi

log_success "任务已提交，任务ID：$TASK_ID"
echo ""

# ============================================
# 第8步：批量上传多张图片
# ============================================
echo ""
echo -e "${BLUE}═══════════════════════════════════════${NC}"
log_info "第8步：批量上传多张图片"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo ""

log_info "上传3张图片进行批处理..."
BATCH_RESPONSE=$(curl -s -X POST http://localhost:5000/api/v1/image/process \
  -F "images=@test_images/test_image_1.jpg" \
  -F "images=@test_images/test_image_2.jpg" \
  -F "images=@test_images/test_image_3.jpg" \
  -F "process_type=upscale" \
  -F "model_name=custom_model_v1")

echo ""
log_info "批处理API响应："
echo "$BATCH_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$BATCH_RESPONSE"
echo ""

BATCH_TASK_ID=$(echo "$BATCH_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('task_id', ''))" 2>/dev/null)

log_success "批处理任务已提交，任务ID：$BATCH_TASK_ID"
echo ""

# ============================================
# 第9步：监控任务执行进度
# ============================================
echo ""
echo -e "${BLUE}═══════════════════════════════════════${NC}"
log_info "第9步��监控任务执行进度"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo ""

log_info "查询第一个任务状态..."
for i in {1..10}; do
    echo ""
    log_info "检查 (${i}/10)..."
    STATUS_RESPONSE=$(curl -s http://localhost:5000/api/v1/image/task/$TASK_ID)
    
    echo "$STATUS_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$STATUS_RESPONSE"
    
    STATUS=$(echo "$STATUS_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('status', ''))" 2>/dev/null)
    
    if [ "$STATUS" = "completed" ]; then
        log_success "任务已完成！"
        break
    fi
    
    sleep 3
done

echo ""

# ============================================
# 第10步：显示监控仪表板
# ============================================
echo ""
echo -e "${BLUE}═══════════════════════════════════════${NC}"
log_info "第10步：启动监控仪表板"
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo ""

log_success "所有服务已启动并验证！"
echo ""
echo "════════════════════════════════════════════════════════"
echo "📊 监控仪表板访问地址："
echo "════════════════════════════════════════════════════════"
echo ""
echo -e "${GREEN}Flower 任务监控${NC}"
echo "  🔗 http://localhost:5555"
echo "  查看实时任务执行情况、已完成任务、失败任务等"
echo ""
echo -e "${GREEN}RabbitMQ 消息队列管理${NC}"
echo "  🔗 http://localhost:15672"
echo "  用户名: guest"
echo "  密码: guest"
echo "  查看消息队列状态、连接情况等"
echo ""
echo -e "${GREEN}API 服务${NC}"
echo "  🔗 http://localhost:5000"
echo "  健康检查: http://localhost:5000/api/v1/health"
echo ""
echo "════════════════════════════════════════════════════════"
echo "📝 任务信息："
echo "════════════════════════════════════════════════════════"
echo ""
echo "第一个任务 (单张图片):"
echo "  任务ID: $TASK_ID"
echo "  命令: curl http://localhost:5000/api/v1/image/task/$TASK_ID"
echo ""
echo "批处理任务 (3张图片):"
echo "  任务ID: $BATCH_TASK_ID"
echo "  命令: curl http://localhost:5000/api/v1/image/task/$BATCH_TASK_ID"
echo ""
echo "════════════════════════════════════════════════════════"
echo "🧪 测试命令："
echo "════════════════════════════════════════════════════════"
echo ""
echo "# 查询任务状态"
echo "curl http://localhost:5000/api/v1/image/task/$TASK_ID"
echo ""
echo "# 上传新图片"
echo "curl -X POST http://localhost:5000/api/v1/image/process \\"
echo "  -F \"images=@test_images/test_image_1.jpg\" \\"
echo "  -F \"process_type=style_transfer\" \\"
echo "  -F \"model_name=custom_model_v1\""
echo ""
echo "# 查看所有容器日志"
echo "docker-compose -f docker/docker-compose.yml logs -f"
echo ""
echo "# 停止所有服务"
echo "docker-compose -f docker/docker-compose.yml stop"
echo ""
echo "════════════════════════════════════════════════════════"
echo ""
echo -e "${GREEN}✓ 启动和测试完成！${NC}"
echo ""
echo "现在你可以："
echo "  1. 打开 Flower 监控: http://localhost:5555"
echo "  2. 打开 RabbitMQ 管理: http://localhost:15672"
echo "  3. 查看 API 日志: docker-compose -f docker/docker-compose.yml logs -f api"
echo "  4. 查看 Worker 日志: docker-compose -f docker/docker-compose.yml logs -f worker"
echo ""
echo "════════════════════════════════════════════════════════"
