# Linux AI CLI Isolation

在 Linux 服务器上部署 AI CLI 工具环境（Claude Code、Gemini CLI & Codex CLI），支持灵活的配置模式。

## 特性

- **灵活配置** - 每个服务可独立选择：项目级隔离、全局配置或禁用
- **Conda 集成** - 隔离模式下自动创建/管理 Conda 环境
- **国内加速** - 可选清华 Conda 源 + 淘宝 NPM 镜像
- **安全存储** - API 密钥存储在 Git 忽略的目录中
- **多场景适配** - 支持多用户服务器、个人服务器、WSL 等多种环境

## 配置模式

| 模式 | 说明 | 适用场景 |
|------|------|----------|
| `isolated` | 项目级隔离，配置存储在项目目录 | 多用户共享服务器、多项目隔离 |
| `global` | 全局配置，存储在用户主目录 | 个人服务器、WSL、无 Conda 环境 |
| `disabled` | 不配置该服务 | 不需要某个工具时 |

### 各服务支持的模式

| 服务 | isolated | global | disabled |
|------|:--------:|:------:|:--------:|
| Claude Code | ✅ | ✅ | ✅ |
| Gemini CLI | ✅ | ✅ | ✅ |
| Codex CLI | ❌ | ✅ | ✅ |

> **注意**: Codex CLI 不支持项目级隔离，只能使用全局配置或禁用。

## 快速开始

### 1. 克隆项目

```bash
git clone https://github.com/yourusername/linux-ai-cli-isolation.git
cd linux-ai-cli-isolation
```

### 2. 配置环境变量

```bash
cp .env.example .env
nano .env
```

### 3. 选择配置模式

编辑 `.env` 文件，为每个服务选择配置模式：

```bash
# 示例：多用户服务器（全部隔离）
CLAUDE_MODE=isolated
GEMINI_MODE=isolated
CODEX_MODE=global

# 示例：个人服务器/WSL（全局配置）
CLAUDE_MODE=global
GEMINI_MODE=global
CODEX_MODE=global

# 示例：只使用 Claude
CLAUDE_MODE=global
GEMINI_MODE=disabled
CODEX_MODE=disabled
```

### 4. 运行安装

```bash
chmod +x setup.sh remove.sh
./setup.sh
```

### 5. 激活环境

**隔离模式** (需要 Conda):
```bash
conda deactivate && conda activate ai_cli_env
```

**全局模式** (添加到 shell 配置):
```bash
# 如果 Claude 使用 global 模式
echo 'source ~/.claude_env' >> ~/.bashrc

# 如果 Gemini 使用 global 模式
echo 'source ~/.gemini_env' >> ~/.bashrc

source ~/.bashrc
```

### 6. 开始使用

```bash
claude   # Claude Code
gemini   # Gemini CLI
codex    # Codex CLI
```

## 配置说明

### `.env` 完整配置

```bash
# ========== 通用设置 ==========
CONDA_ENV_NAME=ai_cli_env    # Conda 环境名称（仅 isolated 模式需要）
USE_CN_MIRROR=true           # 使用国内镜像
PROXY_URL=                   # 代理地址（可选）

# ========== Claude Code ==========
CLAUDE_MODE=isolated         # isolated/global/disabled
CLAUDE_URL=                  # API 地址（默认: https://api.anthropic.com）
CLAUDE_KEY=                  # API Key（必填）
CLAUDE_MODEL=claude-opus-4-5-20251101-thinking
CLAUDE_SMALL_MODEL=claude-haiku-4-5-20251001

# ========== Gemini CLI ==========
GEMINI_MODE=isolated         # isolated/global/disabled
GEMINI_URL=                  # API 地址（默认: https://generativelanguage.googleapis.com）
GEMINI_KEY=                  # API Key（必填）
GEMINI_MODEL=gemini-3-pro-preview

# ========== Codex CLI ==========
CODEX_MODE=global            # global/disabled（不支持 isolated）
CODEX_URL=                   # API 地址（默认: https://api.openai.com/v1）
CODEX_KEY=                   # API Key（必填）
CODEX_MODEL=gpt-5.1-codex-max
CODEX_REASONING_EFFORT=medium
CODEX_WIRE_API=responses
CODEX_NETWORK_ACCESS=enabled
CODEX_DISABLE_RESPONSE_STORAGE=true
```

### 第三方 API 服务配置

```bash
# Claude 第三方服务
CLAUDE_URL=https://your-api-proxy.com

# Gemini 第三方服务
GEMINI_URL=https://your-api-proxy.com

# Codex 第三方服务（只需修改 URL，无需其他配置）
CODEX_URL=https://your-api-proxy.com/v1
```

## 目录结构

### 隔离模式 (isolated)

```
项目目录/
├── setup.sh
├── remove.sh
├── .env.example
├── .env                      # 不提交 Git
└── .ai_tools_config/         # 不提交 Git
    ├── .private_config/
    │   ├── claude.env
    │   ├── gemini.env
    │   └── npmrc
    ├── .private_storage/     # XDG 隔离目录
    └── .gemini/
        └── settings.json
```

### 全局模式 (global)

```
~/
├── .claude_env               # Claude 环境变量
├── .gemini_env               # Gemini 环境变量
├── .gemini/
│   └── settings.json
└── .codex/
    ├── config.toml
    └── auth.json
```

## 使用场景示例

### 场景 1：多用户共享服务器

多个用户共享同一台服务器，需要隔离各自的配置：

```bash
CLAUDE_MODE=isolated
GEMINI_MODE=isolated
CODEX_MODE=global  # Codex 只能全局
```

### 场景 2：个人 Linux 服务器

个人使用，不需要隔离：

```bash
CLAUDE_MODE=global
GEMINI_MODE=global
CODEX_MODE=global
```

### 场景 3：Windows WSL

WSL 环境，可能没有 Conda：

```bash
CLAUDE_MODE=global
GEMINI_MODE=global
CODEX_MODE=global
```

### 场景 4：只使用特定工具

只需要 Claude Code：

```bash
CLAUDE_MODE=global
GEMINI_MODE=disabled
CODEX_MODE=disabled
```

## 常用命令

### 验证配置

```bash
# 隔离模式
echo $AI_CONFIG_ROOT
cat $AI_CONFIG_ROOT/.private_config/claude.env

# 全局模式
cat ~/.claude_env
cat ~/.codex/config.toml
```

### 重新安装

```bash
./remove.sh
./setup.sh
```

### 完全卸载

```bash
./remove.sh
# 按提示选择要删除的内容
```

## 常见问题

### Q: 隔离模式报错 "Conda not found"

**原因**: 隔离模式需要 Conda

**解决方案**:
1. 安装 Conda/Miniconda
2. 或改用全局模式：`CLAUDE_MODE=global`

### Q: Codex 报错连接失败

**原因**: 网络问题或配置错误

**解决方案**:
1. 检查 `CODEX_URL` 是否正确
2. 或配置代理：`PROXY_URL=http://127.0.0.1:7890`

### Q: Codex 报错 "Error finding codex home"

**原因**: `CODEX_HOME` 环境变量指向错误目录

**解决方案**:
```bash
unset CODEX_HOME
conda deactivate && conda activate ai_cli_env
```

### Q: 全局模式配置后命令仍无法使用

**原因**: 环境变量未加载

**解决方案**:
```bash
# 确保添加到 shell 配置
source ~/.claude_env   # Claude
source ~/.gemini_env   # Gemini

# 或重新加载 shell
source ~/.bashrc
```

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

## 贡献

欢迎提交 Issue 和 Pull Request！

## License

MIT License
