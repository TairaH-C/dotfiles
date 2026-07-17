#!/bin/bash
# Container entrypoint (runs as root): fix home-volume ownership, run the
# user-level bootstrap (docker/bootstrap.sh), then hand off to the main
# command. Keep root-only concerns here; everything else goes in bootstrap.sh.
set -uo pipefail

log() { echo "[entrypoint] $*"; }

DEV_UID=1000
DEV_GID=1000
DEV_HOME=/home/dev
SENTINEL="$DEV_HOME/.devenv_initialized"

if [ "$(id -u)" = "0" ]; then
  # -xdev keeps find inside the home volume (never descends into the
  # workspace / .ssh bind mounts); read-only mount points are pruned.
  if [ ! -e "$SENTINEL" ]; then
    log "First start with this home volume: normalizing ownership..."
    find "$DEV_HOME" -xdev \
      \( -path "$DEV_HOME/workspace" -o -path "$DEV_HOME/.ssh" -o -path "$DEV_HOME/.config/github-copilot" \) -prune -o \
      \( ! -uid "$DEV_UID" -o ! -gid "$DEV_GID" \) -exec chown -h "$DEV_UID:$DEV_GID" {} + || true
    su -s /bin/bash dev -c "touch '$SENTINEL'"
  else
    # Cheap safety net for files dropped in as root (e.g. via docker cp)
    find "$DEV_HOME" -maxdepth 1 -xdev \
      \( -path "$DEV_HOME/workspace" -o -path "$DEV_HOME/.ssh" \) -prune -o \
      \( ! -uid "$DEV_UID" -o ! -gid "$DEV_GID" \) -exec chown -h "$DEV_UID:$DEV_GID" {} + || true
  fi

  # `su` without `-` so compose environment (GIT_USER_NAME, ...) reaches
  # bootstrap; su still sets HOME/USER/SHELL to dev's.
  if ! su -s /bin/bash dev -c "bash /usr/local/bin/devenv-bootstrap.sh"; then
    log "WARNING: bootstrap reported errors (see messages above); continuing."
  fi
fi

exec "$@"
