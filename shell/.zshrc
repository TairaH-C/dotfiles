# =============================================================================
# Zsh Configuration
# =============================================================================

# -- XDG -----------------------------------------------------------------------

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# -- PATH ----------------------------------------------------------------------

export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# -- Zinit (plugin manager) ----------------------------------------------------

ZINIT_HOME="${XDG_DATA_HOME}/zinit"
if [[ -f "${ZINIT_HOME}/zinit.zsh" ]]; then
  source "${ZINIT_HOME}/zinit.zsh"

  # Plugins
  zinit light zsh-users/zsh-autosuggestions
  zinit light zsh-users/zsh-syntax-highlighting
  zinit light zsh-users/zsh-completions

  # Load completions
  autoload -Uz compinit && compinit
  zinit cdreplay -q
else
  # Fallback if zinit not installed
  autoload -Uz compinit && compinit
fi

# -- History -------------------------------------------------------------------

HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS

# -- Directory navigation ------------------------------------------------------

setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT

# -- Completion ----------------------------------------------------------------

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu select

# -- Key bindings (emacs mode) -------------------------------------------------

bindkey -e

# -- Aliases -------------------------------------------------------------------

[ -f "$HOME/.aliases" ] && source "$HOME/.aliases"

# -- FZF -----------------------------------------------------------------------

# Catppuccin Mocha colors
export FZF_DEFAULT_OPTS=" \
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
  --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
  --color=selected-bg:#45475a \
  --multi"

export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
[ -f /usr/share/doc/fzf/examples/completion.zsh ] && source /usr/share/doc/fzf/examples/completion.zsh

# -- Zoxide (smart cd) ---------------------------------------------------------

if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
fi

# -- Starship prompt -----------------------------------------------------------

if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi
