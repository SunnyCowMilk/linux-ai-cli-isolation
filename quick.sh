#!/bin/bash
# ==============================================================================
# Linux AI CLI Isolation - 快速管理脚本
#
# 使用方法:
#   curl -fsSL https://raw.githubusercontent.com/SunnyCowMilk/linux-ai-cli-isolation/main/quick.sh | bash
#
# 国内用户:
#   curl -fsSL https://ghproxy.com/https://raw.githubusercontent.com/SunnyCowMilk/linux-ai-cli-isolation/main/quick.sh | bash
#
# 直接指定操作:
#   curl ... | bash -s -- install    # 直接安装
#   curl ... | bash -s -- uninstall  # 直接卸载
#   curl ... | bash -s -- update     # 更新配置
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
# 检测网络环境
# ==========================================
check_network() {
    echo -e "${BLUE}>>> 检测网络环境...${NC}"
    if curl -s --connect-timeout 5 https://github.com > /dev/null 2>&1; then
        echo -e "${GREEN}   ✅ 可直接访问 GitHub${NC}"
        USE_PROXY=false
    else
        echo -e "${YELLOW}   ⚠️  无法直接访问 GitHub，使用加速镜像${NC}"
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
        read -p "   是否删除并重新下载？(y/N): " confirm
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            rm -rf "$INSTALL_DIR"
        else
            echo -e "${BLUE}   使用现有目录${NC}"
            return 0
        fi
    fi

    if [ "$USE_PROXY" = true ]; then
        echo -e "   使用加速镜像下载..."
        git clone "$REPO_URL_CN" "$INSTALL_DIR" 2>/dev/null || {
            echo -e "${YELLOW}   加速镜像失败，尝试直接下载...${NC}"
            git clone "$REPO_URL" "$INSTALL_DIR"
        }
    else
        git clone "$REPO_URL" "$INSTALL_DIR"
    fi

    echo -e "${GREEN}   ✅ 下载完成${NC}"
}

# ==========================================
# 交互式配置
# ==========================================
interactive_config() {
    echo -e "\n${BLUE}>>> 交互式配置${NC}"
    echo -e "${YELLOW}提示: 留空使用默认值，按 Enter 跳过${NC}\n"

    echo -e "${BOLD}选择配置模式:${NC}"
    echo -e "  ${GREEN}global${NC}   - 全局配置（推荐个人电脑/WSL）"
    echo -e "  ${GREEN}isolated${NC} - 项目级隔离（需要 Conda）"
    echo -e "  ${GREEN}disabled${NC} - 禁用该服务"
    echo ""

    # Claude 配置
    echo -e "${BOLD}--- Claude Code ---${NC}"
    read -p "模式 [global/isolated/disabled] (默认 global): " claude_mode
    claude_mode=${claude_mode:-global}
    if [ "$claude_mode" != "disabled" ]; then
        read -p "API Key (必填): " claude_key
        read -p "API URL (留空使用官方): " claude_url
    fi

    # Gemini 配置
    echo -e "\n${BOLD}--- Gemini CLI ---${NC}"
    read -p "模式 [global/isolated/disabled] (默认 global): " gemini_mode
    gemini_mode=${gemini_mode:-global}
    if [ "$gemini_mode" != "disabled" ]; then
        read -p "API Key (必填): " gemini_key
        read -p "API URL (留空使用官方): " gemini_url
    fi

    # Codex 配置
    echo -e "\n${BOLD}--- Codex CLI ---${NC}"
    read -p "模式 [global/disabled] (默认 global): " codex_mode
    codex_mode=${codex_mode:-global}
    if [ "$codex_mode" != "disabled" ]; then
        read -p "API Key (必填): " codex_key
        read -p "API URL (留空使用官方): " codex_url
    fi

    # 通用配置
    echo -e "\n${BOLD}--- 通用配置 ---${NC}"
    read -p "使用国内镜像？[true/false] (默认 true): " use_cn_mirror
    use_cn_mirror=${use_cn_mirror:-true}

    # 写入配置
    cat > "$INSTALL_DIR/.env" << EOF
# Linux AI CLI Isolation - 配置文件 (自动生成)

CONDA_ENV_NAME=ai_cli_env
USE_CN_MIRROR=$use_cn_mirror
PROXY_URL=

CLAUDE_MODE=$claude_mode
CLAUDE_URL=$claude_url
CLAUDE_KEY=$claude_key
CLAUDE_MODEL=claude-opus-4-5-20251101-thinking
CLAUDE_SMALL_MODEL=claude-sonnet-4-5-20250929

GEMINI_MODE=$gemini_mode
GEMINI_URL=$gemini_url
GEMINI_KEY=$gemini_key
GEMINI_MODEL=gemini-3-pro-preview

CODEX_MODE=$codex_mode
CODEX_URL=$codex_url
CODEX_KEY=$codex_key
CODEX_MODEL=gpt-5.1-codex-max
CODEX_REASONING_EFFORT=medium
CODEX_WIRE_API=responses
CODEX_NETWORK_ACCESS=enabled
CODEX_DISABLE_RESPONSE_STORAGE=true
EOF

    echo -e "\n${GREEN}   ✅ 配置已保存${NC}"
}

# ==========================================
# 安装
# ==========================================
do_install() {
    show_banner
    check_network
    check_dependencies
    download_project

    echo -e "\n${YELLOW}请选择配置方式:${NC}"
    echo -e "  ${GREEN}1)${NC} 交互式配置（推荐新手）"
    echo -e "  ${GREEN}2)${NC} 手动编辑 .env 文件"
    echo -e "  ${GREEN}3)${NC} 使用默认配置"
    echo ""
    read -p "请选择 [1-3]: " config_choice

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

    echo ""
    echo -e "${GREEN}${BOLD}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║                    🎉 安装完成！                           ║${NC}"
    echo -e "${GREEN}${BOLD}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "📁 安装目录: ${GREEN}$INSTALL_DIR${NC}"
    echo ""
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
    read -p "确认卸载？(y/N): " confirm
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

    read -p "是否删除安装目录？(y/N): " delete_dir
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
    read -p "请选择 [1-2]: " update_choice

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
    echo -e "  ${GREEN}2)${NC} 卸载 AI CLI 工具"
    echo -e "  ${GREEN}3)${NC} 更新配置"
    echo -e "  ${GREEN}0)${NC} 退出"
    echo ""
    read -p "请选择 [0-3]: " choice

    case $choice in
        1) do_install ;;
        2) do_uninstall ;;
        3) do_update ;;
        0) echo "再见！"; exit 0 ;;
        *) echo -e "${RED}无效选择${NC}"; exit 1 ;;
    esac
}

# ==========================================
# 主入口
# ==========================================
main() {
    case "${1:-}" in
        install)   do_install ;;
        uninstall) do_uninstall ;;
        update)    do_update ;;
        *)         show_menu ;;
    esac
}

main "$@"
