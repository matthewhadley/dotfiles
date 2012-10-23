#!/bin/bash
# create symlinks for ~/bin
#
DIR="$HOME/bin"
if [ ! -d $DIR ]; then
  mkdir $DIR
fi
cd $DIR
ln -s ~/dev/nodejs/LOTS/LOTS.js LOTS
ln -s ~/dev/perl/cloc/cloc-1.56.pl cloc
ln -s ~/dev/bash/bashbin/domains domains
ln -s ~/dev/bash/bashbin/export-tags export-tags
ln -s ~/dev/perl/git-moo/git-moo git-moo
ln -s ~/dev/bash/git.corp.identity/git.corp.identity.sh git.corp.identity
ln -s ~/dev/bash/git.dayone/git.dayone.sh git.dayone
ln -s ~/dev/bash/bashbin/gitbox gitbox
ln -s ~/dev/python/gtasks/gtasks.py gtasks
ln -s ~/dev/bash/bashbin/gtasks-dashboard gtasks-dashboard
ln -s ~/dev/python/keychain/keychain.py keychain
ln -s /Applications/openmeta openmeta
ln -s ~/dev/bash/bashbin/perms perms
ln -s /Applications/Sublime\ Text\ 2.app/Contents/SharedSupport/bin/subl sb
ln -s ~/dev/bash/bashbin/sbp sbp
ln -s ~/dev/bash/spark/spark spark
ln -s ~/dev/bash/bashbin/toggleyit toggleyit
ln -s ~/dev/bash/bashbin/tp tp
ln -s ~/dev/utils/jq/jq jq
echo "symlinks created"