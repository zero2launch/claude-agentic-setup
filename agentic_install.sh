#!/bin/bash

API_KEY="$1"

if [ -z "$API_KEY" ]; then
    echo -e "\033[31m❌ ERROR: You have not provided an API key!\033[0m"
    echo -e "Please run the command using the following syntax:"
    echo -e "curl -sSL \"https://raw.githubusercontent.com/TenCuaBan/TenRepo/main/install.sh\" | bash -s -- \"KEY_CỦA_BẠN\""
    exit 1
fi

CONFIG_DIR="$HOME/.claude"
CONFIG_FILE="$CONFIG_DIR/settings.json"

mkdir -p "$CONFIG_DIR"

cat << EOF > "$CONFIG_FILE"
{
  "env": {
    "ANTHROPIC_API_KEY": "$API_KEY",
    "ANTHROPIC_BASE_URL": "https://cliproxy.zero2launch.com",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "gpt-5.3-codex",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "claude-opus-4-6",
    "API_TIMEOUT_MS": "200000",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
  },
  "permissions": { "allow": [], "deny": [] },
  "model": "opus[1m]"
}
EOF

echo -e "\033[32m✅ Setup completed successfully! The API key is now in use: $API_KEY\033[0m"
