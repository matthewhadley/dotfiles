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

# env
# export NODE_ENV=development
