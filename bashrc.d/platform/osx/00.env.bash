# env
export NODE_ENV=dev

# set GIT_SSH to allow per host configs
# https://github.com/diffsky/git-ssh
export GIT_SSH=$HOME/dev/bash/git-ssh/git-ssh.sh
export GIT_CORP=$HOME/dev/bash/git.corp/git.corp.sh

# Add default ssh key
ssh-add $HOME/.ssh/id_rsa 2>/dev/null
