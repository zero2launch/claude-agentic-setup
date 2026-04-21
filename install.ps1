# Zero2Launch Claude Agentic Setup - Install Script (Windows)
# Install or uninstall Claude Code proxy configuration
# Usage: & ([scriptblock]::Create((irm "https://raw.githubusercontent.com/zero2launch/claude-agentic-setup/main/install.ps1"))) -ApiKey "YOUR_KEY"

param (
    [string]$ApiKey = "",
    [switch]$Uninstall,
    [switch]$Install
)

Set-StrictMode -Off
$ErrorActionPreference = "Stop"

# ─── Config ───

$BASE_URL  = "https://agentic.zero2launch.io"
$CLAUDE_DIR   = Join-Path $HOME ".claude"
$SETTINGS_FILE = Join-Path $CLAUDE_DIR "settings.json"

$ALL_EZAI_VARS = @(
    "ANTHROPIC_BASE_URL",
    "ANTHROPIC_API_KEY",
    "ANTHROPIC_AUTH_TOKEN",
    "ANTHROPIC_DEFAULT_SONNET_MODEL",
    "ANTHROPIC_DEFAULT_OPUS_MODEL",
    "API_TIMEOUT_MS",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC",
    "OPENAI_BASE_URL",
    "OPENAI_API_KEY"
)

# ─── Helper: backup file before modifying ───

function Backup-File {
    param([string]$Path)
    if (Test-Path $Path) {
        $timestamp = Get-Date -Format "yyyyMMddHHmmss"
        Copy-Item $Path "${Path}.backup.$timestamp" -ErrorAction SilentlyContinue
    }
}

# ─── Detect current installation status ───

function Test-EzAIInstalled {
    # Check user env vars
    foreach ($var in $ALL_EZAI_VARS) {
        if ([System.Environment]::GetEnvironmentVariable($var, "User")) {
            return $true
        }
    }
    # Check settings.json
    if (Test-Path $SETTINGS_FILE) {
        $content = Get-Content $SETTINGS_FILE -Raw -ErrorAction SilentlyContinue
        if ($content -match "zero2launch|ANTHROPIC_BASE_URL") {
            return $true
        }
    }
    return $false
}

# ─── Determine ACTION ───

$ACTION = ""
if ($Uninstall) { $ACTION = "uninstall" }
elseif ($Install -or $ApiKey) { $ACTION = "install" }

# ─── Interactive menu (if no action specified) ───

if (-not $ACTION) {
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════╗"
    Write-Host "  ║      ⚡ Zero2Launch Claude Setup     ║"
    Write-Host "  ╚══════════════════════════════════════╝"
    Write-Host ""

    if (Test-EzAIInstalled) {
        Write-Host "  Status: 🟢 Zero2Launch is currently installed"
    } else {
        Write-Host "  Status: ⚪ Zero2Launch is not installed"
    }

    Write-Host ""
    Write-Host "  ┌──────────────────────────────────────┐"
    Write-Host "  │  1) Install / Update                  │"
    Write-Host "  │  2) Uninstall                         │"
    Write-Host "  │  3) Exit                              │"
    Write-Host "  └──────────────────────────────────────┘"
    Write-Host ""

    $choice = Read-Host "  Choose [1-3]"

    switch ($choice) {
        "1" { $ACTION = "install" }
        "2" { $ACTION = "uninstall" }
        "3" { Write-Host "  Bye! 👋"; Write-Host ""; exit 0 }
        default { Write-Host "  ❌ Invalid choice."; exit 1 }
    }
    Write-Host ""
}

# ═══════════════════════════════════════════
#  UNINSTALL
# ═══════════════════════════════════════════

if ($ACTION -eq "uninstall") {
    Write-Host "  ╔══════════════════════════════════════╗"
    Write-Host "  ║    🗑️  Zero2Launch Uninstaller       ║"
    Write-Host "  ╚══════════════════════════════════════╝"
    Write-Host ""

    # ─── Step 1: Remove User environment variables ───
    Write-Host "  [1/3] Removing environment variables..."
    $removed = $false
    foreach ($var in $ALL_EZAI_VARS) {
        $val = [System.Environment]::GetEnvironmentVariable($var, "User")
        if ($val) {
            [System.Environment]::SetEnvironmentVariable($var, $null, "User")
            Write-Host "    ✓ Removed $var"
            $removed = $true
        }
    }
    if (-not $removed) {
        Write-Host "    · No environment variables found (already clean)"
    }

    # ─── Step 2: Clean ~/.claude/settings.json ───
    Write-Host "  [2/3] Cleaning $SETTINGS_FILE..."
    if (Test-Path $SETTINGS_FILE) {
        Backup-File $SETTINGS_FILE
        try {
            $data = Get-Content $SETTINGS_FILE -Raw | ConvertFrom-Json
            $changed = $false
            foreach ($var in $ALL_EZAI_VARS) {
                if ($data.env.PSObject.Properties[$var]) {
                    $data.env.PSObject.Properties.Remove($var)
                    $changed = $true
                }
            }
            # Remove top-level keys added by installer
            if ($data.PSObject.Properties["disableLoginPrompt"]) {
                $data.PSObject.Properties.Remove("disableLoginPrompt")
            }
            if ($changed) {
                $data | ConvertTo-Json -Depth 10 | Set-Content $SETTINGS_FILE -Encoding UTF8
                Write-Host "    ✓ Removed Zero2Launch keys from Claude settings"
            } else {
                Write-Host "    · No Zero2Launch keys found (already clean)"
            }
        } catch {
            Write-Host "    ⚠ Could not parse settings.json — please edit manually"
        }
    } else {
        Write-Host "    · File not found (nothing to clean)"
    }

    # ─── Step 3: Clear current session variables ───
    Write-Host "  [3/3] Clearing current session..."
    foreach ($var in $ALL_EZAI_VARS) {
        Remove-Item "Env:\$var" -ErrorAction SilentlyContinue
    }
    Write-Host "    ✓ Done"

    Write-Host ""
    Write-Host "  ════════════════════════════════════════"
    Write-Host "  ✅ Zero2Launch has been removed!"
    Write-Host ""
    Write-Host "  Restart your terminal to apply changes."
    Write-Host "  Your tools will now use their default API settings."
    Write-Host ""
    exit 0
}

# ═══════════════════════════════════════════
#  INSTALL
# ═══════════════════════════════════════════

# If no key yet, ask for it interactively
if (-not $ApiKey) {
    $ApiKey = Read-Host "  Enter your API key"
    if (-not $ApiKey) {
        Write-Host ""
        Write-Host "  ❌ No API key provided."
        Write-Host "  Get your key at: $BASE_URL/dashboard"
        Write-Host ""
        exit 1
    }
    Write-Host ""
}

Write-Host "  ╔══════════════════════════════════════╗"
Write-Host "  ║    🚀 Zero2Launch Claude Installer   ║"
Write-Host "  ╚══════════════════════════════════════╝"
Write-Host ""
Write-Host "  Base URL: $BASE_URL"
Write-Host "  API Key:  $($ApiKey.Substring(0, [Math]::Min(12, $ApiKey.Length)))..."
Write-Host ""

# ─── Step 1: Set User environment variables ───

Write-Host "  [1/4] Setting environment variables..."

$envVars = @{
    "ANTHROPIC_API_KEY"                        = $ApiKey
    "ANTHROPIC_AUTH_TOKEN"                     = $ApiKey
    "ANTHROPIC_BASE_URL"                       = $BASE_URL
    "ANTHROPIC_DEFAULT_SONNET_MODEL"           = "gpt-5.3-codex"
    "ANTHROPIC_DEFAULT_OPUS_MODEL"             = "claude-opus-4-7"
    "OPENAI_BASE_URL"                          = "$BASE_URL/v1"
    "OPENAI_API_KEY"                           = $ApiKey
    "API_TIMEOUT_MS"                           = "200000"
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC" = "1"
}

foreach ($kv in $envVars.GetEnumerator()) {
    [System.Environment]::SetEnvironmentVariable($kv.Key, $kv.Value, "User")
    Set-Item "Env:\$($kv.Key)" $kv.Value -ErrorAction SilentlyContinue
    Write-Host "    ✓ $($kv.Key)"
}

# ─── Step 2: Update ~/.claude/settings.json ───

Write-Host "  [2/4] Updating $SETTINGS_FILE..."

if (-not (Test-Path $CLAUDE_DIR)) {
    New-Item -ItemType Directory -Path $CLAUDE_DIR | Out-Null
}

Backup-File $SETTINGS_FILE

$settingsWritten = $false

if (Test-Path $SETTINGS_FILE) {
    try {
        $data = Get-Content $SETTINGS_FILE -Raw | ConvertFrom-Json

        if (-not $data.PSObject.Properties["env"]) {
            $data | Add-Member -NotePropertyName "env" -NotePropertyValue ([PSCustomObject]@{})
        }

        foreach ($kv in $envVars.GetEnumerator()) {
            if ($data.env.PSObject.Properties[$kv.Key]) {
                $data.env.PSObject.Properties[$kv.Key].Value = $kv.Value
            } else {
                $data.env | Add-Member -NotePropertyName $kv.Key -NotePropertyValue $kv.Value
            }
        }

        if (-not $data.PSObject.Properties["disableLoginPrompt"]) {
            $data | Add-Member -NotePropertyName "disableLoginPrompt" -NotePropertyValue $true
        } else {
            $data.disableLoginPrompt = $true
        }

        if (-not $data.PSObject.Properties["model"]) {
            $data | Add-Member -NotePropertyName "model" -NotePropertyValue "opus[1m]"
        }

        $data | ConvertTo-Json -Depth 10 | Set-Content $SETTINGS_FILE -Encoding UTF8
        Write-Host "    ✓ Merged with existing settings"
        $settingsWritten = $true
    } catch {
        Write-Host "    ⚠ Could not parse existing settings.json — will overwrite"
    }
}

if (-not $settingsWritten) {
    $newSettings = [PSCustomObject]@{
        env = [PSCustomObject]@{
            ANTHROPIC_API_KEY                        = $ApiKey
            ANTHROPIC_AUTH_TOKEN                     = $ApiKey
            ANTHROPIC_BASE_URL                       = $BASE_URL
            ANTHROPIC_DEFAULT_SONNET_MODEL           = "gpt-5.3-codex"
            ANTHROPIC_DEFAULT_OPUS_MODEL             = "claude-opus-4-7"
            OPENAI_BASE_URL                          = "$BASE_URL/v1"
            OPENAI_API_KEY                           = $ApiKey
            API_TIMEOUT_MS                           = "200000"
            CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1"
        }
        permissions        = [PSCustomObject]@{ allow = @(); deny = @() }
        model              = "opus[1m]"
        disableLoginPrompt = $true
    }
    $newSettings | ConvertTo-Json -Depth 10 | Set-Content $SETTINGS_FILE -Encoding UTF8
    Write-Host "    ✓ Created settings.json"
}

# ─── Step 3: Set current session variables (already done above) ───

Write-Host "  [3/4] Current session updated..."
Write-Host "    ✓ Environment variables active in this session"

# ─── Step 4: Verify ───

Write-Host "  [4/4] Verifying..."

$verifyOk = $true

if ((Test-Path $SETTINGS_FILE) -and ((Get-Content $SETTINGS_FILE -Raw) -match [regex]::Escape($ApiKey))) {
    Write-Host "    ✓ ~/.claude/settings.json"
} else {
    Write-Host "    ✗ ~/.claude/settings.json (check manually)"
    $verifyOk = $false
}

if ((Test-Path $SETTINGS_FILE) -and ((Get-Content $SETTINGS_FILE -Raw) -match "ANTHROPIC_AUTH_TOKEN")) {
    Write-Host "    ✓ ANTHROPIC_AUTH_TOKEN configured"
} else {
    Write-Host "    ✗ ANTHROPIC_AUTH_TOKEN missing (check manually)"
    $verifyOk = $false
}

$envCheck = [System.Environment]::GetEnvironmentVariable("ANTHROPIC_BASE_URL", "User")
if ($envCheck -eq $BASE_URL) {
    Write-Host "    ✓ User environment variables"
} else {
    Write-Host "    ✗ User environment variables (check manually)"
    $verifyOk = $false
}

Write-Host ""
Write-Host "  ════════════════════════════════════════"

if ($verifyOk) {
    Write-Host "  ✅ Installation complete!" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Installation completed with warnings" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  Next steps:"
Write-Host ""
Write-Host "  1. Restart your terminal to apply env changes"
Write-Host ""
Write-Host "  2. For Claude Code:"
Write-Host "     claude"
Write-Host ""
Write-Host "  3. For Cursor / VS Code:"
Write-Host "     Set API Base URL: $BASE_URL"
Write-Host "     Set API Key: (your key)"
Write-Host ""
Write-Host "  4. For any OpenAI-compatible tool:"
Write-Host "     Base URL: $BASE_URL/v1"
Write-Host "     API Key: (your key)"
Write-Host ""
Write-Host "  Dashboard: $BASE_URL/dashboard"
Write-Host "  Docs: $BASE_URL/docs"
Write-Host ""
