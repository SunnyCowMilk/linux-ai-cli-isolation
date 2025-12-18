#!/bin/bash
# ==============================================================================
# Script: remove.sh
# Version: v12.0
# Description: Cleanup AI CLI configurations (supports isolated and global modes)
# ==============================================================================

BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${RED}${BOLD}>>> AI Environment Cleanup Tool v12.0${NC}"
echo "----------------------------------------------------------------"

PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CONFIG_CONTAINER_DIR="$PROJECT_ROOT/.ai_tools_config"

# Load .env if exists
if [ -f "$PROJECT_ROOT/.env" ]; then
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
fi

CONDA_ENV_NAME=${CONDA_ENV_NAME:-ai_cli_env}

echo -e "\n${BLUE}>>> Cleanup Options${NC}"
echo ""

# ==========================================
# [1] Project Local Configs (isolated mode)
# ==========================================
if [ -d "$CONFIG_CONTAINER_DIR" ]; then
    echo -e "📁 Found project configs: ${YELLOW}$CONFIG_CONTAINER_DIR${NC}"
    read -p "   Remove project-local configs? (y/n): " CONFIRM_PROJ
    if [[ "$CONFIRM_PROJ" == "y" ]]; then
        rm -rf "$CONFIG_CONTAINER_DIR"
        echo -e "   ${GREEN}✅ Project configs removed${NC}"
    fi
else
    echo -e "📁 No project-local configs found"
fi

# ==========================================
# [2] Global Configs
# ==========================================
echo ""
echo -e "🌐 ${BLUE}Global configurations:${NC}"

# Claude global config
if [ -f "$HOME/.claude_env" ]; then
    echo -e "   Found: ${YELLOW}~/.claude_env${NC}"
    read -p "   Remove Claude global config? (y/n): " CONFIRM_CLAUDE
    if [[ "$CONFIRM_CLAUDE" == "y" ]]; then
        rm -f "$HOME/.claude_env"
        echo -e "   ${GREEN}✅ ~/.claude_env removed${NC}"
    fi
fi

# Gemini global config
if [ -f "$HOME/.gemini_env" ] || [ -d "$HOME/.gemini" ]; then
    [ -f "$HOME/.gemini_env" ] && echo -e "   Found: ${YELLOW}~/.gemini_env${NC}"
    [ -d "$HOME/.gemini" ] && echo -e "   Found: ${YELLOW}~/.gemini/${NC}"
    read -p "   Remove Gemini global configs? (y/n): " CONFIRM_GEMINI
    if [[ "$CONFIRM_GEMINI" == "y" ]]; then
        rm -f "$HOME/.gemini_env"
        rm -rf "$HOME/.gemini"
        echo -e "   ${GREEN}✅ Gemini configs removed${NC}"
    fi
fi

# Codex global config
if [ -d "$HOME/.codex" ]; then
    echo -e "   Found: ${YELLOW}~/.codex/${NC}"
    read -p "   Remove Codex global config? (y/n): " CONFIRM_CODEX
    if [[ "$CONFIRM_CODEX" == "y" ]]; then
        rm -rf "$HOME/.codex"
        echo -e "   ${GREEN}✅ ~/.codex removed${NC}"
    fi
fi

# ==========================================
# [3] Conda Hooks
# ==========================================
echo ""
if command -v conda &> /dev/null; then
    source "$(conda info --base)/etc/profile.d/conda.sh"
    if conda info --envs | grep -q "$CONDA_ENV_NAME"; then
        echo -e "🐍 Found Conda environment: ${YELLOW}$CONDA_ENV_NAME${NC}"

        read -p "   Remove Conda hooks? (y/n): " CONFIRM_HOOKS
        if [[ "$CONFIRM_HOOKS" == "y" ]]; then
            conda activate "$CONDA_ENV_NAME"
            CONDA_DIR="$CONDA_PREFIX"
            rm -f "$CONDA_DIR/etc/conda/activate.d/env_hook_isolation.sh"
            rm -f "$CONDA_DIR/etc/conda/deactivate.d/env_hook_isolation.sh"
            echo -e "   ${GREEN}✅ Conda hooks removed${NC}"
        fi

        read -p "   Uninstall NPM packages (claude-code, gemini-cli)? (y/n): " CONFIRM_NPM
        if [[ "$CONFIRM_NPM" == "y" ]]; then
            conda activate "$CONDA_ENV_NAME"
            npm uninstall -g @anthropic-ai/claude-code @google/gemini-cli 2>/dev/null
            echo -e "   ${GREEN}✅ NPM packages uninstalled${NC}"
        fi

        read -p "   ${RED}Delete entire Conda environment '$CONDA_ENV_NAME'? (y/n): ${NC}" CONFIRM_ENV
        if [[ "$CONFIRM_ENV" == "y" ]]; then
            conda deactivate 2>/dev/null
            conda remove -n "$CONDA_ENV_NAME" --all -y
            echo -e "   ${GREEN}✅ Conda environment removed${NC}"
        fi
    else
        echo -e "🐍 Conda environment '$CONDA_ENV_NAME' not found"
    fi
else
    echo -e "🐍 Conda not installed, skipping Conda cleanup"
fi

# ==========================================
# Summary
# ==========================================
echo ""
echo -e "${GREEN}🎉 Cleanup Complete!${NC}"
echo "----------------------------------------------------------------"
echo -e "${YELLOW}Note: If you added 'source ~/.claude_env' or 'source ~/.gemini_env'"
echo -e "to your shell profile, please remove those lines manually.${NC}"
