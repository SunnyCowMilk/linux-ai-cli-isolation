#!/bin/bash
# ==============================================================================
# Linux AI CLI Isolation - 一键安装脚本
#
# 使用方法:
#   curl -fsSL https://raw.githubusercontent.com/SunnyCowMilk/linux-ai-cli-isolation/main/install.sh | bash
#
# 国内用户（使用 ghproxy 加速）:
#   curl -fsSL https://ghproxy.com/https://raw.githubusercontent.com/SunnyCowMilk/linux-ai-cli-isolation/main/install.sh | bash
# ==============================================================================

set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

REPO_URL="https://github.com/SunnyCowMilk/linux-ai-cli-isolation.git"
REPO_URL_CN="https://ghproxy.com/https://github.com/SunnyCowMilk/linux-ai-cli-isolation.git"
INSTALL_DIR="$HOME/linux-ai-cli-isolation"

echo -e "${BLUE}${BOLD}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║       Linux AI CLI Isolation - 一键安装脚本               ║"
echo "║       Claude Code | Gemini CLI | Codex CLI                ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ==========================================
# 检测网络环境
# ==========================================
check_network() {
    echo -e "${BLUE}>>> 检测网络环境...${NC}"

    # 尝试访问 GitHub
    if curl -s --connect-timeout 5 https://github.com > /dev/null 2>&1; then
        echo -e "${GREEN}   ✅ 可直接访问 GitHub${NC}"
        USE_PROXY=false
    else
        echo -e "${YELLOW}   ⚠️  无法直接访问 GitHub，尝试使用加速镜像${NC}"
        USE_PROXY=true
    fi
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
        echo -e "${YELLOW}请先安装缺少的工具:${NC}"
        echo -e "  Ubuntu/Debian: ${GREEN}sudo apt update && sudo apt install git curl${NC}"
        echo -e "  Alpine:        ${GREEN}apk add git curl${NC}"
        echo -e "  CentOS/RHEL:   ${GREEN}sudo yum install git curl${NC}"
        echo -e "  macOS:         ${GREEN}brew install git curl${NC}"
        exit 1
    fi

    echo -e "${GREEN}   ✅ git 已安装${NC}"
    echo -e "${GREEN}   ✅ curl/wget 已安装${NC}"
}

# ==========================================
# 下载项目
# ==========================================
download_project() {
    echo -e "\n${BLUE}>>> 下载项目...${NC}"

    # 如果目录已存在，询问是否覆盖
    if [ -d "$INSTALL_DIR" ]; then
        echo -e "${YELLOW}   ⚠️  目录已存在: $INSTALL_DIR${NC}"
        read -p "   是否删除并重新下载？(y/N): " confirm
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            rm -rf "$INSTALL_DIR"
        else
            echo -e "${BLUE}   使用现有目录${NC}"
            return 0
        fi
    fi

    # 选择下载源
    if [ "$USE_PROXY" = true ]; then
        echo -e "   使用加速镜像下载..."
        git clone "$REPO_URL_CN" "$INSTALL_DIR" 2>/dev/null || {
            echo -e "${YELLOW}   加速镜像失败，尝试直接下载...${NC}"
            git clone "$REPO_URL" "$INSTALL_DIR"
        }
    else
        git clone "$REPO_URL" "$INSTALL_DIR"
    fi

    echo -e "${GREEN}   ✅ 下载完成: $INSTALL_DIR${NC}"
}

# ==========================================
# 配置向导
# ==========================================
configure_env() {
    echo -e "\n${BLUE}>>> 配置向导${NC}"

    cd "$INSTALL_DIR"

    # 复制配置模板
    if [ ! -f ".env" ]; then
        cp .env.example .env
    fi

    echo ""
    echo -e "${YELLOW}请选择配置方式:${NC}"
    echo -e "  ${GREEN}1)${NC} 交互式配置（推荐新手）"
    echo -e "  ${GREEN}2)${NC} 手动编辑 .env 文件"
    echo -e "  ${GREEN}3)${NC} 使用默认配置（稍后手动修改）"
    echo ""
    read -p "请选择 [1-3]: " config_choice

    case $config_choice in
        1)
            interactive_config
            ;;
        2)
            echo -e "\n${BLUE}请编辑配置文件:${NC}"
            echo -e "  ${GREEN}nano $INSTALL_DIR/.env${NC}"
            echo -e "\n编辑完成后，运行:"
            echo -e "  ${GREEN}cd $INSTALL_DIR && ./setup.sh${NC}"
            exit 0
            ;;
        3)
            echo -e "${YELLOW}   使用默认配置${NC}"
            ;;
        *)
            echo -e "${YELLOW}   使用默认配置${NC}"
            ;;
    esac
}

# ==========================================
# 交互式配置
# ==========================================
interactive_config() {
    echo -e "\n${BLUE}>>> 交互式配置${NC}"
    echo -e "${YELLOW}提示: 留空则使用默认值，按 Enter 跳过${NC}\n"

    # 配置模式选择
    echo -e "${BOLD}选择配置模式:${NC}"
    echo -e "  ${GREEN}global${NC}   - 全局配置（推荐个人电脑/WSL）"
    echo -e "  ${GREEN}isolated${NC} - 项目级隔离（需要 Conda）"
    echo -e "  ${GREEN}disabled${NC} - 禁用该服务"
    echo ""

    # Claude 配置
    echo -e "${BOLD}--- Claude Code 配置 ---${NC}"
    read -p "Claude 模式 [global/isolated/disabled] (默认 global): " claude_mode
    claude_mode=${claude_mode:-global}

    if [ "$claude_mode" != "disabled" ]; then
        read -p "Claude API Key (必填): " claude_key
        read -p "Claude API URL (留空使用官方): " claude_url
    fi

    # Gemini 配置
    echo -e "\n${BOLD}--- Gemini CLI 配置 ---${NC}"
    read -p "Gemini 模式 [global/isolated/disabled] (默认 global): " gemini_mode
    gemini_mode=${gemini_mode:-global}

    if [ "$gemini_mode" != "disabled" ]; then
        read -p "Gemini API Key (必填): " gemini_key
        read -p "Gemini API URL (留空使用官方): " gemini_url
    fi

    # Codex 配置
    echo -e "\n${BOLD}--- Codex CLI 配置 ---${NC}"
    read -p "Codex 模式 [global/disabled] (默认 global): " codex_mode
    codex_mode=${codex_mode:-global}

    if [ "$codex_mode" != "disabled" ]; then
        read -p "Codex API Key (必填): " codex_key
        read -p "Codex API URL (留空使用官方，第三方需加 /v1): " codex_url
    fi

    # 通用配置
    echo -e "\n${BOLD}--- 通用配置 ---${NC}"
    read -p "使用国内镜像加速？[true/false] (默认 true): " use_cn_mirror
    use_cn_mirror=${use_cn_mirror:-true}

    # 写入配置
    cat > .env << EOF
# Linux AI CLI Isolation - 配置文件
# 由安装脚本自动生成

# --- 通用设置 ---
CONDA_ENV_NAME=ai_cli_env
USE_CN_MIRROR=$use_cn_mirror
PROXY_URL=

# --- Claude Code ---
CLAUDE_MODE=$claude_mode
CLAUDE_URL=$claude_url
CLAUDE_KEY=$claude_key
CLAUDE_MODEL=claude-opus-4-5-20251101-thinking
CLAUDE_SMALL_MODEL=claude-sonnet-4-5-20250929

# --- Gemini CLI ---
GEMINI_MODE=$gemini_mode
GEMINI_URL=$gemini_url
GEMINI_KEY=$gemini_key
GEMINI_MODEL=gemini-3-pro-preview

# --- Codex CLI ---
CODEX_MODE=$codex_mode
CODEX_URL=$codex_url
CODEX_KEY=$codex_key
CODEX_MODEL=gpt-5.1-codex-max
CODEX_REASONING_EFFORT=medium
CODEX_WIRE_API=responses
CODEX_NETWORK_ACCESS=enabled
CODEX_DISABLE_RESPONSE_STORAGE=true
EOF

    echo -e "\n${GREEN}   ✅ 配置已保存到 .env${NC}"
}

# ==========================================
# 运行安装
# ==========================================
run_setup() {
    echo -e "\n${BLUE}>>> 运行安装脚本...${NC}"

    cd "$INSTALL_DIR"
    chmod +x setup.sh remove.sh update.sh 2>/dev/null || true

    ./setup.sh
}

# ==========================================
# 完成提示
# ==========================================
show_completion() {
    echo ""
    echo -e "${GREEN}${BOLD}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║                    🎉 安装完成！                           ║${NC}"
    echo -e "${GREEN}${BOLD}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "📁 安装目录: ${GREEN}$INSTALL_DIR${NC}"
    echo ""
    echo -e "${YELLOW}常用命令:${NC}"
    echo -e "  ${GREEN}claude${NC}  - 启动 Claude Code"
    echo -e "  ${GREEN}gemini${NC}  - 启动 Gemini CLI"
    echo -e "  ${GREEN}codex${NC}   - 启动 Codex CLI"
    echo ""
    echo -e "${YELLOW}管理命令:${NC}"
    echo -e "  ${GREEN}cd $INSTALL_DIR && ./update.sh${NC}  - 更新配置"
    echo -e "  ${GREEN}cd $INSTALL_DIR && ./remove.sh${NC}  - 卸载"
    echo ""
}

# ==========================================
# 主流程
# ==========================================
main() {
    check_network
    check_dependencies
    download_project
    configure_env
    run_setup
    show_completion
}

main
