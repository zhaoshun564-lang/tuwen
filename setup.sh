#!/bin/bash

# 自动化仓库配置脚本
# 用途：快速初始化tuwen项目并创建所有必要的目录和文件

set -e

echo "=========================================="
echo "图文 (Tuwen) 项目自动化配置"
echo "=========================================="
echo ""

# 检查GitHub CLI是否安装
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI 未安装"
    echo "请访问: https://cli.github.com/ 进行安装"
    exit 1
fi

echo "✅ GitHub CLI 已安装"
echo ""

# 检查git是否安装
if ! command -v git &> /dev/null; then
    echo "❌ Git 未安装"
    exit 1
fi

echo "✅ Git 已安装"
echo ""

# 创建项目目录
PROJECT_DIR="tuwen"
if [ -d "$PROJECT_DIR" ]; then
    echo "⚠️  目录 $PROJECT_DIR 已存在，将在其中进行配置"
else
    echo "📁 创建项目目录: $PROJECT_DIR"
    mkdir -p "$PROJECT_DIR"
fi

cd "$PROJECT_DIR"

# 初始化git（如果还未初始化）
if [ ! -d ".git" ]; then
    echo "🔧 初始化Git仓库..."
    git init
    git config user.name "zhaoshun564-lang"
else
    echo "✅ Git仓库已初始化"
fi

echo ""
echo "📂 创建项目目录结构..."

# 创建所有必要的目录
mkdir -p api/routes api/models
mkdir -p worker/models
mkdir -p storage/{original,processed,temp}
mkdir -p config
mkdir -p utils
mkdir -p tests
mkdir -p docker
mkdir -p logs
mkdir -p .github/workflows

echo "✅ 目录结构创建完成"
echo ""

# 创建__init__.py文件
echo "🐍 创建Python包初始化文件..."
touch api/__init__.py
touch api/routes/__init__.py
touch api/models/__init__.py
touch worker/__init__.py
touch worker/models/__init__.py
touch config/__init__.py
touch utils/__init__.py
touch tests/__init__.py

echo "✅ Python包初始化完成"
echo ""

# 创建README.md
echo "📝 创建README文档..."

cat > README.md << 'EOF'
# 图文 (Tuwen) - 图生图自动化系统

一个完整的图生图自动化处理系统，支持图片风格转换、超分辨率、超真实处理等功能。

## 🌟 核心特性

- ✅ **异步批处理**：单次最多支持14张图片的批量处理
- ✅ **REST API服务**：完整的RESTful API接口
- ✅ **消息队列集成**：基于RabbitMQ的异步任务队列
- ✅ **本地存储**：原始图片和处理结果本地存储
- ✅ **Docker支持**：完整的容器化部署
- ✅ **自定义模型**：支持自定义深度学习模型集成

## 🚀 快速开始

### 前置要求
- Python 3.8+
- RabbitMQ 3.8+
- Docker & Docker Compose（可选）

### 本地开发

```bash
# 1. 克隆项目
git clone https://github.com/zhaoshun564-lang/tuwen.git
cd tuwen

# 2. 创建虚拟环境
python -m venv venv
source venv/bin/activate  # Linux/Mac

# 3. 安装依赖
pip install -r requirements.txt

# 4. 配置环境变量
cp .env.example .env

# 5. 启动服务
docker-compose -f docker/docker-compose.yml up -d

# 6. 启动API（新终端）
python -m api.app

# 7. 启动Worker（新终端）
celery -A worker.celery_app worker --loglevel=info
```

## 📝 API文档

### 提交图片处理任务
```bash
POST /api/v1/image/process
Content-Type: multipart/form-data

{
  "images": [file1, file2, ...],
  "process_type": "style_transfer",
  "model_name": "custom_model_v1"
}
```

### 查询任务状态
```bash
GET /api/v1/image/task/{task_id}
```

### 下载处理结果
```bash
GET /api/v1/image/download/{task_id}/{image_id}
```

## 📊 项目结构

```
tuwen/
├── api/                    # API服务
├── worker/                 # 后台任务处理
├── storage/                # 存储管理
├── config/                 # 配置文件
├── utils/                  # 工具函数
├── tests/                  # 测试文件
├── docker/                 # Docker配置
└── requirements.txt        # 依赖配置
```

## 🤝 贡献指南

欢迎提交Issue和Pull Request！

## 📄 许可证

MIT License

## 📧 联系方式

- 作者：zhaoshun564-lang
- 项目链接：https://github.com/zhaoshun564-lang/tuwen
EOF

echo "✅ README.md 创建完成"
echo ""

# 创建.gitignore
echo "🔒 创建 .gitignore..."

cat > .gitignore << 'EOF'
__pycache__/
*.py[cod]
*$py.class
.Python
env/
venv/
ENV/
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# IDE
.idea/
.vscode/
*.swp
*.swo
*~

# Project specific
storage/original/
storage/processed/
storage/temp/
models/
logs/
*.log

# Environment
.env
.env.local

# OS
.DS_Store
Thumbs.db

# Testing
.coverage
.pytest_cache/
htmlcov/

# Temporary
*.tmp
*.bak
EOF

echo "✅ .gitignore 创建完成"
echo ""

# 创建requirements.txt
echo "📦 创建依赖配置..."

cat > requirements.txt << 'EOF'
# Web框架
Flask==2.3.3
flask-cors==4.0.0

# 任务队列
celery==5.3.1
redis==5.0.0

# RabbitMQ
pika==1.3.1
kombu==5.3.2

# 图像处理
Pillow==10.0.0
opencv-python==4.8.0.74
numpy==1.24.3

# 深度学习
torch==2.0.1
torchvision==0.15.2

# 数据验证
pydantic==2.1.1

# 环境变量
python-dotenv==1.0.0

# 日志
python-json-logger==2.0.7

# 测试
pytest==7.4.0
pytest-cov==4.1.0

# 工具
requests==2.31.0
tqdm==4.65.0

# 监控
flower==2.0.1

# 部署
gunicorn==21.2.0
EOF

echo "✅ requirements.txt 创建完成"
echo ""

# 创建.env.example
echo "⚙️  创建环境变量示例..."

cat > .env.example << 'EOF'
# API服务
API_HOST=0.0.0.0
API_PORT=5000
API_DEBUG=False
API_LOG_LEVEL=INFO

# RabbitMQ
RABBITMQ_HOST=localhost
RABBITMQ_PORT=5672
RABBITMQ_USER=guest
RABBITMQ_PASSWORD=guest

# Celery
CELERY_BROKER_URL=amqp://guest:guest@localhost:5672//
CELERY_RESULT_BACKEND=redis://localhost:6379/0

# 存储
STORAGE_BASE_PATH=./storage
MAX_IMAGES_PER_BATCH=14
MAX_IMAGE_SIZE=52428800

# 模型
MODEL_BASE_PATH=./models
MODEL_NAME=custom_model_v1
MODEL_DEVICE=cpu

# 处理
PROCESS_TIMEOUT=3600
PROCESS_WORKERS=4
EOF

echo "✅ .env.example 创建完成"
echo ""

# 创建配置文件
echo "⚙️  创建应用配置文件..."

cat > config/settings.py << 'EOF'
"""
应用全局配置
"""
import os
from dotenv import load_dotenv

load_dotenv()

# API配置
API_HOST = os.getenv('API_HOST', '0.0.0.0')
API_PORT = int(os.getenv('API_PORT', 5000))
API_DEBUG = os.getenv('API_DEBUG', 'False').lower() == 'true'
API_LOG_LEVEL = os.getenv('API_LOG_LEVEL', 'INFO')

# RabbitMQ配置
RABBITMQ_HOST = os.getenv('RABBITMQ_HOST', 'localhost')
RABBITMQ_PORT = int(os.getenv('RABBITMQ_PORT', 5672))
RABBITMQ_USER = os.getenv('RABBITMQ_USER', 'guest')
RABBITMQ_PASSWORD = os.getenv('RABBITMQ_PASSWORD', 'guest')
RABBITMQ_VHOST = os.getenv('RABBITMQ_VHOST', '/')

# Celery配置
CELERY_BROKER_URL = os.getenv('CELERY_BROKER_URL', 'amqp://guest:guest@localhost:5672//')
CELERY_RESULT_BACKEND = os.getenv('CELERY_RESULT_BACKEND', 'redis://localhost:6379/0')

# 存储配置
STORAGE_BASE_PATH = os.getenv('STORAGE_BASE_PATH', './storage')
MAX_IMAGES_PER_BATCH = int(os.getenv('MAX_IMAGES_PER_BATCH', 14))
MAX_IMAGE_SIZE = int(os.getenv('MAX_IMAGE_SIZE', 52428800))
ALLOWED_IMAGE_FORMATS = os.getenv('ALLOWED_IMAGE_FORMATS', 'jpg,jpeg,png,webp').split(',')

# 模型配置
MODEL_BASE_PATH = os.getenv('MODEL_BASE_PATH', './models')
MODEL_NAME = os.getenv('MODEL_NAME', 'custom_model_v1')
MODEL_DEVICE = os.getenv('MODEL_DEVICE', 'cpu')

# 处理配置
PROCESS_TIMEOUT = int(os.getenv('PROCESS_TIMEOUT', 3600))
PROCESS_WORKERS = int(os.getenv('PROCESS_WORKERS', 4))

# 日志配置
LOG_LEVEL = os.getenv('LOG_LEVEL', 'INFO')
LOG_FILE = os.getenv('LOG_FILE', './logs/tuwen.log')
EOF

echo "✅ config/settings.py 创建完成"
echo ""

# 创建主应用文件
echo "🚀 创建API应用文件..."

cat > api/app.py << 'EOF'
"""
Flask主应用
"""
from flask import Flask, jsonify
from flask_cors import CORS
from config.settings import API_HOST, API_PORT, API_DEBUG
import logging

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 创建Flask应用
app = Flask(__name__)
CORS(app)

# 注册蓝图
from api.routes.health import health_bp
from api.routes.image_process import image_bp

app.register_blueprint(health_bp, url_prefix='/api/v1')
app.register_blueprint(image_bp, url_prefix='/api/v1')

@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Not Found'}), 404

@app.errorhandler(500)
def internal_error(error):
    logger.error(f"Internal error: {error}")
    return jsonify({'error': 'Internal Server Error'}), 500

if __name__ == '__main__':
    logger.info(f"Starting API server on {API_HOST}:{API_PORT}")
    app.run(host=API_HOST, port=API_PORT, debug=API_DEBUG)
EOF

echo "✅ api/app.py 创建完成"
echo ""

# 创建健康检查路由
echo "💚 创建健康检查路由..."

cat > api/routes/health.py << 'EOF'
"""
健康检查路由
"""
from flask import Blueprint, jsonify
from datetime import datetime

health_bp = Blueprint('health', __name__)

@health_bp.route('/health', methods=['GET'])
def health():
    """健康检查端点"""
    return jsonify({
        'status': 'healthy',
        'api': 'ok',
        'timestamp': datetime.utcnow().isoformat()
    }), 200
EOF

echo "✅ api/routes/health.py 创建完成"
echo ""

# 创建图片处理路由
echo "🖼️  创建图片处理路由..."

cat > api/routes/image_process.py << 'EOF'
"""
图片处理路由
"""
from flask import Blueprint, request, jsonify, send_file
import os
import uuid
from config.settings import STORAGE_BASE_PATH, MAX_IMAGES_PER_BATCH
import logging

logger = logging.getLogger(__name__)
image_bp = Blueprint('image', __name__)

@image_bp.route('/image/process', methods=['POST'])
def process_image():
    """处理图片"""
    try:
        # 检查文件
        if 'images' not in request.files:
            return jsonify({'error': 'No images provided'}), 400
        
        images = request.files.getlist('images')
        
        # 检查数量
        if len(images) > MAX_IMAGES_PER_BATCH:
            return jsonify({
                'error': f'Too many images. Maximum {MAX_IMAGES_PER_BATCH} allowed'
            }), 400
        
        # 生成任务ID
        task_id = str(uuid.uuid4())
        
        return jsonify({
            'task_id': task_id,
            'status': 'processing',
            'image_count': len(images),
            'message': 'Task submitted successfully'
        }), 202
        
    except Exception as e:
        logger.error(f"Error processing image: {e}")
        return jsonify({'error': str(e)}), 500

@image_bp.route('/image/task/<task_id>', methods=['GET'])
def get_task_status(task_id):
    """查询任务状态"""
    try:
        return jsonify({
            'task_id': task_id,
            'status': 'processing',
            'images': [],
            'total_time': None,
            'error': None
        }), 200
        
    except Exception as e:
        logger.error(f"Error getting task status: {e}")
        return jsonify({'error': str(e)}), 500
EOF

echo "✅ api/routes/image_process.py 创建完成"
echo ""

# 创建Celery应用
echo "⚙️  创建Celery应用..."

cat > worker/celery_app.py << 'EOF'
"""
Celery应用配置
"""
from celery import Celery
from config.settings import CELERY_BROKER_URL, CELERY_RESULT_BACKEND

# 创建Celery应用
celery_app = Celery('tuwen')

# 配置
celery_app.conf.update(
    broker_url=CELERY_BROKER_URL,
    result_backend=CELERY_RESULT_BACKEND,
    task_serializer='json',
    accept_content=['json'],
    result_serializer='json',
    timezone='UTC',
    enable_utc=True,
)

# 自动发现任务
celery_app.autodiscover_tasks(['worker'])
EOF

echo "✅ worker/celery_app.py 创建完成"
echo ""

# 创建任务定义
echo "📋 创建任务定义..."

cat > worker/tasks.py << 'EOF'
"""
异步任务定义
"""
from worker.celery_app import celery_app
import logging

logger = logging.getLogger(__name__)

@celery_app.task(bind=True)
def process_image_task(self, task_id, images_data):
    """
    处理图片任务
    
    Args:
        task_id: 任务ID
        images_data: 图片数据
    """
    try:
        logger.info(f"Processing task {task_id}")
        # 这里添加实际的图片处理逻辑
        return {
            'task_id': task_id,
            'status': 'completed',
            'images_processed': len(images_data)
        }
    except Exception as e:
        logger.error(f"Error processing task {task_id}: {e}")
        self.update_state(state='FAILURE', meta={'error': str(e)})
        raise
EOF

echo "✅ worker/tasks.py 创建完成"
echo ""

# 创建Docker相关文件
echo "🐳 创建Docker配置..."

cat > docker/docker-compose.yml << 'EOF'
version: '3.8'

services:
  rabbitmq:
    image: rabbitmq:3-management
    container_name: tuwen_rabbitmq
    ports:
      - "5672:5672"
      - "15672:15672"
    environment:
      RABBITMQ_DEFAULT_USER: guest
      RABBITMQ_DEFAULT_PASS: guest
    healthcheck:
      test: rabbitmq-diagnostics -q ping
      interval: 30s
      timeout: 10s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: tuwen_redis
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 5

  api:
    build:
      context: ..
      dockerfile: docker/Dockerfile.api
    container_name: tuwen_api
    ports:
      - "5000:5000"
    environment:
      - RABBITMQ_HOST=rabbitmq
      - REDIS_HOST=redis
    depends_on:
      rabbitmq:
        condition: service_healthy
      redis:
        condition: service_healthy
    volumes:
      - ../storage:/app/storage
      - ../logs:/app/logs
    command: gunicorn -w 4 -b 0.0.0.0:5000 api.app:app

  worker:
    build:
      context: ..
      dockerfile: docker/Dockerfile.worker
    container_name: tuwen_worker
    environment:
      - RABBITMQ_HOST=rabbitmq
      - REDIS_HOST=redis
    depends_on:
      rabbitmq:
        condition: service_healthy
      redis:
        condition: service_healthy
    volumes:
      - ../storage:/app/storage
      - ../logs:/app/logs
    command: celery -A worker.celery_app worker --loglevel=info -c 4

  flower:
    build:
      context: ..
      dockerfile: docker/Dockerfile.worker
    container_name: tuwen_flower
    ports:
      - "5555:5555"
    environment:
      - RABBITMQ_HOST=rabbitmq
      - REDIS_HOST=redis
    depends_on:
      - rabbitmq
      - redis
    volumes:
      - ../logs:/app/logs
    command: celery -A worker.celery_app flower --port=5555
EOF

echo "✅ docker/docker-compose.yml 创建完成"
echo ""

# 创建Dockerfile
echo "🐳 创建Dockerfile..."

cat > docker/Dockerfile.api << 'EOF'
FROM python:3.10-slim

WORKDIR /app

# 安装依赖
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 复制应用
COPY . .

# 暴露端口
EXPOSE 5000

# 启动应用
CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:5000", "api.app:app"]
EOF

cat > docker/Dockerfile.worker << 'EOF'
FROM python:3.10-slim

WORKDIR /app

# 安装依赖
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 复制应用
COPY . .

# 启动Worker
CMD ["celery", "-A", "worker.celery_app", "worker", "--loglevel=info"]
EOF

echo "✅ Dockerfile 创建完成"
echo ""

# 创建CI/CD工作流
echo "🔄 创建CI/CD工作流..."

mkdir -p .github/workflows

cat > .github/workflows/ci.yml << 'EOF'
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      rabbitmq:
        image: rabbitmq:3-alpine
        options: >-
          --health-cmd "rabbitmq-diagnostics -q ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
      
      redis:
        image: redis:7-alpine
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.10'
    
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt
    
    - name: Lint with flake8
      run: |
        pip install flake8
        flake8 api worker --count --select=E9,F63,F7,F82 --show-source --statistics
    
    - name: Test with pytest
      run: |
        pip install pytest pytest-cov
        pytest tests/ --cov=api --cov=worker
EOF

echo "✅ CI工作流创建完成"
echo ""

# 创建测试文件
echo "🧪 创建测试文件..."

cat > tests/test_api.py << 'EOF'
"""
API测试
"""
import pytest
from api.app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_health(client):
    """测试健康检查"""
    response = client.get('/api/v1/health')
    assert response.status_code == 200
    assert response.json['status'] == 'healthy'

def test_no_images(client):
    """测试没有图片的情况"""
    response = client.post('/api/v1/image/process')
    assert response.status_code == 400
EOF

echo "✅ tests/test_api.py 创建完成"
echo ""

# 初始化git仓库
echo "📦 提交到Git..."
git add .
git commit -m "初始化项目：基础项目结构和配置"

echo ""
echo "=========================================="
echo "✅ 项目初始化完成！"
echo "=========================================="
echo ""
echo "后续步骤："
echo ""
echo "1️⃣  配置环境变量"
echo "   cp .env.example .env"
echo ""
echo "2️⃣  安装依赖"
echo "   pip install -r requirements.txt"
echo ""
echo "3️⃣  启动服务"
echo "   docker-compose -f docker/docker-compose.yml up -d"
echo ""
echo "4️⃣  启动API（新终端）"
echo "   python -m api.app"
echo ""
echo "5️⃣  启动Worker（新终端）"
echo "   celery -A worker.celery_app worker --loglevel=info"
echo ""
echo "6️⃣  访问服务"
echo "   API: http://localhost:5000/api/v1/health"
echo "   Flower: http://localhost:5555"
echo "   RabbitMQ: http://localhost:15672"
echo ""
echo "=========================================="
