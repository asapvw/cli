# =============================================================================
# ~/.config/zsh/.zshenv — environment variables, sourced for ALL zsh sessions
# Keep this file fast and quiet: no output, no slow commands. The only side
# effect is a one-time cache write to ~/.zsh_local (WIN_HOME derivation).
# Interactive-only setup (MANPAGER, GPG_TTY, tool inits) belongs in .zshrc.
# =============================================================================

# ---------- XDG base directories ----------
# Centralizes config/cache/data locations
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

export ZDOTDIR="$HOME/.config/zsh"

# ---------- tmux ----------
export TMUX_CONF="$XDG_CONFIG_HOME/tmux/tmux.conf"
export TMUX_CONF_LOCAL="$TMUX_CONF.local"
export TMUX_CONF_DIR=$(dirname "$TMUX_CONF")

# ---------- Editor ----------
# Default editor used by git, crontab, etc.
export EDITOR="nvim"
export VISUAL="nvim"

# ---------- Starship ----------
export STARSHIP_CONFIG="$ZDOTDIR/starship.toml"

# ---------- PATH ----------
# Personal binaries/scripts
export PATH="$HOME/.local/bin:$PATH"
# ovftool
export PATH="$HOME/tools/ovftool:$PATH"

# -----------------------------------------------------------------------------
# Windows host home (WSL2 mount of C:\Users\<user>)
# Resolution order:
#   1. ~/.zsh_local (per-machine, untracked) — authoritative if present
#   2. $USERPROFILE via wslpath — fast, works when WSLENV forwards it
#   3. cmd.exe query — fallback when $USERPROFILE is empty/unset
# The derived value is cached to ~/.zsh_local so future shells (including
# every non-interactive script) skip the slow wslpath/cmd.exe round-trips.
# -----------------------------------------------------------------------------
# Per-machine overrides (untracked), if present
[[ -f ~/.zsh_local ]] && source ~/.zsh_local

# Auto-derive Windows home if not already set by .zsh_local
if [[ -z "$WIN_HOME" ]]; then
  WIN_HOME="$(wslpath "$USERPROFILE" 2>/dev/null)"
  # wslpath "" returns "." — reject that (and any non-directory) so the
  # cmd.exe fallback actually fires instead of silently accepting garbage.
  if [[ -z "$WIN_HOME" || "$WIN_HOME" == "." || ! -d "$WIN_HOME" ]]; then
    WIN_HOME="$(wslpath "$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')" 2>/dev/null)"
  fi
  # Cache for future shells
  [[ -d "$WIN_HOME" ]] && print -r -- "export WIN_HOME=\"$WIN_HOME\"" >> ~/.zsh_local
fi
export WIN_HOME

export REPOS="$HOME/repos"
export WINREPOS="$WIN_HOME/repos"
export DOTFILES="$WIN_HOME/repos/dotfiles"
export ASAPVW="$WIN_HOME/repos/asapvw.xcx"
export QOPRODUCT="$WIN_HOME/repos/qo-product"
export QODOCS="$WIN_HOME/repos/qo-docs"
