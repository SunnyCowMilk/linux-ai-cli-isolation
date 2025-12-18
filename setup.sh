#!/bin/bash
# ==============================================================================
# Script: setup.sh
# Version: v13.0 (Auto Shell Profile)
# Description: Deploy AI CLI environments with flexible configuration modes.
#              Supports: isolated (project-level), global, or disabled per service.
#              Global mode automatically configures shell profile.
# ==============================================================================

BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}${BOLD}>>> Linux AI CLI Setup Tool v13.0${NC}"
echo "----------------------------------------------------------------"

# ==========================================
# [Helper Functions]
# ==========================================

# Detect user's shell profile file
get_shell_profile() {
    if [ -n "$ZSH_VERSION" ] || [ "$SHELL" = "/bin/zsh" ] || [ "$SHELL" = "/usr/bin/zsh" ]; then
        echo "$HOME/.zshrc"
    else
        echo "$HOME/.bashrc"
    fi
}

# Add source command to shell profile (avoid duplicates)
add_to_shell_profile() {
    local env_file="$1"
    local profile_file=$(get_shell_profile)
    local source_line="[ -f \"$env_file\" ] && source \"$env_file\""

    if [ -f "$profile_file" ]; then
        if ! grep -qF "$env_file" "$profile_file"; then
            echo "" >> "$profile_file"
            echo "# AI CLI Configuration (added by setup.sh)" >> "$profile_file"
            echo "$source_line" >> "$profile_file"
            echo -e "${GREEN}   ✅ Added to $profile_file${NC}"
            return 0
        else
            echo -e "${YELLOW}   ⏭️  Already in $profile_file${NC}"
            return 1
        fi
    else
        echo "$source_line" > "$profile_file"
        echo -e "${GREEN}   ✅ Created $profile_file${NC}"
        return 0
    fi
}

# ==========================================
# [Phase 0] Initialization
# ==========================================
PROJECT_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CONFIG_CONTAINER_DIR="$PROJECT_ROOT/.ai_tools_config"
SHELL_PROFILE=$(get_shell_profile)
NEED_RELOAD_SHELL=false

echo -e "📍 Project Root: ${GREEN}$PROJECT_ROOT${NC}"
echo -e "📍 Shell Profile: ${GREEN}$SHELL_PROFILE${NC}"

# Setup .gitignore
GITIGNORE_FILE="$PROJECT_ROOT/.gitignore"
touch "$GITIGNORE_FILE"
for IGNORE_ITEM in ".ai_tools_config/" ".env" ".claude/"; do
    grep -qxF "$IGNORE_ITEM" "$GITIGNORE_FILE" || echo "$IGNORE_ITEM" >> "$GITIGNORE_FILE"
done

# Load .env Configuration
if [ -f "$PROJECT_ROOT/.env" ]; then
    echo -e "${GREEN}📄 Loading configuration from .env...${NC}"
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
else
    echo -e "${RED}❌ No .env file found! Please run: cp .env.example .env${NC}"
    exit 1
fi

# ==========================================
# [Phase 1] Configuration & Defaults
# ==========================================
# Mode defaults
CLAUDE_MODE=${CLAUDE_MODE:-isolated}
GEMINI_MODE=${GEMINI_MODE:-isolated}
CODEX_MODE=${CODEX_MODE:-global}

# Validate Codex mode (only global or disabled)
if [ "$CODEX_MODE" = "isolated" ]; then
    echo -e "${YELLOW}⚠️  Codex does not support isolated mode, switching to global${NC}"
    CODEX_MODE="global"
fi

# Service defaults
CONDA_ENV_NAME=${CONDA_ENV_NAME:-ai_cli_env}
CLAUDE_URL=${CLAUDE_URL:-"https://api.anthropic.com"}
CLAUDE_MODEL=${CLAUDE_MODEL:-"claude-opus-4-5-20251101-thinking"}
CLAUDE_SMALL_MODEL=${CLAUDE_SMALL_MODEL:-"claude-haiku-4-5-20251001"}
GEMINI_URL=${GEMINI_URL:-"https://generativelanguage.googleapis.com"}
GEMINI_MODEL=${GEMINI_MODEL:-"gemini-3-pro-preview"}
CODEX_URL=${CODEX_URL:-"https://api.openai.com/v1"}
CODEX_MODEL=${CODEX_MODEL:-"gpt-5.1-codex-max"}
CODEX_REASONING_EFFORT=${CODEX_REASONING_EFFORT:-"medium"}
CODEX_WIRE_API=${CODEX_WIRE_API:-"responses"}
CODEX_NETWORK_ACCESS=${CODEX_NETWORK_ACCESS:-"enabled"}
CODEX_DISABLE_RESPONSE_STORAGE=${CODEX_DISABLE_RESPONSE_STORAGE:-"true"}

# Mirror Settings
if [ "$USE_CN_MIRROR" = "true" ]; then
    CONDA_CHANNEL="https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge"
    NPM_REGISTRY="https://registry.npmmirror.com"
else
    CONDA_CHANNEL="conda-forge"
    NPM_REGISTRY="https://registry.npmjs.org"
fi

# Check if any service uses isolated mode
NEED_CONDA=false
if [ "$CLAUDE_MODE" = "isolated" ] || [ "$GEMINI_MODE" = "isolated" ]; then
    NEED_CONDA=true
fi

# Display configuration
echo -e "\n${BLUE}>>> Configuration Summary${NC}"
echo -e "  Claude: ${YELLOW}$CLAUDE_MODE${NC}"
echo -e "  Gemini: ${YELLOW}$GEMINI_MODE${NC}"
echo -e "  Codex:  ${YELLOW}$CODEX_MODE${NC}"

# ==========================================
# [Phase 2] API Key Validation
# ==========================================
if [ "$CLAUDE_MODE" != "disabled" ] && [ -z "$CLAUDE_KEY" ]; then
    read -p "🔑 Enter Claude API Key: " CLAUDE_KEY
fi
if [ "$GEMINI_MODE" != "disabled" ] && [ -z "$GEMINI_KEY" ]; then
    read -p "🔑 Enter Gemini API Key: " GEMINI_KEY
fi
if [ "$CODEX_MODE" != "disabled" ] && [ -z "$CODEX_KEY" ]; then
    read -p "🔑 Enter Codex API Key: " CODEX_KEY
fi

# ==========================================
# [Phase 3] Environment Setup
# ==========================================
echo -e "\n${BLUE}>>> Setting up environment...${NC}"

# Conda setup (only if needed)
if [ "$NEED_CONDA" = true ]; then
    if ! command -v conda &> /dev/null; then
        echo -e "${RED}❌ Conda not found but required for isolated mode.${NC}"
        echo -e "${YELLOW}   Install Conda or switch to global mode.${NC}"
        exit 1
    fi

    source "$(conda info --base)/etc/profile.d/conda.sh"
    TARGET_NODE_VERSION=24
    echo -e "🐍 Configuring Conda environment: $CONDA_ENV_NAME..."

    conda_env_exists() { conda info --envs | awk '{print $1}' | grep -qx "$1"; }

    if conda_env_exists "$CONDA_ENV_NAME"; then
        echo -e "${GREEN}   Using existing environment: $CONDA_ENV_NAME${NC}"
        conda activate "$CONDA_ENV_NAME"
        if ! command -v node &> /dev/null; then
            conda install "nodejs>=$TARGET_NODE_VERSION" -c "$CONDA_CHANNEL" -y
        fi
    else
        echo -e "${GREEN}   Creating new environment: $CONDA_ENV_NAME${NC}"
        conda create -n "$CONDA_ENV_NAME" python=3.10 "nodejs>=$TARGET_NODE_VERSION" -c "$CONDA_CHANNEL" -y
        conda activate "$CONDA_ENV_NAME"
    fi

    # Create isolated config directories
    mkdir -p "$CONFIG_CONTAINER_DIR/.private_storage/config"
    mkdir -p "$CONFIG_CONTAINER_DIR/.private_storage/data"
    mkdir -p "$CONFIG_CONTAINER_DIR/.private_storage/state"
    mkdir -p "$CONFIG_CONTAINER_DIR/.private_storage/cache"
    mkdir -p "$CONFIG_CONTAINER_DIR/.private_config"

    # NPM Registry for isolated mode
    NPMRC_FILE="$CONFIG_CONTAINER_DIR/.private_config/npmrc"
    echo "registry=$NPM_REGISTRY" > "$NPMRC_FILE"
    export NPM_CONFIG_USERCONFIG="$NPMRC_FILE"
fi

# ==========================================
# [Phase 4] Install CLI Tools
# ==========================================
echo -e "\n${BLUE}>>> Installing CLI tools...${NC}"

if [ "$CLAUDE_MODE" != "disabled" ]; then
    echo -e "📦 Installing Claude Code..."
    npm install -g @anthropic-ai/claude-code
fi

if [ "$GEMINI_MODE" != "disabled" ]; then
    echo -e "📦 Installing Gemini CLI..."
    npm install -g @google/gemini-cli
fi

# Codex is typically installed separately or via npm
# npm install -g @openai/codex

# ==========================================
# [Phase 5] Configure Services
# ==========================================
echo -e "\n${BLUE}>>> Configuring services...${NC}"

# --- Claude Configuration ---
if [ "$CLAUDE_MODE" = "isolated" ]; then
    echo -e "🔧 Claude: ${GREEN}isolated${NC} mode"
    CLAUDE_SECRETS="$CONFIG_CONTAINER_DIR/.private_config/claude.env"
    cat << EOF > "$CLAUDE_SECRETS"
export ANTHROPIC_BASE_URL="$CLAUDE_URL"
export ANTHROPIC_API_KEY="$CLAUDE_KEY"
export ANTHROPIC_AUTH_TOKEN="$CLAUDE_KEY"
export ANTHROPIC_MODEL="$CLAUDE_MODEL"
export ANTHROPIC_SMALL_FAST_MODEL="$CLAUDE_SMALL_MODEL"
EOF
    chmod 600 "$CLAUDE_SECRETS"

elif [ "$CLAUDE_MODE" = "global" ]; then
    echo -e "🔧 Claude: ${GREEN}global${NC} mode"
    CLAUDE_GLOBAL_CONFIG="$HOME/.claude_env"
    cat << EOF > "$CLAUDE_GLOBAL_CONFIG"
# Claude Code Configuration (generated by setup.sh)
export ANTHROPIC_BASE_URL="$CLAUDE_URL"
export ANTHROPIC_API_KEY="$CLAUDE_KEY"
export ANTHROPIC_AUTH_TOKEN="$CLAUDE_KEY"
export ANTHROPIC_MODEL="$CLAUDE_MODEL"
export ANTHROPIC_SMALL_FAST_MODEL="$CLAUDE_SMALL_MODEL"
EOF
    chmod 600 "$CLAUDE_GLOBAL_CONFIG"
    add_to_shell_profile "$CLAUDE_GLOBAL_CONFIG" && NEED_RELOAD_SHELL=true
fi

# --- Gemini Configuration ---
if [ "$GEMINI_MODE" = "isolated" ]; then
    echo -e "🔧 Gemini: ${GREEN}isolated${NC} mode"
    GEMINI_DIR="$CONFIG_CONTAINER_DIR/.gemini"
    mkdir -p "$GEMINI_DIR"
    echo '{"ide":{"enabled":true},"security":{"auth":{"selectedType":"gemini-api-key"}}}' > "$GEMINI_DIR/settings.json"

    GEMINI_SECRETS="$CONFIG_CONTAINER_DIR/.private_config/gemini.env"
    cat << EOF > "$GEMINI_SECRETS"
export GOOGLE_GEMINI_BASE_URL="$GEMINI_URL"
export GEMINI_API_KEY="$GEMINI_KEY"
export GOOGLE_API_KEY="$GEMINI_KEY"
export GEMINI_MODEL="$GEMINI_MODEL"
EOF
    chmod 600 "$GEMINI_SECRETS"

elif [ "$GEMINI_MODE" = "global" ]; then
    echo -e "🔧 Gemini: ${GREEN}global${NC} mode"
    GEMINI_GLOBAL_DIR="$HOME/.gemini"
    mkdir -p "$GEMINI_GLOBAL_DIR"
    echo '{"ide":{"enabled":true},"security":{"auth":{"selectedType":"gemini-api-key"}}}' > "$GEMINI_GLOBAL_DIR/settings.json"

    GEMINI_GLOBAL_CONFIG="$HOME/.gemini_env"
    cat << EOF > "$GEMINI_GLOBAL_CONFIG"
# Gemini CLI Configuration (generated by setup.sh)
export GOOGLE_GEMINI_BASE_URL="$GEMINI_URL"
export GEMINI_API_KEY="$GEMINI_KEY"
export GOOGLE_API_KEY="$GEMINI_KEY"
export GEMINI_MODEL="$GEMINI_MODEL"
EOF
    chmod 600 "$GEMINI_GLOBAL_CONFIG"
    add_to_shell_profile "$GEMINI_GLOBAL_CONFIG" && NEED_RELOAD_SHELL=true
fi

# --- Codex Configuration (global only) ---
if [ "$CODEX_MODE" = "global" ]; then
    echo -e "🔧 Codex: ${GREEN}global${NC} mode"
    CODEX_HOME_DIR="$HOME/.codex"
    mkdir -p "$CODEX_HOME_DIR"

    cat << EOF > "$CODEX_HOME_DIR/config.toml"
model_provider = "openai"
model = "$CODEX_MODEL"
model_reasoning_effort = "$CODEX_REASONING_EFFORT"
network_access = "$CODEX_NETWORK_ACCESS"
disable_response_storage = $CODEX_DISABLE_RESPONSE_STORAGE

[model_providers.openai]
name = "openai"
base_url = "$CODEX_URL"
wire_api = "$CODEX_WIRE_API"
requires_openai_auth = true
EOF

    cat << EOF > "$CODEX_HOME_DIR/auth.json"
{
  "OPENAI_API_KEY": "$CODEX_KEY"
}
EOF
    chmod 600 "$CODEX_HOME_DIR/auth.json"

    # Create codex env file for shell profile
    CODEX_GLOBAL_CONFIG="$HOME/.codex_env"
    cat << EOF > "$CODEX_GLOBAL_CONFIG"
# Codex CLI Configuration (generated by setup.sh)
export OPENAI_API_KEY="$CODEX_KEY"
export OPENAI_BASE_URL="$CODEX_URL"
EOF
    chmod 600 "$CODEX_GLOBAL_CONFIG"
    add_to_shell_profile "$CODEX_GLOBAL_CONFIG" && NEED_RELOAD_SHELL=true
    echo -e "${GREEN}   ✅ Codex config written to: $CODEX_HOME_DIR/${NC}"
fi

# ==========================================
# [Phase 6] Conda Hooks (for isolated mode)
# ==========================================
if [ "$NEED_CONDA" = true ]; then
    echo -e "\n${BLUE}>>> Injecting Conda Hooks...${NC}"
    CONDA_DIR="$CONDA_PREFIX"
    mkdir -p "$CONDA_DIR/etc/conda/activate.d"
    mkdir -p "$CONDA_DIR/etc/conda/deactivate.d"

    # Build activate script dynamically
    ACTIVATE_SCRIPT="$CONDA_DIR/etc/conda/activate.d/env_hook_isolation.sh"
    cat << 'HEADER' > "$ACTIVATE_SCRIPT"
#!/bin/bash
HEADER

    echo "export AI_CONFIG_ROOT=\"$CONFIG_CONTAINER_DIR\"" >> "$ACTIVATE_SCRIPT"

    # Add proxy if configured
    if [ -n "$PROXY_URL" ]; then
        echo "export HTTP_PROXY=\"$PROXY_URL\" HTTPS_PROXY=\"$PROXY_URL\" ALL_PROXY=\"$PROXY_URL\"" >> "$ACTIVATE_SCRIPT"
    fi

    # Claude isolated
    if [ "$CLAUDE_MODE" = "isolated" ]; then
        echo "source \"$CONFIG_CONTAINER_DIR/.private_config/claude.env\"" >> "$ACTIVATE_SCRIPT"
        echo "export XDG_CONFIG_HOME=\"$CONFIG_CONTAINER_DIR/.private_storage/config\"" >> "$ACTIVATE_SCRIPT"
        echo "export XDG_DATA_HOME=\"$CONFIG_CONTAINER_DIR/.private_storage/data\"" >> "$ACTIVATE_SCRIPT"
        echo "export XDG_STATE_HOME=\"$CONFIG_CONTAINER_DIR/.private_storage/state\"" >> "$ACTIVATE_SCRIPT"
        echo "export XDG_CACHE_HOME=\"$CONFIG_CONTAINER_DIR/.private_storage/cache\"" >> "$ACTIVATE_SCRIPT"
        echo "export NPM_CONFIG_USERCONFIG=\"$CONFIG_CONTAINER_DIR/.private_config/npmrc\"" >> "$ACTIVATE_SCRIPT"
    fi

    # Gemini isolated
    if [ "$GEMINI_MODE" = "isolated" ]; then
        echo "source \"$CONFIG_CONTAINER_DIR/.private_config/gemini.env\"" >> "$ACTIVATE_SCRIPT"
        echo "export GEMINI_HOME=\"$CONFIG_CONTAINER_DIR/.gemini\"" >> "$ACTIVATE_SCRIPT"
    fi

    # Codex global (set env vars to ensure priority over any existing values)
    if [ "$CODEX_MODE" = "global" ]; then
        echo "export OPENAI_API_KEY=\"$CODEX_KEY\"" >> "$ACTIVATE_SCRIPT"
        echo "export OPENAI_BASE_URL=\"$CODEX_URL\"" >> "$ACTIVATE_SCRIPT"
    fi

    echo 'echo "🤖 AI CLI environment activated"' >> "$ACTIVATE_SCRIPT"

    # Build deactivate script
    DEACTIVATE_SCRIPT="$CONDA_DIR/etc/conda/deactivate.d/env_hook_isolation.sh"
    cat << 'EOF' > "$DEACTIVATE_SCRIPT"
#!/bin/bash
unset ANTHROPIC_BASE_URL ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN ANTHROPIC_MODEL ANTHROPIC_SMALL_FAST_MODEL
unset GOOGLE_GEMINI_BASE_URL GEMINI_API_KEY GOOGLE_API_KEY GEMINI_MODEL GEMINI_HOME
unset OPENAI_API_KEY OPENAI_BASE_URL CODEX_HOME
unset AI_CONFIG_ROOT NPM_CONFIG_USERCONFIG
unset XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME XDG_CACHE_HOME
unset HTTP_PROXY HTTPS_PROXY ALL_PROXY
echo "🔌 AI CLI environment deactivated"
EOF
fi

# ==========================================
# [Phase 7] Summary
# ==========================================
echo -e "\n${GREEN}✅ Setup Complete!${NC}"
echo "----------------------------------------------------------------"

echo -e "\n📝 Enabled services:"
[ "$CLAUDE_MODE" != "disabled" ] && echo -e "   - claude ($CLAUDE_MODE)"
[ "$GEMINI_MODE" != "disabled" ] && echo -e "   - gemini ($GEMINI_MODE)"
[ "$CODEX_MODE" != "disabled" ] && echo -e "   - codex ($CODEX_MODE)"

echo ""
if [ "$NEED_CONDA" = true ]; then
    echo -e "🔄 ${YELLOW}To activate isolated environment:${NC}"
    echo -e "   conda deactivate && conda activate $CONDA_ENV_NAME"
fi

if [ "$NEED_RELOAD_SHELL" = true ]; then
    echo -e "\n🔄 ${YELLOW}To apply global configuration:${NC}"
    echo -e "   source $SHELL_PROFILE"
    echo -e "   ${BLUE}(or restart your terminal)${NC}"
fi
