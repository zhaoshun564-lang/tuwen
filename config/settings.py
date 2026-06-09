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
