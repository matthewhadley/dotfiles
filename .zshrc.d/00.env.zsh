# stackoverflow.com/questions/23128353/zsh-shortcut-ctrl-a-not-working
bindkey -e

# allow #comments in shell
setopt interactivecomments

# Get TTY number, last 2 digits
TTY_NUM=$(tty|cut -c11-)

# Prevent tar include "._" file resource forks
export COPYFILE_DISABLE=true

# Editor. EDITOR stays vim as the fallback; VISUAL is the variable most tools
# check first, so nvim wins wherever a tool consults both -- git, which has no
# core.editor set, is one. Typing `vim` or `vi` still gets vim.
#
# yazi is NOT one of these: its built-in edit opener is hardcoded to
# ${EDITOR:-vi} and never looks at VISUAL, so it needs its own override --
# see the [opener] block in ~/.config/yazi/yazi.toml.
export EDITOR=vim
export VISUAL=nvim

# lazygit resolves its config dir through adrg/xdg: ~/.config on Linux, but
# ~/Library/Application Support on macOS. The config is tracked at the Linux
# path so one file serves both, and this points macOS at it.
#
# Guarded on the file existing rather than on the OS: LG_CONFIG_FILE is
# error-if-missing, so an unconditional export would turn a missing config into
# a hard failure instead of lazygit falling back to its defaults.
if [ -f "$HOME/.config/lazygit/config.yml" ]; then
  export LG_CONFIG_FILE="$HOME/.config/lazygit/config.yml"
fi

# Path
function pathadd {
  if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
    PATH="$1:$PATH"
  fi
}

# Homebrew - ensure homebrew binaries take precedence over macOS built-ins
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# After brew, deliberately: both pathadd and `brew shellenv` prepend, so
# whichever runs last ends up in front. This is what puts ~/.local/bin ahead of
# /opt/homebrew/bin.
pathadd "$HOME/.local/bin"

# Completion
# HOMEBREW_PREFIX is set by `brew shellenv` above
if [ -n "$HOMEBREW_PREFIX" ]; then
  FPATH=$HOMEBREW_PREFIX/share/zsh-completions:$FPATH

  autoload -Uz compinit
  compinit
fi

# tab completion capital letters also match small letters
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
