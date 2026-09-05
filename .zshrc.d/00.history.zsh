# Don't add commands that start with a space
setopt HIST_IGNORE_SPACE
# Don't add duplicate commands
setopt HIST_IGNORE_DUPS
# Append history instead of rewriting it
setopt appendhistory
# Immediately append to the history file, not just when a term is killed
setopt incappendhistory
# Add timestamps to history entries
setopt EXTENDED_HISTORY

# Allow a larger history file
SAVEHIST=1000000
HISTSIZE=1000000

# History per TTY
mkdir -p "$HOME/.history.d"
HISTFILE="$HOME/.history.d/${HOSTNAME:+$HOSTNAME-}${TTY_NUM}"

# ripgrep
alias rg="rg --colors 'match:bg:yellow' --colors 'match:fg:black' --colors 'line:fg:white'"
rgh() {
  fc -AI 2>/dev/null || true
  rg "$@" "$HISTFILE" ~/.history.d 2>/dev/null
}
