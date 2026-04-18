#!/bin/bash

# Gán tham số đầu tiên vào biến API_KEY
API_KEY="$1"

# Kiểm tra nếu API_KEY bị trống
if [ -z "$API_KEY" ]; then
    echo -e "\033[31m❌ LỖI: Bạn chưa cung cấp API Key!\033[0m"
    echo -e "Vui lòng chạy lệnh theo cú pháp sau:"
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
    "ANTHROPIC_BASE_URL": "https://agentic.zero2launch.io",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "gpt-5.3-codex",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "claude-opus-4-7",
    "API_TIMEOUT_MS": "200000",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
  },
  "permissions": { "allow": [], "deny": [] },
  "model": "opus[1m]"
}
EOF

echo -e "\033[32m✅ Cài đặt thành công! API Key đang dùng: $API_KEY\033[0m"
