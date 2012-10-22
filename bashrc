## bash.rc
export DOTFILES=$HOME/.dotfiles
export OS=`uname`
if [ -d /home/y ]; then
  export DOMAIN='yahoo'
elif [ -f /etc/arch-release ]; then
  export DOMAIN='arch'
fi

function source_rc() {
    for rc in $1/*; do
        if [ -f $rc ]; then
            source $rc
        fi
    done
}

source_rc $DOTFILES/bash
source_rc $DOTFILES/bash/domain/$DOMAIN
source_rc $DOTFILES/bash/os/$OS
source_rc $DOTFILES/bash/host/$HOSTNAME
