# =========================================================
# Listing (eza)
# =========================================================

# Better ls
alias ls='eza --icons'

# Detailed listing
alias ll='eza -lh --icons --git'

# Detailed listing including hidden files
alias la='eza -lah --icons --git'

# Tree views
alias tree='eza --tree --icons'
alias lt='eza --tree --icons --level=2'
alias lg='eza -l --icons --git --sort=modified'

# Reuse ls completions for eza (avoids defining a separate completion function)
compdef eza=ls

# Better cat
alias cat='bat --paging=never'
alias catp='bat'  # with paging, for longer files

# =========================================================
# Core utilities
# =========================================================

alias grep='rg --color=auto'
alias diff='diff --color=auto'
alias df='df -h'
alias cl='clear'

# =========================================================
# Navigation
# =========================================================

alias -- -='cd -'  # -- prevents - being parsed as a flag; cd - jumps to previous directory
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

lf() { # zsh follow lf navigation
    tmp=$(mktemp)
    command lf -last-dir-path="$tmp" "$@"
    if [ -f "$tmp" ]; then
        dir=$(cat "$tmp")
        rm -f "$tmp"
        [ -d "$dir" ] && [ "$dir" != "$(pwd)" ] && cd "$dir"
    fi
}

y() { # yazi wrapper: cd to the directory yazi exited in
    local tmp="$(mktemp -t yazi-cwd.XXXXXX)" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

alias yr='y "$REPOS"'     # browse $REPOS in yazi, cd to where you exit
alias ywr='y "$WINREPOS"' # same for $WINREPOS
alias yz='y "$ZDOTDIR"'     # browse $ZDOTDIR in yazi, cd to where you exit

repo() { # fuzzy-pick a repo under $REPOS and cd into it
  local dir
  dir=$(fd . "$REPOS" --max-depth 1 --type d | fzf --prompt="repo> ")
  [[ -n "$dir" ]] && cd "$dir"
}

# =========================================================
# Editor
# =========================================================

alias v='nvim'
alias vi='nvim'

# =========================================================
# Git
# =========================================================

alias glog='PAGER="less -F -X" git log'                              # -F quit if one screen, -X no clear on exit
alias gadog='PAGER="less -F -X" git log --all --decorate --oneline --graph'
alias dotfiles='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
alias g='git'
alias gs='git status -sb'
alias gd='git diff'
alias gaa='git add -A'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate -20'
alias lzg='lazygit'

# =========================================================
# Package updates
# =========================================================

alias bru='brew update && brew upgrade -y'
alias aptu='sudo apt update && sudo apt upgrade -y'

# =========================================================
# Claude Code
# =========================================================

alias resclaude='claude --resume'
alias cleanpaste='xclip -selection clipboard -o | sed "s/[▏▕│┃]//g" | sed "s/[[:space:]]*$//" | xclip -selection clipboard -i'

# =========================================================
# WSL2
# =========================================================

alias explorer='explorer.exe .'  # opens Windows File Explorer in the current directory
alias clip='clip.exe'            # pipes stdin to the Windows clipboard, e.g. `pwd | clip`

# =========================================================
# QoL 
# =========================================================

als() { # print current aliases, optionally filtered: `als git`
    if (( $# )); then
        alias | sort | grep -i --color=auto -- "$1"
    else
        alias | sort | bat -l zsh --style=plain --paging=never
    fi
}

pkgsync() { # refresh the package manifests committed in this repo
    brew bundle dump --force --file="$ZDOTDIR/packages/Brewfile"
    apt-mark showmanual > "$ZDOTDIR/packages/apt-manual.txt"
    print "Updated $ZDOTDIR/packages/ — review with: git -C $ZDOTDIR diff packages"
}

alias home='cd ~'
alias reload='source $ZDOTDIR/.zshrc'
alias path='echo -e ${PATH//:/\\n}'
alias hist='history'
alias c='clear'

# =========================================================
# Misc
# =========================================================

# Fix CRLF line endings (Windows -> Unix)
fix_crlf() {
  dos2unix "$1" 2>/dev/null || sed -i 's/\r//' "$1"
}

# Video
alias stream='mpv av://v4l2:/dev/video4 --fullscreen --demuxer-lavf-o=input_format=mjpeg,framerate=30 --profile=low-latency --untimed'
