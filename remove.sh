#!/bin/bash
# ==============================================================================
# Script: remove.sh
# Version: v11.0
# Description: Cleanup local configs and conda hooks.
# ==============================================================================

BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}${BOLD}>>> AI Environment Cleanup Tool${NC}"
PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CONFIG_CONTAINER_DIR="$PROJECT_ROOT/.ai_tools_config"

if [ -f "$PROJECT_ROOT/.env" ]; then set -a; source "$PROJECT_ROOT/.env"; set +a; fi
CONDA_ENV_NAME=${CONDA_ENV_NAME:-ai_cli_env}

echo -e "\nCleanup Targets:"
echo -e "  1. Project Local Configs: ${RED}$CONFIG_CONTAINER_DIR${NC}"
echo -e "  2. Conda Hooks:           $CONDA_ENV_NAME"
echo ""
read -p "❓ Remove Project Configs? (y/n): " CONFIRM_PROJ
if [[ "$CONFIRM_PROJ" == "y" ]]; then
    rm -rf "$CONFIG_CONTAINER_DIR"
    echo -e "${GREEN}✅ Local configs removed.${NC}"
fi

# Clean Hooks
if command -v conda &> /dev/null; then
    source "$(conda info --base)/etc/profile.d/conda.sh"
    if conda info --envs | grep -q "$CONDA_ENV_NAME"; then
        conda activate "$CONDA_ENV_NAME"
        CONDA_DIR="$CONDA_PREFIX"
        rm -f "$CONDA_DIR/etc/conda/activate.d/env_hook_isolation.sh"
        rm -f "$CONDA_DIR/etc/conda/deactivate.d/env_hook_isolation.sh"
        echo -e "${GREEN}✅ Conda hooks removed.${NC}"
        
        read -p "❓ Uninstall NPM packages (claude/gemini/codex)? (y/n): " CONFIRM_NPM
        if [[ "$CONFIRM_NPM" == "y" ]]; then
            npm uninstall -g @anthropic-ai/claude-code @google/gemini-cli 2>/dev/null
            echo -e "${GREEN}✅ NPM packages uninstalled.${NC}"
        fi
    fi
fi

echo ""
echo -e "${YELLOW}⚠️  Codex Configuration is stored in ~/.codex (Global)${NC}"
read -p "❓ Remove ~/.codex directory? (y/n) [Be careful!]: " CONFIRM_CODEX
if [[ "$CONFIRM_CODEX" == "y" ]]; then
    rm -rf "$HOME/.codex"
    echo -e "${GREEN}✅ ~/.codex removed.${NC}"
fi

echo -e "\n${GREEN}🎉 Cleanup Complete.${NC}"