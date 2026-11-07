# dotfiles

Personal dev-environment setup for WSL2 (Ubuntu) using **Nix** for reproducible
tooling, **home-manager** for shell/config management, and a simple
**install.sh** for lightweight config symlinks.

## Why this setup

- **Reproducible tooling** — Nix pins exact versions of git, zsh, neovim, tmux,
  starship, fzf, wezterm, etc. No dependence on apt versions.
- **Dual config management** — home-manager handles shell-heavy configs (zsh,
  starship, wezterm); `install.sh` handles simpler configs (git, tmux, nvim,
  vim, ssh) via plain symlinks.
- **Fast bootstrap** — install Determinate Nix, clone, run `nix develop`, then
  `./install.sh`. For home-manager managed configs, run
  `home-manager switch --flake .`.

## Quick start

```bash
# Bootstrap shell (provides the home-manager CLI on a fresh machine)
nix develop

# Symlink config/* files into $HOME (backs up existing files)
./install.sh

# Apply home-manager configs (zsh, starship, wezterm)
home-manager switch --flake .
```

## File-by-file

| File / dir | Managed by | Purpose |
|---|---|---|
| `flake.nix` | Nix | Pins nixpkgs + home-manager; defines the bootstrap shell and home config |
| `flake.lock` | Nix | Auto-generated lockfile for exact nixpkgs revision |
| `home.nix` | home-manager | Home-manager module — everyday CLI tools (`home.packages`) plus zsh, starship, wezterm configs |
| `home/.config/wezterm/wezterm.lua` | home-manager | Wezterm config (out-of-store symlink via `mkOutOfStoreSymlink`) |
| `install.sh` | — | Symlinks files under `config/` into `$HOME`; backs up existing |
| `config/git/.gitconfig` | install.sh | Git config — colors, aliases |
| `config/git/.gitignore_global` | install.sh | Global gitignore (OS + editor patterns) |
| `config/tmux/.tmux.conf` | install.sh | Tmux config — Ctrl-a prefix, mouse mode, vi navigation |
| `config/nvim/init.lua` | install.sh | Neovim config — lazy.nvim bootstrap, basic options, keymaps |
| `config/vim/.vimrc` | install.sh | Basic vim settings |
| `config/starship/starship.toml` | install.sh | Starship prompt — minimal preset |
| `config/ssh/config` | install.sh | SSH config template (commented out) |
| `config/claude/CLAUDE.md` | install.sh | Global Claude Code instructions linked to `~/.claude/CLAUDE.md` (re-entry, design interview, TDD, plan-compact-build) |
| `config/claude/skills/explain-back/SKILL.md` | install.sh | Custom skill: quizzes me on a change before merge → `~/.claude/skills/explain-back/` |
| `scripts/setup-claude-tools.sh` | — | Run `bash scripts/setup-claude-tools.sh` once: installs mattpocock-skills + pr-review-toolkit plugins and the no-mistakes push gate |
| `.gitignore` | — | Ignores editor swap files, OS cruft, Nix build artifacts |

## Fresh WSL install

```bash
# 1. Install Determinate Nix
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# 2. Clone dotfiles
cd ~
git clone https://github.com/AdamDunn1437/dotfiles.git
cd dotfiles

# 3. Enter the bootstrap shell (for the home-manager CLI) & symlink configs
nix develop
./install.sh

# 4. Apply home-manager configs
home-manager switch --flake .

# 5. Switch default shell to zsh (optional)
chsh -s "$(which zsh)"
```
