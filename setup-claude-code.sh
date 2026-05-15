#!/usr/bin/env bash
# ============================================================
#  setup-claude-code.sh
#  Sets up Node.js (via NVM) + Claude Code on a fresh Ubuntu EC2
#  Configured to use MiniMax via opencode.ai/zen
#  Usage: bash setup-claude-code.sh
# ============================================================

set -euo pipefail

# ── Colour helpers ────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# ── Config ────────────────────────────────────────────────────
NODE_VERSION="22"       # LTS — works perfectly with Claude Code
NVM_VERSION="v0.40.3"  # pin NVM release for reproducibility

# ── Prompt for MiniMax API key ────────────────────────────────
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}   Claude Code — MiniMax Setup${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""

while true; do
  read -rsp "  Enter your MiniMax API key: " USER_API_KEY </dev/tty
  echo ""
  if [ -n "${USER_API_KEY}" ]; then
    break
  fi
  warn "API key cannot be empty. Please try again."
done

info "API key received. Will be saved to ~/.claude/settings.json"

# ── 1. System packages ────────────────────────────────────────
info "Updating package lists and installing prerequisites..."
sudo apt-get update -qq
sudo apt-get install -y -qq curl git ripgrep unzip

# ── 2. Install NVM ────────────────────────────────────────────
if [ -d "$HOME/.nvm" ]; then
  warn "NVM already present at ~/.nvm — skipping NVM install."
else
  info "Installing NVM ${NVM_VERSION}..."
  curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
fi

# Load NVM into current shell session
export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Verify NVM loaded
command -v nvm &>/dev/null || error "NVM failed to load. Try running: source ~/.bashrc"

# ── 3. Install Node.js ────────────────────────────────────────
if nvm ls "${NODE_VERSION}" 2>/dev/null | grep -q "v${NODE_VERSION}"; then
  warn "Node.js ${NODE_VERSION} is already installed — skipping."
else
  info "Installing Node.js ${NODE_VERSION} LTS..."
  nvm install "${NODE_VERSION}"
fi

info "Setting Node.js ${NODE_VERSION} as default..."
nvm alias default "${NODE_VERSION}"
nvm use default

# ── 4. Verify Node & npm ──────────────────────────────────────
NODE_VER=$(node --version)
NPM_VER=$(npm --version)
info "Node.js: ${NODE_VER}  |  npm: ${NPM_VER}"

# Enforce minimum Node version (18+)
MAJOR=$(echo "${NODE_VER}" | sed 's/v//' | cut -d. -f1)
[ "${MAJOR}" -ge 18 ] || error "Node.js 18+ required. Got ${NODE_VER}."

# ── 5. Install Claude Code ────────────────────────────────────
info "Installing Claude Code globally..."
npm install -g @anthropic-ai/claude-code@latest

# ── 6. Verify Claude Code ─────────────────────────────────────
CLAUDE_VER=$(claude --version 2>/dev/null || echo "not found")
if [[ "${CLAUDE_VER}" == "not found" ]]; then
  warn "claude binary not in PATH yet. This is normal — run:"
  warn "  source ~/.bashrc && claude --version"
else
  info "Claude Code installed: ${CLAUDE_VER}"
fi

# ── 7. Persist NVM in shell profile ──────────────────────────
SHELL_RC="$HOME/.bashrc"
if ! grep -q 'NVM_DIR' "${SHELL_RC}" 2>/dev/null; then
  info "Adding NVM init lines to ${SHELL_RC}..."
  cat >> "${SHELL_RC}" <<'BASHRC'

# NVM — added by setup-claude-code.sh
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
BASHRC
fi

# ── 8. Write ~/.claude/settings.json ─────────────────────────
CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"

info "Creating ${SETTINGS_FILE}..."
mkdir -p "${CLAUDE_DIR}"

cat > "${SETTINGS_FILE}" <<SETTINGS
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://opencode.ai/zen",
    "ANTHROPIC_MODEL": "minimax-m2.5-free",
    "ANTHROPIC_API_KEY": "${USER_API_KEY}",
    "ENABLE_TOOL_SEARCH": "true"
  },
  "model": "minimax-m2.5-free",
  "theme": "dark"
}
SETTINGS

# Lock down permissions — only owner can read the key
chmod 600 "${SETTINGS_FILE}"
info "Settings saved. Permissions set to 600 (owner read/write only)."

# ── Done ──────────────────────────────────────────────────────
echo ""
info "✅  Setup complete!"
echo ""
echo "  What was configured:"
echo "    • Node.js ${NODE_VERSION} LTS      (via NVM)"
echo "    • Claude Code              (latest)"
echo "    • Model:                   minimax-m2.5-free"
echo "    • Base URL:                https://opencode.ai/zen"
echo "    • Settings file:           ${SETTINGS_FILE}"
echo ""
echo "  Next step:"
echo "    source ~/.bashrc && claude"
echo ""
