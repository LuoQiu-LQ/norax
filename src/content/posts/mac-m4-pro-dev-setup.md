---
title: "我的 Mac M4 Pro 开发环境：从零到顺手"
date: 2026-03-27
description: "详细记录Mac M4 Pro开发环境配置，包括Homebrew、终端、IDE、开发语言环境等，让新Mac开箱即用。"
tags: ["Mac"]
featured: false
---

入手 Mac M4 Pro 后，第一件事就是配置开发环境。本文记录我从零开始配置的全过程，包括工具安装、开发环境配置和一些提升效率的技巧。

## 硬件与系统

| 项目 | 配置 |
|------|------|
| 芯片 | Apple M4 Pro (14英寸) |
| 内存 | 24GB |
| 硬盘 | 512GB |
| 系统 | macOS Sequoia 15.x |

M4 Pro 的性能确实强劲，编译速度比之前 Intel 机型快了好几倍。

## 系统基础设置

### 1. 显示与外观

```bash
# 开启深色模式
# 系统设置 -> 外观 -> 深色

# 开启抗锯齿（可选）
defaults write -g CGFontRenderingFontSmoothingDisabled -bool NO
```

### 2. 触控板设置

推荐开启「轻点来点按」和「三指拖移」，大幅提升操作效率。

### 3. 菜单栏优化

- 移除不需要的菜单栏图标
- 添加「显示器亮度」「键盘亮度」等常用项

## 安装 Homebrew

Homebrew 是 macOS 必备的包管理器：

```bash
# 安装 Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 配置国内镜像（可选但推荐）
echo 'export HOMEBREW_API_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"' >> ~/.zshrc
echo 'export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"' >> ~/.zshrc
echo 'export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"' >> ~/.zshrc
echo 'export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"' >> ~/.zshrc
echo 'export HOMEBREW_PIP_INDEX_URL="https://pypi.tuna.tsinghua.edu.cn/simple"' >> ~/.zshrc
source ~/.zshrc

# 安装后测试
brew --version
```

## 开发工具安装

### Git

```bash
brew install git

# 配置全局信息
git config --global user.name "落秋"
git config --global user.email "00510liu@gmail.com"

# 配置默认分支为 main
git config --global init.defaultBranch main

# 配置别名
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
```

### Node.js (通过 nvm)

```bash
# 安装 nvm
brew install nvm

# 配置 nvm 环境变量（添加到 ~/.zshrc）
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && . "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && . "/opt/homebrew/opt/nvm/etc/bash_comilation.d/nvm"

# 安装 Node.js LTS 版本
nvm install --lts
nvm alias default lts/*

# 验证
node --version
npm --version
```

### Python (通过 pyenv)

```bash
# 安装 pyenv
brew install pyenv

# 配置环境变量（添加到 ~/.zshrc）
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# 安装 Python
pyenv install 3.11.8
pyenv global 3.11.8

# 安装 pipx
python -m ensurepip
python -m pip install --upgrade pip
python -m pip install pipx
pipx ensurepath
```

### Go

```bash
# 安装 Go
brew install go

# 配置 GOPATH（添加到 ~/.zshrc）
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

# 验证
go version
```

### Rust

```bash
# 安装 Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# 配置 cargo 镜像源
mkdir -p ~/.cargo
cat > ~/.cargo/config.toml << EOF
[source.crates-io]
replace-with = 'ustc'

[source.ustc]
registry = "sparse+https://mirrors.ustc.edu.cn/crates.io-index/"
EOF

# 验证
rustc --version
cargo --version
```

### Docker

```bash
# 安装 Docker Desktop
brew install --cask docker

# 或者安装 OrbStack（更轻量，推荐M系列芯片）
brew install --cask orbstack
```

## 终端配置

### iTerm2

macOS 自带的 Terminal 已经不错，但 iTerm2 功能更强大：

```bash
brew install --cask iterm2
```

**iTerm2 主题配置：**
1. 下载 [ Dracula 主题](https://draculatheme.com/iterm)
2. 设置 -> Profiles -> Colors -> Color Presets -> Import
3. 选择下载的 .itermcolors 文件

### Oh My Zsh

```bash
# 安装 Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# 安装插件
# zsh-autosuggestions（命令提示）
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# zsh-syntax-highlighting（语法高亮）
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# fzf（模糊搜索）
brew install fzf
$(brew --prefix)/opt/fzf/install
```

### 配置 ~/.zshrc

```bash
# Oh My Zsh 主题
ZSH_THEME="robbyrussell"

# 插件
plugins=(git zsh-autosuggestions zsh-syntax-highlighting fzf macos)

# 环境变量
export EDITOR="vim"
export VISUAL="code"

# PATH 配置
export PATH="$HOME/bin:/usr/local/bin:$PATH"

# Homebrew 清理
alias bu="brew update && brew upgrade && brew cleanup -s && brew doctor"
```

## IDE 配置

### VS Code

```bash
brew install --cask visual-studio-code

# 安装命令行工具
code --install-extension ms-vscode-commandlin
```

**推荐扩展：**
- Chinese (Simplified) Language Pack
- GitLens
- Prettier
- ESLint
- Python
- Error Lens
- GitHub Copilot

**VS Code settings.json：**
```json
{
  "editor.fontSize": 14,
  "editor.fontFamily": "JetBrains Mono, Menlo, Monaco, 'Courier New', monospace",
  "editor.tabSize": 2,
  "editor.formatOnSave": true,
  "editor.minimap.enabled": false,
  "terminal.fontSize": 14,
  "terminal.integrated.fontFamily": "JetBrains Mono",
  "git.autofetch": true,
  "files.autoSave": "afterDelay"
}
```

### Cursor

```bash
brew install --cask cursor
```

### JetBrains 全家桶

```bash
# 安装 IntelliJ IDEA
brew install --cask intellij-idea

# 安装 PyCharm
brew install --cask pycharm-ce

# 安装 WebStorm
brew install --cask webstorm
```

## 开发语言环境

### Java (通过 SDKMAN)

```bash
# 安装 SDKMAN
curl -s "https://get.sdkman.io" | bash

# 安装 Java
sdk install java 21.0.2-tem

# 安装 Maven
sdk install maven

# 安装 Gradle
sdk install gradle
```

### Ruby (通过 rbenv)

```bash
brew install rbenv ruby-build

# 配置 rbenv（添加到 ~/.zshrc）
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

# 安装 Ruby
rbenv install 3.3.0
rbenv global 3.3.0
```

## 效率工具

### Alfred

```bash
brew install --cask alfred
```

配置 Powerpack 后，设置热键为 `Option + Space`，效率翻倍。

### Raycast

```bash
brew install --cask raycast
```

Raycast 是 Alfred 的现代替代品，界面更美观，功能更强大。

### Fig

```bash
brew install --cask fig
```

终端自动补全工具，让命令行操作更高效。

## 项目开发环境

### 前端项目模板

```bash
# 创建项目目录
mkdir -p ~/Projects/frontend
cd ~/Projects/frontend

# 常用项目初始化
npm create vite@latest my-app -- --template react-ts
npm create vite@latest my-app -- --template vue-ts

# Astro 项目
npm create astro@latest
```

### 后端项目模板

```bash
mkdir -p ~/Projects/backend

# Python FastAPI 项目
cd ~/Projects/backend
python -m venv venv
source venv/bin/activate
pip install fastapi uvicorn

# Go 项目
cd ~/Projects/backend
go mod init github.com/username/project
```

## 数据库

```bash
# MySQL
brew install mysql
brew services start mysql

# PostgreSQL
brew install postgresql@15
brew services start postgresql@15

# Redis
brew install redis
brew services start redis

# MongoDB
brew install mongodb-community
brew services start mongodb-community
```

## 常用命令别名

在 `~/.zshrc` 中添加：

```bash
# Git
alias gs="git status"
alias ga="git add ."
alias gc="git commit"
alias gp="git push"
alias gl="git pull"
alias gco="git checkout"
alias gb="git branch"
alias gf="git fetch"

# Docker
alias d="docker"
alias dc="docker-compose"
alias dps="docker ps"
alias dstop="docker stop \$(docker ps -aq)"

# 系统
alias ll="ls -la"
alias ..="cd .."
alias ...="cd ../.."
alias ports="lsof -i -P -n | grep LISTEN"
alias ip="curl ifconfig.me"

# 项目
alias proj="cd ~/Projects"
```

## 性能优化

### M4 Pro 特色优化

1. **Metal 加速**：Xcode 构建速度大幅提升
2. **统一内存**：机器学习任务更高效
3. **媒体引擎**：视频编码/解码更快

### 开发建议

- 使用 Xcode Cloud 进行远程构建
- 利用 Parallels 或 UTM 运行 Windows/Linux 测试环境
- 使用 docker desktop 的 virtualization framework

## 备份与同步

### Time Machine

外接 SSD 作为 Time Machine 备份盘，每周自动备份。

### dotfiles 同步

将配置文件通过 Git 同步：

```bash
# 创建 dotfiles 仓库
mkdir -p ~/dotfiles
cd ~/dotfiles
git init

# 链接配置文件
ln -sf ~/dotfiles/.zshrc ~/.zshrc
ln -sf ~/dotfiles/.gitconfig ~/.gitconfig
ln -sf ~/dotfiles/.vimrc ~/.vimrc
```

## 总结

我的 Mac M4 Pro 开发环境配置完成，包括：

- ✅ Homebrew 包管理器
- ✅ 多语言开发环境（Node、Python、Go、Rust等）
- ✅ 强大的终端配置（iTerm2 + Oh My Zsh）
- ✅ VS Code + JetBrains IDE
- ✅ 数据库服务（MySQL、PostgreSQL、Redis）
- ✅ 效率工具（Alfred、Raycast、Fig）

这套环境已经足够应对日常开发需求，M4 Pro 的性能让编译、运行都非常流畅。

---

你有什么好的开发环境配置建议？欢迎留言分享！
