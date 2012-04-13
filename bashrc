## bash.rc

### SHELL VARS

# Path
function pathadd {
    if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
        PATH="$PATH:$1"
    fi
}

pathadd '/usr/local/sbin'
pathadd $HOME'/bin'

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
function parseGitBranch {
    git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

function tasksDashboard {
    if [ -f ~/.tasks ]; then
        db=`cat $HOME/.tasks`
        echo -e "\n$db"
    fi
}

TXTDEF='\[\e[0m\]'          # everything back to defaults
BLDWHT='\[\033[1;37m\]'     # bold white text

PS1="$BLDWHT\h: \w \$(parseGitBranch)\$(tasksDashboard)$BLDWHT\n\$ $TXTDEF"
