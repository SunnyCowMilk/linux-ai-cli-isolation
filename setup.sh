#!/bin/bash

# ==============================================================================
# Project: linux-ai-cli-isolation
# Script: setup.sh
# Version: v1.0 (Public Release)
# Description: 
#   Deploy isolated Claude Code & Gemini CLI environments on Linux.
#   Features: Asset separation, Conda hooks, and Git-friendly config storage.
# ==============================================================================

BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}${BOLD}>>> Linux AI CLI Isolation Setup Tool${NC}"
echo "----------------------------------------------------------------"

# ==========================================
# [Phase 1] Workspace Initialization
# ==========================================
echo -e "\n${YELLOW}[1/3] Workspace & Environment${NC}"

# 1. Auto-detect project root
PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CONFIG_CONTAINER_DIR="$PROJECT_ROOT/.ai_tools_config"

echo -e "📍 Project Root: ${GREEN}$PROJECT_ROOT${NC}"
echo -e "🔒 Config Path:  $CONFIG_CONTAINER_DIR"

# 2. Setup .gitignore
GITIGNORE_FILE="$PROJECT_ROOT/.gitignore"
if ! grep -q ".ai_tools_config" "$GITIGNORE_FILE" 2>/dev/null; then
    echo ".ai_tools_config/" >> "$GITIGNORE_FILE"
    echo -e "🛡️  Added .ai_tools_config to .gitignore."
else
    echo -e "🛡️  .gitignore check passed."
fi

# 3. Conda Env Name (Default: ai_cli_env)
read -p "🐍 Conda Environment Name [default: ai_cli_env]: " CONDA_ENV_NAME
CONDA_ENV_NAME=${CONDA_ENV_NAME:-ai_cli_env}

# ==========================================
# [Phase 2] API Configuration
# ==========================================
echo -e "\n${YELLOW}[2/3] API Configuration${NC}"
echo "Enter your credentials. Press Enter to use defaults (Official APIs)."

# --- Claude Code ---
echo -e "\n--- Claude Code Configuration ---"

# Default to Official URL, but allow user to input Proxy URL
read -p "🌐 Base URL [default: https://api.anthropic.com]: " CLAUDE_URL
CLAUDE_URL=${CLAUDE_URL:-"https://api.anthropic.com"}

read -p "🔑 API Key (sk-...): " CLAUDE_KEY

# Default to standard official model
read -p "🤖 Model [default: claude-opus-4-5-20251101-thinking]: " CLAUDE_MODEL
CLAUDE_MODEL=${CLAUDE_MODEL:-"claude-opus-4-5-20251101-thinking"}

# --- Gemini CLI ---
echo -e "\n--- Gemini CLI Configuration ---"

# Default to Official URL
read -p "🌐 Base URL [default: https://generativelanguage.googleapis.com]: " GEMINI_URL
GEMINI_URL=${GEMINI_URL:-"https://generativelanguage.googleapis.com"}

read -p "🔑 API Key: " GEMINI_KEY

read -p "🤖 Model [default: gemini-3-pro-preview]: " GEMINI_MODEL
GEMINI_MODEL=${GEMINI_MODEL:-"gemini-3-pro-preview"}

# ==========================================
# [Phase 3] Installation
# ==========================================
echo -e "\n${BLUE}>>> Starting Installation...${NC}"

# Check Conda
if ! command -v conda &> /dev/null; then
    echo -e "${RED}❌ Error: Conda not found.${NC}"; exit 1
fi

# Initialize Directories
mkdir -p "$CONFIG_CONTAINER_DIR/.private_storage"
mkdir -p "$CONFIG_CONTAINER_DIR/.gemini"
mkdir -p "$CONFIG_CONTAINER_DIR/.private_config"
touch "$CONFIG_CONTAINER_DIR/.private_config/npmrc"

# Setup Conda Env
echo -e "🐍 Configuring Conda environment: $CONDA_ENV_NAME..."
source "$(conda info --base)/etc/profile.d/conda.sh"
if ! conda info --envs | grep -q "$CONDA_ENV_NAME"; then
    echo "   -> Creating new environment..."
    conda create -n "$CONDA_ENV_NAME" python=3.10 nodejs -c conda-forge -y
fi
conda activate "$CONDA_ENV_NAME"

# Install CLI Tools
echo -e "📦 Installing NPM packages..."
# Use generic registry or let user configure it. 
# For China users, we can suggest npmmirror, but for global github, default is better.
# However, to be safe, we can just use default registry, or keep npmmirror if your audience is mostly CN.
# Here I use npmmirror as it is generally stable.
npm config set registry https://registry.npmmirror.com
npm install -g @anthropic-ai/claude-code
npm install -g @google/gemini-cli

# ==========================================
# [Phase 4] Asset Separation & Hooks
# ==========================================
echo -e "🔒 Generating Secure Configs..."

# Claude Secrets
SECRETS_FILE="$CONFIG_CONTAINER_DIR/.private_config/secrets.env"
cat << EOF > "$SECRETS_FILE"
export ANTHROPIC_BASE_URL="$CLAUDE_URL"
export ANTHROPIC_API_KEY="$CLAUDE_KEY"
export ANTHROPIC_AUTH_TOKEN="\$ANTHROPIC_API_KEY"
export ANTHROPIC_MODEL="$CLAUDE_MODEL"
export ANTHROPIC_SMALL_FAST_MODEL="claude-3-haiku-20240307"
export MY_GEMINI_KEY="$GEMINI_KEY"
EOF
chmod 600 "$SECRETS_FILE"

# Gemini Config
cat << EOF > "$CONFIG_CONTAINER_DIR/.gemini/.env"
GOOGLE_GEMINI_BASE_URL=$GEMINI_URL
GEMINI_API_KEY=$GEMINI_KEY
GEMINI_MODEL=$GEMINI_MODEL
EOF
echo '{"ide":{"enabled":true},"security":{"auth":{"selectedType":"gemini-api-key"}}}' > "$CONFIG_CONTAINER_DIR/.gemini/settings.json"

# Inject Hooks
echo -e "🔗 Injecting Environment Hooks..."
CONDA_DIR="$CONDA_PREFIX"
mkdir -p "$CONDA_DIR/etc/conda/activate.d"
mkdir -p "$CONDA_DIR/etc/conda/deactivate.d"

# Activate Hook
cat << EOF > "$CONDA_DIR/etc/conda/activate.d/env_hook_isolation.sh"
#!/bin/bash
export AI_CONFIG_ROOT="$PROJECT_ROOT/.ai_tools_config"

if [ -f "\$AI_CONFIG_ROOT/.private_config/secrets.env" ]; then
    source "\$AI_CONFIG_ROOT/.private_config/secrets.env"
fi

export NPM_CONFIG_USERCONFIG="\$AI_CONFIG_ROOT/.private_config/npmrc"
export XDG_CONFIG_HOME="\$AI_CONFIG_ROOT/.private_storage/config"
export XDG_DATA_HOME="\$AI_CONFIG_ROOT/.private_storage/data"
export XDG_STATE_HOME="\$AI_CONFIG_ROOT/.private_storage/state"
export XDG_CACHE_HOME="\$AI_CONFIG_ROOT/.private_storage/cache"

alias gemini="HOME=\$AI_CONFIG_ROOT gemini"
EOF

# Deactivate Hook
cat << EOF > "$CONDA_DIR/etc/conda/deactivate.d/env_hook_isolation.sh"
#!/bin/bash
unset AI_CONFIG_ROOT NPM_CONFIG_USERCONFIG
unset XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME XDG_CACHE_HOME
unset ANTHROPIC_BASE_URL ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN ANTHROPIC_MODEL ANTHROPIC_SMALL_FAST_MODEL
unset MY_GEMINI_KEY
unalias gemini 2>/dev/null
EOF

echo -e "\n${GREEN}✅ Setup Complete!${NC}"
echo "----------------------------------------------------------------"
echo "Configuration saved to: $CONFIG_CONTAINER_DIR"
echo "----------------------------------------------------------------"
echo "👉 Please run: conda deactivate && conda activate $CONDA_ENV_NAME"