#!/bin/bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
MODE="${1:---docker}"  # Default to --docker if not specified

# Validate argument
case "$MODE" in
  --docker|--host)
    ;;
  *)
    echo "❌ Invalid argument: $MODE"
    echo "Usage: $0 [--docker|--host]"
    exit 1
    ;;
esac

echo "========================================"
echo "  Dotfiles Installer"
echo "  Mode: $MODE"
echo "========================================"

# Setup symlinks
if bash "$DOTFILES_DIR/scripts/setup-symlinks.sh"; then
  echo "✅ Symlinks setup successful"
else
  echo "❌ Symlinks setup failed"
  exit 1
fi

echo "========================================"
echo "  Installation complete!"
echo "  Symlinks created in $HOME"
echo "========================================"
