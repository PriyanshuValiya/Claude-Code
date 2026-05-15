#!/usr/bin/env bash
# ============================================================
#  setup-claude-code.sh
#  Sets up Node.js (via NVM) + Claude Code on a fresh Ubuntu EC2
#  Usage: bash setup-claude-code.sh
# ============================================================

set -euo pipefail

# ── Colour helpers ────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# ── Config ────────────────────────────────────────────────────
NODE_VERSION="22"          # LTS — works perfectly with Claude Code
NVM_VERSION="v0.40.3"     # pin NVM release for reproducibility

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
# NVM install script usually handles this, but we double-check.
SHELL_RC="$HOME/.bashrc"
if ! grep -q 'NVM_DIR' "${SHELL_RC}" 2>/dev/null; then
  info "Adding NVM init lines to ${SHELL_RC}..."
  cat >> "${SHELL_RC}" <<'EOF'

# NVM — added by setup-claude-code.sh
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
EOF
fi

# ── Done ──────────────────────────────────────────────────────
echo ""
info "✅  Setup complete!"
echo ""
echo "  Next steps:"
echo "    1. Reload your shell:  source ~/.bashrc"
echo "    2. Authenticate:       claude"
echo "       (Browser-based OAuth or set ANTHROPIC_API_KEY env var for headless/CI)"
echo ""