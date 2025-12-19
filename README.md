# Linux AI CLI Isolation

在 Linux 服务器上部署 AI CLI 工具环境（Claude Code、Gemini CLI & Codex CLI），支持灵活的配置模式。

## 特性

- **灵活配置** - 每个服务可独立选择：项目级隔离、全局配置或禁用
- **Conda 集成** - 隔离模式下自动创建/管理 Conda 环境，支持使用已有环境
- **自动配置** - 全局模式自动检测 shell 类型并配置 profile
- **国内加速** - 可选清华 Conda 源 + 淘宝 NPM 镜像
- **安全存储** - API 密钥存储在 Git 忽略的目录中
- **多场景适配** - 支持多用户服务器、个人服务器、WSL 等多种环境

## 配置模式详解

本工具支持三种配置模式，你可以为每个 AI 服务独立选择：

### isolated（项目级隔离）

```
适合场景：多用户共享服务器、需要多项目隔离
```

- **工作原理**：配置文件存储在当前项目的 `.ai_tools_config/` 目录下
- **优点**：不同项目可以有不同的 API Key 和配置，互不影响
- **缺点**：需要安装 Conda，每次使用前要激活环境
- **激活方式**：`conda activate 环境名`

### global（全局配置）

```
适合场景：个人电脑、WSL、只有一套配置的简单场景
```

- **工作原理**：配置文件存储在用户主目录（如 `~/.claude_env`）
- **优点**：配置简单，脚本自动添加到 shell 配置，重启终端即可使用
- **缺点**：所有项目共享同一套配置
- **激活方式**：自动（重启终端或 `source ~/.bashrc`）

### disabled（禁用）

```
适合场景：不需要某个工具时
```

- **工作原理**：完全跳过该服务的安装和配置
- **用途**：只想使用部分工具时选择此项

### 各服务支持的模式

| 服务 | isolated | global | disabled | 说明 |
|------|:--------:|:------:|:--------:|------|
| Claude Code | ✅ | ✅ | ✅ | Anthropic 的 AI 编程助手 |
| Gemini CLI | ✅ | ✅ | ✅ | Google 的 AI 编程助手 |
| Codex CLI | ❌ | ✅ | ✅ | OpenAI 的 AI 编程助手 |

> **为什么 Codex 不支持 isolated？**
> Codex CLI 的设计限制，它只能读取固定位置（`~/.codex/`）的配置文件，无法自定义配置路径。

## 快速开始

### 第一步：克隆项目

```bash
# 下载项目到本地
git clone https://github.com/SunnyCowMilk/linux-ai-cli-isolation.git

# 进入项目目录
cd linux-ai-cli-isolation
```

### 第二步：创建配置文件

```bash
# 复制配置模板
cp .env.example .env

# 用编辑器打开配置文件
nano .env   # 或者用 vim、vscode 等你熟悉的编辑器
```

### 第三步：填写配置

打开 `.env` 文件后，你需要：

1. **选择配置模式**：为每个服务选择 `isolated`、`global` 或 `disabled`
2. **填写 API Key**：从各服务商官网获取（见下方"如何获取 API Key"）
3. **（可选）修改其他设置**：如模型名称、代理地址等

### 第四步：运行安装脚本

```bash
# 添加执行权限
chmod +x setup.sh remove.sh

# 运行安装
./setup.sh
```

### 第五步：激活环境

**如果使用 isolated 模式**（需要 Conda）：
```bash
# 激活 Conda 环境（环境名在 .env 中配置，默认是 ai_cli_env）
conda activate ai_cli_env
```

**如果使用 global 模式**（自动配置）：
```bash
# 方式一：重新加载 shell 配置
source ~/.bashrc   # bash 用户
source ~/.zshrc    # zsh 用户

# 方式二：直接重启终端
```

### 第六步：开始使用

```bash
claude   # 启动 Claude Code
gemini   # 启动 Gemini CLI
codex    # 启动 Codex CLI
```

## 配置参数详解

### 通用设置

| 参数 | 说明 | 默认值 | 示例 |
|------|------|--------|------|
| `CONDA_ENV_NAME` | Conda 环境名称（仅 isolated 模式需要） | `ai_cli_env` | `agent`, `dev`, `myenv` |
| `USE_CN_MIRROR` | 是否使用国内镜像加速下载 | `true` | `true` / `false` |
| `PROXY_URL` | 网络代理地址（可选） | 空 | `http://127.0.0.1:7890` |

#### CONDA_ENV_NAME 详解

这个参数指定要使用的 Conda 虚拟环境名称：

- **使用已有环境**：如果你已经有一个常用的 Conda 环境（如 `agent`），直接填写该名称
- **创建新环境**：填写一个不存在的名称，脚本会自动创建

```bash
# 示例：使用已存在的 agent 环境
CONDA_ENV_NAME=agent

# 示例：让脚本创建新的 ai_cli_env 环境
CONDA_ENV_NAME=ai_cli_env
```

#### USE_CN_MIRROR 详解

控制是否使用国内镜像源：

- `true`：使用清华大学 Conda 镜像 + 淘宝 NPM 镜像（国内用户推荐）
- `false`：使用官方源（海外用户或有稳定代理的用户）

#### PROXY_URL 详解

如果你的网络需要代理才能访问外网：

```bash
# 不使用代理（留空）
PROXY_URL=

# 使用本地 Clash 代理
PROXY_URL=http://127.0.0.1:7890

# 使用局域网代理服务器
PROXY_URL=http://192.168.1.1:8080
```

---

### Claude Code 配置

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `CLAUDE_MODE` | 配置模式 | `isolated` |
| `CLAUDE_URL` | API 服务地址 | `https://api.anthropic.com` |
| `CLAUDE_KEY` | API 密钥（必填） | 空 |
| `CLAUDE_MODEL` | 主模型名称 | `claude-opus-4-5-20251101-thinking` |
| `CLAUDE_SMALL_MODEL` | 快速模型名称 | `claude-haiku-4-5-20251001` |

#### CLAUDE_MODE 详解

选择 Claude Code 的配置方式：

```bash
CLAUDE_MODE=isolated   # 项目级隔离（需要 Conda）
CLAUDE_MODE=global     # 全局配置（自动配置 shell）
CLAUDE_MODE=disabled   # 不安装 Claude Code
```

#### CLAUDE_URL 详解

指定 API 服务器地址：

```bash
# 使用官方服务（留空即可）
CLAUDE_URL=

# 使用第三方 API 代理服务
CLAUDE_URL=https://your-proxy-provider.com
```

#### CLAUDE_KEY 详解

API 密钥用于验证身份，**如何获取**：

1. 访问 [Anthropic Console](https://console.anthropic.com)
2. 注册或登录账号
3. 进入 API Keys 页面
4. 点击 "Create Key" 创建新密钥
5. 复制密钥（以 `sk-ant-` 开头）

```bash
CLAUDE_KEY=sk-ant-xxxxxxxxxxxxxxxxxxxxxxxxx
```

#### CLAUDE_MODEL 详解

选择要使用的 Claude 模型（以下为示例，实际可用模型请参考 [Anthropic 官方文档](https://docs.anthropic.com/en/docs/about-claude/models)）：

| 示例模型 | 特点 | 适用场景 |
|------|------|----------|
| `claude-opus-4-5-20251101-thinking` | 最强大，支持深度思考 | 复杂编程任务 |
| `claude-sonnet-4-5-20250929` | 平衡性能和速度 | 日常开发（推荐） |
| `claude-haiku-4-5-20251001` | 最快速，成本最低 | 简单任务、代码补全 |

---

### Gemini CLI 配置

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `GEMINI_MODE` | 配置模式 | `isolated` |
| `GEMINI_URL` | API 服务地址 | `https://generativelanguage.googleapis.com` |
| `GEMINI_KEY` | API 密钥（必填） | 空 |
| `GEMINI_MODEL` | 模型名称 | `gemini-2.5-pro` |

#### GEMINI_KEY 详解

**如何获取 Gemini API Key**：

1. 访问 [Google AI Studio](https://aistudio.google.com/apikey)
2. 使用 Google 账号登录
3. 点击 "Create API Key"
4. 复制生成的密钥

```bash
GEMINI_KEY=AIzaSyxxxxxxxxxxxxxxxxxxxxxxxxx
```

#### GEMINI_MODEL 详解

选择要使用的 Gemini 模型（以下为示例，实际可用模型请参考 [Google AI 官方文档](https://ai.google.dev/gemini-api/docs/models)）：

| 示例模型 | 特点 |
|------|------|
| `gemini-3-pro-preview` | 专业版，功能最强 |
| `gemini-2.5-pro` | 上一代专业版 |
| `gemini-2.5-flash` | 快速版，响应更快 |

---

### Codex CLI 配置

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `CODEX_MODE` | 配置模式（仅 global/disabled） | `global` |
| `CODEX_URL` | API 服务地址 | `https://api.openai.com/v1` |
| `CODEX_KEY` | API 密钥（必填） | 空 |
| `CODEX_MODEL` | 模型名称 | `gpt-5.1-codex-max` |
| `CODEX_REASONING_EFFORT` | 推理深度 | `medium` |
| `CODEX_WIRE_API` | API 协议 | `responses` |
| `CODEX_NETWORK_ACCESS` | 网络访问权限 | `enabled` |
| `CODEX_DISABLE_RESPONSE_STORAGE` | 禁用响应存储 | `true` |

#### CODEX_KEY 详解

**如何获取 OpenAI API Key**：

1. 访问 [OpenAI Platform](https://platform.openai.com/api-keys)
2. 登录 OpenAI 账号
3. 点击 "Create new secret key"
4. 复制密钥（以 `sk-` 开头）

```bash
CODEX_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

#### CODEX_MODEL 详解

选择要使用的模型（以下为示例，实际可用模型请参考 [OpenAI 官方文档](https://platform.openai.com/docs/models)）：

| 示例模型 | 特点 |
|------|------|
| `gpt-5.1-codex-max` | 代码模型 |
| `o3` | 推理增强模型 |
| `gpt-4.1` | 通用模型 |
| `gpt-4o` | 通用多模态模型 |

#### CODEX_REASONING_EFFORT 详解

控制模型思考的深度：

```bash
CODEX_REASONING_EFFORT=low     # 快速响应，适合简单问题
CODEX_REASONING_EFFORT=medium  # 平衡模式（推荐）
CODEX_REASONING_EFFORT=high    # 深度思考，适合复杂问题
```

#### CODEX_WIRE_API 详解

指定与 API 服务器通信的协议：

```bash
CODEX_WIRE_API=responses  # 新版协议（推荐，功能更多）
CODEX_WIRE_API=chat       # 传统 Chat Completions 协议
```

**何时使用 `chat`**：
- 第三方 API 代理不支持 responses 协议时
- 遇到兼容性问题时

#### CODEX_NETWORK_ACCESS 详解

控制 Codex 是否可以访问网络：

```bash
CODEX_NETWORK_ACCESS=enabled   # 允许（可搜索、获取文档）
CODEX_NETWORK_ACCESS=disabled  # 禁止（更安全）
```

#### CODEX_DISABLE_RESPONSE_STORAGE 详解

控制是否在 OpenAI 服务器上存储对话记录：

```bash
CODEX_DISABLE_RESPONSE_STORAGE=true   # 不存储（保护隐私，推荐）
CODEX_DISABLE_RESPONSE_STORAGE=false  # 允许存储
```

---

## 使用第三方 API 代理

如果你使用第三方 API 代理服务（如 API 中转站），只需修改对应的 URL：

```bash
# Claude 第三方服务
CLAUDE_URL=https://your-proxy-provider.com

# Gemini 第三方服务
GEMINI_URL=https://your-proxy-provider.com

# Codex 第三方服务（注意：通常需要加 /v1 后缀）
CODEX_URL=https://your-proxy-provider.com/v1
```

同时使用代理商提供的 API Key。

---

## 目录结构

### 项目文件

```
linux-ai-cli-isolation/
├── setup.sh          # 安装脚本
├── update.sh         # 更新配置脚本（无需重装）
├── remove.sh         # 卸载脚本
├── .env.example      # 配置模板（提交到 Git）
├── .env              # 你的配置（不提交到 Git）
├── .gitignore        # Git 忽略规则
└── README.md         # 说明文档
```

### isolated 模式生成的文件

```
项目目录/
└── .ai_tools_config/           # 不提交 Git
    ├── .private_config/
    │   ├── claude.env          # Claude 环境变量
    │   ├── gemini.env          # Gemini 环境变量
    │   └── npmrc               # NPM 配置
    ├── .private_storage/       # XDG 隔离目录
    │   ├── config/
    │   ├── data/
    │   ├── state/
    │   └── cache/
    └── .gemini/
        └── settings.json       # Gemini 设置
```

### global 模式生成的文件

```
~/（用户主目录）
├── .bashrc 或 .zshrc     # 自动添加 source 命令
├── .claude_env           # Claude 环境变量
├── .gemini_env           # Gemini 环境变量
├── .codex_env            # Codex 环境变量
├── .gemini/
│   └── settings.json     # Gemini 设置
└── .codex/
    ├── config.toml       # Codex 配置
    └── auth.json         # Codex 认证信息
```

---

## 使用场景示例

### 场景 1：多用户共享服务器

多个开发者共享同一台服务器，每个人有自己的 API Key：

```bash
CLAUDE_MODE=isolated    # 每个用户独立配置
GEMINI_MODE=isolated    # 每个用户独立配置
CODEX_MODE=global       # Codex 只能全局（建议每个用户单独运行脚本）
```

### 场景 2：个人 Linux 服务器 / 台式机

个人使用，追求简单：

```bash
CLAUDE_MODE=global
GEMINI_MODE=global
CODEX_MODE=global
```

### 场景 3：Windows WSL

WSL 环境，可能没有安装 Conda：

```bash
CLAUDE_MODE=global      # 不需要 Conda
GEMINI_MODE=global
CODEX_MODE=global
```

### 场景 4：只使用特定工具

只需要 Claude Code，不需要其他工具：

```bash
CLAUDE_MODE=global
GEMINI_MODE=disabled    # 不安装
CODEX_MODE=disabled     # 不安装
```

---

## 常用命令

### 更新配置（更换 Key/Model/URL）

安装后如需修改配置，**无需重新安装**：

```bash
# 1. 修改 .env 文件
nano .env

# 2. 运行更新脚本
./update.sh

# 3. 重新加载环境
conda deactivate && conda activate ai_cli_env  # isolated 模式
source ~/.bashrc                                # global 模式
```

### 验证配置是否生效

```bash
# 检查 isolated 模式配置
echo $AI_CONFIG_ROOT
cat $AI_CONFIG_ROOT/.private_config/claude.env

# 检查 global 模式配置
cat ~/.claude_env
cat ~/.codex/config.toml
```

### 重新安装

```bash
./remove.sh   # 先卸载
./setup.sh    # 再安装
```

### 完全卸载

```bash
./remove.sh
# 按提示选择要删除的内容
```

---

## 常见问题

### Q: 运行时报错 "Conda not found"

**原因**：你选择了 `isolated` 模式，但系统没有安装 Conda。

**解决方案**（二选一）：
1. 安装 [Miniconda](https://docs.conda.io/en/latest/miniconda.html) 或 Anaconda
2. 改用 `global` 模式（不需要 Conda）

### Q: Codex 报错 "连接失败" 或 "401 Unauthorized"

**可能原因**：
1. API Key 填写错误
2. API URL 格式不对
3. 网络无法访问 API 服务器

**解决方案**：
```bash
# 1. 检查 API Key 是否正确（应以 sk- 开头）
# 2. 确认 URL 格式（官方服务留空，第三方通常需要 /v1 后缀）
CODEX_URL=https://your-proxy.com/v1

# 3. 如需代理，配置代理地址
PROXY_URL=http://127.0.0.1:7890
```

### Q: 报错 "Error finding codex home"

**原因**：`CODEX_HOME` 环境变量指向了错误的目录。

**解决方案**：
```bash
# 清除错误的环境变量
unset CODEX_HOME

# 重新激活环境
conda deactivate && conda activate ai_cli_env
```

### Q: 全局模式配置后，命令仍然找不到

**原因**：shell 配置还没有生效。

**解决方案**：
```bash
# 重新加载 shell 配置
source ~/.bashrc   # bash 用户
source ~/.zshrc    # zsh 用户

# 或者直接重启终端
```

### Q: 如何切换配置模式？

**解决方案**：
```bash
# 1. 修改 .env 文件中的 MODE 设置
# 2. 运行卸载和重新安装
./remove.sh
./setup.sh
```

### Q: 全局模式下报错 "npm not found"

**原因**：全局模式不使用 Conda，需要预先安装 Node.js 和 npm。

**解决方案**：
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install nodejs npm

# Alpine Linux
apk add nodejs npm

# macOS
brew install node

# 安装后重新运行 setup.sh
./setup.sh
```

> **说明**：isolated 模式会通过 Conda 自动安装 Node.js，全局模式则需要用户自行安装。

### Q: WSL 新环境如何从零开始安装？

**问题**：新安装的 WSL（尤其是 Alpine Linux）可能缺少 git、bash、npm 等基础工具。

**Alpine Linux 完整安装步骤**：
```bash
# 1. 安装基础工具
apk update
apk add git bash curl nodejs npm

# 2. 克隆项目
git clone https://github.com/SunnyCowMilk/linux-ai-cli-isolation.git
cd linux-ai-cli-isolation

# 3. 配置
cp .env.example .env
vi .env   # 填写 API Key，建议使用 global 模式

# 4. 运行安装
chmod +x setup.sh
bash setup.sh

# 5. 重启 WSL 或执行
source ~/.profile
```

**Ubuntu/Debian WSL 完整安装步骤**：
```bash
# 1. 安装基础工具
sudo apt update
sudo apt install git curl nodejs npm

# 2. 克隆项目
git clone https://github.com/SunnyCowMilk/linux-ai-cli-isolation.git
cd linux-ai-cli-isolation

# 3. 配置
cp .env.example .env
nano .env   # 填写 API Key，建议使用 global 模式

# 4. 运行安装
chmod +x setup.sh
./setup.sh

# 5. 重启终端或执行
source ~/.bashrc
```

**WSL 推荐配置**：
```bash
# WSL 建议使用 global 模式（无需 Conda）
CLAUDE_MODE=global
GEMINI_MODE=global
CODEX_MODE=global
```

---

## 环境变量参考

这些是脚本最终设置的环境变量，供高级用户参考：

### Claude Code

| 环境变量 | 说明 |
|----------|------|
| `ANTHROPIC_BASE_URL` | API 服务地址 |
| `ANTHROPIC_API_KEY` | API 密钥 |
| `ANTHROPIC_MODEL` | 主模型名称 |
| `ANTHROPIC_SMALL_FAST_MODEL` | 快速模型名称 |

### Gemini CLI

| 环境变量 | 说明 |
|----------|------|
| `GOOGLE_GEMINI_BASE_URL` | API 服务地址 |
| `GEMINI_API_KEY` | API 密钥 |
| `GOOGLE_API_KEY` | API 密钥（别名） |
| `GEMINI_MODEL` | 模型名称 |
| `GEMINI_HOME` | Gemini 配置目录（isolated 模式） |

### Codex CLI

| 环境变量 | 说明 |
|----------|------|
| `OPENAI_API_KEY` | API 密钥 |
| `OPENAI_BASE_URL` | API 服务地址 |

---

## 贡献

欢迎提交 Issue 和 Pull Request！

## License

MIT License
