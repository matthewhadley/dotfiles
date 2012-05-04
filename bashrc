## bash.rc
export DOTHOME=$HOME/etc/dothome
export OS=`uname`

function source_rc() {
    for rc in $1/*; do
        if [ -f $rc ]; then
            source $rc
        fi
    done
}

source_rc $DOTHOME/bash
source_rc $DOTHOME/bash/os/$OS
source_rc $DOTHOME/bash/host/$HOSTNAME