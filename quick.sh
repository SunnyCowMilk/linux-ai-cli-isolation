#!/bin/bash
# ==============================================================================
# Linux AI CLI Isolation - 快速管理脚本
#
# 使用方法:
#   curl -fsSL https://raw.githubusercontent.com/SunnyCowMilk/linux-ai-cli-isolation/main/quick.sh | bash
#
# 国内用户（使用 jsdelivr CDN 加速）:
#   curl -fsSL https://cdn.jsdelivr.net/gh/SunnyCowMilk/linux-ai-cli-isolation@main/quick.sh | bash
#
# 直接指定操作:
#   curl ... | bash -s -- install     # 正常安装（下载项目文件）
#   curl ... | bash -s -- standalone  # 自包含安装（跳过下载，网络不稳定推荐）
#   curl ... | bash -s -- uninstall   # 直接卸载
#   curl ... | bash -s -- update      # 更新配置
# ==============================================================================

set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# GitHub 仓库地址（多镜像源）
REPO_GITHUB="https://github.com/SunnyCowMilk/linux-ai-cli-isolation.git"
REPO_MIRRORS=(
    "https://mirror.ghproxy.com/https://github.com/SunnyCowMilk/linux-ai-cli-isolation.git"
    "https://ghproxy.com/https://github.com/SunnyCowMilk/linux-ai-cli-isolation.git"
    "https://gh-proxy.com/https://github.com/SunnyCowMilk/linux-ai-cli-isolation.git"
)
# jsdelivr 作为最后备选（不支持 git clone，需要逐个下载文件）
JSDELIVR_BASE="https://cdn.jsdelivr.net/gh/SunnyCowMilk/linux-ai-cli-isolation@main"
INSTALL_DIR="$HOME/linux-ai-cli-isolation"
SELECTED_REPO=""
USE_JSDELIVR=false

# ==========================================
# 检测已有安装
# ==========================================
check_existing_install() {
    local found=false
    local locations=()

    # 检测全局配置文件
    if [ -f "$HOME/.claude_env" ] || [ -f "$HOME/.gemini_env" ] || [ -f "$HOME/.codex_env" ]; then
        found=true
        locations+=("全局配置文件 (~/.claude_env 等)")
    fi

    # 检测默认安装目录
    if [ -d "$INSTALL_DIR" ]; then
        found=true
        locations+=("$INSTALL_DIR")
    fi

    # 检测当前目录是否是项目目录
    if [ -f "./setup.sh" ] && [ -f "./.env.example" ]; then
        if [ "$(pwd)" != "$INSTALL_DIR" ]; then
            found=true
            locations+=("当前目录 $(pwd)")
        fi
    fi

    if [ "$found" = true ]; then
        echo -e "${YELLOW}⚠️  检测到已有安装:${NC}"
        for loc in "${locations[@]}"; do
            echo -e "   - $loc"
        done
        echo ""
        echo -e "${YELLOW}如果继续安装，全局配置文件将被覆盖。${NC}"
        read -p "是否继续？(y/N): " confirm < /dev/tty
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            echo -e "${BLUE}已取消安装${NC}"
            exit 0
        fi
        echo ""
    fi
}

# ==========================================
# 显示 Banner
# ==========================================
show_banner() {
    echo -e "${BLUE}${BOLD}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║       Linux AI CLI Isolation - 快速管理工具               ║"
    echo "║       Claude Code | Gemini CLI | Codex CLI                ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# ==========================================
# 检测网络环境（多镜像自动切换）
# ==========================================
check_network() {
    echo -e "${BLUE}>>> 检测网络环境...${NC}"

    # 先测试 GitHub 直连
    if curl -s --connect-timeout 5 https://github.com > /dev/null 2>&1; then
        echo -e "${GREEN}   ✅ 可直接访问 GitHub${NC}"
        SELECTED_REPO="$REPO_GITHUB"
        return 0
    fi

    echo -e "${YELLOW}   ⚠️  无法直接访问 GitHub，尝试镜像源...${NC}"

    # 测试 ghproxy 镜像源（使用真实文件 URL 测试）
    local test_urls=(
        "https://mirror.ghproxy.com/https://raw.githubusercontent.com/SunnyCowMilk/linux-ai-cli-isolation/main/README.md"
        "https://ghproxy.com/https://raw.githubusercontent.com/SunnyCowMilk/linux-ai-cli-isolation/main/README.md"
        "https://gh-proxy.com/https://raw.githubusercontent.com/SunnyCowMilk/linux-ai-cli-isolation/main/README.md"
    )
    local mirror_names=("mirror.ghproxy.com" "ghproxy.com" "gh-proxy.com")

    for i in "${!test_urls[@]}"; do
        echo -n "   测试 ${mirror_names[$i]} ... "
        if curl -s --connect-timeout 8 "${test_urls[$i]}" > /dev/null 2>&1; then
            echo -e "${GREEN}可用${NC}"
            SELECTED_REPO="${REPO_MIRRORS[$i]}"
            return 0
        else
            echo -e "${RED}不可用${NC}"
        fi
    done

    # 最后测试 jsdelivr CDN
    echo -n "   测试 jsdelivr CDN ... "
    if curl -s --connect-timeout 8 "${JSDELIVR_BASE}/README.md" > /dev/null 2>&1; then
        echo -e "${GREEN}可用${NC}"
        echo -e "${YELLOW}   注意: jsdelivr 模式下载较慢，请耐心等待${NC}"
        USE_JSDELIVR=true
        return 0
    else
        echo -e "${RED}不可用${NC}"
    fi

    # 所有镜像都不可用
    echo -e "${RED}❌ 所有镜像源都不可用${NC}"
    echo ""
    echo -e "${YELLOW}请尝试:${NC}"
    echo -e "  1. 检查网络连接"
    echo -e "  2. 配置代理后重试"
    echo -e "  3. 手动下载项目后运行 ./setup.sh"
    exit 1
}

# ==========================================
# 检测必要工具
# ==========================================
check_dependencies() {
    echo -e "\n${BLUE}>>> 检测必要工具...${NC}"
    local missing=()

    if ! command -v git &> /dev/null; then
        missing+=("git")
    fi

    if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
        missing+=("curl 或 wget")
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}❌ 缺少必要工具: ${missing[*]}${NC}"
        echo ""
        echo -e "${YELLOW}请先安装:${NC}"
        echo -e "  Ubuntu/Debian: ${GREEN}sudo apt update && sudo apt install git curl${NC}"
        echo -e "  Alpine:        ${GREEN}apk add git curl${NC}"
        echo -e "  CentOS/RHEL:   ${GREEN}sudo yum install git curl${NC}"
        echo -e "  macOS:         ${GREEN}brew install git curl${NC}"
        exit 1
    fi

    echo -e "${GREEN}   ✅ 依赖检查通过${NC}"
}

# ==========================================
# 下载项目
# ==========================================
download_project() {
    echo -e "\n${BLUE}>>> 下载项目...${NC}"

    if [ -d "$INSTALL_DIR" ]; then
        echo -e "${YELLOW}   ⚠️  目录已存在: $INSTALL_DIR${NC}"
        read -p "   是否删除并重新下载？(y/N): " confirm < /dev/tty
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            rm -rf "$INSTALL_DIR"
        else
            echo -e "${BLUE}   使用现有目录${NC}"
            return 0
        fi
    fi

    if [ "$USE_JSDELIVR" = true ]; then
        # jsdelivr 模式：逐个下载文件
        echo -e "   使用 jsdelivr CDN 下载..."
        if ! download_via_jsdelivr; then
            return 1  # 下载失败，返回错误码
        fi
    else
        # git clone 模式
        echo -e "   正在克隆仓库..."
        if git clone --depth 1 "$SELECTED_REPO" "$INSTALL_DIR" 2>/dev/null; then
            echo -e "${GREEN}   ✅ 下载完成${NC}"
        else
            echo -e "${YELLOW}   ⚠️  git clone 失败${NC}"
            return 1  # 下载失败，返回错误码
        fi
    fi
    return 0
}

# ==========================================
# 通过 jsdelivr 下载文件
# ==========================================
download_via_jsdelivr() {
    mkdir -p "$INSTALL_DIR"
    # 只下载必要文件，减少下载量
    local files=("setup.sh" "update.sh" "remove.sh" ".env.example")
    local failed=0

    for file in "${files[@]}"; do
        echo -n "   下载 $file ... "
        if curl -fsSL --connect-timeout 15 "${JSDELIVR_BASE}/${file}" -o "$INSTALL_DIR/$file" 2>/dev/null; then
            echo -e "${GREEN}✓${NC}"
        else
            echo -e "${RED}✗${NC}"
            ((failed++))
        fi
    done

    chmod +x "$INSTALL_DIR"/*.sh 2>/dev/null || true

    # 检查核心文件是否下载成功
    if [ ! -f "$INSTALL_DIR/setup.sh" ]; then
        echo -e "${YELLOW}   ⚠️  核心文件下载失败，将使用自包含模式安装${NC}"
        return 1
    fi

    if [ $failed -gt 0 ]; then
        echo -e "${YELLOW}   ⚠️  部分文件下载失败，但核心文件已下载${NC}"
    else
        echo -e "${GREEN}   ✅ 下载完成${NC}"
    fi
    return 0
}

# ==========================================
# 交互式配置
# ==========================================
interactive_config() {
    echo -e "\n${BLUE}>>> 交互式配置${NC}"
    echo -e "${YELLOW}提示: 留空使用默认值，按 Enter 跳过${NC}\n"

    echo -e "${BOLD}配置模式说明:${NC}"
    echo -e "  ${GREEN}global${NC}   - 全局配置（推荐个人电脑/WSL，无需 Conda）"
    echo -e "  ${GREEN}isolated${NC} - 项目级隔离（需要 Conda，支持多项目不同配置）"
    echo -e "  ${GREEN}disabled${NC} - 禁用该服务"
    echo ""

    # ========== Claude 配置 ==========
    echo -e "${BOLD}━━━ Claude Code ━━━${NC}"
    read -p "模式 [global/isolated/disabled] (默认 global): " claude_mode < /dev/tty
    claude_mode=${claude_mode:-global}

    if [ "$claude_mode" != "disabled" ]; then
        read -p "API Key (必填): " claude_key < /dev/tty
        read -p "API URL (留空使用官方 api.anthropic.com): " claude_url < /dev/tty

        echo -e "${YELLOW}   默认主模型: claude-opus-4-5-20251101-thinking${NC}"
        read -p "主模型名称 (留空使用默认): " claude_model < /dev/tty
        claude_model=${claude_model:-claude-opus-4-5-20251101-thinking}

        echo -e "${YELLOW}   默认快速模型: claude-sonnet-4-5-20250929${NC}"
        read -p "快速模型名称 (留空使用默认): " claude_small_model < /dev/tty
        claude_small_model=${claude_small_model:-claude-sonnet-4-5-20250929}
    fi

    # ========== Gemini 配置 ==========
    echo -e "\n${BOLD}━━━ Gemini CLI ━━━${NC}"
    read -p "模式 [global/isolated/disabled] (默认 global): " gemini_mode < /dev/tty
    gemini_mode=${gemini_mode:-global}

    if [ "$gemini_mode" != "disabled" ]; then
        read -p "API Key (必填): " gemini_key < /dev/tty
        read -p "API URL (留空使用官方 generativelanguage.googleapis.com): " gemini_url < /dev/tty

        echo -e "${YELLOW}   默认模型: gemini-3-pro-preview${NC}"
        read -p "模型名称 (留空使用默认): " gemini_model < /dev/tty
        gemini_model=${gemini_model:-gemini-3-pro-preview}
    fi

    # ========== Codex 配置 ==========
    echo -e "\n${BOLD}━━━ Codex CLI ━━━${NC}"
    echo -e "${YELLOW}   注意: Codex 不支持 isolated 模式${NC}"
    read -p "模式 [global/disabled] (默认 global): " codex_mode < /dev/tty
    codex_mode=${codex_mode:-global}

    if [ "$codex_mode" != "disabled" ]; then
        read -p "API Key (必填): " codex_key < /dev/tty
        read -p "API URL (留空使用官方，第三方通常需加 /v1): " codex_url < /dev/tty

        echo -e "${YELLOW}   默认模型: gpt-5.1-codex-max${NC}"
        read -p "模型名称 (留空使用默认): " codex_model < /dev/tty
        codex_model=${codex_model:-gpt-5.1-codex-max}

        echo -e "${YELLOW}   推理深度: low(快速) / medium(平衡) / high(深度)${NC}"
        read -p "推理深度 (默认 medium): " codex_reasoning < /dev/tty
        codex_reasoning=${codex_reasoning:-medium}
    fi

    # ========== 通用配置 ==========
    echo -e "\n${BOLD}━━━ 通用配置 ━━━${NC}"
    read -p "使用国内镜像加速？[true/false] (默认 true): " use_cn_mirror < /dev/tty
    use_cn_mirror=${use_cn_mirror:-true}

    read -p "代理地址 (留空不使用，如 http://127.0.0.1:7890): " proxy_url < /dev/tty

    # ========== 写入配置 ==========
    cat > "$INSTALL_DIR/.env" << EOF
# Linux AI CLI Isolation - 配置文件
# 由 quick.sh 自动生成于 $(date '+%Y-%m-%d %H:%M:%S')

# --- 通用设置 ---
CONDA_ENV_NAME=ai_cli_env
USE_CN_MIRROR=$use_cn_mirror
PROXY_URL=$proxy_url

# --- Claude Code ---
CLAUDE_MODE=$claude_mode
CLAUDE_URL=$claude_url
CLAUDE_KEY=$claude_key
CLAUDE_MODEL=$claude_model
CLAUDE_SMALL_MODEL=$claude_small_model

# --- Gemini CLI ---
GEMINI_MODE=$gemini_mode
GEMINI_URL=$gemini_url
GEMINI_KEY=$gemini_key
GEMINI_MODEL=$gemini_model

# --- Codex CLI ---
CODEX_MODE=$codex_mode
CODEX_URL=$codex_url
CODEX_KEY=$codex_key
CODEX_MODEL=$codex_model
CODEX_REASONING_EFFORT=$codex_reasoning
CODEX_WIRE_API=responses
CODEX_NETWORK_ACCESS=enabled
CODEX_DISABLE_RESPONSE_STORAGE=true
EOF

    echo -e "\n${GREEN}   ✅ 配置已保存${NC}"
}

# ==========================================
# 自包含安装（无需下载项目文件）
# ==========================================
do_standalone_install() {
    echo -e "\n${BLUE}>>> 自包含模式安装...${NC}"
    echo -e "${YELLOW}   无需下载额外文件，直接安装${NC}"

    # 检查 npm
    if ! command -v npm &> /dev/null; then
        echo -e "${RED}❌ npm 未安装！请先安装 Node.js${NC}"
        echo -e "${YELLOW}   Ubuntu/Debian: sudo apt install nodejs npm${NC}"
        echo -e "${YELLOW}   Alpine:        apk add nodejs npm${NC}"
        echo -e "${YELLOW}   macOS:         brew install node${NC}"
        exit 1
    fi

    # 检测 shell profile
    get_shell_profile() {
        if [ -n "$ZSH_VERSION" ] || [ "$SHELL" = "/bin/zsh" ] || [ "$SHELL" = "/usr/bin/zsh" ]; then
            echo "$HOME/.zshrc"
        else
            echo "$HOME/.bashrc"
        fi
    }

    add_to_profile_file() {
        local env_file="$1"
        local profile_file="$2"
        local source_line="[ -f \"$env_file\" ] && source \"$env_file\""

        if [ -f "$profile_file" ]; then
            if ! grep -qF "$env_file" "$profile_file"; then
                echo "" >> "$profile_file"
                echo "# AI CLI Configuration (added by quick.sh)" >> "$profile_file"
                echo "$source_line" >> "$profile_file"
                return 0
            fi
        else
            echo "# AI CLI Configuration (added by quick.sh)" > "$profile_file"
            echo "$source_line" >> "$profile_file"
        fi
        return 0
    }

    local SHELL_PROFILE=$(get_shell_profile)

    # 确定是否需要 sudo
    local NPM_CMD="npm install -g"
    local NPM_PREFIX=$(npm config get prefix 2>/dev/null)
    if [ -n "$NPM_PREFIX" ] && [ ! -w "$NPM_PREFIX/lib/node_modules" ] 2>/dev/null; then
        if command -v sudo &> /dev/null; then
            echo -e "${YELLOW}   需要 sudo 权限安装全局 npm 包${NC}"
            NPM_CMD="sudo npm install -g"
        fi
    fi

    # 设置 npm 镜像
    if [ "$use_cn_mirror" = "true" ]; then
        npm config set registry https://registry.npmmirror.com
    fi

    # 安装 CLI 工具
    echo -e "\n${BLUE}>>> 安装 CLI 工具...${NC}"

    if [ "$claude_mode" != "disabled" ]; then
        echo -e "📦 安装 Claude Code..."
        $NPM_CMD @anthropic-ai/claude-code
    fi

    if [ "$gemini_mode" != "disabled" ]; then
        echo -e "📦 安装 Gemini CLI..."
        $NPM_CMD @google/gemini-cli
    fi

    if [ "$codex_mode" != "disabled" ]; then
        echo -e "📦 安装 Codex CLI..."
        $NPM_CMD @openai/codex
    fi

    # 配置服务
    echo -e "\n${BLUE}>>> 配置服务...${NC}"

    # Claude 配置
    if [ "$claude_mode" = "global" ]; then
        echo -e "🔧 配置 Claude Code..."
        local CLAUDE_CONFIG="$HOME/.claude_env"
        cat << EOF > "$CLAUDE_CONFIG"
# Claude Code Configuration (generated by quick.sh)
export ANTHROPIC_BASE_URL="$claude_url"
export ANTHROPIC_API_KEY="$claude_key"
export ANTHROPIC_MODEL="$claude_model"
export ANTHROPIC_SMALL_FAST_MODEL="$claude_small_model"
EOF
        chmod 600 "$CLAUDE_CONFIG"
        add_to_profile_file "$CLAUDE_CONFIG" "$SHELL_PROFILE"
        add_to_profile_file "$CLAUDE_CONFIG" "$HOME/.profile"
    fi

    # Gemini 配置
    if [ "$gemini_mode" = "global" ]; then
        echo -e "🔧 配置 Gemini CLI..."
        mkdir -p "$HOME/.gemini"
        echo '{"ide":{"enabled":true},"security":{"auth":{"selectedType":"gemini-api-key"}}}' > "$HOME/.gemini/settings.json"

        local GEMINI_CONFIG="$HOME/.gemini_env"
        cat << EOF > "$GEMINI_CONFIG"
# Gemini CLI Configuration (generated by quick.sh)
export GOOGLE_GEMINI_BASE_URL="$gemini_url"
export GEMINI_API_KEY="$gemini_key"
export GOOGLE_API_KEY="$gemini_key"
export GEMINI_MODEL="$gemini_model"
EOF
        chmod 600 "$GEMINI_CONFIG"
        add_to_profile_file "$GEMINI_CONFIG" "$SHELL_PROFILE"
        add_to_profile_file "$GEMINI_CONFIG" "$HOME/.profile"
    fi

    # Codex 配置
    if [ "$codex_mode" = "global" ]; then
        echo -e "🔧 配置 Codex CLI..."
        local CODEX_HOME_DIR="$HOME/.codex"
        mkdir -p "$CODEX_HOME_DIR"

        cat << EOF > "$CODEX_HOME_DIR/config.toml"
model_provider = "openai"
model = "$codex_model"
model_reasoning_effort = "$codex_reasoning"
network_access = "enabled"
disable_response_storage = true

[model_providers.openai]
name = "openai"
base_url = "$codex_url"
wire_api = "responses"
requires_openai_auth = true
EOF

        cat << EOF > "$CODEX_HOME_DIR/auth.json"
{
  "OPENAI_API_KEY": "$codex_key"
}
EOF
        chmod 600 "$CODEX_HOME_DIR/auth.json"

        local CODEX_CONFIG="$HOME/.codex_env"
        cat << EOF > "$CODEX_CONFIG"
# Codex CLI Configuration (generated by quick.sh)
export OPENAI_API_KEY="$codex_key"
export OPENAI_BASE_URL="$codex_url"
EOF
        chmod 600 "$CODEX_CONFIG"
        add_to_profile_file "$CODEX_CONFIG" "$SHELL_PROFILE"
        add_to_profile_file "$CODEX_CONFIG" "$HOME/.profile"
    fi

    # 配置代理
    if [ -n "$proxy_url" ]; then
        echo -e "🔧 配置代理..."
        local PROXY_CONFIG="$HOME/.ai_proxy_env"
        cat << EOF > "$PROXY_CONFIG"
# Proxy Configuration (generated by quick.sh)
export HTTP_PROXY="$proxy_url"
export HTTPS_PROXY="$proxy_url"
export ALL_PROXY="$proxy_url"
EOF
        add_to_profile_file "$PROXY_CONFIG" "$SHELL_PROFILE"
        add_to_profile_file "$PROXY_CONFIG" "$HOME/.profile"
    fi

    echo -e "\n${GREEN}✅ 自包含模式安装完成！${NC}"
    echo -e "${YELLOW}请运行以下命令使配置生效:${NC}"
    echo -e "  ${GREEN}source $SHELL_PROFILE${NC}"
    echo -e "  ${BLUE}(或重启终端)${NC}"
}

# ==========================================
# 安装
# ==========================================
do_install() {
    show_banner
    check_existing_install
    check_network
    check_dependencies

    # 尝试下载项目
    local USE_STANDALONE=false
    if ! download_project; then
        echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}项目下载失败，但可以使用自包含模式继续安装${NC}"
        echo -e "${YELLOW}自包含模式：无需下载额外文件，直接安装 CLI 工具${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        read -p "是否使用自包含模式继续？(Y/n): " use_standalone < /dev/tty
        if [ "$use_standalone" = "n" ] || [ "$use_standalone" = "N" ]; then
            echo -e "${RED}安装已取消${NC}"
            exit 1
        fi
        USE_STANDALONE=true
    fi

    echo -e "\n${YELLOW}请选择配置方式:${NC}"
    echo -e "  ${GREEN}1)${NC} 交互式配置（推荐）"
    if [ "$USE_STANDALONE" = false ]; then
        echo -e "  ${GREEN}2)${NC} 手动编辑 .env 文件"
    fi
    echo -e "  ${GREEN}3)${NC} 使用默认配置"
    echo ""
    read -p "请选择 [1-3]: " config_choice < /dev/tty

    if [ "$USE_STANDALONE" = true ]; then
        # 自包含模式
        case $config_choice in
            1|"") interactive_config ;;
            3)
                # 使用默认值
                claude_mode="global"
                gemini_mode="global"
                codex_mode="global"
                use_cn_mirror="true"
                ;;
            *)
                interactive_config
                ;;
        esac
        do_standalone_install
    else
        # 正常模式：使用下载的项目文件
        cd "$INSTALL_DIR"
        cp -n .env.example .env 2>/dev/null || true

        case $config_choice in
            1) interactive_config ;;
            2)
                echo -e "\n${BLUE}请编辑配置文件后运行安装:${NC}"
                echo -e "  ${GREEN}nano $INSTALL_DIR/.env${NC}"
                echo -e "  ${GREEN}cd $INSTALL_DIR && ./setup.sh${NC}"
                exit 0
                ;;
        esac

        echo -e "\n${BLUE}>>> 运行安装脚本...${NC}"
        chmod +x setup.sh remove.sh update.sh 2>/dev/null || true
        ./setup.sh
    fi

    echo ""
    echo -e "${GREEN}${BOLD}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║                    🎉 安装完成！                           ║${NC}"
    echo -e "${GREEN}${BOLD}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    if [ "$USE_STANDALONE" = false ]; then
        echo -e "📁 安装目录: ${GREEN}$INSTALL_DIR${NC}"
        echo ""
    fi
    echo -e "${YELLOW}使用命令:${NC}"
    echo -e "  ${GREEN}claude${NC}  - Claude Code"
    echo -e "  ${GREEN}gemini${NC}  - Gemini CLI"
    echo -e "  ${GREEN}codex${NC}   - Codex CLI"
}

# ==========================================
# 卸载
# ==========================================
do_uninstall() {
    show_banner

    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${YELLOW}⚠️  未找到安装目录: $INSTALL_DIR${NC}"
        echo -e "   如果安装在其他位置，请手动运行 remove.sh"
        exit 1
    fi

    echo -e "${YELLOW}即将卸载 AI CLI 工具${NC}"
    read -p "确认卸载？(y/N): " confirm < /dev/tty
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo -e "${BLUE}已取消${NC}"
        exit 0
    fi

    echo -e "\n${BLUE}>>> 运行卸载脚本...${NC}"
    cd "$INSTALL_DIR"
    if [ -f "remove.sh" ]; then
        chmod +x remove.sh
        ./remove.sh
    fi

    read -p "是否删除安装目录？(y/N): " delete_dir < /dev/tty
    if [ "$delete_dir" = "y" ] || [ "$delete_dir" = "Y" ]; then
        rm -rf "$INSTALL_DIR"
        echo -e "${GREEN}✅ 安装目录已删除${NC}"
    fi

    echo ""
    echo -e "${GREEN}${BOLD}🗑️  卸载完成！${NC}"
    echo -e "${YELLOW}提示: 重启终端或 source ~/.bashrc 使更改生效${NC}"
}

# ==========================================
# 更新配置
# ==========================================
do_update() {
    show_banner

    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${RED}❌ 未找到安装目录: $INSTALL_DIR${NC}"
        exit 1
    fi

    cd "$INSTALL_DIR"

    # 拉取最新代码
    echo -e "${BLUE}>>> 拉取最新版本...${NC}"
    git pull origin main 2>/dev/null || echo -e "${YELLOW}   跳过代码更新${NC}"

    echo -e "\n${YELLOW}选择操作:${NC}"
    echo -e "  ${GREEN}1)${NC} 重新配置（交互式）"
    echo -e "  ${GREEN}2)${NC} 仅更新配置（运行 update.sh）"
    echo ""
    read -p "请选择 [1-2]: " update_choice < /dev/tty

    case $update_choice in
        1)
            interactive_config
            ./setup.sh
            ;;
        2)
            if [ -f "update.sh" ]; then
                chmod +x update.sh
                ./update.sh
            else
                echo -e "${RED}update.sh 不存在${NC}"
            fi
            ;;
    esac

    echo -e "\n${GREEN}✅ 更新完成！${NC}"
}

# ==========================================
# 直接自包含安装（跳过下载）
# ==========================================
do_standalone_only() {
    show_banner
    check_existing_install
    check_dependencies

    echo -e "${BLUE}>>> 自包含模式（跳过项目下载）${NC}"
    echo ""

    echo -e "\n${YELLOW}请选择配置方式:${NC}"
    echo -e "  ${GREEN}1)${NC} 交互式配置（推荐）"
    echo -e "  ${GREEN}2)${NC} 使用默认配置"
    echo ""
    read -p "请选择 [1-2]: " config_choice < /dev/tty

    case $config_choice in
        1|"") interactive_config ;;
        2)
            claude_mode="global"
            gemini_mode="global"
            codex_mode="global"
            use_cn_mirror="true"
            ;;
        *)
            interactive_config
            ;;
    esac

    do_standalone_install

    echo ""
    echo -e "${GREEN}${BOLD}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║                    🎉 安装完成！                           ║${NC}"
    echo -e "${GREEN}${BOLD}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}使用命令:${NC}"
    echo -e "  ${GREEN}claude${NC}  - Claude Code"
    echo -e "  ${GREEN}gemini${NC}  - Gemini CLI"
    echo -e "  ${GREEN}codex${NC}   - Codex CLI"
}

# ==========================================
# 显示菜单
# ==========================================
show_menu() {
    show_banner

    # 检查安装状态
    if [ -d "$INSTALL_DIR" ]; then
        echo -e "📁 已安装: ${GREEN}$INSTALL_DIR${NC}"
    else
        echo -e "📁 状态: ${YELLOW}未安装${NC}"
    fi
    echo ""

    echo -e "${YELLOW}请选择操作:${NC}"
    echo -e "  ${GREEN}1)${NC} 安装 AI CLI 工具"
    echo -e "  ${GREEN}2)${NC} 自包含模式安装（跳过下载，网络不稳定时推荐）"
    echo -e "  ${GREEN}3)${NC} 卸载 AI CLI 工具"
    echo -e "  ${GREEN}4)${NC} 更新配置"
    echo -e "  ${GREEN}0)${NC} 退出"
    echo ""
    read -p "请选择 [0-4]: " choice < /dev/tty

    case $choice in
        1) do_install ;;
        2) do_standalone_only ;;
        3) do_uninstall ;;
        4) do_update ;;
        0) echo "再见！"; exit 0 ;;
        *) echo -e "${RED}无效选择${NC}"; exit 1 ;;
    esac
}

# ==========================================
# 主入口
# ==========================================
main() {
    case "${1:-}" in
        install)    do_install ;;
        standalone) do_standalone_only ;;
        uninstall)  do_uninstall ;;
        update)     do_update ;;
        *)          show_menu ;;
    esac
}

main "$@"
