#!/bin/bash

# --- 配置区 ---
SERVER_USER="lq"
SERVER_IP="39.104.74.119"
SERVER_PORT="22"
REMOTE_PATH="/var/www/norax"
LOCAL_DIST="./dist"
TMP_PATH="/tmp/norax_tmp"

echo "🚀 开始自动化部署流程..."

# 1. 本地构建
echo "📦 正在构建项目 (npm run build)..."
npm run build

if [ $? -ne 0 ]; then
    echo "❌ 构建失败，请检查代码错误！"
    exit 1
fi
echo "✅ 构建成功！"

# 2. 在服务器上创建临时目录
echo "📁 正在初始化服务器临时目录..."
ssh -p $SERVER_PORT $SERVER_USER@$SERVER_IP "rm -rf $TMP_PATH && mkdir -p $TMP_PATH/raw_posts"

if [ $? -ne 0 ]; then
    echo "❌ SSH 连接失败，请检查服务器IP和端口！"
    exit 1
fi

# 3. 上传文件到服务器
echo "📤 正在上传构建产物..."
# 上传 HTML 等静态资源到临时根目录
scp -P $SERVER_PORT -r $LOCAL_DIST/* $SERVER_USER@$SERVER_IP:$TMP_PATH/

echo "📤 正在上传原始 Markdown 文件..."
# 确保本地路径存在并上传 .md 文件到 raw_posts
mkdir -p ./src/content/posts
scp -P $SERVER_PORT -r ./src/content/posts/. $SERVER_USER@$SERVER_IP:$TMP_PATH/raw_posts/

if [ $? -ne 0 ]; then
    echo "❌ 上传失败！"
    exit 1
fi
echo "✅ 上传成功！"

# 4. 服务器上执行部署
echo "🔧 正在部署到网站目录并同步后端..."
ssh -p $SERVER_PORT $SERVER_USER@$SERVER_IP << EOF
# 1. 确保目标目录存在
sudo mkdir -p $REMOTE_PATH

# 2. 【核心修复】先彻底清空线上目录的旧文件，防止幽灵文章和旧缓存残留
sudo rm -rf $REMOTE_PATH/*

# 3. 将临时目录的最新内容安全地同步过去 (-a 保留属性)
sudo cp -ra $TMP_PATH/. $REMOTE_PATH/

# 4. 赋予 Nginx 运行权限并重载服务
sudo chown -R www-data:www-data $REMOTE_PATH/
sudo nginx -s reload

# 5. 清理临时文件夹
rm -rf $TMP_PATH

# 6. 【自动化闭环】重启后端程序，强制触发 SQLite 数据库清理逻辑
cd /var/www/backend
pm2 restart blog-backend || echo "⚠️ PM2 重启失败，请稍后手动检查"
EOF

if [ $? -ne 0 ]; then
    echo "❌ 服务器部署失败！"
    exit 1
fi

echo ""
echo "🎉 部署与数据同步全部完成！网站已更新：http://$SERVER_IP"