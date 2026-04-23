#!/bin/bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

echo "==> Setting up symlinks..."

# Helper function to create symlink with backup
create_symlink() {
  local source="$1"
  local target="$2"

  if [[ -L "$target" ]]; then
    # Already a symlink — replace unconditionally (idempotent)
    rm "$target"
  elif [[ -e "$target" ]]; then
    # Real file/dir exists. Use timestamped backup so repeated runs
    # never clobber an earlier .bak (which would lose the original).
    local backup="${target}.bak.$(date +%Y%m%d-%H%M%S)"
    echo "  → Backing up $target to $backup"
    mv "$target" "$backup"
  fi

  ln -s "$source" "$target"
  echo "  ✓ $target → $(basename "$source")"
}

# Shell
mkdir -p "$HOME"
create_symlink "$DOTFILES_DIR/shell/.zshrc" "$HOME/.zshrc"
create_symlink "$DOTFILES_DIR/shell/.aliases" "$HOME/.aliases"

# Git
create_symlink "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"

# Neovim (use -n flag to avoid following existing symlink)
mkdir -p "$XDG_CONFIG_HOME"
create_symlink "$DOTFILES_DIR/neovim/nvim" "$XDG_CONFIG_HOME/nvim"

# Starship
mkdir -p "$XDG_CONFIG_HOME"
create_symlink "$DOTFILES_DIR/shell/starship.toml" "$XDG_CONFIG_HOME/starship.toml"

# Tmux
create_symlink "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"

# Lazygit
mkdir -p "$XDG_CONFIG_HOME/lazygit"
create_symlink "$DOTFILES_DIR/lazygit/config.yml" "$XDG_CONFIG_HOME/lazygit/config.yml"

echo "==> Symlinks created successfully!"
