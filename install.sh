#!/usr/bin/env bash
set -euo pipefail

# ── dotfiles installer ─────────────────────────────────────────
# Symlinks every file under config/ into $HOME using a per-tool
# target mapping.  Backs up existing non-symlink files as *.bak.
# ───────────────────────────────────────────────────────────────

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$DOTFILES_DIR/config"

# Map each tool subdirectory → target directory under $HOME
declare -A TARGETS
TARGETS[zsh]="$HOME"
TARGETS[git]="$HOME"
TARGETS[tmux]="$HOME"
TARGETS[nvim]="$HOME/.config/nvim"
TARGETS[starship]="$HOME/.config"
TARGETS[vim]="$HOME"
TARGETS[ssh]="$HOME/.ssh"
TARGETS[claude]="$HOME/.claude"

link_file() {
  local src="$1"
  local dest="$2"

  # If a real file (not symlink) exists at destination, back it up
  if [ -f "$dest" ] && [ ! -L "$dest" ]; then
    local bak="${dest}.bak"
    echo "  → backing up $dest → $bak"
    mv "$dest" "$bak"
  elif [ -L "$dest" ]; then
    # Remove existing symlink so we can re-create it
    rm -f "$dest"
  fi

  # Create parent directory if needed
  mkdir -p "$(dirname "$dest")"

  # Create relative symlink for readability (e.g. ../config/zsh/.zshrc)
  local rel
  rel="$(realpath --relative-to="$(dirname "$dest")" "$src")"
  ln -s "$rel" "$dest"
  echo "  ✓ $src → $dest"
}

echo "◆ Installing dotfiles from $CONFIG_DIR"
echo ""

for tool in "${!TARGETS[@]}"; do
  src_dir="$CONFIG_DIR/$tool"
  target_base="${TARGETS[$tool]}"

  if [ ! -d "$src_dir" ]; then
    continue
  fi

  find "$src_dir" -type f | while read -r file; do
    # Relative path inside the tool dir (e.g. .zshrc, init.lua)
    rel_path="${file#$src_dir/}"
    dest="$target_base/$rel_path"
    link_file "$file" "$dest"
  done
done

# Ensure ~/.ssh has restricted permissions
if [ -d "$HOME/.ssh" ]; then
  chmod 700 "$HOME/.ssh"
  chmod 600 "$HOME/.ssh/config" 2>/dev/null || true
fi

echo ""
echo "◆ Done — all config files linked."
