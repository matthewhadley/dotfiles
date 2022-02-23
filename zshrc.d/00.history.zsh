# Don't add commands that start with a space
setopt HIST_IGNORE_SPACE
# Don't add duplicate commands
setopt HIST_IGNORE_DUPS
# Append history instead of rewriting it
setopt appendhistory
# Immediately append to the history file, not just when a term is killed
setopt incappendhistory

# Allow a larger history file
HISTFILESIZE=1000000
HISTSIZE=1000000
# Add timestamps to history entries
HISTTIMEFORMAT='%F %T '

# History per ttyl
mkdir -p "$HOME/.history.d"
HISTFILE="$HOME/.history.d/${HOSTNAME:+$HOSTNAME-}${TTY_NUM}"
