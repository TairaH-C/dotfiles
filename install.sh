#!/bin/bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "========================================"
echo "  Dotfiles Installer"
echo "========================================"

# Install packages
bash "$DOTFILES_DIR/scripts/install-packages.sh"

# Setup symlinks
bash "$DOTFILES_DIR/scripts/setup-symlinks.sh"

# Set default shell to zsh
if [[ "$SHELL" != *"zsh"* ]]; then
  echo "==> Setting zsh as default shell..."
  chsh -s "$(which zsh)"
fi

echo "========================================"
echo "  Installation complete!"
echo "  Please restart your shell or run: exec zsh"
echo "  Then open tmux and press C-Space I to install tmux plugins"
echo "========================================"
