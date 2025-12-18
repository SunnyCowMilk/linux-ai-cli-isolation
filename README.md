nux AI CLI Isolation Tool

A secure setup tool for **Claude Code** and **Gemini CLI** on shared Linux environments.

## Features
*   **Security**: API Keys are stored locally in `.ai_tools_config/` (Git-ignored).
*   **Isolation**: Uses a dedicated Conda environment.
*   **Auto-Hooks**: Environment variables load automatically upon activation.

## Usage
1. Clone the repo:
   `git clone https://github.com/YOUR_USERNAME/linux-ai-cli-isolation.git`
2. Enter directory:
   `cd linux-ai-cli-isolation`
3. Run setup:
   `./setup.sh`
4. Activate:
   `conda activate ai_cli_env`
