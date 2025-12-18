# Linux AI CLI Isolation

在 Linux 服务器上部署隔离的 AI CLI 工具环境（Claude Code & Gemini CLI），支持多项目独立配置。

## ✨ 特性

- 🔒 **完全隔离** - 每个项目独立的配置和缓存，不污染全局环境
- 🐍 **Conda 集成** - 自动创建/管理 Conda 环境
- 🚀 **国内加速** - 可选清华 Conda 源 + 淘宝 NPM 镜像
- 🔑 **安全存储** - API 密钥存储在 Git 忽略的目录中
- 🛠️ **自动配置** - 激活环境时自动加载所有配置

## 📋 支持的工具

| 工具 | 说明 |
|------|------|
| [Claude Code](https://github.com/anthropics/claude-code) | Anthropic 官方 CLI |
| [Gemini CLI](https://github.com/google-gemini/gemini-cli) | Google 官方 CLI |

## 🚀 快速开始

### 1. 克隆项目

```bash
git clone https://github.com/yourusername/linux-ai-cli-isolation.git
cd linux-ai-cli-isolation
```

### 2. 配置环境变量

```bash
# 复制配置模板
cp .env.example .env

# 编辑配置（必填 API Key）
nano .env
```

### 3. 运行安装

```bash
chmod +x setup.sh remove.sh
./setup.sh
```

### 4. 激活环境

```bash
conda deactivate && conda activate ai_cli_env
```

### 5. 开始使用

```bash
# 启动 Claude Code
claude

# 启动 Gemini CLI
gemini
```

## ⚙️ 配置说明

### `.env` 配置项

```bash
# --- [Conda 环境设置] ---
CONDA_ENV_NAME=ai_cli_env

# --- [镜像加速] ---
# 是否使用国内镜像 (true/false)
USE_CN_MIRROR=true

# --- [代理设置] ---
# 如需代理，填写地址，例如: http://127.0.0.1:7890
PROXY_URL=

# --- [Claude Code 配置] ---
# API 地址 (默认: https://api.anthropic.com)
CLAUDE_URL=

# API Key (必填!)
CLAUDE_KEY=

# 主模型 (默认: claude-opus-4-5-20251101-thinking)
CLAUDE_MODEL=

# 快速模型 (默认: claude-haiku-4-5-20251001)
CLAUDE_SMALL_MODEL=

# --- [Gemini CLI 配置] ---
# API 地址 (默认: https://generativelanguage.googleapis.com)
GEMINI_URL=

# API Key (必填!)
GEMINI_KEY=

# 模型 (默认: gemini-3-pro-preview)
GEMINI_MODEL=
```

### 中转服务配置示例

如果使用 API 中转服务：

```bash
# Claude 中转
CLAUDE_URL=https://your-claude-proxy.com

# Gemini 中转
GEMINI_URL=https://your-gemini-proxy.com
```

## 📁 目录结构

```
项目目录/
├── setup.sh              # 安装脚本
├── remove.sh             # 卸载脚本
├── .env.example          # 配置模板
├── .env                  # 实际配置（不提交）
├── .gitignore
├── README.md
└── .ai_tools_config/     # 运行时配置（不提交）
    ├── .private_config/
    │   ├── secrets.env   # API 密钥
    │   └── npmrc         # NPM 配置
    ├── .private_storage/ # XDG 隔离目录
    └── .gemini/
        └── settings.json
```

## 🔧 常用命令

### 验证配置

```bash
# 查看环境变量
echo $ANTHROPIC_API_KEY
echo $GEMINI_API_KEY
echo $GOOGLE_GEMINI_BASE_URL

# 查看配置文件
cat $AI_CONFIG_ROOT/.private_config/secrets.env
```

### 重新安装

```bash
./remove.sh
./setup.sh
conda deactivate && conda activate ai_cli_env
```

### 完全卸载

```bash
./remove.sh
# conda remove -n ai_cli_env --all -y # 谨慎！会删除当前conda环境，如果不需要这个环境了再运行这个
```

## ❓ 常见问题

### Q: Gemini 报错 `fetch failed sending request`

**原因**: 网络无法访问 Google API

**解决方案**:
1. 使用中转服务，修改 `GEMINI_URL`
2. 或配置代理，设置 `PROXY_URL`

### Q: 激活环境后命令找不到

**解决方案**:
```bash
conda deactivate
conda activate ai_cli_env
```

### Q: Node.js 版本不对

**解决方案**: 重新运行 `./setup.sh`，脚本会自动升级

### Q: 如何在多个项目中使用

每个项目独立克隆此仓库，配置各自的 `.env` 文件即可。不同项目的配置完全隔离。

## 📜 环境变量参考

### Claude Code

| 变量 | 说明 |
|------|------|
| `ANTHROPIC_BASE_URL` | API 地址 |
| `ANTHROPIC_API_KEY` | API 密钥 |
| `ANTHROPIC_MODEL` | 主模型 |
| `ANTHROPIC_SMALL_FAST_MODEL` | 快速模型 |

### Gemini CLI

| 变量 | 说明 |
|------|------|
| `GOOGLE_GEMINI_BASE_URL` | API 地址 |
| `GEMINI_API_KEY` | API 密钥 |
| `GEMINI_MODEL` | 模型名称 |

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 License

MIT License