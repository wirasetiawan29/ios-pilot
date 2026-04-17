#!/usr/bin/env bash
# ios-pilot installer
# Usage: curl -fsSL https://raw.githubusercontent.com/wirasetiawan29/ios-pilot/main/install.sh | bash

set -e

REPO="https://github.com/wirasetiawan29/ios-pilot.git"
INSTALL_DIR="$HOME/ios-pilot"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

print_step()  { echo -e "\n${BLUE}==>${NC} ${BOLD}$1${NC}"; }
print_ok()    { echo -e "  ${GREEN}✓${NC} $1"; }
print_warn()  { echo -e "  ${YELLOW}⚠${NC}  $1"; }
print_error() { echo -e "  ${RED}✗${NC} $1"; }

echo ""
echo -e "${BOLD}ios-pilot${NC} — Agentic iOS development pipeline"
echo "────────────────────────────────────────────────"

# ── 1. OS check ──────────────────────────────────────
print_step "Checking environment"

if [[ "$OSTYPE" != "darwin"* ]]; then
  print_error "ios-pilot requires macOS (Xcode is macOS-only)"
  exit 1
fi
print_ok "macOS detected"

# ── 2. Claude Code ───────────────────────────────────
if command -v claude &>/dev/null; then
  print_ok "Claude Code found ($(claude --version 2>/dev/null | head -1))"
else
  print_warn "Claude Code not found"
  echo "       Install it from: https://claude.ai/code"
fi

# ── 3. Xcode ─────────────────────────────────────────
if xcode-select -p &>/dev/null; then
  print_ok "Xcode command line tools found"
else
  print_warn "Xcode not found — install from Mac App Store"
fi

# ── 4. Homebrew ───────────────────────────────────────
if ! command -v brew &>/dev/null; then
  print_step "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  print_ok "Homebrew installed"
else
  print_ok "Homebrew found"
fi

# ── 5. xcodegen ──────────────────────────────────────
print_step "Checking dependencies"

if command -v xcodegen &>/dev/null; then
  print_ok "xcodegen found ($(xcodegen --version 2>/dev/null))"
else
  echo "  Installing xcodegen..."
  brew install xcodegen
  print_ok "xcodegen installed"
fi

# ── 6. gh CLI (optional) ─────────────────────────────
if command -v gh &>/dev/null; then
  print_ok "gh CLI found (MR/PR creation enabled)"
elif command -v glab &>/dev/null; then
  print_ok "glab CLI found (GitLab MR creation enabled)"
else
  print_warn "gh / glab not found — MR/PR creation will be unavailable"
  echo "       Install with: brew install gh   (GitHub)"
  echo "                 or: brew install glab (GitLab)"
fi

# ── 7. Clone or update ───────────────────────────────
print_step "Installing ios-pilot"

if [ -d "$INSTALL_DIR/.git" ]; then
  echo "  Existing installation found — updating..."
  git -C "$INSTALL_DIR" pull --ff-only
  print_ok "Updated to latest"
else
  if [ -d "$INSTALL_DIR" ]; then
    print_error "Directory $INSTALL_DIR already exists but is not a git repo"
    echo "       Remove it first: rm -rf $INSTALL_DIR"
    exit 1
  fi
  git clone --depth 1 "$REPO" "$INSTALL_DIR"
  print_ok "Cloned to $INSTALL_DIR"
fi

INSTALLED_VERSION=$(cat "$INSTALL_DIR/VERSION" 2>/dev/null || echo "unknown")
print_ok "Version: $INSTALLED_VERSION"

# ── 8. Install ios-pilot CLI command ─────────────────
print_step "Installing ios-pilot command"

BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"

ln -sfn "$INSTALL_DIR/bin/ios-pilot" "$BIN_DIR/ios-pilot"
print_ok "Linked: ios-pilot → $BIN_DIR/ios-pilot"

# Add ~/.local/bin to PATH if not already there
_add_to_path() {
  local rc_file="$1"
  local line='export PATH="$HOME/.local/bin:$PATH"'
  if [ -f "$rc_file" ] && ! grep -q '.local/bin' "$rc_file"; then
    echo "" >> "$rc_file"
    echo "# ios-pilot" >> "$rc_file"
    echo "$line" >> "$rc_file"
    print_ok "Added ~/.local/bin to PATH in $rc_file"
  fi
}

if [[ "$SHELL" == */zsh ]]; then
  _add_to_path "$HOME/.zshrc"
elif [[ "$SHELL" == */bash ]]; then
  _add_to_path "$HOME/.bash_profile"
  _add_to_path "$HOME/.bashrc"
fi

# Verify command is reachable
if command -v ios-pilot &>/dev/null || [ -x "$BIN_DIR/ios-pilot" ]; then
  print_ok "Command ready: ios-pilot"
else
  print_warn "Run: source ~/.zshrc (or restart terminal) to activate ios-pilot command"
fi

# ── 9. Done ──────────────────────────────────────────
echo ""
echo "────────────────────────────────────────────────"
echo -e "${GREEN}${BOLD}ios-pilot installed successfully!${NC}"
echo ""
echo -e "${BOLD}Usage:${NC}"
echo ""
echo "  Sandbox Mode — from anywhere:"
echo "  ${BOLD}ios-pilot${NC}"
echo ""
echo "  Project Mode — from your Xcode project:"
echo "  ${BOLD}cd ~/Projects/MyApp && ios-pilot${NC}"
echo "  → Project auto-linked. Tell Claude: project: MyApp"
echo ""
echo "  Other commands:"
echo "  ios-pilot update    — pull latest version"
echo "  ios-pilot doctor    — check environment"
echo "  ios-pilot version   — show installed version"
echo ""
echo "  Docs: https://github.com/wirasetiawan29/ios-pilot"
echo ""
echo -e "${YELLOW}Tip:${NC} If 'ios-pilot' is not found, run: source ~/.zshrc"
echo ""
