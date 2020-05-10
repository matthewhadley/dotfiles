# Don't add duplicate commands or commands that start with a space to bash history
HISTCONTROL=ignoreboth
# Append history instead of rewriting it
shopt -s histappend
# Allow a larger history file
HISTFILESIZE=1000000
HISTSIZE=1000000
# Add timestamps to history entries
HISTTIMEFORMAT='%F %T '

# bash_history per ttyl
mkdir -p $HOME/.history.d
HISTFILE="$HOME/.history.d/$HOSTNAME-$TTY_NUM"

# note `history -a` added to PROMPT_COMMAND
