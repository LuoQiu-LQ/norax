---
title: "Linux 必知必会：20个高频命令"
date: 2026-03-27
description: "总结了日常开发和运维中最常用的20个Linux命令，涵盖文件操作、系统监控、网络诊断等场景，助你快速上手Linux系统管理。"
tags: ["Linux"]
featured: false
---

作为开发者，Linux命令是我们日常工作中不可或缺的工具。本文总结了20个最常用的命令，涵盖文件操作、系统监控、网络诊断等场景。

## 文件与目录操作

### 1. ls - 查看目录内容
```bash
ls -la          # 详细列表显示（含隐藏文件）
ls -lh          # 人性化大小显示
ls -lt          # 按修改时间排序
```

### 2. cd - 切换目录
```bash
cd ~            # 返回主目录
cd -            # 返回上一个目录
cd /path/to/dir # 切换到指定目录
```

### 3. cp / mv / rm - 文件操作三剑客
```bash
cp -r source/ dest/      # 递归复制目录
mv oldname newname       # 重命名或移动
rm -rf directory/        # 强制删除目录
```

### 4. find - 查找文件
```bash
find . -name "*.txt"           # 按名称查找
find / -size +100M              # 查找大于100M的文件
find . -type f -mtime -7        # 查找7天内修改的文件
```

## 文本处理

### 5. grep - 文本搜索
```bash
grep -r "keyword" ./             # 递归搜索
grep -n "pattern" file           # 显示行号
grep -E "regex" file             # 使用正则表达式
```

### 6. cat / head / tail - 查看文件
```bash
cat file.txt                     # 查看全部内容
head -n 20 file.txt              # 查看前20行
tail -f log.txt                  # 实时监控日志
```

### 7. wc - 统计行数
```bash
wc -l file.txt                   # 统计行数
wc -w file.txt                   # 统计单词数
```

## 系统监控

### 8. top / htop - 进程监控
```bash
top -c                           # 显示完整命令
htop                             # 更友好的界面
```

### 9. df / du - 磁盘使用
```bash
df -h                            # 查看磁盘空间
du -sh *                         # 查看当前目录各文件大小
du -h --max-depth=1              # 限制显示深度
```

### 10. free - 内存查看
```bash
free -h                          # 人性化显示
free -m                          # 以MB为单位
```

## 网络诊断

### 11. ping - 网络连通性
```bash
ping -c 4 google.com             # 发送4个包
ping -i 0.5 host                 # 0.5秒间隔
```

### 12. curl / wget - 网络请求
```bash
curl -X GET https://api.example.com
wget https://example.com/file.tar.gz
```

### 13. netstat / ss - 网络连接
```bash
netstat -tulpn                   # 查看监听端口
ss -tulpn                        # 更现代的工具
```

### 14. ssh - 远程连接
```bash
ssh user@hostname                # 基本连接
ssh -p 2222 user@host           # 指定端口
ssh -i key.pem user@host         # 密钥登录
```

## 权限与用户

### 15. chmod / chown - 权限管理
```bash
chmod 755 script.sh              # 设置权限
chown user:group file            # 更改所有者
```

### 16. sudo - 提权执行
```bash
sudo apt update                  # 以管理员权限执行
sudo -i                          # 切换到root
```

## 压缩与解压

### 17. tar - 归档管理
```bash
tar -czvf archive.tar.gz dir/    # 压缩
tar -xzvf archive.tar.gz         # 解压
```

### 18. zip / unzip
```bash
zip -r archive.zip directory/
unzip archive.zip
```

## 其他实用命令

### 19. history - 命令历史
```bash
history                          # 查看历史
!123                             # 执行第123条命令
Ctrl+R                           # 交互式搜索
```

### 20. kill / pkill - 进程管理
```bash
kill -9 PID                      # 强制终止
pkill -f process_name            # 按名称终止
```

## 实用技巧

### 管道与重定向
```bash
command > output.txt            # 输出重定向
command >> output.txt           # 追加重定向
command 2>&1                    # 错误输出重定向
command1 | command2             # 管道传递
```

### 后台运行
```bash
nohup command &                 # 后台运行
screen                           # 终端复用
tmux                             # 现代终端管理器
```

---

掌握这些命令，你已经具备了Linux日常操作的核心能力。建议收藏本文，遇到问题时随时查阅！

如果觉得有帮助，欢迎留言分享你的常用命令组合。
