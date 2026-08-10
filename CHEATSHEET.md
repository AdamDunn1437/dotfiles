# Development Setup Cheat Sheet

Personal dev-environment for WSL2 (Ubuntu) using **Nix** (reproducible tooling),
**home-manager** (shell-heavy configs), and a plain **install.sh** (symlink-based
configs). Everything lives in `~/github/AdamDunn1437/dotfiles` and is versioned in git.

This sheet covers how to get into the environment, use each tool to its full
capability, and change how everything is configured.

---

## 1. Getting into the environment

### From Windows PowerShell

Fastest way to a Linux shell (drops you into the WSL home directory):

```powershell
wsl
```

Or open a specific WSL distribution / start directly in the dotfiles repo:

```powershell
wsl -d Ubuntu
wsl --cd "~/github/AdamDunn1437/dotfiles"
wsl ~
```

To browse the WSL filesystem without opening a shell (slow for heavy file
operations — prefer `wsl` for real work):

```powershell
cd \\wsl.localhost\Ubuntu\home\adunner\github\AdamDunn1437\dotfiles
```

You can also reach WSL from the terminal: `wsl.exe -d Ubuntu -- cd ~` runs a
command then exits.

**What this stack is for.** The whole point is *reproducibility*. Nix pins an
exact set of tool versions in `flake.lock`, so every machine you set up gets the
same tools — no "works here but not there" version drift. `nix develop` puts
those pinned tools in front of your PATH for the current session; `./install.sh`
and home-manager then place your *configuration* on top. You edit one file in
this repo and every tool picks it up from there, instead of manually configuring
each app.

**Companion tools you get for free** (installed but not covered by their own
section):

| Tool | What it does | When you'll reach for it |
|---|---|---|
| `fzf` | Fuzzy finder | `Ctrl+t` (file), `Ctrl+r` (history), `Alt+c` (cd) in zsh; `<C-p>`/`<C-g>` in nvim |
| `rg` (ripgrep) | Search file contents at speed | `rg "foo" src/` instead of slow `grep -r` |
| `fd` | Find files by name, fast | `fd "*.md"` instead of `find` |
| `htop` | Interactive process monitor | Diagnose what's eating CPU/RAM |
| `jq` | Parse/filter JSON in the shell | `curl ... | jq '.name'` |

### From inside the WSL shell

```bash
cd ~/github/AdamDunn1437/dotfiles  # the dotfiles repo
```

### Activate the dev environment

The pinned tools (git, zsh, vim, tmux, starship, fzf, ripgrep, fd, wezterm) are
only on your PATH while the Nix dev shell is active:

```bash
cd ~/github/AdamDunn1437/dotfiles
nix develop
```

This prints the versions of everything available. While inside the shell you see
the starship `❄ nix-shell` indicator. To leave: `exit`.

> **Note:** `nix develop` only affects the current shell session. New terminals
> need to run it again. The system-installed packages you use daily (zsh,
> starship, fzf bindings via your `~/.zshrc`) come from home-manager, not Nix.

### Why the paths work

- `$HOME/.local/bin` is prepended to your PATH (see `home.nix`), so anything you
  install there is callable.
- `EDITOR` / `VISUAL` are set to `vim` — tools like `git commit` will open vim.
- Inside `nix develop`, Homebrew/Linuxbrew is added to PATH **after** Nix paths so
  Nix-managed tools win. Outside the shell, `~/.zshrc` also sources brew.

---

## 2. WezTerm

WezTerm is a GPU-accelerated terminal emulator. Its config lives at
`~/github/AdamDunn1437/dotfiles/home/.config/wezterm/wezterm.lua` and is linked
into place by home-manager as an out-of-store symlink.

**What it is / why you'd use it.** WezTerm is the app you actually look at all
day — it's what renders your shell, nvim, tmux status lines, and Nerd Font
icons. Because it renders on the GPU it stays smooth even with 80% background
transparency, lots of scrolling, and big fonts. Its config being plain Lua is
the key payoff: your whole terminal is version-controlled in this repo, with no
GUI settings panel to click through and no state to lose when you reinstall.
It's also cross-platform, so the same `wezterm.lua` works identically if you
ever leave WSL. It supports tabs/windows out of the box and renders true-colour
schemes like rose-pine-moon exactly as designed.

### Current settings

| Setting | Value | Where |
|---|---|---|
| Color scheme | `rose-pine-moon` | `wezterm.lua` |
| Font | Hack Nerd Font, 15pt | `wezterm.lua` |
| Background opacity | 80% | `wezterm.lua` |
| Tab bar | hidden when only one tab | `wezterm.lua` |
| Window decorations | resize only | `wezterm.lua` |

### Launching

WezTerm is Windows software that opens a WSL shell. Launch it from Windows
PowerShell or the Start menu, then run `wsl` to get into Linux, or configure its
default program if you want it to auto-open WSL. From inside the dev shell you
can also start it (it runs the Windows GUI):

```bash
wezterm start -- wsl
```

### Changing it

1. Edit `home/.config/wezterm/wezterm.lua`.
2. Apply with home-manager:
   ```bash
   home-manager switch --flake .
   ```
   (Because it's an out-of-store symlink, the running config also just needs the
   file saved + WezTerm relaunched.)

Try the LSP for completions/validation:

```bash
wezterm.exe lua docs /path/to/wezterm.lua   # validate config
```

Useful example: add a keybinding to open a new tab across the config's `keys`
table (this setup hasn't customized the default key table — defaults are in the
[WezTerm docs](https://wezterm.org/config/keys.html)).

---

## 3. tmux

**Prefix is `Ctrl-a`** (not the default `Ctrl-b`) so it's thumb-friendly on QWERTY.
Config: `~/github/AdamDunn1437/dotfiles/config/tmux/.tmux.conf`, symlinked via
`install.sh` to `~/.tmux.conf`.

**What it is / why you'd use it.** tmux is a terminal *multiplexer* — one
terminal window that hosts many panes and windows, where your sessions keep
running even after you detach. This matters for long-lived work (a dev server,
a `nix develop` build, a remote install over SSH): detach with `Ctrl-a d`,
walk away for hours, come back and `tmux attach` exactly where you left off.
Splitting a window into panes (`Ctrl-a |` / `Ctrl-a -`) is the standard way to
run an editor beside a shell without a second monitor, and because tmux works
the same over SSH it's your go-to for remote machines too. Pairs perfectly with
neovim: one pane for the editor, one for `git`/`nix` commands, one for logs.

### Starting

```bash
tmux                  # new session
tmux new -s work      # new session named "work"
tmux ls               # list sessions
tmux attach -t work   # reattach to a session
tmux kill-server      # nuke all tmux
```

### Key table (prefix = Ctrl-a)

| Shortcut | Action |
|---|---|
| `Ctrl-a` `|` | Split pane **vertically** (left/right) |
| `Ctrl-a` `-` | Split pane **horizontally** (top/bottom) |
| `Alt+←/→/↑/↓` | Move between panes |
| `Alt+h/j/k/l` | Resize pane by 5 (hold to repeat) |
| `Ctrl-a` `c` | New window |
| `Ctrl-a` `n` / `p` | Next / previous window |
| `Ctrl-a` `0–9` | Jump to window number (windows start at **1**, not 0) |
| `Ctrl-a` `,` | Rename window |
| `Ctrl-a` `d` | Detach (keep session running in background) |
| `Ctrl-a` `r` | Reload `~/.tmux.conf` |
| `Ctrl-a` `[` | Enter copy mode (vi keys: `j/k/h/l`, `/` search, `v` select, `y` yank) |
| `Ctrl-a` `]` | Paste buffer |
| `Ctrl-a` `:` | Command prompt (e.g. `set -g mouse off`) |
| `Ctrl-a` `z` | Zoom / unzoom current pane |
| `Ctrl-a` `x` | Kill current pane |

Mouse is on: click panes/windows, scroll to enter copy-mode scrollback
(scrollback is 50,000 lines).

### Changing it

Edit `config/tmux/.tmux.conf`, then either:

```bash
tmux source-file ~/.tmux.conf    # reload for the current session
./install.sh                     # re-link if you changed the symlink target
```

---

## 4. Neovim

Config: `~/github/AdamDunn1437/dotfiles/config/nvim/init.lua`, symlinked via
`install.sh` to `~/.config/nvim/init.lua`. Plugins are pulled by **lazy.nvim** on
first launch. Colorscheme is **catppuccin-mocha**.

**What it is / why you'd use it.** Neovim is the editor built on vim's modal
model: *normal mode* applies to text (keys are commands), *insert mode* applies
to typing text. That split is what makes "no mouse, hands stay on home row"
workable. Its config is a single Lua file, so your entire editor — keymaps,
plugins, look — is reproducible and versioned in this repo. The plugins here
turn a bare editor into a real IDE: fuzzy file finding (`<C-p>`), project-wide
grep (`<C-g>`), Git workflows (`:Git`, `:Gbrowse`), syntax trees (treesitter),
and a statusline (lualine). Because it's terminal-native, it runs happily inside
a tmux pane or over SSH with zero special setup.

### Launching

```bash
nvim <file>      # edit a file
nvim .           # open netrw file browser at the current dir
```

### Key table (leader = space)

| Shortcut | Action |
|---|---|
| `Space w` | Write/save file |
| `Space q` | Quit |
| `Space e` | Show diagnostics (error/warning float) |
| `Space u` | Toggle undo tree |
| `<C-p>` | Find files (fzf-lua) |
| `<C-g>` | Live grep across project (fzf-lua) |
| `Esc` | Clear search highlight |
| `u` / `<C-r>` | Undo / redo |
| `:earlier 30m` / `:later 30m` | Jump back/forward in the file's undo history (persistent undo) |
| `/` | Search (case-insensitive, smartcase) |
| `n` / `N` | Next / previous search match |
| `g d` | Go to definition (via LSP if attached) |
| `:w`, `:q`, `:wq`, `:q!` | Classic vim write/quit |

### Built-in niceties

- Relative line numbers on (`number` + `relativenumber`).
- **Persistent undo** — undo history survives restarts (`undofile`).
- No swap files. Indent auto-detected by `vim-sleuth` (2-space default).
- `vim-fugitive` gives `:Git` inside nvim; `vim-rhubarb` gives `:Gbrowse` to open
  the current file/line on GitHub.
- lualine statusline, treesitter highlighting, and file icons are enabled.

### Changing it

1. Edit `config/nvim/init.lua`.
2. Re-run `./install.sh` (it re-creates the symlink if needed; it points at the
   same file, so just restarting nvim is usually enough).

Add plugins inside the `require("lazy").setup({...})` table, then restart nvim;
lazy.nvim installs them automatically. Run `:Lazy` for the plugin manager UI.

---

## 5. zsh

zsh is managed by **home-manager** (`programs.zsh` in `home.nix`). The effective
config is generated from `home.nix` at `home-manager switch`.

**What it is / why you'd use it.** zsh is your interactive shell — the program
that reads every command you type, runs it, and gives your prompt back. Compared
to the default bash it has saner tab completion, globbing, and history out of
the box, and this setup layers on the three things that most improve daily
comfort: **ghost-text autosuggestions** (hit `Ctrl+f` to accept instead of
re-typing commands), **syntax highlighting** (typos and unknown commands turn
red as you type), and **shared history** (a command typed in one terminal is
findable with `Ctrl+r` in every other one, because they all write to the same
history file). Home-manager *generates* `~/.zshrc` from `home.nix`, which means
your shell configuration is also reproducible — you never edit the generated
file directly, you edit `home.nix` and re-apply.

### Features

- **Ghost-text autosuggestions** (blue): type and hit **`Ctrl+f`** to accept the
  suggestion (nicer than the default right-arrow).
- **Syntax highlighting** as you type.
- **fzf** keybindings:
  - `Ctrl+t` — insert a file path
  - `Ctrl+r` — fuzzy-search history
  - `Alt+c` — fuzzy-cd into a directory
- `AUTO_CD` is on: type a directory name and press Enter, no `cd` needed.
- **Shared history** — every terminal shares one history file (10,000 lines,
  duplicates ignored).

### Aliases

| Alias | Expands to |
|---|---|
| `..` | `cd ..` |
| `add` | `git add` |
| `commit` | `git commit` |
| `push` | `git push` |
| `diff` | `git diff` |

### Changing it

Edit `home.nix` (`initContent`, `shellAliases`, `history`, etc.), then:

```bash
home-manager switch --flake .
```

New aliases / settings land in the next shell you open (or `exec zsh`).

---

## 6. Git

**What it is / why you'd use it.** Git is version control — the network of
safety under every file in this repo. It records every committed change, shows
what you've modified (`git diff`), lets you shelve half-finished experiments
(`git stash`), and reverts to any earlier state (`git restore`, `git revert`).
That last ability is the whole reason you can confidently edit configs and go
back: section 9 walks through exactly that loop. This dotfiles folder is itself
a Git repository, so *every* config change is captured in `git lg` and can be
rolled back. Its integration with neovim (fugitive/`:Git`) means you can commit
and interact with Git without leaving the editor.

### Global ignores

`config/git/.gitignore_global` → `~/.gitignore_global` keeps swap files, OS
junk, and editor folders out of every repo automatically (wired in via
`core.excludesFile`).

### Aliases

| Alias | Command | Example |
|---|---|---|
| `lg` | `log --oneline --graph --decorate --all` | `git lg` |
| `st` | `status -sb` | `git st` |
| `co` | `checkout` | `git co main` |
| `cb` | `checkout -b` | `git cb feature/x` |
| `ci` | `commit` | `git ci -m "msg"` |
| `ca` | `commit --amend` | `git ca` |
| `df` | `diff` | `git df` |
| `dc` | `diff --cached` | `git dc` |
| `last` | `log -1 HEAD` | `git last` |
| `br` | pretty branch list | `git br` |
| `unstage` | `reset HEAD --` | `git unstage <file>` |
| `cleanup` | prune + gc | `git cleanup` |

Defaults: default branch is `main` on `git init`, editor is `vim`, color on.

> **WSL quirk:** the repo root has a `safe.directory` entry for the
> `\\wsl.localhost\...` UNC path. If git ever complains "dubious ownership",
> `git config --global --add safe.directory <path>` fixes it.

### Changing it

Edit `config/git/.gitconfig`, then `./install.sh`. Per-repo identity (not stored
in dotfiles, by design):

```bash
git config user.name "Adam Dunn"
git config user.email "you@example.com"
```

---

## 7. Starship prompt

Prompt is defined in two places:

- **home-manager** (`programs.starship` in `home.nix`) — the active one.
- **`config/starship/starship.toml`** — an alternative minimal config symlinked
  by `install.sh` (not the one zsh uses by default, unless you set
  `STARSHIP_CONFIG=~/.config/starship.toml`).

**What it is / why you'd use it.** Starship is your prompt — the line text
before your cursor. A good prompt eliminates the reflex of running `pwd`, `git
status`, or `which python` every few minutes, because it answers those questions
constantly for free: which directory, which git branch and whether it's clean
(⇡/⇣ arrows), how long the last command took, and — crucially — whether the
`❄` nix-shell is active. It's rendered in a fraction of a millisecond (no
noticeable lag as you type) and it's cross-shell, so the exact same prompt
follows you into bash or fish. The failure marker (`➜` turns red + nonzero exit
code) instantly tells you whether your last command actually succeeded.

### Reading the prompt (left to right)

| Segment | Shows |
|---|---|
| os + username | current user |
| `directory` | current dir, truncated to 3 path components |
| `git_branch` / `git_status` | branch name (purple) + status (⇡ ahead, ⇣ behind, ⛳ conflicts) |
| ❄ `nix-shell` | active, when inside `nix develop` |
| node/rust/python | active toolchains, when detected |
| `⏱ <duration>` | time of last command |
| `➜` green/red | success / failure prompt character |

### Changing it

The live prompt comes from `home.nix`:

```bash
home-manager switch --flake .
```

To try the file-based version instead, add the override:

```bash
export STARSHIP_CONFIG=$HOME/.config/starship.toml
starship preset list   # explore official presets
starship print-config # what's currently active
```

---

## 8. Install, re-install, and how Nix fits in

**What Nix is / why you'd use it.** Nix is a package manager with a strong
guarantee: it builds packages from locked source revisions, so the same flake
reproducibly yields the same tools on any machine. The pinned versions live in
`flake.lock` (git, zsh, tmux, starship, neovim via home-manager, fzf, ripgrep,
fd, wezterm). That removes the classic setup pain — "works on my machine" —
because there is no machine-dependent apt install step; `nix develop` downloads
exactly what the repo says, and the `❄` starship indicator confirms the sandbox
is live. **home-manager** extends the same idea from packages to *files*: it
generates `~/.zshrc`, the starship prompt, and the wezterm link from `home.nix`,
so your dotfiles are the single source of truth for both tools *and* config.

### Fresh WSL machine

```bash
# 1. Install Determinate Nix
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# 2. Clone the dotfiles
cd ~
git clone https://github.com/AdamDunn1437/dotfiles.git
cd dotfiles

# 3. Enter dev shell (downloads pinned tool versions)
nix develop

# 4. Symlink config/ files into $HOME (backs up existing files as *.bak)
./install.sh

# 5. Apply home-manager configs (zsh, starship, wezterm)
home-manager switch --flake .

# 6. Make zsh your login shell (optional)
chsh -s "$(which zsh)"
```

### Day-to-day config update loop

```bash
cd ~/github/AdamDunn1437/dotfiles

git pull                                    # get latest configs
nix develop                                 # enter tooling
./install.sh                                # re-link config/* (git, tmux, nvim, vim, ssh)
home-manager switch --flake .               # apply home.nix (zsh, starship, wezterm)
tmux source-file ~/.tmux.conf               # reload tmux if relevant
```

### How `install.sh` works

- Maps each tool dir under `config/` to a home target:
  `git`, `tmux`, `vim`, `ssh` → `$HOME` (with `ssh` → `~/.ssh`),
  `nvim` → `~/.config/nvim`, `starship` → `~/.config`. (`zsh` is a no-op in
  practice — zsh and starship are owned by home-manager.)
- Creates **relative symlinks**; safe to run repeatedly.
- Backs up any real file at the destination as `*.bak`, and deletes stale
  symlinks before re-linking.
- Hardens `~/.ssh` to `700` and `~/.ssh/config` to `600` afterwards.

---

## 9. Worked example: edit a config → apply → test → go back to original

This is the loop you'll do constantly: tweak a setting, live with it, and revert
cleanly if it doesn't suit you. Because the dotfiles repo is a git repo and the
configs are symlinked or generated from it, "go back to original" is always one
command away.

**Scenario: try changing the tmux prefix from `Ctrl-a` back to `Ctrl-b`.** The
steps are identical for any edit (prompt, keymaps in nvim, zsh aliases, a
colorscheme), so follow along with whatever you're experimenting with.

### Step 1 — check the current state before you touch anything

```bash
cd ~/github/AdamDunn1437/dotfiles
git status        # any pending local changes?
git diff          # exactly what differs from the last commit
git lg            # recent commit history, if you need an earlier "original"
```

### Step 2 — make the edit

```bash
vim config/tmux/.tmux.conf
# change:  set -g prefix C-a     →     set -g prefix C-b
```

### Step 3 — apply + test the change

```bash
./install.sh                 # re-link symlinks (idempotent, safe to re-run)
tmux source-file ~/.tmux.conf   # apply without restarting tmux
# now try: the prefix should be Ctrl-b; splits still work, pane nav unchanged
```

For home-manager-owned configs (zsh, starship, wezterm) the apply step is instead:

```bash
home-manager switch --flake .          # regenerate ~/.zshrc, prompt, wezterm link
exec zsh                               # pick up shell changes immediately
```

### Step 4 — decide: keep it or revert it

**Option A — keep the change** (and record it like any experiment):

```bash
git add config/tmux/.tmux.conf
git commit -m "try Ctrl-b prefix"      # or use the `commit` zsh alias
```

**Option B — revert to the original** in 3 ways, pick your mood:

```bash
git restore config/tmux/.tmux.conf     # discard the edit entirely (permanent)
git checkout -- config/tmux/.tmux.conf # older syntax, same result
```

If you only want to *shelve* it temporarily (compare against the original, then
maybe bring it back):

```bash
git stash                              # put the edit away, tree back to original
git stash pop                          # bring the edit back
git stash list                         # see what's stashed
```

Verify you're back to original:

```bash
git status        # should be clean (empty)
git diff          # no output = no difference from HEAD
```

**Step 5 — re-apply the config** after reverting (the file and the live config
can get out of sync):

```bash
tmux source-file ~/.tmux.conf   # tmux: reload from the reverted file
./install.sh                    # symlink tools: ensure links point at the reverted file
home-manager switch --flake .   # home-manager tools: regenerate from reverted home.nix
```

### Reverting the other-way-around risks (what to watch for)

| Situation | What to do |
|---|---|
| `install.sh` backed up your real file as `.bak` | You can restore it: `mv ~/.tmux.conf.bak ~/.tmux.conf` (the repo file is the "original" here, so usually not needed) |
| You edited the **generated** `~/.zshrc` directly | Pointless — it's rebuilt from `home.nix`. Cast the change in `home.nix` instead, or `git restore home.nix` |
| You bumped tool versions and broke the build | `git restore flake.lock && git restore flake.nix`, then `nix develop` again |
| You want to undo inside nvim while editing | `u` to undo, `:earlier 30m` to jump across saves (persistent undo), `<leader>u` for the undo tree |
| You committed a bad change | `git revert <hash>` (creates an inverse commit) or `git reset --soft HEAD~1` to un-commit and keep the diff |

> **Rule of thumb:** the repo — not the live symlink — is the source of truth.
> Revert the file in the repo with git, then re-apply (Step 5). That keeps the
> live config, the file, and git history in agreement.

---

## Where each config lives

| What | File | Applied by |
|---|---|---|
| Dev shell tooling | `flake.nix` | `nix develop` |
| zsh | `home.nix` | `home-manager switch --flake .` |
| Starship prompt | `home.nix` | home-manager |
| WezTerm | `home/.config/wezterm/wezterm.lua` | home-manager |
| tmux | `config/tmux/.tmux.conf` | `./install.sh` |
| Neovim | `config/nvim/init.lua` | `./install.sh` |
| Git | `config/git/.gitconfig`, `.gitignore_global` | `./install.sh` |
| vim | `config/vim/.vimrc` | `./install.sh` |
| SSH | `config/ssh/config` | `./install.sh` |