#!/bin/bash
set -euo pipefail

echo "==> Installing packages..."

# Core packages via apt
sudo apt-get update -qq
sudo apt-get install -y -qq \
  zsh \
  tmux \
  ripgrep \
  fd-find \
  bat \
  fzf \
  build-essential \
  cmake \
  unzip \
  curl \
  wget \
  git \
  luarocks \
  python3 \
  python3-pip \
  python3-venv \
  software-properties-common

# Node.js (skip if already installed, e.g. via NodeSource in Docker)
if ! command -v node &>/dev/null; then
  sudo apt-get install -y -qq nodejs npm
fi

# Neovim (latest stable from PPA)
if ! command -v nvim &>/dev/null; then
  echo "==> Installing Neovim..."
  sudo add-apt-repository -y ppa:neovim-ppa/unstable
  sudo apt-get update -qq
  sudo apt-get install -y -qq neovim
else
  nvim_minor=$(nvim --version | head -1 | grep -oP '\d+\.\d+' | head -1 | cut -d. -f2)
  if [[ "$nvim_minor" -lt 10 ]]; then
    echo "==> Upgrading Neovim..."
    sudo add-apt-repository -y ppa:neovim-ppa/unstable
    sudo apt-get update -qq
    sudo apt-get install -y -qq neovim
  fi
fi

# eza (modern ls)
if ! command -v eza &>/dev/null; then
  echo "==> Installing eza..."
  sudo mkdir -p /etc/apt/keyrings
  wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
  echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
  sudo apt-get update -qq
  sudo apt-get install -y -qq eza
fi

# zoxide (smart cd)
if ! command -v zoxide &>/dev/null; then
  echo "==> Installing zoxide..."
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
fi

# git-delta (better diffs)
if ! command -v delta &>/dev/null; then
  echo "==> Installing git-delta..."
  DELTA_VERSION="0.18.2"
  curl -sSfL "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_amd64.deb" -o /tmp/git-delta.deb
  sudo dpkg -i /tmp/git-delta.deb
  rm -f /tmp/git-delta.deb
fi

# lazygit
if ! command -v lazygit &>/dev/null; then
  echo "==> Installing lazygit..."
  LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
  curl -sSfL "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" | tar xzf - -C /tmp lazygit
  sudo install /tmp/lazygit /usr/local/bin/lazygit
  rm -f /tmp/lazygit
fi

# starship prompt
if ! command -v starship &>/dev/null; then
  echo "==> Installing starship..."
  curl -sSfL https://starship.rs/install.sh | sh -s -- -y
fi

# Go (for gopls etc.)
if ! command -v go &>/dev/null; then
  echo "==> Installing Go..."
  GO_VERSION=$(curl -sSfL "https://go.dev/VERSION?m=text" | head -1 | sed 's/go//')
  curl -sSfL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" | sudo tar -C /usr/local -xzf -
  echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> "$HOME/.profile"
  export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
fi

# Rust (for rust-analyzer etc.)
if ! command -v rustup &>/dev/null; then
  echo "==> Installing Rust..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env"
fi

# zinit (zsh plugin manager)
if [[ ! -d "$HOME/.local/share/zinit" ]]; then
  echo "==> Installing zinit..."
  NO_INPUT=1 bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
fi

# TPM (tmux plugin manager)
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
  echo "==> Installing TPM..."
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

echo "==> Package installation complete!"
