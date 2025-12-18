#!/bin/bash
# ==============================================================================
# Script: setup.sh
# Version: v11.0 (Simple Codex)
# Description: Deploy AI environments. Claude/Gemini isolated, Codex global (~/.codex).
# ==============================================================================

BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}${BOLD}>>> Linux AI CLI Setup Tool v11.0${NC}"
echo "----------------------------------------------------------------"

# ==========================================
# [Phase 0] Initialization
# ==========================================
PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CONFIG_CONTAINER_DIR="$PROJECT_ROOT/.ai_tools_config"

echo -e "📍 Project Root: ${GREEN}$PROJECT_ROOT${NC}"

# Setup .gitignore
GITIGNORE_FILE="$PROJECT_ROOT/.gitignore"
touch "$GITIGNORE_FILE"
if ! grep -qxF ".ai_tools_config/" "$GITIGNORE_FILE"; then echo ".ai_tools_config/" >> "$GITIGNORE_FILE"; fi
if ! grep -qxF ".env" "$GITIGNORE_FILE"; then echo ".env" >> "$GITIGNORE_FILE"; fi

# Load .env Configuration
if [ -f "$PROJECT_ROOT/.env" ]; then
    echo -e "${GREEN}📄 Loading configuration from .env...${NC}"
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
else
    echo -e "${RED}❌ No .env file found! Please cp .env.example .env first.${NC}"
    exit 1
fi

# ==========================================
# [Phase 1] Configuration Check & Defaults
# ==========================================
# Set defaults if not present in .env (though they should be)
CONDA_ENV_NAME=${CONDA_ENV_NAME:-ai_cli_env}
CLAUDE_URL=${CLAUDE_URL:-"https://api.anthropic.com"}
CLAUDE_MODEL=${CLAUDE_MODEL:-"claude-opus-4-5-20251101-thinking"}
CLAUDE_SMALL_MODEL=${CLAUDE_SMALL_MODEL:-"claude-haiku-4-5-20251001"}
GEMINI_URL=${GEMINI_URL:-"https://generativelanguage.googleapis.com"}
GEMINI_MODEL=${GEMINI_MODEL:-"gemini-3-pro-preview"}
CODEX_URL=${CODEX_URL:-"https://api.openai.com/v1"}
CODEX_MODEL_PROVIDER=${CODEX_MODEL_PROVIDER:-"openai"}
CODEX_MODEL=${CODEX_MODEL:-"gpt-5.1-codex-max"}
CODEX_REASONING_EFFORT=${CODEX_REASONING_EFFORT:-"medium"}
CODEX_WIRE_API=${CODEX_WIRE_API:-"responses"}
CODEX_NETWORK_ACCESS=${CODEX_NETWORK_ACCESS:-"enabled"}
CODEX_DISABLE_RESPONSE_STORAGE=${CODEX_DISABLE_RESPONSE_STORAGE:-"true"}

# Check Keys
if [ -z "$CLAUDE_KEY" ]; then read -p "🔑 Enter Claude API Key: " CLAUDE_KEY; fi
if [ -z "$GEMINI_KEY" ]; then read -p "🔑 Enter Gemini API Key: " GEMINI_KEY; fi
if [ -z "$CODEX_KEY" ]; then read -p "🔑 Enter Codex API Key: " CODEX_KEY; fi

# Mirror Settings
if [ "$USE_CN_MIRROR" = "true" ]; then
    CONDA_CHANNEL="https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge"
    NPM_REGISTRY="https://registry.npmmirror.com"
else
    CONDA_CHANNEL="conda-forge"
    NPM_REGISTRY="https://registry.npmjs.org"
fi

# ==========================================
# [Phase 2] Installation
# ==========================================
echo -e "\n${BLUE}>>> Starting Installation...${NC}"

if ! command -v conda &> /dev/null; then echo -e "${RED}❌ Conda not found.${NC}"; exit 1; fi

# Create Config Dirs (Isolated for Claude/Gemini)
mkdir -p "$CONFIG_CONTAINER_DIR/.private_storage/config"
mkdir -p "$CONFIG_CONTAINER_DIR/.private_storage/data"
mkdir -p "$CONFIG_CONTAINER_DIR/.private_storage/state"
mkdir -p "$CONFIG_CONTAINER_DIR/.private_storage/cache"
mkdir -p "$CONFIG_CONTAINER_DIR/.gemini"
mkdir -p "$CONFIG_CONTAINER_DIR/.private_config"

# NPM Registry
NPMRC_FILE="$CONFIG_CONTAINER_DIR/.private_config/npmrc"
echo "registry=$NPM_REGISTRY" > "$NPMRC_FILE"

# Conda Setup
source "$(conda info --base)/etc/profile.d/conda.sh"
TARGET_NODE_VERSION=24
echo -e "🐍 Configuring Conda environment: $CONDA_ENV_NAME..."

conda_env_exists() { conda info --envs | awk '{print $1}' | grep -qx "$1"; }

if conda_env_exists "$CONDA_ENV_NAME"; then
    conda activate "$CONDA_ENV_NAME"
    if ! command -v node &> /dev/null; then
        conda install "nodejs>=$TARGET_NODE_VERSION" -c "$CONDA_CHANNEL" -y
    fi
else
    conda create -n "$CONDA_ENV_NAME" python=3.10 "nodejs>=$TARGET_NODE_VERSION" -c "$CONDA_CHANNEL" -y
    conda activate "$CONDA_ENV_NAME"
fi

# Install Tools
echo -e "📦 Installing NPM packages..."
export NPM_CONFIG_USERCONFIG="$NPMRC_FILE"
npm install -g @anthropic-ai/claude-code
npm install -g @google/gemini-cli
# codex usually comes as a binary or specific package, adjust if needed:
# npm install -g codex 2>/dev/null || echo "⚠️  Skipping npm install for codex (assuming binary exists or custom install)"

# ==========================================
# [Phase 3] Generate Config Files
# ==========================================
echo -e "\n${BLUE}>>> Generating Config Files...${NC}"

# 1. Claude/Gemini Secrets (Isolated)
SECRETS_FILE="$CONFIG_CONTAINER_DIR/.private_config/secrets.env"
cat << EOF > "$SECRETS_FILE"
# Claude
export ANTHROPIC_BASE_URL="$CLAUDE_URL"
export ANTHROPIC_API_KEY="$CLAUDE_KEY"
export ANTHROPIC_AUTH_TOKEN="$CLAUDE_KEY"
export ANTHROPIC_MODEL="$CLAUDE_MODEL"
export ANTHROPIC_SMALL_FAST_MODEL="$CLAUDE_SMALL_MODEL"
# Gemini
export GOOGLE_GEMINI_BASE_URL="$GEMINI_URL"
export GEMINI_API_KEY="$GEMINI_KEY"
export GOOGLE_API_KEY="$GEMINI_KEY"
export GEMINI_MODEL="$GEMINI_MODEL"
# Codex Env (Optional, for backup)
export OPENAI_API_KEY="$CODEX_KEY"
export OPENAI_BASE_URL="$CODEX_URL"
EOF
chmod 600 "$SECRETS_FILE"

# 2. Gemini Settings (Isolated)
GEMINI_DIR="$CONFIG_CONTAINER_DIR/.gemini"
echo '{"ide":{"enabled":true},"security":{"auth":{"selectedType":"gemini-api-key"}}}' > "$GEMINI_DIR/settings.json"

# 3. Codex Config (Global ~/.codex) - NO ISOLATION
CODEX_HOME="$HOME/.codex"
mkdir -p "$CODEX_HOME"

cat << EOF > "$CODEX_HOME/config.toml"
model_provider = "$CODEX_MODEL_PROVIDER"
model = "$CODEX_MODEL"
model_reasoning_effort = "$CODEX_REASONING_EFFORT"
network_access = "$CODEX_NETWORK_ACCESS"
disable_response_storage = $CODEX_DISABLE_RESPONSE_STORAGE

[model_providers.$CODEX_MODEL_PROVIDER]
name = "$CODEX_MODEL_PROVIDER"
base_url = "$CODEX_URL"
wire_api = "$CODEX_WIRE_API"
requires_openai_auth = true
EOF

echo -e "${GREEN}✅ Codex config written to: $CODEX_HOME/config.toml${NC}"

cat << EOF > "$CODEX_HOME/auth.json"
{
  "OPENAI_API_KEY": "$CODEX_KEY"
}
EOF
chmod 600 "$CODEX_HOME/auth.json"

# ==========================================
# [Phase 4] Inject Conda Hooks
# ==========================================
echo -e "\n${BLUE}>>> Injecting Conda Hooks...${NC}"
CONDA_DIR="$CONDA_PREFIX"
mkdir -p "$CONDA_DIR/etc/conda/activate.d"
mkdir -p "$CONDA_DIR/etc/conda/deactivate.d"

# Proxy Config
PROXY_EXPORTS=""
PROXY_UNSETS=""
if [ -n "$PROXY_URL" ]; then
    PROXY_EXPORTS="export HTTP_PROXY=\"$PROXY_URL\" HTTPS_PROXY=\"$PROXY_URL\" ALL_PROXY=\"$PROXY_URL\""
    PROXY_UNSETS="unset HTTP_PROXY HTTPS_PROXY ALL_PROXY"
fi

# Activate Hook
cat << EOF > "$CONDA_DIR/etc/conda/activate.d/env_hook_isolation.sh"
#!/bin/bash
export AI_CONFIG_ROOT="$CONFIG_CONTAINER_DIR"
source "$SECRETS_FILE"
$PROXY_EXPORTS
export NPM_CONFIG_USERCONFIG="$NPMRC_FILE"
export XDG_CONFIG_HOME="$CONFIG_CONTAINER_DIR/.private_storage/config"
export XDG_DATA_HOME="$CONFIG_CONTAINER_DIR/.private_storage/data"
export XDG_STATE_HOME="$CONFIG_CONTAINER_DIR/.private_storage/state"
export XDG_CACHE_HOME="$CONFIG_CONTAINER_DIR/.private_storage/cache"
export GEMINI_HOME="$GEMINI_DIR"
# Codex uses global ~/.codex, so no special env var needed here usually
echo "🤖 AI CLI environment activated"
EOF

# Deactivate Hook
cat << EOF > "$CONDA_DIR/etc/conda/deactivate.d/env_hook_isolation.sh"
#!/bin/bash
unset ANTHROPIC_BASE_URL ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN ANTHROPIC_MODEL ANTHROPIC_SMALL_FAST_MODEL
unset GOOGLE_GEMINI_BASE_URL GEMINI_API_KEY GOOGLE_API_KEY GEMINI_MODEL GEMINI_HOME
unset OPENAI_API_KEY OPENAI_BASE_URL CODEX_HOME
unset AI_CONFIG_ROOT NPM_CONFIG_USERCONFIG
unset XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME XDG_CACHE_HOME
$PROXY_UNSETS
echo "🔌 AI CLI environment deactivated"
EOF

echo -e "\n${GREEN}✅ Setup Complete!${NC}"
echo -e "Run: ${YELLOW}conda deactivate && conda activate $CONDA_ENV_NAME${NC}"