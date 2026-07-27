# asapvw Linux CLI config

Single home for the WSL2 Ubuntu command-line environment: zsh configuration,
CLI tool configs (yazi, lazygit, btop, git ignore), and the package manifests
that describe what's installed. Cross-platform configs (`.gitconfig`, nvim)
live in the separate [dotfiles](https://github.com/asapvw/dotfiles) repo.

## Layout

```
.zshenv .zshrc                 zsh core (loaded via ZDOTDIR)
aliases.zsh bindings.zsh
fzf.zsh plugins.zsh prompt.zsh  modular zsh files sourced from .zshrc
starship.toml                  prompt config (STARSHIP_CONFIG)
tools/                         CLI tool configs, symlinked into ~/.config
  yazi/    yazi.toml, keymap.toml
  lazygit/ config.yml
  btop/    themes/ (btop writes btop.conf here once run)
  git/     ignore (global excludes)
packages/                      what's installed on this machine
  Brewfile                     brew bundle manifest
  apt-manual.txt               manually-installed apt packages
bootstrap.zsh                  one-time new-machine setup
```

Symlinks from `~/.config/*` into `tools/` are created and self-healed by
`_ensure_links` in `.zshrc` on every shell start — routed through the
`~/.config/zsh` symlink so they survive a repo move.

## New machine setup

```shell
# 1. prerequisites + Homebrew
sudo apt-get install build-essential procps curl file git
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. get the repos (WSL setup symlinks the copies on the Windows mount).
#    dotfiles is needed too: _ensure_links silently skips the .gitconfig
#    and nvim links when it's absent.
git clone git@github.com:asapvw/cli.git      /mnt/c/Users/<you>/repos/cli
git clone git@github.com:asapvw/dotfiles.git /mnt/c/Users/<you>/repos/dotfiles

# 3. run bootstrap — installs packages, wires ZDOTDIR, creates state dirs
zsh /mnt/c/Users/<you>/repos/cli/bootstrap.zsh

# 4. make zsh the login shell
command -v zsh | sudo tee -a /etc/shells
chsh -s $(which zsh)
exec zsh
```

`bootstrap.zsh` is idempotent — safe to re-run. It writes the `~/.zshenv`
stub that sets `ZDOTDIR="$HOME/.config/zsh"` (a symlink to this repo; the
symlink keeps the name `zsh` because that's what ZDOTDIR is). Plugins and
tool-config symlinks are handled automatically on first shell launch.

Machine-specific values (e.g. `WIN_HOME`) go in `~/.zsh_local`, never
committed.

The SSH-agent block in `.zshrc` expects a key at `~/.ssh/asapvw` — put it
in place (or adjust the path) or every new shell will report a failed
`ssh-add`. If the key isn't on the machine yet, clone the repos over
HTTPS first and switch the remotes later.

## Migrating an existing WSL install

A machine already running an older layout (home-dir `.zshrc`/`.zshenv`
symlinks, or the previous `zsh` repo before the rename) transitions with
the same script:

```shell
# 1. make sure the repos sit at their expected paths
#    $WIN_HOME/repos/cli  and  $WIN_HOME/repos/dotfiles

# 2. re-run bootstrap — it converges the machine:
#    - re-points ~/.config/zsh at this repo (left alone if it already
#      resolves here, even via a different-case drvfs path)
#    - overwrites ~/.zshenv with the ZDOTDIR stub
#    - removes a stale ~/.zshrc symlink (ignored once ZDOTDIR is set)
zsh /mnt/c/Users/<you>/repos/cli/bootstrap.zsh

# 3. reload
exec zsh
```

Plugins re-clone themselves to `~/.local/share/zsh/plugins/` on first
launch and `_ensure_links` refreshes the tool-config symlinks; old plugin
clones from previous layouts (e.g. `plugins/` inside the old repo) can be
deleted, nothing references them.

## Packages

`packages/Brewfile` and `packages/apt-manual.txt` are the source of truth
for what's installed. After installing or removing tools, refresh them with:

```sh
pkgsync
```

then review and commit the diff.

## Plugins

Managed without a third-party plugin manager. Plugins are cloned into `~/.local/share/zsh/plugins/` on first launch (kept off `$ZDOTDIR`, which may sit on a slow `/mnt/c` mount in WSL).

| Plugin | Purpose |
|--------|---------|
| [fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting) | Syntax highlighting |
| [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) | Fish-style inline suggestions |
| [zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search) | Up/down arrow history filtering |
| [zsh-vi-mode](https://github.com/jeffreytse/zsh-vi-mode) | Vi keybindings |

To update all plugins:

```sh
zplugin-update
```

## Keybindings

| Key | Action |
|-----|--------|
| `Ctrl+R` | Fuzzy history search (fzf) |
| `Ctrl+T` | Fuzzy file search including hidden files (fzf + fd) |
| `Ctrl+F` | Fuzzy file search excluding hidden files (fzf + fd) |
| `Ctrl+→` | Move forward one word |
| `Ctrl+←` | Move backward one word |
| `↑` / `↓` | History search by prefix |
| `Ctrl+\` | Toggle autosuggestions |

In yazi, `!` drops into an interactive zsh at yazi's current directory
(`tools/yazi/keymap.toml`); `exit` returns to yazi.

## Starship Config

Included in the repo at [`starship.toml`](./starship.toml) and loaded automatically via `STARSHIP_CONFIG` in `.zshenv`. Requires a [Nerd Font](https://www.nerdfonts.com) in your terminal.
