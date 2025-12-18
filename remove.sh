#!/bin/bash

# ==============================================================================
# Script: remove.sh
# Description: Uninstall the environment and cleanup configs.
# ==============================================================================

BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}${BOLD}>>> AI Environment Cleanup Tool${NC}"

# 1. Detect Path
PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CONFIG_CONTAINER_DIR="$PROJECT_ROOT/.ai_tools_config"

read -p "🐍 Conda Env Name to cleanup [default: ai_cli_env]: " CONDA_ENV_NAME
CONDA_ENV_NAME=${CONDA_ENV_NAME:-ai_cli_env}

echo -e "\nCleanup Targets:"
echo -e "  1. Configs: ${RED}$CONFIG_CONTAINER_DIR${NC}"
echo "  2. Env Hooks: $CONDA_ENV_NAME"
echo ""
read -p "❓ Confirm? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then exit 0; fi

# 2. Clean Configs
if [ -d "$CONFIG_CONTAINER_DIR" ]; then
    rm -rf "$CONFIG_CONTAINER_DIR"
    echo -e "${GREEN}✅ Local configs removed.${NC}"
else
    echo "⚠️ Config directory not found, skipping."
fi

# 3. Clean Hooks
if ! command -v conda &> /dev/null; then
    echo "❌ Conda not found, skipping hook cleanup."
else
    source "$(conda info --base)/etc/profile.d/conda.sh"
    if conda info --envs | grep -q "$CONDA_ENV_NAME"; then
        conda activate "$CONDA_ENV_NAME"
        
        npm uninstall -g @anthropic-ai/claude-code 2>/dev/null
        npm uninstall -g @google/gemini-cli 2>/dev/null
        
        CONDA_DIR="$CONDA_PREFIX"
        rm -f "$CONDA_DIR/etc/conda/activate.d/env_hook_isolation.sh"
        rm -f "$CONDA_DIR/etc/conda/deactivate.d/env_hook_isolation.sh"
        
        echo -e "${GREEN}✅ Conda hooks removed.${NC}"
    fi
fi

echo -e "\n${GREEN}🎉 Cleanup Complete.${NC}"