# Development Setup Cheat Sheet

Personal dev environment for WSL2 (Ubuntu) using **Nix** (pinned tools), **home-manager**
(zsh, starship, wezterm) and a plain **install.sh** (symlinked configs). Everything lives in
`~/github/AdamDunn1437/dotfiles` and is versioned in git.

Every key binding below was checked against the config files in this repo. Where a default
from the tool itself is listed, it's marked *(default)*.

**Contents**

1. [The daily workflow: tmux + Claude Code](#1-the-daily-workflow-tmux--claude-code)
2. [Getting into the environment](#2-getting-into-the-environment)
3. [tmux](#3-tmux)
4. [Claude Code](#4-claude-code)
5. [no-mistakes (push gate)](#5-no-mistakes-push-gate)
6. [WezTerm](#6-wezterm)
7. [zsh](#7-zsh)
8. [fzf, ripgrep, fd, jq, htop](#8-fzf-ripgrep-fd-jq-htop)
9. [Git](#9-git)
10. [Neovim](#10-neovim)
11. [vim](#11-vim)
12. [Starship prompt](#12-starship-prompt)
13. [Nix, home-manager and install.sh](#13-nix-home-manager-and-installsh)
14. [Worked example: edit → apply → test → revert](#14-worked-example-edit--apply--test--revert)
15. [Known gaps in the current configs](#15-known-gaps-in-the-current-configs)
16. [Where each config lives](#16-where-each-config-lives)

---

## 1. The daily workflow: tmux + Claude Code

The setup in one picture: **WezTerm** is the window, **tmux** runs inside it and holds several
windows, and each tmux window runs one job.

```
WezTerm
└── tmux session "capstone"           ← one session per project
    ├── window 1: claude              ← Claude Code (the agent)
    ├── window 2: shell               ← your own commands, tests, servers
    └── window 3: git                 ← git st / git lg / reviewing diffs
```

Switch windows with `Ctrl-a 1`, `Ctrl-a 2`, `Ctrl-a 3`. Detach with `Ctrl-a d` and everything
keeps running; `tmux attach` brings it all back exactly as you left it.

### Build it by hand (do this once to learn the keys)

```bash
cd ~/github/your-project
tmux new -s capstone          # new session called "capstone"; you're now in window 1
claude                        # start Claude Code in window 1
```

Then, using the keys from section 3:

| Step | Keys | What happens |
|---|---|---|
| Name this window | `Ctrl-a ,` → type `claude` → Enter | Status bar shows `1:claude` |
| New window | `Ctrl-a c` | Window 2 opens (in your **home** folder; `cd` back to the project) |
| Name it | `Ctrl-a ,` → `shell` → Enter | |
| Another window | `Ctrl-a c`, then `Ctrl-a ,` → `git` | Window 3 |
| Jump around | `Ctrl-a 1` / `Ctrl-a 2` / `Ctrl-a 3` | |
| Leave it running | `Ctrl-a d` | Back to plain zsh; tmux keeps going |
| Come back | `tmux attach -t capstone` | Everything as you left it |

### Or create it in one command

Paste this function into your shell to try it. To keep it, add it to `initContent` in
`home.nix` and run `home-manager switch --flake .`.

```bash
# dev [dir]: open (or reattach to) a tmux session for a project
# with windows: 1 claude, 2 shell, 3 git
dev() {
  local dir name
  dir="$(cd "${1:-$PWD}" && pwd)" || return 1
  name="$(basename "$dir" | tr '.:' '__')"     # tmux session names can't contain . or :
  if ! tmux has-session -t "=$name" 2>/dev/null; then
    tmux new-session -d -s "$name" -n claude -c "$dir"
    tmux send-keys -t "=$name:claude" 'claude' C-m
    tmux new-window -t "=$name" -n shell -c "$dir"
    tmux new-window -t "=$name" -n git -c "$dir"
    tmux send-keys -t "=$name:git" 'git lg | head -20; git st' C-m
    tmux select-window -t "=$name:claude"
  fi
  if [ -n "$TMUX" ]; then tmux switch-client -t "=$name"; else tmux attach -t "=$name"; fi
}
```

Usage: `dev ~/github/capstone`, or `cd` into a project and run `dev`. Running it again just
reattaches; it won't create duplicate windows.

### Want them side by side instead?

Inside the `claude` window press `Ctrl-a |` to split it. Claude stays on the left, a shell opens
on the right. Move between the two with `Alt+←` / `Alt+→`, and zoom either one full-screen
with `Ctrl-a z` (press again to unzoom).

### A typical feature, start to finish

1. `dev ~/github/capstone`
2. Window 1 (`claude`): describe the feature, then `/grill-me`. Answer its questions one at a time.
3. Claude writes `SPEC.md`, you `/compact`, it builds with tests first.
4. Window 2 (`shell`): run the app or tests yourself while it works.
5. Window 3 (`git`): `git df` to read what changed.
6. Back in window 1: `/pr-review-toolkit:review-pr`, then `git push no-mistakes`, then `/explain-back`.
7. `Ctrl-a d` when you're done for the day.

---

## 2. Getting into the environment

### From Windows

```powershell
wsl                                   # Linux shell in your WSL home
wsl -d Ubuntu                         # a specific distro
wsl --cd "~/github/AdamDunn1437/dotfiles"
```

Browse WSL files from Explorer (slow for heavy work; use `wsl` for real work):
`\\wsl.localhost\Ubuntu\home\adunner\github\AdamDunn1437\dotfiles`

### Activate the dev shell

The pinned tools in `flake.nix` (git, zsh, vim, tmux, starship, fzf, ripgrep, fd, wezterm) are
on your PATH only while the Nix dev shell is active:

```bash
cd ~/github/AdamDunn1437/dotfiles
nix develop          # prints the version of each tool
exit                 # leave the dev shell
```

`nix develop` only affects the current shell. jq, htop and starship come from home-manager
(`home.packages`), so they're always available.

### Why the paths work

- `$HOME/.local/bin` is on PATH (`home.nix`). Claude Code's native installer puts `claude` there.
- `EDITOR` / `VISUAL` are `vim`, so `git commit` opens vim.
- Inside `nix develop`, Linuxbrew is added **after** the Nix paths, so Nix-managed tools win.

---

## 3. tmux

Config: `config/tmux/.tmux.conf` → `~/.tmux.conf` (via `install.sh`).

### The four ideas

| Thing | What it is | Analogy |
|---|---|---|
| **Server** | Background process that owns everything. Survives you closing WezTerm. | The tmux "app" |
| **Session** | A named workspace, usually one per project (`capstone`, `dotfiles`) | A desktop |
| **Window** | A full-screen tab inside a session; shown in the status bar as `1:claude 2:shell` | A browser tab |
| **Pane** | A split inside a window | Split-screen |

**The prefix.** Almost every tmux command is *prefix, then a key*. Your prefix is **`Ctrl-a`**:
press Ctrl+a, **let go**, then press the key. `Ctrl-a c` means "Ctrl+a, release, then c".

> In zsh, `Ctrl-a` normally jumps to the start of the line. Inside tmux, press **`Ctrl-a` twice**
> to send that to the shell (`bind C-a send-prefix`).

### Sessions (from the shell, outside tmux)

```bash
tmux                         # new unnamed session
tmux new -s capstone         # new session named "capstone"
tmux ls                      # list sessions
tmux attach                  # attach to the most recent session
tmux attach -t capstone      # attach to a specific one
tmux kill-session -t capstone
tmux kill-server             # stop everything (all sessions die)
```

### Key table (prefix = Ctrl-a)

**Sessions**

| Keys | Action |
|---|---|
| `Ctrl-a d` | Detach (session keeps running) *(default)* |
| `Ctrl-a s` | Pick a session from a list *(default)* |
| `Ctrl-a $` | Rename session *(default)* |
| `Ctrl-a (` / `)` | Previous / next session *(default)* |

**Windows**

| Keys | Action |
|---|---|
| `Ctrl-a c` | New window (opens in your home folder) *(default)* |
| `Ctrl-a ,` | Rename window *(default)* |
| `Ctrl-a 1`…`9` | Jump to window N (**numbering starts at 1**, per config) |
| `Ctrl-a n` / `p` | Next / previous window *(default)* |
| `Ctrl-a l` | Last-used window (toggle between two) *(default)* |
| `Ctrl-a w` | Tree of all sessions + windows, with previews *(default)* |
| `Ctrl-a &` | Kill window (asks first) *(default)* |

**Panes**

| Keys | Action |
|---|---|
| `Ctrl-a \|` | Split **left/right**, in the current folder (config) |
| `Ctrl-a -` | Split **top/bottom**, in the current folder (config) |
| `Alt+←/→/↑/↓` | Move between panes, **no prefix needed** (config) |
| `Ctrl-a Alt+h/j/k/l` | Resize by 5 cells; keep tapping `Alt+h/j/k/l` to repeat (config) |
| `Ctrl-a z` | Zoom pane full-screen / unzoom *(default)* |
| `Ctrl-a x` | Kill pane (asks first) *(default)* |
| `Ctrl-a q` | Flash pane numbers; press a number to jump *(default)* |
| `Ctrl-a {` / `}` | Swap pane with previous / next *(default)* |
| `Ctrl-a Space` | Cycle through preset layouts *(default)* |
| `Ctrl-a !` | Break the pane out into its own window *(default)* |

**Everything else**

| Keys | Action |
|---|---|
| `Ctrl-a r` | Reload `~/.tmux.conf` (shows "Reloaded!") (config) |
| `Ctrl-a ?` | List every key binding; `q` to close *(default)* |
| `Ctrl-a :` | Command prompt, e.g. `kill-pane`, `set -g mouse off` *(default)* |
| `Ctrl-a [` | Enter copy/scroll mode (below) *(default)* |
| `Ctrl-a ]` | Paste the last tmux copy *(default)* |

### Scrolling and copying

The mouse is on: **scroll the wheel** to scroll back (50,000 lines kept), click a pane to focus
it, click a window name to switch, drag a border to resize.

Keyboard copy mode uses vi keys (`mode-keys vi`):

| In copy mode | Action |
|---|---|
| `Ctrl-a [` | Enter copy mode |
| `h j k l`, `Ctrl-u` / `Ctrl-d` | Move; half-page up / down |
| `/` or `?` then text | Search down / up; `n` / `N` next / previous |
| `Space` | Start selection |
| `Enter` | Copy selection and exit |
| `v` | Toggle rectangle (block) selection |
| `q` | Exit without copying |

> **Copying to Windows.** Dragging with the mouse copies into **tmux's** buffer (paste with
> `Ctrl-a ]`), and may not reach the Windows clipboard. Hold **Shift** while you drag to use
> WezTerm's own selection instead, then `Ctrl+Shift+C` to copy to Windows.

### Gotchas

- **New windows start in `~`.** Only the splits (`|` / `-`) keep the current folder. Use `dev`
  (section 1) or `cd` after `Ctrl-a c`.
- **Don't start tmux inside tmux.** If `echo $TMUX` prints something, you're already inside one.
- **Config changes** only apply after `Ctrl-a r` (or `tmux source-file ~/.tmux.conf`).
- The comment in `.tmux.conf` says resize is "Shift + arrow", but the binding is **`Alt+h/j/k/l`**.

### Changing it

Edit `config/tmux/.tmux.conf`, then `Ctrl-a r`. Re-run `./install.sh` only if the symlink is
missing.

---

## 4. Claude Code

Claude Code is Claude running **in your terminal, inside a project folder**. Unlike a chat, it can
read your files, edit them, run commands (tests, git, builds) and check its own work. By default
it asks before editing files or running commands.

### Install and log in (once)

```bash
curl -fsSL https://claude.ai/install.sh | bash    # run inside WSL, not PowerShell
claude --version                                  # open a new terminal first
cd ~/github/AdamDunn1437/dotfiles
./install.sh                                      # links ~/.claude/CLAUDE.md + explain-back skill
bash scripts/setup-claude-tools.sh                # grill-me pack, pr-review-toolkit, no-mistakes
```

The first `claude` run asks you to log in with your Claude account.

### Starting it

```bash
cd ~/github/capstone
claude                        # new conversation in this project
claude -c                     # continue the most recent conversation here
claude -r                     # pick an older conversation to resume
claude -p "explain src/sim"   # one-shot answer, no interactive session
```

### Keys inside a session

| Keys / input | Action |
|---|---|
| `Enter` | Send message |
| `\` then `Enter` | New line without sending (or run `/terminal-setup` to enable Shift+Enter) |
| `Shift+Tab` | Cycle permission mode: normal → auto-accept edits → **plan mode** (reads and plans, no edits) |
| `Esc` | Stop Claude mid-task (your conversation is kept) |
| `Esc` `Esc` | Jump back to an earlier message to edit or rewind |
| `@path/to/file` | Attach a file or folder to your message (Tab-completes) |
| `!command` | Run a shell command yourself; the output goes into the conversation |
| `Ctrl+C` twice | Quit Claude Code |

### Slash commands you'll use

| Command | What it does |
|---|---|
| `/help` | Everything available, including plugin commands. Trust this over any cheat sheet. |
| `/clear` | Start a fresh conversation (saves tokens when switching tasks) |
| `/compact` | Summarize the conversation so far to free context; add a note on what to keep |
| `/init` | Create a project `CLAUDE.md` describing this repo |
| `/config` | Settings, including **Output style → Learning** (Claude leaves small pieces for you to write) |
| `/model` | Switch model |
| `/plugin` | Install, enable or disable plugins |
| `/reload-plugins` | Pick up newly installed plugins without restarting |

### The workflow your CLAUDE.md asks for

Your global `~/.claude/CLAUDE.md` (from `config/claude/CLAUDE.md`) applies to every project.
It tells Claude to follow this pipeline:

| Step | Command | From |
|---|---|---|
| 1. Design interview, one question at a time | `/grill-me` (or `grill-with-docs` in repos with domain docs) | mattpocock-skills |
| 2. Plan → `SPEC.md` → `/compact` | (Claude prompts you) | CLAUDE.md |
| 3. Build test-first, one slice at a time | `tdd` skill (Claude picks it up automatically) | mattpocock-skills |
| 4. Multi-agent self-review | `/pr-review-toolkit:review-pr` (optionally `tests errors` to narrow) | pr-review-toolkit |
| 5. Push through the gate | `git push no-mistakes` or `/no-mistakes` | no-mistakes |
| 6. Check you understand it | `/explain-back` | your skill in `config/claude/skills/` |

Other skills from the pack worth knowing: `teach` (multi-session lessons on a concept),
`wait-what` (re-explain the last message in plain language), `handoff` (summarize so another
session can continue), `diagnosing-bugs`. Run `/setup-matt-pocock-skills` once per repo before
using the engineering skills.

### Tips

- **One task per conversation.** `/clear` between unrelated tasks; long contexts drift.
- **Plan mode first** (`Shift+Tab`) for anything you don't fully understand yet.
- **Read the diff yourself** in your `git` window (`git df`) before you approve a commit.
- If it ignores a CLAUDE.md rule, say so plainly ("CLAUDE.md says to use the gate"). That
  happens in long sessions.

---

## 5. no-mistakes (push gate)

A local git proxy: instead of `git push origin`, you `git push no-mistakes`. It copies your branch
into a throwaway worktree, rebases on the latest remote, then runs AI **review → tests → docs →
lint**. If everything passes and you approve, it pushes, opens the PR and watches CI.

### Set up (once per repo)

```bash
cd ~/github/capstone
no-mistakes init             # adds the `no-mistakes` remote and the /no-mistakes Claude skill
```

### Use

```bash
git push no-mistakes         # send the current branch through the gate
no-mistakes                  # open the TUI to watch progress and approve, fix or skip findings
```

Or from Claude Code: `/no-mistakes` gates already-committed work, and `/no-mistakes <task>`
does the task and then gates it.

**Token tip:** your CLAUDE.md asks Claude to run the gate from a fresh, cheap **Sonnet** subagent
rather than the long builder conversation, so every gate turn doesn't resend 200k tokens.

**It is not a replacement for you.** It catches sloppiness; you still judge intent and design.
That's what `/explain-back` is for.

---

## 6. WezTerm

Config: `home/.config/wezterm/wezterm.lua`, linked by home-manager (out-of-store symlink, so
saving the file + relaunching WezTerm is enough).

| Setting | Value |
|---|---|
| Color scheme | `rose-pine-moon` |
| Font | Hack Nerd Font, 15pt |
| Background opacity | 80% |
| Tab bar | hidden when only one tab |
| Window decorations | resize only |

### Keys *(all WezTerm defaults; this config doesn't change them)*

| Keys | Action |
|---|---|
| `Ctrl+Shift+C` / `Ctrl+Shift+V` | Copy / paste (Windows clipboard) |
| `Ctrl+Shift+T` / `Ctrl+Shift+W` | New tab / close tab |
| `Ctrl+Tab` / `Ctrl+Shift+Tab` | Next / previous tab |
| `Ctrl+Shift+F` | Search scrollback |
| `Ctrl+=` / `Ctrl+-` / `Ctrl+0` | Font bigger / smaller / reset |
| `Ctrl+Shift+P` | Command palette (search every action) |
| `Alt+Enter` | Toggle full-screen |

**Use tmux windows, not WezTerm tabs**, for project work. tmux survives closing WezTerm;
WezTerm tabs don't.

---

## 7. zsh

Generated by home-manager from `programs.zsh` in `home.nix`. **Never edit `~/.zshrc`
directly**; it gets overwritten. Edit `home.nix`, then `home-manager switch --flake .` and
`exec zsh`.

### Features

| Feature | How to use it |
|---|---|
| Autosuggestions | Grey/blue ghost text from history as you type → **`Ctrl+F`** accepts it |
| Syntax highlighting | Unknown commands turn red before you press Enter |
| Shared history | Every terminal and tmux pane shares one history (10,000 entries, duplicates dropped) |
| `AUTO_CD` | Type a folder name + Enter to `cd` into it |
| fzf keys | `Ctrl+R` history, `Ctrl+T` file path, `Alt+C` cd (section 8) |

### Line-editing keys *(zsh defaults, emacs mode)*

| Keys | Action |
|---|---|
| `Ctrl+A` / `Ctrl+E` | Start / end of line (**inside tmux: press `Ctrl-a` twice**) |
| `Alt+B` / `Alt+F` | Back / forward one word |
| `Ctrl+W` | Delete previous word |
| `Ctrl+U` / `Ctrl+K` | Delete to start / end of line |
| `Ctrl+L` | Clear screen |
| `Tab` | Complete; press again for a menu |
| `!!` | Previous command (`sudo !!`) |

### Aliases (from `home.nix`)

| Alias | Expands to |
|---|---|
| `..` | `cd ..` |
| `add` | `git add` |
| `commit` | `git commit` |
| `push` | `git push` |
| `diff` | `git diff` (shadows the system `diff`; use `command diff a b` for that) |

---

## 8. fzf, ripgrep, fd, jq, htop

### fzf: fuzzy finder

Type a few letters in any order and it narrows the list. `Enter` picks, `Esc` cancels,
`Tab` multi-selects.

| In zsh | Action |
|---|---|
| `Ctrl+R` | Search command history (much better than plain history) |
| `Ctrl+T` | Insert a file path at the cursor: `nvim ` then `Ctrl+T` |
| `Alt+C` | Fuzzy `cd` into a subfolder |
| `**` + `Tab` | Fuzzy-complete paths: `cd **<Tab>`, `nvim src/**<Tab>` |

```bash
git branch | fzf | xargs git checkout   # pick a branch to switch to
```

### rg (ripgrep): search inside files

Fast, respects `.gitignore`, recursive by default.

```bash
rg "TODO"                    # search everything below here
rg -i "drone"                # case-insensitive
rg -w "init"                 # whole word only
rg "fn main" -t rust         # only Rust files (-t py, -t js, ...)
rg "import" -g '*.py'        # glob filter
rg -l "SPEC"                 # just list matching file names
rg -C 3 "panic"              # 3 lines of context around each hit
rg --hidden "token"          # include dotfiles
```

### fd: find files by name

```bash
fd config                    # names containing "config"
fd -e md                     # by extension
fd -e py -x wc -l            # run a command on each result
fd -H .tmux                  # include hidden files
fd -t d src                  # directories only
```

### jq: work with JSON

```bash
cat data.json | jq .                         # pretty-print
jq '.name' package.json                      # one field
jq '.items[] | {id, status}' resp.json       # reshape each element
jq -r '.dependencies | keys[]' package.json  # raw strings, one per line
```

### htop: what's using my CPU / RAM?

`htop`, then `F6` sort, `F3` search, `F9` kill (pick a signal), `F5` tree view, `q` quit.

---

## 9. Git

Config: `config/git/.gitconfig` (+ `.gitignore_global` for swap files and OS junk in every repo).

### Aliases

| Alias | Command | Use it for |
|---|---|---|
| `git st` | `status -sb` | Short status with branch |
| `git lg` | `log --oneline --graph --decorate --all` | The whole history as a graph |
| `git last` | `log -1 HEAD` | What was the last commit? |
| `git df` / `git dc` | `diff` / `diff --cached` | Unstaged / staged changes |
| `git co <branch>` | `checkout` | Switch branch |
| `git cb <name>` | `checkout -b` | New branch |
| `git ci -m "msg"` | `commit` | Commit |
| `git ca` | `commit --amend` | Fix the last commit (only if not pushed yet) |
| `git unstage <file>` | `reset HEAD --` | Undo `git add` |
| `git br` | pretty branch list | Branches with last commit subject |
| `git cleanup` | prune + gc | Tidy stale remote branches |

### The everyday loop

```bash
git cb feature/hover-mode        # 1. branch
# ... work (or let Claude work) ...
git st && git df                 # 2. see what changed
add -p                           # 3. stage hunk by hunk (y/n for each)
git dc                           # 4. check what you're about to commit
git ci -m "Add hover mode"       # 5. commit
git push no-mistakes             # 6. through the gate (or: push -u origin HEAD)
```

### Undo cheats

| Oops | Fix |
|---|---|
| Discard edits to a file | `git restore <file>` |
| Unstage a file | `git unstage <file>` |
| Put work aside for a moment | `git stash` … `git stash pop` |
| Undo the last commit, keep the changes | `git reset --soft HEAD~1` |
| Undo a pushed commit safely | `git revert <hash>` |
| "I lost a commit" | `git reflog`, find it, then `git cb rescue <hash>` |

Identity is per-repo by design: `git config user.name "Adam Dunn"`,
`git config user.email "..."`.

---

## 10. Neovim

Config: `config/nvim/init.lua` → `~/.config/nvim/init.lua`. Plugins install on first launch via
**lazy.nvim** (`:Lazy` to manage). Colorscheme: catppuccin-mocha.

> ⚠️ Neovim itself isn't in `flake.nix` or `home.nix` (see section 15). `nvim --version` tells
> you whether it's installed (e.g. via Linuxbrew).

### Survival guide: modes

| Mode | Enter with | What keys do |
|---|---|---|
| **Normal** | `Esc` | Keys are commands (move, delete, copy) |
| **Insert** | `i` (before cursor), `a` (after), `o` (new line below) | Keys type text |
| **Visual** | `v` (chars), `V` (lines), `Ctrl+V` (block) | Select, then act (`d`, `y`, `>`) |
| **Command** | `:` | `:w` save, `:q` quit, `:wq`, `:q!` quit without saving |

### Moving

| Keys | Move |
|---|---|
| `h j k l` | Left, down, up, right |
| `w` / `b` / `e` | Next word / back a word / end of word |
| `0` / `^` / `$` | Line start / first non-blank / line end |
| `gg` / `G` / `42G` | Top / bottom / line 42 |
| `Ctrl+D` / `Ctrl+U` | Half-page down / up |
| `%` | Jump to matching bracket |
| `5j` | 5 lines down (relative line numbers show you the counts) |

### Editing = operator + motion

| Operator | + motion example | Result |
|---|---|---|
| `d` delete | `dw`, `d$`, `dd` (line) | |
| `c` change | `ciw` (change inner word), `ci"` (inside quotes) | Deletes, then insert mode |
| `y` yank (copy) | `yy` (line), `yiw` | |
| `p` / `P` | | Paste after / before |
| `.` | | Repeat the last change |
| `u` / `Ctrl+R` | | Undo / redo (undo persists across restarts) |

### Your keymaps

The leader key is **not set** in `init.lua`, so it's Neovim's default **`\`** (backslash).

| Keys | Action |
|---|---|
| `Ctrl+P` | Find files (fzf-lua) |
| `Ctrl+G` | Grep across the project (fzf-lua) |
| `\w` | Save |
| `\q` | Quit |
| `\e` | Show the diagnostic under the cursor |
| `Esc` | Clear search highlight |
| `\u` | *Undo tree, but the undotree plugin isn't installed, so this errors (section 15)* |

### Search and replace

`/word` search (smartcase), `n` / `N` next / previous, `*` search the word under the cursor,
`:%s/old/new/g` replace all (`/gc` to confirm each).

### Git inside nvim (vim-fugitive / rhubarb)

`:Git` status window (`-` stage/unstage, `cc` commit, `=` inline diff), `:Git blame`,
`:Gdiffsplit`, `:GBrowse` opens the current line on GitHub.

### Windows and buffers

`:vsp file` / `:sp file` split, `Ctrl+W h/j/k/l` move between splits, `:e file` open,
`:ls` and `:b name` switch buffers, `:Ex` file browser.

---

## 11. vim

Plain vim is the fallback editor (`EDITOR=vim`, so it's what `git commit` opens). Config:
`config/vim/.vimrc`: relative numbers, 2-space indent, incremental + highlighted search,
persistent undo, `scrolloff=8`, colorscheme `torte`. All the modes, motions and operators from
section 10 work the same. There are no plugins or custom keymaps.

**Writing a git commit message in vim:** press `i`, type the message, `Esc`, then `:wq`. To
abort the commit, `:q!`.

---

## 12. Starship prompt

There are **two** starship configs, and they both target the same file:

- **`programs.starship` in `home.nix`** (minimal): home-manager writes it to
  `~/.config/starship.toml`.
- **`config/starship/starship.toml`** (powerline-style, with os/user/nix-shell/language
  segments): `install.sh` symlinks this to the **same path**, `~/.config/starship.toml`.

Whichever ran last wins. Check which one you have with `ls -l ~/.config/starship.toml` (a
symlink into `dotfiles/config/` means the install.sh one). See section 15.

### Reading the home.nix prompt

```
~/github/capstone main [!?] ⏱ 3s
➜
```

| Part | Meaning |
|---|---|
| directory | Where you are |
| branch + `[...]` | Git branch; `!` modified, `?` untracked, `+` staged, `⇡`/`⇣` ahead/behind |
| `⏱ 3s` | How long the last command took (only shown when slow) |
| `➜` purple / red | Last command succeeded / failed |

The install.sh version adds the OS + username, a `❄` marker inside `nix develop`, and the
active Node/Rust/Python versions.

---

## 13. Nix, home-manager and install.sh

| Piece | Owns | Apply changes with |
|---|---|---|
| **Nix flake** (`flake.nix`, `flake.lock`) | Pinned tools for the dev shell | `nix develop` |
| **home-manager** (`home.nix`) | zsh, starship, wezterm link, jq/htop/starship packages | `home-manager switch --flake .` |
| **install.sh** | Symlinks for `config/*` (git, tmux, nvim, vim, ssh, starship, claude) | `./install.sh` |
| **setup-claude-tools.sh** | Claude Code plugins + no-mistakes | `bash scripts/setup-claude-tools.sh` |

### Fresh WSL machine

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
cd ~ && git clone https://github.com/AdamDunn1437/dotfiles.git && cd dotfiles
nix develop
./install.sh
home-manager switch --flake .
chsh -s "$(which zsh)"                              # optional
curl -fsSL https://claude.ai/install.sh | bash      # Claude Code
bash scripts/setup-claude-tools.sh
```

### Day-to-day update loop

```bash
cd ~/github/AdamDunn1437/dotfiles
git pull
./install.sh                     # re-link config/*
home-manager switch --flake .    # if home.nix changed
tmux source-file ~/.tmux.conf    # if tmux changed (or Ctrl-a r)
```

### How install.sh works

- Maps each folder in `config/` to a target: `git`, `tmux`, `vim` → `~`; `ssh` → `~/.ssh`;
  `nvim` → `~/.config/nvim`; `starship` → `~/.config`; `claude` → `~/.claude`.
- Creates relative symlinks; safe to re-run.
- Backs up a real file at the destination as `*.bak` and replaces stale symlinks.
- Locks down `~/.ssh` (700) and `~/.ssh/config` (600).

---

## 14. Worked example: edit → apply → test → revert

The repo is the source of truth: change the file in the repo, apply it, and use git to go back.

**Scenario: try `Ctrl-b` as the tmux prefix.**

```bash
cd ~/github/AdamDunn1437/dotfiles
git st                                          # 1. start clean
vim config/tmux/.tmux.conf                      # 2. set -g prefix C-a  →  set -g prefix C-b
tmux source-file ~/.tmux.conf                   # 3. apply (inside tmux: the OLD prefix + r)
                                                #    test: Ctrl-b c should open a window
```

Keep it:

```bash
add config/tmux/.tmux.conf && commit -m "Try Ctrl-b prefix"
```

Or revert it:

```bash
git restore config/tmux/.tmux.conf    # throw the edit away
git stash / git stash pop             # or shelve it and bring it back later
tmux source-file ~/.tmux.conf         # re-apply the original
```

| Situation | Fix |
|---|---|
| `install.sh` backed up a real file | `mv ~/.tmux.conf.bak ~/.tmux.conf` (rarely needed) |
| You edited the generated `~/.zshrc` | Pointless: change `home.nix` instead |
| A flake update broke the build | `git restore flake.lock flake.nix`, then `nix develop` |
| You committed a bad config | `git revert <hash>` |

---

## 15. Known gaps in the current configs

Found while checking this sheet against the files. None of them breaks anything badly, but
each is worth a ticket:

| Gap | Effect | Fix |
|---|---|---|
| Neovim isn't in `flake.nix` or `home.nix` | A fresh machine has no `nvim` | Add `neovim` to `home.packages` |
| `mapleader` is never set | Leader is `\`, not Space | Add `vim.g.mapleader = " "` **before** `require("lazy")` |
| `\u` calls `UndotreeToggle`, but undotree isn't installed | Pressing it errors | Add `"mbbill/undotree"` to the lazy spec, or delete the mapping |
| lualine is listed with no `setup()` / `opts` | The statusline plugin likely never activates | Use `{ "nvim-lualine/lualine.nvim", opts = {} }` |
| treesitter has no parsers configured | Highlighting is mostly the default | Add `opts = { ensure_installed = {...}, highlight = { enable = true } }` |
| Two starship configs both target `~/.config/starship.toml` | Which prompt you get depends on run order | Keep one: delete `config/starship/` or `programs.starship` |
| `.tmux.conf` comment says "Shift + arrow" resize | Misleading comment; the keys are `Alt+h/j/k/l` | Fix the comment |
| `diff` alias shadows the system `diff` | `diff a b` runs `git diff` | Rename to `gdiff`, or live with `command diff` |

---

## 16. Where each config lives

| What | File | Applied by |
|---|---|---|
| Dev shell tools | `flake.nix` | `nix develop` |
| zsh + aliases | `home.nix` | `home-manager switch --flake .` |
| Starship prompt | `home.nix` **and** `config/starship/starship.toml` (see 12) | home-manager / `./install.sh` |
| WezTerm | `home/.config/wezterm/wezterm.lua` | home-manager |
| tmux | `config/tmux/.tmux.conf` | `./install.sh`, then `Ctrl-a r` |
| Neovim | `config/nvim/init.lua` | `./install.sh` |
| vim | `config/vim/.vimrc` | `./install.sh` |
| Git | `config/git/.gitconfig`, `.gitignore_global` | `./install.sh` |
| SSH | `config/ssh/config` | `./install.sh` |
| Claude Code global rules | `config/claude/CLAUDE.md` | `./install.sh` |
| explain-back skill | `config/claude/skills/explain-back/SKILL.md` | `./install.sh` |
| Claude plugins + no-mistakes | `scripts/setup-claude-tools.sh` | `bash scripts/setup-claude-tools.sh` |
