# ==============================================================
# SETUP-NEW-PC.ps1 - Claude Code + DeepSeek installer
# Run on NEW computer (Windows 11)
# ==============================================================
param(
    [string]$RepoUrl = "https://github.com/IlyaVostrikov/free-claude-code.git",
    [string]$Branch = "ilya/working-setup",
    [string]$InstallDir = "D:\AI BASE\DEEPSEEK"
)

$ErrorActionPreference = "Stop"
$cyan  = "Cyan"
$green = "Green"
$red   = "Red"

Write-Host ""
Write-Host "=====================================" -ForegroundColor $cyan
Write-Host "  Claude Code + DeepSeek Setup        " -ForegroundColor $cyan
Write-Host "  New PC Installer                    " -ForegroundColor $cyan
Write-Host "=====================================" -ForegroundColor $cyan
Write-Host ""

# ── Prerequisites ──
Write-Host "[1/7] Checking prerequisites..." -ForegroundColor $cyan

if (-not (Get-Command "uv" -ErrorAction SilentlyContinue)) {
    Write-Host "  Installing uv..." -ForegroundColor Yellow
    powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
    $env:Path = "$env:USERPROFILE\.local\bin;$env:Path"
}

if (-not (Get-Command "node" -ErrorAction SilentlyContinue)) {
    Write-Host "  Node.js not found - install from https://nodejs.org (LTS)" -ForegroundColor $red
    Write-Host "  After installing, re-run this script." -ForegroundColor $red
    exit 1
}

Write-Host "  uv:      $(uv --version)" -ForegroundColor $green
Write-Host "  Node.js: $(node --version)" -ForegroundColor $green
Write-Host "  npm:     $(npm --version)" -ForegroundColor $green

# ── Clone repo ──
Write-Host "[2/7] Cloning repository..." -ForegroundColor $cyan
$parentDir = Split-Path $InstallDir -Parent

if (-not (Test-Path $parentDir)) {
    New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
}

if (Test-Path $InstallDir) {
    Write-Host "  Directory exists - pulling latest..." -ForegroundColor Yellow
    Push-Location $InstallDir
    git checkout $Branch
    git pull origin $Branch
    Pop-Location
} else {
    git clone --branch $Branch $RepoUrl $InstallDir
}

# ── .env setup ──
Write-Host "[3/7] Configuring .env..." -ForegroundColor $cyan
Push-Location $InstallDir

if (Test-Path ".env") {
    Write-Host "  .env already exists - skipping" -ForegroundColor Yellow
} else {
    Write-Host "  Enter your DeepSeek API key:" -ForegroundColor Yellow
    Write-Host "  (get it at https://platform.deepseek.com/api_keys)" -ForegroundColor Gray
    $apiKey = Read-Host -Prompt "  DEEPSEEK_API_KEY"

    $envLines = @(
        "ANTHROPIC_AUTH_TOKEN=freecc",
        "DEEPSEEK_API_KEY=$apiKey",
        "MODEL=deepseek/deepseek-v4-pro",
        "ENABLE_MODEL_THINKING=true"
    )
    $envLines | Set-Content -Path ".env" -Encoding UTF8

    Write-Host "  .env created" -ForegroundColor $green
}

# ── Install Python deps ──
Write-Host "[4/7] Installing Python dependencies (uv sync)..." -ForegroundColor $cyan
uv sync

Pop-Location

# ── Install Claude Code ──
Write-Host "[5/7] Installing Claude Code (locked at 2.1.153)..." -ForegroundColor $cyan

$ccPkg = "$env:APPDATA\npm\node_modules\@anthropic-ai\claude-code"

npm install -g @anthropic-ai/claude-code@2.1.153

Write-Host "  Locking version via icacls..." -ForegroundColor Gray
$sid = ([System.Security.Principal.WindowsIdentity]::GetCurrent()).User.Value; icacls $ccPkg /deny "*$sid":W /T 2>$null
Write-Host "  Claude Code locked at 2.1.153" -ForegroundColor $green

# ── Configure Claude Code ──
Write-Host "[6/7] Configuring Claude Code settings..." -ForegroundColor $cyan

$claudeDir = "$env:USERPROFILE\.claude"
if (-not (Test-Path $claudeDir)) {
    New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
}

# cc-start.py
$ccStartLines = @(
    "import json, os, shutil",
    "s = os.path.expandvars(r'%USERPROFILE%\.claude\settings.json')",
    "b = os.path.expandvars(r'%USERPROFILE%\.claude\settings.backup.json')",
    "shutil.copy(s, b)",
    "d = json.load(open(s, encoding='utf-8'))",
    "d['env'] = {}",
    "d.pop('model', None)",
    "json.dump(d, open(s, 'w', encoding='utf-8'), indent=2, ensure_ascii=False)",
    "print('env cleared')"
)
$ccStartLines | Set-Content -Path "$claudeDir\cc-start.py" -Encoding UTF8

# cc-end.py
$ccEndLines = @(
    "import os, shutil",
    "s = os.path.expandvars(r'%USERPROFILE%\.claude\settings.json')",
    "b = os.path.expandvars(r'%USERPROFILE%\.claude\settings.backup.json')",
    "shutil.copy(b, s)",
    "print('settings restored')"
)
$ccEndLines | Set-Content -Path "$claudeDir\cc-end.py" -Encoding UTF8

# settings.json
$settings = @{
    env = @{}
    model = "haiku"
    enabledPlugins = @{
        "commit-commands@claude-plugins-official" = $true
        "feature-dev@claude-plugins-official" = $true
        "learning-output-style@claude-plugins-official" = $true
        "pr-review-toolkit@claude-plugins-official" = $true
        "vercel@claude-plugins-official" = $true
        "ui-ux-pro-max@ui-ux-pro-max-skill" = $true
        "interface-design@interface-design" = $true
        "design-research@designer-skills" = $true
        "design-systems@designer-skills" = $true
        "ux-strategy@designer-skills" = $true
        "ui-design@designer-skills" = $true
        "interaction-design@designer-skills" = $true
        "prototyping-testing@designer-skills" = $true
        "design-ops@designer-skills" = $true
        "designer-toolkit@designer-skills" = $true
        "visual-critique@designer-skills" = $true
        "product-strategy@wondelai-skills" = $true
        "ux-design@wondelai-skills" = $true
        "marketing-cro@wondelai-skills" = $true
        "sales-influence@wondelai-skills" = $true
        "product-innovation@wondelai-skills" = $true
        "strategy-growth@wondelai-skills" = $true
        "team-motivation@wondelai-skills" = $true
        "code-craftsmanship@wondelai-skills" = $true
        "systems-architecture@wondelai-skills" = $true
    }
    extraKnownMarketplaces = @{
        "ui-ux-pro-max-skill" = @{
            source = @{
                source = "github"
                repo = "nextlevelbuilder/ui-ux-pro-max-skill"
            }
        }
        "interface-design" = @{
            source = @{
                source = "github"
                repo = "Dammyjay93/interface-design"
            }
        }
        "designer-skills" = @{
            source = @{
                source = "github"
                repo = "Owl-Listener/designer-skills"
            }
        }
        "wondelai-skills" = @{
            source = @{
                source = "github"
                repo = "wondelai/skills"
            }
        }
    }
    skipDangerousModePermissionPrompt = $true
    theme = "light"
    autoUpdate = $false
}

$settings | ConvertTo-Json -Depth 6 | Set-Content -Path "$claudeDir\settings.json" -Encoding UTF8
Write-Host "  Claude Code configured" -ForegroundColor $green

# ── PowerShell profile ──
Write-Host "[7/7] Configuring PowerShell profile..." -ForegroundColor $cyan

$profileDir = Split-Path $PROFILE -Parent
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

$profileLines = @(
    "",
    "# ======================================",
    "# Claude Code + DeepSeek aliases",
    "# ======================================",
    "",
    "# ds-server - start proxy (separate window)",
    'function ds-server { cd "D:\AI BASE\DEEPSEEK"; uv run uvicorn server:app --host 127.0.0.1 --port 8082 }',
    "",
    "# ds - Claude Code via DeepSeek proxy (daily driver)",
    "function ds {",
    '    python "$env:USERPROFILE\.claude\cc-start.py"',
    '    $env:ANTHROPIC_BASE_URL = "http://127.0.0.1:8082"',
    '    $env:ANTHROPIC_AUTH_TOKEN = "freecc"',
    '    $env:CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY = "1"',
    "    claude",
    '    python "$env:USERPROFILE\.claude\cc-end.py"',
    "}",
    "",
    "# cc - Claude Code direct to Anthropic (complex tasks)",
    "function cc {",
    '    $env:ANTHROPIC_BASE_URL = "https://api.anthropic.com"',
    '    $env:ANTHROPIC_AUTH_TOKEN = "sk-ant-your-real-anthropic-key"',
    "    claude",
    "}",
    "",
    "# dsfull - proxy + ds in one go",
    "function dsfull {",
    "    ds-server",
    "    Start-Sleep -Seconds 3",
    "    ds",
    "}",
    "",
    'Write-Host "Aliases loaded: ds-server, ds, cc, dsfull" -ForegroundColor Cyan'
)

if (Test-Path $PROFILE) {
    $existing = Get-Content $PROFILE -Raw
    if ($existing -notmatch "function ds-server") {
        $profileLines | Add-Content -Path $PROFILE -Encoding UTF8
    }
} else {
    $profileLines | Set-Content -Path $PROFILE -Encoding UTF8
}

Write-Host "  PowerShell profile configured" -ForegroundColor $green

# ── Done ──
Write-Host ""
Write-Host "=====================================" -ForegroundColor $cyan
Write-Host "  SETUP COMPLETE!                     " -ForegroundColor $green
Write-Host "=====================================" -ForegroundColor $cyan
Write-Host ""
Write-Host "=== NEXT: MANUAL STEPS ===" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Copy .env to project dir:" -ForegroundColor $cyan
Write-Host "   (if you didn't enter API key above)" -ForegroundColor Gray
Write-Host "   copy <source> ""D:\AI BASE\DEEPSEEK\.env""" -ForegroundColor Green
Write-Host ""
Write-Host "2. VS Code extensions:" -ForegroundColor $cyan
Write-Host "   code --install-extension anthropic.claude-code"
Write-Host "   code --install-extension ms-python.python"
Write-Host "   code --install-extension ms-python.vscode-pylance"
Write-Host "   code --install-extension ms-python.debugpy"
Write-Host "   code --install-extension usernamehw.errorlens"
Write-Host "   code --install-extension christian-kohler.path-intellisense"
Write-Host "   code --install-extension esbenp.prettier-vscode"
Write-Host "   code --install-extension dbaeumer.vscode-eslint"
Write-Host "   code --install-extension eamodio.gitlens"
Write-Host ""
Write-Host "3. VS Code settings (add to settings.json):" -ForegroundColor $cyan
Write-Host '   "claudeCode.preferredLocation": "panel"'
Write-Host '   "claudeCode.environmentVariables": ['
Write-Host '     { "name": "ANTHROPIC_BASE_URL", "value": "http://localhost:8082" },'
Write-Host '     { "name": "ANTHROPIC_AUTH_TOKEN", "value": "freecc" },'
Write-Host '     { "name": "CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY", "value": "1" }'
Write-Host '   ]'
Write-Host ""
Write-Host "4. Copy VS Code keybindings.json (Shift+Enter for terminal):" -ForegroundColor $cyan
Write-Host "   Copy your keybindings.json to %APPDATA%\Code\User\keybindings.json"
Write-Host '   Content: [{ "key": "shift+enter", "command": "workbench.action.terminal.sendSequence", "args": { "text": "\r" }, "when": "terminalFocus" }]'
Write-Host ""
Write-Host "=== USAGE ===" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Terminal 1:  ds-server" -ForegroundColor $green
Write-Host "  Terminal 2:  ds" -ForegroundColor $green
Write-Host ""
Write-Host "  Or single window:  dsfull" -ForegroundColor $green
Write-Host ""
