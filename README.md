# Linux AI CLI Isolation

在 Linux 服务器上部署隔离的 AI CLI 工具环境（Claude Code、Gemini CLI & Codex CLI），支持多项目独立配置。

## 特性

- **完全隔离** - Claude/Gemini 每个项目独立的配置和缓存，不污染全局环境
- **Conda 集成** - 自动创建/管理 Conda 环境
- **国内加速** - 可选清华 Conda 源 + 淘宝 NPM 镜像
- **安全存储** - API 密钥存储在 Git 忽略的目录中
- **自动配置** - 激活环境时自动加载所有配置
- **第三方 API 支持** - 支持配置第三方 API 代理服务

## 支持的工具

| 工具 | 说明 | 隔离方式 |
|------|------|----------|
| [Claude Code](https://github.com/anthropics/claude-code) | Anthropic 官方 CLI | 项目级隔离 |
| [Gemini CLI](https://github.com/google-gemini/gemini-cli) | Google 官方 CLI | 项目级隔离 |
| [Codex CLI](https://github.com/openai/codex) | OpenAI 官方 CLI | 全局配置 (~/.codex) |

## 快速开始

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

# 启动 Codex CLI
codex
```

## 配置说明

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
CLAUDE_URL=                    # API 地址 (默认: https://api.anthropic.com)
CLAUDE_KEY=                    # API Key (必填!)
CLAUDE_MODEL=                  # 主模型 (默认: claude-opus-4-5-20251101-thinking)
CLAUDE_SMALL_MODEL=            # 快速模型 (默认: claude-haiku-4-5-20251001)

# --- [Gemini CLI 配置] ---
GEMINI_URL=                    # API 地址 (默认: https://generativelanguage.googleapis.com)
GEMINI_KEY=                    # API Key (必填!)
GEMINI_MODEL=                  # 模型 (默认: gemini-3-pro-preview)

# --- [Codex CLI 配置] ---
CODEX_URL=                     # API 地址 (默认: https://api.openai.com/v1)
CODEX_KEY=                     # API Key (必填!)
CODEX_MODEL_PROVIDER=openai    # 模型提供者名称
CODEX_MODEL=                   # 模型 (默认: gpt-5.1-codex-max)
CODEX_REASONING_EFFORT=medium  # 推理等级: low/medium/high
CODEX_WIRE_API=responses       # API 类型: responses/chat
CODEX_NETWORK_ACCESS=enabled   # 网络访问: enabled/disabled
CODEX_DISABLE_RESPONSE_STORAGE=true  # 禁用响应存储: true/false
```

### 第三方 API 服务配置

如果使用第三方 API 代理服务，需要相应修改配置：

```bash
# Claude 第三方服务
CLAUDE_URL=https://your-api-proxy.com

# Gemini 第三方服务
GEMINI_URL=https://your-api-proxy.com

# Codex 第三方服务
CODEX_URL=https://your-api-proxy.com/v1
CODEX_MODEL_PROVIDER=your_provider_name  # 重要：必须与服务提供商名称一致
CODEX_MODEL=your-model-name
```

**注意**: 使用第三方 Codex 服务时，`CODEX_MODEL_PROVIDER` 必须设置为服务提供商指定的名称，否则可能无法正常连接。

## 目录结构

```
项目目录/
├── setup.sh              # 安装脚本
├── remove.sh             # 卸载脚本
├── .env.example          # 配置模板
├── .env                  # 实际配置（不提交 Git）
├── .gitignore
├── README.md
└── .ai_tools_config/     # 运行时配置（不提交 Git）
    ├── .private_config/
    │   ├── secrets.env   # API 密钥
    │   └── npmrc         # NPM 配置
    ├── .private_storage/ # XDG 隔离目录
    └── .gemini/
        └── settings.json

~/.codex/                 # Codex 全局配置目录
├── config.toml           # Codex 配置
└── auth.json             # Codex 认证
```

## 常用命令

### 验证配置

```bash
# 查看环境变量
echo $ANTHROPIC_API_KEY
echo $GEMINI_API_KEY
echo $OPENAI_API_KEY

# 查看配置文件
cat $AI_CONFIG_ROOT/.private_config/secrets.env
cat ~/.codex/config.toml
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
# conda remove -n ai_cli_env --all -y  # 可选：删除整个 Conda 环境
```

## 常见问题

### Q: Claude/Gemini 报错连接失败

**原因**: 网络无法访问官方 API

**解决方案**:
1. 使用第三方 API 服务，修改对应的 `_URL` 配置
2. 或配置代理，设置 `PROXY_URL`

### Q: Codex 报错连接失败

**原因**: 网络问题或配置错误

**解决方案**:
1. 检查 `CODEX_URL` 是否正确
2. 如使用第三方服务，确保 `CODEX_MODEL_PROVIDER` 设置正确
3. 或配置代理，设置 `PROXY_URL`

### Q: Codex 报错 "Error finding codex home"

**原因**: `CODEX_HOME` 环境变量指向了错误的目录

**解决方案**:
```bash
unset CODEX_HOME
conda deactivate && conda activate ai_cli_env
```

### Q: 激活环境后命令找不到

**解决方案**:
```bash
conda deactivate
conda activate ai_cli_env
```

### Q: 如何在多个项目中使用

每个项目独立克隆此仓库，配置各自的 `.env` 文件即可。Claude/Gemini 的配置完全隔离，Codex 使用全局配置 (`~/.codex/`)。

## 环境变量参考

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

### Codex CLI

| 变量 | 说明 |
|------|------|
| `OPENAI_API_KEY` | API 密钥 |
| `OPENAI_BASE_URL` | API 地址 |

### Codex 配置文件 (`~/.codex/config.toml`)

| 配置项 | 说明 |
|--------|------|
| `model_provider` | 模型提供者名称 |
| `model` | 使用的模型 |
| `model_reasoning_effort` | 推理等级 (low/medium/high) |
| `network_access` | 网络访问 (enabled/disabled) |
| `disable_response_storage` | 禁用响应存储 (true/false) |
| `wire_api` | API 类型 (responses/chat) |

## 贡献

欢迎提交 Issue 和 Pull Request！

## License

MIT License
