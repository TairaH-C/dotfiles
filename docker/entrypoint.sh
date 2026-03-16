#!/bin/bash
set -euo pipefail

# Source Cargo env if available
if [[ -f "$HOME/.cargo/env" ]]; then
  source "$HOME/.cargo/env"
fi

# Re-run symlinks in case dotfiles were updated
bash "$HOME/.dotfiles/scripts/setup-symlinks.sh" 2>/dev/null || true

# Neovim headless bootstrap (first run only)
BOOTSTRAP_MARKER="$HOME/.local/share/nvim/.bootstrap_done"
if [[ ! -f "$BOOTSTRAP_MARKER" ]]; then
  echo "==> Running Neovim headless bootstrap (first run)..."
  nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
  mkdir -p "$(dirname "$BOOTSTRAP_MARKER")"
  touch "$BOOTSTRAP_MARKER"
  echo "==> Neovim bootstrap complete."
fi

# Tmux plugin install (first run only)
TPM_MARKER="$HOME/.tmux/plugins/.bootstrap_done"
if [[ ! -f "$TPM_MARKER" ]]; then
  echo "==> Installing tmux plugins..."
  tmux new-session -d -s bootstrap 2>/dev/null || true
  "$HOME/.tmux/plugins/tpm/bin/install_plugins" 2>/dev/null || true
  tmux kill-session -t bootstrap 2>/dev/null || true
  mkdir -p "$(dirname "$TPM_MARKER")"
  touch "$TPM_MARKER"
  echo "==> Tmux plugins installed."
fi

exec "$@"
