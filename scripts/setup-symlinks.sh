#!/bin/bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

echo "==> Setting up symlinks..."

# Track what we created so we can roll back on failure.
CREATED_LINKS=()
BACKED_UP=()

rollback() {
  local rc=$?
  if [[ $rc -ne 0 ]]; then
    echo "==> Failure detected (exit $rc). Rolling back..."
    # Remove links we created in this run.
    for link in "${CREATED_LINKS[@]}"; do
      [[ -L "$link" ]] && rm -f "$link" && echo "  ↩ removed $link"
    done
    # Restore each "backup -> original" pair we recorded.
    for entry in "${BACKED_UP[@]}"; do
      local backup="${entry%%::*}"
      local original="${entry##*::}"
      if [[ -e "$backup" && ! -e "$original" ]]; then
        mv "$backup" "$original"
        echo "  ↩ restored $original from $backup"
      fi
    done
  fi
  exit $rc
}
trap rollback EXIT

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
    BACKED_UP+=("${backup}::${target}")
  fi

  ln -s "$source" "$target"
  CREATED_LINKS+=("$target")
  echo "  ✓ $target → $(basename "$source")"
}

# Shell
mkdir -p "$HOME"
create_symlink "$DOTFILES_DIR/shell/.zshrc" "$HOME/.zshrc"
create_symlink "$DOTFILES_DIR/shell/.aliases" "$HOME/.aliases"

# Git
create_symlink "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
create_symlink "$DOTFILES_DIR/git/.gitignore_global" "$HOME/.gitignore_global"

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
trap - EXIT
