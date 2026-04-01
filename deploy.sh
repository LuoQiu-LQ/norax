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
ssh -p $SERVER_PORT $SERVER_USER@$SERVER_IP "rm -rf $TMP_PATH && mkdir -p $TMP_PATH"

if [ $? -ne 0 ]; then
    echo "❌ SSH 连接失败，请检查服务器IP和端口！"
    exit 1
fi

# 3. 上传 dist 到服务器临时目录
echo "📤 正在上传文件到服务器..."
scp -P $SERVER_PORT -r $LOCAL_DIST/* $SERVER_USER@$SERVER_IP:$TMP_PATH/

if [ $? -ne 0 ]; then
    echo "❌ 上传失败！"
    exit 1
fi
echo "✅ 上传成功！"

# 4. 服务器上执行部署
echo "🔧 正在部署到网站目录..."
ssh -p $SERVER_PORT $SERVER_USER@$SERVER_IP << EOF
sudo cp -r $TMP_PATH/* $REMOTE_PATH/
sudo chown -R www-data:www-data $REMOTE_PATH/
sudo nginx -s reload
rm -rf $TMP_PATH
EOF

if [ $? -ne 0 ]; then
    echo "❌ 服务器部署失败！"
    exit 1
fi

echo ""
echo "🎉 部署完成！网站已更新：http://$SERVER_IP"
