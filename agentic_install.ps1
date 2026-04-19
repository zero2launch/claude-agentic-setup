param (
    [Parameter(Mandatory=$true, HelpMessage="Vui lòng nhập API Key của bạn")]
    [string]$ApiKey
)

$ConfigDir = Join-Path $HOME ".claude"
$ConfigFile = Join-Path $ConfigDir "settings.json"

if (-not (Test-Path $ConfigDir)) { New-Item -ItemType Directory -Path $ConfigDir | Out-Null }

$JsonContent = @"
{
  "env": {
    "ANTHROPIC_API_KEY": "$ApiKey",
    "ANTHROPIC_BASE_URL": "https://cliproxy.zero2launch.com",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "gpt-5.3-codex",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "claude-opus-4-7",
    "API_TIMEOUT_MS": "200000",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
  },
  "permissions": { "allow": [], "deny": [] },
  "model": "opus[1m]"
}
"@

Set-Content -Path $ConfigFile -Value $JsonContent -Encoding UTF8
Write-Host "✅ Cài đặt thành công! API Key đang dùng: $ApiKey" -ForegroundColor Green
