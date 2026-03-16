#!/bin/bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

echo "==> Setting up symlinks..."

# Shell
mkdir -p "$HOME"
ln -sf "$DOTFILES_DIR/shell/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTFILES_DIR/shell/.aliases" "$HOME/.aliases"

# Git
ln -sf "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"

# Neovim
mkdir -p "$XDG_CONFIG_HOME"
ln -sfn "$DOTFILES_DIR/neovim/nvim" "$XDG_CONFIG_HOME/nvim"

# Starship
mkdir -p "$XDG_CONFIG_HOME"
ln -sf "$DOTFILES_DIR/shell/starship.toml" "$XDG_CONFIG_HOME/starship.toml"

# Tmux
ln -sf "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"

# Lazygit
mkdir -p "$XDG_CONFIG_HOME/lazygit"
ln -sf "$DOTFILES_DIR/lazygit/config.yml" "$XDG_CONFIG_HOME/lazygit/config.yml"

echo "==> Symlinks created successfully!"
