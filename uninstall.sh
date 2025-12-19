#!/bin/bash
# ==============================================================================
# Linux AI CLI Isolation - 一键卸载脚本
#
# 使用方法:
#   curl -fsSL https://raw.githubusercontent.com/SunnyCowMilk/linux-ai-cli-isolation/main/uninstall.sh | bash
#
# 国内用户:
#   curl -fsSL https://ghproxy.com/https://raw.githubusercontent.com/SunnyCowMilk/linux-ai-cli-isolation/main/uninstall.sh | bash
# ==============================================================================

set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

INSTALL_DIR="$HOME/linux-ai-cli-isolation"

echo -e "${BLUE}${BOLD}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║       Linux AI CLI Isolation - 一键卸载脚本               ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ==========================================
# 检查安装目录
# ==========================================
if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}⚠️  未找到安装目录: $INSTALL_DIR${NC}"
    echo -e "${YELLOW}   可能已卸载或安装在其他位置${NC}"
    echo ""
    echo -e "如果安装在其他位置，请手动运行:"
    echo -e "  ${GREEN}cd <安装目录> && ./remove.sh${NC}"
    exit 1
fi

# ==========================================
# 确认卸载
# ==========================================
echo -e "${YELLOW}即将卸载 AI CLI 工具，包括:${NC}"
echo -e "  - Claude Code"
echo -e "  - Gemini CLI"
echo -e "  - Codex CLI"
echo ""
read -p "确认卸载？(y/N): " confirm

if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo -e "${BLUE}已取消卸载${NC}"
    exit 0
fi

# ==========================================
# 运行卸载脚本
# ==========================================
echo -e "\n${BLUE}>>> 运行卸载脚本...${NC}"

cd "$INSTALL_DIR"

if [ -f "remove.sh" ]; then
    chmod +x remove.sh
    ./remove.sh
else
    echo -e "${YELLOW}⚠️  remove.sh 不存在，执行手动清理${NC}"
fi

# ==========================================
# 询问是否删除安装目录
# ==========================================
echo ""
read -p "是否删除安装目录 $INSTALL_DIR？(y/N): " delete_dir

if [ "$delete_dir" = "y" ] || [ "$delete_dir" = "Y" ]; then
    rm -rf "$INSTALL_DIR"
    echo -e "${GREEN}✅ 安装目录已删除${NC}"
fi

# ==========================================
# 完成
# ==========================================
echo ""
echo -e "${GREEN}${BOLD}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║                    🗑️  卸载完成！                          ║${NC}"
echo -e "${GREEN}${BOLD}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}提示:${NC}"
echo -e "  - 重启终端或运行 ${GREEN}source ~/.bashrc${NC} 使更改生效"
echo -e "  - 如需重新安装，运行一键安装命令即可"
echo ""
