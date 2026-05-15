# ============================================================
#  setup-claude-code.ps1
#  Sets up Node.js (via nvm-windows) + Claude Code on Windows
#  Configured to use MiniMax via opencode.ai/zen
#  Usage: Run in PowerShell as Administrator
#    irm https://raw.githubusercontent.com/PriyanshuValiya/Claude-Code/main/setup-claude-code.ps1 | iex
# ============================================================

$ErrorActionPreference = "Stop"

# ── Colour helpers ────────────────────────────────────────────
function Info  { param($msg) Write-Host "[INFO]  $msg" -ForegroundColor Green }
function Warn  { param($msg) Write-Host "[WARN]  $msg" -ForegroundColor Yellow }
function Err   { param($msg) Write-Host "[ERROR] $msg" -ForegroundColor Red; exit 1 }
function Step  { param($msg) Write-Host "[STEP]  $msg" -ForegroundColor Cyan }

# ── Config ────────────────────────────────────────────────────
$NODE_VERSION    = "22"
$NVM_WIN_VERSION = "1.1.12"   # pin nvm-windows release
$NVM_INSTALLER   = "$env:TEMP\nvm-setup.exe"
$NVM_WIN_URL     = "https://github.com/coreybutler/nvm-windows/releases/download/$NVM_WIN_VERSION/nvm-setup.exe"

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "   Claude Code - MiniMax Setup (Windows)  " -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""

# ── Check: running as Administrator ──────────────────────────
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $isAdmin) {
    Err "Please run this script as Administrator. Right-click PowerShell -> 'Run as administrator'."
}

# ── 1. Install winget prerequisites (git, ripgrep) ────────────
Info "Installing git and ripgrep via winget..."
$wingetApps = @("Git.Git", "BurntSushi.ripgrep.MSVC")
foreach ($app in $wingetApps) {
    $installed = winget list --id $app 2>$null | Select-String $app
    if ($installed) {
        Warn "$app is already installed — skipping."
    } else {
        winget install --id $app -e --silent --accept-source-agreements --accept-package-agreements
        Info "$app installed."
    }
}

# ── 2. Install nvm-windows ────────────────────────────────────
$nvmCmd = Get-Command nvm -ErrorAction SilentlyContinue
if ($nvmCmd) {
    Warn "nvm-windows is already installed — skipping."
} else {
    Info "Downloading nvm-windows $NVM_WIN_VERSION..."
    Invoke-WebRequest -Uri $NVM_WIN_URL -OutFile $NVM_INSTALLER -UseBasicParsing
    Info "Installing nvm-windows (silent)..."
    Start-Process -FilePath $NVM_INSTALLER -ArgumentList "/SILENT" -Wait
    Remove-Item $NVM_INSTALLER -Force

    # Reload PATH so nvm is available in this session
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("PATH", "User")
}

# Verify nvm loaded
$nvmCmd = Get-Command nvm -ErrorAction SilentlyContinue
if (-not $nvmCmd) {
    Warn "nvm not found in current PATH."
    Warn "Close this terminal, open a new Administrator PowerShell, and run the script again."
    exit 1
}

# ── 3. Install Node.js ────────────────────────────────────────
$installedNodes = nvm list 2>$null
if ($installedNodes -match $NODE_VERSION) {
    Warn "Node.js $NODE_VERSION is already installed — skipping."
} else {
    Info "Installing Node.js $NODE_VERSION LTS..."
    nvm install $NODE_VERSION
}

Info "Switching to Node.js $NODE_VERSION..."
nvm use $NODE_VERSION

# ── 4. Verify Node & npm ──────────────────────────────────────
$nodePath = Get-Command node -ErrorAction SilentlyContinue
if (-not $nodePath) {
    Err "node not found in PATH after nvm use. Close and reopen PowerShell as Admin and retry."
}

$nodeVer = node --version
$npmVer  = npm --version
Info "Node.js: $nodeVer  |  npm: $npmVer"

$major = [int]($nodeVer -replace 'v', '' -split '\.')[0]
if ($major -lt 18) { Err "Node.js 18+ required. Got $nodeVer." }

# ── 5. Install Claude Code ────────────────────────────────────
Info "Installing Claude Code globally..."
npm install -g @anthropic-ai/claude-code@latest

# ── 6. Verify Claude Code ─────────────────────────────────────
$claudeVer = & claude --version 2>$null
if ($LASTEXITCODE -ne 0 -or -not $claudeVer) {
    Warn "claude not found in PATH yet — close and reopen PowerShell after setup."
} else {
    Info "Claude Code installed: $claudeVer"
}

# ── 7. Collect MiniMax API key & write settings.json ─────────
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "   Almost done! One last step - API key setup" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "  How to get your MiniMax API key:"
Write-Host ""
Step "1. Open https://opencode.ai/download in your browser"
Step "2. Sign in (or create a free account)"
Step "3. Go to  Zen -> Get Started With Zen -> API Key"
Step "4. Click  'Create API Key',  give it a name, and copy it"
Write-Host ""

$USER_API_KEY = ""
while ($true) {
    $secureKey = Read-Host "  Paste your MiniMax API key here" -AsSecureString
    $USER_API_KEY = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
    )
    if ($USER_API_KEY.Trim() -ne "") { break }
    Warn "API key cannot be empty. Please try again."
}

$CLAUDE_DIR    = "$env:USERPROFILE\.claude"
$SETTINGS_FILE = "$CLAUDE_DIR\settings.json"

New-Item -ItemType Directory -Force -Path $CLAUDE_DIR | Out-Null

$settingsJson = @"
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://opencode.ai/zen",
    "ANTHROPIC_MODEL": "minimax-m2.5-free",
    "ANTHROPIC_API_KEY": "$USER_API_KEY",
    "ENABLE_TOOL_SEARCH": "true"
  },
  "model": "minimax-m2.5-free",
  "theme": "dark"
}
"@

Set-Content -Path $SETTINGS_FILE -Value $settingsJson -Encoding UTF8

# Lock down permissions — remove inheritance, grant only current user
$acl = Get-Acl $SETTINGS_FILE
$acl.SetAccessRuleProtection($true, $false)   # disable inheritance
$acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) | Out-Null }
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $env:USERNAME, "FullControl", "Allow"
)
$acl.AddAccessRule($rule)
Set-Acl -Path $SETTINGS_FILE -AclObject $acl

Info "Settings saved to $SETTINGS_FILE (private — only $env:USERNAME can read)"

# ── Done ──────────────────────────────────────────────────────
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "   Setup complete!                          " -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""
Write-Host "  Installed:"
Write-Host "    * Node.js $NODE_VERSION LTS"
Write-Host "    * Claude Code (latest)"
Write-Host ""
Write-Host "  Configured:"
Write-Host "    * Model:    minimax-m2.5-free"
Write-Host "    * Base URL: https://opencode.ai/zen"
Write-Host "    * Settings: $SETTINGS_FILE"
Write-Host ""
Write-Host "  Start using Claude Code:"
Write-Host "    Close this window, open a new PowerShell, then run:  claude"
Write-Host ""