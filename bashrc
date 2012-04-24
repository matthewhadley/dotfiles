## bash.rc
export DOTHOME=$HOME/etc/dothome

for rc_file in $DOTHOME/bash/*; do
    source $rc_file
done