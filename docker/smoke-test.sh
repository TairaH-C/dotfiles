#!/usr/bin/env bash
# Build verification script for Dev Container
# Checks existence of all CLI tools and validates critical components

# Run validations as dev user when invoked as root (docker exec default)
if [[ "$(id -u)" -eq 0 ]] && id dev >/dev/null 2>&1; then
  exec su -s /bin/bash dev -c "/home/dev/workspace/dotfiles/docker/smoke-test.sh"
fi

# ANSI color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
RESET='\033[0m'

# Track failures
FAILURES=()

# Function to check if command exists
check_command() {
  local cmd="$1"
  local display_name="${2:-$cmd}"

  if command -v "$cmd" &> /dev/null; then
    echo -e "${GREEN}[PASS]${RESET} $display_name"
    return 0
  else
    echo -e "${RED}[FAIL]${RESET} $display_name: command not found"
    FAILURES+=("$display_name")
    return 1
  fi
}

# Function to check file exists
check_file() {
  local file="$1"
  local display_name="${2:-$file}"

  if [[ -f "$file" ]]; then
    echo -e "${GREEN}[PASS]${RESET} $display_name"
    return 0
  else
    echo -e "${RED}[FAIL]${RESET} $display_name: file not found"
    FAILURES+=("$display_name")
    return 1
  fi
}

# Function to check directory exists
check_dir() {
  local dir="$1"
  local display_name="${2:-$dir}"

  if [[ -d "$dir" ]]; then
    echo -e "${GREEN}[PASS]${RESET} $display_name"
    return 0
  else
    echo -e "${RED}[FAIL]${RESET} $display_name: directory not found"
    FAILURES+=("$display_name")
    return 1
  fi
}

echo "=== Dev Container Build Verification ==="
echo ""

# System utilities
echo "Checking system utilities..."
check_command "git" "git"
check_command "curl" "curl"
check_command "wget" "wget"
check_command "unzip" "unzip"
check_command "make" "make (build-essential)"

# Shell tools
echo ""
echo "Checking shell tools..."
check_command "zsh" "zsh"
check_command "tmux" "tmux"
if zsh -i -c "type zinit" &> /dev/null; then
  echo -e "${GREEN}[PASS]${RESET} zinit"
else
  echo -e "${RED}[FAIL]${RESET} zinit: not available in interactive zsh"
  FAILURES+=("zinit")
fi

# CLI enhancements
echo ""
echo "Checking CLI tools..."
check_command "fdfind" "fd (fdfind)"
check_command "rg" "ripgrep (rg)"
check_command "batcat" "bat (batcat)"
check_command "eza" "eza"
check_command "fzf" "fzf"
check_command "zoxide" "zoxide"
check_command "starship" "starship"
check_command "delta" "delta"
check_command "lazygit" "lazygit"

# Python ecosystem
echo ""
echo "Checking Python ecosystem..."
check_command "uv" "uv"

# Node.js
echo ""
echo "Checking Node.js ecosystem..."
check_command "node" "node"
check_command "npm" "npm"

# AI tools
echo ""
echo "Checking AI tools..."
check_command "claude" "Claude Code (claude)"
check_command "opencode" "OpenCode (opencode)"

# Neovim
echo ""
echo "Checking Neovim..."
check_command "nvim" "Neovim (nvim)"

# Verify Neovim version
if command -v nvim &> /dev/null; then
  NVIM_VERSION=$(nvim --version | head -1)
  echo -e "${GREEN}[PASS]${RESET} Neovim version: $NVIM_VERSION"
fi

# Neovim checkhealth
echo ""
echo "Checking Neovim health..."
HEALTH_OUTPUT=$(nvim --headless "+checkhealth" +qa 2>&1)
HEALTH_ERRORS=$(echo "$HEALTH_OUTPUT" | grep -c "ERROR" || true)
HEALTH_ERRORS="${HEALTH_ERRORS:-0}"

if [[ "$HEALTH_ERRORS" -eq 0 ]]; then
  echo -e "${GREEN}[PASS]${RESET} Neovim checkhealth: no errors"
else
  echo -e "${RED}[FAIL]${RESET} Neovim checkhealth: $HEALTH_ERRORS errors found"
  echo "$HEALTH_OUTPUT" | grep "ERROR" || true
  FAILURES+=("Neovim checkhealth")
fi

# Shell startup tests
echo ""
echo "Checking shell functionality..."

# Test zsh startup
if zsh -c "echo ok" &> /dev/null; then
  echo -e "${GREEN}[PASS]${RESET} zsh startup"
else
  echo -e "${RED}[FAIL]${RESET} zsh startup: failed to initialize"
  FAILURES+=("zsh startup")
fi

# Test tmux startup
if tmux new-session -d -s "test-$$" &> /dev/null && tmux kill-session -t "test-$$" &> /dev/null; then
  echo -e "${GREEN}[PASS]${RESET} tmux startup"
else
  echo -e "${RED}[FAIL]${RESET} tmux startup: failed to create session"
  FAILURES+=("tmux startup")
fi

# Test uv venv
echo ""
echo "Checking uv functionality..."
TEMP_VENV=$(mktemp -d)
if uv venv "$TEMP_VENV" &> /dev/null; then
  echo -e "${GREEN}[PASS]${RESET} uv venv creation"
  rm -rf "$TEMP_VENV"
else
  echo -e "${RED}[FAIL]${RESET} uv venv creation: failed"
  FAILURES+=("uv venv creation")
fi

# Git configuration
echo ""
echo "Checking Git configuration..."
GIT_USER=$(git config --global user.name 2>/dev/null || echo "")
GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")

if [[ -n "$GIT_USER" ]]; then
  echo -e "${GREEN}[PASS]${RESET} Git user.name configured: $GIT_USER"
else
  echo -e "${RED}[FAIL]${RESET} Git user.name: not configured"
  FAILURES+=("Git user.name")
fi

if [[ -n "$GIT_EMAIL" ]]; then
  echo -e "${GREEN}[PASS]${RESET} Git user.email configured: $GIT_EMAIL"
else
  echo -e "${RED}[FAIL]${RESET} Git user.email: not configured"
  FAILURES+=("Git user.email")
fi

# Locale check
echo ""
echo "Checking locale settings..."
LOCALE_INFO=$(locale | grep "LC_ALL\|LANG" || echo "")
if echo "$LOCALE_INFO" | grep -i "utf-8\|utf8\|C.UTF-8" &> /dev/null || [[ -z "$LOCALE_INFO" ]]; then
  echo -e "${GREEN}[PASS]${RESET} Locale: UTF-8 compatible"
else
  echo -e "${RED}[FAIL]${RESET} Locale: not UTF-8 compatible"
  FAILURES+=("Locale UTF-8")
fi

# Summary
echo ""
echo "=== Summary ==="

if [[ ${#FAILURES[@]} -eq 0 ]]; then
  echo -e "${GREEN}All checks passed!${RESET}"
  exit 0
else
  echo -e "${RED}Failed checks:${RESET}"
  for failure in "${FAILURES[@]}"; do
    echo -e "  ${RED}•${RESET} $failure"
  done
  exit 1
fi
