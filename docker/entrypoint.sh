#!/bin/bash
set -euo pipefail

# Fix volume ownership if running as root (named volumes may be created as root)
if [ "$(id -u)" = "0" ]; then
  chown -R 1000:1000 \
    /home/dev/.config \
    /home/dev/.cache \
    /home/dev/.local/state \
    /home/dev/.local/share/nvim \
    /home/dev/.local/state/nvim \
    /home/dev/.cache/nvim \
    /home/dev/.cache/uv \
    /home/dev/.tmux/plugins \
    /home/dev/.local/share/zinit \
    /home/dev/.local/share/zoxide \
    /home/dev/.claude \
    2>/dev/null || true
fi

# Re-run symlinks in case dotfiles were updated (run as dev user)
su -s /bin/bash dev -c 'bash "/home/dev/workspace/dotfiles/scripts/setup-symlinks.sh" 2>/dev/null || true'

# Neovim headless bootstrap (first run only) - run as dev user
su -s /bin/bash dev -c '
BOOTSTRAP_MARKER="$HOME/.local/share/nvim/.bootstrap_done"
if [[ ! -f "$BOOTSTRAP_MARKER" ]]; then
  echo "==> Running Neovim headless bootstrap (first run)..."
  nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
  echo "==> Installing Treesitter parsers..."
  nvim --headless "+lua require(\"nvim-treesitter\").install({\"lua\",\"vim\",\"vimdoc\",\"json\",\"yaml\",\"toml\",\"bash\",\"markdown\",\"markdown_inline\",\"python\",\"typescript\",\"tsx\",\"javascript\",\"html\",\"css\",\"dockerfile\",\"gitcommit\",\"diff\",\"regex\",\"query\"})" "+sleep 120" +qa 2>/dev/null || true
  mkdir -p "$(dirname "$BOOTSTRAP_MARKER")"
  touch "$BOOTSTRAP_MARKER"
  echo "==> Neovim bootstrap complete."
fi
'

# Tmux plugin install (first run only) - run as dev user
su -s /bin/bash dev -c '
TPM_MARKER="$HOME/.tmux/plugins/.bootstrap_done"
if [[ ! -f "$TPM_MARKER" ]]; then
  echo "==> Installing tmux plugins..."
  mkdir -p "$HOME/.tmux/plugins"
  
  # Clone tpm if not already present
  if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    echo "    → Cloning tpm..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm" 2>/dev/null || true
  fi
  
  # Clone plugins directly (simpler than using tpm installer in non-interactive mode)
  # Format: "repo/url:directory_name"  (if no colon, use second part of URL)
  declare -a plugins=(
    "tmux-plugins/tmux-sensible"
    "tmux-plugins/tmux-resurrect"
    "tmux-plugins/tmux-continuum"
    "catppuccin/tmux:catppuccin"
    "christoomey/vim-tmux-navigator"
  )
  
  for plugin_spec in "${plugins[@]}"; do
    plugin_url="${plugin_spec%:*}"  # Everything before colon
    plugin_name="${plugin_spec#*:}"  # Everything after colon
    if [[ "$plugin_name" == "$plugin_url" ]]; then
      # No colon provided, use second part of URL
      plugin_name=$(echo "$plugin_url" | cut -d/ -f2)
    fi
    
    if [[ ! -d "$HOME/.tmux/plugins/$plugin_name" ]]; then
      echo "    → Cloning $plugin_name from $plugin_url..."
      git clone "https://github.com/$plugin_url" "$HOME/.tmux/plugins/$plugin_name" 2>/dev/null || true
    fi
  done
  
  mkdir -p "$(dirname "$TPM_MARKER")"
  touch "$TPM_MARKER"
  echo "==> Tmux plugins installed."
fi
'

exec "$@"
