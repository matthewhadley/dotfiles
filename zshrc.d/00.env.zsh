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
export NODE_ENV=development

# set GIT_SSH to allow per host configs
# https://github.com/matthewhadley/git-ssh
export GIT_SSH=$HOME/dev/bash/git-ssh/git-ssh.sh
export GIT_CORP=$HOME/dev/bash/git.corp/git.corp.sh

# Add default ssh key
ssh-add "$HOME/.ssh/id_rsa" 2>/dev/null
