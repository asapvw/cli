# =========================================================
# Keybindings
# =========================================================

# Cursor shape per vi mode. zvm calls this during its init, after the
# $ZVM_CURSOR_* constants exist — set at top level they'd expand empty.
zvm_config() {
  ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BEAM
  ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK
  ZVM_VISUAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK
  ZVM_VI_INSERT_ESCAPE_BINDKEY=jk
}

# Disable command mode line highlight
ZVM_VI_HIGHLIGHT_BACKGROUND=none
ZVM_VI_HIGHLIGHT_FOREGROUND=none
ZVM_VI_HIGHLIGHT_EXTRASTYLE=none

# zsh-vi-mode resets all bindings on init, so custom bindings
# must be registered via this hook to survive.
zvm_after_init() {
  # Restore fzf's Ctrl+R / Ctrl+T / Alt+C, which zvm just wiped
  _fzf_shell_integration

  # Ctrl+Right / Ctrl+Left -> move by word (^[[1;5C / ^[[1;5D are terminal escape codes)
  bindkey '^[[1;5C' forward-word
  bindkey '^[[1;5D' backward-word

  # Home / End / Del
  bindkey '^[[H' beginning-of-line
  bindkey '^[[F' end-of-line
  bindkey '^[[3~' delete-char

  # Ctrl+F -> fzf file picker (no hidden files)
  bindkey '^F' _fzf_file_no_hidden

  # Ctrl+\ -> toggle autosuggestions (useful for screen recordings)
  bindkey '^\' autosuggest-toggle

  # Up/Down -> history search by substring (^[[A/^[[B are up/down arrow escape codes)
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
}
