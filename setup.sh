#!/bin/bash
# ==============================================================================
# Script: setup.sh
# Version: v9.1
# Description: Deploy isolated AI environments using current directory as storage.
# ==============================================================================
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}${BOLD}>>> Linux AI CLI Isolation Setup Tool v9.1${NC}"
echo "----------------------------------------------------------------"

# ==========================================
# [Phase 0] Initialization
# ==========================================
PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CONFIG_CONTAINER_DIR="$PROJECT_ROOT/.ai_tools_config"

echo -e "📍 Project Root: ${GREEN}$PROJECT_ROOT${NC}"
echo -e "🔒 Config Storage: ${GREEN}$CONFIG_CONTAINER_DIR${NC}"

# Setup .gitignore
GITIGNORE_FILE="$PROJECT_ROOT/.gitignore"
touch "$GITIGNORE_FILE"
if ! grep -qxF ".ai_tools_config/" "$GITIGNORE_FILE"; then
    echo ".ai_tools_config/" >> "$GITIGNORE_FILE"
    echo -e "🛡️  Added .ai_tools_config/ to .gitignore"
fi
if ! grep -qxF ".env" "$GITIGNORE_FILE"; then
    echo ".env" >> "$GITIGNORE_FILE"
    echo -e "🛡️  Added .env to .gitignore"
fi

# Load .env Configuration
if [ -f "$PROJECT_ROOT/.env" ]; then
    echo -e "${GREEN}📄 Loading configuration from .env...${NC}"
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
else
    echo -e "${YELLOW}⚠️  No .env file found. Switching to interactive mode.${NC}"
fi

# ==========================================
# [Phase 1] Configuration Check
# ==========================================
echo -e "\n${YELLOW}[1/2] Configuration${NC}"

# 1. Conda Env
if [ -z "$CONDA_ENV_NAME" ]; then
    read -p "🐍 Conda Environment Name [default: ai_cli_env]: " CONDA_ENV_NAME
fi
CONDA_ENV_NAME=${CONDA_ENV_NAME:-ai_cli_env}

# 2. Mirror Settings
if [ -z "$USE_CN_MIRROR" ]; then
    read -p "🌏 Use China mirrors for Conda/NPM? (y/n) [default: n]: " USE_CN_MIRROR_INPUT
    if [[ "$USE_CN_MIRROR_INPUT" =~ ^[Yy]$ ]]; then
        USE_CN_MIRROR=true
    else
        USE_CN_MIRROR=false
    fi
fi

if [ "$USE_CN_MIRROR" = "true" ]; then
    echo -e "${GREEN}🚀 Using China mirrors (Tsinghua + npmmirror)${NC}"
    CONDA_CHANNEL="https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge"
    NPM_REGISTRY="https://registry.npmmirror.com"
else
    CONDA_CHANNEL="conda-forge"
    NPM_REGISTRY="https://registry.npmjs.org"
fi

# 3. Proxy Settings
if [ -z "$PROXY_URL" ]; then
    read -p "🌐 Proxy URL (leave empty if not needed): " PROXY_URL
fi

# 4. Claude Config
if [ -z "$CLAUDE_URL" ]; then read -p "🌐 Claude URL [default: https://api.anthropic.com]: " CLAUDE_URL; fi
CLAUDE_URL=${CLAUDE_URL:-"https://api.anthropic.com"}

while [ -z "$CLAUDE_KEY" ]; do
    read -p "🔑 Enter Claude API Key: " CLAUDE_KEY
done

if [ -z "$CLAUDE_MODEL" ]; then
    read -p "🤖 Claude Main Model [default: claude-opus-4-5-20251101-thinking]: " CLAUDE_MODEL
fi
CLAUDE_MODEL=${CLAUDE_MODEL:-"claude-opus-4-5-20251101-thinking"}

if [ -z "$CLAUDE_SMALL_MODEL" ]; then
    read -p "🤖 Claude Small Model [default: claude-haiku-4-5-20251001]: " CLAUDE_SMALL_MODEL
fi
CLAUDE_SMALL_MODEL=${CLAUDE_SMALL_MODEL:-"claude-haiku-4-5-20251001"}

# 5. Gemini Config
if [ -z "$GEMINI_URL" ]; then 
    read -p "🌐 Gemini URL [default: https://generativelanguage.googleapis.com]: " GEMINI_URL
fi
GEMINI_URL=${GEMINI_URL:-"https://generativelanguage.googleapis.com"}

while [ -z "$GEMINI_KEY" ]; do
    read -p "🔑 Enter Gemini API Key: " GEMINI_KEY
done

if [ -z "$GEMINI_MODEL" ]; then 
    read -p "🤖 Gemini Model [default: gemini-3-pro-preview]: " GEMINI_MODEL
fi
GEMINI_MODEL=${GEMINI_MODEL:-"gemini-3-pro-preview"}

# ==========================================
# [Phase 2] Installation
# ==========================================
echo -e "\n${BLUE}>>> Starting Installation...${NC}"

if ! command -v conda &> /dev/null; then
    echo -e "${RED}❌ Error: Conda not found.${NC}"; exit 1
fi

# Create Config Dirs
echo -e "📁 Creating config directories..."
mkdir -p "$CONFIG_CONTAINER_DIR/.private_storage/config"
mkdir -p "$CONFIG_CONTAINER_DIR/.private_storage/data"
mkdir -p "$CONFIG_CONTAINER_DIR/.private_storage/state"
mkdir -p "$CONFIG_CONTAINER_DIR/.private_storage/cache"
mkdir -p "$CONFIG_CONTAINER_DIR/.gemini"
mkdir -p "$CONFIG_CONTAINER_DIR/.private_config"

# Create project-level .npmrc
NPMRC_FILE="$CONFIG_CONTAINER_DIR/.private_config/npmrc"
cat << EOF > "$NPMRC_FILE"
registry=$NPM_REGISTRY
EOF
echo -e "📦 NPM Registry: $NPM_REGISTRY"

# Initialize Conda Shell
source "$(conda info --base)/etc/profile.d/conda.sh"

echo -e "🐍 Configuring Conda environment: $CONDA_ENV_NAME..."
echo -e "📦 Conda Channel: $CONDA_CHANNEL"
TARGET_NODE_VERSION=24

conda_env_exists() {
    conda info --envs | awk '{print $1}' | grep -qx "$1"
}

if conda_env_exists "$CONDA_ENV_NAME"; then
    echo -e "   -> Environment found. Checking Node.js version..."
    conda activate "$CONDA_ENV_NAME"
    
    if command -v node &> /dev/null; then
        CURRENT_NODE_VER=$(node -v 2>/dev/null | sed 's/^v//' | cut -d'.' -f1)
        
        if [[ "$CURRENT_NODE_VER" =~ ^[0-9]+$ ]]; then
            if [ "$CURRENT_NODE_VER" -lt "$TARGET_NODE_VERSION" ]; then
                echo -e "${YELLOW}⚠️  Current Node.js (v$CURRENT_NODE_VER) < v$TARGET_NODE_VERSION${NC}"
                echo -e "📦 Upgrading Node.js..."
                conda install "nodejs>=$TARGET_NODE_VERSION" -c "$CONDA_CHANNEL" -y
            else
                echo -e "${GREEN}✅ Node.js v$CURRENT_NODE_VER OK${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  Cannot determine Node.js version. Reinstalling...${NC}"
            conda install "nodejs>=$TARGET_NODE_VERSION" -c "$CONDA_CHANNEL" -y
        fi
    else
        echo -e "${YELLOW}⚠️  Node.js not found. Installing...${NC}"
        conda install "nodejs>=$TARGET_NODE_VERSION" -c "$CONDA_CHANNEL" -y
    fi
else
    echo -e "   -> Creating new environment..."
    conda create -n "$CONDA_ENV_NAME" python=3.10 "nodejs>=$TARGET_NODE_VERSION" -c "$CONDA_CHANNEL" -y
    conda activate "$CONDA_ENV_NAME"
fi

if [[ "$CONDA_DEFAULT_ENV" != "$CONDA_ENV_NAME" ]]; then
    conda activate "$CONDA_ENV_NAME"
fi

# Install Tools
echo -e "📦 Installing NPM packages..."
export NPM_CONFIG_USERCONFIG="$NPMRC_FILE"
npm install -g @anthropic-ai/claude-code
npm install -g @google/gemini-cli

# ==========================================
# [Phase 3] Generate Config Files
# ==========================================
echo -e "\n${BLUE}>>> Generating Config Files...${NC}"

# === Combined Secrets File (Claude + Gemini) ===
SECRETS_FILE="$CONFIG_CONTAINER_DIR/.private_config/secrets.env"
cat << EOF > "$SECRETS_FILE"
# ==========================================
# Claude Config
# ==========================================
export ANTHROPIC_BASE_URL="$CLAUDE_URL"
export ANTHROPIC_API_KEY="$CLAUDE_KEY"
export ANTHROPIC_AUTH_TOKEN="$CLAUDE_KEY"
export ANTHROPIC_MODEL="$CLAUDE_MODEL"
export ANTHROPIC_SMALL_FAST_MODEL="$CLAUDE_SMALL_MODEL"

# ==========================================
# Gemini Config
# ==========================================
export GOOGLE_GEMINI_BASE_URL="$GEMINI_URL"
export GEMINI_API_KEY="$GEMINI_KEY"
export GOOGLE_API_KEY="$GEMINI_KEY"
export GEMINI_MODEL="$GEMINI_MODEL"
EOF
chmod 600 "$SECRETS_FILE"
echo -e "${GREEN}✅ Secrets file: $SECRETS_FILE${NC}"

# === Gemini settings.json ===
GEMINI_DIR="$CONFIG_CONTAINER_DIR/.gemini"
cat << EOF > "$GEMINI_DIR/settings.json"
{
  "ide": {
    "enabled": true
  },
  "security": {
    "auth": {
      "selectedType": "gemini-api-key"
    }
  }
}
EOF
echo -e "${GREEN}✅ Gemini settings: $GEMINI_DIR/settings.json${NC}"

# ==========================================
# [Phase 4] Inject Conda Hooks
# ==========================================
echo -e "\n${BLUE}>>> Injecting Conda Hooks...${NC}"

CONDA_DIR="$CONDA_PREFIX"
mkdir -p "$CONDA_DIR/etc/conda/activate.d"
mkdir -p "$CONDA_DIR/etc/conda/deactivate.d"

# Build proxy export commands
PROXY_EXPORTS=""
PROXY_UNSETS=""
if [ -n "$PROXY_URL" ]; then
    PROXY_EXPORTS="
# Proxy settings
export HTTP_PROXY=\"$PROXY_URL\"
export HTTPS_PROXY=\"$PROXY_URL\"
export ALL_PROXY=\"$PROXY_URL\"
export http_proxy=\"$PROXY_URL\"
export https_proxy=\"$PROXY_URL\"
"
    PROXY_UNSETS="unset HTTP_PROXY HTTPS_PROXY ALL_PROXY http_proxy https_proxy"
fi

# === Activate Hook ===
cat << EOF > "$CONDA_DIR/etc/conda/activate.d/env_hook_isolation.sh"
#!/bin/bash
# Auto-generated by setup.sh v9.1

# Project config root
export AI_CONFIG_ROOT="$CONFIG_CONTAINER_DIR"

# Load ALL secrets (Claude + Gemini)
if [ -f "$SECRETS_FILE" ]; then
    source "$SECRETS_FILE"
fi
$PROXY_EXPORTS
# NPM isolation
export NPM_CONFIG_USERCONFIG="$NPMRC_FILE"

# XDG isolation
export XDG_CONFIG_HOME="$CONFIG_CONTAINER_DIR/.private_storage/config"
export XDG_DATA_HOME="$CONFIG_CONTAINER_DIR/.private_storage/data"
export XDG_STATE_HOME="$CONFIG_CONTAINER_DIR/.private_storage/state"
export XDG_CACHE_HOME="$CONFIG_CONTAINER_DIR/.private_storage/cache"

# Gemini data isolation
export GEMINI_HOME="$GEMINI_DIR"

echo "🤖 AI CLI environment activated"
echo "   Config: \$AI_CONFIG_ROOT"
EOF

echo -e "${GREEN}✅ Activate hook created${NC}"

# === Deactivate Hook ===
cat << EOF > "$CONDA_DIR/etc/conda/deactivate.d/env_hook_isolation.sh"
#!/bin/bash
# Auto-generated by setup.sh v9.1

# Claude vars
unset ANTHROPIC_BASE_URL ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN
unset ANTHROPIC_MODEL ANTHROPIC_SMALL_FAST_MODEL

# Gemini vars
unset GOOGLE_GEMINI_BASE_URL GEMINI_API_KEY GOOGLE_API_KEY GEMINI_MODEL
unset GEMINI_HOME

# Other vars
unset AI_CONFIG_ROOT NPM_CONFIG_USERCONFIG
unset XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME XDG_CACHE_HOME
$PROXY_UNSETS

echo "🔌 AI CLI environment deactivated"
EOF

echo -e "${GREEN}✅ Deactivate hook created${NC}"

# ==========================================
# [Phase 5] Final Summary
# ==========================================
echo -e "\n${GREEN}${BOLD}========================================${NC}"
echo -e "${GREEN}${BOLD}✅ Setup Complete!${NC}"
echo -e "${GREEN}${BOLD}========================================${NC}"
echo ""
echo -e "🔧 Next Steps:"
echo -e "   ${YELLOW}1. conda deactivate${NC}"
echo -e "   ${YELLOW}2. conda activate $CONDA_ENV_NAME${NC}"
echo ""
echo -e "📝 Test commands:"
echo -e "   ${BLUE}claude${NC}  - Start Claude Code"
echo -e "   ${BLUE}gemini${NC} - Start Gemini CLI"
echo ""
echo -e "🔍 Verify env vars after activation:"
echo -e "   echo \$GEMINI_API_KEY"
echo -e "   echo \$GOOGLE_GEMINI_BASE_URL"