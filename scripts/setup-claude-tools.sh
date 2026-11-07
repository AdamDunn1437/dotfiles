#!/usr/bin/env bash
set -euo pipefail

# ── Claude Code tooling ────────────────────────────────────────
# Installs the review / planning tools the global CLAUDE.md expects:
#   • mattpocock-skills  — /grill-me, tdd, code-review, teach, wait-what, ...
#   • pr-review-toolkit  — Anthropic's multi-agent PR review (/pr-review-toolkit:review-pr)
#   • no-mistakes        — local git push gate (review → test → docs → lint → PR → CI)
# Run with: bash scripts/setup-claude-tools.sh   (safe to re-run; installed tools are skipped)
# ───────────────────────────────────────────────────────────────

PLUGINS=(
  "mattpocock-skills@claude-plugins-official"
  "pr-review-toolkit@claude-plugins-official"
)

NO_MISTAKES_INSTALLER="https://raw.githubusercontent.com/kunchenguid/no-mistakes/main/docs/install.sh"

echo "◆ Claude Code tooling"

if ! command -v claude >/dev/null 2>&1; then
  echo "  ✗ claude CLI not found on PATH. Install Claude Code first, then re-run." >&2
  exit 1
fi

installed_plugins="$(claude plugin list 2>/dev/null || true)"
for plugin in "${PLUGINS[@]}"; do
  if grep -qF "${plugin%@*}" <<<"$installed_plugins"; then
    echo "  ✓ $plugin (already installed)"
  else
    echo "  → installing $plugin"
    claude plugin install "$plugin" --scope user
  fi
done

if command -v no-mistakes >/dev/null 2>&1; then
  echo "  ✓ no-mistakes (already installed: $(no-mistakes --version 2>/dev/null || echo 'unknown version'))"
else
  echo "  → no-mistakes is not installed."
  echo "    Installer: $NO_MISTAKES_INSTALLER"
  read -r -p "    Download and run it now? [y/N] " reply
  if [[ "$reply" =~ ^[Yy]$ ]]; then
    curl -fsSL "$NO_MISTAKES_INSTALLER" | sh
  else
    echo "    Skipped. Install later with: curl -fsSL $NO_MISTAKES_INSTALLER | sh"
  fi
fi

cat <<'EOF'

◆ Done. Per-repo steps (run inside each project you want gated):
    no-mistakes init              # adds the `no-mistakes` remote + /no-mistakes skill
    /setup-matt-pocock-skills     # in Claude Code, once per repo
  Then restart Claude Code (or run /reload-plugins).
EOF
