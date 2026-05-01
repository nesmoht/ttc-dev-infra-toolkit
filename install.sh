#!/usr/bin/env bash
set -euo pipefail

TOOLKIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "ttc-dev-infra-toolkit installer"
echo "Toolkit: $TOOLKIT_DIR"
echo "Target:  $CLAUDE_DIR"
echo ""

mkdir -p "$CLAUDE_DIR"

link() {
  local src="$TOOLKIT_DIR/$1"
  local dst="$CLAUDE_DIR/$2"

  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    echo "  SKIP  $dst (exists and is not a symlink — remove it manually to replace)"
    return
  fi

  ln -sf "$src" "$dst"
  echo "  LINK  $dst -> $src"
}

link "CLAUDE.md" "CLAUDE.md"
link "agents"    "agents"
link "commands"  "commands"

echo ""
echo "Done. Restart Claude Code to pick up the changes."
echo ""
echo "Verify with:"
echo "  ls -la $CLAUDE_DIR/agents $CLAUDE_DIR/commands"
