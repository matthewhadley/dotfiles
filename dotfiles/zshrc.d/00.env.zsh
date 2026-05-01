# stackoverflow.com/questions/23128353/zsh-shortcut-ctrl-a-not-working
bindkey -e

# allow #comments in shell
setopt interactivecomments

# Get TTY number, last 2 digits
TTY_NUM=$(tty|cut -c11-)

# Prevent tar include "._" file resource forks
export COPYFILE_DISABLE=true

# Use vim
export EDITOR=vim

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

# Completion
# HOMEBREW_PREFIX is set by `brew shellenv` above
if [ -n "$HOMEBREW_PREFIX" ]; then
  FPATH=$HOMEBREW_PREFIX/share/zsh-completions:$FPATH

  autoload -Uz compinit
  compinit
fi

# tab completion capital letters also match small letters
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
