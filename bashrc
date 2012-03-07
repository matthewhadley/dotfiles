## bash.rc

### SHELL VARS

# Path
export PATH="$PATH:~/bin"

### BEHAVIOURS

# Prevent tar include "._" file resource forks
export COPYFILE_DISABLE=true

# Don't add duplicate commands or commands that start with a space to bash history
HISTCONTROL=ignoreboth

### ALIASES

#### Commands

# color output
alias ls='ls -G'

#### ssh hosts
alias sss='ssh stephadflier'
alias ssb='ssh buildingwork'

### CUSTOM FUNCTIONS

# Copy ssh keys to another host
function copykeys {
    username=$2
    ssh ${username:=$USER}@${1} "echo `cat ~/.ssh/id_dsa.pub` >> ~/.ssh/authorized_keys"
}

# Get the git branch name of current directory
function parse_git_branch {
  git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

### SHELL APPEARANCE CUSTOMISATION
PS1="\[\033[1;37m\]\h: \w \$(parse_git_branch) \n$ \[\e[0m\]"
