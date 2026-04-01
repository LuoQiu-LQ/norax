---
title: "用 Flask 搭一个 RESTful API"
date: 2026-03-27
description: "详细讲解如何使用Python的Flask框架搭建RESTful API，包括路由设计、数据库集成、认证授权和部署上线。"
tags: ["Python"]
featured: false
---

Flask是Python最流行的轻量级Web框架，用它可以快速搭建RESTful API。本文从零开始，手把手教你构建一个完整的RESTful API服务。

## 项目概述

### 技术栈

| 组件 | 技术 |
|------|------|
| 框架 | Flask 3.x |
| ORM | SQLAlchemy |
| 数据库 | SQLite (开发) / PostgreSQL (生产) |
| 认证 | JWT |
| API文档 | Flask-RESTX (Swagger) |
| 部署 | Gunicorn + Docker |

### API 设计

```
用户管理:
GET    /api/users          - 获取用户列表
POST   /api/users          - 创建用户
GET    /api/users/<id>     - 获取用户详情
PUT    /api/users/<id>     - 更新用户
DELETE /api/users/<id>     - 删除用户

认证:
POST   /api/auth/register  - 用户注册
POST   /api/auth/login     - 用户登录
POST   /api/auth/refresh   - 刷新Token

文章管理:
GET    /api/posts          - 获取文章列表
POST   /api/posts          - 创建文章 (需认证)
GET    /api/posts/<id>     - 获取文章详情
PUT    /api/posts/<id>     - 更新文章 (需认证)
DELETE /api/posts/<id>     - 删除文章 (需认证)
```

## 项目结构

```text
flask-api/
├── app/
│   ├── __init__.py       # Flask 应用工厂
│   ├── config.py         # 配置文件
│   ├── models/           # 数据模型
│   │   ├── __init__.py
│   │   ├── user.py
│   │   └── post.py
│   ├── routes/            # 路由
│   │   ├── __init__.py
│   │   ├── auth.py
│   │   ├── user.py
│   │   └── post.py
│   ├── schemas/           # 数据验证
│   │   ├── __init__.py
│   │   └── validators.py
│   └── utils/             # 工具函数
│       ├── __init__.py
│       ├── auth.py
│       └── response.py
├── migrations/            # 数据库迁移
├── tests/                 # 测试
├── requirements.txt
├── Dockerfile
├── docker-compose.yml
└── run.py                 # 入口文件
```

## 环境准备

### 创建项目

```bash
# 创建项目目录
mkdir flask-api && cd flask-api

# 创建虚拟环境
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 安装依赖
pip install flask flask-sqlalchemy flask-migrate flask-jwt-extended flask-cors marshmallow python-dotenv gunicorn
```

### requirements.txt

```
Flask==3.0.0
Flask-SQLAlchemy==3.1.1
Flask-Migrate==4.0.5
Flask-JWT-Extended==4.6.0
Flask-CORS==4.0.0
marshmallow==3.20.1
python-dotenv==1.0.0
gunicorn==21.2.0
psycopg2-binary==2.9.9
```

## 配置文件

### app/config.py

```python
import os
from datetime import timedelta

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'your-secret-key-change-in-production'
    
    # 数据库配置
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL') or 'sqlite:///app.db'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    
    # JWT 配置
    JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY') or 'jwt-secret-key-change-in-production'
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=1)
    JWT_REFRESH_TOKEN_EXPIRES = timedelta(days=30)

class DevelopmentConfig(Config):
    DEBUG = True

class ProductionConfig(Config):
    DEBUG = False

config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'default': DevelopmentConfig
}
```

## 数据模型

### app/models/__init__.py

```python
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime

db = SQLAlchemy()

class BaseModel(db.Model):
    __abstract__ = True
    
    id = db.Column(db.Integer, primary_key=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
```

### app/models/user.py

```python
from . import db, BaseModel
from werkzeug.security import generate_password_hash, check_password_hash

class User(BaseModel):
    __tablename__ = 'users'
    
    username = db.Column(db.String(80), unique=True, nullable=False, index=True)
    email = db.Column(db.String(120), unique=True, nullable=False, index=True)
    password_hash = db.Column(db.String(255), nullable=False)
    is_active = db.Column(db.Boolean, default=True)
    
    # 关系
    posts = db.relationship('Post', backref='author', lazy='dynamic')
    
    def set_password(self, password):
        self.password_hash = generate_password_hash(password)
    
    def check_password(self, password):
        return check_password_hash(self.password_hash, password)
    
    def to_dict(self):
        return {
            'id': self.id,
            'username': self.username,
            'email': self.email,
            'is_active': self.is_active,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }
```

### app/models/post.py

```python
from . import db, BaseModel

class Post(BaseModel):
    __tablename__ = 'posts'
    
    title = db.Column(db.String(200), nullable=False)
    content = db.Column(db.Text, nullable=False)
    slug = db.Column(db.String(200), unique=True, index=True)
    published = db.Column(db.Boolean, default=False)
    
    # 外键
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    
    def to_dict(self, include_author=False):
        data = {
            'id': self.id,
            'title': self.title,
            'content': self.content,
            'slug': self.slug,
            'published': self.published,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }
        if include_author:
            data['author'] = self.author.to_dict()
        return data
```

## 路由实现

### app/routes/auth.py

```python
from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, create_refresh_token, jwt_required, get_jwt_identity
from app.models import db
from app.models.user import User

auth_bp = Blueprint('auth', __name__, url_prefix='/api/auth')

@auth_bp.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    
    # 验证必填字段
    if not data or not data.get('username') or not data.get('email') or not data.get('password'):
        return jsonify({'error': '缺少必填字段'}), 400
    
    # 检查用户是否已存在
    if User.query.filter_by(username=data['username']).first():
        return jsonify({'error': '用户名已存在'}), 409
    
    if User.query.filter_by(email=data['email']).first():
        return jsonify({'error': '邮箱已被注册'}), 409
    
    # 创建用户
    user = User(
        username=data['username'],
        email=data['email']
    )
    user.set_password(data['password'])
    
    db.session.add(user)
    db.session.commit()
    
    return jsonify({
        'message': '注册成功',
        'user': user.to_dict()
    }), 201

@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    
    if not data or not data.get('username') or not data.get('password'):
        return jsonify({'error': '缺少必填字段'}), 400
    
    user = User.query.filter_by(username=data['username']).first()
    
    if not user or not user.check_password(data['password']):
        return jsonify({'error': '用户名或密码错误'}), 401
    
    if not user.is_active:
        return jsonify({'error': '账号已被禁用'}), 403
    
    # 生成 Token
    access_token = create_access_token(identity=user.id)
    refresh_token = create_refresh_token(identity=user.id)
    
    return jsonify({
        'message': '登录成功',
        'access_token': access_token,
        'refresh_token': refresh_token,
        'user': user.to_dict()
    }), 200

@auth_bp.route('/refresh', methods=['POST'])
@jwt_required(refresh=True)
def refresh():
    identity = get_jwt_identity()
    access_token = create_access_token(identity=identity)
    
    return jsonify({
        'access_token': access_token
    }), 200
```

### app/routes/user.py

```python
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from app.models import db
from app.models.user import User

user_bp = Blueprint('user', __name__, url_prefix='/api/users')

@user_bp.route('', methods=['GET'])
def get_users():
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 10, type=int)
    
    pagination = User.query.paginate(page=page, per_page=per_page, error_out=False)
    
    return jsonify({
        'users': [user.to_dict() for user in pagination.items],
        'total': pagination.total,
        'page': pagination.page,
        'pages': pagination.pages
    }), 200

@user_bp.route('/<int:user_id>', methods=['GET'])
def get_user(user_id):
    user = User.query.get_or_404(user_id)
    return jsonify(user.to_dict()), 200

@user_bp.route('/<int:user_id>', methods=['PUT'])
@jwt_required()
def update_user(user_id):
    current_user_id = get_jwt_identity()
    
    # 权限检查：只能修改自己的信息
    if current_user_id != user_id:
        return jsonify({'error': '无权限修改该用户'}), 403
    
    user = User.query.get_or_404(user_id)
    data = request.get_json()
    
    # 更新字段
    if 'email' in data:
        user.email = data['email']
    if 'password' in data:
        user.set_password(data['password'])
    if 'is_active' in data:
        user.is_active = data['is_active']
    
    db.session.commit()
    
    return jsonify({
        'message': '更新成功',
        'user': user.to_dict()
    }), 200

@user_bp.route('/<int:user_id>', methods=['DELETE'])
@jwt_required()
def delete_user(user_id):
    current_user_id = get_jwt_identity()
    
    if current_user_id != user_id:
        return jsonify({'error': '无权限删除该用户'}), 403
    
    user = User.query.get_or_404(user_id)
    
    db.session.delete(user)
    db.session.commit()
    
    return jsonify({'message': '删除成功'}), 200
```

### app/routes/post.py

```python
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from slugify import slugify
from app.models import db
from app.models.post import Post
from app.models.user import User

post_bp = Blueprint('post', __name__, url_prefix='/api/posts')

@post_bp.route('', methods=['GET'])
def get_posts():
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 10, type=int)
    published_only = request.args.get('published', True, type=bool)
    
    query = Post.query
    if published_only:
        query = query.filter_by(published=True)
    
    pagination = query.order_by(Post.created_at.desc()).paginate(
        page=page, per_page=per_page, error_out=False
    )
    
    return jsonify({
        'posts': [post.to_dict(include_author=True) for post in pagination.items],
        'total': pagination.total,
        'page': pagination.page,
        'pages': pagination.pages
    }), 200

@post_bp.route('', methods=['POST'])
@jwt_required()
def create_post():
    current_user_id = get_jwt_identity()
    data = request.get_json()
    
    if not data or not data.get('title') or not data.get('content'):
        return jsonify({'error': '缺少必填字段'}), 400
    
    # 生成 slug
    slug = slugify(data['title'])
    # 处理 slug 重复
    existing = Post.query.filter_by(slug=slug).first()
    if existing:
        slug = f"{slug}-{Post.query.count() + 1}"
    
    post = Post(
        title=data['title'],
        content=data['content'],
        slug=slug,
        published=data.get('published', False),
        user_id=current_user_id
    )
    
    db.session.add(post)
    db.session.commit()
    
    return jsonify({
        'message': '创建成功',
        'post': post.to_dict(include_author=True)
    }), 201

@post_bp.route('/<int:post_id>', methods=['GET'])
def get_post(post_id):
    post = Post.query.get_or_404(post_id)
    return jsonify(post.to_dict(include_author=True)), 200

@post_bp.route('/<int:post_id>', methods=['PUT'])
@jwt_required()
def update_post(post_id):
    current_user_id = get_jwt_identity()
    post = Post.query.get_or_404(post_id)
    
    # 权限检查
    if post.user_id != current_user_id:
        return jsonify({'error': '无权限修改该文章'}), 403
    
    data = request.get_json()
    
    if 'title' in data:
        post.title = data['title']
        post.slug = slugify(data['title'])
    if 'content' in data:
        post.content = data['content']
    if 'published' in data:
        post.published = data['published']
    
    db.session.commit()
    
    return jsonify({
        'message': '更新成功',
        'post': post.to_dict(include_author=True)
    }), 200

@post_bp.route('/<int:post_id>', methods=['DELETE'])
@jwt_required()
def delete_post(post_id):
    current_user_id = get_jwt_identity()
    post = Post.query.get_or_404(post_id)
    
    if post.user_id != current_user_id:
        return jsonify({'error': '无权限删除该文章'}), 403
    
    db.session.delete(post)
    db.session.commit()
    
    return jsonify({'message': '删除成功'}), 200
```

## 应用工厂

### app/__init__.py

```python
from flask import Flask, jsonify
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from flask_migrate import Migrate
from dotenv import load_dotenv
import os

from app.models import db
from app.config import config

jwt = JWTManager()
migrate = Migrate()

def create_app(config_name=None):
    if config_name is None:
        config_name = os.environ.get('FLASK_ENV', 'default')
    
    app = Flask(__name__)
    app.config.from_object(config[config_name])
    
    # 加载 .env 文件
    load_dotenv()
    
    # 初始化扩展
    db.init_app(app)
    jwt.init_app(app)
    migrate.init_app(app, db)
    CORS(app)
    
    # 注册蓝图
    from app.routes.auth import auth_bp
    from app.routes.user import user_bp
    from app.routes.post import post_bp
    
    app.register_blueprint(auth_bp)
    app.register_blueprint(user_bp)
    app.register_blueprint(post_bp)
    
    # 健康检查
    @app.route('/health')
    def health():
        return jsonify({'status': 'ok'}), 200
    
    # 错误处理
    @app.errorhandler(404)
    def not_found(error):
        return jsonify({'error': '资源不存在'}), 404
    
    @app.errorhandler(500)
    def internal_error(error):
        return jsonify({'error': '服务器内部错误'}), 500
    
    # JWT 错误处理
    @jwt.expired_token_loader
    def expired_token_callback(jwt_header, jwt_payload):
        return jsonify({'error': 'Token已过期'}), 401
    
    @jwt.invalid_token_loader
    def invalid_token_callback(error):
        return jsonify({'error': '无效的Token'}), 401
    
    return app
```

### run.py

```python
#!/usr/bin/env python
import os
from app import create_app, db
from app.models.user import User
from app.models.post import Post

app = create_app()

@app.shell_context_processor
def make_shell_context():
    return {'db': db, 'User': User, 'Post': Post}

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    app.run(host='0.0.0.0', port=5000, debug=True)
```

## 测试

### tests/test_auth.py

```python
import pytest
from app import create_app, db
from app.models.user import User

@pytest.fixture
def app():
    app = create_app('testing')
    with app.app_context():
        db.create_all()
        yield app
        db.session.remove()
        db.drop_all()

@pytest.fixture
def client(app):
    return app.test_client()

def test_register(client):
    response = client.post('/api/auth/register', json={
        'username': 'testuser',
        'email': 'test@example.com',
        'password': 'password123'
    })
    assert response.status_code == 201
    assert 'user' in response.json

def test_login(client):
    # 先注册
    client.post('/api/auth/register', json={
        'username': 'testuser',
        'email': 'test@example.com',
        'password': 'password123'
    })
    
    # 再登录
    response = client.post('/api/auth/login', json={
        'username': 'testuser',
        'password': 'password123'
    })
    assert response.status_code == 200
    assert 'access_token' in response.json
```

## 部署

### Dockerfile

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# 安装依赖
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 复制应用
COPY . .

# 运行
EXPOSE 5000
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "4", "run:app"]
```

### docker-compose.yml

```yaml
version: '3.8'

services:
  api:
    build: .
    ports:
      - "5000:5000"
    environment:
      - FLASK_ENV=production
      - DATABASE_URL=postgresql://postgres:password@db:5432/flaskapi
      - SECRET_KEY=${SECRET_KEY}
      - JWT_SECRET_KEY=${JWT_SECRET_KEY}
    depends_on:
      - db
    restart: unless-stopped

  db:
    image: postgres:15-alpine
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=flaskapi
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

volumes:
  postgres_data:
```

## API 文档

启动应用后访问 http://localhost:5000/docs 查看 Swagger 文档。

## 总结

本文实现了一个完整的 Flask RESTful API：

- ✅ 用户认证（注册、登录、JWT）
- ✅ 用户管理（CRUD）
- ✅ 文章管理（CRUD）
- ✅ 数据库持久化
- ✅ Docker 部署

这是一个基础框架，可以根据实际需求扩展更多功能，如文件上传、邮件通知、缓存等。

---

有任何问题欢迎留言讨论！
