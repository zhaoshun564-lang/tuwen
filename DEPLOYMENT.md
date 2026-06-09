# 📖 图文 (Tuwen) - 完整部署指南

## 📚 目录

1. [本地开发](#本地开发)
2. [Docker 部署](#docker-部署)
3. [Kubernetes 部署](#kubernetes-部署)
4. [云服务器部署](#云服务器部署)
5. [GitHub Actions CI/CD](#github-actions-cicd)

---

## 本地开发

### 快速启动

```bash
# 1. 克隆项目
git clone https://github.com/zhaoshun564-lang/tuwen.git
cd tuwen

# 2. 复制环境变量
cp .env.example .env

# 3. 启动脚本
chmod +x quick_start.sh
./quick_start.sh
```

### 手动启动

```bash
# 1. 创建虚拟环境
python -m venv venv
source venv/bin/activate  # Linux/Mac
venv\Scripts\activate  # Windows

# 2. 安装依赖
pip install -r requirements.txt

# 3. 启动 RabbitMQ
docker run -d --name rabbitmq -p 5672:5672 -p 15672:15672 rabbitmq:3-management

# 4. 启动 Redis
docker run -d --name redis -p 6379:6379 redis:7-alpine

# 5. 启动 API（终端 1）
python -m api.app

# 6. 启动 Worker（终端 2）
celery -A worker.celery_app worker --loglevel=info

# 7. 启动 Flower（终端 3）
celery -A worker.celery_app flower --port=5555
```

---

## Docker 部署

### 使用 Docker Compose

```bash
# 启动所有服务
docker-compose -f docker/docker-compose.yml up -d

# 查看状态
docker-compose -f docker/docker-compose.yml ps

# 查看日志
docker-compose -f docker/docker-compose.yml logs -f

# 停止服务
docker-compose -f docker/docker-compose.yml stop

# 删除容器
docker-compose -f docker/docker-compose.yml down
```

### 构建自定义镜像

```bash
# 构建 API 镜像
docker build -f docker/Dockerfile.api -t tuwen-api:latest .

# 构建 Worker 镜像
docker build -f docker/Dockerfile.worker -t tuwen-worker:latest .

# 推送到 Docker Hub
docker tag tuwen-api:latest your-username/tuwen-api:latest
docker push your-username/tuwen-api:latest
```

---

## Kubernetes 部署

### 前置要求

- Kubernetes 集群（minikube、EKS、GKE 等）
- kubectl 已安装
- Docker 镜像已推送到镜像仓库

### 部署步骤

```bash
# 1. 创建命名空间
kubectl create namespace tuwen

# 2. 应用配置
kubectl apply -f k8s/ -n tuwen

# 3. 查看部署
kubectl get all -n tuwen

# 4. 查看日志
kubectl logs -f deployment/api -n tuwen

# 5. 端口转发
kubectl port-forward -n tuwen svc/api 5000:5000
kubectl port-forward -n tuwen svc/flower 5555:5555
```

### 扩展副本

```bash
# 将 Worker 扩展到 5 个副本
kubectl scale deployment worker --replicas=5 -n tuwen
```

---

## 云服务器部署

### VPS（阿里云、腾讯云、DigitalOcean等）

#### 1. SSH 连接到服务器

```bash
ssh root@your-server-ip
```

#### 2. 安装 Docker 和 Docker Compose

```bash
# 安装 Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 安装 Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

#### 3. 克隆项目

```bash
git clone https://github.com/zhaoshun564-lang/tuwen.git
cd tuwen
```

#### 4. 启动服务

```bash
# 复制环境变量
cp .env.example .env

# 启动容器
docker-compose -f docker/docker-compose.yml up -d

# 查看状态
docker-compose -f docker/docker-compose.yml ps
```

#### 5. 配置反向代理（Nginx）

```bash
# 安装 Nginx
sudo apt-get install nginx

# 创建配置文件
sudo tee /etc/nginx/sites-available/tuwen > /dev/null <<EOF
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    location /flower {
        proxy_pass http://localhost:5555;
    }
}
EOF

# 启用配置
sudo ln -s /etc/nginx/sites-available/tuwen /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

---

## GitHub Actions CI/CD

### 自动部署流程

项目已配置了以下工作流：

1. **`deploy.yml`** - 自动构建镜像、运行测试、部署服务
2. **`quality.yml`** - 代码质量检查
3. **`auto-start.yml`** - 定时启动和测试服务

### 触发部署

```bash
# 推送到 main 分支自动触发
git push origin main

# 或手动触发
# 在 GitHub 页面选择 Actions -> 选择工作流 -> Run workflow
```

### 查看工作流状态

```bash
# 在 GitHub 项目页面
Actions -> 选择工作流 -> 查看运行状态
```

---

## 监控和日志

### 本地查看日志

```bash
# 查看所有日志
docker-compose -f docker/docker-compose.yml logs -f

# 查看特定服务日志
docker-compose -f docker/docker-compose.yml logs -f api
docker-compose -f docker/docker-compose.yml logs -f worker
```

### Kubernetes 查看日志

```bash
# 查看 Pod 日志
kubectl logs -f pod/api-xxx -n tuwen

# 查看 Deployment 日志
kubectl logs -f deployment/api -n tuwen
```

### 访问监控仪表板

| 服务 | 地址 | 说明 |
|------|------|------|
| Flower | http://localhost:5555 | 任务监控 |
| RabbitMQ | http://localhost:15672 | 消息队列 |
| API | http://localhost:5000 | REST API |

---

## 性能优化

### 1. Worker 副本扩展

**Docker Compose:**
```bash
# 在 docker-compose.yml 中修改 worker 副本数
docker-compose -f docker/docker-compose.yml up -d --scale worker=4
```

**Kubernetes:**
```bash
kubectl scale deployment worker --replicas=4 -n tuwen
```

### 2. 资源限制

**Docker Compose:**
```yaml
services:
  worker:
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 2G
```

**Kubernetes:**
```yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "500m"
  limits:
    memory: "2Gi"
    cpu: "1000m"
```

---

## 故障排查

### API 无法连接

```bash
# 检查容器是否运行
docker ps

# 检查日志
docker logs tuwen_api

# 检查端口
netstat -an | grep 5000
```

### RabbitMQ 连接失败

```bash
# 进入容器检查
docker exec -it tuwen_rabbitmq bash

# 检查连接
rabbitmqctl list_connections
```

### Worker 未处理任务

```bash
# 查看 Worker 状态
docker logs tuwen_worker

# 查看任务队列
docker exec -it tuwen_rabbitmq rabbitmqctl list_queues
```

---

## 常用命令参考

```bash
# 启动服务
./quick_start.sh

# Docker 相关
docker-compose up -d
docker-compose logs -f
docker-compose ps
docker-compose stop
docker-compose down

# Kubernetes 相关
kubectl apply -f k8s/
kubectl get all -n tuwen
kubectl logs -f deployment/api -n tuwen
kubectl delete namespace tuwen

# Git 相关
git push origin main  # 触发 CI/CD
git pull
git status
```

---

## 更多帮助

- 📖 完整文档: https://github.com/zhaoshun564-lang/tuwen
- 🐛 报告问题: https://github.com/zhaoshun564-lang/tuwen/issues
- 💬 讨论: https://github.com/zhaoshun564-lang/tuwen/discussions

---

**祝你部署顺利！** 🚀
