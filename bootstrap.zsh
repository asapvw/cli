#!/usr/bin/env zsh
# =============================================================================
# bootstrap.zsh — one-time-per-machine setup for the cli repo
#
# Run explicitly on a new machine (NOT sourced automatically):
#     zsh /mnt/c/Users/<you>/repos/cli/bootstrap.zsh
#
# Idempotent and safe to re-run. Steps:
#   1. Resolve $WIN_HOME (Windows home) and locate this repo
#   2. Install packages: Homebrew bundle + apt manifest (best-effort)
#   3. Wire zsh: ~/.config/zsh symlink + ~/.zshenv ZDOTDIR stub + state dirs
#   4. Tool-config symlinks are NOT created here — _ensure_links in .zshrc
#      self-heals them on every shell start
# =============================================================================

set -u  # error on unset variables

# -----------------------------------------------------------------------------
# 1. Resolve Windows home ($WIN_HOME) — same logic as .zshenv, self-contained
#    here so bootstrap works before anything is linked.
# -----------------------------------------------------------------------------
[[ -f ~/.zsh_local ]] && source ~/.zsh_local

if [[ -z "${WIN_HOME:-}" ]]; then
  WIN_HOME="$(wslpath "${USERPROFILE:-}" 2>/dev/null)"
  # wslpath "" returns "." — reject that (and any non-directory) so the
  # cmd.exe fallback actually fires instead of silently accepting garbage.
  if [[ -z "$WIN_HOME" || "$WIN_HOME" == "." || ! -d "$WIN_HOME" ]]; then
    WIN_HOME="$(wslpath "$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')" 2>/dev/null)"
  fi
fi

CLI_REPO="$WIN_HOME/repos/cli"

if [[ -z "$WIN_HOME" || ! -d "$CLI_REPO" ]]; then
  print -u2 "✗ Could not resolve the cli repo."
  print -u2 "  WIN_HOME resolved to: '${WIN_HOME:-<empty>}'"
  print -u2 "  Expected repo at:     '$CLI_REPO'"
  print -u2 "  Fix: create ~/.zsh_local with 'export WIN_HOME=/mnt/c/Users/<you>' and re-run."
  exit 1
fi

print "Using CLI_REPO=$CLI_REPO"
print ""

# -----------------------------------------------------------------------------
# 2. Packages — brew bundle from the committed manifest, then apt.
# -----------------------------------------------------------------------------
if (( $+commands[brew] )); then
  print "→ brew bundle (packages/Brewfile)"
  brew bundle --file="$CLI_REPO/packages/Brewfile" || print "⚠ brew bundle reported errors — continuing"
else
  print "⚠ Homebrew not installed — skipping brew packages. Install it first:"
  print '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
fi

if [[ -f "$CLI_REPO/packages/apt-manual.txt" ]]; then
  print "→ apt install (packages/apt-manual.txt) — needs sudo"
  sudo apt-get update -qq
  # xargs keeps going past already-installed packages; missing ones just warn
  xargs -a "$CLI_REPO/packages/apt-manual.txt" sudo apt-get install -y --ignore-missing || \
    print "⚠ some apt packages failed — review output above"
fi

# -----------------------------------------------------------------------------
# 3. Zsh wiring — ~/.config/zsh symlink, ~/.zshenv stub, state dirs.
#    The symlink keeps the name "zsh" (it IS zsh's ZDOTDIR) even though the
#    repo is named cli.
# -----------------------------------------------------------------------------
if [[ "$(readlink ~/.config/zsh 2>/dev/null)" == "$CLI_REPO" ]]; then
  print "✓ already linked: ~/.config/zsh"
else
  mkdir -p ~/.config
  ln -sfn "$CLI_REPO" ~/.config/zsh
  print "→ linked: ~/.config/zsh -> $CLI_REPO"
fi

cat > ~/.zshenv <<'EOF'
# Bootstrap stub — the real zsh config lives in $ZDOTDIR (~/.config/zsh,
# a symlink to the cli repo). This stub exists only because setting
# ZDOTDIR system-wide requires root (/etc/zsh/zshenv); everything else
# belongs in $ZDOTDIR. Do not add config here.
export ZDOTDIR="$HOME/.config/zsh"
[[ -f "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"
EOF
print "→ wrote ~/.zshenv ZDOTDIR stub"
mkdir -p ~/.local/state/zsh ~/.cache/zsh   # history + completion cache

print ""
print "Done. Start a fresh shell with:  exec zsh"
print "(tool-config symlinks are created by _ensure_links on first launch)"
