---
title: "Nginx 反向代理 + HTTPS 从零配置"
date: 2026-03-27
description: "详细讲解如何在Linux上从零配置Nginx反向代理和HTTPS，包括SSL证书申请、自动续期配置，让你快速掌握Web服务器部署技能。"
tags: ["Nginx", "Linux"]
featured: false
---

Nginx是目前最流行的Web服务器之一，既可以作为静态资源服务器，也可以作为反向代理。本教程将从零开始，教你配置Nginx反向代理和HTTPS。

## 环境准备

### 安装 Nginx

```bash
# CentOS/RHEL
sudo yum install nginx

# Ubuntu/Debian
sudo apt update
sudo apt install nginx

# 启动并设置开机自启
sudo systemctl start nginx
sudo systemctl enable nginx
```

### 基本目录结构

```text
/etc/nginx/
├── nginx.conf          # 主配置文件
├── conf.d/             # 自定义配置目录
│   └── default.conf
├── sites-enabled/      # 启用的站点
├── sites-available/    # 可用的站点
├── ssl/                # SSL证书目录
└── logs/               # 日志目录
```

## 反向代理配置

### 基础反向代理

假设有一台运行在 `localhost:3000` 的Node.js应用，我们用Nginx代理它：

```nginx
# /etc/nginx/conf.d/api.conf

server {
    listen 80;
    server_name api.example.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        
        # 转发请求头
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
```

### 常用proxy_set_header说明

| 指令 | 作用 |
|------|------|
| Host | 原始主机名 |
| X-Real-IP | 客户端真实IP |
| X-Forwarded-For | 代理链IP列表 |
| X-Forwarded-Proto | 原始协议(http/https) |

### 负载均衡配置

```nginx
upstream backend {
    least_conn;                    # 最少连接算法
    # ip_hash;                     # 或使用IP哈希
    server 192.168.1.10:8080 weight=5;
    server 192.168.1.11:8080 weight=3;
    server 192.168.1.12:8080 backup;  # 备用服务器
}

server {
    listen 80;
    server_name api.example.com;

    location / {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 路径重写

```nginx
location /api/v1/ {
    rewrite ^/api/v1/(.*)$ /$1 break;
    proxy_pass http://backend;
}
```

## HTTPS 配置

### 申请 SSL 证书（Let's Encrypt 免费）

```bash
# 安装 Certbot
sudo apt install certbot python3-certbot-nginx

# 申请证书（自动配置）
sudo certbot --nginx -d example.com -d www.example.com

# 测试自动续期
sudo certbot renew --dry-run
```

### 手动配置 HTTPS

如果你已经有证书文件：

```nginx
server {
    listen 80;
    server_name example.com www.example.com;
    
    # HTTP 重定向到 HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name example.com www.example.com;

    # SSL 证书配置
    ssl_certificate /etc/nginx/ssl/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/privkey.pem;
    
    # SSL 安全配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers off;
    
    # HSTS（可选）
    add_header Strict-Transport-Security "max-age=31536000" always;
    
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### SSL 优化建议

```nginx
# SSL 会话缓存
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 1d;

# OCSP Stapling
ssl_stapling on;
ssl_stapling_verify on;
resolver 8.8.8.8 8.8.4.4 valid=300s;
```

## 完整配置示例

### Vue/React SPA 应用

```nginx
server {
    listen 80;
    server_name www.example.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name www.example.com;
    
    root /var/www/dist;
    index index.html;

    # SSL 配置
    ssl_certificate /etc/nginx/ssl/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/privkey.pem;
    
    # 前端路由处理
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

### 前后端分离 API 代理

```nginx
server {
    listen 80;
    server_name www.example.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name www.example.com;
    
    root /var/www/frontend/build;
    index index.html;

    ssl_certificate /etc/nginx/ssl/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/privkey.pem;

    # 前端静态资源
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # API 反向代理
    location /api/ {
        proxy_pass http://127.0.0.1:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    # WebSocket 支持
    location /ws/ {
        proxy_pass http://127.0.0.1:8080/ws/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

## 安全加固

### 基础安全配置

```nginx
server {
    # 隐藏 Nginx 版本号
    server_tokens off;
    
    # 防止点击劫持
    add_header X-Frame-Options "SAMEORIGIN" always;
    
    # XSS 防护
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # 禁止搜索引擎收录
    add_header X-Robots-Tag "noindex, nofollow" always;
}
```

### 限制访问

```nginx
# 只允许特定IP访问管理后台
location /admin/ {
    allow 192.168.1.0/24;
    allow 10.0.0.0/8;
    deny all;
    
    proxy_pass http://127.0.0.1:8080/admin/;
}

# 限制连接数
limit_conn_zone $binary_remote_addr zone=conn_limit:10m;
location / {
    limit_conn conn_limit 10;
}
```

## 常用命令

```bash
# 检查配置语法
sudo nginx -t

# 重载配置
sudo systemctl reload nginx

# 重启服务
sudo systemctl restart nginx

# 查看日志
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
```

## 自动续期脚本

创建Cron任务实现证书自动续期：

```bash
# 编辑 crontab
sudo crontab -e

# 添加以下行（每天凌晨2点检查续期）
0 2 * * * /usr/bin/certbot renew --quiet --renew-hook "/usr/sbin/service nginx reload"
```

## 常见问题排查

### 1. 502 Bad Gateway
通常是后端服务未启动或端口配置错误，检查：
```bash
# 查看后端是否运行
curl http://127.0.0.1:3000/health

# 检查端口是否正确
netstat -tlnp | grep 3000
```

### 2. 403 Forbidden
权限问题，检查：
```bash
# 检查目录权限
ls -la /var/www/

# 修改权限
sudo chown -R www-data:www-data /var/www/
```

### 3. SSL 证书无效
- 确认证书链完整
- 检查证书是否过期
- 确认域名解析正确

## 总结

本教程涵盖了：
- ✅ Nginx 反向代理基础配置
- ✅ 负载均衡设置
- ✅ HTTPS/SSL 配置
- ✅ 常用优化和安全设置

建议从简单配置开始，逐步添加复杂功能，多查阅官方文档。

---

有任何问题欢迎留言讨论！
