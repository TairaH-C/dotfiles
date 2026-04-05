FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

# ---- User ----
ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000

# ---- APT package versions (Ubuntu 24.04) ----
ARG GIT_VERSION=1:2.43.0-1ubuntu7.3
ARG CURL_VERSION=8.5.0-2ubuntu10.8
ARG WGET_VERSION=1.21.4-1ubuntu4.1
ARG UNZIP_VERSION=6.0-28ubuntu4.1
ARG BUILD_ESSENTIAL_VERSION=12.10ubuntu1
ARG NCURSES_TERM_VERSION=6.4+20240113-1ubuntu2
ARG LOCALES_VERSION=2.39-0ubuntu8.7
ARG ZSH_VERSION=5.9-6ubuntu2
ARG TMUX_VERSION=3.4-1ubuntu0.1
ARG FD_FIND_VERSION=9.0.0-1
ARG RIPGREP_VERSION=14.1.0-1
ARG BAT_VERSION=0.24.0-1build1

# ---- Tool versions ----
ARG UV_VERSION=0.6.9
ARG NEOVIM_VERSION=v0.11.6
ARG FZF_VERSION=0.60.3
ARG EZA_VERSION=v0.23.4
ARG ZOXIDE_VERSION=0.9.9
ARG STARSHIP_VERSION=v1.24.2
ARG DELTA_VERSION=0.19.2
ARG LAZYGIT_VERSION=0.46.1
ARG LAZYGIT_FALLBACK_VERSION=0.46.0
ARG NODE_VERSION=22.22.2
ARG CLAUDE_CODE_VERSION=2.1.91
ARG OPENCODE_VERSION=1.3.13
ARG OH_MY_OPENAGENTS_PACKAGE=oh-my-opencode
ARG OH_MY_OPENAGENTS_VERSION=3.14.0
ARG ZINIT_COMMIT=6c9ac1c4bc9bcaede64cb473759ac2c5b9187f98

ENV LANG=C.UTF-8
ENV TERM=xterm-256color
ENV SHELL=/usr/bin/zsh

# ---- System packages (low change frequency first) ----
RUN set -eux; \
    apt-get update -qq; \
    apt-get install -y -qq --no-install-recommends \
      ca-certificates \
      xz-utils \
      tar \
      git=${GIT_VERSION} \
      curl=${CURL_VERSION} \
      wget=${WGET_VERSION} \
      unzip=${UNZIP_VERSION} \
      build-essential=${BUILD_ESSENTIAL_VERSION} \
      ncurses-term=${NCURSES_TERM_VERSION} \
      locales=${LOCALES_VERSION} \
      zsh=${ZSH_VERSION} \
      tmux=${TMUX_VERSION} \
      fd-find=${FD_FIND_VERSION} \
      ripgrep=${RIPGREP_VERSION} \
      bat=${BAT_VERSION}; \
    locale-gen C.UTF-8; \
    rm -rf /var/lib/apt/lists/*

# Debian command compatibility
RUN ln -sf /usr/bin/fdfind /usr/local/bin/fd \
    && ln -sf /usr/bin/batcat /usr/local/bin/bat

# ---- Language runtimes ----
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    [ "$arch" = "amd64" ]; \
    curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" \
      | tar -xJ --strip-components=1 -C /usr/local

RUN set -eux; \
    curl -LsSf "https://astral.sh/uv/${UV_VERSION}/install.sh" | env INSTALLER_NO_MODIFY_PATH=1 sh; \
    mv /root/.local/bin/uv /usr/local/bin/uv; \
    mv /root/.local/bin/uvx /usr/local/bin/uvx

# ---- Neovim from GitHub Releases (.deb, no PPA) ----
RUN set -eux; \
    curl -fL "https://github.com/neovim/neovim-releases/releases/download/${NEOVIM_VERSION}/nvim-linux-x86_64.deb" -o /tmp/nvim.deb; \
    apt-get update -qq; \
    apt-get install -y -qq --no-install-recommends /tmp/nvim.deb; \
    rm -f /tmp/nvim.deb; \
    rm -rf /var/lib/apt/lists/*

# ---- CLI tools from GitHub Releases ----
RUN set -eux; \
    curl -fsSL "https://github.com/eza-community/eza/releases/download/${EZA_VERSION}/eza_x86_64-unknown-linux-gnu.tar.gz" \
      | tar xz -C /usr/local/bin --wildcards --no-anchored eza; \
    chmod +x /usr/local/bin/eza; \
    curl -fsSL "https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-linux_amd64.tar.gz" \
      | tar xz -C /usr/local/bin; \
    curl -fL "https://github.com/ajeetdsouza/zoxide/releases/download/v${ZOXIDE_VERSION}/zoxide_${ZOXIDE_VERSION}-1_amd64.deb" -o /tmp/zoxide.deb; \
    apt-get update -qq; \
    apt-get install -y -qq --no-install-recommends /tmp/zoxide.deb; \
    rm -f /tmp/zoxide.deb; \
    curl -fsSL "https://github.com/starship/starship/releases/download/${STARSHIP_VERSION}/starship-x86_64-unknown-linux-gnu.tar.gz" \
      | tar xz -C /usr/local/bin starship; \
    curl -fL "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_amd64.deb" -o /tmp/delta.deb; \
    apt-get install -y -qq --no-install-recommends /tmp/delta.deb; \
    rm -f /tmp/delta.deb; \
    if curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" \
      | tar xz -C /usr/local/bin lazygit; then \
      true; \
    else \
      curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_FALLBACK_VERSION}/lazygit_${LAZYGIT_FALLBACK_VERSION}_Linux_x86_64.tar.gz" \
        | tar xz -C /usr/local/bin lazygit; \
    fi; \
    rm -rf /var/lib/apt/lists/*

# ---- AI tools (npm global, pinned) ----
RUN set -eux; \
    for i in 1 2 3; do \
      if npm install -g \
        "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" \
        "opencode-ai@${OPENCODE_VERSION}" \
        "${OH_MY_OPENAGENTS_PACKAGE}@${OH_MY_OPENAGENTS_VERSION}"; then \
        break; \
      fi; \
      if [ "$i" -eq 3 ]; then \
        exit 1; \
      fi; \
      sleep $((i * 5)); \
    done; \
    ln -sf /usr/local/bin/oh-my-opencode /usr/local/bin/oh-my-openagents

# ---- Non-root user ----
RUN set -eux; \
    userdel -r ubuntu 2>/dev/null || true; \
    groupadd --gid "${USER_GID}" "${USERNAME}"; \
    useradd --uid "${USER_UID}" --gid "${USER_GID}" --shell /usr/bin/zsh --create-home "${USERNAME}"

# ---- zinit pinned commit ----
RUN set -eux; \
    git clone https://github.com/zdharma-continuum/zinit.git /tmp/zinit; \
    git -C /tmp/zinit checkout "${ZINIT_COMMIT}"; \
    mkdir -p /home/${USERNAME}/.local/share; \
    mv /tmp/zinit /home/${USERNAME}/.local/share/zinit; \
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}

USER ${USERNAME}
WORKDIR /home/${USERNAME}

CMD ["zsh"]
