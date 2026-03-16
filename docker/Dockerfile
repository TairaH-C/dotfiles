FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000

# ---------- System base ----------
RUN apt-get update -qq && apt-get install -y -qq \
    ca-certificates \
    curl \
    wget \
    git \
    sudo \
    locales \
    software-properties-common \
    zsh \
    && locale-gen en_US.UTF-8 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# ---------- Non-root user ----------
RUN groupadd --gid "$USER_GID" "$USERNAME" \
    && useradd --uid "$USER_UID" --gid "$USER_GID" \
       --shell /usr/bin/zsh \
       --create-home "$USERNAME" \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# ---------- Docker CLI (DooD) ----------
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
       -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] \
       https://download.docker.com/linux/ubuntu noble stable" \
       > /etc/apt/sources.list.d/docker.list \
    && apt-get update -qq \
    && apt-get install -y -qq docker-ce-cli \
    && usermod -aG docker "$USERNAME" \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ---------- Node.js 20 LTS ----------
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y -qq nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ---------- Copy dotfiles ----------
COPY --chown=${USERNAME}:${USERNAME} . /home/${USERNAME}/.dotfiles

# ---------- Switch to user ----------
USER ${USERNAME}
WORKDIR /home/${USERNAME}

# ---------- Install packages (idempotent) ----------
RUN bash /home/${USERNAME}/.dotfiles/scripts/install-packages.sh

# ---------- Claude Code CLI ----------
RUN npm install -g @anthropic-ai/claude-code

# ---------- PATH ----------
ENV PATH="/home/${USERNAME}/.local/bin:/usr/local/go/bin:/home/${USERNAME}/go/bin:/home/${USERNAME}/.cargo/bin:${PATH}"

# ---------- Symlinks ----------
RUN bash /home/${USERNAME}/.dotfiles/scripts/setup-symlinks.sh

# ---------- TPM (tmux plugin manager) ----------
RUN if [ ! -d "/home/${USERNAME}/.tmux/plugins/tpm" ]; then \
      git clone --depth=1 https://github.com/tmux-plugins/tpm \
        /home/${USERNAME}/.tmux/plugins/tpm; \
    fi

# ---------- Entrypoint ----------
COPY --chown=${USERNAME}:${USERNAME} docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["zsh"]
