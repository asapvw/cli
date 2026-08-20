# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

The complete Linux CLI configuration for a WSL2 Ubuntu machine: zsh config (originally created by merging a personal config into the open-source [radleylewis/zsh](https://github.com/radleylewis/zsh) project), CLI tool configs under `tools/` (tmux, yazi, lazygit, btop, global git ignore), package manifests under `packages/`, and `bootstrap.zsh` for new-machine setup. The repo is named `cli`; cross-platform configs (`.gitconfig`, nvim) stay in the separate dotfiles repo. There is no build, lint, or test suite — validation is done by syntax-checking and launching a shell.

## Ask before you assume

Never guess at intent. If a task leaves anything open — whether a value belongs in `~/.zsh_local` or the repo, whether a keybinding needs the `zvm_after_init` hook, whether a config change should also land in the dotfiles repo, what happens on failure — stop and ask. One question up front is cheaper than half a day of work in the wrong direction.

- Ask when the request could reasonably mean two different things.
- Do not widen scope past what was asked. Note the adjacent thing you spotted; don't fix it unprompted.
- When running unattended (background job, headless), pick the conservative interpretation instead of blocking on a question.
- If you had to assume something you couldn't resolve, list it explicitly at the top of your summary.

## Validation commands

```sh
zsh -n .zshrc                      # syntax check any file (no execution)
ZDOTDIR=$PWD zsh -i -c exit        # smoke-test THIS repo's config end to end
time ZDOTDIR=$PWD zsh -i -c exit   # startup-time measurement
```

Without the `ZDOTDIR=$PWD` override, `zsh -i` tests the machine's live config, not this working copy (see below).

## Deployment model — read this before editing

This working copy IS the live config. `~/.config/zsh` is a symlink to this repo, and a `~/.zshenv` bootstrap stub sets `ZDOTDIR="$HOME/.config/zsh"` and sources `$ZDOTDIR/.zshenv` (the stub exists because setting `ZDOTDIR` in `/etc/zsh/zshenv` would need root). Load order: `~/.zshenv` stub → `$ZDOTDIR/.zshenv` → `$ZDOTDIR/.zshrc` → the five modular files.

Consequences:

1. Edits here take effect in the next shell — no copy/sync step. Test with `zsh -i -c exit` before considering a change done.
2. `_ensure_links` in `.zshrc` self-heals the tool-config symlinks on every shell start: `tools/*` entries are addressed via `$ZDOTDIR` (so they survive a repo move); only `.gitconfig` and `nvim` still point at the dotfiles repo.
3. Plugins clone to `~/.local/share/zsh/plugins/` (not `$ZDOTDIR/plugins/`) to keep them off the slow `/mnt/c` drvfs mount.
4. `packages/Brewfile` and `packages/apt-manual.txt` are dumped manifests, not hand-curated — refresh with the `pkgsync` function after installing/removing tools; don't edit them manually.

## File roles and load order

- `.zshenv` — sourced by *every* zsh invocation (including scripts); must stay fast and output-free. Sets XDG dirs, editor, and derives `WIN_HOME` (WSL mount of the Windows home) with a `wslpath`/`cmd.exe` fallback chain, caching the result to `~/.zsh_local`. `~/.zsh_local` (untracked, per-machine) is sourced first and wins. Interactive-only setup (MANPAGER, GPG_TTY, tool inits) belongs in `.zshrc`, not here.
- `.zshrc` — interactive config. Order is load-bearing: Homebrew `shellenv` + `fpath` first (every tool below is brew-installed), then `compinit` (once, with the XDG-cached dump), then the modular files, then NVM/SSH-agent. Don't add a second `compinit`, a second `zoxide init`, or prompt-theme calls (`promptinit`/`prompt`) — starship in `prompt.zsh` owns the prompt.
- `fzf.zsh`, `aliases.zsh`, `bindings.zsh`, `plugins.zsh`, `prompt.zsh` — modular files, each sourced from `.zshrc`. Aliases and shell functions go in `aliases.zsh`; fzf env vars and widgets in `fzf.zsh`.
- `.src-zshenv`, `.src-zshrc`, `SRC-README.md` — pristine reference copies of the upstream project ([radleylewis/zsh](https://github.com/radleylewis/zsh)). Never edit these as live config; they exist for diffing against upstream.
- `starship.toml` — prompt config, loaded via `STARSHIP_CONFIG="$ZDOTDIR/starship.toml"` in `.zshenv`.
- `tools/` — CLI tool configs (tmux, yazi, lazygit, btop, git ignore), symlinked into `~/.config` by `_ensure_links`. Edit these files here, not the symlink targets' neighbors in `~/.config`.
- `packages/` — dumped Brewfile + apt manifest (see `pkgsync`).
- `bootstrap.zsh` — one-time new-machine setup: installs packages from the manifests, wires `~/.config/zsh` + the `~/.zshenv` ZDOTDIR stub. Idempotent; run manually, never sourced.

## Plugin system

No third-party plugin manager for zsh. `plugins.zsh` defines `_zplugin_load`, which clones each plugin into `~/.local/share/zsh/plugins/` on first launch and sources it. `zplugin-update` pulls all of them.

tmux plugins use TPM, kept in the same spirit: `tools/tmux/tmux.conf` self-clones TPM into `~/.local/share/tmux/plugins/` on first tmux launch (off drvfs, like the zsh plugins) — no manual install step. `prefix+I` installs newly added plugins, `prefix+U` updates.

**zsh-vi-mode constraint:** the plugin resets all keybindings when it initializes at the first prompt. Any `bindkey` must be registered inside the `zvm_after_init()` hook in `bindings.zsh` or it will be silently wiped. That hook also re-runs `_fzf_shell_integration` (defined in `fzf.zsh`) to restore fzf's Ctrl+R/Ctrl+T/Alt+C — keep that call first if you edit the hook.

## Conventions

- Commit messages follow loose conventional-commit prefixes: `feat:`, `fix:`, `refactor:`, `chore:`.
- Work happens on `qo/YYYY.WW` branches (e.g. `qo/2026.28`); PRs target `main`.
- Machine-specific values go in `~/.zsh_local`, never committed.

## Keep the README in sync

Whenever a change substantially adds to or removes from the core zsh configuration (`.zshenv`, `.zshrc`, the modular files), the plugin set (zsh or tmux), or `bootstrap.zsh`, update `README.md` in the same change so it accurately reflects the current state of the project — layout, setup/migration steps, plugin tables, and keybindings — and document any important information or useful details the change introduced. Small tweaks (an alias, a color, a refactor with no behavior change) don't require a README pass.

## Keeping this file current

This file is a failure log, not a wishlist. Every line in the failure log should exist because it went wrong at least once.

When you make a mistake, get corrected, or discover something about this codebase that wasn't written down:

1. Add one line to the failure log below, in the imperative, describing the correct behaviour.
2. Keep it specific to this repo. General advice belongs nowhere.
3. If the fix is a workflow rather than a rule, put it in `.claude/skills/` and link it from here.
4. Include the update alongside the work that prompted it and mention it in your summary.

Keep this file under 500 lines. It is loaded into every session, and long context makes you less reliable, not more. If a section outgrows its usefulness, move it to a skill in `.claude/skills/` and link it from here.

## Failure log

- 
